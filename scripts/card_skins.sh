#!/usr/bin/env bash
# Aggregates system-card (SysInfoCard) skins from the built-in skins dir and
# from installed addons that declare a `cardSkin` manifest field.
#
#   card_skins.sh list   → JSON array of skin objects (each is the skin JSON
#                          plus a normalized `id` and a `builtin` boolean)
#
# Single source of truth for skin discovery: SysInfoCard.qml runs this via a
# Process, and the config-ui server execs it for /api/cardskins. Skin DATA
# itself lives only in the JSON files.
set -euo pipefail

HYPR="$HOME/.config/hypr"
BUILTIN_DIR="$HYPR/scripts/quickshell/sysinfo/skins"
PLUGINS_DIR="$HYPR/plugins"

# emit <json-file> <builtin-bool> <fallback-id>
emit() {
    jq -c --argjson b "$2" --arg fid "$3" \
       '. + {id: (.id // $fid), builtin: $b}' "$1" 2>/dev/null || true
}

list() {
    local items=()

    if [ -d "$BUILTIN_DIR" ]; then
        for f in "$BUILTIN_DIR"/*.json; do
            [ -e "$f" ] || continue
            items+=("$(emit "$f" true "$(basename "$f" .json)")")
        done
    fi

    if [ -d "$PLUGINS_DIR" ]; then
        for m in "$PLUGINS_DIR"/*/manifest.json; do
            [ -e "$m" ] || continue
            local rel dir pid f
            rel="$(jq -r '.cardSkin // empty' "$m" 2>/dev/null)"
            [ -n "$rel" ] || continue
            dir="$(dirname "$m")"
            f="$dir/$rel"
            [ -f "$f" ] || continue
            pid="$(jq -r '.id // empty' "$m")"
            items+=("$(emit "$f" false "$pid")")
        done
    fi

    if [ "${#items[@]}" -eq 0 ]; then
        echo "[]"
    else
        printf '%s\n' "${items[@]}" | jq -s '.'
    fi
}

case "${1:-list}" in
    list) list ;;
    *) echo "usage: $0 list" >&2; exit 1 ;;
esac
