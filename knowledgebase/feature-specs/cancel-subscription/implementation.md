# Implementation contract — cancel-subscription (FS-003)

Feature-specific hardening for `/implement-feature cancel-subscription`. Feature
spec: `../FS-003-cancel-subscription.md`. API: `../../api-spec/update-subscription.md`.
Patterns: `../../integration-patterns/idempotency.md` (especially cancel idempotency).

## Backend route

Full path = `POST {mount prefix}/subscription/cancel` (e.g. `POST /api/subscription/cancel`). Do **NOT** add a path parameter for `partnerReferenceId` — resolved server-side from the session.

**Logic:**
1. Resolve `partner_reference_id` server-side (`store.getCurrent(userId, offerId)` — same store as claim/find). If no non-CANCELLED record → return idempotent success `200 { status: "CANCELLED" }`.
2. Extract `reason_code` from body (`USER_CANCELLED` | `NOT_ELIGIBLE`; default `USER_CANCELLED`).
3. Call `retailApiClient.cancelSubscription(partner_reference_id, reason_code)`.
4. On success: **call `store.updateStatus(partnerReferenceId, 'CANCELLED')` to retire the id** so the NEXT claim mints a brand-new unique id — re-activation must never reuse a cancelled id (uniqueness invariant) — then return Adobe's result.
5. On 404/409 from Adobe: `retailApiClient.cancelSubscription` already maps these to idempotent success internally; still call `store.updateStatus` to keep local state consistent, then return the result.
6. On 5xx: the client retries up to 3×; propagate HTTP 503 if all fail.
7. Log: `event=subscription.cancel_requested reason={code} outcome=CANCELLED`.

## Mobile / native

Default mocks: `../../ui-mocks/defaults/FS-003-cancel-subscription/` — states `cancel-dialog`, `cancel-processing`, `cancel-confirmed`, `cancel-error`. Use the partner's existing dialog/bottom-sheet component — never a new dialog library.

**Cancellation is IMMEDIATE** — never promise access "until {end_date}".

**Confirmation dialog / bottom sheet** (triggered from FS-002 manage screen):
- Title: "Cancel {offered product}?" (offer name — not Adobe Express).
- Body: "Cancelling ends your {offered product} access immediately. This can't be undone."
- Destructive "Cancel subscription" button + "Keep subscription" dismiss.
- On confirm: loading → call backend cancel route.

**Cancellation confirmation screen:** "Subscription cancelled" heading; "Your access has ended." (no continued-access/end_date copy); "Re-activate later" link; "Done" → home/rewards.

**Post-cancellation:** in the re-activate path, add a comment that a new `partner_reference_id` is required after cancellation; the re-activate button navigates to the claim flow (FS-001) where a new id is generated.

## Web

Same UX via the partner's existing modal component.

## Report reminders

Confirmed/dialog copy must use **immediate-cancellation** wording (verify against the mock SVGs). Note mocks used. Suggest running `/implement-feature notify-handler` next.
