#!/bin/bash
# Samples luminance at dot positions directly from the wallpaper file.
# Scales coordinates from screen-space to wallpaper-space (cover mode).

SCREEN_W=${1:-1920}
SCREEN_H=${2:-1080}
DOT_COUNT=8
DOT_SIZE=9
GAP=6

WALLPAPER=$(cat "$HOME/.cache/wallpaper_picker/current" 2>/dev/null | tr -d '[:space:]')
if [ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ]; then
    echo "128 128 128 128 128 128 128 128"; echo "128"; exit 0
fi

# Wallpaper dimensions
WP_W=$(identify -format "%w" "$WALLPAPER" 2>/dev/null)
WP_H=$(identify -format "%h" "$WALLPAPER" 2>/dev/null)
[ -z "$WP_W" ] && { echo "128 128 128 128 128 128 128 128"; echo "128"; exit 0; }

# Scale factor for "cover" mode (fill screen, crop overflow)
# Use python3 for float math — bc can miss precision
COORDS=$(python3 -c "
sw, sh = $SCREEN_W, $SCREEN_H
ww, wh = $WP_W, $WP_H
scale = max(sw/ww, sh/wh)
# wallpaper effective size at this scale
eff_w = ww * scale
eff_h = wh * scale
# offset to center the crop
ox = (eff_w - sw) / 2
oy = (eff_h - sh) / 2

dot_count = $DOT_COUNT
dot_size  = $DOT_SIZE
gap       = $GAP
total_w   = dot_count * dot_size + (dot_count - 1) * gap
start_x   = sw / 2 - total_w / 2
dot_y     = 46

# Map screen coords → wallpaper coords
crop_x = int((start_x + ox) / scale)
crop_y = int((dot_y   + oy) / scale)
crop_w = max(1, int(total_w / scale))
crop_h = max(1, int(dot_size / scale))
print(crop_x, crop_y, crop_w, crop_h)
")

CX=$(echo $COORDS | awk '{print $1}')
CY=$(echo $COORDS | awk '{print $2}')
CW=$(echo $COORDS | awk '{print $3}')
CH=$(echo $COORDS | awk '{print $4}')

PER_DOT=$(convert "$WALLPAPER" \
    -crop "${CW}x${CH}+${CX}+${CY}" +repage \
    -resize "${DOT_COUNT}x1!" \
    -depth 8 txt:- 2>/dev/null \
  | awk 'NR>1 {
      match($0, /\(([0-9]+),([0-9]+),([0-9]+)/, c)
      printf "%d ", int((c[1]*299 + c[2]*587 + c[3]*114) / 1000)
    }')

[ -z "$PER_DOT" ] && PER_DOT="128 128 128 128 128 128 128 128"
AVG=$(echo "$PER_DOT" | awk '{s=0; for(i=1;i<=NF;i++) s+=$i; print int(s/NF)}')

echo "$PER_DOT"
echo "${AVG:-128}"
