---
service: "{service_name}"
owner: "{team_or_owner}"
status: "TODO"            # e.g. active | maintenance | deprecated
repo: "{repo_url_or_path}"
stack: "{language_and_framework}"   # e.g. Java 17 / Spring Boot, Node 20 / Express
last_updated: "<fill: YYYY-MM-DD>"
---

# Backend Service Card — {service_name}

*Entry file for this backend surface. Read this first; it links to the seven
companion cards below. Fill every section from the partner's real code — do not
guess. Where a fact is not yet known, leave `TODO` so the gap is visible to the
verify step.*

---

## 1. What We Do

*One short paragraph, then a bullet list of the concrete responsibilities this
backend actually owns (the capabilities, not aspirations). State it in the
partner's own domain terms.*

- <fill: responsibility 1>
- <fill: responsibility 2>
- TODO

## 2. What We Explicitly Do Not Do

*List the things a reader might assume this service does but it does NOT — work
that belongs to another service, another team, or the client surfaces. This
section prevents wrong integration decisions.*

- <fill: explicitly out of scope 1>
- TODO

## 3. Contracts (summary)

*A one-line-per-item summary only. The authoritative detail lives in
[`CONTRACTS.md`](./CONTRACTS.md) (inbound) and [`CONNECTORS.md`](./CONNECTORS.md)
(outbound). Do not duplicate params/response bodies here.*

### APIs We Expose

*Inbound HTTP surface this backend serves. See [`CONTRACTS.md`](./CONTRACTS.md).*

| Method | Path | Purpose |
|---|---|---|
| `<GET/POST/…>` | `<fill: /base/path>` | <fill> |
| TODO | TODO | TODO |

### APIs We Consume

*Outbound dependencies this backend calls. See [`CONNECTORS.md`](./CONNECTORS.md).*

| Dependency | Purpose |
|---|---|
| <fill> | <fill> |
| TODO | TODO |

### Events

*Async messages consumed/published. See "Async Contracts" in [`CONTRACTS.md`](./CONTRACTS.md).*

| Direction | Topic / Channel | Purpose |
|---|---|---|
| Consume / Publish | <fill> | <fill> |
| TODO | TODO | TODO |

## 4. Module Index (Summary)

*One line per top-level capability, pointing to its detail block in
[`MODULE_INDEX.md`](./MODULE_INDEX.md). This is a map, not the resolver itself.*

| Capability | Entry point | Detail |
|---|---|---|
| <fill> | `<fill: controller/route>` | [`MODULE_INDEX.md`](./MODULE_INDEX.md) |
| TODO | TODO | — |

## 5. Source Structure

*The layout of the repo as it actually is. Annotate each top-level dir with its
role. Keep it to the directories that matter for planning integration work.*

```text
<fill: repo tree>
  src/            # <fill>
  ...             # TODO
```

## 6. What You Need to Know Before Planning Work Here

*The hard-won context an engineer needs before touching this service. Be
specific and cite file paths.*

### Fragile Areas

*Code that is easy to break, has hidden coupling, or lacks tests. Name files.*

- <fill> — TODO

### Known Constraints

*Runtime, platform, contractual, or business constraints that limit changes.*

- <fill> — TODO

### Test Coverage

*Where tests live, what is well covered, and the notable gaps. See
[`BUILD_CONFIG.md`](./BUILD_CONFIG.md) for the authoritative test command.*

- <fill> — TODO

### LLD Hints

*Guidance for the low-level-design step: preferred extension points, the layer
where new Adobe integration code should land, patterns to follow. See
[`../../../manual/methodology/card-model.md`](../../../manual/methodology/card-model.md#lld-section-contract).*

- <fill> — TODO

---

## Companion Files

*The other seven backend cards for this surface. All live in this directory.*

| Card | Purpose |
|---|---|
| [`MODULE_INDEX.md`](./MODULE_INDEX.md) | Capability → code resolver (layers, catalogue, cross-refs). |
| [`CONTRACTS.md`](./CONTRACTS.md) | Inbound HTTP + async contracts this backend exposes. |
| [`CONNECTORS.md`](./CONNECTORS.md) | Outbound dependencies, incl. Adobe integration connectors. |
| [`BUILD_CONFIG.md`](./BUILD_CONFIG.md) | Runtime, env-var schema, authoritative build/verify commands. |
| [`PLATFORM.md`](./PLATFORM.md) | Feature flags, caching, database/datastore. |
| [`INTEGRATION_CONTEXT.md`](./INTEGRATION_CONTEXT.md) | Where the Adobe integration state lives; who owns it. |
| [`READINESS.md`](./READINESS.md) | Per-point ✅/⚠️/❌ integration readiness. |
