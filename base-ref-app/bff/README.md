# Partner Ref App — BFF (feature-less base)

A thin **backend-for-frontend** (Node + Express + TypeScript) for the Partner
Reference App. This is the **feature-less base**: it provides partner login and
partner management only. It holds **no Adobe credentials** and has no IMS token
service, Retail API client, or Notify webhook — those are added by the Partner
Integration AI Kit (Mode A) when the Adobe integration is generated onto this app.

The Flutter app (web · iOS · Android) all call this one BFF.

## Endpoints

| Method · Path | Purpose |
|---|---|
| `POST /api/auth/login` | partner login → session JWT |
| `GET /admin/partners` | list partners (allowlisted client-id) |
| `POST /admin/partners` | create/update a partner |
| `PUT /admin/partners` | create/update a partner (alias of `POST`, same handler) |
| `DELETE /admin/partners/:id` | remove a partner |
| `GET /health` | liveness |

**Admin guard is a shared-secret header check, not gateway-validated auth.**
`requireAdmin` checks that `x-gw-ims-client-id` matches one of the values in
`REFAPP_ADMIN_ALLOWED_CLIENT_IDS` — set that value yourself and pass it as the
header when calling `/admin/*`. In Adobe's own production services this header
is injected by an upstream gateway after validating a service token; this base
app has no such gateway in front of it, so treat the configured value as a
shared secret and never expose `/admin/*` on the open internet without putting
a real authenticated gateway in front of it.

## Config

Nothing is required to boot — `npm install && npm run dev` works with no
`.env` at all: `JWT_SECRET` is auto-generated for that run,
and the partner store falls back to an in-memory store seeded with a demo
partner (`EXAMPLE`, so `EXAMPLE-001` logs in immediately). This is for
previewing the app only — auto-generated secrets and in-memory data reset on
every restart.

For anything beyond a first look — real persistence, or stable
sessions/credentials across restarts — copy `.env.example` → `.env` and set:

- `JWT_SECRET` — signs session tokens; set a stable value so sessions survive restarts.
- `MONGODB_URL` — partner store. Quickest local option: `docker run -d -p 27017:27017 mongo:7`.
- `CORS_ORIGINS` — allowed origins (`*` for dev).
- `REFAPP_ADMIN_ALLOWED_CLIENT_IDS` — client-ids allowed on `/admin/*`.

## Develop / verify

```bash
npm install
npm run dev          # tsx watch
npm run typecheck    # tsc --noEmit
npm test             # vitest
```

With `MONGODB_URL` set, partners are stored in MongoDB — provision rows
directly or via `POST /admin/partners` (no startup seeding in that mode).
`userId` format is `<PARTNER>-<number>` (e.g. `EXAMPLE-001`); the prefix
selects the partner record.
