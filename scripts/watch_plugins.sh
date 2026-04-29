#!/usr/bin/env bash
# Watches ~/.config/hypr/plugins/ for additions/removals and triggers a rescan.
# Run once at login (exec-once in hyprland.conf).

PLUGINS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/plugins"
SCAN_SCRIPT="$(dirname "${BASH_SOURCE[0]}")/scan_plugins.sh"

mkdir -p "$PLUGINS_DIR"

# Initial scan on start
bash "$SCAN_SCRIPT"

# Watch for directory-level changes (new plugin dropped in / removed)
while true; do
    inotifywait -qq -e create,delete,moved_to,moved_from "$PLUGINS_DIR" 2>/dev/null
    # Small debounce — a plugin drop triggers multiple events
    sleep 0.5
    bash "$SCAN_SCRIPT"
done
