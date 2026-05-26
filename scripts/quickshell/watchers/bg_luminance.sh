#!/bin/bash
# Samples luminance from the wallpaper at the three regions the shell cares
# about, then emits everything in one shot so the QML side can fan it out.
#
# Output (three lines):
#   1) 8 perceptual luminances under the workspace-dot row (per-dot)
#   2) 8 perceptual luminances under the bar applet zones (4 left + 4 right,
#      skipping the central island reservation)
#   3) overall perceptual average (single int, kept for callers that still
#      read /tmp/qs_bg_luminance directly)
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

WALLPAPER=$(cat "$HOME/.cache/wallpaper_picker/current" 2>/dev/null | tr -d '[:space:]')

fallback() {
    echo "128 128 128 128 128 128 128 128"
    echo "128 128 128 128 128 128 128 128"
    echo "128"
    exit 0
}

[ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ] && fallback

WP_W=$(identify -format "%w" "$WALLPAPER" 2>/dev/null)
WP_H=$(identify -format "%h" "$WALLPAPER" 2>/dev/null)
[ -z "$WP_W" ] && fallback

# All three crop rectangles in wallpaper-pixel coords, mapped through the
# `cover` transform so they line up with what the user actually sees.
COORDS=$(python3 - "$SCREEN_W" "$SCREEN_H" "$WP_W" "$WP_H" \
        "$DOT_COUNT" "$DOT_SIZE" "$GAP" "$DOT_Y" \
        "$BAR_Y" "$BAR_H" "$ISLAND_HALF" <<'PY'
import sys
sw, sh, ww, wh = map(int, sys.argv[1:5])
dot_count, dot_size, gap, dot_y = map(int, sys.argv[5:9])
bar_y, bar_h, island_half      = map(int, sys.argv[9:12])

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

# Bar strips — left and right of the central island reservation
left_w  = max(1, sw // 2 - island_half)
right_x = sw // 2 + island_half
right_w = max(1, sw - right_x)

lx, ly = to_wp(0, bar_y)
lw, lh = to_wp_size(left_w, bar_h)
rx, ry = to_wp(right_x, bar_y)
rw, rh = to_wp_size(right_w, bar_h)

print(f"{dw}x{dh}+{dx}+{dy}")
print(f"{lw}x{lh}+{lx}+{ly}")
print(f"{rw}x{rh}+{rx}+{ry}")
PY
)
[ -z "$COORDS" ] && fallback

DOT_RECT=$(echo "$COORDS"  | sed -n '1p')
LEFT_RECT=$(echo "$COORDS" | sed -n '2p')
RIGHT_RECT=$(echo "$COORDS" | sed -n '3p')

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

PER_DOT=$(sample_strip "$DOT_RECT" "$DOT_COUNT")
LEFT_BAR=$(sample_strip "$LEFT_RECT" "$BAR_PER_SIDE")
RIGHT_BAR=$(sample_strip "$RIGHT_RECT" "$BAR_PER_SIDE")

[ -z "$PER_DOT" ]   && PER_DOT="128 128 128 128 128 128 128 128"
[ -z "$LEFT_BAR" ]  && LEFT_BAR="128 128 128 128"
[ -z "$RIGHT_BAR" ] && RIGHT_BAR="128 128 128 128"

BAR_LINE="${LEFT_BAR}${RIGHT_BAR}"
ALL="${PER_DOT}${BAR_LINE}"
AVG=$(awk '{ s = 0; n = 0; for (i = 1; i <= NF; i++) { s += $i; n++ } print (n > 0 ? int(s / n) : 128) }' <<<"$ALL")

echo "${PER_DOT% }"
echo "${BAR_LINE% }"
echo "${AVG:-128}"
