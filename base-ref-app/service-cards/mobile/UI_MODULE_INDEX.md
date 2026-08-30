# UI Module Index — mobile (Partner Ref App)

> _Capability → code resolver for the Flutter surface in `base-ref-app/lib`._

## 1. Module Taxonomy

| Layer | Location | Responsibility | May depend on |
|---|---|---|---|
| Page / Screen | `lib/features/*/**_screen.dart` | Full-screen UI, wires services/providers | Component, Hook/Service, Store |
| Component (widget) | `lib/widgets/*.dart` | Reusable presentational widgets (brand mark, drawer) | Component, Util |
| Hook / Service | `lib/services/*.dart` | Remote calls (Dio) and persistence (shared_preferences) | Util |
| Store (Riverpod provider) | `lib/features/session/session_provider.dart` | App-wide session state | Util |
| Util | `lib/core/*.dart` | Config constants, JWT decoding, date formatting | — |
| Model | `lib/models/session.dart` | Domain types | — |

**Forbidden directions** _(a lower layer must never import an upper one)_:

- Components (`widgets/`) MUST NOT import Pages (`features/*/**_screen.dart`).
- Services (`services/`) and Stores (`features/session/session_provider.dart`)
  MUST NOT import Pages or Components — confirmed true today (`auth_service.dart`
  and `session_storage.dart` import only `core/`/`models/`).
- Util (`core/`) MUST NOT import anything above it — confirmed (`jwt_utils.dart`,
  `config.dart`, `date_format.dart` have no app-level imports).

## 2. Capability Catalogue

### 2.1 Login / Session

- **Page:** `lib/features/session/login_screen.dart`
- **Component(s):** `lib/widgets/adobe_brand.dart`
- **Hook / Service:** `lib/services/auth_service.dart` (`AuthService.login()`)
- **Store:** `lib/features/session/session_provider.dart` (`sessionProvider`,
  a `NotifierProvider<SessionNotifier, Session?>`)
- **Call graph:** `login_screen.dart` → `AuthService.login()` → `POST /api/auth/login` → `sessionProvider.notifier.signIn()` → `SessionStorage.save()`
- **Notes:** app-wide route redirect logic lives in `lib/app.dart`'s
  `routerProvider` (`redirect:` callback), not in the login screen itself —
  see `ROUTES.md`.

### 2.2 Claim (not yet implemented)

- **Page:** none yet — planned entry point is `lib/features/home/home_screen.dart` (currently a placeholder) or a new `lib/features/claim/` directory
- **Component(s):** none yet
- **Hook / Service:** none yet — will be a new service alongside `auth_service.dart`
- **Store:** none yet
- **Call graph:** `TODO` (to be `HomeScreen`/new Claim page → new `ClaimService` → partner backend `/claim`-style route → Adobe, backend-to-backend only)
- **Notes:** no mocks or LLD exist yet for this app; the kit's default mocks
  (`knowledgebase/ui-mocks/defaults/FS-001-claim-product/`) are the fallback
  spec.

### 2.3 Subscription status / Cancel (not yet implemented)

- **Page:** none yet
- **Component(s):** none yet
- **Hook / Service:** none yet
- **Store:** none yet
- **Call graph:** `TODO`
- **Notes:** `HomeScreen` is the natural place for a state-driven entry point
  (Claim CTA vs Manage affordance) per
  [`../../../skills/implement-feature/SKILL.md`](../../../skills/implement-feature/SKILL.md)'s
  cross-surface UI rules.

## 3. Cross-Reference Indexes

**Route → Capability**

| Route | Capability |
|---|---|
| `/login` | 2.1 |
| `/` | 2.1 (redirect target) + future host for 2.2/2.3 |

**Hook → Capabilities**

| Hook / Service | Capabilities |
|---|---|
| `AuthService` (`lib/services/auth_service.dart`) | 2.1 |
