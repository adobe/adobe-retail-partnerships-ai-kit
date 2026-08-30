# Pre-bundled service cards — `base-ref-app/`

These are the kit's **own** service cards for its bundled reference app
(`base-ref-app/bff` + `base-ref-app/lib`), produced by actually running
[`skills/analyze-partner-codebase/SKILL.md`](../../skills/analyze-partner-codebase/SKILL.md)
against this app's current code.

## Why this exists

`base-ref-app/` is fixed and Adobe-controlled — its stack, routes, and
patterns don't change from one Fast-path run to the next the way a real
partner's codebase would. Re-deriving the same cards from scratch on every run
adds nothing but a live re-scan; these cards are committed instead so the
**Fast path** (see
["Process depth by target"](../../manual/methodology/workflow.md#process-depth-by-target) in
`manual/methodology/workflow.md`) can copy them straight into the working `service-cards/`
location and skip straight to design/implementation.

**Ships with the repo — not gitignored.** This is deliberately different from
the per-engagement `service-cards/` at the kit root, which stays gitignored
(re-derivable, per-partner output). These cards describe the kit's own bundled
app, so they are part of the kit itself.

## What's here

- `backend/` — the 8 backend cards for `base-ref-app/bff` (Node 20 / Express 5 + TypeScript).
- `mobile/` — the 9 UI cards for `base-ref-app/lib` (Flutter — one codebase
  compiling to mobile + web).
- `web/UI_SERVICE_CARD.md` — a pointer to `mobile/` (Flutter-web shortcut — same
  codebase, not re-analyzed separately).
- `shared/` — `OFFER_PROFILE.md`, `TERMINOLOGY.md`, `SURFACE_SCOPE.md`.
  `SURFACE_SCOPE.md` is filled concretely (it's a structural fact about the
  bundled app). `OFFER_PROFILE.md`/`TERMINOLOGY.md` are **intentionally left as
  explicit placeholders** — the offered product, `offer_id`, and terminology
  are business decisions only a real partner can supply
  ([`manual/methodology/verification.md`](../../manual/methodology/verification.md#clarify-before-you-build)'s "clarify before you
  build" gate), never something to fabricate just because this is a bundled
  reference app. Downstream skills still STOP and ask before writing any UI
  copy while these remain placeholders — the Fast path changes how much
  process wraps the *design* steps, never this gate.

No `security/DIRECT_CALLS_AUDIT.md` exists here — the analyze run found no
direct-to-Adobe calls or leaked secrets in `base-ref-app/lib` (expected: this
is the feature-less base app; it has no Adobe integration code at all yet).

## How the Fast path uses this

[`skills/implement-feature/SKILL.md`](../../skills/implement-feature/SKILL.md)'s
Fast path and
[`skills/analyze-partner-codebase/SKILL.md`](../../skills/analyze-partner-codebase/SKILL.md)'s
own early-exit step both check: no partner repo registered (`.target-apps` /
`.target-app` absent) **and** this directory exists → copy it into the working
`service-cards/` location and report "Using pre-bundled cards for the base
reference app — skipping full analysis," instead of re-running the full
analyze scan. A real, registered partner repo always gets full live analysis —
this shortcut only applies to the bundled app.

## Keeping these current

If `base-ref-app/bff` or `base-ref-app/lib` changes in a way that would change
what `analyze-partner-codebase` produces (new routes, new auth model, renamed
fields, etc.), re-run that skill against `base-ref-app/` and re-commit the
updated cards here — do not let this drift from the real bundled code.
