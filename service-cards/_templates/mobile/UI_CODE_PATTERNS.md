# UI Code Patterns — {surface}

> _Conventions the generated screens on this UI surface MUST follow. Fill every
> `<fill>` / `TODO`. See [card-model §3.2](../../../manual/methodology/card-model.md)._

## 1. Naming & Structure

_File/class/component naming conventions and where new screens/components go.
Generated code must match these, not introduce a new scheme._

- **File naming:** `<fill>`
- **Component/class naming:** `<fill>`
- **New-screen location:** `<fill>`
- TODO

## 2. Existing Component Library

> **MANDATORY REUSE.** The generated UI MUST reuse this surface's existing
> component library. Generated screens must NOT introduce a new design system,
> component kit, or ad-hoc styling. List the concrete components below so a
> generator can pick from them.

| Component | Location | Use for |
|---|---|---|
| `<fill>` (e.g. Button) | `<fill>` | TODO |
| `<fill>` (e.g. Card) | `<fill>` | TODO |
| `<fill>` (e.g. Dialog/Modal) | `<fill>` | TODO |
| `<fill>` (e.g. Loading/Spinner) | `<fill>` | TODO |
| `<fill>` (e.g. Banner/Toast) | `<fill>` | TODO |

- **Design tokens / theme source:** `<fill>`
- **Rule:** if a needed component does not exist here, compose from existing
  primitives — do NOT pull in an external design system.

## 3. Form Patterns

_How forms/inputs are built and validated on this surface (validation library,
submit/disable pattern, error display)._

- TODO

## 4. Error Handling in Components

_How components render loading / empty / error / not-configured states. Every
integration screen must handle all states shown in the mocks._

- TODO

## 5. Test Patterns

_The surface's testing conventions: framework, widget/component test style, how
network is mocked, file location/naming. New code ships with tests._

- **Framework:** `<fill>`
- **Component/widget test style:** `<fill>`
- **Network mocking:** `<fill>`
- **Location / naming:** `<fill>`

## 6. Universal Principles

_Short, surface-agnostic rules every generated screen obeys._

- Reuse the existing component library (§2) — no new design system.
- Call the partner backend only — never Adobe directly.
- Handle every screen state present in the mock (loading / active / already-active
  / cancelled / not-found / error).
- Ship unit/component tests alongside implementation.
- TODO
