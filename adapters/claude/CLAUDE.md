# Adobe Integration APIs — Claude Code Adapter Context

This file is the **Claude Code adapter** for the kit — it carries **no methodology
of its own**. The canonical, agent-neutral methodology lives in `manual/`; read it
first. (The setup guide copies this file to `.claude/CLAUDE.md` so Claude Code
auto-loads it — see `manual/setup/claude-code.md`.)

> **Read `manual/` before generating anything:** `manual/methodology/workflow.md` ·
> `manual/methodology/card-model.md` · `manual/methodology/modes.md` · `manual/methodology/verification.md`
>
> This adapter's command mapping is in `adapters/claude/README.md`.

Everything below is Claude/target-app **operational** guidance only. Where it
seems to restate a rule, the authoritative version is in `manual/`.

---

## How this tool operates (target app) — read first

This kit is a **standalone tool**. Claude Code is opened **inside the kit**, not
inside the partner app. The partner app is registered separately and **stays
clean**. Full rules: `manual/methodology/modes.md#surface-registry-and-multi-repo-resolution`.

- **Resolve target surfaces first.** Read `.target-apps` at the kit root
  (`<surface> = <absolute path>` per line; surface ∈ `root`, `backend`, `web`,
  `mobile`, `ios`, `android`; written by `./INSTALL.sh`). A surface's path = its
  own entry else the `root` entry; a surface with neither is skipped. Call the
  resolved paths `$APP_backend`, `$APP_web`, `$APP_mobile`, `$APP_ios`,
  `$APP_android`. `mobile` and `ios`/`android` are mutually exclusive. Legacy: a
  lone `.target-app` file = `root`. If neither exists, tell the user to run
  `./INSTALL.sh <path(s)>` and stop.
- **Generated integration code** is the only thing written into a partner surface
  repo. **LLDs** are written to `$APP_<surface>/docs/ai-kit/LLD/{backend,ui}/`.
- **Service cards** are written **in the kit** at `service-cards/<surface>/`
  (never inside a partner repo). See `service-cards/README.md` and
  `manual/methodology/card-model.md`.
- **Never copy the kit's own `.claude/`, `manual/`, `adapters/`, `knowledgebase/`,
  or `service-cards/` into any `$APP_*`.** Partner repos must stay tool-free.
- "Project root" means: for **generated code**, the relevant `$APP_<surface>`;
  for **service cards**, the **kit root**.

---

## The two hard gates (do not skip)

1. **Clarify before you build — the offered product is a VARIABLE.** Never assume
   Adobe Express. Derive from the partner's mocks / code, then **ASK for every
   gap** and confirm. Source of truth: `service-cards/shared/OFFER_PROFILE.md`
   (Mode A) or the mock `manifest.md` (Mode B). Full rule: `manual/methodology/verification.md#clarify-before-you-build`.

2. **Verify before reporting — never claim success on unverified code.** Every
   code-generating skill MUST follow the nine-rule protocol and run each
   surface's own build/test in its own repo before reporting. Full rule:
   `manual/methodology/verification.md`.

---

## Skills (this adapter)

The stage → skill mapping and recommended order are in
`adapters/claude/README.md`. In brief:

`/analyze-partner-codebase` → `service-cards/`. Then per feature:
`/generate-lld` Phase A (DG-3) → Phase B (DG-4) →
`/implement-feature <feature>`. Backend prerequisites: `/generate-adobe-clients`
(Phase 1 IMS, Phase 2 Retail API). Then `/generate-env-config`, `/generate-tests`,
`/generate-integration-checklist`. Mode B: `/build-app-from-mocks`.

**If a skill needs service cards that don't exist, run
`/analyze-partner-codebase` first.**
