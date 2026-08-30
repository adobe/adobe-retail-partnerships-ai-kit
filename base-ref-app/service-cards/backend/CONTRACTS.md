# Contracts — Partner Ref App BFF

*The inbound surface this backend exposes. Outbound calls belong in
[`CONNECTORS.md`](./CONNECTORS.md).*

---

## Overview

- **Base path:** none — there is no single global mount prefix. `bff/src/index.ts`
  mounts `authRouter` at `/api` (so its routes are `/api/auth/...`), and mounts
  `healthRouter` and `adminRouter` at `/` (their own route strings already start
  with `/health` and `/admin`). **A new Adobe route must decide its own prefix
  explicitly** — do not assume `/api` applies kit-wide; only the auth router is
  mounted there today.
- **Auth scheme (end-user):** Bearer JWT in the `Authorization` header, issued
  by `POST /api/auth/login` (`bff/src/auth/authService.ts`), verified by
  `bff/src/auth/jwtMiddleware.ts`'s `requireAuth`. **Not currently applied to
  any route** — no handler in this feature-less app calls `requireAuth` yet
  (verified: no `requireAuth`/`jwtMiddleware` import outside its own test file).
  It is the intended guard for future end-user-authenticated routes (e.g.
  claim/find-subscription/cancel).
- **Inbound caller auth (machine callers):** `/admin/*` uses a **shared-secret**
  gateway-header check (`requireAdmin` in `admin.ts`): it trusts
  `x-gw-ims-client-id` against `config.adminAllowedClientIds`, assuming an
  upstream API gateway actually validated a service token and injected
  that header — no such gateway exists in this bundled local/dev setup, so the
  header can be set by anyone reaching the BFF directly. **This is not a
  registrable Notify-style external-caller mechanism** — there is no
  Adobe-facing inbound endpoint in this base app yet, so `TODO — ASK PARTNER`
  applies once a Notify handler is added (verification rule 8): a real
  deployment must decide what "the partner's own inbound-auth mechanism" is
  before Notify can reuse it.
- **Default authorization:** **Permit-by-default.** Express has no global
  auth middleware (no `app.use` before the routers requires authentication);
  each router/route enforces its own check (`requireAdmin` on `/admin/*`;
  nothing on `/health` or `/api/auth/*`, which are meant to be public). A new
  protected route must explicitly apply `requireAuth` — it does not inherit
  any deny-by-default chain.

## APIs We Expose

### `POST /api/auth/login` — Partner login

- **Auth:** none (public; this IS the auth endpoint)
- **Path params:** none
- **Query params:** none
- **Request body:** `{ userId: string }`
- **Response 2xx:** `200 { token: string, partnerId: string }`
- **Error responses:** `400` missing `userId`; `401` invalid user ID (`INVALID_USER_ID` — malformed id: no `-`, or `-` as the first character, or `INVALID_CREDENTIALS` — no matching partner; both return the same message, never revealing which); `500` unexpected error (`{ error, detail }`)
- **Delegate:** `bff/src/auth/authService.ts` → `login(userId)`

### `POST /api/auth/logout` — Partner logout

- **Auth:** none required (stateless — client just discards the JWT)
- **Path params:** none
- **Query params:** none
- **Request body:** none
- **Response 2xx:** `204` no content
- **Error responses:** none
- **Delegate:** none (no server-side session to invalidate)

### `GET /admin/partners` — List partners

- **Auth:** `requireAdmin` (see Overview)
- **Path params:** none
- **Query params:** none
- **Request body:** none
- **Response 2xx:** `200 [{ id, displayName, maxClaims: number|null }]`
- **Error responses:** `403` missing/non-allowlisted `x-gw-ims-client-id`
- **Delegate:** `bff/src/db/partnerStore.ts` → `partnerStore().list()`

### `POST /admin/partners` / `PUT /admin/partners` — Create/update a partner

- **Auth:** `requireAdmin`
- **Path params:** none
- **Query params:** none
- **Request body:** `{ id: string, displayName: string, maxClaims?: number }`
- **Response 2xx:** `200 { id, updated: true }`
- **Error responses:** `400` missing required field, or non-positive-integer `maxClaims`; `403` (see above)
- **Delegate:** `bff/src/db/partnerStore.ts` → `partnerStore().upsert()`

### `DELETE /admin/partners/:id` — Remove a partner

- **Auth:** `requireAdmin`
- **Path params:** `id` (partner id)
- **Query params:** none
- **Request body:** none
- **Response 2xx:** `200 { id, deleted: true }`
- **Error responses:** `403` (see above); `404 { error: 'NOT_FOUND' }` if the partner does not exist
- **Delegate:** `partnerStore().delete(id)`

### `GET /health` — Liveness

- **Auth:** none
- **Path params:** none
- **Query params:** none
- **Request body:** none
- **Response 2xx:** `200 { status: 'ok', mongo: 'up'|'down' }` (always 200, even if Mongo is down)
- **Error responses:** none
- **Delegate:** `bff/src/db/mongo.ts` → `getDb().command({ ping: 1 })`

## Async Contracts

### Events We Consume

None. This backend is purely synchronous HTTP; no message broker or event
consumer exists.

### Events We Publish

None.
