---
surface: mobile
stack: Flutter/Dart (Riverpod + go_router)
rendering: native (compiles to web + iOS + Android from one codebase — see web/ pointer)
repo: base-ref-app/lib (in-kit, bundled)
status: analyzed
last_updated: 2026-07-16
---

# UI Service Card — mobile (Partner Ref App)

> _Entry point / index for this UI surface's card set — the Flutter app in
> `base-ref-app/lib`. This is the kit's bundled reference app; see
> [`../README.md`](../README.md)._

## 1. What We Do

- Partner login screen (`lib/features/session/login_screen.dart`) — user ID
  form (no password), calls the BFF, persists the resulting session.
- Session lifecycle: sign-in/sign-out state (`session_provider.dart`),
  persisted across app restarts (`session_storage.dart`), with client-side JWT
  expiry checking (`core/jwt_utils.dart`).
- A home shell (`features/home/home_screen.dart`) with an app-bar + drawer
  (`widgets/app_drawer.dart`) — currently just a "Welcome" placeholder; this is
  where claim/subscription/cancel UI will be added.
- Adobe-brand widgets (`widgets/adobe_brand.dart`) used in the app bar/drawer.

## 2. What We Explicitly Do Not Do

- **Never calls Adobe Integration APIs directly.** All Adobe traffic
  goes through the partner's OWN backend (see `DATA_LAYER.md` → Backend-Proxy
  Rule and [verification rule 9](../../../manual/methodology/verification.md)). Today this app
  makes exactly one remote call at all — `POST /api/auth/login` — and it goes
  to the BFF, never Adobe.
- Never holds IMS credentials (`*_CLIENT_ID`, `*_CLIENT_SECRET`, tokens). None
  exist in this codebase.
- No claim / subscription-status / cancel screens exist yet — this is the
  feature-less base Mode A builds those onto.
- Does not verify its own JWT signature client-side — `jwt_utils.dart`'s
  `isJwtExpired` only decodes the payload to read `exp` for a UX check; the BFF
  is the only party that verifies the signature.

## 3. Data Contracts

### APIs We Consume

| Hook/Service | Method | Endpoint (on PARTNER backend) | Purpose |
|---|---|---|---|
| `AuthService.login()` (`lib/services/auth_service.dart`) | `POST` | `/api/auth/login` | Partner login → `{ token, partnerId }` |

No other remote calls exist in this app yet (logout is client-side only — no
`/api/auth/logout` call is made from `lib/`, even though the BFF exposes it).

### Client-Side State We Own

| Key | Storage | Owner | Contents | TTL |
|---|---|---|---|---|
| `partners_ref_app_session` | `shared_preferences` (→ `localStorage` on web) | `SessionStorage` (`lib/services/session_storage.dart`) | JSON-encoded `Session { token, userId, partnerId }` | until the JWT's own `exp` claim (checked, not enforced, on load) |

## 4. Source Structure

```text
lib/
  app.dart                          # MaterialApp.router + go_router config + theming
  main.dart                          # entry point; restores persisted session before first frame
  core/
    config.dart                      # AppConfig.bffBaseUrl (dart-define BFF_BASE_URL)
    date_format.dart                  # (utility, not integration-relevant yet)
    jwt_utils.dart                    # isJwtExpired() — client-side exp check only
  models/
    session.dart                      # Session{token,userId,partnerId} + tryParse()
  services/
    auth_service.dart                 # Dio-based login() call to the BFF
    session_storage.dart              # shared_preferences persistence
  features/
    session/
      login_screen.dart               # login form
      session_provider.dart           # Riverpod Notifier<Session?>
    home/
      home_screen.dart                 # placeholder home shell — future claim/manage UI lands here
  widgets/
    adobe_brand.dart                   # brand mark + wordmark
    app_drawer.dart                     # nav drawer (Home + sign-out)
```

## 5. Module Index (Summary)

- **Claim** — not yet implemented → see `UI_MODULE_INDEX.md`
- **Subscription status** — not yet implemented
- **Cancel** — not yet implemented
- **Login/session** (the only implemented capability today) — see
  `UI_MODULE_INDEX.md` §2.1

## Companion Files

| File | Purpose |
|---|---|
| `UI_MODULE_INDEX.md` | Capability → code resolver. |
| `ROUTES.md` | Route registry, auth guard, deep-link / return-from-Adobe handling. |
| `DATA_LAYER.md` | How the UI talks to its backend; backend-proxy rule. |
| `STATE_MANAGEMENT.md` | Client stores; session seed for `partner_reference_id`. |
| `UI_CODE_PATTERNS.md` | Conventions + the component library the generated UI must reuse. |
| `UI_PLATFORM.md` | Runtime/build; authoritative verify commands. |
| `INTEGRATION_CONTEXT.md` | Where the Adobe integration lives for this surface. |
| `READINESS.md` | Per-point ✅ / ⚠️ / ❌ integration readiness. |
