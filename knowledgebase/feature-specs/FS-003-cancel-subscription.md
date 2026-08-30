# FS-003: Cancel Subscription

**Feature:** Allow a partner's customer to cancel their Adobe subscription, and allow the partner to cancel on a customer's behalf.  
**APIs used:** IMS Token, Update Subscription API (`POST /v1/subscriptions/{id}`)  
**Surfaces:** Backend service, Mobile app, Web app

**API contract:** see `knowledgebase/api-spec/update-subscription.md` (request body, `reason_code` values, response/error codes). This spec owns the **flow, dialog/confirmation UX, and idempotent error handling**.

---

## User Story

> As a partner subscriber with an active Adobe subscription, I want to cancel my subscription from within my carrier app/website, so that I can stop my benefit without having to contact Adobe directly.

> As a partner system, I need to cancel a customer's subscription when their account is closed or they become ineligible, so that Adobe entitlements are kept in sync with partner subscription status.

---

## Two Cancellation Triggers

| Trigger | `reason_code` | Who initiates |
|---|---|---|
| **User-initiated** | `USER_CANCELLED` | Customer taps "Cancel" in the app/web |
| **Partner-initiated** | `NOT_ELIGIBLE` | Partner system cancels on behalf (customer churned, account closed, etc.) |

---

## User Flow (User-Initiated)

```
1. User navigates to subscription status screen (FS-002)
2. User taps "Manage subscription" → sees subscription details
3. User taps "Cancel subscription"
4. App/web shows confirmation dialog:
   "Are you sure you want to cancel your {offered product}? (e.g. "…your Adobe Express Premium?")
   Your access will end immediately and this can't be undone."
5. User confirms
6. [Backend] Partner backend calls Update Subscription API
7. App/web shows cancellation confirmation:
   "Your subscription has been cancelled and your access has ended."
8. Subscription status screen updated to show CANCELLED state

> **Cancellation is IMMEDIATE** — whether the user initiates it from the UI or the partner initiates it, entitlement ends right away. There is **no** "access continues until {end_date}" grace period; do not surface end-of-period / continued-access copy anywhere. (`end_date` in the Get Subscription response is the record's end date, not a promise of continued access after cancellation.)
```

---

## Backend Implementation

### Endpoint to Create

`POST {mount prefix}/subscription/cancel` — the exact path is composed from the partner's route mount prefix (see the implementation contract); do not hardcode `/api/adobe/...`, and no `partnerReferenceId` is ever a client-visible parameter. There is **no path parameter** — `partner_reference_id` is resolved server-side from the authenticated session.

**Request body (from mobile/web frontend):**
```json
{
  "reason_code": "USER_CANCELLED"
}
```

**Success response:**
```json
{
  "partner_reference_id": "partner_9876543210_express_20260129",
  "status": "CANCELLED",
  "end_date": "2027-01-28T23:59:59Z"
}
```

**Backend logic:**
1. Get IMS token (from cache)
2. Call Update Subscription API: `POST /retail/v1/subscriptions/{partner_reference_id}`
   ```json
   { "type": "CANCEL", "reason_code": "USER_CANCELLED" }
   ```
3. On 200: return updated subscription to frontend, update local subscription record
4. On 404: subscription not found or already cancelled — treat as success (return 200 to frontend)
5. On 409: already cancelled — treat as success (return 200 to frontend, idempotent)
6. On 5xx: retry up to 3 times; if all fail return 503 to frontend
7. Log: `event=subscription.cancelled partner_reference_id={id} reason={code} latency={ms}ms status={code}`

**Partner-system-initiated cancellation endpoint:**

`POST {mount prefix}/subscription/cancel` (same endpoint, different `reason_code`)
```json
{ "reason_code": "NOT_ELIGIBLE" }
```

This is called from your internal systems (churn processing, account closure jobs) — not from the user-facing frontend.

---

## Mobile App Implementation

### Confirmation Bottom Sheet / Dialog

Shown before the API call is made, to prevent accidental cancellations.

**UI elements (see ui-mocks/defaults/FS-003-cancel-subscription/ or partner mocks):**
- Title: "Cancel {offered product}?" (e.g. "Cancel Adobe Express Premium?")
- Body text: "Cancelling ends your {offered product} access immediately. This can't be undone." (e.g. "…ends your Adobe Express Premium access immediately.")
- "Cancel subscription" destructive button (proceeds with cancellation)
- "Keep subscription" secondary button (dismisses dialog)

**On confirm:**
1. Dismiss dialog, show loading state
2. Call `POST {mount prefix}/subscription/cancel`
3. On success: navigate to subscription status screen (shows CANCELLED state)
4. On error: show inline error toast with retry option

### Cancellation Confirmation Screen

Shown after successful cancellation.

**UI elements:**
- Checkmark icon
- "Subscription cancelled" heading
- "Your {offered product} access has ended." (e.g. "Your Adobe Express Premium access has ended.")
- "Re-activate later" link (navigates back to offer screen, with note that re-activation requires a new subscription)
- "Done" button → returns to home/rewards screen

---

## Web App Implementation

Same UX as mobile. Confirmation implemented as a modal dialog with the same content.

---

## Post-Cancellation: Re-Purchase Rules

After cancellation:
- The `partner_reference_id` used for the original claim is **permanently retired** at Adobe's end
- If the user wants to re-subscribe, you must generate a **new** `partner_reference_id`
- Display this on the re-activate screen: "To re-activate, a new subscription will be created"
- Do not attempt to reuse the old `partner_reference_id` — this will result in an error from Adobe

---

## Partner-System Cancellation (Background Jobs)

When cancelling on behalf of customers (e.g. churn processing):

```python
# Example: cancel for churned customers
for customer in churned_customers:
    subscription = db.get_active_adobe_subscription(customer.id)
    if subscription:
        partner_backend.cancel_subscription(
            partner_reference_id=subscription.partner_reference_id,
            reason_code="NOT_ELIGIBLE"
        )
        db.mark_subscription_cancelled(subscription.id)
```

Treat 404 and 409 as success (already in desired state). Log every call for audit purposes.

---

## Acceptance Criteria

- [ ] Confirmation dialog shown before calling API — accidental cancellations prevented
- [ ] 200 from Adobe → cancellation confirmation shown, status updated to CANCELLED
- [ ] 404 from Adobe → treated as success (already cancelled/not found)
- [ ] 409 from Adobe → treated as success (idempotent — already cancelled)
- [ ] 5xx from Adobe → error shown with retry option; up to 3 retries attempted
- [ ] Confirmation screen states access ended IMMEDIATELY (no "access until {end_date}" language)
- [ ] Subscription status screen (FS-002) shows CANCELLED after cancellation
- [ ] Re-activate path available from cancellation confirmation
- [ ] Partner-system cancellation endpoint handles bulk/background use correctly
- [ ] All cancellation calls logged with `reason_code`, `partner_reference_id`, and outcome

---

## UI Mock References

- `mocks/<partner>/` (partner mocks, preferred if provided — the screen tagged `manage` in the manifest's Screens table)
- `knowledgebase/ui-mocks/defaults/FS-003-cancel-subscription/cancel-dialog.svg`
- `knowledgebase/ui-mocks/defaults/FS-003-cancel-subscription/cancel-confirmed.svg`

---

## Related

- `api-spec/update-subscription.md` — full Update Subscription spec
- `FS-002-find-subscription.md` — subscription status (entry point to this flow)
- `integration-patterns/idempotency.md` — handling 409 and 404 as success
- `integration-patterns/error-handling.md` — retry and error mapping
