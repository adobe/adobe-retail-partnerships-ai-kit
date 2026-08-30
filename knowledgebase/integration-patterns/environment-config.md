# Integration Pattern: Environment Configuration

> The canonical env-var **name** resolution rule (reuse the partner's existing names; fall back to the canonical `ADOBE_*` names only when none exist) lives in the agent-neutral [`manual/methodology/verification.md`](../../manual/methodology/verification.md) → Rule 1. This page owns the **stage/prod values, the loading/validation pattern, and the `.env.example` template** — it does not redefine the variable set, it gives the values and how to load them.

## Environments

| Environment | Purpose | Adobe API Base | IMS Base |
|---|---|---|---|
| **Stage / Sandbox** | Integration testing, development | `https://partners-stage.adobe.io/retail` | `https://ims-na1-stg1.adobelogin.com` |
| **Production** | Live partner users | `https://partners.adobe.io/retail` | `https://ims-na1.adobelogin.com` |

Adobe provides **separate credentials** for stage and production. Never use production credentials in development.

---

## Required Configuration Variables

See the committed `.env.example` template at the bottom of this page for the full variable set with stage values. Notify var(s) depend on the registered auth type — see the template below and `api-spec/notify-api.md` → Environment Variables for details.

---

## Switching Between Stage and Production

Only the URL values (`ADOBE_IMS_TOKEN_URL`, `ADOBE_RETAIL_API_BASE_URL`) and credentials change. No code changes required.

```bash
# Stage (.env.stage)
ADOBE_IMS_TOKEN_URL=https://ims-na1-stg1.adobelogin.com/ims/token/v3
ADOBE_RETAIL_API_BASE_URL=https://partners-stage.adobe.io/retail
ADOBE_IMS_CLIENT_ID=<stage-client-id>
ADOBE_IMS_CLIENT_SECRET=<stage-client-secret>
ADOBE_OFFER_ID=<stage-offer-id>

# Production (.env.production)
ADOBE_IMS_TOKEN_URL=https://ims-na1.adobelogin.com/ims/token/v3
ADOBE_RETAIL_API_BASE_URL=https://partners.adobe.io/retail
ADOBE_IMS_CLIENT_ID=<prod-client-id>
ADOBE_IMS_CLIENT_SECRET=<prod-client-secret>
ADOBE_OFFER_ID=<prod-offer-id>
```

---

Validate the **boot-required** variables at application startup and fail fast with a clear error if any are missing. **The boot-required set derives from what the generated code actually reads — it is not a fixed list.** Split variables into three tiers:

- **Boot-required** — the IMS credentials the token service reads at boot: `ADOBE_IMS_TOKEN_URL`, `ADOBE_IMS_CLIENT_ID`, `ADOBE_IMS_CLIENT_SECRET`, `ADOBE_IMS_SCOPES` (or the partner's own resolved names).
- **Graceful (NEVER boot-fatal — verification Rule 3):** `ADOBE_API_KEY` and `ADOBE_OFFER_ID`. A route that needs one and finds it missing/empty returns a distinct `*_NOT_CONFIGURED` response and logs a clear line; the app still boots. If `offer_id` lives in per-partner config, it is validated per-request, not at boot.
- **Notify-conditional:** validated only when the Notify handler is present/enabled (the receiver is optional). The var(s) depend on the registered auth type — `ADOBE_NOTIFY_AUTH_SECRET` is the `STATIC` example; `OAUTH2_CLIENT_CREDENTIALS`/`CUSTOM_TOKEN` need no Adobe-specific secret (see `api-spec/notify-api.md` → Environment Variables).

**Branch on the config mechanism** (verification Rule 4): the validator reads from wherever the stack loads config. On a **dotenv** stack it checks `process.env`/`os.environ`; on a **typed/yaml** stack (Spring `application.yml` + `@Value`/`@ConfigurationProperties`, a typed config object, Go Viper) it validates the bound config object — e.g. a Spring `@PostConstruct` validator — **not** `process.env`.

Example (reference dotenv/TypeScript stack — adapt to the partner's mechanism):

```typescript
// Boot-required only. Graceful vars (ADOBE_API_KEY / ADOBE_OFFER_ID) are NOT here —
// their absence yields a *_NOT_CONFIGURED runtime response, not a boot failure.
const BOOT_REQUIRED_ENV_VARS = [
  'ADOBE_IMS_TOKEN_URL',
  'ADOBE_IMS_CLIENT_ID',
  'ADOBE_IMS_CLIENT_SECRET',
  'ADOBE_IMS_SCOPES',
];

// Required ONLY when the Notify handler is enabled (the receiver is optional).
// The actual var(s) depend on the registered auth type (see api-spec/notify-api.md → Environment Variables).
const NOTIFY_ENV_VARS = ['ADOBE_NOTIFY_AUTH_SECRET']; // replace/extend per registered auth type

function validateConfig(notifyHandlerEnabled: boolean): void {
  const required = notifyHandlerEnabled
    ? [...BOOT_REQUIRED_ENV_VARS, ...NOTIFY_ENV_VARS]
    : BOOT_REQUIRED_ENV_VARS;
  const missing = required.filter(key => !process.env[key]);
  if (missing.length > 0) {
    throw new Error(
      `Missing required Adobe integration config: ${missing.join(', ')}\n` +
      `See .env.example for setup instructions.`
    );
  }
}

// Call at startup before accepting any requests.
// Pass whether the Notify endpoint is implemented/enabled in this deployment.
validateConfig(notifyHandlerEnabled);
```

---

## Stage-Only Constraints

- **IP allowlisting required.** Your backend's outbound IP must be allowlisted by Adobe for stage. Submit your IP range to Adobe partner engineering.
- **Test offer IDs.** Stage `offer_id` values are different from production. Use the stage offer ID provided at onboarding.
- **Experience URL domains.** Stage experience URLs use `redeem-stg.adobe.com`; production uses `redeem.adobe.com`. This is handled automatically — just point to the correct `RETAIL_API_BASE_URL`.

---

## Deep Link / Return URL Configuration

Configure your return URL (after user completes Adobe experience UI) per environment:

```bash
# The URL Adobe redirects users to after activation
ADOBE_RETURN_URL=yourapp://adobe/activated           # mobile deep link
ADOBE_RETURN_URL=https://your-web.example.com/adobe/activated  # web
```

Register this URL with Adobe during onboarding. It is embedded in the `experience_url` parameters by the Adobe integration API.

---

## `.env.example` Template

Commit this file to your repository:

```bash
# Adobe Integration APIs — Required Configuration
# Copy to .env and fill in values from Adobe onboarding
# NEVER commit .env to source control

# Adobe IMS (authentication) — ADOBE_IMS_TOKEN_URL is the full endpoint incl. path
ADOBE_IMS_TOKEN_URL=https://ims-na1-stg1.adobelogin.com/ims/token/v3
ADOBE_IMS_CLIENT_ID=
ADOBE_IMS_CLIENT_SECRET=
ADOBE_IMS_SCOPES=

# Adobe Integration APIs
ADOBE_RETAIL_API_BASE_URL=https://partners-stage.adobe.io/retail
ADOBE_API_KEY=
ADOBE_OFFER_ID=

# Notify API — var(s) depend on the auth type registered with Adobe at onboarding
# See api-spec/notify-api.md → Environment Variables for all five types.
# STATIC example (shared secret Adobe sends in a fixed header):
ADOBE_NOTIFY_AUTH_SECRET=
# OAUTH2_CLIENT_CREDENTIALS / CUSTOM_TOKEN: no Adobe-specific secret needed.
```
