# Mock Ingestion

The **authoritative ingestion reference** for `/build-app-from-mocks` (Steps 1–2). It defines the partner input format and naming, the per-form ingestion procedure (Figma / PPTX-composite / images / PDF), the pixel-sampling rule, and the journey-mapping rule. This is consistent with `mocks/README.md` and `mocks/_template/` — if any of these disagree, treat that as a bug and reconcile.

---

## Input format & naming (one folder per partner)

A partner supplies mocks as **one folder per partner** under `mocks/`, copied from the template:

```
cp -r mocks/_template mocks/<partner>
```

That folder has four parts (see `mocks/README.md` and `mocks/_template/`):

| Path | Purpose |
|---|---|
| `mocks/<partner>/manifest.md` | **REQUIRED** spec the skill reads — partner name, wordmark, surfaces requested, offered product/offer id, a **screens table** (file → **role** → what the partner calls it, listed in journey order), the partner's **offer/benefit terminology**, and optional brand tokens (auto-detected from the screens if left blank). Each screen is tagged with a **Role** from the shared vocabulary (`login` / `landing` / `offer` / `benefits` / `manage` / `other` / `adobe-hosted`); `offer` = pre-claim offer surface, `benefits` = where an active subscription appears as an owned benefit (in the partner's words), `adobe-hosted` = served by Adobe at `experience_url`, never built. Blank template: `mocks/_template/manifest.md`. |
| `mocks/<partner>/screens/` | Screen images, **one per screen**, named in journey order `slide-1.png`, `slide-2.png`, … (each a **full screen**, not a crop). Screen-keyword names (`landing*`, `offer*`, `login*`, `benefits*`, `manage*`) are also accepted. This is also where rendered PPTX/PDF composites are written. |
| `mocks/<partner>/brand/` | Logo / wordmark / asset files (svg/png). |
| `mocks/<partner>/source/` | Optional: the raw `.pptx`/PDF deck and notes. |

