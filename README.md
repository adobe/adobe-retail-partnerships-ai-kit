# Adobe Integration APIs — Partner AI Kit

> **A methodology-driven, agent-agnostic kit for integrating Adobe Integration
> APIs into an application** — or rebranding a provided app's UI
> from the partner's design mocks. The kit describes *what* to do and *how*; a
> coding agent (any capable one) drives the steps. It runs **out of the box**
> against a bundled base app — you supply only your Adobe credentials — or
> against your own repos.

Adobe Integration APIs let Telco and retail partners offer an Adobe
product to their subscribers via a claim → manage → cancel subscription
lifecycle. The offered product is set by the partner's Adobe-assigned **offer
ID** and is **product-agnostic** — Adobe Express is only a running example; the
kit never assumes it.

---

## How the kit is organized

```text
skills/         agent-neutral skills — one SKILL.md per workflow stage
manual/         human-facing guide + the canonical, agent-neutral methodology (start here)
service-cards/  the card model: templates + generated per-surface cards
knowledgebase/  source of truth: Adobe API specs, feature specs, patterns, mocks
base-ref-app/   bundled clean, feature-less base app — Mode A's default target
                (runnable Flutter client + Node/Express BFF, no Adobe code yet)
mocks/          partner design mocks (Mode B input)
adapters/       thin per-agent layers that invoke the methodology
  claude/       the Claude Code adapter (skills wired into .claude/ by the setup guide)
  copilot/      the GitHub Copilot adapter (skills wired into .github/ by the setup guide)
```

Everything in `skills/`, `manual/`, `service-cards/`, and `knowledgebase/` is
described without reference to any coding agent, so **any capable LLM/agent can
run the kit**. The methodology is explained fully before any agent is named — see
[`manual/README.md`](manual/README.md). How
a specific agent invokes it lives entirely under [`adapters/`](adapters/README.md);
`.claude/` is generated locally by the setup guide and is not part of the repo.

---

## Surface & stack support

| Surface | Stack | Status |
|---|---|---|
| Backend | Node.js / Express | ✅ Validated (reference implementation) |
| Backend | Spring Boot, FastAPI, Go, Rails, .NET | ⚠️ Best-effort |
| Mobile/Web | Flutter (one codebase → mobile + web) | ✅ Validated |
| Mobile | React Native | ⚠️ Best-effort |
| iOS / Android | Native Swift / Kotlin | ⚠️ Best-effort |
| Web | React / Vue / Angular / Next | ⚠️ Best-effort |

"Best-effort" stacks are detected and generated against your codebase's patterns
but have no reference implementation yet — review generated code carefully.

---

## The canonical workflow

```text
analyze  →  service cards  →  backend LLD  →  UI LLD  →  implement  →  verify
              (DG-1/DG-2)      (DG-3)          (DG-4)
```

