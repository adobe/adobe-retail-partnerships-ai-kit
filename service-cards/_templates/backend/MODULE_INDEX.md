# Module Index — {service_name}

*Capability → code resolver for this backend. Given "where does capability X
live?", this card answers with the exact controller, service, connector(s), and
domain types. Fill every block from the partner's real code, citing file paths.
Companion cards: [`SERVICE_CARD.md`](./SERVICE_CARD.md), [`CONTRACTS.md`](./CONTRACTS.md),
[`CONNECTORS.md`](./CONNECTORS.md).*

---

## 1. Module Taxonomy — Layer Categories

*Describe the architectural layers this codebase uses and where each lives.
Match the partner's actual package/folder layout — do not impose a new one.*

| Layer | Location | Responsibility | May depend on |
|---|---|---|---|
| <fill: e.g. Controller/Route> | `<fill: path>` | <fill> | <fill: layers below it> |
| <fill: e.g. Service/Domain> | `<fill: path>` | <fill> | <fill> |
| <fill: e.g. Connector/Client> | `<fill: path>` | <fill> | <fill> |
| <fill: e.g. Model/Types> | `<fill: path>` | <fill> | (none) |
| TODO | TODO | TODO | TODO |

> **Forbidden dependency directions.** *State the dependency rules that must not
> be violated (e.g. connectors must never import controllers; domain must not
> depend on transport). List each as an explicit "X → Y is forbidden" rule.*
>
> - <fill: forbidden direction 1>
> - TODO

## 2. Capability Catalogue

*One `### N.N <Capability>` block per capability this backend owns. Add or remove
blocks to match reality. Every field must point at real code or say `TODO`.*

### 2.1 <Capability name>

- **Domain:** <fill: the business area this capability serves>
- **Controller:** `<fill: file / class / route handler>`
- **Service:** `<fill: file / class>`
- **Connector(s):** `<fill: outbound client(s) used, or "none">`
- **Domain types:** `<fill: request/response/entity types>`
- **Validation:** `<fill: where inputs are validated>`
- **Call graph:** `<fill: controller → service → connector → …>`
- **Notes:** <fill: gotchas, side effects, TODO>

### 2.2 <Capability name>

- **Domain:** TODO
- **Controller:** TODO
- **Service:** TODO
- **Connector(s):** TODO
- **Domain types:** TODO
- **Validation:** TODO
- **Call graph:** TODO
- **Notes:** TODO

## 3. Cross-Reference Indexes

*Reverse lookups so a reader can start from an endpoint or a connector.*

### Endpoint → Capability

| Endpoint | Capability (§ above) |
|---|---|
| `<METHOD> <fill: /path>` | <fill: 2.N> |
| TODO | TODO |

### Connector → Capabilities

| Connector | Used by capabilities |
|---|---|
| `<fill: connector name>` | <fill: 2.N, 2.M> |
| TODO | TODO |

## 4. Forbidden / Do-Not-Add Rules

*Explicit "do not add this here" rules for anyone (human or agent) generating
code into this service — e.g. "no IMS credentials in this layer", "no new
top-level controller; extend the existing one", "no direct datastore access from
controllers". These protect the invariants in [`../../../manual/methodology/verification.md`](../../../manual/methodology/verification.md).*

- <fill: rule 1>
- TODO
