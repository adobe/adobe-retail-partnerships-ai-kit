# Verification & Code-Generation Protocol

> Agent-neutral. Every step that writes code MUST follow this protocol and run
> these checks **before reporting success**. Never report success on code you
> have not verified. This is the kit's security and correctness backbone; do not
> relax it.

## Clarify Before You Build

> Agent-neutral. This kit is an **interactive assistant, not a batch generator.**
> Before building anything, get the business inputs the code/mocks cannot tell
> you unambiguously, and confirm them with the partner. Derive first, then **ASK
> for every gap** — never guess or default.

### The offered product is a VARIABLE — never assume Adobe Express

Adobe has many products a partner may offer (Adobe Express, Photoshop, Lightroom,
Acrobat Pro, Firefly, Creative Cloud, …). Which product an engagement offers is
defined by:

- **Mode B:** the partner's mock `manifest.md` ("Offered product" + terminology).
  If the manifest doesn't state it, **ask** before generating.
- **Mode A:** `service-cards/shared/OFFER_PROFILE.md`, filled by the analyze step
  **by asking the partner** (product name, `offer_id`(s), the partner's own words
  for offer/benefit/manage, surfaces, Notify intent). Every UI-touching step reads
  it; if it is missing or a value is a placeholder, **ask** before writing copy.

Wherever this kit or a spec shows "Adobe Express," it is **one example**, not the
target. Use the resolved product name and the partner's terminology in all
generated copy, headings, and labels.

### When to stop and ask

Stop and ask the partner whenever code/cards do not make it unambiguous:

- how an external caller should authenticate (Notify inbound auth),
- where secrets come from,
- which offer/`offer_id` applies,
- which datastore holds subscription state / `partner_reference_id`,
- what format/constraints `partner_reference_id` itself should follow (never assume the kit's illustrative UUID example is required — check for an existing partner ID convention first),
- which surfaces are in scope.

See rules 7 and 8 below.

## The nine rules

1. **One env-var name everywhere (resolution rule).** Do not invent names.
   Resolve each variable's name by precedence: (a) the name **already used in the
   partner's code/`.env`** (recorded in `service-cards/backend/BUILD_CONFIG.md`);
   (b) only if none exists, the canonical `ADOBE_*` name (see
   [environment-config](../../knowledgebase/integration-patterns/environment-config.md)).
   Use the **same** resolved name across the IMS client, Retail client,
   `.env.example`, and startup validation — never mix two schemes.

2. **Path consistency (client ↔ server), across repos.** For every endpoint the
   exact path string the frontend calls **must equal** `(server mount prefix +
   route path)`, character for character. Resolve the client surface path and the
   backend surface path independently — they may be **different repos** with no
   shared compile step, so a wrong path ships as a silent 404. Grep the endpoint
   literal in each repo; the report must name the two repos + files compared.

3. **Config-missing ≠ upstream error.** Generated routes/services must
   distinguish "integration not configured" (missing/empty env var) from "Adobe
   returned an error." Missing config → log a clear `*_NOT_CONFIGURED` line and
   return a distinct response — never collapse it into an opaque 500/503.

4. **Config reconciliation (branch on the config mechanism).** Reconcile against
   the mechanism recorded in `BUILD_CONFIG.md`, not a fixed `.env` model.
   - **dotenv stack:** after writing/updating `.env.example`, if a live `.env`
     exists, diff it and print exactly which boot-required vars are missing or
     empty **in `.env`**, naming the precise file + keys.
   - **typed/yaml stack** (Spring `application.yml` + `@Value`/`@ConfigurationProperties`,
     a typed config object, Go Viper/INI): do **not** impose `.env`/`.gitignore`/
     `process.env`. Reconcile against that stack's config source instead — name the
     config file + keys still needing values and confirm a validator (e.g. a Spring
     `@PostConstruct`) covers the boot-required set.

   The kit never writes secret values.

5. **Verify before reporting, per surface.** Run **each registered surface's own**
   build/typecheck **in its own repo** (backend → `tsc --noEmit` / `mvn compile` /
   etc.; `mobile` → `flutter analyze`; `ios` → `swift build`/`xcodebuild`;
   `android` → `./gradlew assembleDebug`; `web` → its build), then the relevant
   tests. The authoritative commands come from each card's
   `BUILD_CONFIG.md` / `UI_PLATFORM.md`. For routes, confirm reachability per rule
   2. Fix and re-verify on failure. The report must state **what was verified per
   surface and the actual command output** — not assumptions.

6. **No hardcoded per-partner values.** Never hardcode `offer_id`, base URLs, or
   partner-specific values in routes. Resolve them from the partner's config
   location (per `BUILD_CONFIG.md`). Name the exact file/field to set and state
   that any shipped value is a placeholder.

7. **The partner OWNS the auth on their inbound endpoints — validate using their
   mechanism; never invent one.** Any endpoint the partner hosts for an external
   caller (e.g. the Adobe Notify webhook) is secured the way the partner already
   secures inbound APIs; the partner defines that mechanism and registers it with
   Adobe at onboarding, and Adobe replays exactly that. Validate according to the
   registered type — one of `STATIC`, `BASIC`, `CUSTOM_HEADERS`,
   `OAUTH2_CLIENT_CREDENTIALS`, `CUSTOM_TOKEN` (see
   [notify-api](../../knowledgebase/api-spec/notify-api.md)). For the static family,
   validate the **partner-supplied** credential via their real verification path
   (timing-safe compare or datastore/hash lookup), reusing the partner's inbound-
   auth check **only if it authenticates external/machine callers** (never an
   end-user login/session filter). For the token family, validate the partner's
   **own** issued token via their identity layer (JWKS/issuer/audience/expiry or
   introspection). If the framework denies unauthenticated requests by default,
   first permit the endpoint through the security chain, then validate. **Never
   hardcode, mint, default, or fabricate a credential.** If the mechanism is not
   one of the five (e.g. mTLS or gateway-terminated), do not force-fit — reuse
   theirs and **ask** (rule 8).

8. **Ask the partner when the codebase doesn't make it clear.** If something
   needed to generate correct code is not unambiguous — how an external caller
   authenticates, where secrets come from, which offer applies, which datastore
   to use — **STOP and ask.** Do not assume or fabricate.

9. **Secret containment (multi-repo).** IMS credentials, `*_CLIENT_SECRET`, and
   any Adobe token-issuing config must appear **only** in the backend surface.
   After generating code, search the mobile/ios/android/web repos for those names
   and **fail loudly** if any leaked. This enforces the backend-to-backend
   invariant across separate repos. The check inspects **names** only. The kit
   ships an enforced check at its root — **`check-secret-containment.sh`** (reads
   `.target-apps`, scans every non-backend surface minus the backend subtree, and
   exits non-zero on a leak; on the **fast path**, where no `.target-apps` exists,
   it falls back to scanning the bundled `base-ref-app/` so the check still runs);
   run it as the mechanical form of this rule.

## Code-quality rules (always)

- Log every Adobe API call with: event name, `partner_reference_id`, latency (ms),
  response status.
- Handle every documented error code explicitly — no silent catch-all.
- Use structured logging matching the partner's existing logger.
- Include a `.env.example` entry for every new environment variable.
- Pass `partner_reference_id` in log context (MDC or equivalent).
- Generate unit tests alongside implementation.

## Reporting

The verification report must state, per surface: the command run, its actual
output, and a PASS/PARTIAL/FAIL verdict — then a `READINESS.md` update and clear
NEXT STEPS. See [card-model.md](card-model.md) §4.3.
