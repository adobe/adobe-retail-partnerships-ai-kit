# Reference-App Map — Base Reference App

> ## ⚠️ Every filename, color, and route below is an EXAMPLE — do not grep for them.
> This maps **one specific app** (the base reference app). **Your actual `.ref-source` is very likely a DIFFERENT app** (e.g. `partner-baremetal`) with different filenames, brand colors, and routes — for instance baremetal uses `partner_brand.dart` (not `adobe_brand.dart`), `claim_service.dart` (not `adobe_service.dart`), `claim_screen.dart` (no `express_offer_screen.dart`), a **blue** `brandPrimary` (not `adobeRed`), and holds the offer id only in the BFF (no `AppConfig.expressOfferId`). **So treat this file as a worked illustration of the *token → file* mapping concept only.** The single source of truth for *which files exist in YOUR source app* is the **discovery-based, source-agnostic procedure in `build-app-from-mocks` Step 4** — run it and ignore any name here that doesn't match. Mode B is a **complete UI rebuild driven by the mocks** (navigation, screens, layout, copy) reusing only the Adobe integration logic — **not** a color/logo reskin.
>
> **This is also a PRIOR/legacy reference app, not the currently-bundled `base-ref-app/`.** The screens named below (`claim_express/`, `express_offer_screen.dart`, `rewards_screen.dart`, `find_subscription_screen.dart`, etc.) come from an earlier version of the reference app that already had claim, find-subscription, cancel, and notify fully implemented — kept here purely as a worked illustration of the token → file mapping concept. The reference app bundled with the kit today (`base-ref-app/`) is intentionally **feature-less**: only `home` and `session` features exist (login, session/auth, a bare home shell). None of the claim/subscription/cancel/notify UI described below exists in `base-ref-app/` until Mode A's `implement-feature` skill generates it.

A precise map of the reference app's **themeable surface**: which file controls colors, typography, app name, logo, offer hero, and per-screen copy — and which files are **OFF-LIMITS**. Based on the real structure at the base reference app.

The app is ONE Flutter codebase (`lib/` builds web + iOS + Android) plus a Node/TypeScript Express BFF (`bff/`). The UI rebuild touches only theme, brand widgets, copy, and screen layout. The Adobe integration (IMS token, claim/subscription/notify) lives in `services/`, `models/`, `claim_product/`, and the BFF — all off-limits.

---

## File-to-responsibility map

### Theme (colors, typography, shape)

**`lib/app.dart`** — the single theme authority.
- Two top-level brand constants drive most of the UI:
  - `const adobeRed = Color(0xFFEB1000);` → set to `colors.primary`.
  - `const spectrumNegative = Color(0xFFD7373F);` → set to `colors.error`.
  > These constants are imported across screens (`home_screen.dart`, `rewards_screen.dart`, `express_offer_screen.dart`, `app_drawer.dart`, `adobe_brand.dart`). Renaming them ripples everywhere — keep the names, change the values, and the whole app recolors.
- `ColorScheme.fromSeed(seedColor: adobeRed, …).copyWith(primary, onPrimary, error)` — update seed + overrides from `colors`.
- `MaterialApp.router(title: 'Partner Ref App', …)` → `copy.appTitle`.
- `ThemeData`: `scaffoldBackgroundColor: Color(0xFFFAFAFA)` → `colors.background`; `appBarTheme` (white bg, `0xFF1F1F1F` fg) → derive from `colors.surface`/`onSurface`. Add a `textTheme` built from `typography.scale` here. Keep `useMaterial3: true`.

### App name / package

**`pubspec.yaml`** — `name: partners_ref_app` → `config.appName` (snake_case); `description:` → partner description. Add `flutter: fonts:` (or a `google_fonts` dependency) only if a custom `typography.fontFamily` is used.

**`dart_defines.example.env`** — runtime config template. Copy to `dart_defines.env` and set `BFF_BASE_URL`, `EXPRESS_OFFER_ID`. (See Config below.)

### Logo / wordmark

**`lib/widgets/adobe_brand.dart`** — `AdobeBrand` widget: a red rounded tile with letter "A" + wordmark "Partner Ref App". Used on the **login screen** and **home app bar**.
- Tile `color: adobeRed` and letter `'A'` → partner mark (recolor + change initial, or replace the `Container` with `Image.asset(brand.logo)`).
- Wordmark `'Partner Ref App'` → `brand.wordmark`.

**`lib/widgets/app_drawer.dart`** — `_DrawerBrand` repeats the same tile+wordmark (drawer header). Also holds:
- Drawer item labels: `Home`, `Adobe Express`, `Find Subscription` → `copy` equivalents.
- Footer text `'Partner reference app · stage'` → partner footer.
- The active-item highlight uses `adobeRed` (inherited from theme) — recolors automatically.

### Offer hero / offer mark

