# Update Subscription API — API Specification

**Purpose:** Update the status of an Adobe subscription. Currently supports cancellation. Renewal is TBA.  
**Direction:** Partner Backend → Adobe  
**Use when:** Customer cancels their subscription through your app, or customer churns/becomes ineligible.

---

## Endpoint

| Environment | URL Pattern |
|---|---|
| Stage / Sandbox | `https://partners-stage.adobe.io/retail/v1/subscriptions/{partner_reference_id}` |
| Production | `https://partners.adobe.io/retail/v1/subscriptions/{partner_reference_id}` |

**Method:** POST  
**Content-Type:** `application/json`

---

## Authentication

```
Authorization: Bearer <access_token>   ← IMS token
X-API-Key: <adobe-api-key>
```

---

## Path Parameters

| Parameter | Type | Required | Description |
|---|---|---|---|
| `partner_reference_id` | String | Yes | The partner's unique tracking ID for this subscription |

---

## Request Body — Cancel Subscription

```json
{
  "type": "CANCEL",
  "reason_code": "USER_CANCELLED"
}
```

### Request Fields

| Field | Type | Required | Description |
|---|---|---|---|
| `type` | String (enum) | Yes | Type of update. Supported: `CANCEL`. (`RENEW` TBA) |
| `reason_code` | String (enum) | Yes for CANCEL | Cancellation reason. See values below. |

### `reason_code` Values

| Value | When to use |
|---|---|
| `USER_CANCELLED` | Customer explicitly requested cancellation via your UI |
| `NOT_ELIGIBLE` | Partner-initiated cancellation: customer churned, no longer a subscriber, subscription tier downgrade, account closure |

---

## Request Body — Renew Subscription

TBA — specification not yet published by Adobe. Do not implement until spec is available.

---

## Response

### Success (200)

```json
{
  "partner_reference_id": "partner_9876543210_express_20260129",
  "offer_id": "30006514",
  "status": "CANCELLED",
  "start_date": "2026-01-29T00:00:00Z",
  "end_date": "2027-01-28T23:59:59Z"
}
```

Response shape is identical to Get Subscription API — updated subscription with new status.

---

## Error Responses

| Status | Cause | Action |
|---|---|---|
| 200 | Cancelled successfully | Update local subscription record, show cancellation confirmation |
| 400 | Invalid `partner_reference_id` or malformed body | Log error, show generic error |
| 401 | Invalid/expired IMS token | Refresh token, retry once |
| 403 | Insufficient permissions | Log, surface as service unavailable |
| 404 | Subscription not found | May already be cancelled or never activated. Treat as success from UX perspective. |
| 409 | Already cancelled | Idempotent — treat as success, subscription is already in the desired state |
| 5xx | Adobe server error | Retry with backoff |

---

## Cancellation Flow

```
User taps "Cancel subscription"
        │
        ▼
Show confirmation dialog
        │
        ▼
Partner Backend: POST /v1/subscriptions/{id}
  body: { "type": "CANCEL", "reason_code": "USER_CANCELLED" }
        │
        ├─ 200 ──► Update local subscription state → show cancellation confirmation
        ├─ 409 ──► Already cancelled → show "already cancelled" message
        ├─ 404 ──► Not found → treat as cancelled → show confirmation
        └─ 5xx ──► Retry up to 3 times → if all fail, show transient error
```

---

## Important: Subscription Lifecycle After Cancellation

**After a subscription is cancelled:**
- The `partner_reference_id` used for the original claim is **permanently retired**
- If the customer re-purchases the same product, you **must generate a new** `partner_reference_id`
- Attempting to reuse a cancelled `partner_reference_id` with a new claim will result in an error

**Adobe will also notify you** (if Notify API is configured) when Adobe-side cancellation events occur (e.g. non-renewal, payment failure). These do not require you to call the Update Subscription API — they are informational callbacks.

---

## Environment Variables Required

```
ADOBE_RETAIL_API_BASE_URL=https://partners-stage.adobe.io/retail
ADOBE_API_KEY=<your-api-key>
```

---

## Implementation Reference

The kit **generates** the cancel-subscription implementation when you run `implement-feature cancel-subscription` (Mode A) — the backend route (e.g. `bff/src/routes/subscription.ts`) and the UI cancellation flow (e.g. under `lib/`), each in your target's own stack. The bundled `base-ref-app/` is intentionally **feature-less**, so these do not exist until you generate them; the `implement-feature` skill + `feature-specs/cancel-subscription/implementation.md` are the authoritative spec.
