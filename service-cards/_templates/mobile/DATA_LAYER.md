# Data Layer — {surface}

> _How this UI surface talks to the partner's backend. Fill every `<fill>` /
> `TODO`. See [card-model §3.2](../../../manual/methodology/card-model.md) and the
> [backend-proxy pattern](../../../knowledgebase/integration-patterns/backend-proxy-pattern.md)._

## Overview

_State the four facts that govern every remote call on this surface._

- **Data-fetch library:** `<fill>` (e.g. dio, fetch/axios, URLSession, Retrofit)
- **Auth-token injection:** `<fill>` (how the session token reaches the request)
- **Freshness policy:** `<fill>` (cache / revalidate / always-fresh)
- **Error surface:** `<fill>` (how errors reach the UI)

## Read Layer — Registry

_Every read this UI performs. The endpoint is a route on the PARTNER backend,
never an Adobe URL._

| Domain | Read Unit | Endpoint (partner backend) | Auth Injection |
|---|---|---|---|
| `<fill>` | `<fill>` | `<fill>` | `<fill>` |

## Write Layer

_Every write/mutation this UI performs (claim initiation, cancel, …). Same
partner-backend rule applies._

| Domain | Write Unit | Endpoint (partner backend) | Auth Injection |
|---|---|---|---|
| `<fill>` | `<fill>` | `<fill>` | `<fill>` |

## Auth Token Injection

_Where the session/auth token comes from and how it is attached to each request
(interceptor, header, middleware). Name the exact file/symbol._

- TODO

## Error Handling Posture

_How network/HTTP errors are classified and surfaced. Note especially how a
"integration not configured" response from the backend is distinguished from a
real upstream error (mirrors [verification rule 3](../../../manual/methodology/verification.md))._

- TODO

## Backend-Proxy Rule

> **This UI NEVER calls Adobe directly.** Every request goes to the partner's own
> backend, which holds the IMS credentials and calls Adobe backend-to-backend.
> This is enforced by [verification rule 9 (secret containment)](../../../manual/methodology/verification.md)
> and required by [card-model §3.2](../../../manual/methodology/card-model.md). No Adobe base
> URL, IMS endpoint, or `*_CLIENT_SECRET` may ever appear in this surface's code.

- **Partner backend base URL (config key):** `<fill>` (a placeholder — resolve
  from this surface's config; never hardcode per [verification rule 6](../../../manual/methodology/verification.md))
- **Confirmation:** grep of this repo for Adobe/IMS hostnames and secret names →
  `TODO` (must be empty)

## Adding a New Read Unit — Checklist

_Steps a generator follows to add a read without breaking the contract._

- [ ] Endpoint points at the partner backend (never Adobe).
- [ ] Path matches the backend route character-for-character ([rule 2](../../../manual/methodology/verification.md)).
- [ ] Auth token injected via the surface's standard mechanism (above).
- [ ] Registered in the Read Layer table.
- [ ] Error posture handled; not-configured ≠ upstream error.
- [ ] Unit test added alongside.
