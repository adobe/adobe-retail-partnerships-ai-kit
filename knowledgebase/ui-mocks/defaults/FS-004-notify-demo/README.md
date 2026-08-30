# Default UI Mocks — FS-004 Notify API Demo

> These default mocks use **Adobe Express** only as a sample product; the real offered product comes from the mock manifest / Offer profile and may be any Adobe product.

The Notify API receiver is a **backend-only feature** — there is no user-facing UI that partners need to implement.

However, the reference app includes an optional demo/testing screen that lets partner engineers inspect incoming Adobe webhook events during integration testing.

## Screens in This Directory

### `notify-test-screen.svg`
**Notify event log screen (reference app / development only)**

An internal development tool for partners to verify their Notify endpoint is receiving and processing events correctly:
- List of received Notify events (most recent first)
- Each row: `partner_subscription_id`, `status`, `timestamp`, duplicate flag
- "Simulate event" button to send a test payload to your own endpoint
- Color-coded status: Active (green), Cancelled (red), Duplicate (grey)

**Important:** This screen is for reference app / development use only. Do not include this screen in production partner apps.

## Production Note

For production apps, the Notify API handler is purely backend. What you may choose to surface to users:

1. **Push notification** when status changes to Cancelled — "Your <offered product> has been cancelled. [Re-activate]" (e.g. "Your Adobe Express Premium has been cancelled.")
2. **Update offer card status chip** (FS-002) on next app open, driven by local subscription state updated by the Notify handler
3. **Nothing visible** — many partners prefer to handle status sync silently; users only see the updated status when they next open the subscription screen

The choice depends on your app's notification strategy. See FS-002 for the subscription status screen mocks.
