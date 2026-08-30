---
name: generate-tests
description: >
  Generate comprehensive unit and integration tests for all Adobe integration code, using the partner's existing test framework and patterns.
---

# Skill: /generate-tests

> Also invoked automatically by `implement-feature`'s Fast path when targeting
> the bundled base app; this file remains the authoritative spec either way,
> and running it standalone always works for the Full workflow or to force
> extra rigor on the bundled app too.

Generate comprehensive unit and integration tests for all Adobe integration code, using the partner's existing test framework and patterns.

---

## Instructions

### Step 1 — Load Context

1. Read whichever service card sets exist under `service-cards/` — the backend set (`backend/BUILD_CONFIG.md` → Dependency Manifest for the test framework, plus `UI_CODE_PATTERNS.md` → Test Patterns and `UI_PLATFORM.md` → Build Interface for each UI surface `mobile/`/`web/`/`ios/`/`android/`) — identify test framework, test file conventions, test directory structure. If none exist, tell the user to run `/analyze-partner-codebase` first.
2. Scan for all generated integration files (IMS client, Retail API client, feature routes, Notify handler).
3. Read `knowledgebase/api-spec/` for all expected request/response shapes.
4. Read `knowledgebase/integration-patterns/error-handling.md` for all error scenarios to test.
5. Read `knowledgebase/integration-patterns/idempotency.md` for idempotency scenarios.

### Step 2 — Test Coverage Plan

For each generated file, identify what to test:

**IMS Token Service:**
- Cache miss: calls IMS, caches token
- Cache hit: returns cached token without calling IMS
- Proactive refresh: token near expiry triggers refresh
- Concurrent refresh: second call waits, does not double-call IMS
- IMS error: 401 propagated as clear error

**Retail API Client:**
- `initiateWorkflow`: 202 success, 409 → AlreadyFulfilled, 403 → ServiceUnavailable, 5xx → retries 3x
- `getSubscription`: 200 success, 404 → null, 5xx → error
- `cancelSubscription`: 200 success, 404 → success (idempotent), 409 → success (idempotent), 5xx → retries

**Backend Routes (one section per feature route — test the handler, not just the client):**
- Claim: valid request → returns experience_url; already-active/ALREADY_FULFILLED handled; **`partner_reference_id` is resolved server-side** (the request body carries none — a test that posts one must be rejected/ignored); config-missing → distinct `*_NOT_CONFIGURED` (not a 500).
- Get Subscription: 200 subscription; 404 from Adobe → returns `{ status: NOT_FOUND }` with HTTP 200.
- Cancel: success; 409 from Adobe → HTTP 200 success; 5xx → 503.
- Path check: assert each route is reachable at `CONTRACTS.md` base path + suffix (Protocol rule 2), not an assumed `/api/adobe/*`.

**Notify Handler:**
- Valid Active event → subscription updated, 200 returned
- Valid Cancelled event → subscription updated, 200 returned
- Duplicate event → 200, no DB mutation
- Invalid auth → 401 (only meaningful once the route is permitted through the security chain)
- Malformed body → 400
- Unknown subscription ID → 200 with warning log

**UI Surface(s) (one section per present surface — mobile/native AND web):**
- **Screen renders per state:** each feature screen pumps/mounts and renders for every state the mocks define (loading / active / already-active / cancelled / not-found / error / PENDING) without throwing — use the surface's widget/component test tool (Flutter widget test, React Testing Library, XCTest/Compose UI test).
- **State-driven entry:** an ACTIVE subscription shows a **Manage** affordance (no Claim CTA); NOT_FOUND/CANCELLED shows Claim.
- **No dead-end:** every rendered state exposes a working action or is intentionally terminal (assert the tap target / button exists).
- **No direct-to-Adobe / no secret:** the UI calls the partner backend proxy, never Adobe directly, and no IMS/secret name appears in the surface.
- Stub network at the provider/data-layer boundary so no real HTTP fires (per the surface's `DATA_LAYER.md`/`STATE_MANAGEMENT.md`).

### Step 3 — Generate Test Files

Generate test files following the partner's conventions:
- Test file naming (e.g. `*.test.ts`, `*Test.java`, `test_*.py`)
- Test file location (co-located or separate `test/` directory)
- Mock/stub patterns (Mockito, Jest mocks, unittest.mock, httptest)

For HTTP client mocking, mock at the HTTP client level — not at the service level. This ensures the actual serialisation, header construction, and URL building are tested.

For integration tests that need a mock Adobe server, use the partner's existing HTTP mock library (WireMock, MSW, responses, httptest.Server) to stub Adobe's endpoints.

**Watch out — a globally-stubbed HTTP primitive also intercepts the test's OWN requests.** If you replace a global client (e.g. `vi.stubGlobal('fetch', …)`, a global `fetch`/`axios` mock, `unittest.mock.patch` on a shared session), it will also catch the request your route test makes to its *own* local server (supertest, a `localhost`/`127.0.0.1` call) — so the test hits the Adobe stub instead of the real handler and fails confusingly. Scope the stub to Adobe's hostname/base URL, or let `localhost`/`127.0.0.1` pass through to the real client, so only the outbound Adobe call is stubbed.

### Step 4 — WireMock / HTTP Stubs Reference

**Match the stubs to the generated client's actual values** — the paths, IMS token URL path, env-var names, and offer_id below are illustrative (drawn from the Adobe spec + reference app). Use the base URL, route paths, and offer/`partner_reference_id` values that the *generated* code and `service-cards/backend/` (`CONTRACTS.md`, `CONNECTORS.md`, `BUILD_CONFIG.md`) actually use, not these literals. Include the following Adobe API stub responses in integration test setup:

```json
// Workflow API — success
POST /retail/v1/workflows → 202
{ "workflow_type": "CLAIM_PRODUCT", "experience_url": "https://redeem-stg.adobe.com/...", "workflow_attributes": [...] }

// Workflow API — already fulfilled
POST /retail/v1/workflows → 409
{ "code": "ALREADY_FULFILLED", "message": "Order already fulfilled" }

// Get Subscription — found
GET /retail/v1/subscriptions/test_ref_001 → 200
{ "partner_reference_id": "test_ref_001", "offer_id": "30006514", "status": "ACTIVE", "start_date": "...", "end_date": "..." }

// Get Subscription — not found
GET /retail/v1/subscriptions/unknown_ref → 404

// Cancel Subscription — success
POST /retail/v1/subscriptions/test_ref_001 → 200
{ "partner_reference_id": "test_ref_001", "status": "CANCELLED", ... }

// IMS Token
POST /ims/token/v3 → 200
{ "access_token": "test_token_abc123", "token_type": "bearer", "expires_in": 86399 }
```

### Step 5 — Verify, then Report

Before reporting, **run the test suite** (Code Generation Protocol rule 5) and confirm it passes — do not report a count for tests you haven't executed. List all test files created, report test count per file with the actual run result (pass/fail), and if any generated integration code does not have corresponding tests, flag it explicitly.
