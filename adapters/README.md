# Agent Adapters

> The kit's methodology is **agent-neutral** and lives in [`../manual/`](../manual/README.md).
> An *adapter* is the thin layer that lets one specific coding agent invoke the
> canonical [workflow](../manual/methodology/workflow.md) stages. Adapters carry **no
> methodology of their own** — they only map "run stage X" onto that agent's
> command/prompt syntax.

## Why adapters exist

The core layer describes *what* each stage does (analyze → service cards →
backend LLD → UI LLD → implement → verify) and the rules that govern it. It never
says "type this slash command." That separation means:

- the kit can be explained end-to-end without naming any agent;
- a new agent (ChatGPT/Codex, GitHub Copilot, Gemini, …) is added by writing a
  new adapter, without changing core semantics;
- partners on different tooling get the same methodology.

## Available adapters

| Adapter | Status | Location |
|---|---|---|
| **Claude Code** | ✅ Shipped | [`claude/`](claude/README.md) — materialized at the kit's `.claude/` |
| **GitHub Copilot** | ✅ Shipped | [`copilot/`](copilot/README.md) — materialized at the kit's `.github/` |
| Codex / ChatGPT | ◻️ Planned | `codex/` (not yet written) |
| Gemini | ◻️ Planned | `gemini/` (not yet written) |

## What every adapter must map

Each adapter provides one invocation per canonical stage:

| Canonical stage (core) | What the adapter maps it to |
|---|---|
| Analyze | the agent's "scan the target repos and fill `service-cards/`" invocation |
| Service-card review (DG-1/DG-2) | a review prompt/checklist |
| Backend LLD (DG-3) | the "generate backend LLD" invocation |
| UI LLD (DG-4) | the "generate UI LLD" invocation |
| Implement | the "write code from the approved LLDs" invocation |
| Verify | the "run per-surface build/test + report" invocation |
| Mode B (build app from mocks) | the "rebuild UI from mocks" invocation |

An adapter may also provide finer-grained invocations (e.g. per-feature
implement steps) as long as they compose into the stages above.

## Writing a new adapter

1. Create `adapters/<agent>/`.
2. Add a `README.md` with a **mapping table** from each core stage to that
   agent's invocation.
3. Add whatever command/prompt files that agent needs, referencing the methodology
   docs (never restate the rules — link to `../../manual/`).
4. If the agent auto-loads files from a conventional location (as Claude Code
   does with `.claude/`), document how the adapter is materialized there.
