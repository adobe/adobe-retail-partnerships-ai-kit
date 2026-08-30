# Platform — {service_name}

*Platform capabilities this backend relies on: feature flags, caching, and the
datastore. Fill from the partner's real code and config, citing paths. If a
capability is not used, state "None" explicitly rather than deleting the
section.*

---

## 1. Feature Flags

*How the service gates behavior. Note the flag system, where flags are defined,
and any flag the Adobe integration should live behind.*

- **Flag system:** `<fill: e.g. LaunchDarkly, env toggle, config table, or None>`
- **Defined in:** `<fill: path>`
- **Relevant flags:** `<fill or "none">` — TODO

## 2. Caching

*Caches this service uses, including the IMS token cache if present. Note engine,
TTLs, and invalidation. See [`../../../knowledgebase/integration-patterns/token-caching.md`](../../../knowledgebase/integration-patterns/token-caching.md)
for the token-cache pattern.*

- **Cache engine:** `<fill: e.g. Redis, Caffeine, in-memory, or None>`
- **What is cached:** `<fill>`
- **TTL / invalidation:** `<fill>` — TODO

## 3. Database / Datastore

*The persistence layer. This is where subscription state and `partner_reference_id`
may be stored — cross-reference [`INTEGRATION_CONTEXT.md`](./INTEGRATION_CONTEXT.md).*

| Field | Value |
|---|---|
| Engine | `<fill: e.g. PostgreSQL, MongoDB, DynamoDB, or None>` |
| ORM | `<fill: e.g. Hibernate/JPA, Mongoose, none>` |
| Migration tool | `<fill: e.g. Flyway, Liquibase, none>` |

*Notes: <fill — key collections/tables relevant to the integration, connection
config location>* — TODO
