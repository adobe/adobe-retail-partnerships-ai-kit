---
offered_product: "TODO"          # e.g. Adobe Express | Photoshop | Lightroom | Acrobat Pro | Firefly — NEVER default to Adobe Express
offer_id: "TODO"                  # the Adobe-assigned offer_id (see below if multiple)
notify_hosted_by_partner: "TODO"  # yes | no
notify_inbound_auth_type: "TODO"  # STATIC | BASIC | CUSTOM_HEADERS | OAUTH2_CLIENT_CREDENTIALS | CUSTOM_TOKEN
last_updated: "<fill: YYYY-MM-DD>"
---

# Offer Profile — Shared Context

*The single source of truth for **what is being offered** in this engagement
(card-model [§4.1](../../../manual/methodology/card-model.md)). Confirmed **with the partner**,
never assumed or derived from a spec example. Every UI-touching step reads this
file; see [`../../../manual/methodology/verification.md`](../../../manual/methodology/verification.md#clarify-before-you-build).*

> **STOP-and-ask gate.** Any field below left as `TODO`, `<fill>`, `{token}`, or
> any placeholder value **forces a STOP-and-ask with the partner before any UI
> copy, label, heading, or offer wiring is written.** Do not guess, default, or
> proceed on a partial profile. See verification rules 7 and 8 in
> [`../../../manual/methodology/verification.md`](../../../manual/methodology/verification.md).

---

## 1. Offered Adobe product

> ⚠️ **NEVER default to Adobe Express.** The offered product is a **variable**
> and must be **confirmed with the partner**. Adobe has many products a partner
> may offer (Adobe Express, Photoshop, Lightroom, Acrobat Pro, Firefly, Creative
> Cloud, …). Any "Adobe Express" you see in a spec or example is *one example*,
> not the target. If unconfirmed, leave `TODO` and ask.

*Capture the exact product name to use in all generated copy, headings, and
labels.*

- **Product name:** `{offered_product}` — TODO
- **Product family / edition (if relevant):** `<fill>` — TODO
- **Confirmed with partner?** `<fill: yes/no + date/source>` — TODO

## 2. Offer ID(s)

*The Adobe-assigned `offer_id`(s) for this engagement. One offer per product/plan.
Never hardcode these in routes — they are resolved from config (verification
rule 6). List every offer in scope.*

| `offer_id` | Applies to (product / plan / surface) | Notes |
|---|---|---|
| `{offer_id}` | <fill> | TODO |
| TODO | TODO | TODO |

## 3. Partner terminology

*The partner's **own words** for each core concept. Use these verbatim in
generated UI copy — do not substitute Adobe's or the kit's vocabulary. This
table is the source that [`TERMINOLOGY.md`](./TERMINOLOGY.md) expands into UI
labels.*

| Concept | Partner's word |
|---|---|
| offer | `<fill>` — TODO |
| benefit | `<fill>` — TODO |
| manage | `<fill>` — TODO |
| claim | `<fill>` — TODO |

## 4. Surfaces in scope

*Which surfaces this offer appears on. Must be consistent with
[`SURFACE_SCOPE.md`](./SURFACE_SCOPE.md). Mark each in / out.*

| Surface | In scope for this offer? |
|---|---|
| backend | `<fill: yes/no>` — TODO |
| mobile | `<fill: yes/no>` — TODO |
| web | `<fill: yes/no>` — TODO |
| ios | `<fill: yes/no>` — TODO |
| android | `<fill: yes/no>` — TODO |

## 5. Notify strategy

*Whether the partner hosts the Adobe→partner Notify webhook, and — if so — the
inbound-auth type they **registered with Adobe at onboarding**. Adobe replays
exactly that mechanism on every call, so validation must match it (verification
rule 7). If the mechanism is unclear or not one of the five listed types (e.g.
mTLS / gateway-terminated), leave `TODO` and **ask** — do not force-fit. See
[`../../../knowledgebase/api-spec/notify-api.md`](../../../knowledgebase/api-spec/notify-api.md).*

- **Does the partner host the Adobe→partner Notify webhook?** `<fill: yes/no>` — TODO
- **Registered inbound-auth type:** `{notify_inbound_auth_type}` — one of
  `STATIC` / `BASIC` / `CUSTOM_HEADERS` / `OAUTH2_CLIENT_CREDENTIALS` /
  `CUSTOM_TOKEN`. TODO
- **Where the auth credential/config lives (config key or identity layer):**
  `<fill>` — TODO *(never a hardcoded or fabricated value)*
- **Notify endpoint path (if hosted):** `<fill>` — TODO
