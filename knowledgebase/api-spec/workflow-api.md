# Workflow API — API Specification

**Purpose:** Initiate a product claim workflow for a partner's customer. Returns an `experience_url` to redirect the user to Adobe's hosted activation UI.  
**Direction:** Partner Backend → Adobe  
**Current supported workflow:** `CLAIM_PRODUCT`

---

## Endpoint

| Environment | URL |
|---|---|
| Stage / Sandbox | `https://partners-stage.adobe.io/retail/v1/workflows` |
| Production | `https://partners.adobe.io/retail/v1/workflows` |

**Method:** POST  
**Content-Type:** `application/json`

---

## Authentication

Both headers are required on every request:

```
Authorization: Bearer <access_token>   ← IMS token from client_credentials grant
X-API-Key: <adobe-api-key>             ← API key provided at onboarding
```

See `api-spec/ims-token.md` for how to obtain `access_token`.

---

## Request Body

```json
{
  "workflow_type": "CLAIM_PRODUCT",
  "workflow_attributes": [
    {
      "key": "partner_reference_id",
      "value": "sub_partner_9876543210_express_2026"
    },
    {
      "key": "offer_id",
      "value": "30006514"
    }
  ]
}
```

### Fields

| Field | Type | Required | Description |
|---|---|---|---|
| `workflow_type` | String (enum) | Yes | Currently only `CLAIM_PRODUCT` supported |
| `workflow_attributes` | Array | Yes, non-empty | Key-value pairs providing workflow context |
| `workflow_attributes[].key` | String | Yes | Attribute name |
| `workflow_attributes[].value` | String | Yes | Attribute value |

### Required Workflow Attributes for `CLAIM_PRODUCT`

| Key | Description | Rules |
|---|---|---|
| `partner_reference_id` | Partner's unique tracking ID for this customer+product combination | Must be unique per (customer, product) pair. Permanent — once used with an `offer_id`, cannot be reused with a different `offer_id`. After cancellation + re-purchase, generate a **new** `partner_reference_id`. |
| `offer_id` | Adobe-assigned offer identifier | Provided at onboarding. Identifies which product/SKU the customer is claiming. |

### `partner_reference_id` Generation Guidance

```
Format recommendation: {partner_prefix}_{customer_id}_{product_code}_{timestamp_or_sequence}
Example: partner_9876543210_express_20260129
```

- Must be unique within your system
- Treat as an opaque string on Adobe's side (max 255 characters, alphanumeric + hyphens/underscores)
- Store it in your database alongside the customer record

---

## Response

### Success (202 Accepted)

```json
{
  "workflow_type": "CLAIM_PRODUCT",
  "experience_url": "https://redeem.adobe.com/express-premium?asm=cs&rc=NHYT-6Y3Y&pid=partner&uuid=zxXJczyeP",
  "short_experience_url": "https://www.adobe.com/go/retail?uuid=zxXJczyeP",
  "workflow_attributes": [
    { "key": "partner_reference_id", "value": "partner_9876543210_express_20260129" },
    { "key": "offer_id", "value": "30006514" }
  ]
}
```

### Response Fields

| Field | Type | Required | Description |
|---|---|---|---|
| `workflow_type` | String | Yes | Echoes the requested `workflow_type` |
| `experience_url` | String | Yes | Full URL for in-app redirect (webview or system browser) |
| `short_experience_url` | String | No | Shortened URL for SMS/messaging channels only. Adds an extra redirect step — do not use in-app. |
| `workflow_attributes` | Array | Yes | Echoes the input attributes |

### Redirect (302)

For Affinity/OEM partners, Adobe may return a 302 redirect directly to the `experience_url`. Your HTTP client must follow this redirect automatically or extract the `Location` header.

---

## Error Responses and Handling

### All Response Codes

| Status | Error Code | Scenario | Partner Action |
|---|---|---|---|
| 202 | — | New workflow initiated | Redirect user to `experience_url` |
| 202 | — | Duplicate unfulfilled request (idempotent) | Redirect user to same `experience_url` |
| 302 | — | Redirect for Affinity/OEM partners | Follow redirect / extract Location header |
| 400 | `INVALID_OFFER` | `offer_id` is not valid for this partner | Log error. Show user: "This offer is not available. Please contact support." |
| 400 | `SUBSCRIPTION_ID_ALREADY_IN_USE` | Same `partner_reference_id`, different `offer_id` | Internal data error — log with high severity. Show generic error to user. |
| 401 | — | IMS token expired or invalid | Refresh IMS token and retry the request exactly once |
| 403 | — | Partner config not found, inactive, or insufficient permissions | Show full-screen error: "Service temporarily unavailable. Please try again later or contact support." Do not retry automatically. |
| 409 | `ALREADY_FULFILLED` | Subscription already activated | Do not re-initiate. Navigate user to subscription status screen. |
| 5xx | — | Adobe server error | Retry with exponential backoff: 1s, 2s, 4s (max 3 attempts). If all fail, show transient error with retry option. |

---

## Integration Flow

```
Partner App/Web  →  Partner Backend  →  Adobe Workflow API
                         │
                         ├─ 1. Get IMS token (cache-aware)
                         ├─ 2. POST /v1/workflows
                         ├─ 3. Receive experience_url (202)
                         └─ 4. Return experience_url to frontend
                                     ↓
                    Partner App/Web redirects user to experience_url
                                     ↓
                         Adobe Redemption UI
                         (user signs in/up, consents, activates)
                                     ↓
                    Adobe calls partner Notify API (if configured)
                         OR partner polls Get Subscription API
```

---

## Idempotency Behaviour

| Scenario | Behaviour |
|---|---|
| Same `partner_reference_id` + same `offer_id`, order NOT yet fulfilled | Returns same `experience_url` — 202. Safe to call again (e.g. user pressed back and re-claimed). |
| Same `partner_reference_id` + same `offer_id`, order FULFILLED | Returns 409 `ALREADY_FULFILLED`. Navigate to subscription status. |
| Same `partner_reference_id` + **different** `offer_id` | Returns 400 `SUBSCRIPTION_ID_ALREADY_IN_USE`. This is a partner data error — the same ID must never be used with two different offers. |

---

## Environment Variables Required

```
ADOBE_RETAIL_API_BASE_URL=https://partners-stage.adobe.io/retail
ADOBE_API_KEY=<your-api-key>
ADOBE_OFFER_ID=<your-offer-id>
```

---

## Implementation Reference

The kit **generates** the claim implementation when you run `implement-feature claim-product` (Mode A) — the backend route (e.g. `bff/src/routes/claim.ts`) and the UI claim flow (e.g. under `lib/`), each in your target's own stack. The bundled `base-ref-app/` is intentionally **feature-less**, so these do not exist until you generate them; the `implement-feature` skill + `feature-specs/claim-product/implementation.md` are the authoritative spec.
