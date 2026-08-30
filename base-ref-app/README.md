# Partner Reference App — feature-less base

This is the **clean, feature-less base app** that the Partner Integration AI Kit's
**Mode A** builds the Adobe integration onto by default. It deliberately
contains **no Adobe integration** — no IMS token service, no Retail API client, no
claim / find-subscription / cancel / notify features. Mode A generates those onto
this app following its existing patterns.

## What's here

- **`lib/`** — a Flutter app (web · iOS · Android from one codebase) with just:
  a login screen, a session/auth layer, and a home shell (app bar + drawer). No
  Adobe features.
- **`bff/`** — a thin Node + Express + TypeScript backend-for-frontend with just:
  partner login/auth (`/api/auth`), partner management (`/admin/*`), and a health
  check (`/health`). It holds no Adobe credentials.

  Auth here authenticates by userId prefix only (no password) and issues a
  JWT — enough to try the app and demonstrate the session pattern, without
  production hardening: no password check, no rate-limiting, no account
  lockout, no MFA. Add those before using this pattern in a production
  deployment.

## Why it's feature-less

Mode A's job is to *implement* the Adobe integration into a provided codebase. If
the base app already had the integration, there would be nothing to build. Keeping
this app feature-less makes it a faithful "day zero" starting point: the partner
supplies only their Adobe credentials, and Mode A writes the integration in this
app's own stack.

## Running it

**Quickstart — no setup required.** No `.env`, no MongoDB, no dart-defines:

```bash
# Backend
cd bff && npm install && npm run dev

# App (separate terminal)
flutter pub get
flutter run -d chrome
```

The backend auto-generates a JWT secret for this run, and falls back to an
in-memory partner store seeded with a demo partner — sign in with userId
**`EXAMPLE-001`** (the hint already shown on the login screen).
The Flutter app already defaults to `http://localhost:8080`, so no
`dart_defines.env` copy is needed either.

### Beyond a first look

The quickstart above is for previewing the app: secrets regenerate and
partner data resets on every restart. Once you're implementing/testing a
feature on top of this app (or want data that survives a restart), configure
`bff/.env` from `.env.example`:

- `MONGODB_URL` — real persistence. Quickest way to get one locally:
  `docker run -d -p 27017:27017 mongo:7` (or `brew install mongodb-community`
  on macOS), then `MONGODB_URL=mongodb://localhost:27017/partner_ref_app`.
- `JWT_SECRET` — a stable value so sessions survive restarts (a session
  issued before a restart is otherwise invalidated once the secret
  regenerates).

With a real `MONGODB_URL` set, seed your own partner via:

```bash
curl -X POST http://localhost:8080/admin/partners \
  -H "Content-Type: application/json" \
  -H "x-gw-ims-client-id: <a value from REFAPP_ADMIN_ALLOWED_CLIENT_IDS>" \
  -d '{"id":"EXAMPLE","displayName":"Example Partner"}'
```

Verify: `cd bff && npm run typecheck && npm test`; and `flutter analyze && flutter test`.

## Notes

- This app ships with the kit as the default Mode A target. It has **no LICENSE or
  CI of its own** — it inherits the kit's.
- Build artifacts (`build/`, `.dart_tool/`, `node_modules/`, `.env`,
  `dart_defines.env`) are gitignored and never shipped.
