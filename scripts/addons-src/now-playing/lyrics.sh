#!/usr/bin/env bash
# Fetch synced (LRC) lyrics from lrclib.net for the Lyrics desktop widget.
# Usage: lyrics.sh "<artist>" "<title>" "<duration_sec>"
# Prints the raw LRC text on stdout (empty if none found). Results are cached
# per artist|title under ~/.cache/quickshell/lyrics/ (incl. negative results).

artist="$1"; title="$2"; dur="${3:-0}"
[ -z "$title" ] && exit 0

cache="$HOME/.cache/quickshell/lyrics"
mkdir -p "$cache"
key=$(printf '%s|%s' "${artist,,}" "${title,,}" | md5sum | cut -d' ' -f1)
hit="$cache/$key.lrc"
miss="$cache/$key.none"

# Cached?
[ -f "$hit" ]  && { cat "$hit"; exit 0; }
[ -f "$miss" ] && exit 0

extract() { jq -r "$1 // empty" 2>/dev/null; }

# 1) exact get (duration helps matching)
synced=$(curl -s -G --max-time 8 "https://lrclib.net/api/get" \
    --data-urlencode "artist_name=$artist" \
    --data-urlencode "track_name=$title" \
    --data-urlencode "duration=$dur" 2>/dev/null | extract '.syncedLyrics')

# 2) fallback: search, first result that has synced lyrics
if [ -z "$synced" ]; then
    synced=$(curl -s -G --max-time 8 "https://lrclib.net/api/search" \
        --data-urlencode "track_name=$title" \
        --data-urlencode "artist_name=$artist" 2>/dev/null \
        | jq -r 'map(select(.syncedLyrics != null and .syncedLyrics != ""))[0].syncedLyrics // empty' 2>/dev/null)
fi

if [ -n "$synced" ]; then
    printf '%s' "$synced" > "$hit"
    printf '%s' "$synced"
else
    : > "$miss"   # remember the miss so we don't refetch every track change
fi
