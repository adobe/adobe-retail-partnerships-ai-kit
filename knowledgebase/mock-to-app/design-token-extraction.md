# Design Token Extraction

Practical heuristics for deriving a Flutter `ColorScheme` / `TextTheme` / spacing from each mock input type, plus a worked example. Pairs with `mock-ingestion.md` (how to read mocks) and `reference-app-map.md` (where the tokens land).

> The worked example below (a "TelcoX" partner, the `adobeRed → blue` recolor, `express_offer_screen.dart`) is **illustrative** — a concrete walk-through against one reference app. Your partner, colors, and the real filenames will differ; discover the actual theme/brand/screen files per `build-app-from-mocks` Step 4.
>
> **Note:** `express_offer_screen.dart` and other claim/subscription screens referenced here belong to a **prior/legacy** version of the reference app (useful only as a worked illustration of the token → file mapping concept). The currently-bundled `base-ref-app/` is intentionally **feature-less** — it has only `home` + `session` features; claim/subscription/cancel/notify screens appear only after Mode A generates them.

---

## Colors → Material `ColorScheme`

The template seeds its scheme from one brand color and overrides a few roles (`lib/app.dart`):

```dart
ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.light)
  .copyWith(primary: primary, onPrimary: onPrimary, error: error);
```

Heuristics to fill `colors`:

| Token | How to derive |
|---|---|
| `primary` | The dominant **saturated** brand color — the one on primary buttons / logo / active states. From Figma: the "Primary"/"Brand" color style. From image/PDF: the most saturated recurring non-neutral hue. |
| `onPrimary` | White if `primary` is dark/saturated; near-black (`#1F1F1F`) if `primary` is light. Pick for ≥4.5:1 contrast. |
| `secondary` | A supporting accent if the mock has one; else a tint/shade of `primary`. |
| `surface` | Card/sheet fill — usually `#FFFFFF` or a very light neutral. |
| `background` | Page/scaffold fill — the lightest neutral behind cards (template: `#FAFAFA`). |
| `onSurface` | Primary text color over surfaces — near-black (template: `#1F1F1F`). |
| `error` | A red/negative accent; if absent, keep template `#D7373F`. |
| `heroGradient` | Two stops sampled from the offer hero banner; if flat, use `[primary, primary]`. |

Notes: sample colors from flat fills, not from anti-aliased edges or shadows. For SVG, read `fill`/`stop-color` attributes for exact hex. 6-digit RGB only — the build step prepends `0xFF` → `Color(0xFFRRGGBB)`.

---

## Typography → `TextTheme`

Map `typography.scale` onto the slots the screens actually use (`headlineSmall`, `titleMedium`, `bodyMedium`/`labelSmall`). Numeric weights → `FontWeight.w###`.

| `scale` key | Flutter slot | Used by |
|---|---|---|
| `headline` | `headlineSmall` | landing "Welcome", login "Sign in" |
| `title` | `titleMedium` | rewards/offer section headings |
| `body` | `bodyMedium` | subheads, descriptions |
| `label` | `labelSmall` | chips, field labels, captions |

- `fontFamily`: prefer a Google Fonts family (add `google_fonts` dep) or a bundled font declared in `pubspec.yaml` `flutter: fonts:`. If the mock font isn't available, pick the closest Google Fonts match and note the substitution in `unmapped`.
- Sizes: read from Figma text styles / PDF spec text where possible; otherwise estimate from rendered cap height relative to known 13–24px template sizes.

---

## Shape & spacing

- `radius.card/button/chip` — corner radii from the mock's cards / buttons / pills. Template defaults 16 / 12 / 20. SVG `rx` gives exact values.
- `spacing.screenPadH/screenPadV/gap` — outer screen padding and inter-element gaps. Template uses 20 horizontal padding, 12–16 gaps. Round to a 4px grid.

---

## Per input type — what to trust

| Input | Most reliable signal | Fall back to |
|---|---|---|
| Figma | Variables → styles (exact hex/px/weight) | node geometry for spacing/radius |
| PDF | redline/spec page text (hex, px, font name) | visual sampling of rendered pages |
| PNG/JPG | visual sampling | — (note estimates in `unmapped`) |
| SVG | `fill`/`stop-color`/`font-*`/`rx` text attributes | visual render |

