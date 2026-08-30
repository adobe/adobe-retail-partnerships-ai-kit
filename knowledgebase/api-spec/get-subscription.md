# Get Subscription API — API Specification

**Purpose:** Retrieve the current status of an Adobe subscription for a partner's customer.  
**Direction:** Partner Backend → Adobe  
**Use when:** Checking subscription state after activation, displaying status in-app, or polling as an alternative to the Notify API.

---

## Endpoint

| Environment | URL Pattern |
|---|---|
| Stage / Sandbox | `https://partners-stage.adobe.io/retail/v1/subscriptions/{partner_reference_id}` |
| Production | `https://partners.adobe.io/retail/v1/subscriptions/{partner_reference_id}` |

**Method:** GET  
**Content-Type:** `application/json`

---

## Authentication

```
Authorization: Bearer <access_token>   ← IMS token (same as Workflow API)
X-API-Key: <adobe-api-key>
```

---

## Path Parameters

| Parameter | Type | Required | Description |
|---|---|---|---|
| `partner_reference_id` | String | Yes | The partner's unique tracking ID for this customer+product combination. Same value used when calling the Workflow API. |

---

## Request

No request body. Path parameter only.

### Example Request

```bash
curl -X GET \
  'https://partners-stage.adobe.io/retail/v1/subscriptions/partner_9876543210_express_20260129' \
  -H 'Authorization: Bearer <access_token>' \
  -H 'X-API-Key: <api-key>'
```

---

## Response

### Success (200)

```json
{
  "partner_reference_id": "partner_9876543210_express_20260129",
  "offer_id": "30006514",
  "status": "ACTIVE",
  "start_date": "2026-01-29T00:00:00Z",
  "end_date": "2027-01-28T23:59:59Z"
}
```

### Response Fields

| Field | Type | Description |
|---|---|---|
| `partner_reference_id` | String | Echoes the path parameter |
| `offer_id` | String | Adobe offer ID associated with this subscription |
| `status` | String | Current subscription status. See status values below. |
| `start_date` | String (ISO 8601) | Subscription activation date |
| `end_date` | String (ISO 8601) | Subscription expiry date |

### Subscription Status Values

| Status | Meaning | Recommended UI |
|---|---|---|
| `ACTIVE` | Subscription is live and entitled | Show "Active" badge with end date |
| `CANCELLED` | Subscription has been cancelled | Show "Cancelled" state with option to re-claim |

---

## Error Responses

| Status | Cause | Action |
|---|---|---|
| 200 | Found | Display subscription details |
| 400 | Malformed `partner_reference_id` | Log, show generic error |
| 401 | Invalid/expired IMS token | Refresh token, retry once |
| 403 | Insufficient permissions | Log, surface as service unavailable |
| 404 | No subscription found | Subscription not yet activated, or unknown ID. Show "Not yet activated" or prompt to claim. |
| 5xx | Adobe server error | Retry with backoff |

---

## When to Call This API

### Polling vs. Notify API

| Approach | When to use |
|---|---|
| **Notify API** (recommended) | When your backend can host a webhook endpoint accessible from Adobe. Near-real-time. |
| **Get Subscription API** (polling) | When Notify API is not implemented. Poll after the user returns from `experience_url` or on app resume. |

### Recommended Polling Strategy

After the user is redirected to `experience_url` and returns to your app:
1. Poll `GET /v1/subscriptions/{id}` immediately
2. If status is not yet `ACTIVE`, poll again after 3 seconds
3. Poll up to 5 times with 3-second intervals
4. If still not `ACTIVE` after 5 polls, show a "Checking activation…" message and check again on next app open

Do not poll continuously in the background — this wastes resources and is not necessary given the Notify API option.

---

## Environment Variables Required

```
ADOBE_RETAIL_API_BASE_URL=https://partners-stage.adobe.io/retail
ADOBE_API_KEY=<your-api-key>
```

---

## Implementation Reference

The kit **generates** the find-subscription implementation when you run `implement-feature find-subscription` (Mode A) — the backend route (e.g. `bff/src/routes/subscription.ts`) and the UI status screens (e.g. under `lib/`), each in your target's own stack. The bundled `base-ref-app/` is intentionally **feature-less**, so these do not exist until you generate them; the `implement-feature` skill + `feature-specs/find-subscription/implementation.md` are the authoritative spec.
