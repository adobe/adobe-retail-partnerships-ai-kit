# State Management — {surface}

> _Client-side state for this UI surface. Fill every `<fill>` / `TODO`. See
> [card-model §3.2](../../../manual/methodology/card-model.md)._

## Overview

_State the state library and how many stores this surface has._

- **State library:** `<fill>` (e.g. Riverpod/Bloc, Redux/Zustand, ObservableObject, ViewModel)
- **Store count:** `<fill>`

## 1. <Store name>

_One numbered section per store. Fill each field; keep State shape as a short
field list, not full code._

- **State shape:** `<fill>`
- **Actions:** `<fill>`
- **Init:** `<fill>` (when/where it is created and seeded)
- **Persistence:** `<fill>` (in-memory / persisted; storage key if any)

## 2. <Store name>

- **State shape:** `<fill>`
- **Actions:** `<fill>`
- **Init:** `<fill>`
- **Persistence:** `<fill>`

## Session Seed for partner_reference_id

> _Dedicated: where the session provides the identity used to derive/carry
> `partner_reference_id`. This surface does NOT mint the id from Adobe — it
> carries the partner's own per-user identity, from which the backend derives
> the id. Recall `partner_reference_id` is permanent per (customer, product)
> pair._

- **Session identity source:** `<fill>` (e.g. logged-in user id, account token claim)
- **Where it is read:** `<fill>` (store/service/file)
- **How it is passed to the backend:** `<fill>`
- **Notes:** TODO

## Storage Key Registry

_Every persisted key this surface writes. TTL blank for non-expiring keys._

| Key | Storage | Contents | TTL |
|---|---|---|---|
| `<fill>` | `<local/secure/session>` | TODO | `<fill>` |

## Cache Strategy

_How cached client state is invalidated/refreshed — especially subscription
status after a claim or cancel, and on return-from-Adobe._

- TODO
