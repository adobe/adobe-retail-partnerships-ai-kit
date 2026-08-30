# FS-004: Notify API Receiver

**Feature:** Partner-hosted webhook that Adobe calls to push subscription lifecycle events.  
**APIs used:** Notify API (Adobe → Partner)  
**Surfaces:** Backend service only (no mobile/web UI — events update your database, which drives the UI in FS-002/FS-003)

**API contract:** see `knowledgebase/api-spec/notify-api.md` (payload schema, status values, response codes). This spec covers only the receiver **behaviour** — validation order, idempotency, processing, and the onboarding checklist.

---

## User Story

> As a partner system, I want to receive real-time notifications from Adobe when a subscription is activated, cancelled, or renewed, so that my system stays in sync with Adobe entitlements without having to poll continuously.

---

## When Adobe Calls Your Endpoint

| Trigger | Payload `status` |
|---|---|
| User completes activation on Adobe experience UI | `"Active"` |
| Subscription cancelled (user-initiated via Adobe) | `"Cancelled"` |
| Subscription renewed | `"Active"` (renewed dates) |

---

## Backend Implementation

### Endpoint to Create

The partner-registered inbound path — composed from `CONTRACTS.md`, e.g. `{mount prefix}/webhooks/notify` for Express stacks (see the implementation contract for how the path is derived per stack). **Never assume `/api/adobe/notify`** — the exact path is whatever the partner registers with Adobe at onboarding.

