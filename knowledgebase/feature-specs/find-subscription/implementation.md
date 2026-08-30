# Implementation contract — find-subscription (FS-002)

Feature-specific hardening for `/implement-feature find-subscription`. Feature
spec: `../FS-002-find-subscription.md`. API: `../../api-spec/get-subscription.md`.

## Backend route

Full path = `{mount prefix}/subscription` (e.g. `GET /api/subscription`). Do **NOT**
add a path parameter for `partnerReferenceId` — the server resolves it from the
authenticated session using the partner's store (same pattern as the claim route).
Never expose the internal `partnerReferenceId` as a URL path param — it is an
opaque server-side detail.

**Logic:**
1. Resolve `partner_reference_id` server-side (`store.getCurrent(userId, offerId)`). If no record → return `{ status: "NOT_FOUND" }`, HTTP 200, without calling Adobe.
2. Call `retailApiClient.getSubscription(partner_reference_id)`.
3. On `null` (404 from Adobe) → return `{ status: "NOT_FOUND" }`, HTTP **200** (not 404).
4. On subscription found → return the full subscription object (pass through from Adobe).
5. On error → return `{ error: "STATUS_UNAVAILABLE" }`, HTTP 503.

**This route always returns HTTP 200 to the frontend.** `NOT_FOUND` is a valid business state, not an HTTP error.

## Mobile / native

Default mocks: `../../ui-mocks/defaults/FS-002-find-subscription/` — states `status-active`, `status-cancelled`, `status-not-found`, `status-loading`, `status-error`, plus `offer-card-chip` (the live-status chip on the offer entry). Reproduce each to its SVG (structure, copy, badges), all driven by the same data source.

- **ACTIVE:** status badge, product name, "Valid until {end_date}", "Open {offered product}" button (offer name — not Adobe Express), "Manage" → FS-003. **If FS-003 (cancel) is not in scope, omit the "Manage" button rather than linking to nothing** — show status detail only (no-dead-end rule).
- **CANCELLED:** cancelled badge, historical dates, "Re-activate" CTA → FS-001.
- **NOT_FOUND:** "Not yet activated", offer tile, "Claim Now" → FS-001.
- **PENDING** is **not** a value this route returns (it returns only `ACTIVE`/`CANCELLED`/`NOT_FOUND`); the UI derives "pending" while polling after a claim, before Adobe reports `ACTIVE`.
- **Loading:** skeleton cards. **Error:** "Unable to check status" + retry.

Also update the FS-001 offer screen's **status chip** to call the `subscriptionProvider` and show live status. For Flutter/Riverpod expose a derived `subscriptionStatusChipProvider` (`Provider<SubscriptionStatus?>`) that reads the subscription state; the claim screen watches it.

**Post-claim polling:** when arriving here after a successful claim (deep-link return), poll-until-active per the feature spec (up to 5 polls, 3-second interval). In Flutter, trigger from `initState` with a `Future.delayed(Duration(seconds: 3), …)` loop + max-attempt counter.

## Web

Same states as mobile, web layout — subscription status card on the benefits/rewards page.

## Report reminders

Note which mocks were used. Suggest running `/implement-feature cancel-subscription` next.
