---
name: implement-feature
description: >
  Implement one Adobe integration feature end-to-end across all detected surfaces (backend route, mobile/native screen(s), web component(s)), from the feature's approved LLD, following the target repo's own conventions.
---

# Skill: /implement-feature

Implement one Adobe integration feature end-to-end across all detected
surfaces (backend route, mobile/native screen(s), web component(s)), from the
feature's approved LLD, following the target repo's own conventions.

```
/implement-feature <feature>
```

`<feature>` ∈ `claim-product` · `find-subscription` · `cancel-subscription` · `notify-handler`.

Each feature has a **per-feature implementation contract** at
`knowledgebase/feature-specs/<feature>/implementation.md` — it holds the
feature-specific backend route logic, exact error codes, UI states, and special
rules. This skill holds the **generic protocol and the cross-cutting hardening**
that applies to every feature; read both.

> **Feature-name → source-of-truth map** (spec / api-spec / default mocks):
> | `<feature>` | Feature spec | API spec | Default mocks folder |
> |---|---|---|---|
> | `claim-product` | `FS-001-claim-product.md` | `workflow-api.md` | `FS-001-claim-product/` |
> | `find-subscription` | `FS-002-find-subscription.md` | `get-subscription.md` | `FS-002-find-subscription/` |
> | `cancel-subscription` | `FS-003-cancel-subscription.md` | `update-subscription.md` | `FS-003-cancel-subscription/` |
> | `notify-handler` | `FS-004-notify-receiver.md` | `notify-api.md` | `FS-004-notify-demo/` |

---

## Step 1 — Load context

