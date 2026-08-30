# Adobe Integration APIs — GitHub Copilot Instructions

<!-- Copied to .github/copilot-instructions.md by manual/setup/copilot.md so GitHub
     Copilot Chat auto-includes it as workspace context. This file carries NO
     methodology of its own — the canonical, agent-neutral methodology lives in
     manual/. Read it first. Paths below are relative to the repository root. -->

You are running the **Adobe Integration APIs — Partner AI Kit**. It is a
standalone tool: this repository (the kit) is opened alongside the partner's
application; the partner application is registered separately and stays clean.
Only generated integration code (and its LLD design documents) is written into the
partner application — the kit's own files are never copied into it.

## Read the methodology first (agent-neutral)

- `manual/methodology/workflow.md` — the stages (analyze → service cards → backend LLD → UI LLD → implement → verify) and gates DG-1..DG-4
- `manual/methodology/card-model.md` — the service-card model and the LLD section contract
- `manual/methodology/modes.md` — Mode A / Mode B and the surface registry / multi-repo resolution
- `manual/methodology/verification.md` — the nine-rule code-generation protocol and the "clarify before you build" gate

## The two hard gates (never skip)

1. **Clarify before you build.** The offered Adobe product is a variable — never
   assume Adobe Express. Derive it from the partner's mocks/code, then ask for
   every gap and confirm (`service-cards/shared/OFFER_PROFILE.md`, or the mock
   `manifest.md`). Rule: `manual/methodology/verification.md` (Clarify before you build).
2. **Verify before reporting.** Never claim success on unverified code. Run each
   surface's own build/test in its own repo before reporting. Rule:
   `manual/methodology/verification.md`.

## Running a stage

Each stage is a skill file at `skills/<name>/SKILL.md` (plain Markdown,
step-by-step). To run a stage, load its skill file as context and follow it
exactly — in Copilot Chat, reference it, for example:

    Follow #file:skills/analyze-partner-codebase/SKILL.md

or, if prompt files are enabled, invoke `/analyze-partner-codebase`.

Resolve target surfaces from `.target-apps` first; if none is registered, the
target defaults to the bundled `base-ref-app/`. If a skill needs service cards
that do not exist, run `analyze-partner-codebase` first.

The stage → skill mapping and recommended order are in `adapters/copilot/README.md`.
