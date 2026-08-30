---
name: generate-lld
description: >
  Generate reviewable backend and UI Low-Level Designs (LLDs) for one feature, before any code is written — Phase A (backend LLD, the DG-3 gate) then Phase B (UI LLD, the DG-4 gate). See ../../manual/methodology/card-model.md#lld-section-contract and ../../manual/methodology/workflow.md.
---

# Skill: /generate-lld

> Also invoked automatically by `implement-feature`'s Fast path when targeting
> the bundled base app; this file remains the authoritative spec either way,
> and running it standalone always works for the Full workflow or to force
> extra rigor on the bundled app too.

Generate reviewable backend and UI Low-Level Designs (LLDs) for one feature, before any code is written, in two sequential phases:

- **Phase A — Backend LLD.** This is the explicit design gate (DG-3) between service cards and implementation.
- **Phase B — UI LLD**, for every detected UI surface. This is the explicit design gate (DG-4) — the last chance to catch a product-intent mismatch — and treats the Phase-A-approved backend LLD as the authoritative contract.

See `../../manual/methodology/card-model.md#lld-section-contract` and `../../manual/methodology/workflow.md`.

**Run after `/analyze-partner-codebase` (backend service cards must exist) and before `/implement-*`.**

Usage: `/generate-lld <feature>` where `<feature>` ∈ `claim-product`, `find-subscription`, `cancel-subscription`, `notify-handler` (maps to `FS-001..FS-004`). Optionally `/generate-lld <feature> --surface mobile|web|ios|android` to restrict Phase B to one UI surface (omit `--surface` to generate for every UI surface that has service cards).

**`notify-handler` is backend-only — skip Phase B for it.** Per `knowledgebase/feature-specs/FS-004-notify-receiver.md` ("Surfaces: Backend service only") there is no partner-facing screen for this feature (the one demo screen under `knowledgebase/ui-mocks/defaults/FS-004-notify-demo/` is explicitly dev-only, never for a partner app). Run Phase A only for `notify-handler`; do not generate a UI LLD.

Phase A and Phase B run sequentially in one invocation: **Phase A must be approved before Phase B starts.** In the Full workflow this is a real stop-and-wait human checkpoint. In the Fast path (no partner repo registered), both phases run without stopping for approval, exactly as `implement-feature`'s Fast-path branch already assumes.

---

## Phase A — Backend LLD (DG-3)

You are writing a backend LLD — a precise implementation plan a partner engineer approves **before** you touch their repo.

**1. Resolve surfaces.** Read `.target-apps` and resolve `$APP_backend` per `../../manual/methodology/modes.md#surface-registry-and-multi-repo-resolution`. If backend service cards do not exist under `service-cards/backend/`, tell the user to run `/analyze-partner-codebase` first and stop.

**2. Load inputs (in this precedence).** Service cards are the primary source of truth; source code fills gaps; **trust source on contradiction**:
- `service-cards/backend/` — all eight cards (esp. `CONTRACTS.md`, `CONNECTORS.md`, `BUILD_CONFIG.md`, `INTEGRATION_CONTEXT.md`, `MODULE_INDEX.md`).
- `service-cards/shared/OFFER_PROFILE.md` — offered product, `offer_id`, Notify strategy. If a value is a placeholder, **STOP and ask** (verification rule 8).
- `knowledgebase/feature-specs/FS-00X-*.md` — the behavior to build.
- `knowledgebase/feature-specs/<feature>/implementation.md` — the exact route logic, error codes, and special rules `implement-feature` will apply; the LLD must not contradict it.
- `knowledgebase/api-spec/*.md` — the Adobe endpoint contract(s) this feature calls.

**3. Write the LLD** to `$APP_backend/docs/ai-kit/LLD/backend/<feature>-lld.md` (this design record is the ONLY thing that lands in the partner repo at this stage; no code yet). **Monorepo:** when `$APP_backend` resolves to a monorepo root but the backend actually lives in a nested subproject (e.g. `bff/`, `services/api/` — the directory recorded in `service-cards/backend/` `SERVICE_CARD.md`/`MODULE_INDEX.md`), write the LLD **beside that detected subproject** (`<subproject>/docs/ai-kit/LLD/backend/<feature>-lld.md`), not at the repo root, so the design sits with the code it plans. Follow the section contract in `../../manual/methodology/card-model.md#lld-section-contract`:

1. **Summary** — what the feature does on the backend; the cards/specs drawn on.
2. **Data Flow** — request → IMS token → Adobe endpoint → response mapping → partner response. (Most-scrutinized section at DG-3.)
3. **Change Summary** — an overview table `File | Action (CREATE/MODIFY) | Layer | Reason` (layers: Model, Controller, Route, Connector, Constants, Util, Config), then one **self-contained** subsection per file describing exactly what to add/change. Every "reuse existing X" claim must cite a real path from the cards.
4. **DB / State Changes** — where `partner_reference_id` and subscription state are stored (from `INTEGRATION_CONTEXT.md`); mint/retire rules per `knowledgebase/integration-patterns/idempotency.md`.
5. **Design Decisions** — `Decision | Why | Trade-off | Enforcement`.
6. **Acceptance-Criteria Coverage** — each feature-spec criterion → where met.
7. **Out of Scope**.

**4. Honor the invariants** from `../../manual/methodology/card-model.md#concepts-surfaces-apis-and-the-security-invariant` (backend-to-backend only; config-missing ≠ upstream error; env-var name reuse per `BUILD_CONFIG.md`; no hardcoded per-partner values). Do NOT write code — this skill produces a design only.

