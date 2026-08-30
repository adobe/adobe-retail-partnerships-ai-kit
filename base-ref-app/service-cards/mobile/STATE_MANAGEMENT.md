# State Management — mobile (Partner Ref App)

> _Client-side state for the Flutter surface in `base-ref-app/lib`._

## Overview

- **State library:** Riverpod (`flutter_riverpod: ^3.3.2`), using the
  `Notifier`/`NotifierProvider` API (not the `@riverpod` codegen annotation —
  `pubspec.yaml` does not include `riverpod_annotation`/`riverpod_generator`,
  so generated code must NOT introduce codegen providers; follow the manual
  `Notifier` pattern below).
- **Store count:** 1 (`sessionProvider`). `routerProvider` (`lib/app.dart`) is
  also a `Provider<GoRouter>` but it's routing config, not app state.

## 1. Session Store

- **State shape:** `Session? { token: String, userId: String, partnerId: String }` (`lib/models/session.dart`)
- **Actions:** `signIn(Session)`, `signOut()` (`SessionNotifier` in `lib/features/session/session_provider.dart`)
- **Init:** `SessionNotifier.build()` returns `null` (signed out) by default;
  `lib/main.dart` restores a persisted session (if any, not expired) into the
  provider **before** `runApp()` via a `ProviderContainer` read of
  `sessionStorageProvider.load()`, so a page refresh doesn't bounce the user to
  `/login`.
- **Persistence:** persisted — every `signIn`/`signOut` call also calls
  `SessionStorage.save()`/`.clear()` (`ref.read(sessionStorageProvider)`).

## Session Seed for partner_reference_id

> _This surface does NOT mint the id from Adobe — it carries the partner's own
> per-user identity, from which the backend derives the id._

- **Session identity source:** `Session.userId` (`lib/models/session.dart`) —
  the user-entered login ID (format `<PARTNER>-<number>`, e.g. `EXAMPLE-001`).
  **Note the naming:** this field is called `userId`, not
  `partnerReferenceId` — it is the app-level session identity only; the
  server-side `partner_reference_id` sent to Adobe is a distinct value the
  backend generates/stores itself (see
  [`../backend/INTEGRATION_CONTEXT.md`](../backend/INTEGRATION_CONTEXT.md)).
  Never conflate the two or send `userId` to Adobe as if it were the reference
  id.
- **Where it is read:** `ref.watch(sessionProvider)?.userId` (see
  `widgets/app_drawer.dart` for an existing read example) or
  `ref.read(sessionProvider)?.userId`.
- **How it is passed to the backend:** implicitly, via the `Authorization:
  Bearer <token>` header once a route validates the JWT server-side (the JWT
  payload itself carries `userId` + `partnerId` — see
  `bff/src/auth/jwtMiddleware.ts`'s `AuthUser`). The client never sends
  `userId`/`partnerId` as an explicit request body field to any future claim
  endpoint — the backend resolves identity from the verified JWT.
- **Notes:** confirmed no `partnerReferenceId` field or naming exists anywhere
  in `lib/` — this app was fixed to use `userId` (not `partnerReferenceId`)
  precisely to avoid this conflation (see `test/services/auth_service_test.dart`
  comment: "no server-side reference id in response").

## Storage Key Registry

| Key | Storage | Contents | TTL |
|---|---|---|---|
| `partners_ref_app_session` | `local` (`shared_preferences`, which is `localStorage` on web) | JSON `Session.toJson()` | until JWT `exp` (checked on load by `SessionStorage.load()`, not proactively enforced) |

## Cache Strategy

- No cached subscription/claim state exists yet (no such feature exists). When
  added, the natural pattern to follow is `SessionNotifier`'s: a Riverpod
  `Notifier` holding the current status, invalidated by re-fetching after
  claim/cancel actions and on return-from-Adobe (per
  [`ROUTES.md`](./ROUTES.md) → Deep-Link handling, which is itself not yet
  implemented).
