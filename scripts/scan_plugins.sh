#!/usr/bin/env bash
# Scans ~/.config/hypr/plugins/ for Noctalia-compatible plugins and writes
# ~/.cache/quickshell/plugins.json for PluginLoader.qml to consume.

PLUGINS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/plugins"
OUTPUT_DIR="$HOME/.cache/quickshell"
OUTPUT="$OUTPUT_DIR/plugins.json"
RELOAD_SIGNAL="/tmp/qs_plugins_reload"

mkdir -p "$OUTPUT_DIR"

json_entries=()

for manifest_file in "$PLUGINS_DIR"/*/manifest.json; do
    [ -f "$manifest_file" ] || continue
    plugin_dir="$(dirname "$manifest_file")"

    # Validate it has at least an id field
    plugin_id="$(jq -r '.id // empty' "$manifest_file" 2>/dev/null)"
    [ -n "$plugin_id" ] || continue

    # Inject pluginDir into the manifest object
    entry="$(jq --arg dir "$plugin_dir" '. + {pluginDir: $dir}' "$manifest_file" 2>/dev/null)"
    [ -n "$entry" ] && json_entries+=("$entry")
done

# Write array (empty array if no plugins)
if [ ${#json_entries[@]} -eq 0 ]; then
    printf '[]' > "$OUTPUT"
else
    (
        printf '['
        for i in "${!json_entries[@]}"; do
            [ "$i" -gt 0 ] && printf ','
            printf '%s' "${json_entries[$i]}"
        done
        printf ']'
    ) > "$OUTPUT"
fi

# Signal QML watcher — write timestamp so FileView always sees a change
date +%s%N > "$RELOAD_SIGNAL"