**First, determine which path applies** (see
[`../../manual/methodology/workflow.md`](../../manual/methodology/workflow.md#process-depth-by-target-fast-path-vs-full-workflow)
for the full rationale). Resolve target surfaces per
[`../../manual/methodology/modes.md`](../../manual/methodology/modes.md#surface-registry-and-multi-repo-resolution):

- **Fast path** — no partner repo is registered (`.target-apps`/`.target-app`
  absent at the kit root), so the target has defaulted to the bundled
  `base-ref-app/`.
- **Full workflow** — any surface is registered. Behavior in this branch is
  **unchanged** from before this section existed — every stop-and-tell-the-user
  instruction below still applies exactly as written, with no auto-continue.

1. **Service cards.**
   - **Fast path:** if `service-cards/backend/` is missing, copy the
     pre-bundled cards from
     [`base-ref-app/service-cards/`](../../base-ref-app/service-cards/README.md)
     into the working `service-cards/` location (the same copy-from-bundle
     behavior as
     [`/analyze-partner-codebase`](../analyze-partner-codebase/SKILL.md)'s Step
     0) and report *"Using pre-bundled cards for the base reference app —
     skipping full analysis."* If `base-ref-app/service-cards/` is itself
     somehow missing, tell the user to run `/analyze-partner-codebase` once
     and stop.
   - **Full workflow:** if `service-cards/backend/` is missing, tell the user
     to run `/analyze-partner-codebase` first and stop.
   - Either way: read whichever sets exist — `service-cards/backend/` and any
     UI surface sets present (`service-cards/mobile/`, `service-cards/ios/`,
     `service-cards/android/`, `service-cards/web/`) — understand every
     detected surface, its existing patterns, and where new code goes.
2. **Offer profile (product is a VARIABLE) — same in both paths.** Read `service-cards/shared/OFFER_PROFILE.md` for the offered product name, `offer_id`, and the partner's terminology (offer/benefit/manage words; see also `service-cards/shared/TERMINOLOGY.md`). Use these in **all** generated UI copy/labels — **do NOT assume Adobe Express**. **If any value is a placeholder / `TODO` / `TBD`, STOP and ask the partner before generating** (the "Clarify before you build" gate — [`../../manual/methodology/verification.md`](../../manual/methodology/verification.md#clarify-before-you-build)). This gate fires identically in the Fast path — the bundled app's own `OFFER_PROFILE.md` ships with explicit placeholders for exactly this reason.
3. **Feature contract + spec — same in both paths.** Read `knowledgebase/feature-specs/<feature>/implementation.md` (the per-feature contract) plus its feature spec and API spec (see the map above). Read any integration patterns the contract names (e.g. `integration-patterns/idempotency.md`, `integration-patterns/security.md`).
4. **LLD.**
   - **Escape hatch (either path):** if an LLD already exists on disk for this
     feature at `$APP_<surface>/docs/ai-kit/LLD/{backend,ui}/<feature>-lld.md`
     — because someone already ran `/generate-lld` (Phase A / Phase B)
     by hand — it is the authoritative file manifest **regardless of path**;
     read it and implement exactly what it specifies. This is how an engineer
     deliberately opts into the full rigorous flow even against the bundled
     app, with zero new flags: just run the generator skills first.
   - **Fast path, no LLD yet:** generate it now, internally. Follow the
     **exact same content/rules** as
     [`generate-lld/SKILL.md`](../generate-lld/SKILL.md)'s Phase A (backend
     LLD) + Phase B (UI LLD) — that file is the authoritative spec for LLD
     content; do not duplicate or paraphrase it here — and write the result to
     the same documented path
     (`$APP_<surface>/docs/ai-kit/LLD/{backend,ui}/<feature>-lld.md`). Then
     apply `generate-lld/SKILL.md`'s own Phase A / Phase B review-gate
     checklists as a **mechanical self-check** (that file is the authoritative
     checklist) — continue automatically unless it finds a real contradiction
     (e.g. a UI
     fetch URL/field that doesn't match the backend LLD, a mock state with no
     matching acceptance-criteria row, an env-var name mismatch against
     `BUILD_CONFIG.md`), in which case **STOP and report it precisely** —
     cite the exact mismatch (file:section on each side). State clearly in
     the output that this happened, so it is never silent, e.g.: *"Fast path:
     generated + self-checked backend/UI LLD automatically (target is the
     bundled base app). No partner repo registered — see
     `manual/quick-start.md` to run against your own code with full review
     gates."*
   - **Full workflow, no LLD yet:** unchanged — tell the user to run
     `/generate-lld <feature>` (Phase A generates the backend LLD, Phase B
     the UI LLD) first, or proceed only if they explicitly ask. Do **not**
     auto-generate in this branch.
5. **UI mocks — authoritative screen spec (fidelity mandatory) — same in both paths.** For any UI surface, resolve mocks by precedence: if the kit root `mocks/<partner>/` folder exists (per `mocks/README.md`), read its `manifest.md` and use the screens tagged with the role(s) this feature concerns (`claim-product` → `offer`; `find-subscription`/`cancel-subscription` → `benefits`/`manage`) — partner screen files are named `slide-1.png`, `slide-2.png`, … in journey order (or matched by keyword per `knowledgebase/mock-to-app/mock-ingestion.md`), never by a `claim*`/`FS-001*`-style filename. Else fall back to the default folder (see map above). **Before generating, tell the user which source you resolved** (e.g. "Found partner mocks at `mocks/<partner>/` — using these" or "No partner mocks found — using the default `FS-00X-*` mocks"), so this is a visible checkpoint, not just a note in the final report. **Open/inspect EVERY state SVG/image in the resolved folder (rendered if your agent supports images) AND read each as text** for exact hex / copy / layout. Do NOT proceed from filenames — extract the real structure, copy, colors, and every state. Reproduce each state in Steps 3–4 with the partner's own component library, not a generic screen. **Restate in the final report which mocks were used (partner vs defaults) and which state files you read.**
6. **Prerequisite clients — same in both paths.** For features that call Adobe (all but `notify-handler` inbound), confirm the Retail API client and IMS client exist (from `/generate-adobe-clients`, Phase 2 and Phase 1 respectively). If missing, tell the user to run that first.

## Step 2 — Backend route

Create the route in the partner's **existing** backend, following their routing
convention. **Read `service-cards/backend/CONTRACTS.md` (Overview → base path) for
the exact mount prefix** and compose the full path from it — never invent an
`/api/adobe/...` path. The per-feature contract gives the exact path suffix,
method, request/response shape, and error-code mapping.

Cross-cutting backend rules (all features):

1. **Resolve `partner_reference_id` server-side — NEVER accept it from the client.** Use the partner's existing subscription store (from `service-cards/backend/INTEGRATION_CONTEXT.md` → "Where Subscription State Lives" / "Where `partner_reference_id` Is Stored"), keyed by `(userId, offerId)`. The client request carries no `partner_reference_id`. If no store exists yet, use an in-memory map only as a last resort with a comment "replace with a DB in production" — never mint the id client-side, never rotate it on every click.
2. **`partner_reference_id` lifecycle** (see `integration-patterns/idempotency.md`): unique per `(customer, product)`. Backend generates + stores it on first claim — **there is no fixed format**; use the format recorded in `service-cards/backend/INTEGRATION_CONTEXT.md` → "Where `partner_reference_id` Is Stored" → Format if the partner has an existing ID convention, otherwise ask; a composite like `{partnerId}_{userId}_{offerId}_{uuid}` is only the illustrative fallback this base app and any un-answered case default to. **Reuses** it while active/initiated (repeated claims are idempotent), and generates a **new** id only after a cancellation retires the previous one.
3. **Resolve `offer_id` exactly as the cards describe** (`INTEGRATION_CONTEXT.md` / `BUILD_CONFIG.md`; value in `OFFER_PROFILE.md`) — per-partner config or env var. Never hardcode the offer in the route.
4. **Config-missing ≠ upstream error.** A missing-config case (unset IMS/offer vars) must be distinguishable from a real Adobe error in both the HTTP response and the logs (verification Rule 3).
5. **Log** per the partner's existing logging pattern; use the event names the per-feature contract specifies.

## Cross-surface UI rules (apply to EVERY UI surface — Steps 3 and 4 both defer here)

These rules are **surface-neutral** — they hold identically for mobile/native and
web. Steps 3 and 4 each apply them, then add only their surface-specific mechanics.

- **Reproduce each Step-1 mock state faithfully** (structure, sections, copy, colors, every state) — a structural reproduction, not a loose reference. Substitute the partner's real brand for placeholder headers. The per-feature contract lists the exact screens and states.
- **Reuse the partner's existing UI component library** (from the surface's `UI_CODE_PATTERNS.md` → Existing Component Library) — never external components — and their existing **navigation/routing** pattern to register screens/routes.
- **State-driven entry.** Any offer/home entry must check live subscription status (FS-002) first and branch: if already ACTIVE, show a **Manage** affordance (not the Claim CTA); show Claim/Activate only when NOT_FOUND or CANCELLED.
- **Loading is NOT empty — never show a false status before the API answers.** Distinguish the in-flight *loading* state from a *resolved* empty/not-found state. While the status is being fetched, render the **loading** state (the mocks' loading/skeleton state, e.g. a "Checking…" chip) — do **not** render a resolved default like "Not activated" or a Claim CTA, and do **not** make the entry tappable into claim/manage, because that shows the user wrong information (and a wrong action) before the status is known. Only the **resolved** `NOT_FOUND` state shows the empty/claim UI. On a fetch error, show a distinct "couldn't load / retry" state — never a default "Not activated".
- **Per-user state isolation — reset on every auth change.** Any state holding user-specific data (subscription status, claim state, cached responses) MUST be reset **and refetched** on login, logout, and switch to a different user. Never render a previous user's data to a newly signed-in user — each `userId` has its own server-side `partner_reference_id`/subscription. Bind the fetch to the session so it re-runs when the session changes (e.g. invalidate the subscription provider on any session change / have it watch the session); a value cached from a prior login must not survive a re-login.
- **No dead-end states.** Enumerate every state the feature's provider can reach — including ones with no mock SVG (e.g. `PENDING`/`INITIATED`: the user claimed but closed the Adobe tab before finishing) — and ensure each has a working next action (retry / continue / manage) or is explicitly terminal by design. A status that renders only static text with no tap target is a bug. Retry is always safe because the backend claim route is idempotent while the reference isn't `CANCELLED`.
- **Session-field caveat (any surface).** The authenticated user's unique ID (e.g. a `session.userId` field) is the `userId` **key for the backend store** — it is **not** the `partner_reference_id` sent to Adobe (the backend resolves/generates that server-side). Never send it as a claim body; the claim endpoint takes **no client body**.

## Step 3 — Mobile / native surface(s)

Skip this step entirely for `notify-handler` — per `knowledgebase/feature-specs/FS-004-notify-receiver.md` it is backend-only, with no partner-facing screen.

Only if a native UI card set exists (`service-cards/mobile/`, `service-cards/ios/`,
or `service-cards/android/`). Implement once per present native card set. **Apply
all Cross-surface UI rules above**, then the native specifics:

- **State management:** use the partner's pattern. For Flutter/Riverpod use `NotifierProvider<Notifier, State>` with a sealed state class (same pattern as `session_provider.dart` in the base reference app). Do NOT use `@riverpod` codegen unless `pubspec.yaml` already includes `riverpod_annotation` + `riverpod_generator`. For native iOS/Android use their equivalent (`@StateObject`/ViewModel, etc.).
- Register screens via the partner's native navigation stack; handle the deep-link / return-from-Adobe per the surface's `ROUTES.md`.

## Step 4 — Web surface

Skip this step entirely for `notify-handler` — per `knowledgebase/feature-specs/FS-004-notify-receiver.md` it is backend-only, with no partner-facing screen.

Only if `service-cards/web/` exists. **Apply all Cross-surface UI rules above**
(reproduce every mock state, reuse the component library, state-driven entry,
no-dead-end, session caveat) — web has **full parity** with native, not a reduced
subset. Then the web specifics:

- **State management + data fetch:** use the partner's web pattern (React Query/SWR/Redux/Zustand/Pinia, etc., from `service-cards/web/STATE_MANAGEMENT.md` / `DATA_LAYER.md`); API calls go through the partner's existing **backend proxy** (from `service-cards/web/DATA_LAYER.md`) — never call Adobe from web code.
- Register routes via the partner's web router; adapt each mock state to web layout (responsive breakpoints) while keeping the same states/UX as native.
- The per-feature contract notes any web-specific behavior (e.g. how `experience_url` opens — new tab vs. same-tab redirect).

## Step 5 — Verify (do not skip)

Complete the **nine-rule Code Generation Protocol** in [`../../manual/methodology/verification.md`](../../manual/methodology/verification.md) before reporting. In particular:

- **Rule 1 (env-var names):** any config the feature needs is named consistently between handler, `.env.example`/config source, and validation code.
- **Rule 2 (path consistency):** search for the exact path string the frontend calls (the Dio/fetch path) and the backend `mount prefix + route path`; confirm they are **identical, character-for-character** (including path params and suffixes like `/cancel`). This is the #1 cause of a silent 404.
- **Rule 3:** config-missing is distinguishable from an Adobe error.
- **Rule 5 (run it):** run the backend typecheck and (for native) `flutter analyze`; boot the backend and confirm the route returns **non-404** (e.g. `curl -i`). On a heavy framework where a full boot is impractical, do NOT fake it — compile the touched module and reason reachability from route registration + security chain, stating a full boot was out of scope. Interpret carefully: a `401` is a "healthy unauthenticated" signal **only** once you've confirmed the route is permitted through the security chain (see the notify contract).
- **Mock fidelity:** compare each built screen/state back to its Step-1 mock SVG — structure, sections, copy, states must match. A state present in the mocks but missing from the UI is a gap — add it and iterate.
- **No dead-end states:** re-confirm every provider state (including `PENDING`/`INITIATED`) has a working action or is intentionally terminal.

## Step 6 — Report

List all created/modified files. State explicitly what you verified (path match,
typecheck, analyze, route reachability). Note which UI mocks were used. Then print
the per-feature **Report reminders** from the contract (e.g. the `offer_id`
action-required note, deep-link registration, or — for `notify-handler` — the
mandatory partner→Adobe hand-off block).

**Fast path only — auto-run the remaining kit steps.** After verification
passes, automatically **also** perform what
[`generate-env-config/SKILL.md`](../generate-env-config/SKILL.md),
[`generate-tests/SKILL.md`](../generate-tests/SKILL.md), and
[`generate-integration-checklist/SKILL.md`](../generate-integration-checklist/SKILL.md)
do — those files remain the authoritative spec for each; do not duplicate
their steps here, just run them. State plainly in the final report that this
happened, e.g.: *"Fast path: also generated `.env.example` + startup
validation, generated and ran tests, and wrote `INTEGRATION_CHECKLIST.md` —
see each section above."*

**Full workflow — unchanged.** Do not auto-run the three skills above; the
user runs `/generate-env-config`, `/generate-tests`, and
`/generate-integration-checklist` separately, as today.
