# FS-001: Claim Product

**Feature:** End-to-end product claim flow — the primary integration feature.  
**APIs used:** IMS Token, Workflow API (`POST /v1/workflows`)  
**Surfaces:** Backend service, Mobile app, Web app

**API contract:** see `knowledgebase/api-spec/workflow-api.md` (request/response/error codes) and `knowledgebase/api-spec/ims-token.md`. This spec owns the **flow, screens, states, and error-UX** — not the Adobe wire contract.

> **Product is a variable.** The offered product below (shown as *Adobe Express Premium* by way of example) is whatever Adobe product this engagement offers — resolved from the mock `manifest.md` (Mode B) or `service-cards/shared/OFFER_PROFILE.md` (Mode A). Never assume Express.

---

## User Story

> As a partner subscriber, I want to claim my Adobe product benefit from within my carrier's app/website, so that I can activate my free subscription for the offered Adobe product (e.g. Adobe Express Premium) without leaving the partner experience.

---

## User Flow

```
1. User navigates to rewards/benefits section of partner app or web
2. User sees Adobe product offer tile (e.g. "Adobe Express Premium — 12 months free")  // label shows the offered product
3. User taps/clicks "Claim" or "Activate"
4. [Backend] Partner backend calls Workflow API → receives experience_url
5. App/web redirects user to experience_url (system browser or webview)
6. [Adobe UI] User signs in or creates Adobe account
7. [Adobe UI] User consents to share activation details with partner
8. [Adobe UI] Adobe provisions the subscription
9. User is redirected back to partner app/web (deep link)
10. App/web shows activation confirmation screen
```

---

## Backend Implementation

### Endpoint to Create

`POST {mount prefix}/claim` — the exact path is composed from the partner's route mount prefix (see the implementation contract); do not hardcode `/api/adobe/claim`.

**Request body (from mobile/web frontend):** empty.

> Both `partner_reference_id` and `offer_id` are resolved **server-side** from the authenticated session — **never sent from the frontend.** (`offer_id` from per-partner config or `ADOBE_OFFER_ID`; `partner_reference_id` from the partner's subscription store — see the implementation contract and `integration-patterns/idempotency.md`.)

**Success response:**
```json
{
  "experience_url": "https://redeem.adobe.com/express-premium?...",
  "partner_reference_id": "partner_9876543210_express_20260129"
}
```

**Backend logic:**
1. Resolve `partner_reference_id` server-side from the partner's subscription store keyed by `(userId, offerId)` — never accept it from the client (see the implementation contract)
2. Get IMS token (from cache or refresh)
3. Call Workflow API: `POST /retail/v1/workflows`
4. On 202: return `experience_url` to frontend
5. Handle all error codes per `api-spec/workflow-api.md`
6. Log: `event=claim.initiated partner_reference_id={id} latency={ms}ms status={code}`

**Error responses from your backend:**
```json
{ "error": "ALREADY_ACTIVATED", "message": "Subscription already active." }      // 409 from Adobe
{ "error": "OFFER_UNAVAILABLE", "message": "Offer is not available." }           // 400 INVALID_OFFER
{ "error": "SERVICE_UNAVAILABLE", "message": "Please try again later." }         // 5xx / 403
```

### `partner_reference_id` Generation

Generate in your backend, not on the frontend. **There is no fixed format** — check the partner's codebase for an existing customer/order ID convention first, and use it if one exists; if none exists or it's unclear, ask the partner (see `knowledgebase/integration-patterns/idempotency.md`). The composite string below is an **illustrative fallback only** — the shape this base app and any generation without a partner answer default to, not a format to recommend to a real partner:
```
{partner_prefix}_{customer_id}_{product_code}_{date}
```
Store it alongside the customer's account record. It is the link between your system and Adobe's subscription.

---

## Mobile App Implementation

### Screen: Offer Detail Screen

Displays the Adobe product offer before the user confirms the claim.

**UI elements (see ui-mocks/defaults/FS-001-claim-product/ or partner mocks):**
- Product logo / hero image
- Product name of the offered Adobe product (e.g. "Adobe Express Premium")
- Offer description (e.g. "12 months free — worth ₹4,000")
- Benefit tiles: key product features (3–4 items)
- "Claim Now" / "Activate" CTA button — **shown only when the subscription is NOT already active** (status NOT_FOUND / CANCELLED, from FS-002)
- Subscription status chip (if subscription already exists — pull from FS-002)
- **If the subscription is already ACTIVE:** do **not** show the Claim/Activate CTA. Replace it with a **"Manage"** action that navigates to the subscription/manage screen (FS-002/FS-003) — the offer entry becomes a Manage entry, not a claim entry.

**On "Claim Now" tap:**
1. Show loading state on button
2. Call partner backend `POST {mount prefix}/claim` with an **empty body** (`partner_reference_id` is resolved server-side — never sent from the client)
3. On success: open `experience_url` in system browser (preferred) or in-app webview
4. On 409 ALREADY_ACTIVATED: navigate to subscription status screen (FS-002)
5. On error: show inline error with retry option

### Screen: Activation Confirmation

Shown when user returns from `experience_url` via deep link.

- "You're all set!" heading
- "Your {offered product} is now active" message (e.g. "Your Adobe Express Premium is now active")
- "Start using {the offered product}" button (e.g. "Start using Adobe Express") → opens the offered Adobe product app or web
- "View subscription details" link → navigates to FS-002

### Deep Link Handling

Configure a deep link (e.g. `yourapp://adobe/activated`) as the return URL. Register it with Adobe during onboarding. On deep link receipt:
1. Dismiss webview if open
2. Navigate to Activation Confirmation screen
3. Trigger one GET subscription call to confirm activation status

---

## Web App Implementation

Same UX as mobile, adapted for browser. Key differences:
- Open `experience_url` in a **new tab** (`_blank`); the current tab moves to the activation-confirmation screen and polls for ACTIVE, so the partner app is never navigated away from. If the browser blocks the popup (the open follows an async call), fall back to a visible "Open" button — a direct click is never blocked.
- Handle return via URL query param `?adobe_activated=true` if deep links are not available on web
- Responsive layout: works on both desktop and mobile-web

---

## Acceptance Criteria

- [ ] Claim flow completes end-to-end against Adobe stage environment
- [ ] 409 ALREADY_FULFILLED → user is taken to subscription status, not shown an error
- [ ] 403 from Adobe → full-screen error shown (not a toast)
- [ ] 5xx from Adobe → retry up to 3 times with backoff before showing error
- [ ] IMS token is refreshed if expired, never exposed to frontend
- [ ] `partner_reference_id` is stored and associated with the customer in partner's system
- [ ] All API calls logged with `partner_reference_id`, latency, and response code
- [ ] Deep link return from Adobe experience UI handled correctly
- [ ] Loading states shown during API call (button disabled, spinner visible)

---

## UI Mock References

- `mocks/<partner>/` (partner mocks, preferred if provided — the screen tagged `offer` in the manifest's Screens table)
- `knowledgebase/ui-mocks/defaults/FS-001-claim-product/offer-detail.svg`
- `knowledgebase/ui-mocks/defaults/FS-001-claim-product/activation-confirmed.svg`

---

## Related

- `api-spec/ims-token.md` — token acquisition
- `api-spec/workflow-api.md` — full Workflow API spec
- `integration-patterns/idempotency.md` — `partner_reference_id` rules
- `integration-patterns/error-handling.md` — all error code mappings
- `FS-002-find-subscription.md` — subscription status (linked from this flow)
