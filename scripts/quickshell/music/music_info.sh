#!/usr/bin/env bash

TMP_DIR="/tmp/eww_covers"
mkdir -p "$TMP_DIR"
PLACEHOLDER="$TMP_DIR/placeholder_blank.png"
STATE_FILE="$TMP_DIR/last_state.json"

# --- 1. ENSURE PLACEHOLDER EXISTS ---
if [ ! -f "$PLACEHOLDER" ]; then
    convert -size 500x500 xc:"#313244" "$PLACEHOLDER"
fi

# Resolve an mpris:artUrl file path to something actually openable from the host.
# Sandboxed browsers (flatpak/snap Chrome, Chromium, Brave…) expose artwork as
# e.g. file:///tmp/.com.google.Chrome.XXXX — a temp file in the app's PRIVATE
# /tmp, invisible on the host. It is reachable via /proc/<pid>/root, but only
# through a *dumpable* pid (sandbox renderers return EACCES), so we probe pids
# with a real 1-byte read and return the first that opens. Echoes the usable
# path on success, nothing on failure.
resolve_art_path() {
    local path="${1#file://}"
    [ -z "$path" ] && return 1
    # Host-visible already?
    if dd if="$path" bs=1 count=1 >/dev/null 2>&1; then
        printf '%s' "$path"; return 0
    fi
    # Only hidden /tmp temp files come from sandboxed browsers — scan their pids.
    case "$path" in
        /tmp/.*) ;;
        *) return 1 ;;
    esac
    local pid src
    for pid in $(pgrep -f 'chrom|brave|edge|vivaldi|opera|electron' 2>/dev/null); do
        src="/proc/$pid/root$path"
        if dd if="$src" bs=1 count=1 >/dev/null 2>&1; then
            printf '%s' "$src"; return 0
        fi
    done
    return 1
}

# --- 2. ONE playerctl CALL for everything ---
PLAYER_FLAG=""
[ -n "$1" ] && PLAYER_FLAG="--player $1"

raw=$(playerctl $PLAYER_FLAG metadata --format \
    '{{status}}|{{xesam:title}}|{{xesam:artist}}|{{mpris:artUrl}}|{{mpris:length}}|{{position}}|{{playerName}}' \
    2>/dev/null)

if [ -z "$raw" ]; then
    STATUS="Stopped"
else
    IFS='|' read -r STATUS TITLE ARTIST rawUrl len_micro pos_micro player_raw <<< "$raw"
fi

