# Service Card Model

> The canonical, agent-neutral description of the kit's card system. Any coding
> agent (or a human) can read this to understand what a service card is, the
> full file taxonomy, and how the cards are consumed downstream.

A **service card** is a durable, machine-readable description of one *surface* of
a partner's system — what it is, how it is built, and how ready it is to receive
the Adobe integration. Cards are the "how to build it here" half of the
[knowledge funnel](workflow.md); the feature specs and API specs in
`knowledgebase/` are the "what to build" half.

Cards are written **into the kit** (never into a partner repo) at
`service-cards/` and are regenerated whenever the partner's code changes. They
are the single input every downstream step reads before writing code.

---

## Concepts: Surfaces, APIs, and the Security Invariant

> Agent-neutral. The domain model shared by every stage and mode.

You are helping a partner developer integrate **Adobe Integration APIs**
into their existing application. The partner already has a running system; you
are integrating into what exists, not building from scratch.

The integration lets the partner offer an **Adobe product of their choice**
(resolved from the mocks / confirmed at intake — **never assumed**, see
[verification.md#clarify-before-you-build](verification.md#clarify-before-you-build))
to their subscribers via a claim → manage → cancel subscription lifecycle.

### The three partner surfaces

```
┌──────────────────────────────────────────────────────────────┐
│                      PARTNER ECOSYSTEM                         │
│  ┌────────────┐   ┌───────────────────────┐  ┌────────────┐   │
│  │ Mobile App │   │   Backend Service(s)  │  │  Web App   │   │
│  │ Claim UI   │──▶│ IMS token client      │◀─│ Same flows │   │
│  │ Sub status │   │ Retail API client     │  │ as mobile  │   │
│  │ Cancel     │   │ Notify receiver       │  │            │   │
│  └────────────┘   └───────────┬───────────┘  └────────────┘   │
└───────────────────────────────┼──────────────────────────────┘
                                 │ backend-to-backend only
                   ┌─────────────▼─────────────┐
                   │ Adobe Integration APIs    │
                   │ • IMS OAuth Token         │
                   │ • Workflow API            │
                   │ • Get Subscription        │
                   │ • Update Subscription     │
                   │ • Notify API (→ Partner)  │
                   └───────────────────────────┘
```

The three-surface model is generic guidance — a partner may have any combination.
The analyze step detects whatever actually exists and writes one card set per
detected surface.

**Server-rendered / monolithic UI.** If the partner's UI is rendered inside the
SAME process/repo as the backend — Rails views, Django templates, a Next.js app
doing SSR+API together in one codebase — with no separate client-side
data-fetch layer, do not force a separate UI card set with fields that don't
apply. Fill the `backend/` card set only, and record how the claim /
subscription / cancel screens are rendered in `INTEGRATION_CONTEXT.md`'s "UI
Rendering" subsection (§4.2) — which templates/views render each screen and
how they read backend state directly. No `DATA_LAYER.md` (or any other UI
card) is produced, since there is no separate client-side fetch layer to
describe.

### Security invariant — never violate

All Adobe Integration API calls are made from the partner's **backend
only**. IMS credentials (`CLIENT_ID`, `CLIENT_SECRET`) never appear in mobile or
web code. Mobile/web call the partner's own backend endpoints.

### The Adobe APIs — where the contract lives

The full request/response/error contract for every endpoint lives in
`knowledgebase/api-spec/` — the **single source of truth**. Do not duplicate
params, response JSON, or error tables anywhere; link to the spec file.

| Endpoint | Direction | Contract |
|---|---|---|
| IMS Token (`client_credentials`) | Partner backend → Adobe IMS | `knowledgebase/api-spec/ims-token.md` |
| Workflow API (initiate Claim) | Partner backend → Adobe | `knowledgebase/api-spec/workflow-api.md` |
| Get Subscription | Partner backend → Adobe | `knowledgebase/api-spec/get-subscription.md` |
| Update Subscription (Cancel/Renew) | Partner backend → Adobe | `knowledgebase/api-spec/update-subscription.md` |
| Notify API (Adobe → partner, optional) | Adobe → Partner backend | `knowledgebase/api-spec/notify-api.md` |

### Key invariants (never violate)

1. **`partner_reference_id` is permanent per (customer, product) pair.** After
   cancellation and re-purchase, a **new** `partner_reference_id` is generated.
2. **FULFILLED/CANCELLED orders are terminal.** A 409 `ALREADY_FULFILLED` means
   the subscription exists — redirect to status rather than retrying the claim.
3. **Backend proxy is mandatory.** Mobile/web call the partner backend, which
   calls Adobe. Credentials never reach the frontend.
4. **Notify endpoint must be idempotent.** Adobe may call multiple times; process
   only if state actually changed.
5. **Token refresh strategy.** Refresh the IMS token 5 minutes before expiry.

### Feature specs

Per-feature behavioral specs live in `knowledgebase/feature-specs/`:

| Spec | Feature |
|---|---|
| `FS-001-claim-product.md` | Claim |
| `FS-002-find-subscription.md` | Subscription status |
| `FS-003-cancel-subscription.md` | Cancel |
| `FS-004-notify-receiver.md` | Notify webhook |

### Integration patterns

Reusable patterns live in `knowledgebase/integration-patterns/`: backend-proxy,
environment-config, error-handling, idempotency, security, token-caching.

---

## LLD Section Contract

> Agent-neutral. The LLD is the explicit design layer between *service cards* and
> *generated code*. It exists so a partner engineer has an **approval point
> before code is written into their repo** — this increases trust, reduces unsafe
> generation into unfamiliar repos, and makes the system easy to explain.

There are two LLDs per feature: a **backend LLD** and a **UI LLD**. Each is a
single Markdown file whose §"Change Summary" table is an authoritative file
manifest, and whose per-file subsections are self-contained implementation
specs. Every bullet in an LLD is an independently verifiable claim consumed by
both [implement](workflow.md) and [verify](verification.md).

### Backend LLD

**Inputs:** the backend service cards (primary source of truth;
source code fills gaps, and source wins on contradiction) + `shared/` context +
the feature spec (`knowledgebase/feature-specs/`) + the API spec
(`knowledgebase/api-spec/`).

**Output:** `docs/ai-kit/LLD/backend/<feature>-lld.md` in the target backend repo.

**Sections:**

1. **Summary** — what the feature does on the backend; which cards/specs it draws on.
2. **Data Flow** — request→Adobe→response path; the most important section at DG-3.
3. **Change Summary** — an overview table `File | Action (CREATE/MODIFY) | Layer | Reason`, then one self-contained subsection per file. Backend layers: Model, Controller, Route, Connector, Constants, Util, Config.
4. **DB / State Changes** — where `partner_reference_id` and subscription state are stored (from `INTEGRATION_CONTEXT.md`).
5. **Design Decisions** — `Decision | Why | Trade-off | Enforcement`.
6. **Acceptance-Criteria Coverage** — each feature-spec criterion → where it is met.
7. **Out of Scope** — what this LLD deliberately does not do.

**Gate:** DG-3 (see [workflow.md](workflow.md)).

### UI LLD

**Inputs:** the experience/feature spec (+ mocks — partner mock or default) + the
UI service cards + the **approved backend LLD** (its contract is
authoritative for every fetch unit; URLs/fields must match exactly) +
`shared/OFFER_PROFILE.md` + `shared/TERMINOLOGY.md`.

**Output:** `docs/ai-kit/LLD/ui/<feature>-lld.md` in the target UI repo.

**Sections:**

1. **Summary** — the journey; states "mocks present (partner/default)" and "backend LLD contract used".
2. **Data Flow** — screen→partner backend→screen (never screen→Adobe directly).
3. **Change Summary** — overview table + per-file subsections. UI layers: Route, Component, Data Fetch, State, Style, Util.
4. **Design Decisions** — including terminology decisions traced to `shared/`.
5. **Acceptance-Criteria Coverage** — including every mock **state** (loading / active / already-active / cancelled / not-found / error).
6. **Out of Scope**.

**Gate:** DG-4 (see [workflow.md](workflow.md)). Classic failure mode to catch:
the spec says "confirmation modal" but the design emits "navigation to a
confirmation page."

### Edit vs re-run

- **Small fixes** (wrong field name, missing error state) → edit the LLD directly,
  then proceed.
- **Structural problems** (wrong data flow, missing capability) → fix the source
  input first (the service card or the spec), then regenerate the LLD.

Both LLDs share the same filename per feature, disambiguated by the
`backend/` vs `ui/` directory.

---

## 1. Terminology

This kit standardizes on **service card** terminology throughout — skills,
templates, and docs all use "service card."

| Term | Meaning |
|---|---|
| **service card** | The umbrella term for every card the kit produces. |
| **backend service card** | Cards describing a backend/BFF surface. |
| **mobile / web / ios / android service card** | Cards describing a client surface. |
| **shared context** | Cross-surface business context (offer, terminology, scope). |
| **integration context** | Where the Adobe integration state lives in the partner's system. |
| **readiness** | The ✅ / ⚠️ / ❌ status of each integration point per surface. |
| **audit** | Security/integration findings (e.g. direct frontend→Adobe calls). |

When talking to partners you may say **"partner service cards"** for warmth, but
the on-disk structure and all canonical docs use `service-cards/`.

---

## 2. On-disk layout

```text
service-cards/
  backend/
    SERVICE_CARD.md          # entry file: what this backend does / does not do
    MODULE_INDEX.md          # capability → code resolver
    CONTRACTS.md             # inbound HTTP + async contracts this backend exposes
    CONNECTORS.md            # outbound dependencies (incl. Adobe Retail APIs)
    BUILD_CONFIG.md          # runtime, build/verify commands, env-var schema
    PLATFORM.md              # feature flags, caching, datastore
    INTEGRATION_CONTEXT.md   # where Adobe state lives; who owns the integration
    READINESS.md             # per-point ✅/⚠️/❌ integration readiness
  mobile/                    # (or web/ ios/ android/ — same UI template set)
    UI_SERVICE_CARD.md
    UI_MODULE_INDEX.md
    ROUTES.md
    DATA_LAYER.md
    STATE_MANAGEMENT.md
    UI_CODE_PATTERNS.md
    UI_PLATFORM.md
    INTEGRATION_CONTEXT.md
    READINESS.md
  web/    ...                # same UI template set as mobile/
  ios/    ...                # same UI template set as mobile/
  android/ ...               # same UI template set as mobile/
  shared/
    OFFER_PROFILE.md         # offered product, offer_id(s), notify intent
    TERMINOLOGY.md           # partner-facing wording; product-naming rules
    SURFACE_SCOPE.md         # which repos/surfaces are in / out of scope
  security/
    DIRECT_CALLS_AUDIT.md    # direct frontend→Adobe calls + secret-leak findings
```

- **One card set per detected surface.** `backend/` is always produced. A UI
  surface produces a UI card set under its own folder (`mobile/`, `web/`,
  `ios/`, or `android/`). The four UI folders reuse the **same template set** —
  the generator fills them per surface.
- **`mobile` is mutually exclusive with `ios`/`android`.** A single
  cross-platform app populates `mobile/`; separate native repos populate `ios/`
  and/or `android/`.
- **`shared/` is always produced** — the offer/terminology/scope are
  cross-surface facts, not per-surface ones.
- **`security/DIRECT_CALLS_AUDIT.md` is produced only when findings exist.** Its
  presence is a go-live blocker signal.

---

## 3. Card taxonomy — section reference

### 3.1 Backend cards

| File | Purpose | Key sections |
|---|---|---|
| `SERVICE_CARD.md` | Entry point / index. | Frontmatter (`service, owner, status, repo, stack`); What We Do; What We Do Not Do; Contracts summary; Module Index summary; Source Structure; What You Need to Know Before Planning Work Here; Companion Files. |
| `MODULE_INDEX.md` | Capability → code resolver. | Module Taxonomy (layers + forbidden dependency directions); Capability Catalogue (per capability: controller, service, connector, types, validation, call graph); Cross-Reference Indexes; Forbidden / Do-Not-Add rules. |
| `CONTRACTS.md` | Inbound surface this backend exposes. | Overview (base path, auth scheme, **inbound caller auth**, **default authorization**); APIs We Expose (per op: auth, params, request, response, errors); Async Contracts (events consumed/published). |
| `CONNECTORS.md` | Outbound dependencies. | Connector Summary; per-connector details (operations, auth & transport, resilience, error handling, unavailability posture); **Adobe integration connectors** section. |
| `BUILD_CONFIG.md` | Runtime + verification. | Runtime spec; dependency manifest; **Environment-variable schema (reusing the partner's existing names)**; secrets; **Build Interface (authoritative verify commands)**; cross-environment mappings. |
| `PLATFORM.md` | Platform capabilities. | Feature flags; caching; database/datastore engine. |
| `INTEGRATION_CONTEXT.md` | Where the Adobe integration lives. | See §4.2. |
| `READINESS.md` | Integration readiness. | See §4.3. |

### 3.2 UI cards (mobile / web / ios / android)

| File | Purpose | Key sections |
|---|---|---|
| `UI_SERVICE_CARD.md` | Entry point / index. | Frontmatter (`stack, rendering`); What We Do / Do Not Do; Data Contracts (APIs consumed, client-side state); Source Structure; Module Index summary; Companion Files. |
| `UI_MODULE_INDEX.md` | Capability → code resolver. | Module Taxonomy (page/component/data/state/util + forbidden directions); Capability Catalogue; Cross-Reference Indexes. |
| `ROUTES.md` | Route registry. | Router; Route Registry; Auth Guard Pattern; Navigation Patterns; **Deep-link / return-from-Adobe handling**. |
| `DATA_LAYER.md` | How the UI talks to its backend. | Read/Write registries; auth-token injection; error posture; **backend-proxy rule (never call Adobe directly)**. |
| `STATE_MANAGEMENT.md` | Client state. | Stores; init order; **session seed for `partner_reference_id`**; storage key registry. |
| `UI_CODE_PATTERNS.md` | UI conventions the generated screens must follow. | Naming; structure; **existing component library the generated UI must reuse**; form/error patterns; test patterns. |
| `UI_PLATFORM.md` | Runtime/build for this UI. | Runtime; build; env vars; **authoritative verify commands**. |
| `INTEGRATION_CONTEXT.md` | Where the Adobe integration lives for this surface. | See §4.2. |
| `READINESS.md` | Integration readiness. | See §4.3. |

### 3.3 Shared context

| File | Purpose |
|---|---|
| `OFFER_PROFILE.md` | The single source of truth for **what is being offered**. See §4.1. |
| `TERMINOLOGY.md` | Partner-facing wording and product-naming rules. See §4.4. |
| `SURFACE_SCOPE.md` | Which repos/surfaces are active vs out of scope; monorepo vs multi-repo map. See §4.5. |

### 3.4 Security

| File | Purpose |
|---|---|
| `DIRECT_CALLS_AUDIT.md` | Direct frontend→Adobe calls, secret-leakage findings, inbound-auth clarity, notify-registration dependencies. See §4.6. |

---

## 4. The partner-distribution sections (why this kit's cards go beyond a generic service card)

These sections preserve the partner-onboarding rigor that makes this kit
distributable. They are **required** and are read by the feature steps.

### 4.1 `OFFER_PROFILE` (shared)

The authoritative answer to "what are we integrating?" Confirmed **with the
partner**, never assumed.

- **Offered Adobe product** — e.g. Adobe Express, Photoshop, Lightroom, Acrobat
  Pro, Firefly. **Never defaults to Adobe Express.**
- **Offer ID(s)** — the Adobe-assigned `offer_id`(s).
- **Partner terminology** — the partner's own words for *offer* / *benefit* /
  *manage*.
- **Surfaces in scope** — which surfaces this offer appears on.
- **Notify strategy** — whether the partner hosts the Adobe→partner Notify
  webhook, and the registered inbound-auth type.

A missing/placeholder value forces a **STOP-and-ask** before any UI copy is
written.

### 4.2 `INTEGRATION_CONTEXT` (per surface)

Where the integration actually lives in the partner's system.

- Where `partner_reference_id` is stored.
- Where subscription state lives (entity/table/collection).
- Deep-link / return-from-Adobe model.
- Adobe redirect/return assumptions.
- Which backend owns the Adobe integration (in multi-repo setups).
- **UI Rendering** (backend `INTEGRATION_CONTEXT.md` only, SSR/monolithic
  partners only) — which templates/views render the claim / subscription /
  cancel screens and how they read backend state directly, when the UI is
  server-rendered inside this same process/repo (see [Concepts: the three
  partner surfaces](#the-three-partner-surfaces)). Not applicable when a
  separate UI card set exists.

### 4.3 `READINESS` (per surface)

A ✅ / ⚠️ / ❌ status per integration point, with the file path evidencing each.

- IMS client status
- Retail API client status
- Claim flow readiness
- Subscription (find) flow readiness
- Cancel flow readiness
- Notify readiness
- Testing readiness
- Configuration readiness
- Stack confidence (validated vs best-effort)

### 4.4 `TERMINOLOGY` (shared)

- Partner-facing wording (labels, headings, button copy).
- Product-naming rules.
- Explicit rule: **labels must not default to "Adobe Express" unless confirmed**
  in `OFFER_PROFILE.md`.

### 4.5 `SURFACE_SCOPE` (shared)

- Which repos/surfaces are active.
- Which are explicitly out of scope.
- Monorepo vs multi-repo mapping (mirrors `.target-apps`).

### 4.6 `DIRECT_CALLS_AUDIT` (security)

- Direct frontend calls to Adobe (security blockers).
- Secret-leakage checks (IMS credentials in frontend repos).
- Inbound-auth clarity for any partner-hosted endpoint.
- Notify-registration dependencies.

---

## 5. Who reads which card

| Step | Reads |
|---|---|
| `generate-adobe-clients` (Phase 1 + Phase 2) | `backend/` (esp. `BUILD_CONFIG`, `CONNECTORS`, `INTEGRATION_CONTEXT`) |
| `generate-lld` Phase A | `backend/` + `shared/` |
| `generate-lld` Phase B | the UI surface's card set + `shared/` + the backend LLD |
| `implement-*` feature steps | `backend/` + the relevant UI card set + `shared/OFFER_PROFILE.md` + `shared/TERMINOLOGY.md` |
| `verify` | every card's `READINESS.md` + `BUILD_CONFIG`/`UI_PLATFORM` verify commands |
| `generate-integration-checklist` | all cards + `security/DIRECT_CALLS_AUDIT.md` |

Every card set is derived by the **analyze** step (see [workflow.md](workflow.md)).
