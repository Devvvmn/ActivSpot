#!/bin/bash
# Samples luminance from the wallpaper at the three regions the shell cares
# about, then emits everything in one shot so the QML side can fan it out.
#
# Output (three lines on stdout, parsed by DynamicIsland.bgLumReader):
#   1) 8 perceptual luminances under the workspace-dot row (per-dot)
#   2) 8 perceptual luminances under the bar applet pills (4 left + 4 right)
#   3) overall perceptual average (single int)
#
# Side effects: writes /tmp/qs_bg_luminance (line 3) and /tmp/qs_bar_lum
# (line 2) directly, and only when the content actually changed — so the
# inotify watchers in TopBar stay quiet between wallpaper changes.
#
# Bar-zone rects come from /tmp/qs_bar_zones ("LX LW RX RW", screen px,
# published by TopBar from the real applet-pill geometry). Without it the
# old fallback applies: each half-bar from screen edge to the island
# reservation — much wider than the pills, prone to miss-detection when
# bright sky sits in the empty part of the strip.
#
# Wallpaper-derived data is cached in ~/.cache/quickshell/bar_lum_cache
# keyed by wallpaper path+mtime+screen+zone rects. The ImageMagick passes
# run only when that key changes; the steady-state per-cycle cost is one
# small grim capture for the dot strip.
#
# Pipeline is sRGB → linear → Y (Rec.709) → gamma-encoded back to 0–255 so
# downstream `< 128` thresholds keep working, but the value now reflects what
# the eye actually sees instead of the Rec.601 byte average.

SCREEN_W=${1:-1920}
SCREEN_H=${2:-1080}

DOT_COUNT=8
DOT_SIZE=9
GAP=6
DOT_Y=46

BAR_Y=22
BAR_H=24
BAR_PER_SIDE=4
ISLAND_HALF=160   # half-width reserved for the dynamic island pill

ZONES_FILE=/tmp/qs_bar_zones
CACHE_FILE="$HOME/.cache/quickshell/bar_lum_cache"

# Write a file only when its content changed — keeps inotify consumers quiet.
emit() {
    [ "$(cat "$1" 2>/dev/null)" = "$2" ] || printf '%s' "$2" > "$1"
}

output() {
    echo "${PER_DOT% }"
    echo "${BAR_LINE% }"
    echo "${AVG:-128}"
    emit /tmp/qs_bg_luminance "${AVG:-128}"
    emit /tmp/qs_bar_lum "${BAR_LINE% }"
    exit 0
}

fallback() {
    PER_DOT="128 128 128 128 128 128 128 128"
    BAR_LINE="128 128 128 128 128 128 128 128"
    AVG=128
    output
}

WALLPAPER=$(cat "$HOME/.cache/wallpaper_picker/current" 2>/dev/null | tr -d '[:space:]')
[ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ] && fallback

# Bar-zone rects: prefer the real applet-pill geometry published by TopBar.
LX=0
LW=$(( SCREEN_W / 2 - ISLAND_HALF ))
RX=$(( SCREEN_W / 2 + ISLAND_HALF ))
RW=$(( SCREEN_W - RX ))
if [ -r "$ZONES_FILE" ]; then
    read -r zlx zlw zrx zrw _ < "$ZONES_FILE"
    if [[ "$zlx" =~ ^[0-9]+$ && "$zlw" =~ ^[1-9][0-9]*$ && \
          "$zrx" =~ ^[0-9]+$ && "$zrw" =~ ^[1-9][0-9]*$ ]]; then
        LX=$zlx; LW=$zlw; RX=$zrx; RW=$zrw
    fi
fi

WP_MTIME=$(stat -c %Y "$WALLPAPER" 2>/dev/null)
KEY="v2|$WALLPAPER|$WP_MTIME|${SCREEN_W}x${SCREEN_H}|$LX $LW $RX $RW"

# Cache: line 1 = key, line 2 = bar line, line 3 = wallpaper dot fallback.
BAR_LINE=""
DOT_FALLBACK=""
if [ -r "$CACHE_FILE" ]; then
    { read -r ckey; read -r cbar; read -r cdot; } < "$CACHE_FILE"
    if [ "$ckey" = "$KEY" ] && [ -n "$cbar" ]; then
        BAR_LINE=$cbar
        DOT_FALLBACK=$cdot
    fi
fi

