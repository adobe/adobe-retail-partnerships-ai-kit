---
service: "Partner Ref App BFF"
owner: "Partner Integration AI Kit (bundled reference)"
status: "active"
repo: "base-ref-app/bff (in-kit, bundled)"
stack: "Node 20 / Express 5 + TypeScript"
last_updated: "2026-07-16"
---

# Backend Service Card — Partner Ref App BFF

*Entry file for this backend surface. Read this first; it links to the seven
companion cards below. This is the kit's own bundled reference app — see
[`../README.md`](../README.md) for how these pre-filled cards are used by the
Fast path.*

---

## 1. What We Do

A thin backend-for-frontend for the Partner Ref App. It is the **feature-less
base** Mode A builds the Adobe integration onto.

- Partner login: verifies a `userId` prefix against a MongoDB-backed
  partner record (no password) and issues a signed session JWT
  (`bff/src/routes/auth.ts`, `bff/src/auth/authService.ts`).
- Partner management (admin/back-office): create/update/list/delete partner
  records, including an optional `maxClaims` cap (`bff/src/routes/admin.ts`).
- Liveness check reporting Mongo connectivity (`bff/src/routes/health.ts`).
- Serves the built Flutter web bundle as static files with an SPA fallback
  (`bff/src/index.ts`).

## 2. What We Explicitly Do Not Do

- **No Adobe integration of any kind yet.** No IMS token service, no Retail API
  client, no claim / find-subscription / cancel / notify routes, no Adobe
  credentials anywhere in this repo. That is what Mode A generates onto this
  app.
- No rate-limiting, account lockout, or MFA — this is a reference auth
  implementation, not a production-hardened one (see `bff/README.md`).
- `/admin/*` does not implement real gateway authentication itself — it trusts
  an `x-gw-ims-client-id` header that, in this bundled local/dev setup, nothing
  actually validates upstream (see §6 Fragile Areas).
- Does not talk to any datastore other than MongoDB; no caching layer.

## 3. Contracts (summary)

*See [`CONTRACTS.md`](./CONTRACTS.md) (inbound) and [`CONNECTORS.md`](./CONNECTORS.md) (outbound) for full detail.*

### APIs We Expose

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/api/auth/login` | Partner login → session JWT |
| `POST` | `/api/auth/logout` | Stateless logout (204, client discards JWT) |
| `GET` | `/admin/partners` | List partners (allowlisted client-id) |
| `POST` / `PUT` | `/admin/partners` | Create/update a partner (same handler) |
| `DELETE` | `/admin/partners/:id` | Remove a partner |
| `GET` | `/health` | Liveness + Mongo status |

### APIs We Consume

| Dependency | Purpose |
|---|---|
| MongoDB | Partner record storage (`bff/src/db/mongo.ts`, `bff/src/db/partnerStore.ts`) |

No external/Adobe APIs are called yet — see [`CONNECTORS.md`](./CONNECTORS.md) §4.

### Events

None. This backend is purely synchronous HTTP.

## 4. Module Index (Summary)

| Capability | Entry point | Detail |
|---|---|---|
| Partner login | `bff/src/routes/auth.ts` | [`MODULE_INDEX.md`](./MODULE_INDEX.md) §2.1 |
| Partner management (admin) | `bff/src/routes/admin.ts` | [`MODULE_INDEX.md`](./MODULE_INDEX.md) §2.2 |
| Health | `bff/src/routes/health.ts` | [`MODULE_INDEX.md`](./MODULE_INDEX.md) §2.3 |

## 5. Source Structure

```text
bff/
  src/
    auth/             # authService (login), jwtMiddleware (requireAuth — not yet
                       #   wired into any route)
    db/                # mongo.ts (connect/getDb), partnerStore.ts (PartnerRecord CRUD,
                       #   Mongo + in-memory implementations)
    routes/            # auth.ts, admin.ts, health.ts
    config.ts          # env-var loading; nothing boot-fatal (secrets auto-generate if unset)
    index.ts            # Express app wiring, static Flutter-web hosting, SPA fallback
  public/              # built Flutter web bundle (served statically) — not in source control
