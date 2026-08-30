# UI Code Patterns — mobile (Partner Ref App)

> _Conventions the generated screens on `base-ref-app/lib` MUST follow._

## 1. Naming & Structure

- **File naming:** `snake_case.dart` (e.g. `login_screen.dart`,
  `session_provider.dart`, `app_drawer.dart`).
- **Component/class naming:** `PascalCase` (e.g. `LoginScreen`, `AppDrawer`,
  `SessionNotifier`), `_PascalCase` for private widgets (e.g. `_DrawerBrand`,
  `_DrawerItem` in `app_drawer.dart`).
- **New-screen location:** `lib/features/<feature>/<feature>_screen.dart` (one
  directory per feature, mirroring `features/session/` and `features/home/`) —
  a new claim/subscription/cancel feature should get its own
  `lib/features/claim/`, `lib/features/subscription/` directories, not be
  crammed into `home/`.
- Screens are `ConsumerWidget`/`ConsumerStatefulWidget` (Riverpod), matching
  `HomeScreen`/`LoginScreen`.

## 2. Existing Component Library

> **MANDATORY REUSE.** This app has a very small, genuinely custom widget set —
> no third-party design-system package (no Material design-kit add-on, no
> `flutter_platform_widgets`, etc.). Generated screens must build on Flutter's
> own Material 3 widgets (as the existing screens do) plus these two shared
> widgets:

| Component | Location | Use for |
|---|---|---|
| `AdobeBrand` | `lib/widgets/adobe_brand.dart` | Brand mark + wordmark in app bars / headers (supports `onDark`) |
| `AppDrawer` | `lib/widgets/app_drawer.dart` | App-wide navigation drawer — add new feature entries as `_DrawerItem`s here |
| `FilledButton` (raw Material 3, styled inline) | as used in `login_screen.dart` | Primary actions (see its `FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))` pattern) |
| `TextField` + shared `_inputDecoration()` helper | `login_screen.dart` (currently private to that file) | Form inputs — replicate its rounded-border / filled-white style for new forms rather than inventing a new input style |
| `SnackBar` (Material, themed via `Theme.of(context).colorScheme.error`) | `login_screen.dart` `_submit()` | Error/toast feedback |

- **Design tokens / theme source:** `lib/app.dart`'s `PartnerRefApp.build()` —
  `ColorScheme.fromSeed(seedColor: adobeRed)`, `adobeRed = Color(0xFFEB1000)`,
  `spectrumNegative = Color(0xFFD7373F)` (error color), Material 3
  (`useMaterial3: true`), white app bar with `Color(0xFF1F1F1F)` foreground.
- **Rule:** if a needed component does not exist here, compose from Flutter's
  Material 3 primitives following the existing screens' inline style — do NOT
  pull in an external design system or component package.

## 3. Form Patterns

- Stateful `TextEditingController`s per field, disposed in `dispose()` (see
  `LoginScreen`'s `_userIdController`).
- Submit-button enablement via a computed `_canSubmit` getter (non-empty
  fields + not already loading) rather than a form-validation package — no
  `Form`/`FormField`/validator library is used.
- Loading state: a local `bool _loading` flag toggled around the async call,
  swapping the submit button's child for a `CircularProgressIndicator` while
  `true` and disabling the button.

## 4. Error Handling in Components

- Errors surface via `ScaffoldMessenger.of(context).showSnackBar(...)`,
  colored with `Theme.of(context).colorScheme.error` — not inline error text
  under the field. New integration screens should follow this same
  snackbar-on-failure pattern for consistency, in addition to any
  in-screen state (loading/active/cancelled/etc.) the mocks require.
- No existing "not configured" vs "upstream error" UI distinction exists yet
  (no such call exists) — this must be designed fresh per
  [`DATA_LAYER.md`](./DATA_LAYER.md) → Error Handling Posture.

## 5. Test Patterns

- **Framework:** `flutter_test` (widget/unit tests) — `pubspec.yaml`
  `dev_dependencies.flutter_test`.
- **Component/widget test style:** primarily plain Dart unit tests today (no
  `WidgetTester.pumpWidget` example exists yet in `test/`) — existing tests
  (`test/features/session/session_provider_test.dart`,
  `test/services/auth_service_test.dart`) test Riverpod providers and services
  directly via `ProviderContainer`, not full widget pumps. A new screen's
  widget test would be the first `pumpWidget`-based test in this repo — model
  it on Flutter's standard `testWidgets` pattern since there's no existing
  in-repo precedent to match beyond the provider-level tests.
- **Network mocking:** a hand-written `Fake`-based mock class implementing the
  Dio surface used (see `test/services/auth_service_test.dart`'s `_MockDio
  extends Fake implements Dio`, overriding only `post<T>`) — no `mockito`/`mocktail`
  package dependency exists; follow the same minimal-Fake-override style for
  new service tests.
- **Location / naming:** `test/` mirrors `lib/`'s directory structure
  (`test/features/session/...`, `test/services/...`, `test/models/...`,
  `test/core/...`), file name `<subject>_test.dart`.

## 6. Universal Principles

- Reuse the existing component library (§2) — no new design system.
- Call the partner backend only — never Adobe directly.
- Handle every screen state present in the mock (loading / active / already-active
  / cancelled / not-found / error).
- Ship unit/component tests alongside implementation, following the existing
  `ProviderContainer` + Fake-mock style in §5.
- Match `go_router`'s declarative route style (`ROUTES.md`) and the drawer's
  "one entry per feature" navigation convention — do not introduce a second
  navigation mechanism.
