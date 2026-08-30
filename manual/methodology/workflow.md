# Canonical Workflow

> Agent-neutral. This is the methodology the kit follows regardless of which
> coding agent drives it. See [adapters/](../../adapters/README.md) for how a
> specific agent (e.g. Claude Code) invokes each step.

The kit turns a partner's existing system into one that carries the Adobe
integration. It does this through a **knowledge funnel**: Adobe supplies *what to
build* (feature specs + API specs in `knowledgebase/`); the analyze step derives
*how to build it here* ([service cards](card-model.md)); the two merge into
**Low-Level Designs (LLDs)** that are reviewed and approved before any code is
written; then code is generated and verified.

```text
knowledgebase/  ── what to build ──┐
                                   ├──►  LLD (backend)  ─┐
service-cards/  ── how to build ───┘     LLD (ui)       ─┼──►  code  ──►  verify
                                                          │
                                   review gates ─────────┘
```

---

## The canonical stages

```text
analyze  →  service cards  →  backend LLD  →  UI LLD  →  implement  →  verify
              (DG-1/DG-2)      (DG-3)          (DG-4)
```

Each stage produces a durable artifact and (for the design stages) a review
gate. These review gates are the **Decision Gates**, labeled **DG-1** through
**DG-4** ("DG" = Decision Gate). **A stage does not begin until the previous gate
is explicitly cleared** — an error that passes a gate compounds downstream.

### Stage 1 — Analyze

Detect every surface (backend, mobile/web/ios/android), deep-dive each one's
stack/auth/config/logging, run the direct-Adobe-call **security audit**, and run
the interactive **offer intake** (offered product, `offer_id`, terminology,
surfaces, Notify intent). Output: one [service-card](card-model.md) set per
surface + `shared/` context + `security/DIRECT_CALLS_AUDIT.md` if findings exist.

