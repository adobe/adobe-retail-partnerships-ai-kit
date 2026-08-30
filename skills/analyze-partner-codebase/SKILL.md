---
name: analyze-partner-codebase
description: >
  Analyze the partner's existing codebase across all detected surfaces and write service cards into service-cards/ — one per-surface card set (backend/, plus a UI set in mobile/, web/, ios/, or android/), always the shared context in shared/, and a security/DIRECT_CALLS_AUDIT.md where applicable. Run this first, before any other skill.
---

# Skill: /analyze-partner-codebase

*New to this kit? Read [`manual/conceptual-guide.md`](../../manual/conceptual-guide.md) and [`manual/quick-start.md`](../../manual/quick-start.md) first — they explain the mental model this skill assumes.*

Analyze the partner's existing codebase across all detected surfaces and write **service cards** (a durable, machine-readable description of one surface of your app — see [`manual/methodology/card-model.md`](../../manual/methodology/card-model.md) for the full model) into `service-cards/` — one per-surface card set (`backend/`, plus a UI set in `mobile/`, `web/`, `ios/`, or `android/`), always the shared context in `shared/`, and a `security/DIRECT_CALLS_AUDIT.md` where applicable. The card taxonomy is defined in [`../../manual/methodology/card-model.md`](../../manual/methodology/card-model.md); the blank templates live in `service-cards/_templates/`.

**Run this first before any other skill.**

---

## Instructions

You are analyzing a partner developer's existing codebase to understand their architecture.