**There is no flat `mocks/` drop and no per-feature filenames at the `mocks/` root.** Everything lives under `mocks/<partner>/`. The manifest is required; if it is still the unfilled template, fill it (from the screens + the partner's answers) before generating.

If a team keeps a local filled-in partner folder under `mocks/<partner>/`, treat it as an example only — keep ingestion partner-agnostic.

## Three accepted forms (detected in this order)

1. `--figma <url>` argument → **Figma** (authoritative for tokens). §1.
2. A raw `.pptx`/PDF in `mocks/<partner>/source/` → **PPTX composite** (§2) / **PDF** (§4).
3. Images in `mocks/<partner>/screens/` (`*.{png,jpg,svg}`) → **Image**. §3.

If more than one form is present, ingest all and merge. Precedence for conflicting values: explicit redline/spec text > Figma variables/styles > SVG attributes > **pixel-sampled** color from a raster mock > visual estimate. **When a `manifest.md` exists, its screen map and tokens win** over guesses derived from the files.

---

## Pixel-sampling rule (raster mocks)

For any raster mock (PNG/JPG, or a rendered PDF/PPTX page), **extract exact colors by sampling the pixels — never eyeball them.** Eyeballed hex is the #1 fidelity error. Run a quick script (Python + Pillow) to count pixels, list the most frequent **saturated** (non-neutral) colors, and identify each brand surface (top banner/header, primary CTA/accent, dark panels, badges). Use those exact values in `tokens.json`. This is how image-only mocks reach high fidelity without Figma. Example:

```python
from PIL import Image; from collections import Counter
im=Image.open('mocks/<partner>/screens/slide-1.png').convert('RGB'); px=im.load(); c=Counter()
for y in range(im.size[1]):
    for x in range(im.size[0]): c[px[x,y]]+=1
for col,n in c.most_common(2000):
    if max(col)-min(col)>30 and n>40: print('#%02X%02X%02X'%col, n)  # saturated brand hues
```

## Journey-mapping rule

**Treat the mocks as a user JOURNEY, not loose screens.** Order them into the flow (e.g. landing → offer → [Adobe-hosted redeem/consent/product] → status). The **landing** screen — what the user sees right after login — becomes the app's **home route** and is reproduced faithfully. **Weave the Adobe offer into wherever the deck places it** (a card/banner on the landing, or a dedicated offer page). Screens served by Adobe at `experience_url` (consent, sign-in, product) are **NOT built** — the app only redirects and handles the return. If the offer CTA goes straight to Adobe, wire it to initiate the claim and open `experience_url` directly (no in-app offer-detail screen). If it is unclear which screen is the landing (e.g. a dashboard AND a recommendations page), **ask** rather than guess. The manifest's screens table (rows listed in journey order) is the source of truth for this ordering.

---

## 1. Figma (via `mcp__claude_ai_Figma`)

**Authenticate first.** The Figma MCP requires an auth handshake (`authenticate` → `complete_authentication`) before any read call. If it is not authenticated, stop and ask the user to authenticate.

Then extract, in this priority:

| Source in Figma | Maps to |
|---|---|
| **Variables / design tokens** (if present) | Cleanest source — map collection values straight to `colors`, `typography`, `shape`. |
| **Local color styles** | `colors.*` (match by style name: Primary/Brand → `primary`, Error/Negative → `error`, Surface/Card → `surface`, Background → `background`). |
| **Local text styles** | `typography.scale` (Heading→`headline`, Title→`title`, Body→`body`, Caption/Label→`label`); family → `typography.fontFamily`. |
| **Frames** (top-level) | One frame ≈ one screen. Match frame name → screen via the manifest map (landing/offer/login/benefits/manage). Capture layout order, alignment, copy. Order them into the journey (above). |
| **Components / component sets** | Reusable pieces (button, card, badge, list row) — reused widgets, not new ones. |
| **Image/vector nodes** named logo/wordmark/hero | Export as SVG/PNG → `partner-brand/<partner>/assets/`; record path in `brand.logo` / `brand.heroImage`. |

For each frame, record copy strings verbatim into the matching `copy.<screen>` block. Note radius/spacing from frame layout (corner radius, padding, item gaps) into `shape`.

---

## 2. PPTX composite (`mocks/<partner>/source/*.pptx`) — render slides, not raw media

A `.pptx` slide is a **composite** (a base screenshot + overlaid logos/cursors/callout text). Do **NOT** treat the raw embedded media (`ppt/media/imageN.*`) as the mock — a single embedded image is only one layer, so it misses overlays (e.g. an offer logo placed on a tile). The overlays carry meaning — an offer logo dropped onto a specific tile tells you exactly where the integration's offer goes.

**Render each slide as the user sees it:**
1. Unzip the pptx. Read the slide size from `ppt/presentation.xml`.
2. For each `ppt/slides/slideN.xml`, read every `<p:pic>`: its `r:embed` → `ppt/media/...` via the slide rels, plus its `<a:off>`/`<a:ext>` position+size in EMU. Also read text runs and their positions.
3. **Composite** the layers (Python + Pillow; rasterize any `.svg` with `cairosvg`) onto a slide-sized canvas at the scaled offsets.
4. Save each as **`mocks/<partner>/screens/slide-N.png`** (journey order, matching the manifest).

These composites are the real mocks — **pixel-sample colors from them** (rule above) and ingest them as images (§3).

---

## 3. Images (`mocks/<partner>/screens/*.{png,jpg,svg}`)

- Read each image with the Read tool (renders visually). Infer layout, copy, and palette; **pixel-sample** colors (rule above) rather than estimating.
- **SVG: also read the file as text.** `fill`, `stop-color`, `font-family`, `font-size`, `rx` (corner radius) attributes give exact values — always prefer them over visual estimates. The kit's own default mocks under `knowledgebase/ui-mocks/defaults/**/*.svg` are good examples of this structure.
- Match each file to a screen by its **journey-order** name (`slide-1.png`, `slide-2.png`, …) per the manifest's screen map; if screen-keyword names are used instead (`landing*`, `offer*`, `login*`, `benefits*`, `manage*`), match by keyword. Unmatched files → ingest for tokens, note in `unmapped`.
- Sample: dominant saturated color → `primary`; near-white card fill → `surface`; page fill → `background`; a red/negative accent → `error`; any 2-stop gradient on a hero → `heroGradient`.

---

## 4. PDF (`mocks/<partner>/source/*.pdf`, Read tool PDF support)

- Read with the Read tool's `pages` parameter. **Max 20 pages per request** — page through larger decks (e.g. `pages: "1-20"`, then `"21-40"`).
- Treat each page (or each labeled screen region on a page) as a screen mock, ordered into the journey.
- Prefer **explicit spec/redline text** on the page (hex codes, px sizes, font names) over sampling. Many decks include a style page — read it first and seed `colors`/`typography`/`shape` from it.
- From rendered screen pages, capture layout order and copy; **pixel-sample** brand + neutral colors where no spec text exists.

---

## 5. Normalization → tokens.json

Produce one `partner-brand/<partner>/tokens.json`. Always emit **every** key; where a value can't be derived, copy the ref-app default and add a note to `unmapped`. Hex values are 6-digit RGB (no alpha — the build step prepends `0xFF`). If the manifest already states a token, copy it in and mark its source; only derive the rest.

Ref-app defaults to fall back to (from `lib/app.dart`, `lib/core/config.dart`):
- `colors.primary` `#EB1000`, `colors.error` `#D7373F`, `colors.background` `#FAFAFA`, `colors.surface` `#FFFFFF`, `colors.onPrimary` `#FFFFFF`.
- `shape.radius.card` 16, `.button` 12, `.chip` 20; `spacing.screenPadH` 20.
- `config.bffBaseUrl` `http://localhost:8080`, `config.offerId` `30006514`.

### tokens.json JSON schema

```json
{
  "brand": {
    "name": "string",
    "wordmark": "string",
    "logo": "string|null — relative path under partner-brand/<partner>/assets/",
    "heroImage": "string|null — relative path under partner-brand/<partner>/assets/"
  },
  "colors": {
    "primary":   "#RRGGBB",
    "onPrimary": "#RRGGBB",
    "secondary": "#RRGGBB",
    "surface":   "#RRGGBB",
    "onSurface": "#RRGGBB",
    "background":"#RRGGBB",
    "error":     "#RRGGBB",
    "heroGradient": ["#RRGGBB", "#RRGGBB"]
  },
  "typography": {
    "fontFamily": "string",
    "headingFamily": "string|null",
    "scale": {
      "headline": { "size": 24, "weight": 800 },
      "title":    { "size": 17, "weight": 800 },
      "body":     { "size": 13, "weight": 400 },
      "label":    { "size": 11, "weight": 600 }
    }
  },
  "shape": {
    "radius":  { "card": 16, "button": 12, "chip": 20 },
    "spacing": { "screenPadH": 20, "screenPadV": 16, "gap": 12 }
  },
  "surfaces": ["web"],
  "copy": {
    "appTitle": "string",
    "<screenId>": { "…": "one object per screen the app has — login, landing, offer, benefits, or whatever the mock defines; keys are per-screen, not a fixed set" }
  },
  "config": {
    "appName": "string (snake_case)",
    "bundleId": "string (reverse-DNS placeholder)",
    "bffBaseUrl": "string (URL)",
    "offerId": "string"
  },
  "unmapped": ["string"]
}
```

Field notes:
- `colors.onPrimary` — pick white or near-black for contrast against `primary`.
- `colors.heroGradient` — supply two stops or repeat `primary` twice.
- `typography.scale.weight` — numeric (400/600/700/800/900) → Flutter `FontWeight.w###`.
- `surfaces` — mirror the manifest's "Surfaces requested" (web / iOS / android / any combination); add no surface the partner didn't ask for.
- `copy.<screen>` — keyed by the screens that exist in the manifest's journey (landing/offer/benefits/login as applicable); capture copy verbatim from the matching mock.
- `unmapped` — anything seen in a mock with no token/screen home. Drives the final report's "couldn't be mapped" section.
