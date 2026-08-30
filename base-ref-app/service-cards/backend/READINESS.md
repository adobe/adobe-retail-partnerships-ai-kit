# Readiness — Partner Ref App BFF

*Per-integration-point readiness for this backend surface. This is the
feature-less base app: every Adobe integration point is genuinely ❌ today —
that is by design (see [`../README.md`](../README.md)).*

---

## Legend

| Status | Meaning |
|---|---|
| ✅ | Present and verified — evidence cited, builds/tests pass for this point. |
| ⚠️ | Partial / best-effort — exists but unverified, incomplete, or assumptions made. |
| ❌ | Absent — not yet implemented. |

## Status

| Integration point | Status | Evidence (file path) | Notes |
|---|---|---|---|
| IMS client | ❌ | — | Not present. No `IMS_*`/`ADOBE_*` names or IMS calls anywhere in `bff/src/`. |
| Retail API client | ❌ | — | Not present. |
| Claim flow | ❌ | — | No `/claim`-style route in `bff/src/routes/`. |
| Subscription (find) flow | ❌ | — | No subscription-status route. |
| Cancel flow | ❌ | — | No cancel route. |
| Notify | ❌ | — | No inbound Notify endpoint; inbound-auth mechanism for one is itself `TODO — ASK PARTNER` (see `CONTRACTS.md` Overview). |
| Testing | ✅ | `bff/src/auth/authService.test.ts`, `bff/src/auth/jwtMiddleware.test.ts`, `bff/src/routes/admin.test.ts` | Existing (non-Adobe) surface is well covered; Adobe-facing code has no tests yet because it doesn't exist. |
| Configuration | ⚠️ | `bff/src/config.ts`, `bff/.env.example` | Non-Adobe config (`JWT_SECRET`, `MONGODB_URL`, `CORS_ORIGINS`, `REFAPP_ADMIN_ALLOWED_CLIENT_IDS`) is complete; nothing is required to boot — the secret auto-generates and the partner store falls back to in-memory if unset. No Adobe config exists yet — greenfield. |
| Stack confidence | ✅ | `bff/package.json`, `bff/README.md` | Validated — Node/Express is the kit's reference-implementation stack (see kit `README.md` support matrix). |
