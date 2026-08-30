# UI Platform — {surface}

> _Runtime and build facts for this UI surface. Fill every `<fill>` / `TODO`.
> §5 is authoritative for the verify step. See
> [card-model §3.2](../../../manual/methodology/card-model.md) and
> [verification rule 5](../../../manual/methodology/verification.md)._

## 1. Runtime

_Language/SDK versions and target platform(s) for this surface._

- **Language / SDK:** `<fill>`
- **Framework version:** `<fill>`
- **Target(s):** `<fill>`

## 2. Build

_Build tool and how a production bundle/artifact is produced._

- **Build tool:** `<fill>`
- **Output artifact:** `<fill>`

## 3. Environment Variables

_Client-safe config only. No IMS credentials or `*_CLIENT_SECRET` may appear on
this surface (per [verification rule 9](../../../manual/methodology/verification.md)). The
partner-backend base URL is the key one._

| Variable | Purpose | Source |
|---|---|---|
| `<fill>` | Partner backend base URL | `<fill>` |
| `<fill>` | TODO | `<fill>` |

## 4. Local Development

_How a developer runs this surface locally against the partner backend._

- **Install deps:** `<fill>`
- **Run:** `<fill>`
- TODO

## 5. Build Interface (AUTHORITATIVE verify commands)

> _These are the EXACT commands the verify step runs for this surface, in its own
> repo ([verification rule 5](../../../manual/methodology/verification.md)). Fill each cell with
> the real command; leave a cell as `n/a` only if the surface truly has no such
> step._

| Phase | Command |
|---|---|
| Setup | `<fill>` (e.g. `flutter pub get` / `npm ci` / `pod install` / `./gradlew`) |
| Build | `<fill>` |
| Analyze / Typecheck | `<fill>` (e.g. `flutter analyze` / `tsc --noEmit` / `swift build` / `./gradlew assembleDebug`) |
| Test | `<fill>` |

## 6. Accessibility

_Accessibility conventions this surface follows (semantics/labels, focus order,
contrast). Generated screens must not regress these._

- TODO

## 7. Analytics (optional)

_If the surface has analytics, how integration screens emit events. Omit if not
used._

- TODO
