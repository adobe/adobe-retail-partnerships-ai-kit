---
offered_product: "PLACEHOLDER — ask before you build"
offer_id: "PLACEHOLDER — ask before you build"
notify_hosted_by_partner: "PLACEHOLDER — ask before you build"
notify_inbound_auth_type: "PLACEHOLDER — ask before you build"
last_updated: "2026-07-16"
---

# Offer Profile — Shared Context (base-ref-app)

*This is the kit's bundled reference app — there is no real partner to ask yet.
Every field below is a deliberate, explicit **placeholder**, not a guess. This
is the "clarify before you build" gate
([`../../../manual/methodology/verification.md`](../../../manual/methodology/verification.md#clarify-before-you-build)) working
correctly: it still fires downstream (any UI-copy-writing step reads this file
and MUST stop and ask before writing copy while these values remain
placeholders) — the Fast path changes how much process wraps the LLD/review
steps, not whether the offer must be confirmed.*

> **STOP-and-ask gate — unchanged.** Any field below is `PLACEHOLDER`. This
> forces a STOP-and-ask with whoever is running the kit before any UI copy,
> label, heading, or offer wiring is written (verification rules 7–8). Fill
> these in with **your own** real Adobe onboarding values (product name,
> `offer_id`, terminology) — never copy a value from a knowledgebase spec
> example.

---

## 1. Offered Adobe product

> ⚠️ **NEVER default to Adobe Express.** Adobe Express appears elsewhere in
> this kit's specs purely as a running example — it is not this engagement's
> answer just because it's bundled with the kit.

- **Product name:** `PLACEHOLDER` — ask before you build
- **Product family / edition (if relevant):** `PLACEHOLDER`
- **Confirmed with partner?** No — this is the bundled base app; there is no
  partner yet. Fill this in once you (or a real partner) supply real Adobe
  onboarding values.

## 2. Offer ID(s)

| `offer_id` | Applies to (product / plan / surface) | Notes |
|---|---|---|
| `PLACEHOLDER` | — | Adobe-assigned at onboarding; not fabricated here. |

## 3. Partner terminology

| Concept | Partner's word |
|---|---|
| offer | `PLACEHOLDER` |
| benefit | `PLACEHOLDER` |
| manage | `PLACEHOLDER` |
| claim | `PLACEHOLDER` |

## 4. Surfaces in scope

*Unlike the offer fields above, this is a structural fact about the bundled
app, not a business decision — safe to record concretely.*

| Surface | In scope for this offer? |
|---|---|
| backend | yes — `base-ref-app/bff` |
| mobile | yes — `base-ref-app/lib` (compiles to iOS + Android) |
| web | yes — same codebase as mobile, compiled to web |
| ios | no — native iOS is not a separate surface here (Flutter covers it) |
| android | no — native Android is not a separate surface here (Flutter covers it) |

## 5. Notify strategy

- **Does the partner host the Adobe→partner Notify webhook?** `PLACEHOLDER` —
  ask before you build.
- **Registered inbound-auth type:** `PLACEHOLDER` — one of `STATIC` / `BASIC` /
  `CUSTOM_HEADERS` / `OAUTH2_CLIENT_CREDENTIALS` / `CUSTOM_TOKEN`. Note: this
  app's only existing inbound machine-caller check (`/admin`'s
  `x-gw-ims-client-id` gate) is a locally-configured shared secret, not a real
  registrable mechanism — see
  [`../backend/CONTRACTS.md`](../backend/CONTRACTS.md) Overview. Do not treat
  it as an answer to this field.
- **Where the auth credential/config lives:** `PLACEHOLDER`
- **Notify endpoint path (if hosted):** `PLACEHOLDER`
