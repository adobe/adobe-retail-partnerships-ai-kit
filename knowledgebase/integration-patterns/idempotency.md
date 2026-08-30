# Integration Pattern: Idempotency

## The Core Rule

**`partner_reference_id` is permanent per (customer, product) pair.**

Once a `partner_reference_id` is used in a Workflow API call, it is permanently bound to that `offer_id`. This binding never changes, even after cancellation.

## Lifecycle of a `partner_reference_id`

```
Customer 1, Product: the offered Adobe product (e.g. Adobe Express)
│
├─ First claim:
│    partner_reference_id = "partner_9999_express_2026"
│    offer_id = "30006514"
│    → INITIATED (order intent created at Adobe)
│    → User activates → FULFILLED (subscription ACTIVE)
│
├─ Subscription cancelled (user or partner):
│    partner_reference_id = "partner_9999_express_2026"  ← RETIRED
│    → CANCELLED at Adobe
│    → "partner_9999_express_2026" can never be reused
│
└─ Customer re-subscribes later:
     partner_reference_id = "partner_9999_express_20270315"  ← NEW ID required
     offer_id = "30006514"  ← same offer is fine
     → New order intent created
```

## Generating `partner_reference_id`

**There is no fixed format.** The two options below (a fresh UUID, or a structured composite string) are illustrative examples of a *strategy*, not a format the kit expects — the value is opaque to Adobe and to this kit. Before generating anything:

1. **Check the partner's own codebase first** for an existing customer/order/subscription ID convention (an existing order-id or account-id scheme) — reusing it is usually preferable to inventing a new one.
2. **If none exists, or it's unclear whether to reuse it, ask the partner** what format/constraints apply (max length, allowed characters, whether it may embed customer-identifying data — many partners will say no to that last one). Record the confirmed answer in `service-cards/backend/INTEGRATION_CONTEXT.md` ("Where `partner_reference_id` Is Stored" → Format).
3. **Only default to a fresh UUID** when neither of the above resolves it — and say so explicitly in the report, so the partner engineer knows a default was used rather than their own convention.

**Option A — Generated on first claim, stored (illustrative):**
```
On first claim:
  id = generate_unique_id()  // UUID, or the partner's existing ID scheme
  store in your DB: { customer_id, offer_id, partner_reference_id: id, status: INITIATED }
  use id in Workflow API call

On subsequent claims (same customer, same product, new subscription):
  id = generate_unique_id()  // new ID — previous one is retired
  store new record
```

**Option B — Structured, database-backed (illustrative):**
```
id = "{partner_prefix}_{customer_id}_{product_code}_{yyyyMMdd}_{sequence}"
Example: "partner_9876543210_express_20260129_001"
Store in DB with customer_id as foreign key.
```

Whichever approach: **store the `partner_reference_id` in your database**. You need it to:
- Look up subscription status (Get Subscription API)
- Cancel the subscription (Update Subscription API)
- Match Notify API callbacks

## Workflow API Idempotency

The Workflow API is safe to retry:

| Scenario | Adobe Response | Your Action |
|---|---|---|
| First call with new `partner_reference_id` | 202 + `experience_url` | Redirect user |
| Same `partner_reference_id` + same `offer_id`, not yet fulfilled | 202 + same `experience_url` | Redirect user (same URL is fine) |
| Same `partner_reference_id` + same `offer_id`, already fulfilled | 409 `ALREADY_FULFILLED` | Navigate to subscription status (not an error) |
| Same `partner_reference_id` + **different** `offer_id` | 400 `SUBSCRIPTION_ID_ALREADY_IN_USE` | Data error in your system — log with high severity |

The last case (400 SUBSCRIPTION_ID_ALREADY_IN_USE) should never happen in a correct implementation. It means you generated the same `partner_reference_id` for two different products, which violates the uniqueness rule.

## Cancel Idempotency

Cancellation is also idempotent:

| Adobe Response | Meaning | Your Action |
|---|---|---|
| 200 | Cancelled | Update your DB → show confirmation |
| 404 | Not found | Already cancelled or never activated → treat as success |
| 409 | Already cancelled | Idempotent → treat as success |

Never show an error to the user for 404 or 409 on cancel — these are valid success states.

## Notify API Idempotency

> Notify payload schema and response codes: see `knowledgebase/api-spec/notify-api.md`. This section covers only the **dedup-key strategy**.

Adobe may deliver the same Notify event more than once (for resilience). Your endpoint must handle this:

```
On receiving notify for (partner_subscription_id, status, timestamp):
  if already processed this exact (id, status, timestamp):
    return 200 immediately  ← do not re-process
  else:
    process event
    record as processed
    return 200
```

Store processed events with enough uniqueness to prevent reprocessing: `(partner_subscription_id, status, timestamp)` is sufficient.

## Summary Table

| API Call | Retry Safe? | Duplicate Handling |
|---|---|---|
| POST /v1/workflows (same ID, same offer, not fulfilled) | Yes | Returns same experience_url |
| POST /v1/workflows (same ID, same offer, fulfilled) | Returns 409 — navigate to status | Not a retry — subscription exists |
| GET /v1/subscriptions | Always safe | Read-only |
| POST /v1/subscriptions (cancel), 409 | Yes | Already cancelled — success |
| POST /v1/subscriptions (cancel), 404 | Yes | Not found — treat as success |
| Notify callback (duplicate) | Yes | Return 200, skip processing |
