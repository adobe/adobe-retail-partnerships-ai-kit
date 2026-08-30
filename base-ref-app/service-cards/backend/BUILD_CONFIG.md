# Build Config — Partner Ref App BFF

*Runtime, dependencies, environment-variable schema, and the AUTHORITATIVE build
and verify commands for this backend.*

---

## 1. Runtime Specifications

| Field | Value |
|---|---|
| Runtime engine | Node 20+ (`bff/package.json` `engines.node: ">=20"`) |
| Package manager | npm (`bff/package-lock.json`) |
| Entry point | `bff/src/index.ts` (compiled to `dist/index.js` via `tsc`) |
| Default port | `8080` (`PORT` env var, `bff/src/config.ts`) |

## 2. Dependency Manifest

- **Manifest file:** `bff/package.json`
- **HTTP client:** none in core dependencies (no axios/got/node-fetch). Node
  20+'s native global `fetch` is available for any new outbound (Adobe) HTTP
  client.
- **Logging:** `console.log`/`console.warn`/`console.error` with a structured
  `event=<name> key=value ...` convention (e.g.
  `event=auth.login_succeeded user_id=... partner_id=...`) — no logging
  library dependency. Generated code must match this exact style.
- **Test framework:** Vitest (`bff/vitest.config.ts`, `bff/src/test-setup.ts`).
  Run with `npm test` (`vitest run`).
- **Other notable:** `express` v5, `jsonwebtoken` v9, `mongodb` driver v6,
  `cors`, `dotenv`. Dev: `tsx` (dev server), `typescript` v5.

## 3. Environment-Variable Schema

> This base app carries **no Adobe env vars yet** — the table below is the
> current (feature-less) schema. It is greenfield for Adobe integration
> purposes: no existing `IMS_*`/`RETAIL_*` names are in use anywhere in this repo
> (confirmed — `bff/src/config.ts` reads only the vars below), so generated
> Adobe code should use the canonical `ADOBE_*` fallback names from
> [`../../../knowledgebase/integration-patterns/environment-config.md`](../../../knowledgebase/integration-patterns/environment-config.md).

| Variable name (AS USED IN THIS CODE) | Purpose | Required? |
|---|---|---|
| `JWT_SECRET` | Signs/verifies partner session JWTs | graceful — auto-generated (ephemeral, per-run) if unset, with a warning |
| `MONGODB_URL` | MongoDB connection URI for the partner store | graceful — if unset or unreachable, falls back to an in-memory partner store seeded with a demo partner (`EXAMPLE`/`EXAMPLE-001`) |
| `CORS_ORIGINS` | Comma-separated allowed CORS origins (`*` = allow all) | graceful — defaults to `*` with a warning |
| `REFAPP_ADMIN_ALLOWED_CLIENT_IDS` | Comma-separated client-ids allowed through `requireAdmin` on `/admin/*` | graceful — empty list means all `/admin/*` calls are forbidden |
| `PORT` | HTTP listen port | graceful — defaults to `8080` |
| *(none yet)* `ADOBE_IMS_CLIENT_ID` | IMS client ID | not present — add per canonical fallback when Mode A generates the IMS client |
| *(none yet)* `ADOBE_IMS_CLIENT_SECRET` | IMS client secret | not present — same |
| *(none yet)* `ADOBE_IMS_SCOPES` | OAuth scopes | not present — same |
| *(none yet)* `ADOBE_IMS_TOKEN_URL` | IMS token endpoint | not present — same (would become boot-required once added) |
| *(none yet)* `ADOBE_RETAIL_API_BASE_URL` | Retail API base URL | not present — same |
| *(none yet)* `ADOBE_API_KEY` | `X-API-Key` header value | not present — graceful once added |
| *(none yet)* `ADOBE_OFFER_ID` | Adobe-assigned offer ID | not present — graceful once added; see [`../shared/OFFER_PROFILE.md`](../shared/OFFER_PROFILE.md) placeholder |
| *(none yet)* `ADOBE_NOTIFY_AUTH_SECRET` | Notify inbound-auth credential | not present — only if Notify enabled |

## 4. Secrets & Sensitive Data

- **Secret source:** `.env` file (dotenv), local to `bff/` — `bff/.env.example`
  documents every key; `.env` itself is gitignored (`bff/.gitignore`).
- **Loaded by:** `bff/src/config.ts` (reads `process.env.*`, validates, exports
  a single frozen `config` object).
- **Sensitive names (must not leak to frontend repos):** `JWT_SECRET`.
  Once generated, the Adobe `*_CLIENT_SECRET`/`ADOBE_API_KEY`
  names above must also appear only here — never in `base-ref-app/lib/`
  (verification rule 9).

## 5. Build Interface (AUTHORITATIVE verify commands)

| Stage | Command |
|---|---|
| Setup | `npm install` (run inside `bff/`) |
| Build | `npm run build` (`tsc`, emits `dist/`) |
| Typecheck | `npm run typecheck` (`tsc --noEmit`) |
| Test | `npm test` (`vitest run`) |
| Package | n/a — no packaging step beyond `tsc` build; `npm run start` runs `node dist/index.js` |

## 6. Cross-Environment Mappings

*This base app has no stage/prod split of its own — `CORS_ORIGINS` and
`REFAPP_ADMIN_ALLOWED_CLIENT_IDS` are the only environment-shaped config today,
and both are set per-deployment via `.env`, not via a stage/prod code branch.*

| Setting | Stage | Prod |
|---|---|---|
| IMS base URL | not yet configured — Mode A will add per [`environment-config.md`](../../../knowledgebase/integration-patterns/environment-config.md) (stage: `https://ims-na1-stg1.adobelogin.com`; prod: `https://ims-na1.adobelogin.com`) | same, prod value |
| Retail API base URL | not yet configured — stage: `https://partners-stage.adobe.io/retail`; prod: `https://partners.adobe.io/retail` | same, prod value |
| `MONGODB_URL` | per-deployment `.env` value | per-deployment `.env` value |
