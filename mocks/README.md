# mocks/ — your design mocks (input to the AI Kit)

Drop your app's screenshots here and the kit builds/rebrands the screens to match them — reproducing your screens while reusing the proven Adobe integration untouched. Used both when a feature is built directly into your app (Mode A) and by the dedicated rebrand skill, `/build-app-from-mocks` (Mode B). **One folder per partner.**

```
mocks/
├── README.md         ← this guide
├── _template/        ← COPY this to mocks/<your-partner>/ and fill it in
│   ├── manifest.md   ← the spec: your screens tagged by role, your wording, your brand
│   ├── screens/      ← your screen images (one per screen) OR your .pptx
│   ├── brand/        ← logo/asset files (svg/png)
│   └── source/       ← optional: original deck, notes
└── <your-partner>/   ← your local filled-in mock set (gitignored)
```

## Adding your mocks — 3 steps

1. **Copy the template:** `cp -r mocks/_template mocks/<your-partner>`
2. **Add your screens** to `mocks/<your-partner>/screens/` — any of:
   - **Exported screen images** (simplest): one PNG per screen, named in order — `slide-1.png`, `slide-2.png`, … (in PowerPoint/Keynote: *File → Export* each slide as PNG).
   - **Your raw `.pptx`/PDF deck**: drop it in `source/` instead — the skill renders each slide into `screens/slide-N.png` for you.
   - **Figma**: skip files entirely and pass `--figma <url>` when you run the skill.
3. **Fill in `manifest.md`.** This is the part that matters most: for each screen, tag it with a **Role** (`login` / `offer` / `benefits` / …) and note what you call it — that's how the kit learns what each screen means in *your* product. Brand colors are optional (auto-detected from your screenshots).

That's it — the kit picks these up automatically once you run a feature build or `/build-app-from-mocks`.

## Rules the skill follows (so output matches your mocks)
- **Exact, not approximate:** colors are pixel-sampled from your images; layout/components reproduce each screen ~90%; nothing of the reference app's UI remains unless a screen shows it.
- **Journey-driven:** the landing screen → app home; the Adobe offer goes where your mock places it; "Get started" opens the Adobe-hosted redeem page (`experience_url`) directly — Adobe's consent/sign-in/product screens are **not** rebuilt.
- **Integration untouched:** the Adobe wiring (IMS/claim/subscription/cancel/notify) is never changed — only theme, layout, copy, and assets.

## What's committed vs. generated
- **Committed (part of the kit):** `README.md`, `_template/`.
- **Gitignored (your input):** each partner folder (`mocks/<your-partner>/`) — what you drop in above.

The skill also creates three **kit-root** directories (siblings of `mocks/`, not inside it) as it works — all gitignored, all per-engagement outputs, not something you create by hand:

| Path | What it is |
|---|---|
| `.ref-source` | A pointer to the app being rebranded (defaults to the Mode A output, i.e. `base-ref-app/` after features are built onto it). |
| `partner-brand/<your-partner>/tokens.json` | The design tokens (colors, typography, copy) the skill extracts from your mocks. |
| `app/` | The materialized, rebranded build — the actual output you get handed back. |

Use `mocks/_template/manifest.md` as the spec format for each partner folder.
