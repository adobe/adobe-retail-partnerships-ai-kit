# Build Config — {service_name}

*Runtime, dependencies, environment-variable schema, and the AUTHORITATIVE build
and verify commands for this backend. The verify step runs the commands in §5
exactly as written (verification rule 5), and resolves env-var names from §3
(rule 1). Fill from the partner's real build files (`pom.xml`, `package.json`,
`build.gradle`, Dockerfile, CI config), citing paths.*

---

## 1. Runtime Specifications

| Field | Value |
|---|---|
| Runtime engine | `<fill: e.g. JDK 17, Node 20>` |
| Package manager | `<fill: e.g. Maven, npm, Gradle>` |
| Entry point | `<fill: main class / entry file>` |
| Default port | `<fill>` |

*Serverless backends (Lambda / Cloud Functions / Azure Functions) have neither a
listening port nor a classic entry-point class. For both fields above,
`N/A — serverless (state your function's trigger type and handler entry point
instead, e.g. `handler.js:exports.claimHandler`)` is a valid, expected value —
do not force-fill a port or entry point that doesn't exist.*

## 2. Dependency Manifest

*Where dependencies are declared and the ones that matter for the integration
(HTTP client, JSON, logging, test framework). Do not paste the whole file — name
it and list the load-bearing entries.*

- **Manifest file:** `<fill: path>`
- **HTTP client:** `<fill>`
- **Logging:** `<fill: logger the generated code must match>`
- **Test framework:** `<fill>`
- **Other notable:** TODO

## 3. Environment-Variable Schema

> **Name resolution (verification rule 1).** The "Variable name" column records
> the name **as it is actually used in the partner's existing code / `.env`**.
> Reuse that exact name across the IMS client, Retail client, `.env.example`,
> and startup validation. Only when **no** existing name exists (greenfield) do
> you fall back to the canonical `ADOBE_*` name from
> [`../../../knowledgebase/integration-patterns/environment-config.md`](../../../knowledgebase/integration-patterns/environment-config.md).
> Never mix the two schemes.

| Variable name (AS USED IN PARTNER CODE) | Purpose | Required? |
|---|---|---|
| `<fill: partner's name, else ADOBE_IMS_CLIENT_ID>` | IMS client ID | yes |
| `<fill: partner's name, else ADOBE_IMS_CLIENT_SECRET>` | IMS client secret | yes |
| `<fill: partner's name, else ADOBE_IMS_SCOPES>` | OAuth scopes (plural, comma-separated) | yes |
| `<fill: partner's name, else ADOBE_IMS_TOKEN_URL>` | IMS token endpoint (full URL incl. path) | yes (boot-required) |
| `<fill: partner's name, else ADOBE_RETAIL_API_BASE_URL>` | Retail API base URL | yes |
| `<fill: partner's name, else ADOBE_API_KEY>` | `X-API-Key` header value | graceful (not boot-fatal) |
| `<fill: partner's name, else ADOBE_OFFER_ID>` | Adobe-assigned offer ID | graceful (not boot-fatal) |
| `<fill: partner's name, else ADOBE_NOTIFY_AUTH_SECRET>` | Notify inbound-auth credential | only if Notify enabled |
| TODO | TODO | TODO |

## 4. Secrets & Sensitive Data

*Where secrets come from (env, vault, secret manager) and how they are loaded.
Record the IMS `*_CLIENT_SECRET` here so rule 9 can confirm it appears ONLY in
this backend surface. The kit never writes secret values — names only.*

- **Secret source:** `<fill: e.g. env vars, AWS Secrets Manager, Vault>`
- **Loaded by:** `<fill: config class / file>`
- **Sensitive names (must not leak to frontend repos):** `<fill>` — TODO

## 5. Build Interface (AUTHORITATIVE verify commands)

> These are the **exact** commands the verify step runs in this repo
> (verification rule 5). Fill them with the partner's real commands. If a stage
> does not apply, write `n/a`, not a guess.

| Stage | Command |
|---|---|
| Setup | `<fill: e.g. npm ci / mvn -q dependency:go-offline>` |
| Build | `<fill: e.g. mvn -q compile / npm run build>` |
| Typecheck | `<fill: e.g. tsc --noEmit / mvn -q compile>` |
| Test | `<fill: e.g. mvn -q test / npm test>` |
| Package | `<fill: e.g. mvn -q package / npm run package>` |

## 6. Cross-Environment Mappings

*How config differs between stage and prod (base URLs, credential sets, feature
toggles). Values come from the partner; the kit records the mapping, not the
secrets. See [`../../../knowledgebase/integration-patterns/environment-config.md`](../../../knowledgebase/integration-patterns/environment-config.md).*

| Setting | Stage | Prod |
|---|---|---|
| IMS base URL | `<fill>` | `<fill>` |
| Retail API base URL | `<fill>` | `<fill>` |
| <fill> | TODO | TODO |
