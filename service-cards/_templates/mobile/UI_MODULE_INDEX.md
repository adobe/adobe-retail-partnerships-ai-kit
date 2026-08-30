# UI Module Index — {surface}

> _Capability → code resolver for this UI surface. Fill every `<fill>` / `TODO`.
> See [card-model §3.2](../../../manual/methodology/card-model.md)._

## 1. Module Taxonomy

_List each layer of this surface, where it lives, its responsibility, and which
layers it MAY depend on. Record the forbidden dependency directions below the
table so generated code never inverts them._

| Layer | Location | Responsibility | May depend on |
|---|---|---|---|
| Page / Screen | `<fill>` | TODO | Component, State-Binding Unit, Store |
| Component | `<fill>` | TODO | Component, Util |
| State-Binding Unit | `<fill>` | TODO | Data layer, Store, Util |
| Store | `<fill>` | TODO | Util |
| Util | `<fill>` | TODO | — |

> **State-Binding Unit** is the reusable state-binding unit in your framework —
> a React Hook, a Vue Composable, a Flutter Provider/Riverpod notifier, a
> SwiftUI/Android ViewModel, etc. Use whichever term your stack actually uses
> when filling this taxonomy; "State-Binding Unit" is the stack-neutral label
> for the row, not a term to reproduce verbatim in code.

**Forbidden directions** _(a lower layer must never import an upper one):_

- Components MUST NOT import Pages.
- Stores/Utils MUST NOT import Pages, Components, or State-Binding Units.
- TODO

## 2. Capability Catalogue

_One `### N.N` block per integration capability (Claim, Subscription status,
Cancel, Deep-link return, …). Fill the file paths; the Call graph is a
one-line arrow chain from screen to backend endpoint._

### 2.1 <capability name>

- **Page:** `<fill>`
- **Component(s):** `<fill>`
- **State-Binding Unit:** `<fill>`
- **Store:** `<fill>`
- **Call graph:** `<Page> → <State-Binding Unit> → <partner backend endpoint>`
- **Notes:** TODO

### 2.2 <capability name>

- **Page:** `<fill>`
- **Component(s):** `<fill>`
- **State-Binding Unit:** `<fill>`
- **Store:** `<fill>`
- **Call graph:** `<fill>`
- **Notes:** TODO

## 3. Cross-Reference Indexes

_Quick lookups so a reader can jump from a route or hook to its capability._

**Route → Capability**

| Route | Capability |
|---|---|
| `<fill>` | `<fill>` |

**State-Binding Unit → Capabilities**

| State-Binding Unit | Capabilities |
|---|---|
| `<fill>` | `<fill>` |