```

## 6. What You Need to Know Before Planning Work Here

### Fragile Areas

- `bff/src/routes/admin.ts` `requireAdmin` — checks only that
  `x-gw-ims-client-id` is present and in `config.adminAllowedClientIds`. In this
  bundled local/dev setup there is no real API gateway populating that header,
  so anyone who can reach the BFF can set it themselves (documented in
  `bff/README.md`). Do not treat this as a real authorization boundary when
  reasoning about `/admin/*` security.
- `bff/src/auth/jwtMiddleware.ts` (`requireAuth`) exists and is unit-tested
  (`jwtMiddleware.test.ts`) but is **not wired into any route yet** — no
  `app.use`/router calls it in `index.ts` or elsewhere. It is the ready-made
  guard the Adobe integration's protected routes (claim / find-subscription /
  cancel) should use.

### Known Constraints

- Nothing is boot-fatal (`config.ts`). `JWT_SECRET` is
  auto-generated (ephemeral, per-run) if unset; `CORS_ORIGINS` defaults to
  `*`. All log a `*_NOT_CONFIGURED` warning when defaulted.
- MongoDB connection failure at startup is non-fatal (`index.ts` `start()`
  catches and logs `MONGO_CONNECT_FAILED`) — when unset or unreachable, the
  app falls back to an in-memory `PartnerStore` seeded with a demo partner
  (`EXAMPLE`/`EXAMPLE-001`) so login still works, just without persistence
  across restarts.
- No global route prefix — `authRouter` is mounted at `/api`, `healthRouter` and
  `adminRouter` at `/` (their own paths already include `/admin` and `/health`).
  See [`CONTRACTS.md`](./CONTRACTS.md) Overview.

### Test Coverage

- Vitest, `bff/vitest.config.ts` (setup file `bff/src/test-setup.ts` seeds
  a deterministic `JWT_SECRET` for tests).
- Covered: `auth/authService.test.ts`,
  `auth/jwtMiddleware.test.ts`, `routes/admin.test.ts` (in-memory partner store).
- Gap: no test file for `routes/health.ts` or `index.ts` app wiring itself.

### LLD Hints

- New Adobe-facing routes belong beside the existing ones in `bff/src/routes/`
  (e.g. `claim.ts`, `subscription.ts`, `notify.ts`), following the same
  `Router()` + inline validation + `console.log/warn/error` with
  `event=<name> key=value` structured-log style already used in `auth.ts` /
  `admin.ts`.
- A new Adobe connectors layer does not exist yet — add it under
  `bff/src/adobe/` (or similar), mirroring `db/` as a sibling connector
  directory, never importing from `routes/`.
- Reuse `config.ts`'s pattern (validate at import time, export a frozen
  `config` object) for any new Adobe env vars.
- New protected routes should use `bff/src/auth/jwtMiddleware.ts`'s
  `requireAuth` (currently unused — see Fragile Areas) rather than inventing a
  new guard.
- `partner_reference_id`/subscription state has **no existing store** — the
  only Mongo collection today is `partners_ref_app_partners`
  (`db/partnerStore.ts`). A new collection/field is needed; see
  [`INTEGRATION_CONTEXT.md`](./INTEGRATION_CONTEXT.md).

---

## Companion Files

| Card | Purpose |
|---|---|
| [`MODULE_INDEX.md`](./MODULE_INDEX.md) | Capability → code resolver (layers, catalogue, cross-refs). |
| [`CONTRACTS.md`](./CONTRACTS.md) | Inbound HTTP + async contracts this backend exposes. |
| [`CONNECTORS.md`](./CONNECTORS.md) | Outbound dependencies, incl. Adobe integration connectors. |
| [`BUILD_CONFIG.md`](./BUILD_CONFIG.md) | Runtime, env-var schema, authoritative build/verify commands. |
| [`PLATFORM.md`](./PLATFORM.md) | Feature flags, caching, database/datastore. |
| [`INTEGRATION_CONTEXT.md`](./INTEGRATION_CONTEXT.md) | Where the Adobe integration state lives; who owns it. |
| [`READINESS.md`](./READINESS.md) | Per-point ✅/⚠️/❌ integration readiness. |
