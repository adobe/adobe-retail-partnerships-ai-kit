# Integration Pattern: Error Handling

## Principles

1. **Handle every documented error code explicitly.** No silent catch-all that swallows errors.
2. **Map Adobe errors to user-meaningful messages.** Never show raw API error codes to users.
3. **Distinguish retriable from non-retriable errors.** Retry 5xx; do not retry 4xx (except 401).
4. **Log everything.** Every error must be logged with `partner_reference_id` and response details.
5. **Degrade gracefully.** Errors in the subscription status check should not crash the app — show a retry state.

---

## Error Code → UX Mapping

> The authoritative per-endpoint status/error-code tables live in `knowledgebase/api-spec/` — **`workflow-api.md`**, **`get-subscription.md`**, **`update-subscription.md`**, **`notify-api.md`** (and `ims-token.md`). Do not re-list them here. This section maps those documented codes to **cross-cutting handling decisions** (user message, retry, alerting) that apply across endpoints.

| Class of response | User-facing message | Retry? | Notes |
|---|---|---|---|
| `400` business-data error (e.g. `INVALID_OFFER`, `SUBSCRIPTION_ID_ALREADY_IN_USE`) | "Something went wrong. Please try again." / "This offer is not available." | No | Log; `SUBSCRIPTION_ID_ALREADY_IN_USE` and config errors → HIGH severity + alert |
| `401` invalid/expired token | (internal — do not surface) | Yes, **once** after token refresh | A second 401 = credentials problem; do not retry further |
| `403` partner not configured/inactive | "Service temporarily unavailable…" (full-screen) | No | Partner config issue at Adobe — alert engineering |
| `404` on Get/Update Subscription | (not an error) | No | Get: show "Not yet activated". Cancel: treat as success |
| `409` (`ALREADY_FULFILLED` on claim; already-cancelled on cancel) | (not an error) | No | Claim: navigate to status. Cancel: treat as success (idempotent) |
| `5xx` server error | "Something went wrong. Please try again." | Yes, up to 3× | Exponential backoff: 1s, 2s, 4s |
| Network timeout | "Connection failed. Check your internet and try again." | Yes, once | |

The exact code that produces each class per endpoint is in the api-spec files linked above; the 404/409 "treat as success" rules are detailed in `idempotency.md`.

---

## Retry Strategy

```
function callWithRetry(fn, maxAttempts = 3):
  for attempt in 1..maxAttempts:
    try:
      response = fn()
      return response
    catch 5xx:
      if attempt == maxAttempts:
        throw
      wait(2^(attempt-1) seconds)  // 1s, 2s, 4s
    catch 401:
      if attempt == 1:
        refreshImsToken()
        continue
      throw  // If 401 after token refresh, it's a credentials problem
    catch 4xx (other than 401):
      throw  // Do not retry 4xx
```

---

## 403 Full-Screen Error Pattern

A 403 from the Workflow API means the partner's configuration at Adobe is wrong (inactive, not configured). This cannot be resolved by the user. Show a full-screen error:

```
"Service Temporarily Unavailable"
[Partner logo]

We're having trouble connecting to this service.
Please try again later.

If the problem persists, contact [partner support].
Reference: [timestamp or correlation ID for support]

[Try Again]  [Contact Support]
```

Do NOT show a simple toast or inline error — this is a serious error that requires partner engineering attention.

---

## 401 Token Refresh Handling

```
on 401 from any Adobe API call:
  1. Invalidate cached IMS token
  2. Request new token from IMS
  3. Retry the original request with new token
  4. If still 401: log with HIGH severity (credentials problem)
     Return "Service unavailable" to user — do not retry further
```

Never retry 401 more than once. A second 401 after a fresh token means a credentials or permissions problem.

---

## Logging Template

Every Adobe API call must produce a structured log:

**On success:**
```
event=adobe_api.success
api=workflow_initiate | get_subscription | cancel_subscription | ims_token
partner_reference_id=<value>
http_status=202
latency_ms=143
environment=stage
```

**On error:**
```
event=adobe_api.error
api=workflow_initiate
partner_reference_id=<value>
http_status=403
error_code=<value if present in body>
error_message=<value if present in body>
latency_ms=89
attempt=1
retrying=false
```

**On retry:**
```
event=adobe_api.retry
api=workflow_initiate
partner_reference_id=<value>
attempt=2
delay_ms=1000
previous_status=503
```

---

## Alert Thresholds (Recommended)

| Condition | Severity | Action |
|---|---|---|
| 403 on Workflow API | HIGH | Alert engineering — partner config issue at Adobe |
| 400 `SUBSCRIPTION_ID_ALREADY_IN_USE` | HIGH | Alert engineering — data integrity issue |
| IMS token refresh failure | HIGH | Alert engineering — credentials problem |
| 5xx error rate > 5% on any Adobe API | MEDIUM | Monitor; may indicate Adobe incident |
| Notify endpoint returning 5xx | MEDIUM | Adobe will retry; investigate root cause |
