# Routes — {surface}

> _Route registry for this UI surface. Fill every `<fill>` / `TODO`. See
> [card-model §3.2](../../../manual/methodology/card-model.md)._

## Overview

_State the routing library and the four facts a reader needs to reason about
navigation on this surface._

- **Router:** `<fill>` (e.g. go_router, React Router, native navigator)
- **Auth guard mechanism + location:** `<fill>`
- **Root redirect (authenticated):** `<fill>`
- **Unauthenticated redirect:** `<fill>`

## Route Registry

_One row per route on this surface. "Preconditions" = state that must exist
before the route renders (e.g. an active session, a resolved offer)._

| Path | File | Path params | Auth required | Preconditions |
|---|---|---|---|---|
| `<fill>` | `<fill>` | `<fill>` | `<yes/no>` | TODO |
| `<fill>` | `<fill>` | `<fill>` | `<yes/no>` | TODO |

## Auth Guard Pattern

_Describe how a route is gated: where the guard runs, what it checks, and what it
does on failure. Reference the exact file/symbol._

- TODO

## Navigation Patterns

_How the app moves between screens (push/replace, named vs typed routes, passing
params) and any conventions generated screens must follow._

- TODO

## Deep-Link / Return-from-Adobe Handling

_Dedicated: how this surface handles returning from an Adobe-hosted screen (the
claim flow hands off to an Adobe URL, then the user returns). Cover the return
route/scheme, how the app detects success vs cancel/abandon, and how it
re-fetches subscription state on return._

- **Return route / URI scheme:** `<fill>`
- **Success vs cancel detection:** TODO
- **State re-fetch on return:** TODO
- **Notes:** TODO
