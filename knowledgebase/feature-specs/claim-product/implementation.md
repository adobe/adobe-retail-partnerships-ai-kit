# Implementation contract — claim-product (FS-001)

Feature-specific hardening for `/implement-feature claim-product`. The generic
protocol and cross-cutting rules are in the skill; this file owns the WHAT that is
unique to the claim flow. Feature spec: `../FS-001-claim-product.md`. API:
`../../api-spec/workflow-api.md`. Patterns: `../../integration-patterns/idempotency.md`.

## Backend route

Full path = `{mount prefix from CONTRACTS.md}/claim` (e.g. if routes mount at `/api`, then `POST /api/claim` — NOT `/api/adobe/claim`).

**Request body:** empty. All context (`partner_reference_id`, `offer_id`) is resolved server-side from the authenticated session — the client sends no `partner_reference_id`.

**Logic:**
1. Resolve `partner_reference_id` server-side from the partner's store keyed by `(userId, offerId)`: if a non-CANCELLED record exists, reuse its `partnerReferenceId`; else generate a new one and persist it **before** calling Adobe. Use the format recorded in `service-cards/backend/INTEGRATION_CONTEXT.md` ("Where `partner_reference_id` Is Stored" → Format) — a fresh UUID is only the kit's illustrative default when the partner has no existing convention and none was specified; if that field is still `TODO`, STOP and ask the partner (verification rule 8) rather than assuming UUID.
2. Resolve `offer_id` as the cards describe (per-partner config e.g. `partners.json` → `offerId`, or a single env var); never hardcode.
3. Call `retailApiClient.initiateWorkflow(partner_reference_id, offerId)`.
4. On **202**: return `{ experience_url, partner_reference_id }`.
5. On **409 `ALREADY_FULFILLED`** (Adobe): return `{ error: "ALREADY_ACTIVATED", experience_url: null }`, HTTP 409.
6. On **400 `INVALID_OFFER`** (Adobe): return `{ error: "OFFER_UNAVAILABLE" }`, HTTP 400.
7. On **403 / 5xx** (Adobe): return `{ error: "SERVICE_UNAVAILABLE" }`, HTTP 503.

Backend error codes must match FS-001: `ALREADY_ACTIVATED`, `OFFER_UNAVAILABLE`, `SERVICE_UNAVAILABLE`.

## Mobile / native

Default mocks: `../../ui-mocks/defaults/FS-001-claim-product/` — states `offer-detail`, `offer-activating`, `activation-confirmed`, `offer-already-active`, `offer-error`.

**Offer Detail screen** — reproduce `offer-detail.svg` (hero offer card, "What you get" benefit tiles title+subtitle, full-width CTA) and each state to its SVG. Elements: product name, description, benefit tiles, "Claim Now". On tap: loading → `POST {mount}/claim` → open `experience_url`. On `ALREADY_ACTIVATED`: navigate to subscription status screen. On error: inline error + retry.

**Activation Confirmation screen** — shown on deep-link return: "You're all set!" + details; "Open {offered product}" button (use the offer name — not Adobe Express); "View subscription details" link.

**PENDING / INITIATED (no dead-end):** reachable (user claimed then closed the Adobe tab). No dedicated SVG, but both the home/offer entry card and the offer-detail screen must keep a working "Continue setup" / "Try again" CTA that re-calls the claim action (idempotent while not CANCELLED — same `partner_reference_id`, fresh `experience_url`). Static "Setting up…" text with no tap target is a bug.

## Web

Same UX as mobile. On web, open `experience_url` in a **new tab**
(`webOnlyWindowName: '_blank'`) while the current tab navigates to the
activation-confirmation screen (which polls for ACTIVE) — this keeps the partner
app in place instead of navigating away from it. Return via
`?adobe_activated=true` if deep links aren't available. Note: because the open
happens after the async claim call, a browser may block the `_blank` popup; if
so, present a visible "Open {offered product}" button (a direct click is never
blocked) as the fallback.

## Report reminders

- **⚠️ Action required — set the real `offer_id`:** name the exact file/field (e.g. `bff/partners.json` → `offerId`, or `ADOBE_OFFER_ID` in `bff/.env`) and its current placeholder. Any sample offer fails with `INVALID_OFFER` against real Adobe — it must be the partner's Adobe-assigned offer.
- Deep-link return URL must be registered with Adobe at onboarding.
- State which `partner_reference_id` format was used and whether it came from the partner's own convention or the kit's illustrative UUID default.
