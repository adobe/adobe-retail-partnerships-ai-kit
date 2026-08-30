# FS-002: Find Subscription (Subscription Status)

**Feature:** Display the current status of a user's Adobe subscription.  
**APIs used:** IMS Token, Get Subscription API (`GET /v1/subscriptions/{id}`)  
**Surfaces:** Backend service, Mobile app, Web app

**API contract:** see `knowledgebase/api-spec/get-subscription.md` (response shape, status values, error codes, polling guidance). This spec owns the **UI states and behaviour**.

---

## User Story

> As a partner subscriber who has claimed an Adobe product, I want to see the current status of my subscription from within my carrier app/website, so that I know whether my benefit is active, when it expires, and whether it has been cancelled.

---

## User Flow

```
1. User navigates to "My Benefits" or subscription management section
2. App/web calls backend to get subscription status
3. [Backend] Partner backend calls Get Subscription API
4. User sees subscription status card:
   - ACTIVE: product name, status badge, start date, end date
   - CANCELLED: cancelled status, historical dates
   - NOT_FOUND: "Not yet activated" state with option to claim
5. User can tap/click "Manage" to see cancel option (FS-003)
6. User can tap/click "Open {the offered product}" (e.g. "Open Adobe Express") to launch the product
```

---

## Backend Implementation

### Endpoint to Create

`GET {mount prefix}/subscription` — the exact path is composed from the partner's route mount prefix (see the implementation contract); do not hardcode `/api/adobe/...`, and no `partnerReferenceId` is ever a client-visible parameter. There is **no path parameter** — `partner_reference_id` is resolved server-side from the authenticated session.

**Success response:**
```json
{
  "partner_reference_id": "partner_9876543210_express_20260129",
  "offer_id": "30006514",
  "status": "ACTIVE",
  "start_date": "2026-01-29T00:00:00Z",
  "end_date": "2027-01-28T23:59:59Z"
}
```

**Backend logic:**
1. Get IMS token (from cache)
2. Call Get Subscription API: `GET /retail/v1/subscriptions/{partner_reference_id}`
3. Map response to frontend-friendly DTO
4. On 404: return `{ "status": "NOT_FOUND" }` — not an error state
5. Log: `event=subscription.queried partner_reference_id={id} latency={ms}ms status={code}`

**On 404 response from Adobe:**
- Return HTTP 200 to your frontend with body: `{ "status": "NOT_FOUND" }`
- Do not return 404 to your frontend — this is a valid business state (not yet activated)

---

## Mobile App Implementation

### Screen: Subscription Status Screen

**UI elements (see ui-mocks/defaults/FS-002-find-subscription/ or partner mocks):**

**State: ACTIVE**
- Product logo + name header
- `ACTIVE` status badge (green)
- "Valid until: {end_date formatted}" — e.g. "28 Jan 2027"
- "Activated on: {start_date formatted}"
- "Open {the offered product}" primary button (e.g. "Open Adobe Express") → deep link to the offered Adobe product app
- "Manage subscription" secondary button → leads to FS-003

**State: CANCELLED**
- Product logo + name header
- `CANCELLED` status badge (grey/red)
- "Expired on: {end_date formatted}"
- "Re-activate" CTA → navigates to FS-001 claim flow (must generate new `partner_reference_id`)
- "Learn more" link

**State: NOT_FOUND (not yet activated)**
- "Not yet activated" message
- Offer tile (same as FS-001 offer screen)
- "Claim Now" CTA → navigates to FS-001

**State: Loading**
- Skeleton cards while API call in flight

**State: Error**
- "Unable to check status" with retry button

### Integration with FS-001 Offer Card

The subscription status chip on the FS-001 offer screen (`Status: Active / Unclaimed`) is powered by this API. When the offer screen loads:
1. Call `GET {mount prefix}/subscription` if a `partner_reference_id` exists for this customer
2. Show live status on the offer card
3. If no `partner_reference_id` exists yet → show "Unclaimed"

**State drives the ACTION, not just a chip.** The offer/home entry must switch behaviour by status:
- **LOADING (status not fetched yet)** → show a neutral **"Checking…"** chip (the mocks' loading state) and make the entry **non-interactive**. Do **NOT** show "Not activated" or a Claim CTA while loading — that is false info before the status is known. Resolve to one of the states below only after the fetch completes.
- **ACTIVE** → the entry is **NOT** a claim/offer CTA. Show a **"Manage"** affordance (+ "Active" chip) that navigates to the subscription/manage screen. **Never show "Claim"/"Get started" when already active.**
- **NOT_FOUND / CANCELLED** → show the **claim** CTA (→ FS-001).
- **PENDING** (claimed, awaiting activation) → non-interactive "Pending" chip.
- **ERROR** → show a distinct "couldn't load / retry" affordance — never a default "Not activated".

> **Two clarifications for when only claim + find-subscription are in scope:**
> - **`PENDING` is derived on the client, not returned by this route.** The
>   `find-subscription` backend returns only `ACTIVE` / `CANCELLED` / `NOT_FOUND`
>   (see `find-subscription/implementation.md`). `PENDING` is inferred by the UI
>   during post-claim polling — the user has claimed but Adobe has not yet
>   reported `ACTIVE`. Do not expect a `PENDING` value from the API.
> - **"Manage" must not dead-end if cancel (FS-003) isn't built.** The "Manage"
>   affordance leads to FS-003. If FS-003 is out of scope, do **not** render a
>   button that goes nowhere — show the status detail only (product, validity),
>   or an honest "manage via support" line. Every reachable state must have a
>   working action (the no-dead-end rule).

---

## Web App Implementation

Same states and content as mobile, adapted for web layout. Subscription status card is prominent on the benefits/rewards page.

---

## Polling Strategy Post-Claim

After the user returns from Adobe's `experience_url` (deep link / URL param return), poll to confirm activation:

```
1. Call GET {mount prefix}/subscription
2. If status is ACTIVE → show activation confirmation
3. If status is NOT_FOUND or still pending:
   - Wait 3 seconds, retry (up to 5 times)
4. If still not ACTIVE after 5 polls:
   - Show: "Your activation is being processed. Check back shortly."
   - Do not show an error — processing can take a few minutes
```

---

## Acceptance Criteria

- [ ] ACTIVE state displays correctly with formatted dates
- [ ] CANCELLED state displays correctly with re-activate option
- [ ] NOT_FOUND (404 from Adobe) shows "Not yet activated" — not an error
- [ ] Post-claim return polls and shows activation confirmation when ACTIVE
- [ ] "Open {the offered product}" button (e.g. "Open Adobe Express") correctly deep-links to the offered Adobe product
- [ ] Loading skeleton shown during API call
- [ ] Error state shown with retry button on network/5xx failure
- [ ] Subscription status chip on offer card (FS-001) reflects live status

---

## UI Mock References

- `mocks/<partner>/` (partner mocks, preferred if provided — the screens tagged `benefits`/`manage` in the manifest's Screens table)
- `knowledgebase/ui-mocks/defaults/FS-002-find-subscription/status-active.svg`
- `knowledgebase/ui-mocks/defaults/FS-002-find-subscription/status-not-found.svg`

---

## Related

- `api-spec/get-subscription.md` — full Get Subscription spec
- `FS-001-claim-product.md` — claim flow (entry point to subscription)
- `FS-003-cancel-subscription.md` — cancellation (reachable from this screen)
- `FS-004-notify-receiver.md` — push-based alternative to polling