# Perceptual luminance via sRGB EOTF/OETF + Rec.709 weights. Re-encoded so the
# value reads on the same 0–255 scale as the old Rec.601 byte average.
PERCEPTUAL_AWK='
function srgb_lin(c,    n) {
    n = c / 255.0
    return (n <= 0.04045) ? (n / 12.92) : (((n + 0.055) / 1.055) ^ 2.4)
}
function lin_srgb(c) {
    return (c <= 0.0031308) ? (12.92 * c) : (1.055 * (c ^ (1/2.4)) - 0.055)
}
NR > 1 {
    if (match($0, /\(([0-9]+),([0-9]+),([0-9]+)/, c) == 0) next
    r = srgb_lin(c[1]); g = srgb_lin(c[2]); b = srgb_lin(c[3])
    y = 0.2126 * r + 0.7152 * g + 0.0722 * b
    printf "%d ", int(lin_srgb(y) * 255 + 0.5)
}'

sample_strip() {
    local rect=$1
    local cols=$2
    convert "$WALLPAPER" \
        -crop "$rect" +repage \
        -resize "${cols}x1!" \
        -depth 8 txt:- 2>/dev/null \
      | awk "$PERCEPTUAL_AWK"
}

if [ -z "$BAR_LINE" ]; then
    WP_W=$(identify -format "%w" "$WALLPAPER" 2>/dev/null)
    WP_H=$(identify -format "%h" "$WALLPAPER" 2>/dev/null)
    [ -z "$WP_W" ] && fallback

    # All three crop rectangles in wallpaper-pixel coords, mapped through the
    # `cover` transform so they line up with what the user actually sees.
    COORDS=$(python3 - "$SCREEN_W" "$SCREEN_H" "$WP_W" "$WP_H" \
            "$DOT_COUNT" "$DOT_SIZE" "$GAP" "$DOT_Y" \
            "$BAR_Y" "$BAR_H" "$LX" "$LW" "$RX" "$RW" <<'PY'
import sys
sw, sh, ww, wh = map(int, sys.argv[1:5])
dot_count, dot_size, gap, dot_y = map(int, sys.argv[5:9])
bar_y, bar_h                   = map(int, sys.argv[9:11])
lx, lw, rx, rw                 = map(int, sys.argv[11:15])

scale = max(sw / ww, sh / wh)
eff_w = ww * scale
eff_h = wh * scale
ox = (eff_w - sw) / 2
oy = (eff_h - sh) / 2

def to_wp(sx, sy):
    return int((sx + ox) / scale), int((sy + oy) / scale)

def to_wp_size(w, h):
    return max(1, int(w / scale)), max(1, int(h / scale))

# Dot strip
total_w = dot_count * dot_size + (dot_count - 1) * gap
dx, dy = to_wp(sw / 2 - total_w / 2, dot_y)
dw, dh = to_wp_size(total_w, dot_size)

# Bar strips — exactly under the applet pills
plx, ply = to_wp(lx, bar_y)
plw, plh = to_wp_size(lw, bar_h)
prx, pry = to_wp(rx, bar_y)
prw, prh = to_wp_size(rw, bar_h)

print(f"{dw}x{dh}+{dx}+{dy}")
print(f"{plw}x{plh}+{plx}+{ply}")
print(f"{prw}x{prh}+{prx}+{pry}")
PY
    )
    [ -z "$COORDS" ] && fallback

    DOT_RECT=$(echo "$COORDS"  | sed -n '1p')
    LEFT_RECT=$(echo "$COORDS" | sed -n '2p')
    RIGHT_RECT=$(echo "$COORDS" | sed -n '3p')

    LEFT_BAR=$(sample_strip "$LEFT_RECT" "$BAR_PER_SIDE")
    RIGHT_BAR=$(sample_strip "$RIGHT_RECT" "$BAR_PER_SIDE")
    DOT_FALLBACK=$(sample_strip "$DOT_RECT" "$DOT_COUNT")

    [ -z "$LEFT_BAR" ]  && LEFT_BAR="128 128 128 128 "
    [ -z "$RIGHT_BAR" ] && RIGHT_BAR="128 128 128 128 "
    [ -z "$DOT_FALLBACK" ] && DOT_FALLBACK="128 128 128 128 128 128 128 128"

    BAR_LINE="${LEFT_BAR}${RIGHT_BAR}"
    BAR_LINE="${BAR_LINE% }"
    DOT_FALLBACK="${DOT_FALLBACK% }"

    mkdir -p "$(dirname "$CACHE_FILE")"
    printf '%s\n%s\n%s\n' "$KEY" "$BAR_LINE" "$DOT_FALLBACK" > "$CACHE_FILE"
fi

# For dots: prefer a live grim screenshot just below the island pill (y≈52)
# so cloud patterns that are brighter than the wallpaper file's tile at that
# position are captured correctly. Fall back to wallpaper sampling if grim
# is unavailable or fails.
_dot_total_w=$(( DOT_COUNT * DOT_SIZE + (DOT_COUNT - 1) * GAP ))
_dot_sx=$(( SCREEN_W / 2 - _dot_total_w / 2 - 4 ))
_dot_sw=$(( _dot_total_w + 8 ))
_dot_sy=52   # just below the ~44 px island pill bottom
PER_DOT=""
if command -v grim &>/dev/null && [ -n "${WAYLAND_DISPLAY:-}" ]; then
    PER_DOT=$(grim -l 0 -g "${_dot_sx},${_dot_sy} ${_dot_sw}x4" - 2>/dev/null \
        | convert - -resize "${DOT_COUNT}x1!" -depth 8 txt:- 2>/dev/null \
        | awk "$PERCEPTUAL_AWK")
fi
[ -z "$PER_DOT" ] && PER_DOT=$DOT_FALLBACK
[ -z "$PER_DOT" ] && PER_DOT="128 128 128 128 128 128 128 128"

ALL="${PER_DOT} ${BAR_LINE}"
AVG=$(awk '{ s = 0; n = 0; for (i = 1; i <= NF; i++) { s += $i; n++ } print (n > 0 ? int(s / n) : 128) }' <<<"$ALL")

output
