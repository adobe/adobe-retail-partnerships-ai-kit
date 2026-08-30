# Default UI Mocks — FS-002 Find Subscription

> These default mocks use **Adobe Express** only as a sample product; the real offered product comes from the mock manifest / Offer profile and may be any Adobe product.

Default mocks for the subscription status screen. Skills use these when no partner mocks are found in the kit root `mocks/`.

## Screens in This Directory

### `status-active.svg`
**Subscription active state**

Shown when Get Subscription API returns `ACTIVE`:
- Green status badge: "Active"
- Product name: the offered product (sample SVG: Adobe Express Premium)
- Start date and expiry date
- "Open <offered product>" primary button (sample SVG copy: "Open Adobe Express")
- "Manage subscription" section with cancel option

### `status-cancelled.svg`
**Subscription cancelled state**

Shown when status is `CANCELLED`:
- Neutral/grey status badge: "Cancelled"
- Historical dates (when it was active)
- "Re-activate <offered product>" CTA (sample SVG copy: "Re-activate Adobe Express Premium")
- Note: "Your access ended on {end_date}"

### `status-not-found.svg`
**Not yet activated (404 from Adobe)**

Shown when Get Subscription API returns 404 (valid business state — subscription not yet activated):
- No badge — neutral informational screen
- Product name and short description
- "Claim <offered product>" CTA → leads to FS-001 (sample SVG copy: "Claim Adobe Express Premium")
- Note: this is NOT an error state

### `status-loading.svg`
**Loading / skeleton state**

Shown while API call is in flight:
- Skeleton cards for status badge, dates, buttons
- No text content visible

### `status-error.svg`
**Error state**

Shown when the status API call fails:
- "Unable to check subscription status"
- "Try again" button
- Last known status shown if available (stale but informative)

### `offer-card-chip.svg`
**The benefit card reflects live subscription state — and the ACTION changes with it**

The same card shows different state, and **the tap target changes accordingly**:
- **Not activated / Cancelled** → the card is a **claim/offer** entry (green "Claim"/"Get started" CTA) → leads to the claim flow (FS-001).
- **Active** → the card is **NOT** a claimable offer. It shows an "Active" chip + a **"Manage"** affordance and taps through to **My Subscription** (`status-active.svg` / FS-002), where the user can open the offered product or cancel. **Do not show a "Claim"/offer CTA when the subscription is already active.**
- **Pending** (after claim, before activation completes) → non-interactive "Pending" chip.

This is the rule for the home/offer surface across the whole kit: **active ⇒ Manage → subscription; otherwise ⇒ Claim.**
