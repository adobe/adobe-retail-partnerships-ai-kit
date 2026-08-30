# Connectors — {service_name}

*Every outbound dependency this backend calls: other services, datastores,
third-party APIs, and the Adobe Integration APIs. The inbound surface
belongs in [`CONTRACTS.md`](./CONTRACTS.md). Fill from the partner's real client
code, citing file paths.*

---

## 1. Overview

*One short paragraph: what this backend depends on downstream and the shared
HTTP-client / resilience conventions it uses. Note the security invariant that
all Adobe calls are backend-to-backend only.*

<fill> — TODO

## 2. Connector Summary

*One row per outbound dependency. Criticality = impact if this dependency is
down (e.g. blocking / degraded / optional).*

| # | Dependency | Protocol | Auth | Timeout | Retry | Circuit breaker | Criticality |
|---|---|---|---|---|---|---|---|
| 1 | <fill> | <fill: HTTP/gRPC/…> | <fill> | <fill> | <fill> | <fill: yes/no> | <fill> |
| 2 | TODO | TODO | TODO | TODO | TODO | TODO | TODO |

## 3. Connector Details

*One `### N. <name>` block per connector in the summary table.*

### 1. <connector name>

- **Purpose:** <fill: why this backend calls it>
- **Operations:**

  | Operation | Method / Path | Purpose |
  |---|---|---|
  | <fill> | `<fill>` | <fill> |
  | TODO | TODO | TODO |

- **Auth & transport:** <fill: credential source, headers, base URL config key>
- **Resilience:** <fill: timeout, retry policy, circuit breaker, backoff>
- **Error handling:** <fill: how documented error codes are mapped/handled — no
  silent catch-all per verification rule; distinguish not-configured from
  upstream error per rule 3>
- **Unavailability posture:** <fill: what happens to callers when this is down>

### 2. <connector name>

- **Purpose:** TODO
- **Operations:** TODO
- **Auth & transport:** TODO
- **Resilience:** TODO
- **Error handling:** TODO
- **Unavailability posture:** TODO

## 4. Adobe Integration Connectors

*The connectors that carry the Adobe integration. These are backend-to-backend
only — IMS credentials never leave this surface (verification rule 9). Fill each
row with the partner's real (or to-be-generated) client. The authoritative
request/response/error contract for each lives in
[`../../../knowledgebase/api-spec/`](../../../knowledgebase/api-spec/) — link to
the spec file, do not duplicate it here.*

| Connector | Direction | Contract spec | Status |
|---|---|---|---|
| IMS OAuth Token (`client_credentials`) | backend → Adobe IMS | [`ims-token.md`](../../../knowledgebase/api-spec/ims-token.md) | TODO |
| Workflow API (initiate Claim) | backend → Adobe | [`workflow-api.md`](../../../knowledgebase/api-spec/workflow-api.md) | TODO |
| Get Subscription | backend → Adobe | [`get-subscription.md`](../../../knowledgebase/api-spec/get-subscription.md) | TODO |
| Update Subscription (Cancel / Renew) | backend → Adobe | [`update-subscription.md`](../../../knowledgebase/api-spec/update-subscription.md) | TODO |
| Notify (Adobe → partner, optional) | Adobe → backend | [`notify-api.md`](../../../knowledgebase/api-spec/notify-api.md) | TODO |

*Notes: <fill — e.g. where the IMS token is cached, refresh-before-expiry
strategy, which env var names carry the credentials (see
[`BUILD_CONFIG.md`](./BUILD_CONFIG.md)). Note that Notify is an inbound endpoint
this backend hosts — its auth is captured in [`CONTRACTS.md`](./CONTRACTS.md).>*

## 5. Adding a New Connector

*The checklist a developer follows to add an outbound dependency to this service
correctly — where the client class goes (per [`MODULE_INDEX.md`](./MODULE_INDEX.md)
layers), how config/secrets are wired (per [`BUILD_CONFIG.md`](./BUILD_CONFIG.md)),
required resilience defaults, logging expectations, and tests.*

- <fill: step 1>
- TODO