This endpoint is called **by Adobe**, not by your frontend. It must be:
- Publicly accessible (or accessible from Adobe's egress IPs — provide these during onboarding)
- HTTPS only
- Responding within 10 seconds
- Idempotent

### Request Validation

```
1. Validate auth credentials for the type you registered at onboarding — one of `STATIC`, `BASIC`, `CUSTOM_HEADERS`, `OAUTH2_CLIENT_CREDENTIALS`, `CUSTOM_TOKEN` (see `api-spec/notify-api.md`)
   → Return 401 if invalid
2. Validate required fields: partner_subscription_id, status, timestamp
   → Return 400 if malformed
3. Check for duplicate: (partner_subscription_id, status, timestamp) already processed
   → Return 200 immediately if duplicate (idempotent)
4. Process event
5. Return 200
```

### Request Body (from Adobe)

Payload schema (fields, types, `status` values) is defined in `knowledgebase/api-spec/notify-api.md`. Validate `partner_subscription_id`, `status`, and `timestamp` are present before processing.

### Processing Logic

**On `status = "Active"`:**
- Find the subscription record by `partner_subscription_id` (= `partner_reference_id`)
- Update status to ACTIVE
- Update `startDate` and `endDate`
- Optionally: trigger push notification to user ("Your {offered product} is now active!" — e.g. "Your Adobe Express is now active!")

**On `status = "Cancelled"`:**
- Find the subscription record
- Update status to CANCELLED
- Update `endDate`
- Optionally: trigger push notification to user ("Your {offered product} subscription has ended" — e.g. "Your Adobe Express subscription has ended")

**On subscription not found locally:**
- Log with warning: subscription received notify for unknown `partner_subscription_id`
- Still return 200 — do not fail Adobe's call for a local data inconsistency

### Response Codes

See `knowledgebase/api-spec/notify-api.md` for the full response-code contract (200 / 400 / 401 / 5xx and Adobe's retry behaviour).

### Idempotency Implementation

Store a processed events log. Before processing any event, check if `(partner_subscription_id, status, timestamp)` has already been processed:

```sql
-- Example schema addition
CREATE TABLE adobe_notify_events (
  id              SERIAL PRIMARY KEY,
  subscription_id VARCHAR(255) NOT NULL,
  status          VARCHAR(50)  NOT NULL,
  event_timestamp TIMESTAMPTZ  NOT NULL,
  received_at     TIMESTAMPTZ  DEFAULT NOW(),
  UNIQUE (subscription_id, status, event_timestamp)
);
```

On duplicate insert (unique constraint violation): return 200 without reprocessing.

### Async Processing (Recommended)

For low latency and reliability:

```
POST {mount prefix}/webhooks/notify received
  │
  ├─ Auth check → 401 if invalid
  ├─ Body validation → 400 if malformed
  ├─ Write to notify_events table (dedup key)
  │     → 200 immediately if duplicate
  ├─ Enqueue to background worker queue
  └─ Return 200 OK

Background worker:
  ├─ Update subscription status in main DB
  ├─ Trigger push notifications (optional)
  └─ Log completion
```

---

## Demo/Testing Screen (Optional — for Reference App)

The Partner Reference App includes a real-time Notify event feed screen to demonstrate that the callback is being received. This is for demo purposes and does not need to be implemented in production partner apps.

**If implementing the demo feed:**
- Backend: after processing event, push to a server-sent events (SSE) stream
- Frontend: connect to SSE stream, display events in a live feed list
- Shows: subscription ID, status, timestamps, received-at

---

## Onboarding Checklist

Before Adobe can call your Notify endpoint:
- [ ] Endpoint deployed and publicly accessible (HTTPS)
- [ ] Auth type decided — one of `STATIC`, `BASIC`, `CUSTOM_HEADERS`, `OAUTH2_CLIENT_CREDENTIALS`, `CUSTOM_TOKEN`
- [ ] Auth credentials shared with Adobe partner engineering
- [ ] Stage: Adobe's egress IPs added to your allowlist
- [ ] Test `partner_subscription_id` provided to Adobe for integration testing
- [ ] Idempotency logic implemented and tested

---

## Testing Your Endpoint

Use the following `curl` to simulate Adobe calling your endpoint (replace
`YOUR_REGISTERED_NOTIFY_PATH` with whatever path you registered with Adobe,
e.g. `/api/webhooks/notify` — never assume `/api/adobe/notify`):

```bash
curl -X POST https://your-backend.example.com/YOUR_REGISTERED_NOTIFY_PATH \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_NOTIFY_SECRET' \
  -d '{
    "partner_subscription_id": "test_sub_001",
    "status": "Active",
    "startDate": "2026-01-29T00:00:00Z",
    "endDate": "2027-01-28T23:59:59Z",
    "timestamp": "2026-01-29T10:30:00Z"
  }'
```

Expected response: `200 OK`

Re-run the same command to verify idempotency — should return `200 OK` without creating a duplicate record.

---

## Acceptance Criteria

- [ ] Endpoint accessible via HTTPS from Adobe's egress IPs
- [ ] Auth validation: 401 returned for invalid credentials
- [ ] Body validation: 400 returned for missing required fields
- [ ] On `status: "Active"`: local subscription record updated to ACTIVE with correct dates
- [ ] On `status: "Cancelled"`: local subscription record updated to CANCELLED
- [ ] Duplicate call (same `partner_subscription_id` + `status` + `timestamp`): returns 200 without reprocessing
- [ ] Unknown `partner_subscription_id`: returns 200 (logged as warning, not error)
- [ ] Response within 10 seconds on all valid requests
- [ ] All events logged with: `partner_subscription_id`, `status`, `timestamp`, `duplicate`, `received_at`

---

## Environment Variables Required

Config depends on the registered auth type (see `api-spec/notify-api.md` → Environment Variables): `STATIC` uses a secret such as `ADOBE_NOTIFY_AUTH_SECRET`; `BASIC`/`CUSTOM_HEADERS` use the registered credential(s); `OAUTH2_CLIENT_CREDENTIALS`/`CUSTOM_TOKEN` need no Adobe-specific secret (you validate your own token). See the loading/validation pattern in `knowledgebase/integration-patterns/environment-config.md`.

---

## Related

- `api-spec/notify-api.md` — full Notify API specification
- `FS-002-find-subscription.md` — subscription status UI (driven by notify events)
- `integration-patterns/security.md` — auth validation and credential management
- `integration-patterns/idempotency.md` — duplicate handling
