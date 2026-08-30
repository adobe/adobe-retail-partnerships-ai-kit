# Routes — mobile (Partner Ref App)

> _Route registry for the Flutter surface in `base-ref-app/lib`._

## Overview

- **Router:** `go_router` (`lib/app.dart`'s `routerProvider`, a
  `Provider<GoRouter>`)
- **Auth guard mechanism + location:** `GoRouter`'s `redirect:` callback in
  `lib/app.dart` — reads `sessionProvider` (null = signed out) and redirects
  unauthenticated users to `/login`, and signed-in users away from `/login` to
  `/`. A `_RouterRefresh` `ChangeNotifier` re-triggers the redirect whenever
  `sessionProvider` changes (`ref.listen(sessionProvider, ...)`).
- **Root redirect (authenticated):** `/` (`HomeScreen`)
- **Unauthenticated redirect:** `/login` (`LoginScreen`)

## Route Registry

| Path | File | Path params | Auth required | Preconditions |
|---|---|---|---|---|
| `/login` | `lib/features/session/login_screen.dart` | none | no | `sessionProvider == null` (else redirected to `/`) |
| `/` | `lib/features/home/home_screen.dart` | none | yes | `sessionProvider != null` (else redirected to `/login`) |

No other routes exist. There is no deep-link scheme or return-from-Adobe route
registered yet.

## Auth Guard Pattern

- The guard is centralized in `lib/app.dart`'s `routerProvider.redirect`, not
  per-screen — `LoginScreen`/`HomeScreen` do not each check auth themselves.
  On failure (not signed in, not at `/login`) it redirects to `/login`; when
  signed in and at `/login` it redirects to `/`. Any new authenticated route
  added under `GoRoute`s automatically inherits this guard because the
  `redirect` callback runs for every navigation, not per-route.

## Navigation Patterns

- Declarative `GoRoute` list inside `routerProvider` (`lib/app.dart`). New
  screens are added as additional `GoRoute` entries there.
- Programmatic navigation uses `context.go(route)` (see
  `widgets/app_drawer.dart`'s `_DrawerItem.onTap`) — push/replace semantics are
  `go_router`'s default (`go` replaces the current stack entry for that
  location), not manual `Navigator.push`.
- The drawer (`widgets/app_drawer.dart`) is the app-wide navigation surface —
  new features are added as new `_DrawerItem` entries there, consistent with
  its own comment ("New features are added as entries here").

## Deep-Link / Return-from-Adobe Handling

- **Return route / URI scheme:** not configured — no `GoRoute` or platform deep
  link (`android/`, `ios/` configs not scanned in depth, but nothing references
  a return scheme in `lib/`) exists yet.
- **Success vs cancel detection:** `TODO — ASK PARTNER` / not yet designed;
  this will need to be added when the claim flow's `experience_url` hand-off is
  implemented.
- **State re-fetch on return:** not yet implemented — no subscription-status
  fetch exists at all today.
- **Notes:** this is a genuine gap the Fast path's generated LLD must design,
  not an existing pattern to reuse — flag it explicitly rather than inventing
  one silently.
