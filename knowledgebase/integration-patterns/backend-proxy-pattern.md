# Integration Pattern: Backend Proxy

## The Rule

**All Adobe Integration API calls must be made from your backend service. Never from mobile or web frontends.**

This is the backend-only security invariant stated in `manual/methodology/card-model.md#concepts-surfaces-apis-and-the-security-invariant` — this page is the **how** (architecture, the endpoints your backend exposes, what lives where, web/CORS specifics), not a re-derivation of the rule.

---

## Why

| Risk | If Adobe APIs called from frontend |
|---|---|
| Credential exposure | `CLIENT_ID`, `CLIENT_SECRET`, `X-API-KEY` visible in browser dev tools, APK decompilation, or network intercepts |
| Token exposure | IMS bearer tokens visible in network traffic from user's device |
| CORS | Adobe APIs do not have CORS headers permitting browser origins |
| Auditability | You cannot reliably log or rate-limit frontend-originated calls |

---

## The Architecture

```
CORRECT ✅
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                                            Adobe Retail
  Mobile App  ──► Partner Backend ─────►  Integration APIs
  Web App     ──► Partner Backend ─────►  (IMS, Workflow,
                  (holds credentials)      Subscription)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

WRONG ❌
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Mobile App ──────────────────────────► Adobe Retail APIs
  Web App ─────────────────────────────► Adobe Retail APIs
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## What Your Backend Exposes to Frontend

Your backend creates simple, partner-auth-protected endpoints. These call Adobe on behalf of the frontend:

| Your Backend Endpoint | Adobe API Called |
|---|---|
| `POST {mount prefix}/claim` | `POST /retail/v1/workflows` |
| `GET {mount prefix}/subscription` | `GET /retail/v1/subscriptions/{id}` |
| `POST {mount prefix}/subscription/cancel` | `POST /retail/v1/subscriptions/{id}` |
| `POST {mount prefix}/webhooks/notify` (or similar) | (Adobe calls this — not a proxy) |

*(Exact path comes from your `CONTRACTS.md` mount prefix — never hardcode `/api/adobe/*`. None of these routes take a client-supplied `partnerReferenceId` path param; it's always resolved server-side.)*

Your mobile/web frontend authenticates to **your** backend using your existing auth (JWT, session, API key — whatever you already have). Your backend then adds the Adobe credentials and calls Adobe.

---

## What Lives Where

| Item | Mobile/Web App | Partner Backend |
|---|---|---|
| `ADOBE_IMS_CLIENT_ID` | ❌ Never | ✅ Env var |
| `ADOBE_IMS_CLIENT_SECRET` | ❌ Never | ✅ Env var |
| `ADOBE_API_KEY` | ❌ Never | ✅ Env var |
| IMS access token | ❌ Never | ✅ Cached in memory |
| `ADOBE_OFFER_ID` | ❌ Never | ✅ Env var |
| `partner_reference_id` | ✅ Can hold (it's your own ID) | ✅ Stored in DB |
| `experience_url` | ✅ Receives from backend | ✅ Returns to frontend |
| `ADOBE_NOTIFY_AUTH_SECRET` | ❌ Never | ✅ Env var |

---

## Web-Specific Considerations

Web apps have an additional constraint: even the domain of your backend may need CORS configuration. Your backend must:

1. Allow cross-origin requests from your web app's domain
2. Not forward CORS-sensitive Adobe headers to the browser

```javascript
// Express.js CORS example
app.use(cors({
  origin: ['https://your-web-app.example.com'],  // your web origin only
  credentials: true,
}));
```

Your web app calls `https://your-backend.example.com{mount prefix}/claim`, not any Adobe domain directly.

---

## Checklist

- [ ] No Adobe URL (`partners.adobe.io`, `partners-stage.adobe.io`, `ims-na1.adobelogin.com`) referenced in mobile or web source code
- [ ] No `ADOBE_IMS_CLIENT_ID` or `ADOBE_IMS_CLIENT_SECRET` in mobile/web config files, build scripts, or CI variables for frontend builds
- [ ] IMS token never passed to frontend in any API response
- [ ] All Adobe API calls originated from backend processes/services only
- [ ] `generate-integration-checklist` skill scans for and flags any violations
