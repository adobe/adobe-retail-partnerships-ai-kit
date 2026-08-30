# Claude Code Adapter

> The Claude Code instantiation of the kit's [canonical workflow](../../manual/methodology/workflow.md).
> This adapter carries no methodology — it maps each core stage onto a Claude
> Code slash command. All rules live in [`../../manual/`](../../manual/README.md).

## What this adapter is

Two things at the repo root that let Claude Code run the kit:
[`../../skills/`](../../skills/) (the agent-neutral stage skills) and this
adapter's context file `adapters/claude/CLAUDE.md` (operational guidance Claude
auto-loads). A one-time setup copies them into a gitignored `.claude/`
directory that Claude Code reads.

**Setup lives in one place — [`../../manual/setup/claude-code.md`](../../manual/setup/claude-code.md)** (install + re-sync commands). Run that once, then use the command mapping below.

(Editing `manual/` changes the methodology for every adapter; editing `skills/`
changes only how an agent invokes it.)

## Stage → command mapping

| Canonical stage ([manual/methodology/workflow.md](../../manual/methodology/workflow.md)) | Claude command |
|---|---|
| Analyze → service cards | `/analyze-partner-codebase` |
| Backend clients (Phase 0 design → **review**, then build) | `/generate-adobe-clients` (Phase 1 IMS client, Phase 2 Retail API client) |
| **Backend LLD (DG-3)** | `/generate-lld <feature>` Phase A |
| **UI LLD (DG-4)** | `/generate-lld <feature>` Phase B |
| Implement (per feature) | `/implement-feature <feature>` — `<feature>` ∈ `claim-product`, `find-subscription`, `cancel-subscription`, `notify-handler` |
| Configuration & tests | `/generate-env-config`, `/generate-tests` |
| Verify / audit | `/generate-integration-checklist` |
| Mode B — build app from mocks | `/build-app-from-mocks` |

## Recommended order (Mode A — integrate into existing repos)

Which of these runs is chosen **automatically by target**, not by preference —
see [`../../manual/methodology/workflow.md`](../../manual/methodology/workflow.md#process-depth-by-target-fast-path-vs-full-workflow).

### Fast path — no repo registered (bundled base app)

```text
/implement-feature <feature>                  # cards reused from base-ref-app/service-cards/,
                                               # LLD generated + self-checked, code written,
                                               # env-config/tests/checklist auto-run — one command
```

### Full workflow — a partner repo IS registered

```text
/analyze-partner-codebase                     # → service-cards/  (review: DG-1, DG-2)
/generate-adobe-clients                       # → design → review, then Phase 1 IMS client, Phase 2 Retail API client
# per feature (claim-product, find-subscription, cancel-subscription, notify-handler):
  /generate-lld <feature>                     # → Phase A backend LLD (review: DG-3),
                                               #   Phase B UI LLD      (review: DG-4)
  /implement-feature <feature>                        # → code
/generate-env-config
/generate-tests
/generate-integration-checklist               # → readiness / audit
```

> The `/generate-lld` Phase A → Phase B steps are the explicit design gates,
> with a mandatory human review at each — this sequence is unchanged for
> partner-repo work, where the rigor genuinely matters. Already ran the
> generator skill by hand against the bundled base app? `/implement-feature`
> uses that LLD instead of generating a new one — so the Full workflow's
> gates can be deliberately opted into against the bundled app as well, with
> no flag required.

## Mode B (build app from mocks)

```text
# drop mocks under mocks/<partner>/ (see mocks/README.md), then:
/build-app-from-mocks
/build-app-from-mocks --figma https://figma.com/file/...
```

See [`../../manual/methodology/modes.md`](../../manual/methodology/modes.md).