---

## Worked example — fictional telco "TelcoX" (blue branding)

Suppose the partner supplies a Figma file with a blue primary (`#0B5FFF`), white surfaces, Inter typeface, 12px card radius, and telco copy.

### `partner-brand/<partner>/tokens.json`

```json
{
  "brand": {
    "name": "TelcoX",
    "wordmark": "TelcoX",
    "logo": "assets/telcox-logo.svg",
    "heroImage": "assets/telcox-hero.png"
  },
  "colors": {
    "primary":   "#0B5FFF",
    "onPrimary": "#FFFFFF",
    "secondary": "#00C2FF",
    "surface":   "#FFFFFF",
    "onSurface": "#0A1F44",
    "background":"#F4F7FF",
    "error":     "#D7373F",
    "heroGradient": ["#0B5FFF", "#00C2FF"]
  },
  "typography": {
    "fontFamily": "Inter",
    "scale": {
      "headline": { "size": 24, "weight": 800 },
      "title":    { "size": 17, "weight": 700 },
      "body":     { "size": 13, "weight": 400 },
      "label":    { "size": 11, "weight": 600 }
    }
  },
  "shape": {
    "radius":  { "card": 12, "button": 10, "chip": 20 },
    "spacing": { "screenPadH": 20, "screenPadV": 16, "gap": 12 }
  },
  "copy": {
    "appTitle": "TelcoX Rewards",
    "login":  { "heading": "Sign in", "subhead": "Use your TelcoX ID and password.", "button": "Sign in" },
    "landing":   { "heading": "Welcome", "subhead": "Claim Adobe products with your TelcoX plan.", "primaryCard": "Claim Adobe Express", "secondaryCard": "Find Subscription" },
    "rewards":{ "heading": "Your TelcoX rewards", "offerTitle": "Adobe Express Premium", "offerSubtitle": "12 months free with your plan", "cta": "Claim Now" },
    "offer":  { "appBar": "Adobe Express", "heroTitle": "Anybody can design", "heroSubtitle": "Free Adobe Express Premium for TelcoX members.", "offerTitle": "Adobe Express Premium", "button": "Proceed", "benefits": ["Premium templates", "250 AI credits", "Edit photos & videos"] },
    "benefits": { "appBar": "Find Subscription", "emptyHeading": "Coming soon", "emptyBody": "Look up a customer's subscription by reference ID." }
  },
  "config": {
    "appName": "telcox_rewards",
    "bundleId": "com.telcox.rewards",
    "bffBaseUrl": "http://localhost:8080",
    "offerId": "30006514"
  },
  "unmapped": []
}
```

### Resulting Flutter `ThemeData` (themed `lib/app.dart`)

```dart
// const adobeRed = Color(0xFFEB1000);  ->  TelcoX blue
const brandPrimary = Color(0xFF0B5FFF);
const brandError   = Color(0xFFD7373F);

final colorScheme = ColorScheme.fromSeed(
  seedColor: brandPrimary,
  brightness: Brightness.light,
).copyWith(
  primary: brandPrimary,
  onPrimary: Colors.white,
  secondary: const Color(0xFF00C2FF),
  surface: Colors.white,
  error: brandError,
);

return MaterialApp.router(
  title: 'TelcoX Rewards',
  debugShowCheckedModeBanner: false,
  routerConfig: ref.watch(routerProvider),
  theme: ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: const Color(0xFFF4F7FF),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF0A1F44),
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0A1F44)),
      titleMedium:   TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0A1F44)),
      bodyMedium:    TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFF0A1F44)),
      labelSmall:    TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B6B6B)),
    ),
  ),
);
```

The two brand constants (renamed in spirit but kept as importable top-level `Color`s) recolor every screen that imports them — buttons, drawer highlights, benefit tiles, chips — without per-screen edits. Hero gradient (`#0B5FFF → #00C2FF`) goes into `_Hero` in `express_offer_screen.dart`; logo/hero assets replace the `ExpressLogo`/`AdobeBrand` stand-ins via `Image.asset`. The Adobe integration wiring (`claim_product`, `services/`, BFF) is untouched.