if [ "$STATUS" = "Playing" ] || [ "$STATUS" = "Paused" ]; then

    # --- 3. ART CACHE LOGIC ---
    idStr="${TITLE:-unknown}-${ARTIST:-unknown}"
    trackHash=$(echo "$idStr" | md5sum | cut -d" " -f1)

    finalArt="$TMP_DIR/${trackHash}_art.jpg"
    blurPath="$TMP_DIR/${trackHash}_blur.png"
    lockFile="$TMP_DIR/${trackHash}.lock"

    displayArt="$PLACEHOLDER"
    displayBlur="$PLACEHOLDER"

    if [ -f "$finalArt" ] && [ -s "$finalArt" ]; then
        displayArt="$finalArt"
        if [ -f "$blurPath" ]; then displayBlur="$blurPath"; fi
    else
        if [ ! -f "$lockFile" ] && [ -n "$rawUrl" ]; then
            touch "$lockFile"
            (
                trap "rm -f '$lockFile'" EXIT
                # Fetch into a temp first; only commit to the cache if it turns
                # out to be a real raster image. A failed fetch leaves NO cache
                # entry, so the next tick retries instead of locking in the
                # placeholder forever (the old behaviour broke sandboxed Chrome).
                tmpArt="$TMP_DIR/${trackHash}_art.tmp"
                rm -f "$tmpArt"

                if [[ "$rawUrl" == http* ]]; then
                    curl -s -L --max-time 10 -o "$tmpArt" "$rawUrl"
                else
                    cleanPath=$(resolve_art_path "$rawUrl")
                    [ -n "$cleanPath" ] && cp "$cleanPath" "$tmpArt" 2>/dev/null
                fi

                # Valid image with real dimensions? then commit + blur.
                if [ -s "$tmpArt" ] && identify -format '%wx%h' "$tmpArt" >/dev/null 2>&1; then
                    mv -f "$tmpArt" "$finalArt"
                    convert "$finalArt" -blur 0x20 -brightness-contrast -30x-10 "$blurPath" 2>/dev/null \
                        || cp "$finalArt" "$blurPath"
                else
                    rm -f "$tmpArt"   # no real art this tick — leave cache empty, retry later
                fi

                rm -f "$lockFile"
                (cd "$TMP_DIR" && ls -1t | tail -n +21 | xargs -r rm 2>/dev/null)
            ) &
        fi
    fi

    # --- 4. TIMING ---
    [ -z "$len_micro" ] || [ "$len_micro" -eq 0 ] 2>/dev/null && len_micro=1000000
    len_sec=$(( ${len_micro:-1000000} / 1000000 ))
    [ "$len_sec" -le 0 ] && len_sec=1

    if [ "$STATUS" = "Playing" ]; then
        pos_sec=$(( ${pos_micro:-0} / 1000000 ))
        jq -n -c --argjson pos "$pos_sec" --argjson len "$len_sec" \
            '{pos_sec: $pos, len_sec: $len}' > "$STATE_FILE"
    else
        pos_sec=0
        if [ -f "$STATE_FILE" ]; then
            saved_pos=$(jq -r '.pos_sec' "$STATE_FILE" 2>/dev/null)
            saved_len=$(jq -r '.len_sec' "$STATE_FILE" 2>/dev/null)
            if [ "$saved_len" = "$len_sec" ] && [ -n "$saved_pos" ] && [ "$saved_pos" != "null" ]; then
                pos_sec=$saved_pos
            fi
        fi
    fi

    [ "$pos_sec" -gt "$len_sec" ] && pos_sec=$len_sec
    percent=$(( pos_sec * 100 / len_sec ))
    pos_str=$(printf "%02d:%02d" $((pos_sec/60)) $((pos_sec%60)))
    len_str=$(printf "%02d:%02d" $((len_sec/60)) $((len_sec%60)))

    # --- 5. OUTPUT ---
    player_nice="${player_raw^}"

    jq -n -c \
        --arg title   "${TITLE:-}" \
        --arg artist  "${ARTIST:-}" \
        --arg status  "$STATUS" \
        --arg len     "$len_sec" \
        --arg pos     "$pos_sec" \
        --arg len_str "$len_str" \
        --arg pos_str "$pos_str" \
        --arg percent "$percent" \
        --arg pname   "$player_raw" \
        --arg pnice   "$player_nice" \
        --arg blur    "file://$displayBlur" \
        --arg art     "file://$displayArt" \
        '{
            title:       $title,
            artist:      $artist,
            status:      $status,
            length:      ($len | tonumber),
            position:    ($pos | tonumber),
            lengthStr:   $len_str,
            positionStr: $pos_str,
            timeStr:     ($pos_str + " / " + $len_str),
            percent:     ($percent | tonumber),
            playerName:  $pname,
            source:      $pnice,
            blur:        $blur,
            artUrl:      $art
        }'

else
    # --- FALLBACK (Stopped) ---
    if [ -f "$STATE_FILE" ]; then
        last_pos=$(jq -r '.pos_sec' "$STATE_FILE" 2>/dev/null)
        last_len=$(jq -r '.len_sec' "$STATE_FILE" 2>/dev/null)
    fi
    last_pos=${last_pos:-0}; last_len=${last_len:-1}
    [ "$last_len" -le 0 ] 2>/dev/null && last_len=1
    last_percent=$(( last_pos * 100 / last_len ))
    last_pos_str=$(printf "%02d:%02d" $((last_pos/60)) $((last_pos%60)))
    last_len_str=$(printf "%02d:%02d" $((last_len/60)) $((last_len%60)))

    jq -n -c \
        --arg placeholder "file://$PLACEHOLDER" \
        --arg pos_str "$last_pos_str" \
        --arg len_str "$last_len_str" \
        --arg percent "$last_percent" \
        '{
            title:       "Not Playing",
            artist:      "",
            status:      "Stopped",
            percent:     ($percent | tonumber),
            lengthStr:   $len_str,
            positionStr: $pos_str,
            timeStr:     ($pos_str + " / " + $len_str),
            source:      "Offline",
            playerName:  "",
            blur:        $placeholder,
            artUrl:      $placeholder
        }'
fi
