---
name: generate-adobe-clients
description: >
  Generate production-ready Adobe backend clients in the partner's existing backend stack: Phase 0 — a reviewable design approved before any code is written; Phase 1 — the IMS OAuth token service; Phase 2 — the typed Adobe Integration API client (Workflow, Get Subscription, Update Subscription).
---

# Skill: /generate-adobe-clients

Generate production-ready Adobe backend clients in the partner's existing backend stack. These clients are code written into the partner's backend, so — like every code-writing step in this kit — a **reviewable design comes first**:

- **Phase 0 — Design & review.** Write a short design of the clients (files, paths, env-var names, key decisions) and get it approved **before any code is written** — the same design-before-code gate the feature LLDs use.
- **Phase 1 — IMS Token Client.** A production-ready IMS OAuth token service.
- **Phase 2 — Retail API Client.** A typed Adobe Integration API client — covering Workflow, Get Subscription, and Update Subscription APIs — which depends on Phase 1's token service.

There is no separate approval gate *between* Phase 1 and Phase 2 — Phase 2 confirms Phase 1's client exists **by content** (a `client_credentials` token call), not by a human sign-off — so the single Phase 0 design review covers both.

**Shared verification note:** in both phases' examples, the reference TypeScript stack uses Vitest — mock native `fetch` with `vi.stubGlobal('fetch', vi.fn().mockResolvedValue(...))`, not `jest.fn()`. Adapt to the partner's actual test framework per `BUILD_CONFIG.md`.

---

## Phase 0 — Design the clients, and review, before writing any code

These clients are code written into the partner's backend, so a reviewable design
comes first — the same principle as the feature LLDs and their DG gates.

**1. Write the design.** From the backend cards (`service-cards/backend/` —
`SERVICE_CARD.md`, `MODULE_INDEX.md`, `BUILD_CONFIG.md`, `CONNECTORS.md`) and the
API specs (`knowledgebase/api-spec/ims-token.md`, `workflow-api.md`,
`get-subscription.md`, `update-subscription.md`), write a short **Adobe clients
design** to `$APP_backend/docs/ai-kit/LLD/backend/adobe-clients-lld.md` (beside the
backend subproject on a monorepo, per the LLD path rule in
[`../generate-lld/SKILL.md`](../generate-lld/SKILL.md)). It states:

- **Files to create/modify** — a `File | Action (CREATE/MODIFY) | Purpose` table
  (the IMS token service, the Retail API client, shared types/DTOs, and their
  tests), each at a real path resolved from `MODULE_INDEX.md` / `SERVICE_CARD.md`.
- **Env-var names** the clients will read, resolved per Code-Generation-Protocol
  rule 1 — reuse the partner's existing names from `BUILD_CONFIG.md`; the canonical
  `ADOBE_*` names are a fallback only.
- **Key design points** — token caching (proactive refresh, thread-safe), lazy
  credential reads (never boot-fatal), HTTP-status-based error mapping, the
  `X-API-Key` source, and the `workflow_attributes` extraction rule.

**2. Review checkpoint.** Tell the user this is a review checkpoint and print the
file-change table + the key design points. Confirm every path resolves to a real
location in the cards and every env-var name matches `BUILD_CONFIG.md`. Ask the
partner to review `docs/ai-kit/LLD/backend/adobe-clients-lld.md` and approve or
request corrections. For small fixes, edit the design directly; for structural
ones, fix the source card and re-run. **STOP here — do not write any client code
until this design is approved.**

> **Fast path** (no partner repo registered — target is the bundled `base-ref-app/`):
> write the design to disk and self-check it (paths resolve, env-var names
> consistent), then continue automatically unless the self-check finds a real
> problem — the same auto-continue rule the LLD uses. Say so in the report.

Only after the design is approved (or auto-continued on the fast path) proceed to
Phase 1.

---

## Phase 1 — IMS Token Client

### Step 1 — Load Context

1. Read the backend card set in `service-cards/backend/` (at the kit root) — start at `SERVICE_CARD.md` (stack, source structure, error handling, LLD hints), then `BUILD_CONFIG.md` (HTTP client, logger, test framework, env-var schema, verify commands), `MODULE_INDEX.md` (where new code goes), and `CONNECTORS.md` (Adobe Retail connectors). If the `service-cards/backend/` folder doesn't exist, tell the user to run `/analyze-partner-codebase` first.
2. Read `knowledgebase/api-spec/ims-token.md` for the full IMS API spec.
3. Read `knowledgebase/integration-patterns/token-caching.md` for caching strategy.
4. Read `knowledgebase/integration-patterns/security.md` for security requirements.

