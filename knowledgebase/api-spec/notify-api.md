# Notify API — API Specification

**Purpose:** Adobe calls the partner's Notify endpoint to push subscription lifecycle events: activation, cancellation, and renewal.  
**Direction:** Adobe → Partner Backend  
**Optionality:** Optional but strongly recommended. Partners who do not implement this must poll the Get Subscription API instead.

---

## Overview

The Notify API is a webhook that **you host**. You provide Adobe with the endpoint URL and authentication details during onboarding. Adobe calls your endpoint after:
- Successful subscription activation (after user completes Adobe experience UI)
- Subscription cancellation (user-initiated or system-initiated)
- Subscription renewal

---

## Your Endpoint Requirements

| Requirement | Detail |
|---|---|
| **Protocol** | HTTPS only |
| **Method** | POST |
| **Response time** | Respond within 10 seconds |
| **Success response** | Any `2xx` status code |
| **Idempotency** | Required — same payload may be delivered more than once; return `2xx` without creating duplicate records |
| **Availability** | Must be reachable from Adobe's egress IPs (provide IP allowlist during onboarding for stage) |

---

## Request from Adobe

### Headers (from Adobe) — auth type chosen at onboarding

**You own the auth on this endpoint** — secure it the way you already secure your inbound APIs. You register **one** auth type with Adobe at onboarding; Adobe stores it and **replays exactly that** on every Notify call, and your endpoint validates accordingly. In every type the credential/token is ultimately **yours** — either a secret you give Adobe to replay, or a token Adobe fetches from your own token endpoint. The five supported types (and the fields each uses):

| Type | What Adobe sends | Fields |
|---|---|---|
| `STATIC` | One fixed header: `<headerName>: <valuePrefix><headerValue>` (e.g. `Authorization: Bearer <secret>`, or `X-Api-Key: <secret>`) | `headerName`, `headerValue`, `valuePrefix` |
| `BASIC` | `Authorization: Basic base64(username:password)` | `username`, `password` |
| `CUSTOM_HEADERS` | Multiple fixed headers | `headers` (map) |
| `OAUTH2_CLIENT_CREDENTIALS` | `Authorization: Bearer <token>` — Adobe obtains the token from **your** `tokenUrl` via `client_credentials` | `tokenUrl`, `clientId`, `clientSecret`, `scope` |
| `CUSTOM_TOKEN` | `Bearer <token>` or a custom header — Adobe obtains it from **your** `tokenApiUrl` and extracts it via `tokenResponsePath` | `tokenApiUrl`, `tokenApiMethod`, `tokenApiRequestBody`, `tokenApiHeaders`, `tokenResponsePath`, `tokenUsage`, `tokenHeaderName` |

`STATIC` / `BASIC` / `CUSTOM_HEADERS` are static credentials you give Adobe to replay. `OAUTH2_CLIENT_CREDENTIALS` / `CUSTOM_TOKEN` are tokens Adobe fetches from **your** token endpoint and replays — so you validate **your own** issued token.

> **If your inbound auth isn't one of these five** (e.g. mutual-TLS or an API gateway that terminates auth before your app), that's fine — it's still your mechanism. Discuss it with Adobe partner engineering at onboarding to confirm what Adobe can send, and validate with your existing mechanism. Don't retrofit one of the five just to fit the table.

**Always validate the auth credentials before processing the payload.**

### Request Body

```json
{
  "partner_subscription_id": "partner_9876543210_express_20260129",
  "status": "Active",
  "startDate": "2026-01-29T00:00:00Z",
  "endDate": "2027-01-28T23:59:59Z",
  "timestamp": "2026-01-29T10:30:00Z"
}
```

### Request Fields

| Field | Type | Description |
|---|---|---|
| `partner_subscription_id` | String | Same value as `partner_reference_id` used in the Workflow API call |
| `status` | String | `"Active"` or `"Cancelled"` |
| `startDate` | String (ISO 8601) | Subscription start date |
| `endDate` | String (ISO 8601) | Subscription end date (or cancellation effective date) |
| `timestamp` | String (ISO 8601) | When the event occurred on Adobe's side |

### Status Values

| Value | Meaning |
|---|---|
| `"Active"` | Subscription activated or renewed |
| `"Cancelled"` | Subscription cancelled |

