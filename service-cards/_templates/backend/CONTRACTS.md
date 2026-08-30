# Contracts — {service_name}

*The inbound surface this backend exposes: every HTTP endpoint it serves and
every async message it consumes/publishes. Outbound calls belong in
[`CONNECTORS.md`](./CONNECTORS.md). Fill from the partner's real routing code,
citing file paths. This card feeds path-consistency rule 2 and inbound-auth
rule 7 in [`../../../manual/methodology/verification.md`](../../../manual/methodology/verification.md).*

---

## Overview

*The framing every consumer needs before reading individual operations.*

- **Base path:** `<fill: server mount prefix, e.g. /api/v1>` — if this backend
  is purely async/queue-driven with no synchronous API surface, `Base path:
  N/A — async-only` is a valid, expected value here (symmetric with the "if
  purely synchronous, state 'None' explicitly" guidance in Async Contracts
  below).
- **Auth scheme (end-user):** *<fill: how normal end-user requests are
  authenticated — session cookie, bearer JWT, etc.>*
- **Inbound caller auth (machine callers):** *Distinct from the end-user scheme
  above. How does this backend authenticate an external/machine caller (e.g. the
  Adobe Notify webhook)? Name the registered type — one of `STATIC`, `BASIC`,
  `CUSTOM_HEADERS`, `OAUTH2_CLIENT_CREDENTIALS`, `CUSTOM_TOKEN` — and the code
  that verifies it. See [`../../../knowledgebase/api-spec/notify-api.md`](../../../knowledgebase/api-spec/notify-api.md).
  If unclear from the code, mark `TODO — ASK PARTNER` (verification rule 8).*
  - <fill> — TODO
- **Default authorization:** *Does the framework deny or permit unauthenticated
  requests by default? If deny-by-default (e.g. Spring Security, a global
  guard), record the allow-list mechanism and where machine endpoints must be
  permitted through the chain before per-request validation runs.*
  - <fill: deny-by-default | permit-by-default + where the allow-list lives> — TODO

## APIs We Expose

*One `### <METHOD> /<path> — <purpose>` block per operation. Copy the exact path
string (base path + route) so rule 2 can compare it against the client repo
character-for-character. Do not invent params — read them from the handler.*

*This REST shape is the default, not the only shape. If your backend exposes
**gRPC**: list `service Name { rpc Method(Req) returns (Res) }` pairs instead.
If **GraphQL**: list the relevant Query/Mutation operation names and their type
signatures instead of REST paths. If your backend is queue/event-only — see
Async Contracts below — and truly has no synchronous API surface, state
"None — async-only, see Async Contracts" explicitly rather than leaving this
section blank.*

### `<METHOD> /<path>` — <purpose>

- **Auth:** <fill: which scheme from Overview applies>
- **Path params:** `<fill or "none">`
- **Query params:** `<fill or "none">`
- **Request body:** `<fill: shape / type, or "none">`
- **Response 2xx:** `<fill: status + body shape>`
- **Error responses:** `<fill: status → meaning, per handled code>`
- **Delegate:** `<fill: service/method this route delegates to>`

### `<METHOD> /<path>` — <purpose>

- **Auth:** TODO
- **Path params:** TODO
- **Query params:** TODO
- **Request body:** TODO
- **Response 2xx:** TODO
- **Error responses:** TODO
- **Delegate:** TODO

## Async Contracts

*Message-based contracts, if any. If the backend is purely synchronous, state
"None" explicitly rather than deleting the section.*

### Events We Consume

| Topic / Channel | Payload | Handler | Idempotency notes |
|---|---|---|---|
| <fill> | <fill> | `<fill: file>` | <fill> |
| TODO | TODO | TODO | TODO |

### Events We Publish

| Topic / Channel | Payload | Emitted by | Trigger |
|---|---|---|---|
| <fill> | <fill> | `<fill: file>` | <fill> |
| TODO | TODO | TODO | TODO |
