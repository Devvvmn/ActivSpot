#!/usr/bin/env bash
# Launches hyprlax with options sourced from settings.json -> parallax.
# Used by hyprland.conf exec-once and by WallpaperPicker.qml after wallpaper changes.

set -u

SETTINGS="$HOME/.config/hypr/settings.json"
STATE_FILE="$HOME/.cache/wallpaper_picker/current"
DEFAULT_WALL="$HOME/Pictures/Wallpapers/UltrawideWallpapersDotNet-4844.jpeg"
BIN="$HOME/.local/bin/hyprlax"
[ -x "$BIN" ] || BIN="$(command -v hyprlax || echo hyprlax)"

read_jq() {
    [ -f "$SETTINGS" ] || { echo ""; return; }
    jq -r "$1 // empty" "$SETTINGS" 2>/dev/null
}

# Resolve wallpaper path (overridable via $1)
WALL="${1:-}"
[ -z "$WALL" ] && WALL=$(cat "$STATE_FILE" 2>/dev/null || true)
[ -z "$WALL" ] || [ ! -f "$WALL" ] && WALL="$DEFAULT_WALL"

# Read parallax settings (jq optional — gracefully degrade to flag defaults)
SHIFT=$(read_jq '.parallax.shift')
DURATION=$(read_jq '.parallax.duration')
EASING=$(read_jq '.parallax.easing')
FPS=$(read_jq '.parallax.fps')
INPUT=$(read_jq '.parallax.input')

ARGS=()
[ -n "$SHIFT" ]    && ARGS+=(--shift "$SHIFT")
[ -n "$DURATION" ] && ARGS+=(--duration "$DURATION")
[ -n "$EASING" ]   && ARGS+=(--easing "$EASING")
[ -n "$FPS" ]      && ARGS+=(--fps "$FPS")
[ -n "$INPUT" ]    && ARGS+=(--input "$INPUT")

# If no input override, keep the original cursor+workspace blend that worked.
if [ -z "$INPUT" ]; then
    ARGS+=(--input "cursor:0.0001,workspace")
fi

pkill -x hyprlax >/dev/null 2>&1 || true
for _ in {1..20}; do
    pgrep -x hyprlax >/dev/null || break
    sleep 0.05
done

mkdir -p "$(dirname "$STATE_FILE")"
echo "$WALL" > "$STATE_FILE"

setsid -f "$BIN" "${ARGS[@]}" "$WALL" </dev/null >/dev/null 2>&1

# Wait for the daemon to come up, then push real settings via ctl set
# (the `--shift` CLI flag does not propagate to parallax.shift_pixels on
# this build, so we have to apply it through IPC).
for _ in {1..30}; do
    pgrep -x hyprlax >/dev/null && break
    sleep 0.05
done
sleep 0.2
bash "$HOME/.config/hypr/scripts/hyprlax_apply.sh"
