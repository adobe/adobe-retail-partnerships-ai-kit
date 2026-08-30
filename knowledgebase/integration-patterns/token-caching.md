# Integration Pattern: IMS Token Caching

> **Token request/response contract:** see `knowledgebase/api-spec/ims-token.md`. This page covers only the **caching strategy** (when to refresh, the buffer window, thread-safety) — it does not restate the request params or response fields.

## Why This Matters

The IMS token endpoint has rate limits. Calling it on every API request will cause 429 errors under any real load. Tokens are valid for ~24 hours — there is no reason to request a new one more than once per day under normal conditions.

## The Pattern

```
┌─────────────────────────────────────────────────────────┐
│                    IMS Token Cache                       │
│                                                         │
│  First request:                                         │
│  [No cached token]                                      │
│       → Request new token from IMS                      │
│       → Store: { token, expiresAt = now + expires_in }  │
│       → Return token                                    │
│                                                         │
│  Subsequent requests (within valid window):             │
│  [Cached token, expiresAt > now + 300s]                 │
│       → Return cached token (no IMS call)               │
│                                                         │
│  Proactive refresh (5 min before expiry):               │
│  [Cached token, expiresAt <= now + 300s]                │
│       → Request new token from IMS                      │
│       → Update cache                                    │
│       → Return new token                                │
└─────────────────────────────────────────────────────────┘
```

## Why 5-Minute Buffer

If you refresh exactly at expiry, requests arriving in the instant between expiry and refresh will use an expired token. The 5-minute buffer ensures:
- High-traffic services: all in-flight requests complete before the token expires
- Clock skew: minor differences between your server clock and Adobe IMS are covered

## Thread Safety

In concurrent backend environments, multiple threads may simultaneously find the cache stale and all attempt to refresh. Without a lock, this causes a "thundering herd" against the IMS endpoint:

```
BAD (no lock):
  Thread 1: sees stale → requests new token
  Thread 2: sees stale → requests new token  ← duplicate IMS call
  Thread 3: sees stale → requests new token  ← duplicate IMS call

GOOD (with double-checked lock):
  Thread 1: sees stale → acquires lock → requests new token → updates cache → releases lock
  Thread 2: sees stale → waits for lock → re-checks → cache is fresh → returns cached token
  Thread 3: sees stale → waits for lock → re-checks → cache is fresh → returns cached token
```

## Reference Implementation (TypeScript)

```typescript
interface CachedToken {
  accessToken: string;
  expiresAt: number;  // Unix timestamp (seconds)
}

class ImsTokenService {
  private cachedToken: CachedToken | null = null;
  private refreshPromise: Promise<string> | null = null;
  private readonly REFRESH_BUFFER_SECONDS = 300;

  async getToken(): Promise<string> {
    if (this.isTokenValid()) {
      return this.cachedToken!.accessToken;
    }
    // Coalesce concurrent refreshes into a single IMS call
    if (!this.refreshPromise) {
      this.refreshPromise = this.refreshToken().finally(() => {
        this.refreshPromise = null;
      });
    }
    return this.refreshPromise;
  }

  private isTokenValid(): boolean {
    if (!this.cachedToken) return false;
    const nowSeconds = Math.floor(Date.now() / 1000);
    return this.cachedToken.expiresAt > nowSeconds + this.REFRESH_BUFFER_SECONDS;
  }

  private async refreshToken(): Promise<string> {
    // Build + POST the client_credentials request exactly as specified in
    // api-spec/ims-token.md (request params, endpoint, headers live there — not here).
    const data = await callImsTokenEndpoint();   // returns { access_token, expires_in, ... }
    const nowSeconds = Math.floor(Date.now() / 1000);

    this.cachedToken = {
      accessToken: data.access_token,
      expiresAt: nowSeconds + data.expires_in,
    };

    return this.cachedToken.accessToken;
  }
}
```

## Logging

```
event=ims.token.refreshed  source=cache_miss  latency=142ms
event=ims.token.served     source=cache_hit
event=ims.token.refresh_failed  error="IMS 401"  ← alert on this
```

Never log the token value itself.

## What to Do When Token Refresh Fails

If IMS is down or credentials are wrong, all Adobe API calls will fail. Handle this at the caller level:
1. Log the error with high severity
2. Return an appropriate error to the user ("Service temporarily unavailable")
3. Do not retry the IMS call in a tight loop — use exponential backoff
4. Monitor for IMS token refresh failures — they indicate a credentials problem or IMS outage
