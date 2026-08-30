# Integration Pattern: Security

## Credential Management

### Rules

1. **Never hardcode credentials.** All secrets via environment variables.
2. **Never commit secrets to source control.** Use `.env.example` (not `.env`) in the repo.
3. **Separate stage and production credentials.** Adobe provides different credentials for each environment.
4. **Rotate immediately if exposed.** Contact Adobe partner engineering — do not wait.

### Required Secrets

The canonical env-var **name** resolution rule lives in `manual/methodology/verification.md` (Rule 1); the `.env.example` template and stage/prod values live in `knowledgebase/integration-patterns/environment-config.md`. The security rules here apply to all of them: every secret is an env var, `.env.example` is committed with no real values, real values go only in an uncommitted `.env`.

Add `.env` to `.gitignore`:
```gitignore
.env
.env.local
.env.production
```

---

## Notify API Security

Adobe calls your Notify endpoint. **You own this endpoint's auth** — secure it the way you already secure your inbound APIs, register that mechanism with Adobe at onboarding, and Adobe replays exactly that on every call. Validate accordingly, by the **type you registered** — one of `STATIC`, `BASIC`, `CUSTOM_HEADERS`, `OAUTH2_CLIENT_CREDENTIALS`, `CUSTOM_TOKEN` (see `api-spec/notify-api.md`). The credential/token is always **yours** (supplied by you, or issued by your own identity layer) — **never hardcode, mint, or fabricate one**; read it from your config/secret store. If your inbound auth isn't one of these five (e.g. mTLS or gateway-terminated), reuse your mechanism and confirm with Adobe partner engineering what Adobe can send.

### STATIC — fixed-header / shared-secret validation

> **Two verification shapes — match the partner's.** The example below is a **config-equality** compare (an env secret). But many real partners verify the header credential against a **datastore of hashed API keys** (e.g. `sk_…` looked up by `scrypt`/`HMAC`/`bcrypt`, or a Rails `ApiKey.find_by_secret_token`, or a Saleor `AppByTokenLoader`). In that case **reuse the partner's existing key-verification code — do NOT substitute a config-equality compare, and add no new env secret** (the credential already lives in their datastore). Language-agnostic: `key = extractHeader(req); return partner.verifyApiKey(key)` (their hashed lookup). Only use the env-compare form when the partner's real mechanism is a single shared secret in config.

Adobe sends: `Authorization: Bearer <shared_secret>` (config-equality form):

```typescript
function validateNotifyAuth(req: Request): boolean {
  const authHeader = req.headers['authorization'];
  if (!authHeader || !authHeader.startsWith('Bearer ')) return false;
  const token = authHeader.substring(7);
  return token === process.env.ADOBE_NOTIFY_AUTH_SECRET;
}
```

Use constant-time comparison to prevent timing attacks:

```typescript
import { timingSafeEqual } from 'crypto';

function validateNotifyAuth(req: Request): boolean {
  const authHeader = req.headers['authorization'] ?? '';
  const expected = `Bearer ${process.env.ADOBE_NOTIFY_AUTH_SECRET}`;
  if (authHeader.length !== expected.length) return false;
  return timingSafeEqual(Buffer.from(authHeader), Buffer.from(expected));
}
```

### BASIC — Basic-auth validation

Adobe sends: `Authorization: Basic <base64(username:password)>`

```typescript
function validateNotifyBasicAuth(req: Request): boolean {
  const authHeader = req.headers['authorization'] ?? '';
  if (!authHeader.startsWith('Basic ')) return false;
  const decoded = Buffer.from(authHeader.substring(6), 'base64').toString('utf8');
  const expected = `${process.env.NOTIFY_USERNAME}:${process.env.NOTIFY_PASSWORD}`;
  return timingSafeEqual(Buffer.from(decoded), Buffer.from(expected));
}
```

### OAUTH2_CLIENT_CREDENTIALS / CUSTOM_TOKEN — token validation

For these types Adobe fetches a token from **your** token endpoint and replays it as `Authorization: Bearer <token>` (or a custom header). You therefore validate **your own** issued token — do not compare against a static secret. Reuse your existing identity/token layer (verify signature + issuer + audience + expiry against your OAuth server / JWKS, or call your introspection endpoint):

```typescript
// Pseudocode — wire to your existing token verifier (JWKS/introspection).
async function validateNotifyToken(req: Request): Promise<boolean> {
  const authHeader = req.headers['authorization'] ?? '';
  if (!authHeader.startsWith('Bearer ')) return false;
  const token = authHeader.substring(7);
  // Validate with YOUR identity layer (the same one Adobe pulled the token from):
  //   verify signature against your JWKS, check issuer/audience/expiry,
  //   or call your token-introspection endpoint.
  return verifyWithOwnIdp(token); // throws/returns false on invalid
}
```

There is no Adobe-specific secret to store for these two types — only your own token-validation config (issuer/JWKS/audience).

---

## HTTPS Requirements

- Your Notify endpoint must use HTTPS (TLS 1.2+)
- Your backend's Adobe API calls go to HTTPS Adobe endpoints — use a standard HTTP client that validates TLS certificates
- Do not disable certificate validation in any environment (not even in development)

---

## IP Allowlisting (Stage Only)

Adobe's stage environment requires your server's egress IPs to be allowlisted. Provide your outbound IP range(s) to Adobe partner engineering before testing on stage.

Production does not require IP allowlisting from your backend. (Your Notify endpoint on production may need to allowlist Adobe's egress IPs — check with Adobe partner engineering.)

---

## Logging Security

**Never log:**
- `client_secret`
- `access_token` values
- `ADOBE_NOTIFY_AUTH_SECRET`
- Full `Authorization` header values

**Always log (safe):**
- HTTP status codes
- `partner_reference_id`
- Request timestamps and latencies
- Error codes from response bodies
- Whether auth validation passed/failed (without logging the actual credentials)

---

## Checklist

- [ ] `.env` is in `.gitignore`
- [ ] `.env.example` is committed with all required variables but no real values
- [ ] Notify endpoint uses timing-safe auth comparison
- [ ] No Adobe credentials referenced in mobile/web source code
- [ ] IMS token never logged or returned to frontend
- [ ] Stage IP allowlist submitted to Adobe partner engineering
- [ ] TLS certificate validation enabled on all HTTP clients
