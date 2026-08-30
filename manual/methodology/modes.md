# Delivery Modes

> Agent-neutral. Both modes run against a **provided app path + code** — neither
> builds from nothing. Both obey the same [verification protocol](verification.md)
> and security rules. They differ in *what they change* in the target app.

The two modes compose. A typical end-to-end path:

1. **Mode A** implements the Adobe features into a **feature-less base reference
   app** (or any partner codebase) → an app that now has claim / subscription /
   cancel / notify working.
2. **Mode B** takes that app (or any app with the integration) **plus a partner's
   design mocks** and rebrands its UI to the partner's look-and-feel → a
   partner-branded build (e.g. an APK) to hand over.

Either can run alone, and mocks may also be supplied *during* a Mode A run so
features and branding land together. **Any combination is valid — but a target
app path is always required.**

---

## Surface Registry and Multi-Repo Resolution

> Agent-neutral. The kit supports a partner whose surfaces live in one monorepo
> **or** several separate repositories, without ever modifying the partner repos.

### The surface registry

The kit is a **standalone tool**. The agent runs **inside the kit**, not inside
the partner app. Partner app paths are recorded in a registry file at the kit
root (`.target-apps`), one `<surface> = <absolute path>` per line, where surface
∈ `root`, `backend`, `web`, `mobile`, `ios`, `android`. It is written by the
install step (`./INSTALL.sh`) and records paths only — it never copies anything
into a partner repo.

### Resolution rules

- **A surface's path** = its own entry if present, else the `root` entry. A
  surface with neither is **not present** — skip it.
- Resolved paths are referred to as `$APP_backend`, `$APP_web`, `$APP_mobile`,
  `$APP_ios`, `$APP_android`.
- `mobile` (one cross-platform app) and `ios`/`android` (native apps) are
  **mutually exclusive**.
- **Legacy fallback:** if `.target-apps` is absent but an old `.target-app`
  exists, treat its single path as `root`.

### Multi-repo implications

- **Path consistency across repos** (verification rule 2): when client and server
  live in separate repos there is no shared compile step, so a wrong path ships as
  a silent 404 — grep the literal in each repo and confirm equality.
- **Per-surface verify** (rule 5): run each surface's own build/typecheck in its
  own repo; do not assume one typecheck covers all.
- **Secret containment** (rule 9): IMS/`*_CLIENT_SECRET` config appears only in
  `$APP_backend`; grep frontend repos and fail loudly on any leak.
- **Native cards**: separate `ios`/`android` repos produce `service-cards/ios/`
  and/or `service-cards/android/` instead of `service-cards/mobile/`.

`service-cards/shared/SURFACE_SCOPE.md` records the active/out-of-scope map and
mirrors the registry.

---

## Mode A — Implement the integration into a codebase

**What it does:** writes the Adobe integration (claim → manage → cancel →
notify) into a **provided** codebase, in that codebase's own stack, following its
own patterns. This is the mode the six [workflow](workflow.md) stages
(analyze → service cards → backend LLD → UI LLD → implement → verify) describe
directly.

