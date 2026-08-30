# UI Platform — mobile (Partner Ref App)

> _Runtime and build facts for the Flutter surface in `base-ref-app/lib`._

## 1. Runtime

- **Language / SDK:** Dart, Flutter SDK `>=3.4.0 <4.0.0` (`pubspec.yaml` `environment.sdk`)
- **Framework version:** Flutter (channel/version not pinned in `pubspec.yaml`
  beyond the Dart SDK constraint above); key packages: `flutter_riverpod ^3.3.2`,
  `go_router ^17.3.0`, `dio ^5.9.0`, `shared_preferences ^2.5.5`, `url_launcher ^6.3.0`
- **Target(s):** web, iOS, Android — one codebase (`android/`, `ios/`, `web/`
  directories present at `base-ref-app/` root alongside `lib/`). Desktop
  (linux/macos/windows) is explicitly out of scope (`.gitignore` excludes
  those platform dirs).

## 2. Build

- **Build tool:** `flutter` CLI (`flutter build web` / `flutter build apk` / `flutter build ios`, etc. — no custom build script beyond the standard Flutter toolchain)
- **Output artifact:** for web, a static bundle under `build/web/` (served by the BFF from its `public/` dir per `bff/src/index.ts`); for mobile, the standard `.apk`/`.ipa`.

## 3. Environment Variables

- **Client-safe config only.** Confirmed clean — no IMS credentials or
  `*_CLIENT_SECRET` anywhere in `lib/`.

| Variable | Purpose | Source |
|---|---|---|
| `BFF_BASE_URL` | Partner backend base URL | `--dart-define-from-file=dart_defines.env` (see `dart_defines.example.env`); read via `AppConfig.bffBaseUrl` (`lib/core/config.dart`) — defaults to `http://localhost:8080` if unset |

*Notes: Adobe-integration dart-defines (e.g. an offer id shown in UI copy) will
be added by the kit when the integration is generated — none exist yet
(`dart_defines.example.env`'s own comment confirms this).*

## 4. Local Development

- **Install deps:** `flutter pub get`
- **Run:** `cp dart_defines.example.env dart_defines.env` (set `BFF_BASE_URL`
  if needed), then `flutter run -d chrome --dart-define-from-file=dart_defines.env`
  (or `-d <device>` for iOS/Android). Requires the BFF running separately
  (`cd bff && npm run dev`).

## 5. Build Interface (AUTHORITATIVE verify commands)

| Phase | Command |
|---|---|
| Setup | `flutter pub get` |
| Build | `flutter build web` (or platform-specific: `flutter build apk` / `flutter build ios`) |
| Analyze / Typecheck | `flutter analyze` |
| Test | `flutter test` |

## 6. Accessibility

- No explicit accessibility conventions are documented or enforced in this
  codebase beyond Flutter/Material 3 defaults (semantic labels come for free
  from standard widgets like `TextField`, `FilledButton`; no custom
  `Semantics` wrapping observed in `lib/`). Generated screens should rely on
  the same Material 3 defaults rather than inventing new patterns.

## 7. Analytics (optional)

- None. No analytics package or event-emission pattern exists in this
  codebase.
