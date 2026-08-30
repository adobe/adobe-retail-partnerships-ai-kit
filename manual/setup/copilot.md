# Setting Up GitHub Copilot

This kit is **coding-agent agnostic**. The skills and methodology live in
root-level directories (`skills/`, `manual/`) with no dependency on any specific
agent. To use the kit with **GitHub Copilot** (in VS Code), run the one-time setup
below to load those directories into GitHub's `.github/` conventions.

The skills are the **same files** Claude Code uses — only the loading mechanism
differs (`.github/` here, `.claude/` for Claude Code).

---

## Prerequisites

- VS Code with the **GitHub Copilot** and **GitHub Copilot Chat** extensions
- This repo cloned locally
- Your target app path(s) registered with the kit — run `./INSTALL.sh <path(s)>`
  (see the [README](../../README.md) → Install). Not needed for Mode B from mocks.
- *(Optional, to invoke skills as `/commands`)* enable prompt files in VS Code:
  set `"chat.promptFiles": true` in your settings.

---

## Setup

Run these from the root of this repo:

```bash
mkdir -p .github

# 1. Workspace context Copilot Chat auto-includes (methodology pointer + hard gates)
cp adapters/copilot/copilot-instructions.md .github/copilot-instructions.md

# 2. (Optional) one prompt file per skill, invokable as /<name> in Copilot Chat
mkdir -p .github/prompts
for d in skills/*/; do n=$(basename "$d"); cp "$d/SKILL.md" ".github/prompts/$n.prompt.md"; done
```

Open the repo in VS Code. Copilot Chat now auto-includes the kit's context, and
each stage is available either **by reference** (`Follow #file:skills/<name>/SKILL.md`)
or, with prompt files enabled, as **`/<name>`**.

---

## Running the workflow

Open Copilot Chat and run the stages in order (full mapping:
[`../../adapters/copilot/README.md`](../../adapters/copilot/README.md)):

1. `Follow #file:skills/analyze-partner-codebase/SKILL.md`
2. `Follow #file:skills/generate-adobe-clients/SKILL.md`
3. Per feature: `#file:skills/generate-lld/SKILL.md` (e.g. `claim-product`), then `#file:skills/implement-feature/SKILL.md`
4. `#file:skills/generate-env-config/SKILL.md`, `generate-tests`, `generate-integration-checklist`

Review each design gate before proceeding — see [decision-gates.md](../decision-gates.md).

---

## Re-syncing after kit updates

If you pull updates to `skills/` or the adapter context, re-copy them:

```bash
cp adapters/copilot/copilot-instructions.md .github/copilot-instructions.md
rm -rf .github/prompts && mkdir -p .github/prompts
for d in skills/*/; do n=$(basename "$d"); cp "$d/SKILL.md" ".github/prompts/$n.prompt.md"; done
```

---

## Using yet another agent

Because the skills and methodology are agent-neutral, any capable coding agent can
run them: point your agent at the `skills/<name>/SKILL.md` files (plain Markdown,
each with step-by-step instructions) and follow the same order. The methodology
every skill relies on is in [`../README.md`](../README.md) → the methodology docs;
read it first, regardless of agent.
