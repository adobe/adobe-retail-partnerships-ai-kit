---
name: build-app-from-mocks
description: >
  Produce a fully branded, runnable partner app from partner-supplied mocks by reproducing the partner's UI on top of a reference app that already contains all the Adobe integration capabilities (claim, find-subscription, cancel, notify). Every partner's UI is different — this is a COMPLETE UI rebuild to match their mocks, not a color/logo swap of the reference app.
---

# Skill: /build-app-from-mocks

Produce a fully branded, runnable partner app from partner-supplied **mocks** by **reproducing the partner's UI** on top of a reference app that already contains all the Adobe integration capabilities (claim, find-subscription, cancel, notify). **Every partner's UI is different — this is a COMPLETE UI rebuild to match their mocks, NOT a color/logo swap of the reference app.**

> **Core principle — rebuild the UI to the mocks; reuse ONLY the Adobe integration.** The reference app is ONE Flutter codebase (`lib/` → web + iOS + Android) plus a Node/TypeScript Express BFF (`bff/`). The **entire UI — screens, layout, navigation model, components, theme, copy, assets — is rebuilt to match the partner's mocks, which may look nothing like the reference app** (a sidebar dashboard, a bottom-nav mobile app, an e-commerce grid, a carousel home — whatever the mocks show). What is **REUSED, UNTOUCHED** is only the Adobe **integration logic**: `lib/services/**`, `lib/models/**`, every `*_provider.dart`, the BFF (`bff/`), and the workflow/claim/subscription/notify wiring + routes. So: any layout is valid; the partner's screens are the target to reproduce ~100%; only the Adobe plumbing is fixed. Do not rewrite that plumbing, and do not ship a generic app that ignores the mocks. Wire the partner's own "offer/get-started" control to the reused claim flow → `experience_url`.

This skill: resolves mocks → extracts design tokens → references the capability app read-only → materializes/updates the branded app in `app/` → rebuilds the UI (theme, brand, copy, layout) → configures the requested surfaces → **verifies by building and running** → reports a per-screen mock-vs-build diff.

---

## Inputs

### How a partner provides & names mocks (the input format)

The input format is defined by `mocks/README.md` and `mocks/_template/`, and the authoritative per-form ingestion procedure is `knowledgebase/mock-to-app/mock-ingestion.md`. **This skill must stay consistent with all three.** In short:

- **One folder per partner.** The partner copies the template — `cp -r mocks/_template mocks/<partner>` — giving a folder with four parts: `manifest.md` (the spec), `screens/` (screen images **or** the deck), `brand/` (logo/asset files), and `source/` (optional raw deck/notes). There is **no flat `mocks/` drop** and no per-feature filenames at the `mocks/` root — everything lives under `mocks/<partner>/`.
- **`manifest.md` is REQUIRED.** It is the authoritative spec the skill reads: partner name, wordmark, **surfaces requested** (web / iOS / android / any combination), offered product/offer id, a **screen → role → what-the-partner-calls-it map** (rows listed in journey order), the partner's own **offer/benefit terminology**, and optional brand tokens (auto-detected from the screens if left blank). Two fields matter most for correct placement: (a) each screen's **Role** (`login` / `landing` / `offer` / `benefits` / `manage` / `other` / `adobe-hosted` — the shared vocabulary defined at the top of the template); the `offer` role is where the offer is shown pre-claim, the `benefits` role is where an active subscription surfaces as an owned benefit, and `adobe-hosted` screens are NEVER built. Derive each screen's app route and whether to reproduce it from its Role (per the template's Role table) rather than expecting the partner to specify them. (b) the **"Your words"** block — the partner's own words for the offer and for an owned benefit, plus the CTA label. Use those words in headings/labels (Step 4 item 5); Adobe branding only on the offer card itself. Blank template: `mocks/_template/manifest.md`. Do not assume any named partner example ships with the kit.

The partner supplies screens in **one of three forms** (detected in the order below; see `mock-ingestion.md` for the per-form procedure):

1. **`--figma <url>`** — a Figma file/frame URL (the Figma MCP must be authenticated). Most exact: frames → screens, Variables/styles → tokens, image nodes → assets. Step 1a.
2. **Exported screen images in `mocks/<partner>/screens/`** — one PNG per screen, each the **full screen as the user sees it** (not a crop). Name them **in journey order**: `slide-1.png`, `slide-2.png`, … (e.g. PowerPoint/Keynote *File → Export* per slide). Screen-keyword names (`landing*`, `offer*`, `login*`, `benefits*`, `manage*`) are also accepted when order is implicit, but the `slide-N.png` ordered convention is preferred and matches `_template/manifest.md`. Step 1c.
3. **A raw `.pptx`/PDF in `mocks/<partner>/source/`** — the skill RENDERS each slide/page as a **composite** (base screenshot + overlaid logos/cursors/callout text, via the slide XML offsets; Pillow + cairosvg) into `mocks/<partner>/screens/slide-N.png`. It **never** treats a single raw embedded media file (`ppt/media/imageN.*`) as the mock — that is only one layer and misses the overlays that carry meaning (e.g. an offer logo dropped on a specific tile). Steps 1b·a (PPTX) / 1b (PDF).

If more than one form is present, ingest all and merge (precedence in `mock-ingestion.md`). When a `manifest.md` exists, **the manifest's screen map and tokens win** over guesses from the files.

### Step 0 — Resolve inputs (STOP early if ambiguous — manual/methodology/verification.md Protocol rule 8)

