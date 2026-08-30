---
surface: <fill>            # describes whatever this surface actually is, e.g. mobile | web | ios | android | desktop | other — a descriptive label, not a closed enum
stack: <fill>              # e.g. Flutter/Dart, React/TS, SwiftUI, Kotlin/Compose
rendering: <fill>          # e.g. SPA, SSR, native, hybrid
repo: <fill>               # absolute path or repo URL of this UI surface
status: TODO               # draft | analyzed | verified
last_updated: TODO         # YYYY-MM-DD
---

# UI Service Card — {surface}

> _Entry point / index for this UI surface's card set. Fill every `<fill>` /
> `TODO`. This card is the single input downstream UI steps read first. See
> [card-model §3.2](../../../manual/methodology/card-model.md) and the
> [verification protocol](../../../manual/methodology/verification.md). `surface:` is a
> descriptive label, not a closed enum — record whatever the partner's own
> surface actually is (mobile/web/ios/android/desktop/other); this `mobile/`
> template set is the starting point to adapt for any of them._

## 1. What We Do

_State, in 3–6 bullets, what this UI surface is responsible for in the Adobe
Retail Integration — the claim / subscription-status / cancel screens it hosts.
Describe capabilities, not implementation._

- TODO
- TODO

## 2. What We Explicitly Do Not Do

_List the things this UI surface must never do. The first bullet is mandatory and
non-negotiable._

- **Never calls Adobe Integration APIs directly.** All Adobe traffic goes
  through the partner's OWN backend (see `DATA_LAYER.md` → Backend-Proxy Rule and
  [verification rule 9](../../../manual/methodology/verification.md)).
- Never holds IMS credentials (`*_CLIENT_ID`, `*_CLIENT_SECRET`, tokens).
- TODO
- TODO

## 3. Data Contracts

### APIs We Consume

_Every remote call this UI makes. The endpoint column is a route on the PARTNER's
backend — never an Adobe URL._

| State-Binding Unit | Method | Endpoint (on PARTNER backend) | Purpose |
|---|---|---|---|
| `<fill>` | `<GET/POST/…>` | `<fill>` | TODO |
| `<fill>` | `<fill>` | `<fill>` | TODO |

### Client-Side State We Own

_Durable or in-memory client state this surface owns. TTL is blank for
non-expiring state._

| Key | Storage | Owner | Contents | TTL |
|---|---|---|---|---|
| `<fill>` | `<memory/local/secure>` | `<store/module>` | TODO | `<fill>` |

## 4. Source Structure

_Sketch the directory layout of this surface relevant to the integration. One
line per notable path with a short role note._

```text
<fill>/
  <fill>/        # TODO
  <fill>/        # TODO
```

## 5. Module Index (Summary)

_One-line pointer to `UI_MODULE_INDEX.md`; list only the top capabilities so a
reader can orient without opening it._

- **Claim** — TODO → see `UI_MODULE_INDEX.md`
- **Subscription status** — TODO
- **Cancel** — TODO

## Companion Files

_The other cards in this UI surface's set. Keep this table as the surface index._

| File | Purpose |
|---|---|
| `UI_MODULE_INDEX.md` | Capability → code resolver. |
| `ROUTES.md` | Route registry, auth guard, deep-link / return-from-Adobe handling. |
| `DATA_LAYER.md` | How the UI talks to its backend; backend-proxy rule. |
| `STATE_MANAGEMENT.md` | Client stores; session seed for `partner_reference_id`. |
| `UI_CODE_PATTERNS.md` | Conventions + the component library the generated UI must reuse. |
| `UI_PLATFORM.md` | Runtime/build; authoritative verify commands. |
| `INTEGRATION_CONTEXT.md` | Where the Adobe integration lives for this surface. |
| `READINESS.md` | Per-point ✅ / ⚠️ / ❌ integration readiness. |
