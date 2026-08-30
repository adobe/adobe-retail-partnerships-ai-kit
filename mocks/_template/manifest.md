# Mock Manifest — <PARTNER NAME>

> The spec the kit reads to turn your screenshots into a working, branded app. Fill what you can; anything left blank is auto-detected from your screens. Delete the `<…>` placeholders. Keep the completed file at `mocks/<partner>/manifest.md`.

## 1. Partner
- **Name:** <e.g. Acme Telco>
- **Wordmark** (if different from your name): <optional>
- **Surfaces requested:** <web | iOS | android | any combination>
- **Offered Adobe product:** <e.g. Adobe Express, Photoshop, Lightroom, Acrobat Pro, Firefly — REQUIRED, drives all product copy>
- **Offer id:** <Adobe-assigned offer_id — REQUIRED before the app can be generated; if you don't have it yet, generation stops here until it's filled in>

## 2. Screens — list them in the order a user sees them
Drop your images in `screens/`, named in order (`slide-1.png`, `slide-2.png`, …), then tag each with a **Role** so the kit knows what it means in your product:

| Role | What it means | Built by the kit? |
|---|---|---|
| `login` | Your sign-in screen. | Optional — skip if you have your own |
| `landing` | Your home screen right after login. Exactly one. | Yes, reproduced faithfully |
| `offer` | Where the Adobe offer is shown **before** it's claimed (a card, tile, or page). | Yes, CTA wired to claim |
| `benefits` | Where a **claimed/active** subscription appears as something the user owns (e.g. your "Your Benefits" area). | Yes, reflects live status |
| `manage` | Where the user views details / cancels. May be the same screen as `benefits`. | Yes, if cancel should be reachable |
| `other` | Any screen with no Adobe role. | Reproduced for fidelity, no wiring |
| `adobe-hosted` | Screens **Adobe itself** serves (redeem / consent / sign-in / the product). | Never — the app only redirects here |

| File | Role | What you call it |
|---|---|---|
| `screens/slide-1.png` | `landing` | <e.g. "My Dashboard"> |
| `screens/slide-2.png` | `offer` | <e.g. "Perks"> |
| `screens/slide-3.png` | `benefits` | <e.g. "Your Benefits"> |

Tapping the offer's CTA opens Adobe's own redeem/consent/sign-in flow directly — no in-app screen is built for the `adobe-hosted` step; the app only handles the return.

## 3. Your words (so copy uses YOUR terms, not "Adobe")
- **You call the offer:** <e.g. "Perks" / "Rewards" / "Member Offers">
- **You call an owned/active benefit:** <e.g. "Your Benefits" / "My Subscriptions">
- **CTA label to start a claim:** <e.g. "Get started" / "Claim now" / "Activate">
- Adobe branding shows **only** on the offer card itself (its logo/name) — every heading and status label stays in your wording.

## 4. Brand — optional, auto-detected from your screenshots if left blank
Only fill these in if you want to override what the kit samples from your images.

| Token | Value |
|---|---|
| Primary (buttons / accent) | `#______` |
| Background | `#______` |
| Font | <name, or leave blank to match your screens> |

- `brand/<logo>.svg` or `.png` — drop your logo here if you have one as a separate file.

## Anything else to know
<e.g. "cancel should also be reachable from a settings menu, even though it's not in these screens" — or leave blank>

## Adobe integration (never touched)
The Adobe wiring (IMS / claim / subscription / cancel / notify) is never changed by any of this — only theme, layout, copy, and assets. When Adobe's Notify webhook fires, the subscription flips to Active and your `benefits` screen reflects it, in your own wording.