1. If `--figma <url>` was passed → Figma path (Step 1a). Else resolve the partner folder `mocks/<partner>/`: **naming the partner is the expected path** — the kit accumulates many partner folders over time, so "exactly one folder exists" is rarely true in practice. If the user named a partner whose folder does **not** exist yet, **create `mocks/<partner>/` from `mocks/_template/`** and proceed to fill it (step 2 below). If no partner was named: use the sole folder when exactly one exists, otherwise **ask the user which partner**.
2. If a partner folder exists but its `manifest.md` is still the unfilled template, **ask the partner to fill it** (or fill it from the screens + their answers) before generating — the manifest is required. If no partner folder exists and no `--figma`, **STOP**: "Add a mock set under `mocks/<partner>/` (copy `mocks/_template/`, fill `manifest.md`, drop screens in `screens/` or a deck in `source/`), or pass `--figma <url>`. See `mocks/README.md`."
3. **Read the manifest fully.** Record: partner name, **the Adobe product being offered** (e.g. Adobe Express, Photoshop, Lightroom, Acrobat Pro, Firefly — **never assume Express**), the **`offer_id`** for it, **surfaces requested**, brand tokens (note any marked *approx*), and the screen map. **If the manifest does not state which Adobe product is offered (or its `offer_id`), STOP and ask the partner** — the product name and the partner's terminology drive every heading/label/CTA, so guessing produces wrong copy. If the surfaces or the screen→feature mapping are unclear, **ask** before generating.
4. **Treat the mocks as a user JOURNEY, not loose screens.** Order them into the flow (e.g. dashboard/landing → offer → [Adobe-hosted redeem/consent/product] → back to a status screen). The **landing** screen — what the user sees right after login — becomes the app's **home route**, and must be reproduced faithfully (Step 5b). **Weave the Adobe offer into wherever the deck places it** (a card/banner on the landing, or a dedicated offer page). Screens served by Adobe at `experience_url` (consent, sign-in, product) are **NOT built** — the app only redirects to them and handles the return. If the deck shows two partner pages (e.g. a dashboard AND a recommendations page) and it's unclear which is the landing, **ask** rather than guess.

