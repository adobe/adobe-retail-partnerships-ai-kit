# Default UI Mocks — FS-001 Claim Product

> These default mocks use **Adobe Express** only as a sample product; the real offered product comes from the mock manifest / Offer profile and may be any Adobe product.

These are the kit's production-quality default mocks for the claim product flow. Skills use these when no partner mocks are found in the kit root `mocks/`.

## Screens in This Directory

### `offer-detail.svg`
**Offer detail / entry point screen**

What the user sees when they navigate to the offered product's offer (sample SVG shows Adobe Express Premium):
- Product name and tagline
- Key benefit tiles (3–4 short bullet points)
- "Claim Now" CTA button (primary, full-width)
- Small print about the subscription
- Loading state: button shows spinner, disabled

### `offer-activating.svg`
**In-progress / redirecting state**

Shown while the backend calls the Workflow API and before redirecting to `experience_url`:
- Full-screen or inline loading indicator
- "Setting up your <offered product>…" message (sample SVG copy: "Setting up your Adobe Express Premium…")
- Progress text (optional)

### `activation-confirmed.svg`
**Activation confirmation (after return from `experience_url`)**

Shown when the user returns via deep link after completing the Adobe activation flow:
- Success state with checkmark or celebration
- "You're all set! <offered product> is now active." (sample SVG copy: "Adobe Express Premium is now active.")
- "Open <offered product>" primary button (sample SVG copy: "Open Adobe Express")
- "View subscription details" secondary link

### `offer-already-active.svg`
**Already activated state**

Shown when the Workflow API returns `ALREADY_FULFILLED`:
- Informational (not error) tone
- "You already have <offered product>" (sample SVG copy: "You already have Adobe Express Premium")
- "View subscription" CTA

### `offer-error.svg`
**Error state**

Shown on API failure:
- Friendly error message
- "Try again" retry button
- Contact support link

## Design Notes

- Partner chrome (top bar, nav, "Done" actions) is intentionally **partner-neutral**: a generic "Partner App" top bar with a neutral blue accent (`#1473E6`). The offered Adobe product (e.g. Adobe Express in these sample SVGs) uses Adobe red (`#EB1000`).
- Add files to the kit root `mocks/` to apply your brand (skills prefer them over these defaults)
- All screens are sized for mobile-first (390×844pt, rounded status bar); adapt for web as needed
