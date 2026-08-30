# The review checkpoints

The kit never writes code into your app on its own. At a few points it stops, shows you what it found or what it is about to do, and waits for your approval. These are your checkpoints. No stage moves ahead until you are satisfied, and a mistake caught here, in a short document, is far cheaper to fix than one caught later in the code.

If you spot a problem, in most cases you edit the document the kit produced and continue. Only larger, structural issues require re-running the step.

There are four checkpoints, in two pairs. The kit calls them **Decision Gates**
(**DG-1** through **DG-4**) — "DG" is just shorthand for Decision Gate.

## First pair: did the kit understand your app?

After the kit reads your code, it writes up what it found and pauses so you can confirm it is right.

For your backend, check that it got these right:
- how your backend talks to external services — timeouts, retries, and error handling,
- how incoming requests are authenticated, and whether your framework allows requests by default or blocks them (this decides how Adobe's status-update webhook is secured),
- where your subscription data is stored,
- the commands that build and test your backend.

For your screens — the mobile app, the website, or both — check that it got these right:
- how your screens fetch data (a mistake here is the most common cause of later bugs),
- how navigation and login protection work,
- which of your existing UI components it should reuse. It must build from your components and never bring in outside ones.

## Also, once per project: the shared backend-clients design

Before the first feature, the kit designs the two pieces every feature reuses — the IMS login-token client and the Retail API client — and stops to show you that design before building them. This runs once per project, not per feature, so it isn't numbered alongside DG-1..DG-4, but it's the same kind of checkpoint: review the design, approve or request changes, then the kit builds it.

## Second pair: is the plan correct, before any code?

For each feature, the kit writes a short plan — the backend first, then the screens — and stops on each one.

The backend plan. Check that the path from your app to Adobe and back makes sense, that every "we will reuse your existing X" points at something real, that errors are handled the way the feature is meant to behave, and that everything the feature promises is covered.

The screen plan. This is your last chance to catch a mismatch before code is written. Check that the screens call the backend exactly as the backend plan says, that the flow matches your mockups, that every situation is covered (loading, errors, nothing found, already active, cancelled), and that the wording uses your product name and your terms — not a generic "Adobe Express."

## After you approve

Once the plans are approved, the kit writes the code and then checks its own work. It confirms that your app and backend connect correctly (a mismatch here is the kind of bug that otherwise fails silently), that every screen situation is handled, and that each part builds and its tests pass. It won't report success on anything it hasn't verified.

---

In the more technical guides, these four Decision Gates are labeled DG-1 through DG-4:
DG-1 (backend service cards), DG-2 (UI service cards), DG-3 (backend plan), DG-4 (UI plan).