**`lib/features/claim_express/express_brand.dart`** — `ExpressLogo`: a gradient rounded tile with letters "Ex" (the Express stand-in mark). Used on `rewards_screen.dart` and `express_offer_screen.dart`.
- Gradient `[#FF3366, #FF6F3C, #D93FB3]` and letters `'Ex'` → partner offer mark (recolor/relabel, or swap to `Image.asset(brand.heroImage)`).

**`lib/features/claim_express/express_offer_screen.dart`** — the `_Hero` widget is the offer-detail hero banner: a 2-stop gradient `[#EB1000, #D93FB3]` with title "Anybody can design" + subtitle. → `colors.heroGradient` + `copy.offer.heroTitle/heroSubtitle`.

### Per-screen copy + layout

| Screen file | Copy strings to replace | Notes |
|---|---|---|
| `lib/features/session/login_screen.dart` | "Sign in", "Enter your partner user ID and password.", field labels `USER ID`/`PASSWORD`, hint `e.g. PARTNER-001`, button "Sign in" | Keep `AuthService.login` wiring + `sessionProvider.signIn` intact. |
| `lib/features/home/home_screen.dart` | "Welcome", "Claim Adobe products…", card titles `Claim Adobe Express` / `Find Subscription`, subtitles, "Coming soon" badge | Keep `context.go('/rewards')` and `context.go('/find-subscription')`. Reuse `_ActionCard`. |
| `lib/features/claim_express/rewards_screen.dart` | "Enjoy your rewards", offer title `Adobe Express Premium`, subtitle `12 months free · worth ₹4000`, chip `Validity: 12 Month`, CTA `Claim Now` | Keep `context.go('/express-offer')`. Reuse `_RewardCard`. |
| `lib/features/claim_express/express_offer_screen.dart` | app bar `Adobe Express`, hero copy, `Adobe Express Premium`, status `Unclaimed`/`12 Month`, section `Your subscription includes`, 3 benefit labels, button `Proceed` | Keep `_proceed()` → `claimProductProvider.submit(...)` and the activation-URL launch logic intact. Reuse `_Hero`/`_StatusCard`/`_BenefitTile`. |
| `lib/features/find_subscription/find_subscription_screen.dart` | app bar `Find Subscription`, `Coming soon`, body text | Placeholder screen; adapt copy/layout freely (no provider wiring yet). |

`lib/core/config.dart` — `AppConfig.bffBaseUrl` (default `http://localhost:8080`) and `AppConfig.expressOfferId` (default `30006514`). Both are `String.fromEnvironment` — editing the defaults is allowed, but prefer setting them via dart-defines. **Do not change the env var names** (`BFF_BASE_URL`, `EXPRESS_OFFER_ID`) — the BFF and CI rely on them.

---

## Config / dart-defines

The app **never** holds IMS credentials or client id — it talks only to the BFF (those live in `bff/.env`). Set only:

```
BFF_BASE_URL=...        # web/iOS sim: http://localhost:8080 ; Android emu: http://10.0.2.2:8080
EXPRESS_OFFER_ID=...
```

Run: `flutter run --dart-define-from-file=dart_defines.env`. Bundle ids (Android `applicationId`, iOS `PRODUCT_BUNDLE_IDENTIFIER`) are placeholders for the partner to finalize.

---

## OFF-LIMITS — never edit (Adobe integration)

| Path | Why |
|---|---|
| `lib/services/adobe_client.dart` | Adobe workflow client interface. |
| `lib/services/adobe_service.dart` | Dio-based Adobe workflow calls (claim/subscription). |
| `lib/services/auth_service.dart` | Partner login → session. |
| `lib/models/*` (`session.dart`, `workflow_response.dart`, `adobe_exception.dart`) | API contract shapes. |
| `lib/features/claim_product/*` (`claim_product_provider.dart`, `claim_product_state.dart`) | Claim state machine + provider. |
| `lib/features/session/session_provider.dart` | Session/auth state. |
| `lib/main.dart` **redirect / auth-guard logic** (NOT the route list) | The signed-in/out redirect the providers depend on. |
| `bff/**` | Entire BFF integration (IMS token, claim/subscription/notify against Adobe). |

**Routes are NOT off-limits** — this defers to the **canonical Routing policy in `build-app-from-mocks` Step 4**: the **route list / paths in `lib/app.dart` may be added to, moved, and deleted** to match the mock (e.g. delete the offer-detail route when the offer goes straight to `experience_url`, add shell/tab routes). What stays fixed is only (a) the **redirect / auth-guard logic** and (b) the **provider/service each surviving screen calls**. When rebuilding a screen, change presentation and route *placement* freely — but never change the providers it reads or the callbacks it fires. If `flutter analyze`/`test` failures trace into `services`/`models`/`*_provider.dart`/`bff`, the rebuild introduced a wiring error elsewhere; fix the rebuild, do not edit those files.
