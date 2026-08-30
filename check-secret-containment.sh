#!/usr/bin/env bash
set -euo pipefail

# Adobe Integration APIs — Partner AI Kit
# Secret-containment check (verification.md Rule 9 — enforced, name-based).
#
# IMS credentials, *_CLIENT_SECRET, and any Adobe token-issuing config must appear
# ONLY in the backend surface. This script reads .target-apps, greps every
# NON-backend surface (web / mobile / ios / android, and the monorepo root minus
# the backend) for those NAMES, and exits non-zero if any leaked.
#
# It inspects NAMES only (never values) and never writes anything.
#   ./check-secret-containment.sh            # uses ./.target-apps
#   ./check-secret-containment.sh /path/reg  # explicit registry file

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REG="${1:-$KIT_DIR/.target-apps}"

# Parse "<surface> = <path>" lines.
backend_paths=()
declare -a scan_paths=()   # non-backend surfaces (label:path)
root_path=""

if [ ! -f "$REG" ]; then
  # Fast path: no partner repo registered, so the kit's bundled base app is the
  # target. Scan it in place rather than doing nothing — Rule 9 must still be
  # enforceable here (the fast path deliberately omits .target-apps).
  if [ -d "$KIT_DIR/base-ref-app" ]; then
    echo "ℹ️  No target registry — scanning the bundled base-ref-app/ (fast path)."
    backend_paths=("$KIT_DIR/base-ref-app/bff")
    root_path="$KIT_DIR/base-ref-app"
  else
    echo "ℹ️  No target registry at $REG and no base-ref-app/ — run ./INSTALL.sh <path(s)> first. Nothing to check."
    exit 0
  fi
else
  while IFS= read -r line; do
    case "$line" in \#*|"") continue;; esac
    key="$(printf '%s' "$line" | sed -E 's/[[:space:]]*=.*$//' | tr -d '[:space:]')"
    val="$(printf '%s' "$line" | sed -E 's/^[^=]*=[[:space:]]*//')"
    [ -z "$val" ] && continue
    case "$key" in
      backend) backend_paths+=("$val");;
      root)    root_path="$val";;
      web|mobile|ios|android) scan_paths+=("$key:$val");;
    esac
  done < "$REG"
fi

# The root surface is scanned too (a monorepo root often holds the frontend), but
# the backend subtree inside it is excluded below.
[ -n "$root_path" ] && scan_paths+=("root:$root_path")

if [ "${#scan_paths[@]}" -eq 0 ]; then
  echo "ℹ️  No non-backend surfaces registered — nothing to check."
  exit 0
fi

# Secret / token-issuing NAMES that must never appear outside the backend.
PATTERN='CLIENT_SECRET|client_secret|clientSecret|ADOBE_SECRET|IMS_CLIENT_SECRET|ADOBE_IMS_CLIENT_SECRET|ADOBE_IMS_TOKEN_URL|IMS_TOKEN_URL'

# Directories that are never source (build output, deps, and documentation —
# service cards, LLDs, and checklists legitimately *name* these secrets in prose,
# which is not a leak: this check is name-based and about frontend SOURCE code).
PRUNE=( node_modules build dist .git .dart_tool .gradle .next .nuxt Pods docs service-cards )

leaks=0
for entry in "${scan_paths[@]}"; do
  label="${entry%%:*}"; path="${entry#*:}"
  [ -d "$path" ] || { echo "⚠️  $label path not found: $path (skipping)"; continue; }
  abs="$(cd "$path" && pwd)"

  # Build find prune expression + backend-subtree exclusions.
  find_cmd=(find "$abs")
  for d in "${PRUNE[@]}"; do find_cmd+=( -name "$d" -prune -o ); done
  # Exclude any backend path nested under this surface (avoid flagging legit backend use).
  # "${backend_paths[@]:-}" guards against macOS's default bash 3.2, which treats
  # an empty array as an unbound variable under `set -u` (a web-only/mobile-only
  # registration with no `backend` entry would otherwise crash here).
  for bp in "${backend_paths[@]:-}"; do
    [ -z "$bp" ] && continue
    babs="$(cd "$bp" 2>/dev/null && pwd || echo "$bp")"
    find_cmd+=( -path "$babs*" -prune -o )
  done
  find_cmd+=( -type f -not -name '*.example' -not -name '*.example.*' -not -name '*.md' -print )

  while IFS= read -r f; do
    if grep -InE "$PATTERN" "$f" >/dev/null 2>&1; then
      echo "❌ LEAK in $label surface: $f"
      grep -InE "$PATTERN" "$f" | sed 's/^/     /'
      leaks=$((leaks+1))
    fi
  done < <("${find_cmd[@]}" 2>/dev/null)
done

if [ "$leaks" -gt 0 ]; then
  echo ""
  echo "❌ Secret-containment FAILED: $leaks file(s) outside the backend reference IMS/secret names."
  echo "   Move all Adobe token-issuing calls to the backend (see verification.md Rule 9)."
  exit 1
fi

echo "✅ Secret containment OK — no IMS/secret names found outside the backend surface."
exit 0
