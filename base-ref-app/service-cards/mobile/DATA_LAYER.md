# Data Layer — mobile (Partner Ref App)

> _How the Flutter surface in `base-ref-app/lib` talks to its backend._

## Overview

- **Data-fetch library:** `dio` (`lib/services/auth_service.dart`'s
  `AuthService` wraps a `Dio` instance; `pubspec.yaml` `dio: ^5.9.0`)
- **Auth-token injection:** none yet for outbound requests — `AuthService`
  today only calls the unauthenticated `/api/auth/login` endpoint. No
  interceptor attaches `Authorization: Bearer <token>` to any request yet
  because no authenticated backend call exists in this app.
- **Freshness policy:** always-fresh — no caching layer wraps Dio calls.
- **Error surface:** `AuthService.login()` catches `DioException` and rethrows
  a typed `AuthException` with a user-facing message (401 → "Invalid user ID";
  anything else → generic "Login failed. Please try again.");
  `LoginScreen._submit()` catches `AuthException` (and any other error) and
  shows a `SnackBar`.

## Read Layer — Registry

| Domain | Read Unit | Endpoint (partner backend) | Auth Injection |
|---|---|---|---|
| *(none yet — see Write Layer; login is the only implemented call and it's a write/action, not a read)* | | | |

## Write Layer

| Domain | Write Unit | Endpoint (partner backend) | Auth Injection |
|---|---|---|---|
| Auth | `AuthService.login(userId)` | `POST /api/auth/login` | none (this IS the auth call) |

No claim/cancel writes exist yet.

## Auth Token Injection

- Not yet implemented for authenticated calls — there is no Dio interceptor in
  this codebase. When a future authenticated route is added (e.g. claim), it
  should attach `Authorization: Bearer <sessionProvider token>` — the token is
  available via `ref.read(sessionProvider)?.token` (Riverpod), matching how
  `LoginScreen`/`AppDrawer` already read `sessionProvider`. There is no
  existing interceptor file to extend; one would need to be added to
  `AuthService` (or a shared Dio client) as new authenticated calls are
  introduced.

## Error Handling Posture

- `AuthService` classifies only by DioException status code today (401 vs
  anything else) — there is no existing "integration not configured" vs
  "upstream error" distinction because no Adobe-backed call exists yet. A
  generated claim/subscription/cancel service must add that distinction fresh
  (per [verification rule 3](../../../manual/methodology/verification.md)), following
  `AuthService`'s pattern of a typed exception class + a `catch (DioException)`
  branch on status code.

## Backend-Proxy Rule

> **This UI NEVER calls Adobe directly.** Confirmed true today — the only
> remote call in `lib/` targets the BFF (`AppConfig.bffBaseUrl`), never an
> Adobe hostname. No IMS/Retail hostnames or `*_CLIENT_SECRET` strings appear
> anywhere in `lib/` (verified by inspection of every file in `lib/`).

- **Partner backend base URL (config key):** `BFF_BASE_URL` dart-define, read
  via `AppConfig.bffBaseUrl` in `lib/core/config.dart` (defaults to
  `http://localhost:8080`; set via `dart_defines.env`, see
  `dart_defines.example.env`).
- **Confirmation:** grep of `lib/` for Adobe/IMS hostnames and secret names →
  **empty** (no matches) — confirmed clean.

## Adding a New Read Unit — Checklist

- [ ] Endpoint points at the partner backend (`AppConfig.bffBaseUrl`), never Adobe.
- [ ] Path matches the backend route character-for-character ([rule 2](../../../manual/methodology/verification.md)).
- [ ] Auth token injected via `ref.read(sessionProvider)?.token` (no existing
      interceptor to reuse — attach explicitly per call or add one).
- [ ] Registered in the Read Layer table above.
- [ ] Error posture handled; not-configured ≠ upstream error.
- [ ] Unit test added alongside, following `test/services/auth_service_test.dart`'s
      pattern (a `Fake`-based mock `Dio` subclass overriding the relevant verb).
