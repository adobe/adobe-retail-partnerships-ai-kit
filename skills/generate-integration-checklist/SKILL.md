---
name: generate-integration-checklist
description: >
  Scan the entire codebase and produce a definitive integration checklist — what's done, what's partial, and what's missing. Share this with Adobe partner engineering when requesting stage access review.
---

# Skill: /generate-integration-checklist

> Also invoked automatically by `implement-feature`'s Fast path when targeting
> the bundled base app; this file remains the authoritative spec either way,
> and running it standalone always works for the Full workflow or to force
> extra rigor on the bundled app too.

Scan the entire codebase and produce a definitive integration checklist — what's done, what's partial, and what's missing. Share this with Adobe partner engineering when requesting stage access review.

---

## Instructions

### Step 1 — Load Context

1. Read all service cards under `service-cards/` — the `backend/` set, each UI surface set (`mobile/`, `web/`, `ios/`, `android/` — whichever exist), `shared/` (OFFER_PROFILE, TERMINOLOGY, SURFACE_SCOPE), and `security/DIRECT_CALLS_AUDIT.md` if present — for surfaces detected and each surface's `READINESS.md`. If no `service-cards/` sets exist, tell the user to run `/analyze-partner-codebase` first.
2. Scan all files in the project for Adobe integration references.

### Step 2 — Check Each Integration Point

First resolve the backend's route base path from `service-cards/backend/CONTRACTS.md` (Overview → base path / mount prefix) and each feature's path suffix from the per-feature contract — **do NOT assume an `/api/adobe/*` shape** (it contradicts the feature contracts, which use paths like `/api/claim` and take no path param for the reference id). For each item below, search the codebase and determine: ✅ Implemented / ⚠️ Partial / ❌ Not found

**Backend — IMS Token**
- [ ] IMS token service exists and calls `client_credentials` grant
- [ ] Token caching implemented (check for expiry logic)
- [ ] Token refresh on 401 handled
- [ ] `ADOBE_IMS_CLIENT_ID` and `ADOBE_IMS_CLIENT_SECRET` read from env (not hardcoded)

**Backend — Retail API Client**
- [ ] `POST /retail/v1/workflows` call exists
- [ ] `GET /retail/v1/subscriptions/{id}` call exists
- [ ] `POST /retail/v1/subscriptions/{id}` (cancel) call exists
- [ ] All required headers sent: `Authorization: Bearer`, `X-API-Key`
- [ ] All documented error codes handled explicitly

**Backend — Routes** (compose each full path from the `CONTRACTS.md` base path + the per-feature contract's suffix; the paths below are role labels, not literal paths)
- [ ] Claim route exists (the claim-product path from its contract — e.g. `<base>/claim`; no reference-id path param)
- [ ] Find-subscription route exists (the find-subscription path from its contract)
- [ ] Cancel-subscription route exists (the cancel-subscription path from its contract)
- [ ] Notify-receiver route exists (the notify-handler path the partner registers with Adobe)

**Backend — Notify Handler**
- [ ] Auth validation on Notify endpoint (timing-safe)
- [ ] Idempotency logic (duplicate events handled)
- [ ] `status: "Active"` processing implemented
- [ ] `status: "Cancelled"` processing implemented
- [ ] Auth config for the registered Notify type read from env/secret store (token types — `OAUTH2_CLIENT_CREDENTIALS`/`CUSTOM_TOKEN` — may need none)

**Security**
- [ ] No Adobe credentials in mobile source code
- [ ] No Adobe credentials in web source code
- [ ] (dotenv stacks) `.env` in `.gitignore` — skip on typed/yaml config stacks (no `.env`)
- [ ] Config example committed with all required variables (`.env.example` on dotenv stacks; documented `application.yml`/typed-config keys otherwise)
- [ ] IMS token never returned to frontend

**Config**
- [ ] Every var the generated code actually reads is present in the config source (resolve the real names from the code, not an assumed `ADOBE_*` set — Code Generation Protocol rule 1)
- [ ] Config reconciled per the mechanism (dotenv: live `.env` diff; typed/yaml: config file keys) — no boot-required var missing/empty (Protocol rule 4)
- [ ] Startup validation for the boot-required vars (graceful `*_NOT_CONFIGURED` for `ADOBE_API_KEY`/`ADOBE_OFFER_ID` — not boot-fatal, Rule 3)
- [ ] For each frontend→backend endpoint, the client path equals the server `mount + route` (Protocol rule 2)

**Mobile** (skip if not detected)
- [ ] Claim flow UI implemented
- [ ] Subscription status screen implemented
- [ ] Cancel confirmation implemented
- [ ] Deep link return handling implemented

**Web** (skip if not detected)
- [ ] Claim flow UI implemented
- [ ] Subscription status screen implemented
- [ ] Cancel confirmation implemented

**Tests**
- [ ] IMS token service tests
- [ ] Retail API client tests (including error scenarios)
- [ ] Backend route tests
- [ ] Notify handler tests (including idempotency)

### Step 3 — Security Scan

Search for potential security violations — flag any found:
- `partners.adobe.io` or `partners-stage.adobe.io` in mobile/web source
- `ims-na1.adobelogin.com` in mobile/web source
- `CLIENT_SECRET` or `client_secret` hardcoded (not in `.env.example`)
- IMS `access_token` in any API response returned to frontend

### Step 4 — Write INTEGRATION_CHECKLIST.md

Write `INTEGRATION_CHECKLIST.md` to the project root:

```markdown
# Adobe Integration APIs — Checklist
Generated: {date}
Partner surfaces: {list}

## Status Summary
- ✅ Done: {count}
- ⚠️ Partial: {count}
- ❌ Missing: {count}

## Backend
[checklist items]

## Security
[checklist items]

## Mobile [if applicable]
[checklist items]

## Web [if applicable]
[checklist items]

## Tests
[checklist items]

## Security Scan Results
{violations found, or "No violations found"}

## Onboarding Checklist (for Adobe partner engineering)
- [ ] Stage IMS credentials provided by Adobe
- [ ] Stage offer_id provided by Adobe
- [ ] Stage API key (X-API-Key) provided by Adobe
- [ ] Stage IPs of partner backend allowlisted at Adobe
- [ ] Notify endpoint URL and auth credentials shared with Adobe
- [ ] Test partner_reference_id provided for integration testing
- [ ] Deep link / return URL registered with Adobe
```

### Step 5 — Print to User

Print the full checklist. For any ❌ items, suggest which skill to run. For any ⚠️ partial items, describe what's missing.

End with: "Share `INTEGRATION_CHECKLIST.md` with Adobe partner engineering when requesting stage access. The onboarding section lists what Adobe needs from you before testing can begin."
