#!/usr/bin/env bash
set -euo pipefail

# Adobe Integration APIs — Partner AI Kit
# Standalone TOOL. Run it FROM the cloned kit and point it at your app(s):
#   ./INSTALL.sh /path/to/monorepo
#   ./INSTALL.sh --backend /p/be --ios /p/ios --android /p/aa --web /p/web
#   ./INSTALL.sh --backend /p/be --mobile /p/app
#   ./INSTALL.sh /path/to/monorepo --backend /p/be      # hybrid: root + override
#
# It only RECORDS your app path(s) in .target-apps; it does NOT modify your app(s).
# Skills then resolve each surface as "its own entry, else the monorepo root".

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'USAGE'
Usage:
  ./INSTALL.sh <path-to-monorepo>
  ./INSTALL.sh [--backend P] [--web P] [--mobile P] [--ios P] [--android P]
  ./INSTALL.sh <path-to-monorepo> [--backend P] ...      # hybrid: root + overrides

Surfaces: backend, web, mobile, ios, android
  mobile       = one cross-platform app (Flutter / React Native)
  ios/android  = native apps (mutually exclusive with mobile)
A surface with no explicit path falls back to the monorepo root (if one is given).
USAGE
}

root=""
sb=""; sw=""; sm=""; si=""; sa=""

require_value() {   # <flag> <$#> <next-arg>
  local flag="$1" argc="$2" next="${3:-}"
  if [ "$argc" -lt 2 ] || [ -z "$next" ] || [ "${next#-}" != "$next" ]; then
    echo "✗ $flag requires a path argument" >&2; exit 1
  fi
}

while [ $# -gt 0 ]; do
  case "$1" in
    --backend) require_value "--backend" "$#" "${2:-}"; sb="$2"; shift 2;;
    --web)     require_value "--web"     "$#" "${2:-}"; sw="$2"; shift 2;;
    --mobile)  require_value "--mobile"  "$#" "${2:-}"; sm="$2"; shift 2;;
    --ios)     require_value "--ios"     "$#" "${2:-}"; si="$2"; shift 2;;
    --android) require_value "--android" "$#" "${2:-}"; sa="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    --*) echo "✗ Unknown flag: $1" >&2; usage; exit 1;;
    *)
      if [ -n "$root" ]; then echo "✗ More than one monorepo root given: $1" >&2; exit 1; fi
      root="$1"; shift;;
  esac
done

if [ -z "$root" ] && [ -z "$sb$sw$sm$si$sa" ]; then
  usage; exit 1
fi

if [ -n "$sm" ] && { [ -n "$si" ] || [ -n "$sa" ]; }; then
  echo "✗ --mobile is mutually exclusive with --ios/--android (cross-platform OR native, not both)." >&2
  exit 1
fi

normalize() {            # <path> <label>  -> prints abs path, or errors and returns 1
  local p="$1" label="$2"
  if [ ! -d "$p" ]; then echo "✗ $label path not found: $p" >&2; return 1; fi
  p="$(cd "$p" && pwd)"
  if [ "$p" = "$KIT_DIR" ]; then echo "✗ $label path is the kit itself. Pass your application's path." >&2; return 1; fi
  printf '%s' "$p"
}

has_marker() {           # <dir> -> 0 if a recognised project file exists (self or <=depth 2)
  local d="$1" f
  # Polyglot monorepos often keep no marker at the root (e.g. a Flutter repo whose
  # backend lives in bff/); scan the dir itself plus subdirectories to depth 2.
  local names="package.json pom.xml build.gradle build.gradle.kts pubspec.yaml \
               go.mod Cargo.toml requirements.txt pyproject.toml Package.swift Gemfile"
  for f in $names; do
    if find "$d" -maxdepth 2 -type f -name "$f" \
         -not -path '*/node_modules/*' -not -path '*/build/*' \
         -not -path '*/.git/*' -not -path '*/.dart_tool/*' 2>/dev/null | grep -q .; then
      return 0
    fi
  done
  # wildcard markers: .NET (*.csproj/*.sln/*.slnx), Rails (gemspec / config/routes.rb)
  for f in "*.csproj" "*.sln" "*.slnx" "*.gemspec"; do
    if find "$d" -maxdepth 2 -type f -name "$f" \
         -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null | grep -q .; then
      return 0
    fi
  done
  find "$d" -maxdepth 3 -type f -path '*/config/routes.rb' 2>/dev/null | grep -q . && return 0
  return 1
}

REG="$KIT_DIR/.target-apps"
TMP="$(mktemp)"
trap 'rm -f "${TMP:-}"' EXIT
echo "# Adobe AI Kit target registry — <surface> = <absolute path>. See CLAUDE.md." > "$TMP"

emit() {                 # <key> <raw-path>  (no-op when path empty)
  local key="$1" val="$2" abs
  [ -z "$val" ] && return 0
  abs="$(normalize "$val" "$key")" || { rm -f "$TMP"; exit 1; }
  has_marker "$abs" || echo "ℹ️  No project marker found within $key $abs (scanned to depth 2) — registering anyway; surface detection runs deeper at analyze time."
  printf '%-7s = %s\n' "$key" "$abs" >> "$TMP"
}

emit root    "$root"
emit backend "$sb"
emit web     "$sw"
emit mobile  "$sm"
emit ios     "$si"
emit android "$sa"

mv "$TMP" "$REG"

# Supersede the legacy single-path file so there is one source of truth.
if [ -f "$KIT_DIR/.target-app" ]; then
  rm -f "$KIT_DIR/.target-app"
  echo "ℹ️  Removed legacy .target-app (superseded by .target-apps)."
fi

echo ""
echo "✅ Target registry written: $REG"
sed 's/^/   /' "$REG"
echo ""
echo "Next:"
echo "  1. Open Claude Code in the kit:  $KIT_DIR"
echo "  2. (Optional) drop UI mocks into  mocks/"
echo "  3. Run:  /analyze-partner-codebase"
echo ""
