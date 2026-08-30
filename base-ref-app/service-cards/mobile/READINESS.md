# Readiness — mobile (Partner Ref App)

> _Per-point integration readiness for the Flutter surface. This is the
> feature-less base app — every Adobe integration point is genuinely ❌
> today, by design (see [`../README.md`](../README.md))._

## Legend

| Status | Meaning |
|---|---|
| ✅ | Present and validated — evidence file cited. |
| ⚠️ | Partial / best-effort — exists but unverified or incomplete. |
| ❌ | Missing — not yet present on this surface. |

## Status

| Integration point | Status (✅/⚠️/❌) | Evidence (file path) | Notes |
|---|---|---|---|
| Claim flow UI | ❌ | — | Not implemented; `HomeScreen` is a placeholder. |
| Subscription status UI | ❌ | — | Not implemented. |
| Cancel flow UI | ❌ | — | Not implemented. |
| Deep-link handler | ❌ | — | Not implemented; `url_launcher` dep exists but is unused. |
| Component-library reuse | ✅ | `lib/widgets/adobe_brand.dart`, `lib/widgets/app_drawer.dart` | Small but real reusable set — see `UI_CODE_PATTERNS.md` §2. |
| Testing | ✅ | `test/features/session/session_provider_test.dart`, `test/services/auth_service_test.dart`, `test/services/session_storage_test.dart`, `test/models/session_test.dart`, `test/core/jwt_utils_test.dart` | Existing (non-Adobe) surface is well covered. |
| Configuration | ✅ | `dart_defines.example.env`, `lib/core/config.dart` | `BFF_BASE_URL` is the only client config; no Adobe dart-defines exist yet (expected). |
| Stack confidence | ✅ | `pubspec.yaml`, `README.md` | Validated — Flutter is the kit's reference-implementation stack for mobile+web (see kit `README.md` support matrix). |
