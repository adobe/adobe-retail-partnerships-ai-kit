# Setting Up Claude Code

This kit is **coding-agent agnostic**. The skills and methodology live in
root-level directories (`skills/`, `manual/`) with no dependency on any specific
LLM or agent. To use the kit with **Claude Code**, run the one-time setup below
to wire those directories into Claude Code's expected `.claude/` structure.

---

## Prerequisites

- [Claude Code](https://claude.ai/code) installed
- This repo cloned locally
- Your target app path(s) registered with the kit — run `./INSTALL.sh <path(s)>`
  (see the [README](../../README.md) → Install). Not needed for Mode B from mocks.

---

## Setup

Run these from the root of this repo:

```bash
# 1. Create the .claude directory
mkdir -p .claude

# 2. Copy the agent-neutral skills in as Claude Code skills
cp -r skills .claude/skills

# 3. Copy the Claude adapter context (auto-loaded by Claude Code)
cp adapters/claude/CLAUDE.md .claude/CLAUDE.md

# 4. Start Claude Code in the kit root
claude
```

Claude Code now exposes each skill as a slash command (e.g.
`/analyze-partner-codebase`, `/implement-feature <feature>`). The recommended
run order and the full stage → skill mapping are in
[`adapters/claude/README.md`](../../adapters/claude/README.md).

---

## Re-syncing after kit updates

If you pull updates to `skills/` or the adapter context, re-copy them:

```bash
rm -rf .claude/skills && cp -r skills .claude/skills
cp adapters/claude/CLAUDE.md .claude/CLAUDE.md
```

---

## Using a different agent

Because the skills and methodology are agent-neutral, any capable coding agent
can run them: point your agent at the `skills/<name>/SKILL.md` files (they are
plain Markdown, each with a `name`/`description` header and step-by-step
instructions) and follow the same order. The methodology every skill relies on
is in [`manual/`](../../manual/README.md); read it first, regardless of agent.
