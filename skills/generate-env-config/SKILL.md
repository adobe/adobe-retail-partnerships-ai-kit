---
name: generate-env-config
description: >
  Generate a complete .env.example with all required Adobe integration variables, add .env to .gitignore, and add startup config validation to the backend.
---

# Skill: /generate-env-config

> Also invoked automatically by `implement-feature`'s Fast path when targeting
> the bundled base app; this file remains the authoritative spec either way,
> and running it standalone always works for the Full workflow or to force
> extra rigor on the bundled app too.

Generate a complete `.env.example` with all required Adobe integration variables, add `.env` to `.gitignore`, and add startup config validation to the backend.

---

## Instructions

### Step 1 — Load Context

1. Read `service-cards/backend/BUILD_CONFIG.md` (§3 Environment-Variable Schema, §4 Secrets, §5 Build Interface) — the authoritative env-var names and config-loading mechanism. If the `service-cards/backend/` folder is missing, tell user to run `/analyze-partner-codebase` first.
2. Read `knowledgebase/integration-patterns/environment-config.md`.
3. Scan the project for any already-generated integration files to discover all env vars used.

### Step 2 — Collect All Required Variables

Scan all generated integration code (IMS client, Retail API client, Notify handler, feature routes) for environment variable references. Collect every `process.env.X`, `@Value("${x}")`, `os.environ["X"]`, etc.

**The names you find in the generated code are authoritative** (Code Generation Protocol rule 1). If the code reads `IMS_TOKEN_URL`/`IMS_CLIENT_ID`/`RETAIL_BASE_URL` etc., the `.env.example` and validation **MUST use those exact names** — do NOT rewrite them to the `ADOBE_*` names below. The list below is only the canonical **fallback** for a greenfield integration where the code reads no Adobe vars yet:

Canonical fallback names (used only when the code reads no partner-specific names yet):
```
ADOBE_IMS_TOKEN_URL          # full IMS token endpoint incl. path
ADOBE_IMS_CLIENT_ID
ADOBE_IMS_CLIENT_SECRET
ADOBE_IMS_SCOPES             # plural, comma-separated
ADOBE_RETAIL_API_BASE_URL
ADOBE_API_KEY                # graceful — see Step 5 (not boot-fatal)
ADOBE_OFFER_ID               # graceful — see Step 5 (not boot-fatal)
```

**Nothing the kit adds is boot-fatal — the app must always start, even with no Adobe credentials set (verification Rule 3).** `ADOBE_API_KEY`, `ADOBE_OFFER_ID`, **and the IMS credentials** are all **graceful**: the IMS token client reads its credentials lazily (at the first token request, not at boot — see `generate-adobe-clients`), so a route that needs any Adobe credential but finds it missing/empty returns a distinct `*_NOT_CONFIGURED` response and logs a clear line — it does **not** fail startup. The only boot-required variables are the ones the **app already needed to start before this integration** (its own DB URL, its own JWT secret, etc.); the Adobe integration contributes nothing to that tier.

Notify endpoint auth (type-dependent):
Config depends on the auth type the partner registered with Adobe. For `STATIC` / `BASIC` / `CUSTOM_HEADERS`, emit the partner-registered credential var(s) — e.g. `ADOBE_NOTIFY_AUTH_SECRET` for `STATIC`. For `OAUTH2_CLIENT_CREDENTIALS` / `CUSTOM_TOKEN`, emit **no** Adobe-specific secret (Adobe replays a token it fetched from the partner's own token endpoint, so validation reuses the partner's existing token-validation config). **Never make notify config boot-fatal** — the Notify receiver is optional. Never hardcode a credential in source.

### Step 3 — Write the config source (form depends on the stack)

**Branch on the config mechanism recorded in `service-cards/backend/BUILD_CONFIG.md` (§3/§4):**
- **dotenv stack** (`.env` / `process.env` / `os.environ` / `dotenv`): write `.env.example` (below) and update `.gitignore` (Step 4).
- **typed / yaml config stack** (Spring `application.yml` + `@Value`/`@ConfigurationProperties`, a typed config object, Rails credentials, Go Viper/INI): do **NOT** write `.env.example` or touch `.gitignore`. Instead add the keys in that stack's form (e.g. `application.yml` keys, or documented environment keys the typed config binds) and rely on that stack's secret handling. Skip Step 4 for these stacks; Step 5 emits a validator in the stack's idiom (e.g. a Spring `@PostConstruct`).

For a dotenv stack, write `.env.example` to the project root (or the backend service root, following existing conventions). **Substitute the actual variable names resolved in Step 2** — the block below uses the canonical names purely as a layout example; if the code uses `IMS_*`/`RETAIL_*`, write those instead:

