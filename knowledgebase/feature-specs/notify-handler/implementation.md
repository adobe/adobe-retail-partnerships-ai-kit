# Implementation contract — notify-handler (FS-004)

Feature-specific hardening for `/implement-feature notify-handler` — the
partner-hosted endpoint Adobe calls to push subscription lifecycle events
(INBOUND). Feature spec: `../FS-004-notify-receiver.md`. API:
`../../api-spec/notify-api.md`. Patterns: `../../integration-patterns/security.md`
(auth validation), `../../integration-patterns/idempotency.md` (duplicate handling).

Extra Step-1 reads: `service-cards/backend/CONTRACTS.md` (Overview → inbound caller
auth + default authorization), `INTEGRATION_CONTEXT.md` (subscription entity),
`PLATFORM.md` (datastore), `BUILD_CONFIG.md` (config loading, env-var schema), and
`OFFER_PROFILE.md` §5 (registered inbound-auth type).

## Endpoint — idiomatic to the detected stack

Do **NOT** assume a REST `/api/adobe/notify` path. Generate an Express route, Django
view / GraphQL mutation, NestJS controller, Spring `@RestController`, Rails engine
route, ASP.NET minimal-API/controller, Go chi/gin handler, etc. Full path = whatever
the partner registers with Adobe, and it must match (Rule 2); derive the prefix from
`CONTRACTS.md` → Overview. **Express:** if routes mount at `/api`, use a separate
webhooks router at `/api/webhooks` → `POST /api/webhooks/notify` (separate webhook
routes from authenticated API routes). GraphQL-only / prefix-less: prefer a mutation
or prefix-free path. **If the detected stack has no reference impl in the kit** (Go,
Rust, .NET, Rails, native), generate idiomatic code from the pseudocode contract +
FS-004 and **state in the report that no reference snippet existed** (best-effort).

**The endpoint implements, in order:**

1. **Auth validation** — see the dedicated section below. Return 401 (no body) if invalid.
2. **Body validation** — require `partner_subscription_id`, `status`, `timestamp`. Return 400 if missing.
3. **Idempotency check** — if `(partner_subscription_id, status, timestamp)` already processed, return 200 immediately (no reprocess).
4. **Event processing:** `status = "Active"` → set subscription ACTIVE, update `startDate`/`endDate`; `status = "Cancelled"` → set CANCELLED, update `endDate`; subscription not found → log warning, return 200 (don't fail on local data gaps).
5. **Return 200** for all successfully processed events (including duplicates).
6. **Log:** `event=notify.received id={partner_subscription_id} status={status} duplicate={true/false}`.

Use the partner's existing data-access pattern (ORM/repository/raw query) from
`PLATFORM.md` + `INTEGRATION_CONTEXT.md`. **If the partner's data model has no
entity/field for the Adobe subscription** (common on a generic platform), do NOT
invent a schema — **STOP and ask the partner** which entity/table/custom-field it
lives on (Rule 8), then wire to that.

## Idempotency storage

Read `INTEGRATION_CONTEXT.md` + `PLATFORM.md`: if the partner has a DB (Mongo/Postgres/…),
store a unique `(subscription_id, status, event_timestamp)` doc/row and check before
processing. If single-instance with no events table yet, use an in-memory `Set` keyed
`${subscription_id}:${status}:${timestamp}` with a comment "replace with a DB-backed
unique table in production to survive restarts." Do NOT invent a new collection/table
without checking the card first. Minimum unique key: `(subscription_id, status, event_timestamp)`.

## Auth validation — the partner OWNS this auth

The partner secures this endpoint the way they already secure inbound APIs and
registers that mechanism with Adobe at onboarding; Adobe **replays exactly that** on
every call. Validate using the partner's mechanism — **never invent, mint, default, or
fabricate a credential.** Validate by the registered **type** — one of `STATIC`,
`BASIC`, `CUSTOM_HEADERS`, `OAUTH2_CLIENT_CREDENTIALS`, `CUSTOM_TOKEN` — using the
matching pattern in `integration-patterns/security.md`.

**FIRST — reconcile with the framework's default authorization** (`CONTRACTS.md` →
Overview → "Default authorization"). Two opposite cases:

