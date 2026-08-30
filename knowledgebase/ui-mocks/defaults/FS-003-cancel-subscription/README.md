# Default UI Mocks — FS-003 Cancel Subscription

> These default mocks use **Adobe Express** only as a sample product; the real offered product comes from the mock manifest / Offer profile and may be any Adobe product.

Default mocks for the cancel subscription flow. Skills use these when no partner mocks are found in the kit root `mocks/`.

## Screens in This Directory

### `cancel-dialog.svg`
**Cancellation confirmation dialog / bottom sheet**

Triggered from the subscription management screen when user taps "Cancel subscription":
- Bottom sheet (mobile) or modal (web)
- Title: "Cancel <offered product>?" (sample SVG copy: "Cancel Adobe Express Premium?")
- Body copy: "Your access ends immediately. This can't be undone."
- "Cancel subscription" — destructive red button (confirms cancellation)
- "Keep my subscription" — dismiss/secondary button
- Both buttons clearly visible and accessible

### `cancel-processing.svg`
**In-progress state**

Shown while the cancel API call is in flight:
- Loading spinner on the confirm button
- Buttons disabled
- No dismiss until complete

### `cancel-confirmed.svg`
**Cancellation confirmed screen**

Shown after successful cancellation:
- Confirmation message: "Your subscription has been cancelled"
- "Your access ends immediately"
- "Done" button → return to home/rewards
- "Re-activate later" subtle link

### `cancel-error.svg`
**Error state**

Shown when cancel API call fails after retries:
- "Something went wrong. Your subscription is still active."
- "Try again" button
- Contact support link