The kit merges *what to build* (Adobe's feature specs + API specs in
`knowledgebase/`) with *how to build it here* (the [service cards](manual/methodology/card-model.md)
derived from the partner's code) into reviewable **Low-Level Designs**, approved
at explicit gates (**DG-1..DG-4**) before any code is written, then implemented
and verified per surface. Full detail: [`manual/methodology/workflow.md`](manual/methodology/workflow.md).

The explicit **backend LLD → UI LLD → review** stages give a partner engineer an
approval point before code is written into their repo — increasing trust and
avoiding unsafe generation into unfamiliar repositories.

---

## Two delivery modes

| Mode | When | You provide | You get |
|---|---|---|---|
| **A — Implement the integration** | Add the Adobe features to a codebase | your existing repo(s) — backend / mobile / web / ios / android; or **nothing** — Mode A defaults to the bundled `base-ref-app/` | Adobe integration code written into the target project in its own tech stack |
| **B — Rebrand app from mocks** | Give a partner a branded build (mostly an Adobe-team task) | an app that already has the integration (the Mode A output by default) **+** design **mocks** under `mocks/<partner>/` | the same app with its UI rebuilt to the mocks, reusing the proven Adobe integration |

**Mode A has two process depths, chosen automatically by target.** Against the
bundled base app (nothing registered), `implement-feature <feature>` alone
builds, self-checks, and verifies the whole feature — one command. Against
your own registered repo, the full gated workflow applies — analyze → LLD →
review → implement, unchanged. See
[`manual/methodology/workflow.md`](manual/methodology/workflow.md#process-depth-by-target-fast-path-vs-full-workflow).

Both modes **operate on a provided app path** (neither builds from nothing) — Mode
A defaults its target to the bundled `base-ref-app/`, Mode B to the Mode A output —
run the same workflow, and obey the same security and verification rules. They
compose: Mode A adds features to the base app, then Mode B rebrands that app's UI
from a partner's mocks. Full detail: [`manual/methodology/modes.md`](manual/methodology/modes.md).

---

## The service-card model

Before any code is written, the kit derives one **service-card** set for exactly
the surfaces the partner's app actually has, into `service-cards/`. Backend and
every UI surface are equally first-class targets — a mobile-only partner (no
separate web/backend repo of their own) gets a full, primary-path mobile card
set, not a secondary one:

- **mobile / web / ios / android** — `UI_SERVICE_CARD`, `UI_MODULE_INDEX`,
  `ROUTES`, `DATA_LAYER`, `STATE_MANAGEMENT`, `UI_CODE_PATTERNS`, `UI_PLATFORM`,
  `INTEGRATION_CONTEXT`, `READINESS`
- **backend** — `SERVICE_CARD`, `MODULE_INDEX`, `CONTRACTS`, `CONNECTORS`,
  `BUILD_CONFIG`, `PLATFORM`, `INTEGRATION_CONTEXT`, `READINESS`
- **shared** — `OFFER_PROFILE`, `TERMINOLOGY`, `SURFACE_SCOPE`
- **security** — `DIRECT_CALLS_AUDIT` (only when findings exist)

The `shared/` and `INTEGRATION_CONTEXT`/`READINESS` cards preserve the
partner-onboarding context — the offered product, the partner's own terminology,
where subscription state lives, and per-point readiness. Full detail:
[`manual/methodology/card-model.md`](manual/methodology/card-model.md).

---

## Security & verification (never relaxed)

- **Backend-to-backend only.** All Adobe API calls come from the partner backend;
  IMS credentials never reach frontend code.
- **Multi-repo first-class.** Surfaces may live in one monorepo or separate
  repos; the kit resolves and verifies each independently, and enforces secret
  containment across repos.
- **Nine-rule code-generation protocol.** Env-var-name reuse, cross-repo path
  consistency, config-missing ≠ upstream error, per-surface verify, partner-owned
  inbound auth, and more. See [`manual/methodology/verification.md`](manual/methodology/verification.md).

---

## Prerequisites

- Any capable coding agent (see [Get started with any agent](#get-started-with-any-agent) below).
- Optionally, your existing project checked out locally (whichever surfaces you
  have) — otherwise Mode A runs against the bundled `base-ref-app/`.
- Adobe Integration API credentials from onboarding: `CLIENT_ID`,
  `CLIENT_SECRET`, `SCOPES`, `OFFER_ID`, `X_API_KEY`.

## Install

The kit is a **standalone tool** — you clone it and run it *against* your app.
You do **not** copy it into your app; your app stays clean (only generated
integration code, or the re-derivable Mode B `app/`, ever lands in it).

```bash
git clone https://github.com/adobe/partner-integration-ai-kit.git
cd partner-integration-ai-kit

# Register your app path(s) with the kit — records paths only; modifies nothing.
./INSTALL.sh /path/to/your-app
```

Registering an app is **optional**: with nothing registered, Mode A runs against
the bundled `base-ref-app/` and you supply only your Adobe credentials.

### Multi-repo setup

```bash
# Monorepo
./INSTALL.sh /path/to/your-app

# Separate repos per surface
./INSTALL.sh --backend /path/to/backend --web /path/to/web-app \
             --ios /path/to/ios-app --android /path/to/android-app

# Cross-platform app + separate backend
./INSTALL.sh --backend /path/to/backend --mobile /path/to/app
```

`--mobile` is mutually exclusive with `--ios`/`--android`. Paths are recorded in
`.target-apps`. See [`manual/methodology/modes.md`](manual/methodology/modes.md#surface-registry-and-multi-repo-resolution).

## Add your mocks (Mode B)

`mocks/` is the single mock input location — one folder per partner. Copy
`mocks/_template/` to `mocks/<partner>/`, add screen images, and fill
`manifest.md` (partner, surfaces, pixel-sampled brand colors, journey, screen
map). See `mocks/README.md`.

**After INSTALL → analyze → cards.** Whether you register one repo or several, the next step is always the same: run `/analyze-partner-codebase` in Claude Code. It reads `.target-apps`, scans each registered surface, and writes **one Partner Service Card per surface** into `partner-cards/` (`backend-card.md`, plus `mobile-card.md` / `ios-card.md` / `android-card.md` / `web-card.md` as they exist). Every other skill reads those cards, so this runs first.

---

## Get started with any agent

The steps above are described agent-neutrally in `skills/` and `manual/`, so **any
capable coding agent can run the kit** — Claude Code is only one example. The
generic path:

1. Clone the kit and (optionally) register your app — or rely on the bundled base
   app. See [Install](#install).
2. Read [`manual/`](manual/README.md) first (the methodology every skill enforces).
3. Point your agent at `skills/<name>/SKILL.md` — each is plain Markdown with a
   `name`/`description` header and numbered steps — and run them in the order in
   [`manual/methodology/workflow.md`](manual/methodology/workflow.md).

| Agent | Status | How to run |
|---|---|---|
| **Any capable agent** | ✅ Usable | Point it at `skills/<name>/SKILL.md` (plain Markdown, step-by-step) and follow the [workflow order](manual/methodology/workflow.md); read [`manual/`](manual/README.md) first. |
| **Claude Code** (example) | ✅ Shipped | One-time setup wires `skills/` into `.claude/` as slash commands — see [`manual/setup/claude-code.md`](manual/setup/claude-code.md). Mapping: [`adapters/claude/README.md`](adapters/claude/README.md). |
| Codex / ChatGPT, Copilot, Gemini adapters | ◻️ Planned | Dedicated adapters — see [`adapters/README.md`](adapters/README.md) for the contract. |

### Example: Claude Code commands (Mode A)

**Fast path (bundled base app, nothing registered) — one command:**

```text
/implement-feature <feature>              # → cards reused, LLD generated + self-checked, code, env-config/tests/checklist — all in one
```

**Full workflow (your own registered repo) — unchanged, gated:**

```text
/analyze-partner-codebase                 # → service-cards/  (review DG-1/DG-2)
# per feature:
  /generate-lld <feature>                 # → Phase A backend LLD (review DG-3),
                                           #   Phase B UI LLD      (review DG-4)
  /implement-feature <feature>                    # → code
/generate-env-config  /generate-tests  /generate-integration-checklist
```

**Claude Code quick path (Mode B):** `/build-app-from-mocks`.

Full command mapping: [`adapters/claude/README.md`](adapters/claude/README.md).

---

## Reference implementation

The kit bundles a clean, feature-less **base reference app** at
[`base-ref-app/`](base-ref-app/README.md) — `lib/` (Flutter — one codebase
compiled to web + iOS + Android) plus `bff/` (Node.js / TypeScript Express
backend-for-frontend), with **no Adobe integration yet**. Mode A runs onto it by
default, so you can see every integration point built end-to-end supplying only
your credentials. In this app the mobile and web surfaces are the **same Flutter
codebase**; a real partner may instead have separate apps — the analyze step cards
whatever exists.

Pre-approved reference artifacts (Adobe API specs, feature specs, and default
screen mocks) live in [`knowledgebase/`](knowledgebase/).

---

## Documentation map

- [`manual/README.md`](manual/README.md) — the guide-map + the methodology (read first)
- [`service-cards/README.md`](service-cards/README.md) — the card model
- [`adapters/README.md`](adapters/README.md) — the adapter model

## Support

- Questions and bugs: open an issue on this repository.
- Please read the [Disclaimer](DISCLAIMER.md) before using the kit.