### Step 2 — Understand the Existing Stack

From the backend card set (`service-cards/backend/`), identify:
- Backend language and framework (`SERVICE_CARD.md`)
- Existing HTTP client library (`BUILD_CONFIG.md` → Dependency Manifest)
- Config loading mechanism / env-var schema (`BUILD_CONFIG.md` → §3 + §4)
- Logging library and format (`BUILD_CONFIG.md` → Dependency Manifest)
- Where new service files should go (`MODULE_INDEX.md` layers + `SERVICE_CARD.md` → Source Structure / LLD Hints)
- Test framework (`BUILD_CONFIG.md` → Dependency Manifest)

### Step 3 — Generate the IMS Token Service

Generate a token service in the partner's exact stack that:

1. **Reads credentials from environment variables** — resolve the variable **names** per **Code Generation Protocol rule 1** in manual/methodology/verification.md: reuse the names already in the partner's code/`.env` (from `service-cards/backend/BUILD_CONFIG.md` → "Environment-Variable Schema", e.g. `IMS_TOKEN_URL`/`IMS_CLIENT_ID`/`IMS_CLIENT_SECRET`/`IMS_SCOPE`). Only if none exist, use the canonical fallback names below. Use the **same** resolved names in the generated code AND in `.env.example` (Step 5) AND in startup validation — never mix two naming schemes.
   - `ADOBE_IMS_TOKEN_URL` (full IMS token endpoint, including path — e.g. `https://ims-na1-stg1.adobelogin.com/ims/token/v3`)
   - `ADOBE_IMS_CLIENT_ID`
   - `ADOBE_IMS_CLIENT_SECRET`
   - `ADOBE_IMS_SCOPES` (comma-separated required scopes — sent as the IMS `scope` request parameter)

   **Important:** the canonical names above are the fallback. If the partner already has any IMS var names in their `.env` / code, use those **exactly** and do NOT fall back to the canonical names (e.g. a partner may use `IMS_TOKEN_URL`, `IMS_CLIENT_ID`, `IMS_CLIENT_SECRET`, `IMS_SCOPE`). The fallback names listed here are for partners with no pre-existing IMS config.

   **Read the credentials lazily — at the first token request, never at module load or app startup.** If any IMS credential is missing or empty, the token service must surface a distinct not-configured condition that the calling route maps to a `*_NOT_CONFIGURED` response (verification Rule 3) — it must **not** throw at import/construction time and must **never** stop the app from starting. Missing Adobe configuration is a graceful request-time state, not a boot failure, so the app always boots even with no Adobe credentials set.

2. **Implements token caching with proactive refresh:**
   - Cache token in memory
   - Refresh when fewer than 300 seconds remain before expiry
   - Thread-safe (prevent concurrent refresh storms)
   - See `integration-patterns/token-caching.md` for the algorithm

3. **Uses the partner's existing HTTP client** — do not introduce a new dependency

4. **Uses the partner's existing logger** — same format and style as their existing log calls. From `service-cards/backend/BUILD_CONFIG.md` (Dependency Manifest → Logging), the format is `key=value` strings: e.g. `event=ims.token.refreshed latencyMs=42 status=200`. Do NOT use JSON object literals `{ event: '...' }` unless the card shows that style.

5. **Never logs token values** — only log: event, latency, HTTP status

6. **Raises appropriate errors** — map IMS 401/403 to clear exception types

The generated file path follows the module layout in `service-cards/backend/MODULE_INDEX.md` (and the Source Structure / LLD Hints in `SERVICE_CARD.md`).

### Step 4 — Generate Tests

Generate a unit test for the IMS service using the partner's existing test framework:
- Happy path: valid credentials, token cached
- Proactive refresh: token near expiry triggers refresh
- Concurrent calls: second call waits for first refresh (does not double-refresh)
- IMS error: 401 response handled correctly

Test file goes in the same test directory convention used by the partner's existing tests.

### Step 5 — Update Environment Config

Add to the config source using the **resolved env var names** from Step 3 rule 1 (not the canonical names if the partner already has their own), in the **form the target stack uses** (dotenv `.env.example`, Spring `application.yml`, a typed config object — per `BUILD_CONFIG.md` §3/§4). Example for a dotenv-based partner with no pre-existing IMS config:
```
# ADOBE_IMS_TOKEN_URL is the full endpoint including path (not just the base URL)
ADOBE_IMS_TOKEN_URL=https://ims-na1-stg1.adobelogin.com/ims/token/v3
ADOBE_IMS_CLIENT_ID=
ADOBE_IMS_CLIENT_SECRET=
ADOBE_IMS_SCOPES=openid,AdobeID,read_organizations
# Dev override — paste a ready access token to skip the IMS exchange (local dev only)
IMS_ACCESS_TOKEN=
```

