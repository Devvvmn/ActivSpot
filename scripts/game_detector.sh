#!/usr/bin/env bash
# Detects active Steam game via Hyprland window class.
# Parses all Steam library paths from libraryfolders.vdf,
# finds the appmanifest, resolves cover art (local cache → CDN).
# Writes JSON to /tmp/qs_game_active every poll cycle.

OUT_FILE="/tmp/qs_game_active"
STEAM_DIR="$HOME/.local/share/Steam"
COVER_CACHE="$HOME/.cache/qs_game_covers"
POLL=3

mkdir -p "$COVER_CACHE"
echo '{"active":false}' > "$OUT_FILE"

# Returns all steamapps/ paths (one per line), deduped.
get_library_paths() {
    local vdf="$STEAM_DIR/steamapps/libraryfolders.vdf"
    {
        # Main library is always present
        echo "$STEAM_DIR/steamapps"
        # Additional libraries listed in vdf
        if [[ -f "$vdf" ]]; then
            grep -oP '"path"\s+"\K[^"]+' "$vdf" | sed 's|$|/steamapps|'
        fi
    } | sort -u
}

find_manifest() {
    local appid="$1"
    while IFS= read -r libpath; do
        local f="$libpath/appmanifest_${appid}.acf"
        [[ -f "$f" ]] && { echo "$f"; return 0; }
    done < <(get_library_paths)
    return 1
}

get_cover() {
    local appid="$1"
    # Prefer locally cached Steam artwork (downloaded by Steam client)
    local local_v="$STEAM_DIR/appcache/librarycache/${appid}_library_600x900.jpg"
    local local_h="$STEAM_DIR/appcache/librarycache/${appid}_header.jpg"
    local cached="$COVER_CACHE/${appid}.jpg"

    if   [[ -f "$local_v" ]]; then echo "file://$local_v"
    elif [[ -f "$local_h" ]]; then echo "file://$local_h"
    elif [[ -f "$cached"  ]]; then echo "file://$cached"
    else
        # Download vertical cover from Steam CDN
        if curl -sf --max-time 5 \
            "https://cdn.akamai.steamstatic.com/steam/apps/${appid}/library_600x900.jpg" \
            -o "$cached" 2>/dev/null; then
            echo "file://$cached"
        else
            echo ""
        fi
    fi
}

last_appid=""

while true; do
    # Look for window with class steam_app_XXXXXXX
    appid=$(hyprctl clients -j 2>/dev/null \
        | grep -oP '"initialClass":\s*"steam_app_\K[0-9]+' \
        | head -1)

    if [[ -z "$appid" ]]; then
        if [[ -n "$last_appid" ]]; then
            echo '{"active":false}' > "$OUT_FILE"
            last_appid=""
        fi
        sleep "$POLL"
        continue
    fi

    if [[ "$appid" == "$last_appid" ]]; then
        sleep "$POLL"
        continue
    fi

    last_appid="$appid"

    manifest=$(find_manifest "$appid")
    if [[ -z "$manifest" ]]; then
        echo '{"active":false}' > "$OUT_FILE"
        sleep "$POLL"
        continue
    fi

    name=$(grep -oP '"name"\s+"\K[^"]+' "$manifest" | head -1)
    cover=$(get_cover "$appid")
    start=$(date +%s)

    # Escape name for JSON (basic: replace " and \)
    name_esc="${name//\\/\\\\}"
    name_esc="${name_esc//\"/\\\"}"

    printf '{"active":true,"appid":"%s","name":"%s","cover":"%s","start":%d}\n' \
        "$appid" "$name_esc" "$cover" "$start" > "$OUT_FILE"

    sleep "$POLL"
done