**First resolve the target surfaces:** read the `.target-apps` registry at the kit root and resolve `$APP_backend`, `$APP_web`, `$APP_mobile`, `$APP_ios`, `$APP_android` per the rule in manual/methodology/modes.md / [`../../manual/methodology/modes.md`](../../manual/methodology/modes.md#surface-registry-and-multi-repo-resolution) (a surface = its own entry, else `root`; absent surfaces are skipped). If neither `.target-apps` nor a legacy `.target-app` exists, **default the target to the kit's bundled feature-less base app at `base-ref-app/`** (Mode A's default — analyze `base-ref-app/` in place; the partner supplies only their Adobe credentials later). Only if `base-ref-app/` is also absent, tell the user to run `./INSTALL.sh <path(s)>` from the kit and stop. A partner may always register their own repo(s) to target instead. **Scan each resolved surface in its own repo.** Write the card sets into `service-cards/` **at the kit root** (never inside a partner repo, which must stay clean) — copy the matching template set from `service-cards/_templates/` into the surface folder, then fill it (see Step 8). When `root` resolves multiple surfaces to one path (monorepo), scan its subprojects as in Step 1.

### Step 0 — Fast path shortcut: reuse the pre-bundled cards (bundled base app only)

**Before running Step 1, check whether this run even needs a live scan.** If
**no partner repo is registered** (`.target-apps`/`.target-app` absent — the
target has defaulted to `base-ref-app/` above) **and**
[`base-ref-app/service-cards/`](../../base-ref-app/service-cards/README.md)
already exists, **copy that directory's contents into the working
`service-cards/` location** (backend/, mobile/, web/, shared/) instead of
re-scanning the code, and report: *"Using pre-bundled cards for the base
reference app — skipping full analysis."* Skip straight to Step 9 with those
copied cards. This is the Fast path described in
[`../../manual/methodology/workflow.md`](../../manual/methodology/workflow.md#process-depth-by-target-fast-path-vs-full-workflow)
— `base-ref-app/` is fixed and Adobe-controlled, so its cards don't need live
re-derivation on every run.

**A real, registered partner repo always gets the full live analysis below —
this shortcut never applies to one.** Steps 1–9 are unchanged and still the
only path for any registered surface (or if `base-ref-app/service-cards/` is
itself somehow missing, in which case fall through to Step 1 and analyze
`base-ref-app/` for real, as this skill originally did to produce that
pre-bundled set).

### Step 1 — Detect Surfaces

Scan the project root **and common subproject directories (depth ≤ 2)** for each surface — e.g. `bff/`, `backend/`, `server/`, `api/`, `services/*`, `apps/*`, `packages/*`. A marker file (`package.json`, `pom.xml`, `build.gradle`, `pubspec.yaml`, `go.mod`, …) found in **any** of these defines a surface rooted at **that directory**, not just the repo root. Record each surface's directory — the deep dives in Steps 2–4 operate inside it. Look for these markers:

**Backend service:**
- `package.json` + `express`, `fastify`, `koa`, or **`@nestjs/*`** (Nest) → Node.js
- `pom.xml` + `spring-boot` → Java Spring Boot
- `build.gradle` + `spring-boot` → Java Spring Boot (Gradle)
- Python: `requirements.txt`/`pyproject.toml` + `fastapi`/`flask`, **or `django`/`djangorestframework`/`graphene`/`strawberry`/`ariadne`** (a `manage.py`, `settings.py`, or `urls.py` is a strong Django signal — a GraphQL-only API is still a backend)
- `go.mod` → Go (router is usually chi / gin / echo / stdlib `net/http`; config via INI (`app.ini`) / Viper / env)
- `Gemfile` **or a `*.gemspec` declaring `rails`/`railties`**, or a `config/routes.rb` at any depth → Ruby on Rails (a JS-only root `package.json` does **not** rule out a Rails backend nested in a monorepo — Spree keeps `rails` in `*/​*.gemspec`, not a root Gemfile)
- `*.csproj`/`*.sln` + `Microsoft.NET.Sdk.Web` / `Microsoft.AspNetCore.*` → **.NET / ASP.NET Core** (minimal APIs or MVC)

> **Do not conclude "no backend" just because the framework isn't in this list.** These are common markers, not the whole universe (heavy real apps use NestJS, Django+GraphQL, .NET, Micronaut, Quarkus, etc.). Any package that serves HTTP/GraphQL is a backend surface — record the actual framework you find.

> **Monorepo / nested backends:** the backend is frequently NOT at the repo root (e.g. this kit's reference app keeps its Express backend in `bff/`, while the root holds only `pubspec.yaml`). Search recursively (excluding `node_modules`, `build`, `.git`, `.dart_tool`) for any `package.json` whose dependencies include `express`/`fastify`/`koa`/`nest`, any `pom.xml`/`build.gradle` with `spring-boot`, any `*.gemspec`/`config/routes.rb` (Rails), or any `*.csproj` (.NET), and treat the **containing directory** as the backend surface. **Never conclude "no backend" from a root-only scan.**

> **Multi-SERVICE backend (microservices):** a backend surface may contain **many services** (e.g. a Spring Cloud or .NET microservices repo with `account-service`, `ordering`, `webhooks`, …). Do **not** assume one service, and do **not** assume a service *named* `*webhook*`/`*notify*` is the Adobe receiver — inspect what it does (many "webhooks" services manage the partner's *own outbound* webhooks and are user-scoped). Identify the service that owns **subscription / order / account** state as the integration host; record the candidate services and, if ambiguous, **STOP and ask the partner** (rule 8). Note the API-gateway route that fronts the chosen service (the external path may be defined there, not in the service).

> **Multi-APP mobile / workspace parents:** if a registered mobile/`ios`/`android` root is a **workspace parent** (e.g. a Flutter/Dart `pubspec.yaml` with a `workspace:` list and no `lib/`, or a repo of many sample apps), it is not itself a runnable app. Enumerate the member apps (those with a real `lib/` + `android/ios/web`) and **STOP and ask the partner which app is the integration target** (rule 8) — do not card the meta-manifest or arbitrarily pick one.

**Mobile / App:**
- `pubspec.yaml` → Flutter
- `package.json` + `react-native` → React Native
- `ios/` directory + Swift files → iOS native
- `android/` directory + Kotlin files → Android native

**Web / Webapp:**
- `package.json` + `react` → React
- `package.json` + `vue` or `nuxt` → Vue/Nuxt
- `package.json` + `next` → Next.js
- `package.json` + `angular` → Angular
- `pubspec.yaml` + a `web/` directory → **Flutter web** (the *same* codebase as the Flutter mobile surface, compiled to web — not a separate app)

**Adobe SDK (any of the following):**
- `@adobe/cceverywhere` or `@adobe/express-embed-sdk` in package.json → Express Embed SDK
- `AdobeCreativeSDK` in Podfile or build.gradle → Creative SDK
- Any import of `adobe` SDK packages in source files

### Step 2 — Backend Deep Dive

Read key backend files to understand:
- **HTTP client library** — how outbound HTTP calls are made (axios, fetch, WebClient, requests, http.Client). A framework's core package may bundle **none** — record "none in core; SDKs / native fetch used in plugins/services" rather than forcing a match. **For Node backends specifically:** check `package.json` for `axios`, `got`, `node-fetch`, `undici`. If none are present, check the Node version (`engines.node` in package.json) — Node ≥18 has native `fetch` globally; if the app targets Node ≥18 and no HTTP client dep is listed, generated code may use native `fetch` without adding a dependency. Record which is appropriate and if no outbound calls exist yet, state "none yet — native fetch available (Node 20+)" rather than silently omitting the field.
- **Existing auth middleware** — where user auth is validated on incoming requests
- **Inbound caller auth (external system — NOT end user)** — how (or whether) the codebase authenticates an *external system* calling its endpoints. **Critically distinguish this from end-user auth:** a login/session token, member/admin JWT, or **per-user** API key authenticates a *human/account* — a third party like Adobe cannot obtain or replay it, so it is **NOT** an external-caller mechanism and must not be mapped to a Notify auth type. Recognized external-caller shapes: a static shared secret / API key compared against config; an **opaque bearer token / API key / PAT verified against a datastore (often hashed)**; OAuth/JWT issuer+JWKS validation for a *machine* client; mTLS; an API-gateway key. **Record the exact verification path** (config-equality vs datastore/hash lookup vs JWKS/introspection) — it changes how the notify handler validates. If several auth paths exist, pick the one for **machine/app callers**, not the human-login path. **Negative example (frequent trap):** a Git-host **personal-access token**, a member/admin **JWT**, or a **user OAuth grant** that resolves to a *user account* is end-user auth **even though it's a bearer token** — do NOT map it to a Notify type; if that's all the codebase has, record UNCLEAR. **Trace the actual resolver** (the dataloader/service/filter that verifies the credential — e.g. an `AppByTokenLoader`, an `ApiKey.find_by_secret_token`, a scrypt/HMAC datastore lookup), not just the outermost middleware, because the machine path is often a *different* resolver than the visible user-login one. If the backend exposes **multiple OAuth2 grant types**, record BOTH (the end-user `password`/`authorization_code` grant AND the machine `client_credentials` grant) and name which one a caller like Adobe would use. If the only inbound auth is end-user/session-scoped, or there is no external-caller mechanism at all, record **UNCLEAR — must ask partner** so the notify skill asks rather than inventing a secret or misusing the user-login filter.
- **Default request authorization / security chain** — does the framework **deny unauthenticated requests by default**? Read the security config (Spring Security `SecurityFilterChain`/`authorizeHttpRequests`, a NestJS global `APP_GUARD`, DRF `DEFAULT_PERMISSION_CLASSES`, or a globally-mounted Express auth middleware). Record the **default rule** (`anyRequest().authenticated()` vs `permitAll`), the **filter/guard order**, and any **URL allow-list mechanism** (`permitAll` matchers, `secure.ignored.urls`, a `@Public`/`@Allow(Public)` decorator). A newly added inbound endpoint **inherits the default rule**, so the notify skill must permit its path through the chain. In multi-module/monorepo projects, resolve which security beans actually load in the **target module** (`@ConditionalOnBean`, active profiles) — the shared security module's full behavior may not apply.
- **Config loading** — how config/secrets are accessed: dotenv, Spring `application.yml` + `@Value`/`@ConfigurationProperties`, `os.environ`, INI (`app.ini`) / Viper (Go), Rails `credentials` + `ENV`, or a **typed config object** the app constructs (e.g. a `VendureConfig`/framework config passed at bootstrap). Record the actual mechanism — new config keys must be added in that form, not assumed to be a `.env`.
- **Error handling** — how errors are propagated (try/catch patterns, global error handler, middleware)
- **Logging** — which logger is used and how it's called (console.log, SLF4J, structlog, slog)
- **Test framework** — Jest, JUnit5, pytest, testing package
- **Package/module structure** — where new services/controllers should be placed
- **Existing Adobe/IMS specifics** (if any already present) — the IMS **grant type** and token URL path actually in use (`client_credentials` vs `authorization_code`; `/ims/token/v1` vs `/v3`), and the **existing env-var names** for Adobe credentials, so generated code reuses them (e.g. `IMS_*`/`RETAIL_*`) instead of inventing `ADOBE_*` names. **Always read both `.env` and `.env.example`** (if they exist) to extract actual var names — the `.env.example` often contains commented-out Adobe vars (`IMS_*`, `RETAIL_*`, `ADOBE_*`) that define the intended naming scheme even before code is written. List ALL vars found, including `IMS_SCOPE`/`IMS_SCOPES`, `ADOBE_NOTIFY_AUTH_SECRET` or similar webhook/notify secret vars. Also check `.env.example` for any commented-out `*_NOTIFY_AUTH_SECRET`, `*_WEBHOOK_SECRET`, or similar — these signal the partner's intended Notify auth mechanism even when no handler code exists yet (record them under "Inbound caller auth").

### Step 3 — Mobile / App Deep Dive

Write the result into the `service-cards/mobile/` card set for a single cross-platform `mobile` surface, or into `service-cards/ios/` and/or `service-cards/android/` when native `ios`/`android` surfaces are registered as separate repos (one card set per native stack — Swift / Kotlin; all reuse the `_templates/mobile/` UI template set). Scan each in its resolved `$APP_<surface>`.

Read key mobile source files to understand:
- **Navigation** — how screens are registered and navigated to
- **Network layer** — existing HTTP client/service (Dio, URLSession, Retrofit, Axios)
- **State management** — Riverpod, Redux, @StateObject, ViewModel, BLoC
- **Existing component/widget library** — custom design system or third-party UI kit
- **User session** — how the current user's identity is accessed (what field is the unique user ID)
- **Deep link handling** — how the app handles incoming deep links

### Step 4 — Web / Webapp Deep Dive

Read key web source files to understand:
- **Build tool** — Vite, Webpack, Next.js built-in
- **Routing** — React Router, Vue Router, Next.js pages, Nuxt pages
- **API call pattern** — React Query, SWR, useFetch, raw fetch/axios
- **State management** — Redux, Zustand, Pinia, Context API
- **UI component library** — Material UI, Ant Design, custom components — where are they?
- **Backend proxy** — does an API gateway / proxy already exist?

### Step 5 — SDK Detection

If an Adobe SDK was detected in Step 1:
- Identify which SDK, version, and which surface it's on
- Read the integration file(s) to understand the usage pattern
- Determine whether the SDK flow (e.g. content creation) is separate from the subscription lifecycle
- Note any auth or credential sharing that could conflict with the Retail API flow

### Step 6 — Direct Calls Security Audit

Search all mobile and web source files for:
- `ims-na1.adobelogin.com` or `ims-na1-stg1.adobelogin.com`
- `partners.adobe.io` or `partners-stage.adobe.io`
- `CLIENT_SECRET`, `client_secret`, `ADOBE_SECRET` (any hardcoded credential pattern)
- Any import of IMS or Retail API URLs directly in mobile/web code

Any match is a **security blocker** — record it for the direct-calls audit card.

### Step 7 — Integration Readiness Scan

Search the codebase for any existing Adobe integration:
- Search for `adobe`, `ims`, `partners.adobe.io`, `CLAIM_PRODUCT`, `partner_reference_id`, `experience_url`, `offer_id`
- Note what already exists vs. what needs to be created

### Step 7.5 — Clarify the offer with the partner (interactive intake — DO NOT skip)

Code analysis reveals the *stack*, not the *business intent*. Before writing cards, **ask the partner** the things the codebase cannot state unambiguously — derive a proposed answer from the scan/mocks first, then confirm/fill each with the partner (the "Clarify before you build" gate (manual/methodology/verification.md#clarify-before-you-build) + manual/methodology/verification.md Protocol rule 8). Ask (batch the questions):

1. **Which Adobe product is being offered?** (e.g. Adobe Express, Photoshop, Lightroom, Acrobat Pro, Firefly — **never assume Express**.) This is the display name used in all generated UI copy. Code cannot reveal it — **always ask** unless a partner mock manifest already states it.
2. **The `offer_id`(s)** for that product. If Step 7/backend scan already found an offer id in config, show it and ask the partner to confirm; otherwise ask (it is Adobe-assigned at onboarding — record as a placeholder to fill if not yet known).
3. **The partner's own terminology** — what does the partner call the offer, an owned/active benefit, and the manage/cancel area? (e.g. "Rewards", "Your Benefits", "Memberships".) These words go into headings/labels; Adobe branding stays only on the offer card itself.
4. **Which surfaces to integrate** — confirm the detected surfaces are the ones to build into (some may be out of scope).
5. **Notify intent** — will the partner implement the optional Adobe Notify webhook, or rely on Get Subscription polling? If Notify, which of the five inbound-auth types (from Step 2) will they register with Adobe?
6. **Own screen designs (mocks)?** — for each UI surface in scope, ask whether the partner has their **own designs/mocks** for the claim and subscription screens. A partner integrating into their own product almost always wants the generated screens to match their product, so **ask up front — do not silently fall back to defaults.** If **yes**, tell them to drop the files under `mocks/<partner>/` (copy `mocks/_template/`, fill `manifest.md`) before the UI stage, so the UI phase reproduces their designs. If **no**, confirm the kit will build clean screens from its **built-in default layouts** using the partner's own component library + terminology, which they can restyle to their brand later via Mode B (`build-app-from-mocks`). Record the choice (own mocks vs defaults, per surface) in `service-cards/shared/SURFACE_SCOPE.md`.
7. **`partner_reference_id` format** — check the backend scan first for an existing customer/order/subscription ID convention (an existing order-id or account-id scheme). If one exists, confirm it's the one to reuse. If none exists, **ask the partner** what format/constraints apply (max length, allowed characters, whether it may embed customer-identifying data). The kit's own docs (`knowledgebase/integration-patterns/idempotency.md`) show a UUID-based id purely as an illustrative default when nothing else is specified — never assume that literal format is required.

Record the confirmed answers in **`service-cards/shared/OFFER_PROFILE.md`** (and expand the partner's wording into `service-cards/shared/TERMINOLOGY.md`; record which surfaces are in/out in `service-cards/shared/SURFACE_SCOPE.md`; record the `partner_reference_id` format decision (item 7) in `service-cards/backend/INTEGRATION_CONTEXT.md` → "Where `partner_reference_id` Is Stored" → Format). Downstream `/implement-*` skills read `OFFER_PROFILE.md` instead of assuming any product. If the partner cannot answer a value yet (e.g. `offer_id` not issued), record it as an explicit `TODO`/`TBD — ask before go-live` placeholder rather than inventing one — a placeholder there forces a STOP-and-ask before any UI copy is written.

**Non-interactive / headless fallback (no partner to ask right now).** When this skill runs where the intake questions cannot be answered live (CI, a batch/agent run, no interactive channel), do **NOT** guess the product, `offer_id`, terminology, or `partner_reference_id` format, and do **NOT** block the analysis. Instead: derive the best proposed answer from the scan/mocks, then write **every unanswered intake field as an explicit `TODO — ASK PARTNER` / `TBD — ask before go-live` placeholder** in `OFFER_PROFILE.md` (and `TERMINOLOGY.md`/`SURFACE_SCOPE.md`/`INTEGRATION_CONTEXT.md`), and in the Step 9 report list exactly which fields are unresolved. These placeholders are **hard-STOP gates downstream**: `/generate-lld` (Phase B), `/implement-feature`, and `/build-app-from-mocks` MUST stop and ask before generating any UI copy/labels while any offer field is still a placeholder (never default to Adobe Express). This lets analysis complete headless while guaranteeing the offer is confirmed before any product-specific output is produced. Likewise, if the mocks question (item 6) cannot be asked live, note in `SURFACE_SCOPE.md` and the Step 9 report that **no partner mocks were provided and the built-in default layouts will be used** — the partner can still add mocks under `mocks/<partner>/` and re-run the UI phase, or restyle later with Mode B (this is a visible default, not a silent one).

### Step 8 — Write the Service Card Sets

**Create one card set per detected surface by copying the matching template set from `service-cards/_templates/` into `service-cards/<surface>/`, then filling every `<fill>`/`TODO` from the partner's real code (cite file paths).** The taxonomy and section reference is [`../../manual/methodology/card-model.md`](../../manual/methodology/card-model.md).

- **`backend/`** — always produced. Copy `_templates/backend/` → `service-cards/backend/` (8 cards).
- **A UI surface** — copy `_templates/mobile/` → its own folder: `service-cards/mobile/` for a single cross-platform app, or `service-cards/web/` / `service-cards/ios/` / `service-cards/android/` for separate surfaces (`mobile` is mutually exclusive with `ios`/`android`). All UI surfaces reuse the one `_templates/mobile/` set.
- **`shared/`** — always produced. Copy `_templates/shared/` → `service-cards/shared/` and fill `OFFER_PROFILE.md`, `TERMINOLOGY.md`, `SURFACE_SCOPE.md` from Step 7.5.
- **`security/DIRECT_CALLS_AUDIT.md`** — produced **only if** Step 6 found findings.

Do not use the retired flat single-file-per-surface layout — the per-surface `service-cards/<surface>/` card sets are authoritative.

**If mobile and web are the SAME codebase** (e.g. Flutter compiled to both), do NOT re-analyze twice: fill the `mobile/` set fully, and in `service-cards/web/UI_SERVICE_CARD.md` write a short pointer — "same codebase as `service-cards/mobile/` — all source in `lib/`" — so downstream skills don't generate duplicated or divergent code (see the Flutter-web shortcut below).

The rest of this step maps **each fact the analysis captured** to the exact destination card + section. Relocate every fact; do not lose any nuance.

---

#### Backend card set — `service-cards/backend/` (always)

Copy `_templates/backend/` → `service-cards/backend/` and fill every card. (If Step 1's root scan found no backend, run the nested/recursive scan above **first**; only produce an all-`❌` `READINESS.md` if a backend genuinely does not exist anywhere in the repo.) Relocate each captured fact to its destination card + section:

| Fact captured | Destination card → section |
|---|---|
| Stack — `{language} + {framework}` ({directory}) | `SERVICE_CARD.md` frontmatter (`stack`, `repo`) + `BUILD_CONFIG.md` §1 Runtime Specifications |
| HTTP client (how outbound calls are made) | `BUILD_CONFIG.md` §2 Dependency Manifest → HTTP client |
| Logging — logger + log-format example generated code must match | `BUILD_CONFIG.md` §2 Dependency Manifest → Logging |
| Test framework + conventions | `BUILD_CONFIG.md` §2 Dependency Manifest → Test framework (coverage gaps → `SERVICE_CARD.md` §6 Test Coverage) |
| Build / verify commands | `BUILD_CONFIG.md` §5 Build Interface (authoritative verify commands) |
| Error-handling pattern | `SERVICE_CARD.md` §6 → Known Constraints / LLD Hints |
| End-user auth middleware | `CONTRACTS.md` Overview → "Auth scheme (end-user)" |
| Source structure / where new code goes | `MODULE_INDEX.md` (Taxonomy + Capability Catalogue) + `SERVICE_CARD.md` §5 Source Structure / §6 LLD Hints |
| Unusual patterns / warnings | `SERVICE_CARD.md` §6 "What You Need to Know Before Planning Work Here" |
| Outbound deps + IMS / Retail / Notify connectors | `CONNECTORS.md` (§2/§3 general, §4 Adobe Integration Connectors) |
| Subscription entity + where `partner_reference_id` lives + which backend owns the integration | `INTEGRATION_CONTEXT.md` |
| Integration readiness (all points) | `READINESS.md` |

Preserve these nuances (they change how downstream code is generated):

**Env-var names → `BUILD_CONFIG.md` §3 Environment-Variable Schema.** Record the EXACT config var names already used in this codebase — read from `.env`, `.env.example`, and source files. Include ALL relevant vars: e.g. `IMS_CLIENT_ID`, `IMS_CLIENT_SECRET`, `IMS_TOKEN_URL`, `IMS_SCOPE` (or `IMS_SCOPES`), `RETAIL_BASE_URL`, `ADOBE_NOTIFY_AUTH_SECRET`. Also state where `offer_id` lives: env var (name it), per-partner config JSON (file + field path — cross-ref `INTEGRATION_CONTEXT.md`), or not found. Downstream skills MUST reuse these exact names (Code Generation Protocol rule 1 / [`../../manual/methodology/verification.md`](../../manual/methodology/verification.md)) — do NOT invent `ADOBE_*` names if the partner already uses `IMS_*`/`RETAIL_*` names. If none exist yet, write "none yet — use canonical `ADOBE_*` fallback names".

**Route mount → `CONTRACTS.md` Overview (base path).** How full paths are formed in THIS stack — Express router mount (`/api`+route), NestJS global prefix set in bootstrap + controller path, Spring `server.servlet.context-path` + `@RequestMapping`, Django root URLConf (often NO prefix). If the prefix is set in the partner's bootstrap (not the analyzed package) or is absent, say the path is prefix-dependent / must be confirmed — do NOT invent `/api`. Generated routes MUST match the URL registered with Adobe (rule 2).

**Inbound caller auth → `CONTRACTS.md` Overview → "Inbound caller auth (machine callers)".** How the partner authenticates EXTERNAL SERVICE callers (machine-to-machine) — DISTINCT from end-user auth. A login/session token, member/admin JWT, or per-user API key is END-USER auth and does NOT count (Adobe can't obtain it). Record the shape AND the exact verification path: config-equality shared secret, opaque token/API-key verified against a datastore (hashed), machine-client OAuth/JWKS, mTLS, or gateway key. If several exist, record the machine-caller one. The Adobe Notify webhook reuses this (rule 7); keep it consistent with the Notify strategy in `shared/OFFER_PROFILE.md` §5. If the only inbound auth is end-user/session, or none exists, write `TODO — ASK PARTNER` ("UNCLEAR — must ask partner").

**Default authorization → `CONTRACTS.md` Overview → "Default authorization".** Does the framework DENY unauthenticated requests by default? Record the default rule (e.g. Spring `anyRequest().authenticated()` vs `permitAll`, a NestJS global guard, DRF default permissions) and the allow-list mechanism (`permitAll` matcher, `secure.ignored.urls`, `@Public`/`@Allow(Public)`). A new inbound endpoint inherits this — the notify skill must permit its path through the chain before its own validation runs.

**Integration readiness → `READINESS.md`** (status ✅/⚠️/❌ + evidence file path per row):
- IMS client — ✅ Found at path | ❌ Not found
- Retail API client — ✅ Found | ❌ Not found
- Notify — ✅ Found at path | ⚠️ Found but missing auth/idempotency | ❌ Not found
- Configuration → `offer_id` configured — ✅ in env var (name it) | ✅ in per-partner config file (file + field path — this means `offer_id` is NOT a single global env var and generated code must read it from that config, not `process.env.OFFER_ID`) | ❌ Not found
- Stack confidence — ✅ validated (Node/Express, Flutter — has a reference impl) | ⚠️ best-effort (detected but unvalidated stack — downstream skills lower their claims; see README support matrix)

**Subscription entity → `INTEGRATION_CONTEXT.md`** ("Where Subscription State Lives" / "Where `partner_reference_id` Is Stored"): which entity/table/field holds subscription state the Notify handler updates. If ❌ none exists, the notify skill must STOP and ask the partner where Adobe subscription state should live.

**Suggested integration path → `MODULE_INDEX.md` + `SERVICE_CARD.md` §6 LLD Hints:** prefer EXTENDING existing files (e.g. an existing IMS token service / Retail API client) over creating new scaffolding when those already exist.

---

#### UI card set — `service-cards/mobile/` (or `web/` / `ios/` / `android/`)

Produce for a single cross-platform `mobile` surface (Flutter, React Native, or a monorepo mobile app), or into `service-cards/ios/` and/or `service-cards/android/` when native `ios`/`android` surfaces are registered as separate repos (one set per native stack — Swift / Kotlin — consistent with Step 3 and manual/methodology/modes.md#surface-registry-and-multi-repo-resolution; do NOT produce `mobile/` when only native ios/android surfaces are registered — produce the native sets instead). Copy `_templates/mobile/` → the surface folder, set the `surface`/`stack`/`rendering`/`repo` frontmatter in `UI_SERVICE_CARD.md`, and relocate each captured fact:

| Fact captured | Destination card → section |
|---|---|
| Navigation — how to add a new screen | `ROUTES.md` (Router, Route Registry, Navigation Patterns) |
| Network — HTTP client class/file, API-call pattern | `DATA_LAYER.md` (Overview, Read/Write registries, Auth Token Injection) |
| State management — how new state is added | `STATE_MANAGEMENT.md` (stores, init) |
| Existing UI component library the generated UI MUST reuse | `UI_CODE_PATTERNS.md` §2 Existing Component Library |
| Session — how to get the current user ID (the `partner_reference_id` seed) | `STATE_MANAGEMENT.md` → "Session Seed for partner_reference_id" + `INTEGRATION_CONTEXT.md` |
| Deep links (existing setup, or "Not configured") | `ROUTES.md` → "Deep-Link / Return-from-Adobe Handling" + `INTEGRATION_CONTEXT.md` |
| Runtime / build / verify commands | `UI_PLATFORM.md` (§5 authoritative verify commands) |
| Where new screens/components go / suggested integration path | `UI_MODULE_INDEX.md` + `UI_SERVICE_CARD.md` §4 Source Structure |
| Backend proxy (web: existing proxy location, or "None — must be added") | `DATA_LAYER.md` → Backend-Proxy Rule + `INTEGRATION_CONTEXT.md` → Partner Backend This Surface Calls |
| Integration readiness (claim UI, subscription UI, cancel UI, deep-link handler, component-library reuse, testing, config, stack confidence) | `READINESS.md` |

**Flutter-web shortcut.** If the web surface is `pubspec.yaml` + `web/` directory (Flutter compiled to web — the **same** codebase as the `mobile` surface), do NOT re-analyze it: write `service-cards/web/UI_SERVICE_CARD.md` as a short pointer — "same codebase as `service-cards/mobile/` — all source in `lib/`" — and skip the rest of the `web/` set. Downstream skills follow the pointer to the `mobile/` set so they don't generate duplicated or divergent code.

---

A **web** surface (React, Vue/Nuxt, Next.js, Angular, or Flutter web) uses this **same** UI card set in `service-cards/web/` — Routing → `ROUTES.md`, API-call pattern → `DATA_LAYER.md`, state → `STATE_MANAGEMENT.md`, UI component library → `UI_CODE_PATTERNS.md`, backend proxy → `DATA_LAYER.md` Backend-Proxy Rule. Apply the Flutter-web shortcut above when it is the same codebase as `mobile/`.

---

#### Shared context — `service-cards/shared/` (always)

Filled in Step 7.5 from the partner intake: `OFFER_PROFILE.md` (offered product; `offer_id`(s) — or `TODO`/`TBD — ask before go-live`; partner terminology for offer/benefit/manage; surfaces in scope; Notify strategy + registered inbound-auth type), `TERMINOLOGY.md` (expanded UI wording + product-naming rules), `SURFACE_SCOPE.md` (in/out surfaces + monorepo-vs-multi-repo map mirroring `.target-apps`). A placeholder in `OFFER_PROFILE.md` is a STOP-and-ask gate downstream — never fill it with a guess.

---

#### Adobe SDK findings (no dedicated card in the new model)

If Step 5 detected an Adobe SDK, do **NOT** create a separate SDK card. Instead record the findings in the relevant surface's `SERVICE_CARD.md` / `UI_SERVICE_CARD.md` under **"What You Need to Know Before Planning Work Here"**: SDK name + package, version, file path(s), surface, what it is used for, and whether its flow is independent of the subscription lifecycle (call out any shared auth/credentials or state the Retail API integration must not break; state whether coordination is needed). **If the SDK creates a security concern** — it shares/exposes IMS credentials, or calls Adobe directly from a frontend surface — **also** record it in `service-cards/security/DIRECT_CALLS_AUDIT.md`.

---

#### Security audit — `service-cards/security/DIRECT_CALLS_AUDIT.md` (only if findings)

Produce this file **only if** Step 6 found violations — its very presence is a go-live BLOCKER signal. Copy `_templates/security/DIRECT_CALLS_AUDIT.md` and fill: §1 direct frontend → Adobe calls (`file:line`, call, severity, remediation), §2 secret-leakage checks (IMS credentials / `*_CLIENT_SECRET` names found in a frontend repo — verification rule 9), §3 inbound-auth clarity, §4 notify-registration dependencies (keep consistent with `shared/OFFER_PROFILE.md` §5). Recommended remediation: run `/generate-adobe-clients` (Phase 1 then Phase 2) to move the calls to the backend, and remove the frontend calls before production.

---

### Step 9 — Report to User

After writing all card sets, print:
- The **confirmed Offer profile** (from `service-cards/shared/OFFER_PROFILE.md`) — offered product, `offer_id`(s), partner terminology, surfaces in scope, Notify choice (flag any value still a `TODO`/`TBD` placeholder)
- Which surfaces were detected and which per-surface card folders were written under `service-cards/` (e.g. `backend/`, `mobile/` or `web/`/`ios/`/`android/`, and always `shared/`)
- Whether Adobe-SDK findings were recorded (and in which surface card)
- Whether `service-cards/security/DIRECT_CALLS_AUDIT.md` was written (and how many violations)
- What's already integrated vs. what needs to be built (from each surface's `READINESS.md`)
- Recommended next step: `/generate-adobe-clients` (if no security blockers) or "resolve `service-cards/security/DIRECT_CALLS_AUDIT.md` first" (if violations found)

### Review gate (DG-1 backend / DG-2 UI)

This report IS the DG-1/DG-2 checkpoint (see `../../manual/decision-gates.md`) — the
first chance to confirm the kit understood the partner's code before any design or
code follows. Explicitly tell the user this is a review checkpoint, then ask them
to confirm, per card set:

- **DG-1 — backend cards.** How the backend talks to external services (timeouts,
  retries, error handling); how incoming requests are authenticated and whether the
  framework allows or blocks requests by default; where subscription data is stored;
  the commands that build and test the backend.
- **DG-2 — UI cards** (per surface). How screens fetch data; how navigation and
  login protection work; which existing UI components the generated screens must
  reuse.

For small fixes, edit the card directly; for structural problems (something scanned
wrong), re-run this skill. State whether each gate is **cleared** or **blocked**.
**STOP here — do not proceed to `/generate-adobe-clients` or `/generate-lld` until
DG-1 and DG-2 are cleared** (Fast path — no partner repo registered, bundled
`base-ref-app/` only — continue automatically, per `../../manual/methodology/workflow.md#process-depth-by-target-fast-path-vs-full-workflow`).
