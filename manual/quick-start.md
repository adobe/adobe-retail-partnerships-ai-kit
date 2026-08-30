# Quick Start

This is the complete walkthrough. If you have not read the [Conceptual Guide](conceptual-guide.md) yet, read it first.

First, connect the kit to your coding assistant. For Claude Code, follow [the setup guide](setup/claude-code.md). For any other assistant, point it at the files in the `skills/` folder and follow the same order shown below.

You do not need Adobe credentials to generate the integration code. You need them only at the final step, to run against Adobe. Have them ready for that step — `CLIENT_ID`, `CLIENT_SECRET`, `SCOPES`, `OFFER_ID`, `X_API_KEY`. Adobe issues all of these during onboarding.

## Running against the built-in reference app

The kit ships with a small reference app: a working app that has no Adobe features yet. A single command adds one:

```text
implement-feature claim-product
```

That single command runs the whole sequence: it reads what it needs about the reference app, plans the backend and the screens, writes the code, and tests it, then reports what it built. It still checks which Adobe product you are offering, and you add your real credentials afterward to run it live.

This is the fastest way to see the kit work, and the best way to get familiar with it before you point it at your own app.

## Running against your own application

When you are ready to work on your own code, tell the kit where it lives. This only records the location; it does not change your app:

```bash
./INSTALL.sh /path/to/your-app
```

If different parts of your application live in different repositories, register each one:

```bash
./INSTALL.sh --backend /path/to/backend --web /path/to/web \
             --ios /path/to/ios --android /path/to/android
```

Whatever your app looks like — a full backend plus web and mobile, a single mobile app, or a website alone — the kit treats each part as equally important. Mobile-only and web-only partners are fully supported. Your stack does not have to match the reference app's (Node and Flutter): the kit reads Java/Spring, Python, Go, Ruby on Rails, .NET, and more. It will not wrongly conclude you have no backend just because your code looks different from the example.

Once your app is registered, the kit runs a more careful, step-by-step version of the same work. Because it is now writing into your production code, it pauses to show its plan and get your approval before each stage. Run these steps in order:

| Step | What happens | Command | You review? |
|---|---|---|---|
| Setup | The kit reads your app and writes up what it found | `analyze-partner-codebase` | Yes |
| Setup (once) | It designs the shared pieces that talk to Adobe — the IMS and Retail API clients every feature reuses — you approve the design, then it builds them | `generate-adobe-clients` | Yes |
| Per feature — plan | It writes the plan, backend first then screens (you approve before any code) | `generate-lld <feature>` | Yes, at two points |
| Per feature — build | It writes the code from the approved plan | `implement-feature <feature>` | — |
| Finish | It adds configuration, tests, and a readiness checklist | `generate-env-config`, `generate-tests`, `generate-integration-checklist` | — |

The two "Setup" steps run once for the project. The two "Per feature" steps repeat for each feature — and within each feature the plan (`generate-lld`) always comes before the code (`implement-feature`).

The features you can build: claim a product, check a subscription, cancel a subscription, and receive Adobe's status updates. Start with claiming a product, the main flow, then add the others the same way.

Where the output goes: the new integration code and its plan documents are written into your app. Everything else — all of the kit's own files — stays in the kit. Your app is not cluttered with anything it does not need.

The process is interactive and transparent. As it works, the kit asks for the few things it cannot tell from your code: which Adobe product you are offering and what you call it, and whether you have your own screen designs (covered just below). Before each stage it shows you something to review and waits for your approval.

### Reviewing the plan

Before writing any code, the kit produces a short plan — first for the backend, then for the screens — and saves it in your own repository, under `docs/ai-kit/LLD/`. It is a plain document you open and read like any other file. The kit prints a summary and a short checklist of what to look for, then waits. You can approve it, fix a small detail by editing the document yourself, or ask it to redo the plan if something is wrong at a deeper level. It writes code only after you approve. These are the checkpoints described in [the review checkpoints](decision-gates.md).

### Screen designs: your own, or the built-in defaults

When the kit builds the claim and subscription screens into your app, you will usually want them to match your product, not a generic layout. It asks at the start whether you have your own screen designs (mockups):

- **If you do**, put them in a folder under `mocks/` (copy `mocks/_template/` and fill in `manifest.md` — the spec that tells the kit what each screen means: your screens, tagged by role, plus your brand colors and wording) before you run the build. Screens can be exported images, a raw slide deck/PDF, or a Figma link — see `mocks/README.md` for the exact input formats. The kit reproduces your designs faithfully, using your own UI components.
- **If you do not**, it builds clean, working screens from its built-in default layouts (`knowledgebase/ui-mocks/defaults/`), still using your existing components and your wording, never an outside design system. You can restyle them to your brand later with the rebrand step below.

In either case, the kit reports which option it used.

## Rebranding an application to your design

If you have design mockups and want an app that matches your brand, the kit can rebuild the screens to match your designs while keeping the Adobe integration working underneath. This runs on an app that already has the integration — by default, the one the steps above just produced.

Put your mockups in a folder under `mocks/` (copy `mocks/_template/` and fill in the short `manifest.md`: your name, the product, the screens, your brand colors), then run:

```text
build-app-from-mocks
```

The kit reproduces each screen faithfully from your designs instead of producing a generic layout.

## After the build

1. Enter your real product ID and Adobe credentials where the kit tells you to — a sample ID won't work against Adobe.
2. Register your status-update webhook and return link with Adobe during onboarding. The kit prints exactly what to give them.
3. Run the readiness checklist and your app's own tests.

---

Next: [the review checkpoints](decision-gates.md) · [the quick reference](reference.md).
