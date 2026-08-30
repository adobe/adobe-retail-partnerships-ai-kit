# Service Cards

This directory holds the kit's **service cards** — the durable, machine-readable
description of each surface of a partner's system. See
[`../manual/methodology/card-model.md`](../manual/methodology/card-model.md) for the full model.

Backend and every UI surface (`mobile`/`web`/`ios`/`android`) are equally
first-class card sets — the kit produces exactly the ones the partner's app
actually has. A mobile-only partner (no separate backend or web repo of their
own) gets a full, primary-path `mobile/` card set; it is never a secondary case.

## Layout

- **`_templates/`** — the blank, fillable card templates (committed). The
  **analyze** step copies and fills them per partner.
- **`mobile/`, `web/`, `ios/`, `android/`, `backend/`, `shared/`, `security/`** —
  the *filled* card sets for the current engagement. These are **generated
  output** and are gitignored (per-engagement, re-derivable).

## Template sets

| Template set | Fills | Files |
|---|---|---|
| `_templates/mobile/` | `mobile/` **or** `web/` **or** `ios/` **or** `android/` | 9 cards (see card-model §3.2) |
| `_templates/backend/` | `backend/` | 8 cards (see card-model §3.1) |
| `_templates/shared/` | `shared/` | `OFFER_PROFILE`, `TERMINOLOGY`, `SURFACE_SCOPE` |
| `_templates/security/` | `security/` | `DIRECT_CALLS_AUDIT` (only when findings exist) |

**One UI template set, reused per surface.** The `_templates/mobile/` set is
surface-neutral — the analyze step fills it into whichever UI surface folders are
active (`mobile/` for a cross-platform app, or `web/` / `ios/` / `android/` for
separate surfaces). `mobile` is mutually exclusive with `ios`/`android`.

## How cards are produced and consumed

1. The **analyze** stage detects each surface and fills a card set per surface,
   plus `shared/` context, plus `security/DIRECT_CALLS_AUDIT.md` if findings
   exist.
2. Review gates **DG-1** (backend cards) and **DG-2** (UI cards) approve them.
3. The **backend LLD** and **UI LLD** stages read the cards.
4. The **implement** and **verify** stages read the cards for the "how" and the
   authoritative verify commands.

See [`../manual/methodology/workflow.md`](../manual/methodology/workflow.md).
