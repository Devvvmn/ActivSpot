#!/usr/bin/env bash

SETTINGS_FILE="$HOME/.config/hypr/settings.json"
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
ZSH_RC="$HOME/.zshrc"

# Ensure the settings file exists before we try to watch it
mkdir -p "$(dirname "$SETTINGS_FILE")"
[ ! -f "$SETTINGS_FILE" ] && echo "{}" > "$SETTINGS_FILE"

echo "Started watching $SETTINGS_FILE for changes..."

# Single-instance guard — don't stack watchers if exec-once fires twice
PIDFILE="$HOME/.cache/quickshell/settings_watcher.pid"
mkdir -p "$(dirname "$PIDFILE")"
if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE" 2>/dev/null)" 2>/dev/null; then
    echo "Another settings_watcher already running ($(cat "$PIDFILE")) — exiting."
    exit 0
fi
echo $$ > "$PIDFILE"
trap 'rm -f "$PIDFILE"' EXIT

# Loop endlessly, triggering only when the file is saved (closed after writing).
# `inotifywait` exits non-zero if the file is replaced via rename (e.g. atomic
# editor writes) — keep the loop alive across those.
while :; do
    inotifywait -q -e close_write,move_self "$SETTINGS_FILE" >/dev/null 2>&1 || { sleep 0.5; continue; }
    echo "Settings updated! Applying changes..."

    # Extract values using jq 
    # Removed '// empty' from the boolean to prevent 'false' from evaluating to empty
    LANG=$(jq -r '.language // empty' "$SETTINGS_FILE")
    KB_OPT=$(jq -r '.kbOptions // empty' "$SETTINGS_FILE")
    GUIDE_STARTUP=$(jq -r '.openGuideAtStartup' "$SETTINGS_FILE")
    WP_DIR=$(jq -r '.wallpaperDir // empty' "$SETTINGS_FILE")

    # 1. Update Keyboard Layout & Options
    if [ -n "$LANG" ] && [ "$LANG" != "null" ]; then
        sed -i "s/^ *kb_layout =.*/    kb_layout = $LANG/" "$HYPR_CONF"
    fi
    
    if [ -n "$KB_OPT" ] && [ "$KB_OPT" != "null" ]; then
        sed -i "s/^ *kb_options =.*/    kb_options = $KB_OPT/" "$HYPR_CONF"
    else
        # If it's explicitly empty/null (No Toggle), clear the value entirely
        sed -i "s/^ *kb_options =.*/    kb_options = /" "$HYPR_CONF"
    fi

    # 2. Update Guide Autostart (Comment / Uncomment)
    if [ "$GUIDE_STARTUP" == "true" ]; then
        # Remove any leading hash/spaces to enable the autostart
        sed -i 's|^#*[[:space:]]*exec-once = .*qs_manager.sh toggle hello.*|exec-once = sleep 4 \&\& ~/.config/hypr/scripts/qs_manager.sh toggle hello \&|' "$HYPR_CONF"
    elif [ "$GUIDE_STARTUP" == "false" ]; then
        # Add a hash to comment it out if it isn't already
        sed -i 's|^exec-once = .*qs_manager.sh toggle hello.*|# exec-once = sleep 4 \&\& ~/.config/hypr/scripts/qs_manager.sh toggle hello \&|' "$HYPR_CONF"
    fi

    # Parallax: push live to running hyprlax via ctl set (no restart)
    bash "$HOME/.config/hypr/scripts/hyprlax_apply.sh" &

    # 3. Update Wallpaper Directory
    if [ -n "$WP_DIR" ] && [ "$WP_DIR" != "null" ]; then
        # We use '|' as the sed delimiter here to prevent path slashes from breaking the command
        sed -i "s|^env = WALLPAPER_DIR,.*|env = WALLPAPER_DIR,$WP_DIR|" "$HYPR_CONF"
        
        # WALLPAPER_DIR is already exported via hyprland.conf env = line above;
        # do not mutate ~/.zshrc without explicit user consent.
    fi
done