### Review gate (DG-3)

After writing, tell the user this is a **review checkpoint** and print a short summary: the data flow, the file-change manifest, and any assumptions or `TBD`s. Then run this checklist and report each item (✅ / ⚠️ / ❌) with the exact file:section for each issue:

- Data flow is correct end-to-end (IMS → Adobe → response mapping).
- Every row in the Change Summary is justified; every "reuse existing X" claim resolves to a real path in `service-cards/backend/`.
- Design decisions are sound; env-var names match `service-cards/backend/BUILD_CONFIG.md` (verification rule 1); no hardcoded per-partner values (rule 6).
- Acceptance-criteria coverage is complete against `knowledgebase/feature-specs/FS-00X-*.md`.
- Out-of-scope is explicit.

Ask the partner engineer to review `docs/ai-kit/LLD/backend/<feature>-lld.md` and approve or request edits. For small fixes, edit the LLD directly; for structural problems, fix the source card/spec first and re-run. State whether the gate is **cleared** or **blocked**. **STOP here — do not proceed to Phase B or `/implement-*` until Phase A is approved** (Fast path: continue automatically, per the Fast-path note above).

---

## Phase B — UI LLD (DG-4)

You are writing a UI LLD — a precise per-screen plan a partner engineer approves **before** you touch their UI repo.

**1. Resolve surfaces.** Read `.target-apps` and resolve the UI surface path(s) per `../../manual/methodology/modes.md#surface-registry-and-multi-repo-resolution`. If the surface's service cards do not exist under `service-cards/<surface>/`, run `/analyze-partner-codebase` first and stop.

**2. Load inputs.** The **Phase-A-approved backend LLD is the authoritative contract** — every fetch unit's URL and fields must match it exactly (a mismatch across repos ships as a silent 404; see verification rule 2):
- `$APP_backend/docs/ai-kit/LLD/backend/<feature>-lld.md` — the approved backend LLD from Phase A. If it is missing/unapproved, stop and complete Phase A first.
- `service-cards/<surface>/` — the UI cards (esp. `ROUTES.md`, `DATA_LAYER.md`, `STATE_MANAGEMENT.md`, `UI_CODE_PATTERNS.md`, `INTEGRATION_CONTEXT.md`). The generated UI **must reuse the partner's existing component library** from `UI_CODE_PATTERNS.md`.
- `service-cards/shared/OFFER_PROFILE.md` + `service-cards/shared/TERMINOLOGY.md` — product name + the partner's own words. **Never default to Adobe Express.** If a value is a placeholder, STOP and ask.
- The mocks: if `mocks/<partner>/` exists, read its `manifest.md` and use the screens tagged with the role(s) this feature concerns (`claim-product` → `offer`; `find-subscription`/`cancel-subscription` → `benefits`/`manage`) — a partner's one mock folder can hold screens for every feature, so filter to the relevant role rather than reproducing the whole set. Else fall back to the defaults in `knowledgebase/ui-mocks/defaults/FS-00X-*/`. Reproduce **every screen state** for the resolved screens.

**3. Write the LLD** to `$APP_<surface>/docs/ai-kit/LLD/ui/<feature>-lld.md`, per `../../manual/methodology/card-model.md#lld-section-contract`. **Monorepo:** when the surface resolves to a monorepo root but the UI subproject is nested (the directory recorded in `service-cards/<surface>/`), write the LLD **beside that detected subproject** (`<subproject>/docs/ai-kit/LLD/ui/<feature>-lld.md`), not the repo root. The backend LLD you read in step 2 follows the same rule — resolve it beside the backend subproject if that's where it was written.

1. **Summary** — the journey; state "mocks: partner|default" and "backend LLD contract used".
2. **Data Flow** — screen → partner backend → screen (never screen → Adobe directly).
3. **Change Summary** — overview table `File | Action | Layer | Reason` (layers: Route, Component, Data Fetch, State, Style, Util) + a self-contained subsection per file.
4. **Design Decisions** — including terminology decisions traced to `shared/`.
5. **Acceptance-Criteria Coverage** — must cover **every mock state** (loading / active / already-active / cancelled / not-found / error as applicable).
6. **Out of Scope**.

Do NOT write code — design only.

### Review gate (DG-4)

After writing, tell the user this is the **last review checkpoint before code**. Print: the journey step list, the file-change manifest, and confirm every fetch URL/field matches the backend LLD. Then run this checklist and report each item (✅ / ⚠️ / ❌) with the exact file:section for each issue:

- Every fetch unit's URL/fields match the approved backend LLD **exactly** (rule 2).
- The step-by-step journey matches the experience card / mocks; **every screen state** is covered (loading/active/already-active/cancelled/not-found/error).
- Copy/terminology matches `service-cards/shared/TERMINOLOGY.md` + `OFFER_PROFILE.md` (never defaults to Adobe Express).
- Component reuse matches `service-cards/<surface>/UI_CODE_PATTERNS.md`.
- Watch for the classic mismatch: "confirmation modal" vs "navigation to a confirmation page."

Ask them to review `docs/ai-kit/LLD/ui/<feature>-lld.md` and approve. For small fixes, edit the LLD directly; for structural problems, fix the source card/spec first and re-run. State whether the gate is **cleared** or **blocked**. Do not proceed to `/implement-*` until approved (Fast path: continue automatically, per the Fast-path note above).
