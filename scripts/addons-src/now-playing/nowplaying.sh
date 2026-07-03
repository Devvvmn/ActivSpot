#!/usr/bin/env bash
# Now-playing probe for the Lyrics desktop widget.
# Emits one JSON line: {status,title,artist,player,position,length}
# position = seconds (float), length = seconds (int).

raw=$(playerctl metadata --format \
    '{{status}}|{{xesam:title}}|{{xesam:artist}}|{{playerName}}|{{position}}|{{mpris:length}}' 2>/dev/null)

if [ -z "$raw" ]; then
    jq -n -c '{status:"Stopped", title:"", artist:"", player:"", position:0, length:0}'
    exit 0
fi

IFS='|' read -r STATUS TITLE ARTIST PLAYER POS LEN <<< "$raw"

# {{position}} and {{mpris:length}} are microseconds (may be empty).
posSec=$(awk "BEGIN{printf \"%.2f\", ${POS:-0}/1000000}")
lenSec=$(awk "BEGIN{printf \"%d\",   ${LEN:-0}/1000000}")

jq -n -c \
    --arg s "${STATUS:-Stopped}" \
    --arg t "${TITLE:-}" \
    --arg a "${ARTIST:-}" \
    --arg p "${PLAYER:-}" \
    --argjson pos "${posSec:-0}" \
    --argjson len "${lenSec:-0}" \
    '{status:$s, title:$t, artist:$a, player:$p, position:$pos, length:$len}'