- **Deny-by-default** (Spring Security `anyRequest().authenticated()`, NestJS global `APP_GUARD`, DRF default permissions): the chain rejects the call *before your handler runs*, so you MUST **(a)** permit the notify path through the chain **then (b)** validate inside the handler. **Both required** — doing only (b) yields a 401 before your validator runs. Permit-through by stack: Spring modern → `permitAll()` matcher in `SecurityFilterChain` (**note:** with `server.servlet.context-path` set, the `requestMatcher`/`permitAll` path is servlet-relative — it EXCLUDES the context path — while the URL you register with Adobe INCLUDES it; matching the context-path-prefixed URL in the security chain silently fails to permit the route); legacy Spring `@EnableResourceServer` → `ResourceServerConfigurerAdapter.configure(HttpSecurity).authorizeRequests().antMatchers(path).permitAll()`; NestJS → `@Public()`/exclude from guard; DRF → `permission_classes=[AllowAny]`; ASP.NET Core → `.AllowAnonymous()` / group without `.RequireAuthorization()`; Django → CSRF-exempt `re_path`.
- **Permit-by-default** (custom route/prefix with NO auth — Medusa custom routes, bare Express router, public controller): opposite danger — an **open, unauthenticated webhook**. You MUST **ADD** auth (mount under the partner's authenticated group, or attach their auth middleware) — never leave it open. Watch **actor-scoped middleware** (e.g. an api-key check that only fires for actor type `user`): confirm it runs for your route, or wire it explicitly.

By type:
- **`STATIC`/`BASIC`/`CUSTOM_HEADERS`:** validate the **partner-supplied** credential, matching the partner's actual verification path (`CONTRACTS.md` → Inbound caller auth): config value → timing-safe compare; token verified against a datastore (hashed API keys / PATs) → reuse that lookup, do NOT substitute a config-equality compare. Read any secret from the partner's config/secret store — never hardcode, never generate a secret for them. Reuse the partner's inbound-auth check **only if it authenticates external/machine callers** — **never wire the webhook into an end-user login/session filter** (member/admin JWT, session cookie); if that's all they have, treat inbound caller auth as UNCLEAR and ask (Rule 8). **Special case:** if `BUILD_CONFIG.md` records `ADOBE_NOTIFY_AUTH_SECRET` (or equivalent) present in `.env` but no verification code exists yet, implement a timing-safe compare of `Authorization: Bearer <secret>` against that env var — this is the STATIC type and needs no further clarification.
- **`OAUTH2_CLIENT_CREDENTIALS`/`CUSTOM_TOKEN`:** Adobe replays a token fetched from the partner's own token endpoint — validate the partner's **own** issued token via their existing identity layer (signature/issuer/audience/expiry, or introspection). Reuse their token-validation code; no parallel scheme.
- **Not one of the five** (mutual-TLS, auth terminated at a gateway): don't force-fit — reuse the partner's mechanism and **ask** how Adobe authenticates in their setup (Rule 8).
- **Unclear** from code/cards: **STOP and ask** which mechanism/type they registered (Rule 8) — never pick silently.

Read the registered type from `CONTRACTS.md` → Overview ("Inbound caller auth (machine callers)"), cross-checked against `OFFER_PROFILE.md` §5. If "UNCLEAR — must ask partner" / `TODO — ASK PARTNER` or absent, STOP and ask before writing auth code.

## Environment config

Add only what the **registered type** needs, in the form the target uses
(`BUILD_CONFIG.md` §3 env schema / §4 secrets — `.env`/`.env.example`, Spring
`application.yml` + `@Value`, typed config object, etc.):
- `STATIC` — expected secret/header value (e.g. `ADOBE_NOTIFY_AUTH_SECRET`).
- `BASIC` — expected username + password.
- `CUSTOM_HEADERS` — expected header name(s) + value(s).
- `OAUTH2_CLIENT_CREDENTIALS`/`CUSTOM_TOKEN` — the partner's own token-validation config (issuer URL, JWKS endpoint, audience) — no fabricated Adobe secret; may be nothing to add.

Read values from that store; never hardcode. Do NOT make a missing notify secret
boot-fatal (Rule 3). If the partner's real machine-auth is reused, the right answer
may be **no new config** — enforce auth by *not* exempting the route from their guard.

## Tests

Valid `Active` → updated + 200; valid `Cancelled` → updated + 200; duplicate → 200,
no DB update; invalid auth → 401; malformed body → 400; unknown
`partner_subscription_id` → 200 (warning logged).

## Verify

- **Rule 1:** whatever auth config the registered type requires (may be none for token types) is named consistently across handler, `.env.example`, validation code. Don't assume `ADOBE_NOTIFY_AUTH_SECRET`.
- **Rule 2:** the route's `mount prefix + path` equals the URL the partner registers with Adobe — exactly.
- **Rule 5:** run typecheck + the tests; if feasible boot and confirm non-404. Heavy framework: compile the touched module, reason reachability from route registration + security chain, state a full boot was out of scope. A `401` is the "healthy unauthenticated" signal **only** after confirming the route is permitted through the chain — otherwise the request may have been rejected before reaching your handler.

## Report reminders — MANDATORY partner→Adobe hand-off

This endpoint is useless until Adobe is told about it. Adobe calls it to mark a
subscription Active (after the user finishes `experience_url`) or Cancelled. The
partner must register it with Adobe at onboarding — the kit cannot. Print, with
concrete values (not placeholders):

```
=== PROVIDE THIS TO ADOBE AT ONBOARDING ===
Notify webhook URL : https://<partner-public-host>/api/webhooks/notify   ← the route just created; must be PUBLIC HTTPS (localhost is NOT reachable by Adobe — use the deployed host or an ngrok/tunnel URL for testing)
Auth type          : <the registered type, e.g. STATIC>
Auth credential    : the value of <ADOBE_NOTIFY_AUTH_SECRET or the partner's chosen secret> — shared with Adobe out-of-band, NEVER committed
Egress/ingress IPs : the partner provides their allowlist; ask Adobe for Adobe's egress IPs (stage)
Test id            : a test partner_subscription_id Adobe can use to verify delivery
```

State plainly: *"Until the partner registers this URL + auth with Adobe, Adobe cannot
call it and subscriptions will not auto-update to Active/Cancelled — the app would have
to poll Get Subscription instead."* Then print the FS-004 onboarding checklist and
suggest `/generate-env-config`, `/generate-tests`, `/generate-integration-checklist` next.
