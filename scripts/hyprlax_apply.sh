#!/usr/bin/env bash
# Push parallax settings from settings.json into a running hyprlax daemon
# via `hyprlax ctl set`. No restart, no flash.

SETTINGS="$HOME/.config/hypr/settings.json"
BIN="$HOME/.local/bin/hyprlax"
[ -x "$BIN" ] || BIN="$(command -v hyprlax || echo hyprlax)"

pgrep -x hyprlax >/dev/null || exit 0
[ -f "$SETTINGS" ] || exit 0

read_jq() { jq -r "$1 // empty" "$SETTINGS" 2>/dev/null; }

apply_if_set() {
    local key="$1" jq_path="$2" val
    val=$(read_jq "$jq_path")
    [ -n "$val" ] && [ "$val" != "null" ] && "$BIN" ctl set "$key" "$val" >/dev/null 2>&1
}

# `shift` alias in this hyprlax build doesn't propagate to parallax.shift_pixels,
# which is what actually drives the on-screen amplitude. Convert the fraction
# from settings.json to pixels using the primary monitor width.
SHIFT_FRAC=$(read_jq '.parallax.shift')
if [ -n "$SHIFT_FRAC" ] && [ "$SHIFT_FRAC" != "null" ]; then
    MON_W=$(hyprctl monitors -j 2>/dev/null | jq -r '[.[].width] | max // 1920')
    [ -z "$MON_W" ] || [ "$MON_W" = "null" ] && MON_W=1920
    PX=$(awk -v f="$SHIFT_FRAC" -v w="$MON_W" 'BEGIN { printf "%.0f", f * w }')
    "$BIN" ctl set parallax.shift_pixels "$PX" >/dev/null 2>&1
fi

apply_if_set duration        '.parallax.duration'
apply_if_set easing          '.parallax.easing'
apply_if_set fps             '.parallax.fps'
apply_if_set parallax.input  '.parallax.input'
