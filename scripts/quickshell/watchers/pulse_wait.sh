#!/usr/bin/env bash
# pulse_wait.sh - Event-driven waiting for pulse updates

TRIGGER_FILE="/tmp/qs_pulse_update"
touch "$TRIGGER_FILE" 2>/dev/null

# Wait for a change to the trigger file OR 30 seconds (failsafe)
echo "[Watcher] Waiting for pulse update..." >> /tmp/qs_pulse_debug.log
inotifywait -qq -t 30 -e close_write,moved_to "$TRIGGER_FILE" 2>/dev/null
echo "[Watcher] Wait exited with code $?" >> /tmp/qs_pulse_debug.log

# Small delay to ensure server finished writing (though not strictly needed for touch)
sleep 0.1
exit 0
