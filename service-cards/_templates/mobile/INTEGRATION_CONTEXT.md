# Integration Context — {surface}

> _Where the Adobe integration lives for THIS UI surface. Fill every `<fill>` /
> `TODO`. See [card-model §4.2](../../../manual/methodology/card-model.md)._

## Integration Points on This Surface

_Which screens/routes host each lifecycle step. Point at the concrete
route/file._

| Lifecycle step | Screen / Route | File |
|---|---|---|
| Claim flow | `<fill>` | `<fill>` |
| Manage / subscription status | `<fill>` | `<fill>` |
| Cancel flow | `<fill>` | `<fill>` |

## Session Seed for partner_reference_id

_Where the identity this surface carries comes from, and how it flows to the
partner backend (which derives `partner_reference_id`). Cross-reference
`STATE_MANAGEMENT.md`._

- **Identity source:** `<fill>`
- **Carried to backend via:** `<fill>`
- **Notes:** TODO

## Deep-Link / Return-from-Adobe Model

_How this surface hands off to an Adobe-hosted screen and handles the return.
Cross-reference `ROUTES.md` → Deep-Link / Return-from-Adobe Handling._

- **Hand-off mechanism:** `<fill>`
- **Return route / scheme:** `<fill>`
- **Post-return behavior:** `<fill>` (state re-fetch, success/cancel handling)

## Partner Backend This Surface Calls

_Which partner backend surface this UI proxies through (relevant in multi-repo
setups). This UI never calls Adobe directly._

- **Backend surface / repo:** `<fill>`
- **Base URL config key:** `<fill>` (placeholder — resolved from config, never hardcoded)
- **Notes:** TODO
