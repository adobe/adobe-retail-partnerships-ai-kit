# Conceptual Guide

**Read this before anything else.** It explains what the kit does and the model
behind it. The workflow makes far more sense once that model is clear.

---

## What the kit does

The Adobe Integration APIs let you offer an Adobe product — Photoshop or Adobe
Express, for example — to your own customers, directly inside your app or website.
Customers claim the product, check whether their subscription is active, and cancel
it, without ever leaving your product.

Building that integration is real engineering work. It spans your backend, your
mobile app, and your website, each with its own stack and conventions. This kit
builds it for you.

It is not a library you install, and not a template that emits fixed code. It is a
**methodology plus a set of skills** that direct a coding agent — any capable AI
assistant — to do two things:

1. **Learn your codebase** — how your app is structured, routed, configured, and styled.
2. **Write the Adobe integration into it** — in your own stack, following your own patterns.

The result is working integration code, written directly into your app, reviewed at
each step, with you in control throughout.

---

## Who does what

Two sides contribute. **Adobe**, through this kit, defines what each feature does
and how it should behave. **You** decide how it fits your codebase, supply your
credentials, and approve each step. You do not author the feature specs — you
review them, then run the kit against your own app.

| Adobe provides (through this kit) | You provide |
|---|---|
| The methodology and the skills | Your app — or, to evaluate, the kit's built-in sample app |
| The Adobe API specs and each feature's intended behavior | Your Adobe credentials, added at the final step |
| A ready-to-run sample app | Review and approval at each step |

---

## The offered product is yours to choose

Different partners offer different Adobe products, so the kit never assumes one.
Wherever these docs say "Adobe Express," treat it as an example. During analysis
the kit asks which product you are offering and what you call it, then uses that
everywhere it writes copy. Where something is unknown, it asks — it does not guess.

---

## How it keeps you safe

Two rules, enforced without exception:

- **Credentials stay on your backend.** Every call to Adobe is made server-side.
  Adobe keys never reach a mobile app or a browser.
- **Nothing is reported done until it is verified.** No feature is marked complete
  until its code has been built, tested, and confirmed to be wired correctly
  between the app and its backend.

---

## What the kit does not do

- It does not deploy or configure CI/CD. Generated code lands in your repo;
  shipping it is your call.
- It does not skip review. Engineer review of the generated code is expected, not
  optional.
- It does not copy its own files into your app. Only the integration code — and its
  design documents — is written there.
- It does not assume a language, framework, or product.

---

## Two ways to use it

- **Mode A — build the integration.** The kit writes the Adobe integration into an
  app, in that app's own stack. By default it targets the built-in sample app, so
  you can see the full flow with only your credentials; or you point it at your own
  repositories.
- **Mode B — rebrand from designs.** Starting from an app that already has the
  integration, the kit rebuilds the screens to match your design mockups, leaving
  the integration logic untouched. This is primarily an Adobe-team task.

Both operate on a real app and follow the same security and verification rules, and
they compose: build the integration, then rebrand the screens.

---

## Next steps

Once the model is clear, continue with the **[Quick Start](quick-start.md)**. For
the methodology behind it, see **[the workflow](methodology/workflow.md)** and
**[the two modes](methodology/modes.md)**.
