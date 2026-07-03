#!/usr/bin/env bash
# Pack an addon source dir into a distributable .qsplugin (a zip with
# manifest.json at the root). Source of truth lives in scripts/addons-src/<id>/;
# output goes to dist/<id>.qsplugin (gitignored — upload to GitHub Releases).
#
# Usage:
#   pack_addon.sh <id>     pack one addon
#   pack_addon.sh all      pack every addon under addons-src/
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$ROOT/scripts/addons-src"
OUT_DIR="$ROOT/dist"
mkdir -p "$OUT_DIR"

pack_one() {
    local id="$1"
    local dir="$SRC_DIR/$id"
    [ -f "$dir/manifest.json" ] || { echo "skip $id: no manifest.json" >&2; return 1; }

    local mid
    mid="$(jq -r '.id // empty' "$dir/manifest.json" 2>/dev/null)"
    [ "$mid" = "$id" ] || { echo "skip $id: manifest id '$mid' != dir name" >&2; return 1; }

    local out="$OUT_DIR/$id.qsplugin"
    rm -f "$out"
    # zip contents of the dir so manifest.json sits at the archive root.
    ( cd "$dir" && zip -q -r "$out" . -x '.*' '*/.*' )
    echo "packed  $out  ($(jq -r '.version // "?"' "$dir/manifest.json"))"
}

if [ "${1:-all}" = "all" ]; then
    for d in "$SRC_DIR"/*/; do pack_one "$(basename "$d")" || true; done
else
    pack_one "$1"
fi
