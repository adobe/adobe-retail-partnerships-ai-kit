---
offered_product: "TODO"   # must match OFFER_PROFILE.md — NEVER default to Adobe Express
last_updated: "<fill: YYYY-MM-DD>"
---

# Terminology — Shared Context

*Partner-facing wording and product-naming rules (card-model
[§4.4](../../../manual/methodology/card-model.md)). Every generated label, heading, and button
string is drawn from this file so the UI reads in the **partner's own voice**.
Derived from the partner's words captured in
[`OFFER_PROFILE.md`](./OFFER_PROFILE.md); confirm anything ambiguous with the
partner. See [`../../../manual/methodology/verification.md`](../../../manual/methodology/verification.md#clarify-before-you-build).*

> Any value left as `TODO` / `<fill>` / `{token}` forces a **STOP-and-ask**
> before writing UI copy (mirrors the [`OFFER_PROFILE.md`](./OFFER_PROFILE.md)
> gate).

---

## 1. Partner-facing wording

*The exact copy/label to render for each UI element. Use the partner's real
strings — not the kit's or Adobe's defaults. Add rows for every screen state
that carries copy (offer detail, activating, active, already-active, cancel
dialog, error, etc.).*

| UI element | Exact copy / label |
|---|---|
| Offer / entitlement name (as shown to user) | `{offered_product}` — TODO |
| Claim / activate button | `<fill>` — TODO |
| Manage subscription action | `<fill>` — TODO |
| Cancel action | `<fill>` — TODO |
| Cancel-confirmation dialog title | `<fill>` — TODO |
| Cancel-confirmation dialog body | `<fill>` — TODO |
| Active-status label | `<fill>` — TODO |
| Cancelled-status label | `<fill>` — TODO |
| "What you get" / benefits heading | `<fill>` — TODO |
| Benefit tile title(s) | `<fill>` — TODO |
| Error / retry message | `<fill>` — TODO |

## 2. Product-naming rules

*How the offered product is named across the UI: full name vs short form, casing,
trademark/®/™ treatment, and any strings the partner is contractually required
to use (or forbidden from using). Cite the partner source where possible.*

- **Canonical product name (first/prominent use):** `<fill>` — TODO
- **Short form (repeat use, tight layouts):** `<fill>` — TODO
- **Casing / trademark rules:** `<fill>` — TODO
- **Do-not-use strings:** `<fill>` — TODO

## 3. Rule — do not default the product name

> **Labels MUST NOT default to "Adobe Express."** The product name used anywhere
> in generated copy must come from **`offered_product` in
> [`OFFER_PROFILE.md`](./OFFER_PROFILE.md)**, confirmed with the partner. If that
> field is still a placeholder, **STOP and ask** — never fall back to Adobe
> Express or any other product. "Adobe Express" in any spec or mock is one
> example, not the target (verification rules 7–8 in
> [`../../../manual/methodology/verification.md`](../../../manual/methodology/verification.md)).
