---
last_updated: "2026-07-16"
---

# Surface Scope — Shared Context (base-ref-app)

*Which repos/surfaces are active for the bundled base app. Unlike
[`OFFER_PROFILE.md`](./OFFER_PROFILE.md), this is a structural fact derived
from scanning `base-ref-app/`, not a business decision — recorded concretely.*

---

## 1. Active surfaces

| Surface | Repo path | In scope? | Card folder | Mocks |
|---|---|---|---|---|
| backend | `base-ref-app/bff` | yes | `service-cards/backend/` | n/a |
| mobile | `base-ref-app/lib` | yes | `service-cards/mobile/` | defaults (no partner mocks bundled) |
| web | `base-ref-app/lib` (compiled to `web/`; same codebase as mobile) | yes | `service-cards/web/` (pointer to `mobile/`) | defaults (no partner mocks bundled) |
| ios | n/a | no | — | n/a |
| android | n/a | no | — | n/a |

## 2. Out of scope

| Surface / repo | Why out of scope |
|---|---|
| native `ios`/`android` card sets | This app is a single cross-platform Flutter codebase (`lib/`) that already compiles to iOS + Android — there are no separate native repos/surfaces to card. The `android/`, `ios/` directories at the repo root are Flutter's platform runner shells, not independent apps. |

## 3. Monorepo vs multi-repo mapping

- **Topology:** monorepo. `base-ref-app/` is a single repo containing both
  `bff/` (backend) and `lib/` (+ `android/`/`ios/`/`web/` platform shells,
  mobile+web).
- **Registry (`.target-apps`) entries observed:** none — no `.target-apps` or
  legacy `.target-app` file exists at the kit root. This is the **default**
  Mode A target (per [`../../../manual/methodology/modes.md`](../../../manual/methodology/modes.md)): with
  nothing registered, Mode A resolves to `base-ref-app/` copied to the working
  `app/`.

| Surface | Registry key used (`root` or own entry) | Resolved repo path | Shares repo with |
|---|---|---|---|
| backend | `root` (no registry present — bundled-app default) | `base-ref-app/bff` (→ `app/bff` when copied for a run) | mobile, web (same monorepo) |
| mobile | `root` | `base-ref-app/lib` (→ `app/lib`) | backend, web |
| web | `root` | `base-ref-app/lib` (→ `app/lib`, compiled to `web/`) | backend, mobile — same codebase as mobile |
| ios | — | not present | — |
| android | — | not present | — |