> **This is interactive.** The offered product is a variable — never assumed. See
> [verification.md#clarify-before-you-build](verification.md#clarify-before-you-build).

### Stage 2 — Service cards → **DG-1 / DG-2**

The cards from Stage 1 are the reviewable artifact.

- **DG-1 — Backend service card review.** Highest-priority cards: `CONNECTORS.md`
  (auth/timeout/retry/error posture), `CONTRACTS.md` (inbound auth + default
  authorization), `INTEGRATION_CONTEXT.md`, `BUILD_CONFIG.md` (verify commands).
- **DG-2 — UI service card review.** Highest-priority cards: `ROUTES.md` and
  `DATA_LAYER.md` (an inaccurate data layer is the most common source of
  generated-code bugs), plus `UI_CODE_PATTERNS.md` (the component library the
  generated UI must reuse).

Fix findings by editing the cards directly; only re-run analyze for structural
problems.

### Stage 3 — Backend LLD → **DG-3**

Merge the backend cards + `shared/` context + the relevant feature/API specs into
a **backend LLD** (`docs/ai-kit/LLD/backend/<feature>-lld.md` in the target repo).
The LLD is the cheapest place to catch a design error. See
[card-model.md#lld-section-contract](card-model.md#lld-section-contract) for the section contract.

- **DG-3 — Backend LLD review.** Verify the data-flow, the file-change manifest
  (every "reuse" claim must exist in the cards), design decisions, acceptance-
  criteria coverage, and out-of-scope. Edit the LLD directly for small fixes.

### Stage 4 — UI LLD → **DG-4**

Merge the experience/feature spec (+ mocks) + the UI cards + the **approved
backend LLD** (its contract is authoritative for every fetch unit) into a **UI
LLD** (`docs/ai-kit/LLD/ui/<feature>-lld.md`). See [card-model.md#lld-section-contract](card-model.md#lld-section-contract).

- **DG-4 — UI LLD review.** Last chance to catch product-intent mismatch. Verify
  fetch-hook URLs/fields match the backend LLD exactly, the step-by-step journey
  matches the experience card / mocks, every error state is present, and the
  terminology matches `shared/TERMINOLOGY.md` and `shared/OFFER_PROFILE.md`.

### Stage 5 — Implement

Execute the approved LLDs — write real code into the resolved surface repos. The
LLD defines *what*; the service cards define *how*. Includes a **wiring check**
(client path == server mount + route, character for character, across repos) and
an experience-card/mock coverage check before reporting.

### Stage 6 — Verify

Exercise the change end-to-end. Run **each surface's own** authoritative
build/typecheck + tests in its own repo, confirm route reachability across repos,
and (for UI) confirm mock/experience-card fidelity. See
[verification.md](verification.md). **Never report success on unverified code.**

---

## Two delivery modes

The workflow above is the backbone. It runs in one of two modes; both preserve
every stage's rigor. See [modes.md](modes.md).

- **Mode B — Build app from mocks.** The partner-facing UI is rebuilt to the
  partner's mocks on top of the proven reference integration, materialized into a
  branded app. Mock fidelity is mandatory.
- **Mode A — Integrate into an existing codebase.** The integration is written
  into the partner's own repos in their own stack. This is the mode the six
  stages above describe most directly.

---

## Process depth by target: Fast path vs Full workflow

The six stages above are constant — what varies is **how much process wraps
them**, and that varies by *target*, not by preference. A run against the
kit's own bundled, Adobe-controlled `base-ref-app/` carries a fundamentally
different risk profile than a run against a real partner's unknown production
codebase, and the kit reflects that automatically, with no flag to set.

### Fast path — target defaults to the bundled `base-ref-app/`

**Triggers when no partner repo is registered** — `.target-apps`/`.target-app`
absent at the kit root, so the target resolves to the bundled `base-ref-app/`
(the existing Mode-A-default behavior, [modes.md](modes.md)). In this case
`implement-feature <feature>` is a **single command** that internally does the
whole thing:

1. Uses the [pre-bundled service cards](../../base-ref-app/service-cards/README.md)
   shipped at `base-ref-app/service-cards/` — no live re-analysis.
2. Auto-generates the backend + UI LLD to disk (same content/rules as
   [`generate-lld`](../../skills/generate-lld/SKILL.md)'s Phase A (backend) +
   Phase B (UI) — that file stays the authoritative spec).
3. Auto-runs `generate-lld`'s own Phase A / Phase B review-gate checklists as a
   **mechanical self-check** — continues automatically unless it finds an
   actual contradiction (e.g. a UI fetch URL that doesn't match the backend
   LLD), in which case it **stops and reports the exact mismatch**. Same
   "stop only when something's really wrong" philosophy the kit already uses
   for the offer-clarify gate and the no-dead-end rule — not a lowered bar,
   just no *human* wait when nothing is actually wrong.
4. Generates the code.
5. Auto-runs what [`generate-env-config`](../../skills/generate-env-config/SKILL.md),
   [`generate-tests`](../../skills/generate-tests/SKILL.md), and
   [`generate-integration-checklist`](../../skills/generate-integration-checklist/SKILL.md)
   do.

The report states plainly that this happened — the Fast path is never silent
about having skipped the human wait.

### Full workflow — a partner repo IS registered

**Triggers whenever any surface is registered** in `.target-apps`/
`.target-app`. **Completely unchanged:** the same explicit multi-step,
multi-gate sequence as always —
[`analyze-partner-codebase`](../../skills/analyze-partner-codebase/SKILL.md) →
`generate-adobe-clients` (Phase 0 design + review → Phase 1 IMS / Phase 2 Retail API) →
[`generate-lld`](../../skills/generate-lld/SKILL.md) Phase A (DG-3) →
`generate-lld` Phase B (DG-4) →
[`implement-feature`](../../skills/implement-feature/SKILL.md) →
`generate-env-config` / `generate-tests` / `generate-integration-checklist`,
with mandatory human review at each DG gate exactly as documented above. This
is where the rigor genuinely matters: the code is about to be written into
unfamiliar production infrastructure the kit has never seen before.

### Escape hatch — opting into the full rigor against the bundled app too

If someone has **already manually run** `generate-lld` (Phase A / Phase B)
against the bundled base app, an LLD already exists on disk
at the documented path (`$APP_<surface>/docs/ai-kit/LLD/{backend,ui}/<feature>-lld.md`
— for the fast path that is `base-ref-app/docs/ai-kit/LLD/...`).
`implement-feature` always checks for an existing LLD first, in **either**
path, and uses it instead of generating a new one. This means an engineer can
still deliberately opt into the full, gated flow even against the bundled
app — with **zero new flags** — simply by running the design-gate skills by
hand first.

### Hard invariant — never relaxed in either path

The Fast path changes exactly three things: **(a)** whether service cards are
re-derived vs. reused from the bundle, **(b)** whether the LLD-generation +
review steps require a human wait vs. auto-continue-with-self-check, and
**(c)** whether env-config/tests/checklist are separate manual invocations vs.
auto-run at the end. It changes **nothing else**. In particular, none of the
following are ever skipped, weakened, or made conditional on which path is
running — they are not about partner-repo trust, they are correctness and
security invariants:

- The **nine-rule verification protocol** ([verification.md](verification.md))
  — build/typecheck/test/route-reachability verification.
- The **"clarify before you build" hard gate**
  ([verification.md#clarify-before-you-build](verification.md#clarify-before-you-build))
  — still fires in the Fast path if the offer/product is unresolved (see the
  bundled app's own
  [`shared/OFFER_PROFILE.md`](../../base-ref-app/service-cards/shared/OFFER_PROFILE.md),
  which ships with explicit placeholders for exactly this reason).
- **Secret containment** (verification rule 9).
- **Mock fidelity** (every UI state reproduced faithfully).
- **Server-side `partner_reference_id` resolution** (never accepted from the client).
- The **Notify auth-reconciliation logic** (rule 7 — reuse the partner's own mechanism).
- The **PENDING / no-dead-end rule** (every reachable state has a working action).

### Why one command on the Fast path, seven steps on the Full workflow

The Full workflow is deliberately several discrete steps —
`analyze-partner-codebase` → `generate-adobe-clients` → `generate-lld` →
`implement-feature` → `generate-env-config` → `generate-tests` →
`generate-integration-checklist` — because each one hands you an artifact to
inspect (service cards, then a backend design, then a UI design) before the
next one runs anything into your real codebase. That review surface is the
point, not overhead.

The Fast path collapses those same steps into a single `implement-feature`
command **only because the target is the kit's own bundled base app** — there
is no unfamiliar production code to protect, and no human needs to wait between
design and code. Nothing is removed: the same LLDs are still written to disk,
the same DG-3/DG-4 review checklists still run (as an automatic self-check that
stops only on a real contradiction), and the same verification and security
rules below still apply. Only the *human wait* and the *separate commands*
disappear — never a gate, a check, or a rule.

---

## Where the artifacts live

| Artifact | Location | Committed to partner repo? |
|---|---|---|
| Service cards | `service-cards/` **in the kit** | No |
| Backend / UI LLD | `docs/ai-kit/LLD/{backend,ui}/` **in the target repo** | Yes (design record) |
| Generated integration code | the relevant surface repo | Yes |
| Verification report | printed; optionally `docs/ai-kit/` | Optional |

The kit's own files (`manual/`, `adapters/`, `knowledgebase/`, `service-cards/`)
**never** land in a partner repo. See [modes.md](modes.md) and
[card-model.md](card-model.md).