```bash
# Adobe Integration APIs — Required Configuration
# Copy this file to .env and fill in values from Adobe onboarding
# NEVER commit .env to source control

# ── Adobe IMS (authentication) ──────────────────────────────────
# Full token endpoint incl. path.
# Stage:  https://ims-na1-stg1.adobelogin.com/ims/token/v3
# Prod:   https://ims-na1.adobelogin.com/ims/token/v3
ADOBE_IMS_TOKEN_URL=https://ims-na1-stg1.adobelogin.com/ims/token/v3

# IMS client ID — provided by Adobe at onboarding
ADOBE_IMS_CLIENT_ID=

# IMS client secret — provided by Adobe at onboarding (KEEP SECRET)
ADOBE_IMS_CLIENT_SECRET=

# Required OAuth scopes — provided by Adobe at onboarding
ADOBE_IMS_SCOPES=

# ── Adobe Integration APIs ───────────────────────────────
# Stage:  https://partners-stage.adobe.io/retail
# Prod:   https://partners.adobe.io/retail
ADOBE_RETAIL_API_BASE_URL=https://partners-stage.adobe.io/retail

# X-API-Key header — provided by Adobe at onboarding
ADOBE_API_KEY=

# Adobe offer identifier — provided by Adobe at onboarding
ADOBE_OFFER_ID=

# ── Notify API ──────────────────────────────────────────────────
# Var(s) depend on the auth type registered with Adobe at onboarding.
# STATIC example — the shared secret Adobe sends in a fixed header:
ADOBE_NOTIFY_AUTH_SECRET=
# BASIC: set expected username + password vars instead.
# CUSTOM_HEADERS: set expected header name(s) + value(s) instead.
# OAUTH2_CLIENT_CREDENTIALS / CUSTOM_TOKEN: no Adobe-specific secret needed
#   (Adobe replays a token it fetched from your token endpoint; validate via
#   your own identity layer using its existing config).
```

### Step 4 — Update `.gitignore` (dotenv stacks only)

**Skip this step entirely on typed/yaml config stacks** (there is no `.env` to ignore). For a dotenv stack, ensure these lines exist in `.gitignore` (add if missing, do not duplicate):
```
.env
.env.local
.env.production
.env.staging
*.env
```

### Step 5 — Add Startup Validation

Add config validation to the backend's startup sequence, in the partner's existing startup pattern and config form (Spring `@PostConstruct`, Express startup, FastAPI lifespan event, Go `main`, etc.). For a typed/yaml stack this is a validator over the bound config object — **not** a `process.env` check.

**Derive the boot-required set from what the generated code actually reads — do NOT hardcode an always-required list.** Scan the generated integration code (Step 2) and split the variables it references into two tiers:

```
Validate on startup (fail-fast, clear message):
  Boot-required = ONLY variables the app ALREADY needed to start before this
    integration (its own DB URL, its own JWT secret, etc.). The Adobe
    integration the kit adds contributes NOTHING to this tier — do NOT newly
    fail-fast on any ADOBE_*/IMS_* variable.

  Graceful (NEVER boot-fatal — verification Rule 3):
    ALL Adobe integration credentials — the IMS ones (ADOBE_IMS_TOKEN_URL,
    ADOBE_IMS_CLIENT_ID, ADOBE_IMS_CLIENT_SECRET, ADOBE_IMS_SCOPES, or the
    partner's own resolved names) AND ADOBE_API_KEY / ADOBE_OFFER_ID (and
    per-partner offer config). The IMS client reads these lazily at the first
    token request (see generate-adobe-clients), so a route that needs one and
    finds it missing/empty returns a distinct <NAME>_NOT_CONFIGURED response
    and logs a clear line — the app still boots. Do NOT add any of these to the
    fail-fast set. (If offer_id lives in per-partner config rather than an env
    var, it is validated per-request, not at boot.)

  Conditionally required: the notify auth var(s) for the registered type
    (e.g. ADOBE_NOTIFY_AUTH_SECRET for STATIC; token types may need none).
    Validate ONLY if the Notify handler is present/enabled (the receiver is
    optional). Do not fail-fast on it for partners without a notify handler.

  If any BOOT-REQUIRED variable is missing (the app's own pre-existing must-haves
  only — never an Adobe integration var):
    Log error listing the missing variables
    Throw/exit — fail fast with a clear message pointing to the config source
```

### Step 6 — Report

List files created/modified. Print the complete list of variables with descriptions, marking each **boot-required** / **graceful** / **notify-conditional**. Remind user:
- Fill in values from Adobe onboarding in the stack's config source (copy `.env.example` → `.env` for a dotenv stack; set the `application.yml`/typed-config keys otherwise)
- Stage and production credentials are different
- Submit stage server IP to Adobe for allowlisting before testing