If the partner already uses their own names (e.g. `IMS_TOKEN_URL`, `IMS_CLIENT_ID`, `IMS_CLIENT_SECRET`, `IMS_SCOPE`), use those instead.

For dotenv stacks, also ensure `.env` is in `.gitignore`. For non-dotenv stacks (typed config / `application.yml`), follow that stack's secret-handling convention instead (see `generate-env-config` and `integration-patterns/environment-config.md`).

### Step 6 — Verify, then Report

Before reporting, complete the **Code Generation Protocol** in [`../../manual/methodology/verification.md`](../../manual/methodology/verification.md) (rules 1, 3, 4, 5): confirm the env-var names the code reads match what you write to the config source; **resolve the actual typecheck/test command from `service-cards/backend/BUILD_CONFIG.md` §5 (Build Interface)** and run it plus the Step 4 tests; and **reconcile the live config** (rule 4) — for a dotenv stack diff the live `.env` and print which IMS vars are missing/empty; for a typed/yaml stack point at the config file + keys instead.

**Example (reference TypeScript stack) — adapt to the partner's actual stack:**
- TypeScript typecheck command: `npx tsc --noEmit` from `$APP_backend`. If `tsconfig.json` excludes `*.test.ts` from the typecheck, production code and test code are verified separately: `npx tsc --noEmit` for production + `npx vitest run` for tests.
- See the shared verification note above for the Vitest `fetch`-mocking tip.

Then tell the user:
- What files were created/modified, and what you verified (typecheck + test output)
- The exact `.env` keys still needing values (from the reconciliation diff) — the skill never writes secret values
- Proceed to Phase 2 below

---

## Phase 2 — Retail API Client

### Step 1 — Load Context

1. Read the backend card set in `service-cards/backend/` — `SERVICE_CARD.md` (stack, structure), `BUILD_CONFIG.md` (HTTP client, logger, test framework, env-var schema), `CONNECTORS.md` (Adobe Retail connectors), `MODULE_INDEX.md` (where new code goes), and `INTEGRATION_CONTEXT.md` (subscription entity, where `offer_id` lives). If the `service-cards/backend/` folder is missing, tell user to run `/analyze-partner-codebase` first.
2. Read all files in `knowledgebase/api-spec/`:
   - `workflow-api.md`
   - `get-subscription.md`
   - `update-subscription.md`
3. Read `knowledgebase/integration-patterns/error-handling.md` for complete error code mapping.
4. Read `knowledgebase/integration-patterns/backend-proxy-pattern.md` to confirm security architecture.
5. Check if Phase 1's IMS token client output exists **by role, not by a hardcoded path or language.** Search the whole backend surface for the IMS token service using a role-based, language-agnostic file glob — e.g. `*ims*token*` / `*token*service*` (case-insensitive) across `$APP_backend`, matching any extension (`.ts`, `.java`, `.py`, `.go`, `.rb`, `.cs`, …) — since the model may have placed it anywhere (`ims/`, `services/`, `adobe/`, `auth/`) and the stack may not be Node. Confirm by content (a `client_credentials` token call), not just the filename. If nothing matches, run Phase 1 first (re-run this skill).

### Step 2 — Generate the Retail API Client

Generate a single API client class/module in the partner's stack with these methods. Signatures are shown **language-neutrally** — express each in the partner's real idiom (Java method + typed DTO, Python function + Pydantic model, Go func + struct, TS interface, etc.); do not force TS `camelCase`/`Promise`.

