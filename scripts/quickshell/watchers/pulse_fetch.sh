#!/usr/bin/env bash
# pulse_fetch.sh - Fetch data from the standalone REST API

# Try to fetch from the local API server
PULSE_DATA=$(curl -s http://127.0.0.1:7334/pulse)
echo "[Watcher] Fetched: $PULSE_DATA" >> /tmp/qs_pulse_debug.log

if [ $? -eq 0 ] && [ -n "$PULSE_DATA" ]; then
    echo "$PULSE_DATA"
else
    # Fallback if server is down
    jq -n -c --arg rate "72" --arg icon "󰏤" '{rate: $rate, icon: $icon}'
fi
