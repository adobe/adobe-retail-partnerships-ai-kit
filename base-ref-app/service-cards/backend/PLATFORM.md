# Platform — Partner Ref App BFF

*Platform capabilities this backend relies on: feature flags, caching, and the
datastore.*

---

## 1. Feature Flags

- **Flag system:** None. There is no feature-flag library, config table, or
  env-based toggle system in this codebase.
- **Defined in:** n/a
- **Relevant flags:** None — a future IMS-token-cache or Notify-enablement
  toggle would be new, not an extension of an existing system.

## 2. Caching

- **Cache engine:** None. No Redis/Caffeine/in-memory cache exists.
- **What is cached:** Nothing today.
- **TTL / invalidation:** n/a. When the IMS token service is generated, it will
  need its own in-process cache (see
  [`../../../knowledgebase/integration-patterns/token-caching.md`](../../../knowledgebase/integration-patterns/token-caching.md))
  — there is no existing cache abstraction to extend.

## 3. Database / Datastore

| Field | Value |
|---|---|
| Engine | MongoDB (driver `mongodb` v6, `bff/src/db/mongo.ts`) |
| ORM | None — raw driver calls via `Db.collection<T>()` (typed with TS interfaces, no schema library) |
| Migration tool | None |

*Notes: single collection today, `partners_ref_app_partners`
(`bff/src/db/partnerStore.ts`), holding `PartnerRecord { id, displayName,
maxClaims? }`. Connection config is the single `MONGODB_URL` env
var (see [`BUILD_CONFIG.md`](./BUILD_CONFIG.md) §3); the default DB is
whichever the URI names (`client.db()` with no override). There is no existing
collection for subscription state or `partner_reference_id` — see
[`INTEGRATION_CONTEXT.md`](./INTEGRATION_CONTEXT.md).*
