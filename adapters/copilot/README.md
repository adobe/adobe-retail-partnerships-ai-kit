# GitHub Copilot Adapter

> The GitHub Copilot instantiation of the kit's [canonical workflow](../../manual/methodology/workflow.md).
> Like every adapter it carries no methodology of its own — it maps each core
> stage onto a Copilot invocation. All rules live in [`../../manual/`](../../manual/README.md).

## What this adapter is

The kit's skills at [`../../skills/`](../../skills/) are **agent-neutral Markdown —
Copilot runs the exact same skill files Claude Code does.** This adapter adds two
thin pieces so Copilot loads them conveniently, using GitHub's own `.github/`
conventions in place of Claude Code's `.claude/`:

- **`copilot-instructions.md`** — workspace context that GitHub Copilot Chat
  auto-includes (the methodology pointer + the two hard gates), copied to
  `.github/copilot-instructions.md`.
- **Prompt files** *(optional)* — one per skill under `.github/prompts/`, so each
  stage is invokable as a `/command` in Copilot Chat.

**Setup lives in one place — [`../../manual/setup/copilot.md`](../../manual/setup/copilot.md).** Run that once, then use the mapping below.

## Stage → invocation mapping

In Copilot Chat, run a stage by referencing its skill file (or the matching prompt
file). `<feature>` ∈ `claim-product`, `find-subscription`, `cancel-subscription`, `notify-handler`.

| Canonical stage ([workflow.md](../../manual/methodology/workflow.md)) | Copilot Chat invocation |
|---|---|
| Analyze → service cards | `Follow #file:skills/analyze-partner-codebase/SKILL.md` — or `/analyze-partner-codebase` |
| Backend clients (Phase 0 design → **review**, then build) | `#file:skills/generate-adobe-clients/SKILL.md` (Phase 1 IMS client, Phase 2 Retail API client) |
| **Backend LLD (DG-3)** | `#file:skills/generate-lld/SKILL.md` — `<feature>`, Phase A |
| **UI LLD (DG-4)** | `#file:skills/generate-lld/SKILL.md` — `<feature>`, Phase B |
| Implement (per feature) | `#file:skills/implement-feature/SKILL.md` — `<feature>` |
| Configuration & tests | `#file:skills/generate-env-config/SKILL.md`, `#file:skills/generate-tests/SKILL.md` |
| Verify / audit | `#file:skills/generate-integration-checklist/SKILL.md` |
| Mode B — build app from mocks | `#file:skills/build-app-from-mocks/SKILL.md` |

## Recommended order (Mode A — integrate into an existing repository)

Reference each skill in Copilot Chat, in order, reviewing each design gate
(DG-1..DG-4) before proceeding — see [`../../manual/decision-gates.md`](../../manual/decision-gates.md):

```text
analyze-partner-codebase                     → service cards (review: DG-1, DG-2)
generate-adobe-clients                       → design → review, then IMS client + Retail API client
# per feature (claim-product, find-subscription, cancel-subscription, notify-handler):
  generate-lld <feature>                     → backend LLD (DG-3), UI LLD (DG-4)
  implement-feature <feature>                → code
generate-env-config
generate-tests
generate-integration-checklist               → readiness / audit
```

For the bundled base app (no repository registered), reference
`implement-feature` for the feature and Copilot follows the same steps against
`base-ref-app/`. See [`../../manual/methodology/modes.md`](../../manual/methodology/modes.md).

> The same `skills/` directory drives Claude Code and Copilot alike — only the
> loading mechanism differs (`.github/` here, `.claude/` for Claude Code). No
> skill content is duplicated per agent.