**Input:** the partner's (or the base reference app's) existing repo(s) — backend
/ web / mobile / ios / android — registered via the [surface registry](#surface-registry-and-multi-repo-resolution).
**Output:** Adobe integration code written into those repos.

**Target resolution (defaults to the bundled base app):** if a surface is
registered (`.target-apps` / `.target-app`), use it. **If nothing is registered,
default the target to the kit's bundled feature-less base app at `base-ref-app/`**
(build the integration onto it **in place** — `base-ref-app/` is git-committed, so
`git checkout base-ref-app/` restores the feature-less baseline afterward) — the
partner then supplies only their Adobe credentials. Only if `base-ref-app/` is somehow absent does the
run stop and ask for `./INSTALL.sh <path(s)>`. Mode A never generates into a
vacuum — it builds onto the bundled base app or a partner-provided repo.

### Process depth by target: Fast path vs Full workflow

This same target-resolution split also decides **how much process wraps** the
six workflow stages: no registered repo (target = bundled `base-ref-app/`)
runs a single-command **Fast path**; a registered partner repo runs the
**Full workflow**, unchanged, with a mandatory human review at every DG gate.
This is a process-depth difference only — verification, the offer-clarify
gate, and every other security/correctness invariant apply identically to
both. Full detail: [workflow.md § Process depth by
target](workflow.md#process-depth-by-target-fast-path-vs-full-workflow).

## Mode B — Rebrand an app's UI from mocks

**What it does:** takes a **provided app that already carries the integration**
(the base reference app after Mode A, or a partner app) and **rebuilds its
partner-facing UI to the partner's design mocks**, reusing the app's proven Adobe
integration untouched. Primarily an **Adobe-team** tool: rebrand a reference app's
UI with a partner's mocks and hand the partner a branded build (e.g. an APK).

**Input:** (a) a **target app path** to rebrand — a local app via `.ref-source`
(or a registered target), **required**; and (b) design **mocks** (Figma link, PDF,
images, or a slide deck) + a short manifest under `mocks/<partner>/`.
**Output:** the same app, its UI rebuilt to the mocks, its Adobe integration
reused verbatim.

**Target resolution (defaults to the integrated app):** resolve the app to rebrand
in this order — (1) an explicit `.ref-source`; (2) the app Mode A just built the
integration into — the bundled `base-ref-app/` after a fast-path run, or your
registered repo — when it already carries the integration; (3) a registered target
app. If none resolves, the run **stops** and asks for the path to an app that
already carries the integration — it does **not** scaffold an app from nothing
(run Mode A first).

Core principle: **rebuild the UI to the mocks; reuse ONLY the Adobe integration
(untouched, proven).** The integration logic is referenced read-only and never
edited.

Mock handling:

- `mocks/<partner>/` (one folder per partner, required `manifest.md`) is the
  authoritative screen spec.
- Colors are **pixel-sampled**, never eyeballed.
- The journey is ordered; Adobe-hosted screens are never rebuilt.
- Fidelity is **mandatory** (~90–100%), verified with render/golden checks + a
  per-screen scorecard. The #1 defect is ignoring the mocks and shipping a
  generic screen.
- The offer is woven into the partner's own section using the partner's
  terminology (from `shared/OFFER_PROFILE.md` / `shared/TERMINOLOGY.md`), never a
  generic "Adobe" block, and never assuming Adobe Express.
- Fallback: if neither a partner mock nor a default exists for a feature, generate
  clean UI using the target app's existing component library — never an external
  design system.

The kit ships **default screen specs** at
`knowledgebase/ui-mocks/defaults/FS-00X-*/` (one spec per screen **state**) used
as the fallback when no partner mock exists.

> **Default mocks are drawn as mobile (portrait phone) frames.** They define the
> **states, copy, and component structure** — not a fixed pixel width. On a **web
> or desktop** surface, treat them as the state/copy spec and **reflow** the layout
> to the web breakpoint (constrain content to a centered max-width; full-bleed
> hero/footer where the partner's chrome calls for it) rather than shipping a
> phone-width column on desktop. The state set and terminology carry over verbatim;
> only the framing adapts.

## Shared guarantees (both modes)

- **Neither mode builds from nothing** — there is always a target app. Mode A
  defaults to the bundled `base-ref-app/` (else a registered repo); Mode B defaults
  to the app Mode A built into (`base-ref-app/` after a fast-path run, else
  `.ref-source`/a registered app). A partner may
  always point either mode at their own repo instead.
- The target repo stays clean — only generated integration code (Mode A) or the
  re-derived branded build (Mode B) is produced; the kit's own files never land in
  a target repo.
- Multi-repo is first-class (see [Surface Registry and Multi-Repo
  Resolution](#surface-registry-and-multi-repo-resolution) above).
- Security and env-var rigor are identical (see [verification.md](verification.md)).
- The offer is a variable and is confirmed with the partner (see
  [verification.md#clarify-before-you-build](verification.md#clarify-before-you-build)).
