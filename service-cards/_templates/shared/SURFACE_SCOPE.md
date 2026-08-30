---
last_updated: "<fill: YYYY-MM-DD>"
---

# Surface Scope — Shared Context

*Which repos/surfaces are active vs out of scope, and how they map to repos
(card-model [§4.5](../../../manual/methodology/card-model.md)). This is the authoritative
in/out list every step reads before touching a surface. Keep it consistent with
"Surfaces in scope" in [`OFFER_PROFILE.md`](./OFFER_PROFILE.md).*

> Leave any unknown cell as `TODO`; an unresolved scope decision is a
> **STOP-and-ask** — do not silently include or drop a surface.

---

## 1. Active surfaces

*Every surface the kit will generate into. `mobile` is mutually exclusive with
`ios`/`android` (one cross-platform app vs separate native repos). The card
folder is where this surface's card set lives under `service-cards/`. **Mocks**
records, per UI surface, whether the partner supplied their own screen designs
(`mocks/<partner>/`) or the built-in default layouts will be used — confirmed at
intake ([`analyze-partner-codebase/SKILL.md`](../../../skills/analyze-partner-codebase/SKILL.md), Step 7.5 item 6); `n/a` for backend.*

| Surface | Repo path | In scope? | Card folder | Mocks |
|---|---|---|---|---|
| backend | `{APP_backend}` | `<fill: yes/no>` — TODO | `service-cards/backend/` | n/a |
| mobile | `{APP_mobile}` | `<fill: yes/no>` — TODO | `service-cards/mobile/` | `<fill: partner / defaults>` — TODO |
| web | `{APP_web}` | `<fill: yes/no>` — TODO | `service-cards/web/` | `<fill: partner / defaults>` — TODO |
| ios | `{APP_ios}` | `<fill: yes/no>` — TODO | `service-cards/ios/` | `<fill: partner / defaults>` — TODO |
| android | `{APP_android}` | `<fill: yes/no>` — TODO | `service-cards/android/` | `<fill: partner / defaults>` — TODO |

## 2. Out of scope

*Surfaces, repos, or apps that exist but are **explicitly excluded** from this
engagement, with the reason. This prevents wrong integration decisions later.*

| Surface / repo | Why out of scope |
|---|---|
| `<fill>` | TODO |
| TODO | TODO |

## 3. Monorepo vs multi-repo mapping

*How the surfaces above physically map to repositories. This **mirrors the
`.target-apps` registry** at the kit root (written by `./INSTALL.sh`) — a
surface's path is its own entry if present, else the `root` entry; a surface
with neither is not present. Record whether surfaces share one repo (monorepo)
or live in separate repos (multi-repo), since cross-repo paths ship with no
shared compile step. See [`../../../manual/methodology/modes.md`](../../../manual/methodology/modes.md#surface-registry-and-multi-repo-resolution).*

- **Topology:** `<fill: monorepo | multi-repo | mixed>` — TODO
- **Registry (`.target-apps`) entries observed:** `<fill>` — TODO

| Surface | Registry key used (`root` or own entry) | Resolved repo path | Shares repo with |
|---|---|---|---|
| backend | `<fill>` | `{APP_backend}` | `<fill: none / surface>` — TODO |
| mobile | `<fill>` | `{APP_mobile}` | `<fill>` — TODO |
| web | `<fill>` | `{APP_web}` | `<fill>` — TODO |
| ios | `<fill>` | `{APP_ios}` | `<fill>` — TODO |
| android | `<fill>` | `{APP_android}` | `<fill>` — TODO |
