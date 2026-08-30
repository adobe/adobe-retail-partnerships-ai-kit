# Adobe Integration APIs — Partner AI Kit — Manual

This manual is the human-facing guide to using the kit. It is **agent-agnostic**:
the workflow, methodology, and skills work with any capable coding agent. A specific
coding agent is named only in the setup step.

---

## 1. Set up your agent

Wire the kit's agent-neutral `skills/` into your coding agent:

| Agent | Setup guide |
|---|---|
| Claude Code | [setup/claude-code.md](setup/claude-code.md) |
| GitHub Copilot | [setup/copilot.md](setup/copilot.md) |
| Any other agent | Point it at `skills/<name>/SKILL.md` and follow the same order — see the note at the bottom of either setup guide. |

---

## 2. Start here

| Guide | Read when |
|---|---|
| [conceptual-guide.md](conceptual-guide.md) | **First — everyone.** The mental model: what the kit is, Adobe-provides vs you-do, the offer variable, the security invariant, the two modes. |
| [quick-start.md](quick-start.md) | You're ready to run it end-to-end (Mode A and Mode B paths). |
| [decision-gates.md](decision-gates.md) | What to review and approve at each Decision Gate (DG-1..DG-4; "DG" = Decision Gate). |
| [reference.md](reference.md) | Quick-lookup: skills, file paths, credentials, common gotchas. |

---

## 3. The methodology

Whatever your role or agent, read these before generating anything. This is the
authoritative, agent-neutral methodology the skills enforce. It's described
without reference to any specific coding agent; how a particular agent (for
example, Claude Code) invokes these steps lives in [`adapters/`](../adapters/README.md).

The four methodology docs live under [`methodology/`](methodology/). Read them in
order:

| # | Doc | What it covers |
|---|---|---|
| 1 | [methodology/workflow.md](methodology/workflow.md) | The stages: analyze → cards → backend LLD → UI LLD → implement → verify, with gates DG-1..DG-4 |
| 2 | [methodology/card-model.md](methodology/card-model.md) | The service-card taxonomy; core concepts (surfaces, the Adobe APIs, the security invariant); the LLD section contract |
| 3 | [methodology/modes.md](methodology/modes.md) | Mode A (implement the integration; defaults to the bundled base app) and Mode B (rebrand a provided app from mocks); the surface registry and cross-repo resolution |
| 4 | [methodology/verification.md](methodology/verification.md) | The nine-rule code-generation protocol; the interactive model (the offered product is a variable) |

Supporting source-of-truth material (not duplicated here):

- [`../knowledgebase/api-spec/`](../knowledgebase/api-spec/) — Adobe endpoint contracts.
- [`../knowledgebase/feature-specs/`](../knowledgebase/feature-specs/) — per-feature behavior.
- [`../knowledgebase/integration-patterns/`](../knowledgebase/integration-patterns/) — reusable patterns.
- [`../service-cards/_templates/`](../service-cards/_templates/) — the card templates the analyze step fills.

---

## 4. How a feature gets built

**Against the kit's bundled base app, the entire build is one command:**

```text
implement-feature claim-product
```

That one command reuses the base app's service cards, designs the backend and UI,
writes the code, tests it, and self-checks the result. It's the most direct way
to evaluate the kit, and the best path to demo live.

**Against your own repo, the same work runs as a reviewed, step-by-step flow** —
this is where the gates matter, because code is about to be written into a
production codebase:

```text
analyze  →  service cards          →  review DG-1 / DG-2   (did the kit understand your code?)
         →  generate Adobe clients  →  review the design    (IMS token + Retail API client, once)
  per feature:
         →  generate LLD            →  review DG-3 (backend design) · DG-4 (UI design)
         →  implement               →  code, wired across repos + verified
         →  env config · tests · integration checklist
```

You approve each **DG** gate before the next stage runs — an early mistake is
cheapest to catch in a design document, not in generated code. The exact
skill-by-skill mapping for Claude Code is in
[`adapters/claude/README.md`](../adapters/claude/README.md); the gates are
explained in [decision-gates.md](decision-gates.md).

---

## 5. Two ways to start

- **Mode A — implement the integration.** Run analyze → LLD → implement per
  feature. By default the target is the bundled base app
  ([`base-ref-app/`](../base-ref-app/README.md)), so it runs out of the box with
  only your credentials — or register your own repo(s) with `./INSTALL.sh` to
  target them. Adobe integration code is written into the target project in its own
  stack; the kit's own files never land in it.
- **Mode B — rebrand an app from mocks.** Drop design mocks under
  `mocks/<partner>/` (see [`mocks/README.md`](../mocks/README.md)) and run the
  build-app skill. The kit rebuilds the partner-facing UI of a **provided app that
  already has the integration** (the Mode A output by default) to those mocks,
  reusing the proven Adobe integration untouched.

See [methodology/modes.md](methodology/modes.md) for the full details.
