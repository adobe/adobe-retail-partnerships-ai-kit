---
surface: web
stack: Flutter/Dart (same codebase as mobile)
rendering: Flutter web (compiled from lib/)
repo: base-ref-app/lib (in-kit, bundled — same source as ../mobile/)
status: analyzed
last_updated: 2026-07-16
---

# UI Service Card — web (Partner Ref App)

**Same codebase as [`../mobile/`](../mobile/UI_SERVICE_CARD.md) — all source in
`base-ref-app/lib/`.** `base-ref-app/web/` holds only the Flutter web shell
(`index.html`, `manifest.json`, icons) that `flutter build web` populates; there
is no separate web-only source tree, router, data layer, or component set to
analyze.

Per the analyze skill's Flutter-web shortcut
([`../../../skills/analyze-partner-codebase/SKILL.md`](../../../skills/analyze-partner-codebase/SKILL.md)),
do not re-analyze this surface independently — read
[`../mobile/UI_SERVICE_CARD.md`](../mobile/UI_SERVICE_CARD.md) and its
companion cards (`UI_MODULE_INDEX.md`, `ROUTES.md`, `DATA_LAYER.md`,
`STATE_MANAGEMENT.md`, `UI_CODE_PATTERNS.md`, `UI_PLATFORM.md`,
`INTEGRATION_CONTEXT.md`, `READINESS.md`) for everything about this surface's
routing, data layer, state, and component library — they apply identically to
the web build. The only web-specific facts are the build/serve mechanics below.

## Web-specific build/serve facts

- **Build:** `flutter build web` → static bundle under `build/web/`.
- **Served by:** the BFF (`bff/src/index.ts`) — copies/serves the built bundle
  from its `public/` directory as static files, with an SPA fallback
  (`app.get(/.*/, ...)` → `index.html`) so `go_router` handles client-side
  routing.
- **Runtime config:** same `BFF_BASE_URL` dart-define mechanism as mobile (see
  [`../mobile/UI_PLATFORM.md`](../mobile/UI_PLATFORM.md)); on web,
  `shared_preferences` persistence (session storage) is backed by
  `localStorage`.