---

## Response from Your Endpoint

| Status | When to return |
|---|---|
| `200 OK` | Payload processed successfully (including duplicate/idempotent delivery) |
| `400 Bad Request` | Payload is malformed or missing required fields |
| `401 Unauthorized` | Auth credentials invalid |
| `5xx` | Genuine server error — Adobe will retry |

**Do NOT return 5xx for business logic errors** (e.g. subscription not found in your system). Return `200` and handle the discrepancy internally.

---

## Implementation Requirements

### 1. Auth Validation

Validate Adobe's auth credentials on every request before processing:

```
if auth credentials do not match expected values:
  return 401 Unauthorized
  log: "Notify API: rejected unauthorised request from {ip}"
```

### 2. Idempotency

```
incomingKey = (partner_subscription_id, status, timestamp)

if already processed (incomingKey in processed_events):
  return 200 OK   ← do not re-process, just acknowledge
  
process the event
store (incomingKey) in processed_events
return 200 OK
```

A simple approach: store `(partner_subscription_id, status, timestamp)` as a unique key. If already seen, return 200 immediately.

### 3. Event Processing Logic

```
on status = "Active":
  update local subscription record to ACTIVE
  store startDate, endDate
  trigger any internal notifications (push notification, email, etc.)

on status = "Cancelled":
  update local subscription record to CANCELLED
  update endDate
  trigger any internal notifications
```

### 4. Asynchronous Processing (Recommended)

For reliability, acknowledge Adobe immediately (return 200) and process the event asynchronously:

```
POST /notify received
  ├─ Validate auth → 401 if invalid
  ├─ Validate body → 400 if malformed
  ├─ Enqueue event to internal queue/worker
  └─ Return 200 immediately

Internal worker:
  ├─ Process event (update DB, send notifications)
  └─ Handle failures with internal retry
```

This ensures Adobe always receives a timely 2xx and your internal failures don't cause Adobe to retry unnecessarily.

---

## Error Handling

| Scenario | Your Response | Adobe Behaviour |
|---|---|---|
| Valid payload, processed successfully | 200 | No retry |
| Valid payload, already processed (duplicate) | 200 | No retry |
| Invalid auth | 401 | Adobe may alert; check with Adobe partner engineering |
| Malformed payload | 400 | No retry (client error) |
| Your server error | 500+ | Adobe retries with backoff |
| Your server timeout (>10s) | — | Adobe retries |

---

## Logging

Log every incoming Notify request with:
```
event: "notify.received"
partner_subscription_id: <value>
status: <value>
timestamp: <value>
auth_valid: true/false
duplicate: true/false
```

---

## Onboarding Information to Provide Adobe

During onboarding, provide Adobe with:
1. Your Notify API endpoint URL (HTTPS)
2. The auth type you registered (one of `STATIC`, `BASIC`, `CUSTOM_HEADERS`, `OAUTH2_CLIENT_CREDENTIALS`, `CUSTOM_TOKEN`) and the corresponding credentials/config (see Headers above).
3. Your stage IP allowlist expectations
4. A test `partner_subscription_id` that returns 200 for integration testing

---

## Environment Variables Required

Config depends on the auth type you registered (above):

- `STATIC` — the expected header name + secret value, e.g. `ADOBE_NOTIFY_AUTH_SECRET=<secret-for-validating-incoming-calls>`
- `BASIC` — the expected username + password
- `CUSTOM_HEADERS` — the expected header name(s) + value(s)
- `OAUTH2_CLIENT_CREDENTIALS` / `CUSTOM_TOKEN` — **no Adobe-specific secret**; you validate the token against your own identity/token layer (issuer / JWKS / introspection), using whatever config that layer already requires.

Read every value from your config/secret store — never hardcode a credential in source.

---

## Implementation Reference

The kit **generates** the notify-handler implementation when you run `implement-feature notify-handler` (Mode A) — the partner-hosted webhook route, in your target's own stack, with auth validation, idempotency, and async processing wired per the implementation contract. The bundled `base-ref-app/` is intentionally **feature-less**, so this does not exist until you generate it; the `implement-feature` skill + `feature-specs/notify-handler/implementation.md` are the authoritative spec.
