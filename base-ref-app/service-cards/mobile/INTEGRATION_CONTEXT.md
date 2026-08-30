# Integration Context — mobile (Partner Ref App)

> _Where the Adobe integration lives for the Flutter surface. This is the
> feature-less base app — none of the lifecycle steps exist yet; this card
> records where they should go._

## Integration Points on This Surface

| Lifecycle step | Screen / Route | File |
|---|---|---|
| Claim flow | not yet implemented — natural host is `HomeScreen` or a new `lib/features/claim/claim_screen.dart` | `lib/features/home/home_screen.dart` (placeholder today) |
| Manage / subscription status | not yet implemented | — |
| Cancel flow | not yet implemented | — |

## Session Seed for partner_reference_id

- **Identity source:** `Session.userId` (`lib/models/session.dart`) — see
  [`STATE_MANAGEMENT.md`](./STATE_MANAGEMENT.md) → Session Seed for the full
  explanation of why this is named `userId`, not `partnerReferenceId`.
- **Carried to backend via:** the session JWT (`Authorization: Bearer` header)
  once an authenticated route validates it server-side via
  `bff/src/auth/jwtMiddleware.ts`'s `requireAuth` — not via an explicit request
  body field.
- **Notes:** the backend, not this surface, resolves/generates the actual
  `partner_reference_id` — see
  [`../backend/INTEGRATION_CONTEXT.md`](../backend/INTEGRATION_CONTEXT.md).

## Deep-Link / Return-from-Adobe Model

- **Hand-off mechanism:** not yet implemented — no `experience_url`
  launch/redirect code exists (`url_launcher` is a dependency in
  `pubspec.yaml` but is not yet used anywhere in `lib/`, confirmed by
  inspection — it is available for this future purpose).
- **Return route / scheme:** not yet configured — see
  [`ROUTES.md`](./ROUTES.md) → Deep-Link / Return-from-Adobe Handling.
- **Post-return behavior:** not yet implemented.

## Partner Backend This Surface Calls

- **Backend surface / repo:** `base-ref-app/bff` — same monorepo as this
  surface (`base-ref-app/`), not a separate repo.
- **Base URL config key:** `BFF_BASE_URL` dart-define →
  `AppConfig.bffBaseUrl` (`lib/core/config.dart`) — never hardcoded.
- **Notes:** this app's `mobile` and `web` surfaces are the **same Flutter
  codebase** compiled to different targets (see
  [`../web/UI_SERVICE_CARD.md`](../web/UI_SERVICE_CARD.md)'s pointer) — both
  call the same BFF via the same `AuthService`/`AppConfig`.
