# Quick reference

Quick reference for the commands, paths, and credentials you'll use. For the full walkthrough, see [Quick Start](quick-start.md).

## The steps, and what each one is called

| Command | What it does |
|---|---|
| `analyze-partner-codebase` | Reads each part of your app and writes up what it found; asks which product you're offering; flags any risky direct-to-Adobe calls |
| `generate-adobe-clients` | Builds the backend pieces that talk to Adobe — the login-token client, then the API client |
| `generate-lld <feature>` | Writes the plan — backend first, then screens — for you to review |
| `implement-feature <feature>` | Writes the actual code for one feature |
| `generate-env-config` | Sets up configuration and an example settings file |
| `generate-tests` | Writes tests for the new code |
| `generate-integration-checklist` | Produces a readiness checklist for onboarding |
| `build-app-from-mocks` | Rebrands an app's screens to match your design mockups |

The features: claim a product · check a subscription · cancel a subscription · receive Adobe's status updates.

## Where things end up

| Thing | Where it lives | In your app? |
|---|---|---|
| What the kit learned about your app | in the kit | No |
| The plan documents | in your app, under `docs/ai-kit/` | Yes |
| The new integration code | in your app | Yes |

The kit's own files are never written into your app.

## Registering your app

| Command | Use it when |
|---|---|
| `./INSTALL.sh /path` | Your whole app is in one repository |
| `./INSTALL.sh --backend P --web P …` | Different parts live in different repositories |

It only records the paths; it does not change your app. For more on multi-repo setups, see [the two modes](methodology/modes.md#surface-registry-and-multi-repo-resolution).

## Your Adobe credentials (added at the end)

`CLIENT_ID`, `CLIENT_SECRET`, `SCOPES`, `OFFER_ID`, `X_API_KEY` — Adobe issues these during onboarding. The kit reuses whatever names your code already uses for them, and falls back to the standard Adobe names only if you do not have your own. Credentials are read from your normal config or secret store, never written into the code, and never sent to the app or website.

## Two guarantees the kit keeps

- It asks which product you are offering instead of assuming, so the wrong product name never appears on your screens.
- It never reports a feature as working until it has built it and run the tests.

## If something looks wrong

| What you see | Most likely reason |
|---|---|
| A request comes back "not found," with nothing in the server log | Your app is calling a slightly different address than the backend expects |
| Adobe rejects it with "invalid offer" | The sample product ID wasn't replaced with your real one |
| Subscriptions never turn "active" | The status-update webhook wasn't registered with Adobe during onboarding |
| The rebranded screens look generic | The mockups weren't followed closely enough |
| A missing setting looks like an Adobe outage | A configuration value isn't set — it should read as a config problem, not an Adobe failure |

---

For the full rules, see [how the kit verifies its work](methodology/verification.md).
