# Module Index — Partner Ref App BFF

*Capability → code resolver for this backend. Companion cards:
[`SERVICE_CARD.md`](./SERVICE_CARD.md), [`CONTRACTS.md`](./CONTRACTS.md),
[`CONNECTORS.md`](./CONNECTORS.md).*

---

## 1. Module Taxonomy — Layer Categories

| Layer | Location | Responsibility | May depend on |
|---|---|---|---|
| Route | `bff/src/routes/*.ts` | HTTP request/response, input validation, status codes | Service, Connector |
| Service | `bff/src/auth/authService.ts` (login) | Business logic | Connector, Util |
| Connector | `bff/src/db/mongo.ts`, `bff/src/db/partnerStore.ts` | Outbound I/O (MongoDB) | Util |
| Config | `bff/src/config.ts` | Env-var loading + startup validation | (none) |
| Model/Types | `PartnerRecord`/`AuthUser` (declared inline in `db/partnerStore.ts`, `auth/jwtMiddleware.ts`) | Domain shapes | (none) |

> **Forbidden dependency directions.**
>
> - Connector (`db/`) MUST NOT import Route (`routes/`).
> - Config (`config.ts`) MUST NOT import Route or Service.
> - No layer imports Adobe SDKs or credentials — none exist yet in this base app.

## 2. Capability Catalogue

### 2.1 Partner Login

- **Domain:** Auth
- **Controller:** `bff/src/routes/auth.ts` (`POST /api/auth/login`, `POST /api/auth/logout`)
- **Service:** `bff/src/auth/authService.ts` (`login()`)
- **Connector(s):** MongoDB via `bff/src/db/partnerStore.ts`
- **Domain types:** `LoginResult` (`authService.ts`), `PartnerRecord` (`partnerStore.ts`)
- **Validation:** inline in `routes/auth.ts` (missing `userId` → 400); `authService.login()` throws `INVALID_USER_ID` (malformed id) or `INVALID_CREDENTIALS` (no matching partner) — both mapped to the same 401 response
- **Call graph:** `auth.ts` → `authService.login()` → `partnerStore().get()` → `jwt.sign()`
- **Notes:** login is by `userId` prefix only — no password check. `userId` format is `<PARTNER>-<number>`; the prefix before the first `-` selects the partner record. This is intentional: the reference app's login exists so a partner can try it locally with just a userId, not a credential-verification pattern to copy into a production integration.

### 2.2 Partner Management (admin)

- **Domain:** Admin / back-office
- **Controller:** `bff/src/routes/admin.ts` (`GET`/`POST`/`PUT /admin/partners`, `DELETE /admin/partners/:id`)
- **Service:** inline in `admin.ts` (no separate service layer)
- **Connector(s):** MongoDB via `bff/src/db/partnerStore.ts`
- **Domain types:** `PartnerRecord`
- **Validation:** inline (`id`/`displayName` required → 400; `maxClaims` must be a positive integer if present → 400)
- **Call graph:** `admin.ts` (`requireAdmin` guard) → `partnerStore().upsert()`/`.list()`/`.delete()`
- **Notes:** `requireAdmin` is a shared-secret header check standing in for a gateway check (see `SERVICE_CARD.md` Fragile Areas) — it is NOT equivalent to real inbound machine-caller auth. No credential is stored on a `PartnerRecord`; there is nothing password-shaped anywhere in this app.

### 2.3 Health

- **Domain:** Ops
- **Controller:** `bff/src/routes/health.ts` (`GET /health`)
- **Service:** none (inline)
- **Connector(s):** MongoDB via `bff/src/db/mongo.ts` (`getDb().command({ ping: 1 })`)
- **Domain types:** none
- **Validation:** none
- **Call graph:** `health.ts` → `mongo.getDb().command()`
- **Notes:** returns `{ status: 'ok', mongo: 'up'|'down' }`; never fails the HTTP call even if Mongo is down.

## 3. Cross-Reference Indexes

### Endpoint → Capability

| Endpoint | Capability (§ above) |
|---|---|
| `POST /api/auth/login` | 2.1 |
| `POST /api/auth/logout` | 2.1 |
| `GET /admin/partners` | 2.2 |
| `POST /admin/partners` | 2.2 |
| `PUT /admin/partners` | 2.2 |
| `DELETE /admin/partners/:id` | 2.2 |
| `GET /health` | 2.3 |

### Connector → Capabilities

| Connector | Used by capabilities |
|---|---|
| MongoDB (`db/mongo.ts`, `db/partnerStore.ts`) | 2.1, 2.2, 2.3 |

## 4. Forbidden / Do-Not-Add Rules

- No Adobe/IMS credentials anywhere in this backend's frontend-adjacent code —
  moot today (none exist) but binding once the integration is generated
  (verification rule 9).
- Do not add a new top-level Express app/router — extend `bff/src/index.ts`'s
  existing three-router mounting (`healthRouter`, `authRouter`, `adminRouter`)
  with new routers following the same pattern.
- Do not bypass `bff/src/auth/jwtMiddleware.ts`'s `requireAuth` for new
  end-user-authenticated routes — reuse it rather than inventing a new JWT
  check.
