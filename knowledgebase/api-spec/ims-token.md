# IMS Token Generation — API Specification

**Source:** Adobe Identity Management System (IMS)  
**Purpose:** Obtain an OAuth 2.0 `client_credentials` access token for authenticating all Adobe Integration API calls.  
**Direction:** Partner Backend → Adobe IMS

---

## Endpoints

| Environment | URL |
|---|---|
| Stage / Sandbox | `https://ims-na1-stg1.adobelogin.com/ims/token/v3` |
| Production | `https://ims-na1.adobelogin.com/ims/token/v3` |

---

## Request

**Method:** POST  
**Content-Type:** `application/x-www-form-urlencoded`  
**No Authorization header required** (credentials in body)

### Parameters

| Parameter | Required | Description |
|---|---|---|
| `grant_type` | Yes | Must be `client_credentials` |
| `client_id` | Yes | Adobe-issued client ID (provided at onboarding) |
| `client_secret` | Yes | Adobe-issued client secret (provided at onboarding) |
| `scope` | Yes | Comma-separated required scopes (provided at onboarding) |

### Example Request

```bash
curl -X POST 'https://ims-na1.adobelogin.com/ims/token/v3' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'grant_type=client_credentials&client_id=YOUR_CLIENT_ID&client_secret=YOUR_CLIENT_SECRET&scope=YOUR_SCOPES'
```

---

## Response

### Success (200)

```json
{
  "access_token": "eyJhbGciOiJSUzI1NiJ9...",
  "token_type": "bearer",
  "expires_in": 86399
}
```

### Response Fields

| Field | Type | Description |
|---|---|---|
| `access_token` | String | Bearer token for all Adobe Retail API calls. Valid for `expires_in` seconds. |
| `token_type` | String | Always `"bearer"` |
| `expires_in` | Integer | Seconds until expiry. Typically `86399` (~24 hours). |

### Error Responses

| Status | Cause | Action |
|---|---|---|
| 400 | Malformed request or invalid `grant_type` | Check request params |
| 401 | Invalid `client_id` or `client_secret` | Verify onboarding credentials |
| 403 | Insufficient scope | Request correct scopes during onboarding |

---

## Token Lifecycle and Caching

### Rules

1. **Cache in memory.** Store the token and its expiry timestamp (`now + expires_in`).
2. **Proactive refresh.** Request a new token when fewer than **300 seconds** (5 minutes) remain before expiry. This prevents failures under load when a request arrives just as the token expires.
3. **No refresh token.** Re-request using the same `client_credentials` grant.
4. **Separate tokens per environment.** Stage credentials only work against stage IMS; production credentials only work against production IMS.
5. **Thread-safe caching.** Token refresh must be thread-safe — use a lock or atomic check-and-set to prevent concurrent refresh storms.

### Token Cache Algorithm

```
function getToken():
  if cachedToken is not null AND now < cachedToken.expiresAt - 300s:
    return cachedToken.accessToken
  
  # Acquire refresh lock (prevent concurrent refreshes)
  lock.acquire():
    # Double-check after acquiring lock
    if cachedToken is not null AND now < cachedToken.expiresAt - 300s:
      return cachedToken.accessToken
    
    newToken = callImsTokenEndpoint()
    cachedToken = { accessToken: newToken.access_token, expiresAt: now + newToken.expires_in }
    return cachedToken.accessToken
```

### Environment Variables Required

```
# Full token endpoint including path (not just the base URL).
ADOBE_IMS_TOKEN_URL=https://ims-na1-stg1.adobelogin.com/ims/token/v3   # stage
ADOBE_IMS_CLIENT_ID=<your-client-id>
ADOBE_IMS_CLIENT_SECRET=<your-client-secret>
ADOBE_IMS_SCOPES=<comma-separated-scopes>
```

> These are the canonical **fallback** names. When the partner's codebase already
> uses its own IMS var names, reuse those exactly (Code Generation Protocol rule 1).

---

## Security Requirements

- `CLIENT_ID` and `CLIENT_SECRET` must be stored as environment variables — never in code or config files committed to source control
- The IMS token must only be used from backend services — never passed to mobile or web frontends
- Log the token request (latency, response status) but **never log the token value or the client secret**
- Rotate credentials if they are ever exposed; contact Adobe partner engineering immediately

---

## Implementation Reference

The kit **generates** a complete IMS token client when you run `generate-adobe-clients` (Mode A, Phase 1) — typically at `bff/src/ims/tokenService.ts` (or the equivalent path/stack for your backend). The bundled `base-ref-app/` is intentionally **feature-less**, so this file does not exist until you generate it; the `generate-adobe-clients` skill (Phase 1) is the authoritative spec for what it contains.