#### `initiate_workflow(partner_reference_id, offer_id) → WorkflowResult`
- Calls `POST /retail/v1/workflows` with body `{ "workflow_type": "CLAIM_PRODUCT", "workflow_attributes": [ {key: "partner_reference_id", value: …}, {key: "offer_id", value: …} ] }`
- Gets IMS token from the IMS service (generated in Phase 1)
- **`offer_id` argument is required** — check `service-cards/backend/INTEGRATION_CONTEXT.md` and `BUILD_CONFIG.md` → Environment-Variable Schema (the `offer_id` value itself lives in `service-cards/shared/OFFER_PROFILE.md`) to determine the source:
  - If `offer_id` is per-partner in config (e.g. a partners config file with an `offerId`/`offer_id` field): accept it as an argument; the **route/handler** resolves it from the partner lookup; the client method does NOT read it from env.
  - If `offer_id` is a single global env var: read `ADOBE_OFFER_ID` (or the partner's existing name) from config; the argument may be omitted.
- Handles: 202, 302, 400 (`INVALID_OFFER`, `SUBSCRIPTION_ID_ALREADY_IN_USE`), 401 (refresh+retry), 403, 409 (`ALREADY_FULFILLED`), 5xx (retry with backoff)
- **Return-shape extraction (CRITICAL — the fields are NOT all top-level).** Per `knowledgebase/api-spec/workflow-api.md`, the 202/302 body is:
  ```json
  { "workflow_type": "CLAIM_PRODUCT",
    "experience_url": "…", "short_experience_url": "…",
    "workflow_attributes": [ {"key":"partner_reference_id","value":"…"}, {"key":"offer_id","value":"…"} ] }
  ```
  Map it explicitly into the flat `WorkflowResult`:
  - `experience_url` ← top-level `experience_url`
  - `short_experience_url` ← top-level `short_experience_url` (optional)
  - `partner_reference_id` ← the `workflow_attributes` entry where `key == "partner_reference_id"` (**nested in the array — do NOT read it from the top level**; it is not there)
  - (optionally `offer_id` ← the `workflow_attributes` entry where `key == "offer_id"`)
  Do not assume `partner_reference_id`/`offer_id` are top-level response fields — reading `body.partner_reference_id` returns undefined. On a 302, follow the redirect / read the `Location` header for `experience_url`.
- Logs: `event=retail.claim.initiated partner_reference_id={id} latencyMs={ms}` — use the logging format from `service-cards/backend/BUILD_CONFIG.md` (Dependency Manifest → Logging)

#### `get_subscription(partner_reference_id) → SubscriptionResult | null`
- Calls `GET /retail/v1/subscriptions/{partner_reference_id}`
- Returns null/None on 404 (not an error — not yet activated)
- Handles: 200, 400, 401 (refresh+retry), 403, 404 (→ null), 5xx
- Returns: `{ partner_reference_id, offer_id, status, start_date, end_date }` or null
- Logs: `event=subscription.queried partner_reference_id={id} latency={ms}ms status={code}`

#### `cancel_subscription(partner_reference_id, reason_code) → SubscriptionResult`
- Calls `POST /retail/v1/subscriptions/{partner_reference_id}`
- `reason_code`: `USER_CANCELLED` | `NOT_ELIGIBLE`
- Treats 404 and 409 as success (idempotent — see `integration-patterns/idempotency.md`)
- Handles: 200, 400, 401 (refresh+retry), 403, 404 (→ success), 409 (→ success), 5xx
- Logs: `event=subscription.cancel_requested partner_reference_id={id} reason={code} latency={ms}ms status={code}`

**Map errors by HTTP status, not by a response-body field.** Where the API spec defines a status→meaning (e.g. workflow `409 → ALREADY_FULFILLED`, subscription `404 → not found`), derive the outcome from the **HTTP status code directly** — do NOT depend on a body field like `error_code`/`code`, which real Adobe responses may not populate as documented. Reading the body for extra detail is fine, but the status-defined outcome must hold even when the body is empty or shaped differently. This is critical: a mislabeled `409` collapses the caller's "already activated → show subscription" path into a generic failure. Verify each documented error status against a stubbed/real response (Protocol rule 5).

### Step 3 — Model/DTO Types

Generate typed request/response models matching the API contract. `WorkflowResult` is a **flattened** view of the workflow response — the client populates it via the Step 2 extraction mapping (top-level `experience_url` + `partner_reference_id` pulled out of the `workflow_attributes` array), so callers never traverse the array themselves:

```
WorkflowResult {
  experience_url: string
  short_experience_url?: string   // optional
  partner_reference_id: string    // extracted from workflow_attributes[key=="partner_reference_id"]
}

SubscriptionResult {
  partner_reference_id: string
  offer_id: string
  status: "ACTIVE" | "CANCELLED"
  start_date: string   // ISO 8601
  end_date: string     // ISO 8601
}

CancelReasonCode: "USER_CANCELLED" | "NOT_ELIGIBLE"

AdobeApiError {
  errorCode: string    // camelCase — NOT "code" — to avoid collision with Error.code
  message: string
  httpStatus: number
  isRetriable: boolean
}
```

**Note on `AdobeApiError`:** Use `errorCode` (camelCase), not `code`. TypeScript's built-in `Error` class already has a `code` property in some environments; using `errorCode` avoids ambiguity. If the partner's stack already has a different error convention, match that instead.

Use the partner's existing type/model conventions (TypeScript interfaces, Java records, Python Pydantic models, Go structs, etc.)

### Step 4 — Generate Tests

Generate unit tests with mocked HTTP client:
- `initiateWorkflow` happy path (202)
- `initiateWorkflow` 409 `ALREADY_FULFILLED` → throws `AlreadyFulfilledException`
- `initiateWorkflow` 5xx → retries 3 times with backoff
- `getSubscription` 200 → returns subscription
- `getSubscription` 404 → returns null
- `cancelSubscription` 200 → returns cancelled subscription
- `cancelSubscription` 409 → returns success (idempotent)

### Step 5 — Update Environment Config

Add to `.env.example` using the **resolved env var names** from `service-cards/backend/BUILD_CONFIG.md` (Environment-Variable Schema) — do NOT hardcode canonical names if the partner already has their own. The `X-API-Key` header value comes from `IMS_CLIENT_ID` (not a separate `ADOBE_API_KEY` env var) when the card shows the same credential for both — check the schema/Secrets sections.

Example for a partner with no pre-existing Retail API config:
```
ADOBE_RETAIL_API_BASE_URL=https://partners-stage.adobe.io/retail
# ADOBE_API_KEY is the X-API-Key — check whether this is the same as IMS_CLIENT_ID
# (if so, no separate entry needed)
ADOBE_OFFER_ID=
# NOTE: if offer_id is per-partner in config (e.g. partners.json), no env var is needed here
```

**Reference example (adapt to the partner's cards):** a reference app resolved these as `RETAIL_BASE_URL` (not `ADOBE_RETAIL_API_BASE_URL`), sourced `X-API-Key` from its IMS client-id credential (no separate `ADOBE_API_KEY`), and kept `offer_id` per-partner in a partners config file (not an env var). Use whatever `BUILD_CONFIG.md`/`INTEGRATION_CONTEXT.md` actually report for this partner.

### Step 6 — Verify, then Report

Before reporting, complete the **Code Generation Protocol** in [`../../manual/methodology/verification.md`](../../manual/methodology/verification.md) (rules 1, 3, 4, 5): env-var names match what the code reads (reuse the IMS names from the IMS client; the `X-API-Key` source must match too); **resolve the actual typecheck/test command from `service-cards/backend/BUILD_CONFIG.md` §5 (Build Interface)** and run it plus the Step 4 tests; and reconcile the live config (rule 4 — dotenv `.env` diff, or the typed/yaml config keys).

**`X-API-Key` source (verify from the cards):** check `service-cards/backend/BUILD_CONFIG.md` §3/§4 whether there is a dedicated `ADOBE_API_KEY` var or whether the IMS client id doubles as the API key — use whichever the cards report. `ADOBE_API_KEY` is a **graceful** value (Rule 3): missing → `*_NOT_CONFIGURED` at request time, not a boot failure.

**Example (reference TypeScript/Vitest stack) — adapt to the partner's actual stack:**
- Typecheck `npx tsc --noEmit` from `$APP_backend`; if `tsconfig.json` excludes `*.test.ts`, run the test runner (e.g. `npx vitest run`) separately for tests.
- To mock native `fetch` in Vitest, see the shared verification note above; the `headers.get(name)` call must be on the mocked response object (not a plain Headers map).
- Fake-timer tests with `vi.useFakeTimers()` and async retries: capture the rejection via `.catch((err) => err)` before `vi.runAllTimersAsync()`, then `await` the caught value — do NOT `await` the promise after `runAllTimersAsync` or the rejection becomes unhandled.
- Reference-app example where the IMS client id doubled as the `X-API-Key`: a `getApiKey()` reading `process.env.IMS_CLIENT_ID`. Only applies when the partner's cards show that same-credential arrangement.

Then tell the user:
- Files created and what you verified (typecheck + test output)
- The client is ready to be used by the feature skills
- Suggest running `/implement-feature claim-product` next

**⚠️ Action required — set the real offer_id (do not skip):** The `offer_id` is per-partner and Adobe-assigned; any value shipped in the repo (e.g. a sample like `30006514`) is a placeholder and will fail with `INVALID_OFFER` against real Adobe. Tell the user explicitly **where** to set it based on what `service-cards/backend/BUILD_CONFIG.md` / `INTEGRATION_CONTEXT.md` and `service-cards/shared/OFFER_PROFILE.md` reported:
- If the partner stores offers **per-partner in config** (e.g. a partners config file with an `offerId`/`offer_id` field): "Set each partner's real `offerId` in `<that file>` — the current value is only a sample."
- If the partner uses a **single env var** (`ADOBE_OFFER_ID`, or the partner's own existing offer-id name): "Set `ADOBE_OFFER_ID` in the backend's config source to your Adobe-assigned offer."
- Name the exact file/field and the current placeholder value so the user knows precisely what to change.