5. **Speak the PARTNER's language, not Adobe's — for both the offer and the claimed/active subscription.** The Adobe product is one of the *partner's* offers/benefits; surface it inside the partner's own section using the partner's own terminology from the mocks — e.g. **"Your Benefits", "Rewards", "Memberships", "Subscriptions", "Claimed Offers"** — whatever the manifest/mock calls it. **Do NOT invent a generic "Adobe" section/heading.** Adobe branding appears ONLY where the mock shows it (typically the offer card's own logo/wordmark); the section header, surrounding chrome, and status labels stay in the partner's voice. Concretely: **before claim**, the offer sits as one item in the partner's offers/benefits area; **after the subscription is Active** (the Notify webhook flips it — Mode A), that *same* area shows it as an owned benefit (e.g. under "Your Benefits" with an "Active" chip) in the partner's wording — never a standalone "Your Adobe Subscription" block unless the mock explicitly shows one. The manifest's screen map names this section and what the partner calls it.
   - **State drives the ACTION (load live status, then branch).** The benefit/offer entry must check subscription status and switch: **ACTIVE → NO claim/offer CTA — show a "Manage" affordance routing to the subscription/manage screen**; NOT_FOUND / CANCELLED → the claim CTA; PENDING → a non-interactive pending chip. Load status when the home/entry builds (e.g. the subscription provider's `load()`), then render Claim-vs-Manage from it. Do not show "Claim"/"Get started" on an already-active benefit.

Read `knowledgebase/mock-to-app/mock-ingestion.md` before ingesting raw files — it is the authoritative per-form ingestion reference (Figma / PPTX-composite / images / PDF), and defines the same input format, naming convention, pixel-sampling rule, and journey-mapping rule as this skill.

---

## Step 1 — Input Ingestion

### Step 1a — Figma
Authenticate the `mcp__claude_ai_Figma` tools first; if auth fails, tell the user and stop. Read frames (→ screens), components, local styles, and Variables (→ tokens). Export brand assets (logo/wordmark/hero) to `partner-brand/<partner>/assets/`.

### Step 1b·a — PowerPoint (.pptx) — render the COMPOSITE slides, not raw media
A `.pptx` slide is a **composite** (a base screenshot + overlaid logos/cursors/callout text). Do **NOT** treat the raw embedded media (`ppt/media/imageN.*`) as the mock — a single embedded image is only one layer, so it misses overlays (e.g. an offer logo placed on a tile). Instead **render each slide as the user sees it**: unzip the pptx, read each `ppt/slides/slideN.xml` for every `<p:pic>` (its `r:embed` → `ppt/media/...` via the slide rels, plus its `<a:off>`/`<a:ext>` position+size in EMU) and the slide size from `presentation.xml`, then **composite** the layers (Python + Pillow; rasterize any `.svg` with `cairosvg`) onto a slide-sized canvas at the scaled offsets, and save **`mocks/<partner>/screens/slide-N.png`**. These composites are the real mocks (and pixel-sample colors from them, Step 2). The overlays carry meaning — e.g. an offer logo dropped onto a specific tile tells you exactly where the integration's offer goes.

### Step 1b — PDF
Open/inspect each PDF page (rendered if your agent supports images; a paging limit of ≈20 pages/request is typical). Each page/labelled screen = a screen mock. Prefer any embedded redline hex/px over visual estimates.

### Step 1c — Images (PNG/JPG/SVG)
Open/inspect each image in `mocks/<partner>/screens/` (rendered if your agent supports images). For SVG also read as text — `fill`/`stop-color`/`font-family`/`font-size` give exact values. Images are named **in journey order** (`slide-1.png`, `slide-2.png`, …) — read them in that order; if screen-keyword names are used instead (`landing*`/`offer*`/`login*`/`benefits*`/`manage*`), match by keyword. **If a manifest exists, the manifest's screen map and tokens win** over guesses.

---

## Step 2 — Design Token Extraction

Normalize everything into **`partner-brand/<partner>/tokens.json`**. If the manifest already states tokens, copy them in and mark their source; only derive the rest. Read `knowledgebase/mock-to-app/design-token-extraction.md` for heuristics.

**Extract exact colors by SAMPLING the mock's pixels — never eyeball them.** Eyeballed hex is the #1 fidelity error (a navy-vs-blue banner is instantly wrong). For any raster mock (PNG/JPG, or a rendered PDF page), run a quick script to read the **actual** hex — e.g. Python + Pillow: count pixels, list the most frequent **saturated** (non-neutral) colors, and identify each brand surface (top banner/header, primary CTA/accent, dark panels, badges). Use those exact values in `tokens.json` and in every screen (including hardcoded `Color(0xFF…)` constants). This is how **image-only mocks reach high fidelity without Figma** — pixel-sampling, not estimation. Example:
```python
from PIL import Image; from collections import Counter
im=Image.open('mocks/<partner>/screens/<file>.png').convert('RGB'); px=im.load(); c=Counter()
for y in range(im.size[1]):
    for x in range(im.size[0]): c[px[x,y]]+=1
for col,n in c.most_common(2000):
    if max(col)-min(col)>30 and n>40: print('#%02X%02X%02X'%col, n)  # saturated brand hues
```

```json
{
  "brand":   { "name": "string", "wordmark": "string", "logo": "path|null", "heroImage": "path|null" },
  "colors":  { "primary":"#RRGGBB","onPrimary":"#RRGGBB","secondary":"#RRGGBB","surface":"#RRGGBB","onSurface":"#RRGGBB","background":"#RRGGBB","error":"#RRGGBB","heroGradient":["#RRGGBB","#RRGGBB"] },
  "typography": { "fontFamily":"string","headingFamily":"string|null","scale": { "headline":{"size":24,"weight":800},"title":{"size":17,"weight":800},"body":{"size":13,"weight":400},"label":{"size":11,"weight":600} } },
  "shape":   { "radius": {"card":16,"button":12,"chip":20}, "spacing": {"screenPadH":20,"screenPadV":16,"gap":12} },
  "surfaces": ["web"],
  "copy":    { "appTitle":"string", "landing":{}, "offer":{}, "benefits":{} },
  "config":  { "appName":"snake_case","bundleId":"com.partner.app","bffBaseUrl":"http://localhost:8080","offerId":"string" },
  "unmapped": ["string"]
}
```
Rules: emit every key; where a value can't be derived, copy the reference default and add a note to `unmapped`; hex are 6-digit (the build adds `0xFF`). **`copy` is keyed per screen** — `appTitle` plus one object per screen/section the app actually has (`login`, `landing`, `offer`, `benefits`, and also things like `nav`, `footer`, `overview`, `billing` — whatever the mock defines); the `landing`/`offer`/`benefits` keys above are only examples, not a fixed set. **`copy` is a spec/checklist** for the rebuild — a full rebuild's screens usually hold their strings as literals, so `copy` need not be a runtime source; use it to make sure every string is accounted for. **Extra brand accents** beyond the fixed `colors` keys (e.g. a gold badge color, a 4th accent) go in a `colors.extra` named map (`{"gold":"#RRGGBB"}`) — do **not** smuggle colors into `copy`. Write `tokens.json` + assets to **`partner-brand/<partner>/`** (per-partner, mirroring `mocks/<partner>/` — never the shared `partner-brand/` root, which would clobber another engagement's tokens).

---

## Step 3 — Resolve the app to rebrand & materialize `app/`

**Mode B always rebrands a PROVIDED app that already carries the Adobe integration
— it never scaffolds an app from nothing.** That app is either the base reference
app (after Mode A implemented the features into it) or a partner app that already
has the integration. It is **referenced read-only** and never modified in place.
Resolve its source:

1. **`.ref-source`** file at the kit root, if present — its single line is a **local path** to a capability app (one that already has claim/subscription/cancel/notify implemented) to rebrand from. Use it directly, read-only.
2. **The Mode-A output `app/`** — if a working `app/` already exists (the bundled `base-ref-app/` after Mode A implemented the integration onto it), that is the **default** source. Rebrand it **in place** via the "subsequent runs — do NOT wipe `app/`" update path below.
3. Else, a registered target app path from `.target-apps` / `.target-app` (the `root` or a UI surface).

**State which source you used.** If **none** resolves, **STOP** and tell the
user: *"Mode B rebrands an existing app's UI from your mocks — it needs an app that
already has the Adobe integration. Run Mode A first (it defaults to the bundled
`base-ref-app/` → produces `app/`), or set `.ref-source` to such an app's local
path, or register it with `./INSTALL.sh`, then re-run."* Do **not** attempt to
author an app from the bundled reference material — Mode B is a UI rebrand of real
code, not a from-scratch build (use Mode A to create the integration first).

**Materialize/update `app/`** (gitignored) — `app/` is the **current engagement's** build; the kit targets **one app per checkout** (via `.target-app`), so re-running for a different partner re-derives `app/` in place. (Per-engagement *inputs* live under `mocks/<partner>/` and derived tokens under `partner-brand/<partner>/`, so those never collide; the active build is always `app/`.)
- First run (`app/` absent): copy the resolved source app, excluding VCS/build artifacts:
  `rsync -a --exclude='.git' --exclude='build' --exclude='.dart_tool' --exclude='node_modules' <ref>/ app/`
- Subsequent runs: this is an **update** — do NOT wipe `app/`. Re-apply Steps 4–6 against the current `app/`. Never clobber generated integration code; only re-derive theme/brand/copy.

---

## Step 4 — Discover the UI surface to rebuild (DO NOT hardcode paths)

The reference app's file layout varies between sources, so **discover** the themeable surface inside `app/` rather than assuming filenames:
1. **Theme file** — search `app/lib` for `ThemeData`, `ColorScheme`, `MaterialApp`/`MaterialApp.router`, `useMaterial3`, and `Color(0xFF…)` brand constants. That file (commonly `lib/app.dart`) holds the seed color, scheme, title, scaffold background, text theme.
2. **Brand widgets** — search for widgets whose name/contents reference a brand mark, wordmark, or logo (e.g. `*_brand.dart`, an app drawer, a logo tile with an initial/letter). These hold the wordmark text + logo tile color.
3. **Screens** — list `lib/features/*/**_screen.dart`. Map each to a manifest screen via the screen map (e.g. `home_screen.dart`, `claim_screen.dart`, `activation_confirmed_screen.dart`, `subscription_screen.dart`, `cancel_screen.dart`, `login_screen.dart`).
4. **Config + pubspec** — `lib/core/config.dart` (bffBaseUrl/offerId defaults), `pubspec.yaml` (`name`, fonts), `dart_defines*.env`.

Record the discovered file→role map; Steps 5–6 operate on those exact files.

### OFF-LIMITS — never edit (integration logic):
- `lib/services/**` (auth/claim/subscription/cancel + any pis/ims client), `lib/models/**`, every `*_provider.dart`, and the entire `bff/`.

**Routing policy (CANONICAL — Step 4b, the delete-screens note, and Step 5b all defer to this).** The Adobe **wiring** is fixed; **routes and navigation are not.** Precisely:
- **Immutable — never change:** the *behavior* behind the Adobe capabilities (the claim submit action, the subscription lookup, the cancel action) and **the provider/service each surviving screen calls**. This is about *what a screen invokes*, not its route path or placement. Never edit `lib/services/**`, `lib/models/**`, `*_provider.dart`, or `bff/`, and never change request/response handling or workflow types.
- **Addable — freely:** any new partner screen, tab, or **shell route** the mock shows (drawer / bottom-nav / top-nav shells, new pages). Add as many routes as the mock's navigation needs.
- **Deletable / re-pointable:** reference-app UI routes the mock does **not** show (e.g. the offer-detail / activation screens when the offer goes straight to `experience_url`) may be **deleted outright, route entry included**. If a deleted screen was also an entry point (e.g. the re-activate action on subscription/cancel), **re-point** that entry to the partner's offer control or a thin auto-claim screen (Step 4b reconciliation note). A capability the partner still needs (subscription / cancel) must stay **reachable**, but its route path and placement may change — only its provider binding is fixed.

Net: rename, move, add, and delete routes freely to match the mock; the only invariants are the provider/service a surviving screen calls and the Adobe request/response handling.

---

## Step 4b — Rebuild the navigation model & UI to the mock (archetype recipes)

The partner's UI may be ANY shape — reproduce it; do NOT force the reference app's drawer/dashboard. **Adding new screens, tabs, and routes IS allowed and expected.** Per the **Routing policy** (Step 4): only the **Adobe wiring** is fixed — the claim/subscription/cancel *behavior* and the provider each surviving screen calls — while route paths, the navigation chrome, and all partner screens are rebuilt to the mock (routes may be added, moved, or deleted).

**Navigation-model recipes** (pick the one the mock shows):
- **Drawer** (reference default) — keep only if the mock shows a hamburger drawer.
- **Sidebar dashboard** — persistent left rail. Give this the same rigor as bottom-nav: wrap content in a shell widget shared across routes. Use a `LayoutBuilder`/`MediaQuery` breakpoint (~900–1000px): **wide** → `Scaffold(body: Row(children: [SideNav(currentRoute: …), Expanded(content)]))` with **no AppBar** (so no stray hamburger) and the nav computing its active item from the current route; **narrow** → a normal `Scaffold(appBar:, drawer: SideNavAsDrawer)`. Each route builds its body wrapped in this shell (pass the current route so the active item highlights). Constrain content to a centered max-width if the mock does.
- **Bottom navigation (mobile)** — go_router `StatefulShellRoute`/`ShellRoute` + `Scaffold(bottomNavigationBar: NavigationBar)`; compute the selected index from the current route; host the app bar in the shell. Add the new tab routes (e.g. `/rewards`, `/account`).
- **Top nav bar (web/storefront)** — horizontal bar: logo-left, nav links, optional **search field**, cart/account cluster; inert links need no route; an **account/avatar menu** (e.g. `PopupMenuButton` → `context.go`) can host kept capabilities (subscription/cancel) when there's no drawer. **Replacing a drawer is a delete-and-rewire, not just "host the items":** delete the drawer widget AND any brand/header widgets only it used (then fix orphaned imports — a dangling drawer import breaks the build, often in `login_screen.dart`), and **re-home ALL drawer actions — including sign-out** (which usually lived in the drawer footer calling `sessionProvider.notifier.signOut()`) — into the account menu, or that action is silently lost. Search for the deleted widget's name across `lib/` and fix every reference.

**Component vocabulary** (build to match the mock; reuse the partner's widgets where present):
- Gradient **hero** banner (full-bleed `Container` + `LinearGradient` + headline/subcopy/CTAs).
- Horizontal **carousel** (`SizedBox(height:…)` around a horizontal `ListView`).
- **Responsive grid** (columns by breakpoint 4→3→2→1; `GridView`/`Wrap` + `childAspectRatio`; inside a scroll use `shrinkWrap` + `NeverScrollableScrollPhysics` or a bounded height).
- **Product card** (image/placeholder + discount-badge overlay + title + price + CTA) vs **recommendation card** (category + headline + logo) — use whichever the mock shows; style the Adobe offer to harmonize with, yet stand apart from, surrounding cards.
- **Footer** (dark link-column) — storefronts have one; the reference app doesn't, so you build it from scratch. Structure: a dark full-bleed band whose inner content uses the **same centered max-width** as the page; a `Wrap`/`Row` of link **columns** (each = a title + a list of links, typically **inert** — no routes); then a wordmark + tagline + copyright row. Make it responsive (columns wrap on narrow).
- **Filter pills** (wrapping chips, first selected, no icons) — distinct from icon **tab pills**.
- **Search field**, **account/avatar menu**, **badges** (NEW / discount) as shown.
- **Stat / balance hero** — full-bleed header with a large formatted number (e.g. currency) + a trend/delta pill + often an inline chart; distinct from a marketing gradient hero.
- **Inline chart / sparkline** — small area/line chart; hand-roll with `CustomPainter` (or a charts package). Pitfall: type the data as `List<double>` — a `List<num>` inference breaks `const`.
- **Ledger / transaction row** — leading avatar/initial + name + "date · category" subtitle + trailing **signed amount colored by sign** (credit = green, debit = red). This is a **domain semantic color** — preserve it (semantic colors are not only success/error).
- **Account / wallet card** — type chip + masked number (`•••• 4821`) + balance, usually in a **horizontal scroll row**.
- **Quick-action tile grid** — a card of tinted rounded icon tiles + labels (Transfer/Pay/…).
- **Ticket / boarding-pass card** — header strip + big code columns (origin→dest, gate/seat/time) + a **dashed/perforated divider with punched notches** + a **barcode/QR strip** (`CustomPaint`); reused for passes/tickets/loyalty.
- **Itinerary / trip row** — route title (A → B) + datetime + a color-coded **status badge**.
- **Offer-among-peers** — a **row OR vertical list** of sibling offer/perk cards (match the mock's layout — storefront perks are often a horizontal grid of equal-width cards, not a vertical list) with the partner (Adobe) offer **elevated** among them. "Elevated" = pick what the mock shows: an accent **border** or top **strip**, an elevation **shadow**, a **filled** CTA vs. outlined peers, and/or a colored **eyebrow** (+ mark + title + body). Decide which peer CTAs are inert vs. wired; only the Adobe CTA fires the claim.

**Surface framing:**
- **Mobile mock** → design for **portrait phone** (e.g. 1080×2160 mock; golden `tester.view.physicalSize` ≈ 430×932 portrait; handle safe-area + bottom-nav inset). Web is only the dev harness.
- **Desktop web mock** → constrain content to a **max width** (~1520px) centered, with full-bleed hero/footer; the golden must be wide.

**Reconciling reference screens you delete but that are still referenced:** the reference `ClaimScreen`/activation screens are removed when the mock's offer goes straight to `experience_url` — but they may also be the **re-activate entry** from subscription/cancel. Re-point those entries at the partner's offer control (if the offer lives **inline on home** with no dedicated offer screen, re-point them to home), OR keep a **thin auto-claim screen** (immediately calls the claim provider → `launchUrl(experience_url)`, with no reference marketing copy). **CRITICAL — migrate the claim→launch handler, don't just "wire the CTA":** the `launchUrl(experience_url)` + success/error/already-active handling frequently lives **inside the offer screen you are deleting** (e.g. a `ref.listen(claimProvider, …)` in that screen's `build`/`initState`), NOT in the provider. Deleting the screen deletes that logic — so **re-implement the `claimProvider` listener on your new CTA host** (the inline offer card / thin auto-claim screen): watch the claim state, `launchUrl` on success, show error/already-active states. Search the deleted screen first for `launchUrl`/`ref.listen`/`context.go` to see exactly what to carry over. After deleting, **search the build for the reference copy** (e.g. "EXCLUSIVE PARTNER OFFER") and assert it's gone (Step 7b rule 1).

**Two coupling traps (both observed in testing):**
- **Brand widgets are coupled to `app.dart` constants** (`brandPrimary`, …). If you rewrite the theme/constants, migrate the brand widgets in the same pass or they break.
- **Renaming `pubspec.yaml` `name`** breaks every `package:<oldname>/…` import (incl. tests). Prefer changing only the **display identity** (`MaterialApp` title + `web/index.html` + `manifest.json`) and leave the Dart package `name` as-is; if you must rename, search-and-update all `package:` imports.
- **Per-screen headers under a bottom-nav shell** — if each tab renders its own full-bleed header (no shared app bar), the shell hosts only the `NavigationBar` and each screen owns its header.
- **Horizontal-scroll bounded-height rows overflow** — a horizontal `ListView` of cards inside a Column needs a bounded height, and the inner Column can overflow a few px under wide test fonts; give it headroom / `FittedBox`.
- **Stretch `Row` of cards inside a scroll view → "BoxConstraints forces an infinite height"** — a `Row` with `crossAxisAlignment: stretch` (e.g. equal-height stat cards) placed in a `Column`/`ListView` has no bounded height and throws at layout. Wrap that row in `IntrinsicHeight` (or give the cards a fixed height). Common on dashboard stat-card rows above a chart.
- **Inline chart (CustomPainter) beyond the `List<double>` tip** — scale to the data's min/max (don't assume 0-based), draw axis/month labels with a `TextPainter`, and for an area fill close the `Path` down to the baseline. Keep the painter's `size` bounded (wrap in a `SizedBox(height:)`).
- **Currency & number formatting** — use the mock's literal formatted strings (or `intl`) and match exact glyphs (minus sign `−` vs `-`, thousands separators).
- **Golden bootstrap is not a failure** — the first `flutter test` "fails" only because goldens don't exist yet; run `flutter test --update-goldens` to seed them, then `flutter test`.
- **Pillow mock glyphs** — emoji/symbol glyphs render as tofu in composed PNGs unless you bundle a symbol font or draw vector shapes; the generated app should use Material icons regardless.

---

## Step 5 — Apply theme + brand + copy

- **Theme** (the discovered theme file): set the seed/primary → `colors.primary`; error → `colors.error`; `ColorScheme` (primary/onPrimary/secondary/surface/background); `MaterialApp` `title` → `copy.appTitle`; `scaffoldBackgroundColor` → `colors.background`; build a `TextTheme` from `typography` (use `google_fonts` if a non-system family is named; add the dep + import). Keep `useMaterial3: true`. Apply colors as `Color(0xFF + hex)`.
- **Brand widgets:** logo tile color + letter/initial → partner (or `Image.asset` of `brand.logo`); wordmark text → `brand.wordmark`; drawer/footer labels → `copy`.
- **Brand-accent remap in screens (CRITICAL — a central theme swap is NOT enough):** feature screens frequently **hardcode** the reference app's brand color as `Color(0xFF…)` constants (e.g. a `_adobeRed`/`_brandX` used for hero banners, primary CTAs, logo tiles). Changing only the `ThemeData` seed leaves these screens the old color. So: search `lib/features/**` for hardcoded `Color(0xFF…)`, identify the reference **brand/accent hue(s)** (the dominant non-neutral color on heroes & primary buttons) and remap them to `colors.primary` (or the matching token). Leave neutral grays/text/borders and semantic colors (success green, error red) unless the mock dictates. **A partnered *product's own* brand color is semantic, not the partner-app's accent:** the reference app may hardcode Adobe's brand hue (e.g. an `_adobeRed`) on an Adobe offer/subscription surface — that represents Adobe, so **keep it unless the mock recolors it**; only remap the *partner-app's* former accent (its logo/hero/primary-button hue) to `colors.primary`. This MUST be screenshot-verified (Step 7) — it is the #1 reason a rebuild "still looks like the reference app."
- **Assets:** copy `partner-brand/<partner>/assets/*` into `app/assets/` and register in `pubspec.yaml` `flutter: assets:`.

### Step 5a — Typography (token-driven — works for ANY font in the mock)
Drive everything from `tokens.json.typography`; never hardcode a partner's font. Procedure:
1. If `fontFamily`/`headingFamily` name a **system/default** font (or are null), leave the default `TextTheme` (just apply weights from `scale`).
2. If they name a **non-system family**, add the dependency once (`flutter pub add google_fonts`) and build the theme generically — resolve the family **by name** at runtime so any Google font works:
   ```dart
   // body family from tokens.typography.fontFamily; headings from headingFamily (fallback to body)
   final base = GoogleFonts.getTextTheme(tokens.fontFamily, Theme.of(context).textTheme);
   final textTheme = (headingFamily == null) ? base : base.copyWith(
     displayLarge:  GoogleFonts.getFont(headingFamily, textStyle: base.displayLarge),
     headlineSmall: GoogleFonts.getFont(headingFamily, textStyle: base.headlineSmall, fontWeight: FontWeight.w700),
     titleLarge:    GoogleFonts.getFont(headingFamily, textStyle: base.titleLarge,   fontWeight: FontWeight.w700),
   );
   // ThemeData(..., textTheme: textTheme)
   ```
   Use `GoogleFonts.getFont(name)` / `getTextTheme(name)` (string-keyed) rather than a hardcoded `GoogleFonts.lora()` call, so the **token value alone** selects the font. If a named family isn't on Google Fonts, fall back to the default and note it in `unmapped`.
3. Apply `scale` sizes/weights from tokens to the headline/title/body/label roles.

### Step 5b — Layout & copy adaptation (REPRODUCE the mock ~90%, not just recolor)

**The goal is that each partner-built mock screen is reproduced to ~90–100% fidelity — same structure, sections, and components — not a theme/color swap of the reference layout.** Read the mock carefully and rebuild the screen's layout to match: its navigation chrome (e.g. a light vs. dark **sidebar** with the partner's actual menu items + badges), its **content structure** (a card **grid** of recommendations, a status timeline, an assistant panel, etc.), and each component's shape (card with title/description/badge/CTA/brand-mark). The reference app's Adobe **wiring** (routes, providers, services) stays intact, but the **visual layout is rebuilt to the mock**. A recolor of the reference layout is NOT acceptable when a screen mock was supplied — screenshot-compare side-by-side (Step 7) and iterate until it visually matches.
For each mapped screen, adjust the screen widget in `app/` to match the mock — **reuse the private section widgets already in the file** (cards, tiles, hero, status), restyle/reorder/recopy them; do not introduce a new UI framework. Swap copy from `tokens.json.copy`. **Keep state wiring and callbacks intact** (e.g. the offer card still navigates to the claim route; claim still calls the claim provider). If a mock screen has no reference equivalent, add it to `unmapped` and surface it in the report — do not improvise integration logic. If a mock screen is **Adobe-hosted** (served at `experience_url`, e.g. consent/product), **do not build it** — it is reached by redirect. **Remove reference-app screens that are NOT in the journey** — when mocks are supplied, *nothing of the reference app's UI should remain unless a mock calls for it.* If the mock's offer CTA goes straight to Adobe, wire that CTA to **initiate the claim and open `experience_url` directly** (e.g. `launchUrl(experience_url)`) — do NOT keep or generate an in-app offer-detail/activation screen, and delete the reference app's versions of those screens + their routes. Keep capability screens (subscription/cancel) only if the partner needs them reachable (e.g. a sidebar entry). **Make every adapted layout overflow-safe:** wrap text/rows in `Flexible`/`Expanded` with `overflow: TextOverflow.ellipsis` (nav labels, card titles, button rows). The screen-render & golden tests use a **wide fallback font**, so they surface real narrow-width overflow — a green run means the layout is robust, not just lucky at one width. When the mock shows a persistent **sidebar/dashboard** (vs. a drawer), adapt the home to a responsive `Row(side-nav + content)` on wide screens while keeping the drawer for narrow — and keep every nav item wired to its existing route.

**Kept capability screens with NO mock (subscription / cancel):** if you keep a reference capability screen the mock didn't cover, do not stop at the accent remap — that leaves reference **surfaces** intact, so a light-themed reference card lands in a now-dark app (white-on-white). Re-theme those screens from tokens too: apply `colors.surface`/`onSurface`/`background` to their scaffolds/cards/text so they match the new palette (not just the primary accent). **Do this even when the brightness does NOT flip** (both themes light): still retint the neutral card/surface/background fills to the token palette, or the kept screen reads slightly cooler/off-palette next to the rebuilt screens — keep only the *partnered product's* own semantic hue (e.g. Adobe red). Keep their providers/callbacks untouched. If even that can't make them coherent, note it in `unmapped` and flag it in the report rather than shipping a clashing screen.

---

## Step 6 — Surfaces & config

1. Honor `surfaces` from the manifest/tokens. Flutter is one codebase; enable only the requested run targets:
   - **web** → ensure `app/web/` exists (`flutter create --platforms web .` only if missing); this is the default run target. **Also rebrand the web shell** — the `MaterialApp` title does NOT set the browser tab / PWA name: update `web/index.html` (`<title>`, `<meta name=description>`, `<meta name=apple-mobile-web-app-title>`) and `web/manifest.json` (`name`, `short_name`, `description`, `theme_color`=`colors.primary`, `background_color`=`colors.background`). Search the build for the old reference name afterwards — it must be gone.
   - **android** → ensure `app/android/`; set `applicationId` placeholder = `config.bundleId`.
   - **ios** → ensure `app/ios/`; set `PRODUCT_BUNDLE_IDENTIFIER` placeholder = `config.bundleId`.
   Bundle ids are placeholders — flag them for the partner to finalize. Do not add a surface the partner did not ask for.
2. Runtime config via dart-defines: copy `dart_defines.example.env` → `dart_defines.env` (gitignored); set `BFF_BASE_URL`, and the offer-id define **using whatever name the reference app already uses** (e.g. `ADOBE_OFFER_ID`) from `tokens.json.config.offerId`. **Discover which of these the Flutter app actually reads** — often only `BFF_BASE_URL`; the **offer id may live entirely in the BFF** (no `AppConfig` offer-id field), so don't assume one exists or hunt for it. `config.appName` is **informational only** — it does **not** rename the Dart package (see the `pubspec.yaml name` rule below). Set the **`MaterialApp` title** (display identity). **Leave `pubspec.yaml` `name` as-is** — the Dart package name is not the display name, and renaming it breaks every `package:<name>/…` import (see the coupling trap in Step 4b). Only rename it if you also search-and-update all `package:` imports.
3. **Never** put IMS credentials/secrets in dart-defines or Flutter code (manual/methodology/card-model.md#concepts-surfaces-apis-and-the-security-invariant security invariant).

---

## Step 7 — Verify by building and running (MANDATORY LOOP — never report success unverified)

Follow manual/methodology/verification.md **Code Generation Protocol rule 5**. Run from inside `app/`:
```bash
flutter pub get
flutter analyze            # must be clean
flutter test               # must pass
```
**Screen-render verification (mandatory — proves each screen renders, not just compiles):** generate/maintain `test/screens_render_test.dart` that pumps each screen inside a `ProviderScope`. Key rules learned in testing:
- **Seed the signed-in session by _overriding_ `sessionProvider`** with a fake notifier that returns a `Session` from its `build()` — **never** call `signIn`/`load` from a widget `initState`/`build`, or Riverpod throws *"Tried to modify a provider while the widget tree was building."*
- **Size the test surface to the TARGET device** — portrait phone (≈ 430×932) for a mobile mock, the mock's width for web. **Do NOT oversize to avoid overflow**: the point of the wide test font is to *surface* real narrow-width overflow, so a green run means the layout is genuinely robust.
- **Two screen kinds:** (a) **new/rebuilt screens** — usually need no stubs; assert the partner **wordmark** + each screen's key copy renders. (b) **kept capability screens** (subscription/cancel/login) — these hit the network on init, so override each provider they read (search for `initState`/`.notifier).load()`/`FutureProvider`) with a fake returning a fixed state + no-op `load()` so **no real HTTP fires**. (Riverpod 3.x gotcha: the `Override` type is **not** exported from the `flutter_riverpod.dart` barrel — `import 'package:flutter_riverpod/misc.dart' show Override;`, or just inline the override list so you never name the type.)
- "Discover the screen list from `lib/features/*/**_screen.dart`" means *enumerate for coverage* (don't hardcode a stale list) — you still supply the correct per-screen stubs. `flutter test` must pass.

**Visual check (golden screenshots — mandatory):** also generate `test/screenshots_test.dart` that renders each screen **wrapped in the app's real themed root** — pump `PartnerRefApp` / your `MaterialApp.router`, or extract the theme into a shared `partnerTheme()` that both the app and the test call. **Do NOT hand-copy `ThemeData` into the test**, or the golden validates a *copy* of the theme, not the shipped one. `matchesGoldenFile` → run `flutter test --update-goldens`, then **open each PNG and inspect it.** Confirm the **brand accent matches the partner primary** (not the reference's hue — catches hardcoded `Color(0xFF…)` the theme swap missed) and the layout is sane. Treat goldens as a **one-time visual snapshot, not a first-run pass/fail gate** (on first `--update-goldens` they cannot fail). Goldens render text as boxes when fonts aren't bundled — judge **color + layout** from the PNG and **copy** from the render test + the compiled-build search (Step 7b rule 1). Do not claim visual fidelity without having looked at the PNG.

For each requested surface, do a **real build/run**:
- web: `flutter build web` (must succeed); if a browser run is possible, `flutter run -d chrome` and confirm the rebuilt screens render.
If the BFF is in scope: `cd bff && npm install && npm test` (or the partner's documented test command). Then attempt a **live smoke test, best-effort** — use the partner's **test entrypoint** if one is documented (a seed/login route + test credential recorded in `service-cards/backend/BUILD_CONFIG.md`, a `docker-compose`, a `make dev`, etc.): boot the backend, obtain a token via that entrypoint, and hit each generated route asserting **non-404**. **If no test entrypoint exists** (no seeded login, backend not locally bootable), **do not fabricate one** — fall back to **compile + unit/integration tests only** and say so in the report. (When you can boot it: a stale long-running server can serve old config — always test a freshly booted instance, and never report login credentials without an actual 200 from a running server.)

**Guardrail — integration logic untouched:** after the rebuild, assert the OFF-LIMITS files are byte-identical to the reference (e.g. `diff -r` or `git diff --stat` of `lib/services lib/models **/*_provider.dart bff/`). If any differ, **revert those files** and redo the rebuild without touching them.

**Loop:** if `analyze`/`test`/`build` fail, fix **only UI-side** issues (theme/widget/copy/assets/pubspec) and re-run — up to a sensible number of iterations. If a failure traces into OFF-LIMITS files, stop and report it as a UI-side error elsewhere (do not edit integration code to paper over it). Then perform a **per-screen mock-vs-build diff** (screenshot/golden if available, else structural description) and record concrete diffs.

---

## Step 7b — Fidelity Protocol (reproduce ANY mock to ~99% — MANDATORY, learned rules)

These rules are derived from real rebuilds; skipping any one visibly regresses fidelity. Apply them to **every** screen.

1. **Copy is verified by reading the ACTUAL rendered text — NEVER golden/widget-test screenshots.** Golden tests render text as filler boxes, so they *cannot* confirm a single word. For each screen: (a) **search the compiled build** (`build/web/main.dart.js`) for every headline/label/CTA string the mock shows, and assert any wrong/placeholder copy is **absent**; and (b) diff a real render (browser or the mock) string-by-string. Every visible word must equal the mock exactly (e.g. the offer's *italic* body copy + its exact CTA like "Click here to get started" — not a base tile's generic copy).

2. **Deck slides carry a TEXT layer, not just images.** A `.pptx` slide = base screenshot(s) + overlaid **text boxes** + logos/cursors. When ingesting, extract the slide's text runs (`<a:t>` in `ppt/slides/slideN.xml`) **and their `<a:off>` positions**. Text positioned over a tile/region **replaces** that region's base copy (the deck drops the offer's marketing copy + CTA onto a base tile, hiding the base text). Map each overlay text block to the tile it covers and use THAT copy — do not read copy off the base screenshot. **Filter out presenter notes / callout annotations** (e.g. *User clicks "get started"*) — those describe the interaction, they are not UI copy.

3. **Pixel-sample every brand color** from the mock images (Pillow; most-frequent saturated hues) — banner/header, primary CTA, dark surfaces, badges — and use the exact hex in the theme **and** every hardcoded screen constant. Never eyeball (a navy-vs-teal banner is instantly wrong). Note: tiny anti-aliased accents (a small CTA/badge) may not sample cleanly — then fall back to the **manifest's stated token** (manifest wins); re-sample only what's cleanly present (large regions like banners/surfaces).

4. **Reproduce LAYOUT & COMPONENTS structurally, not just color/copy.** Match containers exactly: a 2×2 grid = ONE bordered box split by dividers (not N separate shadowed cards); tab bars = pills **with icons**; sidebars = the partner's exact nav items + badges; each card = category label + headline + logo placement. Compare component-by-component against the mock.

5. **Logos / brand marks.** Rasterize any vector logo from the mock (`cairosvg` SVG→PNG) into `app/assets/` and render via `Image.asset`; for wordmark logos, reproduce as styled `RichText` using the pixel-sampled colors (e.g. two-tone marks). Match size + placement to the mock.

6. **Fonts must be BUNDLED — do NOT rely on `google_fonts` runtime fetch** (it silently fails and falls back to the wrong face). Download the TTF(s) → `app/fonts/` → register in `pubspec.yaml` → set `ThemeData.fontFamily` + a `textTheme` using the bundled families (serif for headings if the mock's headings are serif). Prefer the **variable** TTF (e.g. `Lora[wght].ttf`, `Inter[opsz,wght].ttf`) — static per-weight file URLs often 404; register the family once and drive weights via `fontWeight`.

7. **Defeat caching during review.** Flutter web registers a service worker that aggressively caches the app shell; a hard-refresh does NOT reliably evict it. Build with **`flutter build web --pwa-strategy=none`** (no service worker) and serve `build/web` on a **fresh port** so the reviewer always sees the latest.

8. **Overflow-safe layouts** (Flexible/Expanded + ellipsis; `FittedBox` for logos/wordmarks) — widget-test fonts are wide and surface real narrow-width overflow.

9. **Per-screen fidelity loop + scorecard.** For each screen, compare the real render to its mock and score copy / colors / layout / components / logos / fonts. Fix gaps and re-verify **in a loop**. Do not mark a screen done below ~99% match. The report includes a per-screen scorecard.

---

## Step 8 — Report

1. **Source used** — the resolved app to rebrand: the `.ref-source` local path or the registered target app path (state which).
2. **Surfaces built** — and the run/build result for each.
3. **Screens rebuilt** — each, layout-adapted vs theme-only, with the mock it was matched to.
4. **Tokens applied** — color/type/shape values + their source (manifest vs derived); list any *approx* values needing confirmation.
5. **Assets swapped** — logo, wordmark, hero (paths).
6. **Verification** — actual `pub get`/`analyze`/`test`/`build` output (pass/fail) + per-screen mock-vs-build diffs. Do not claim a screen matches without diffing it.
7. **Untouched (assertion)** — confirm `.ref/`/source unmodified and that OFF-LIMITS integration files in `app/` are byte-identical to the reference.
8. **Unmapped** — every mock element that couldn't be mapped, with why.
