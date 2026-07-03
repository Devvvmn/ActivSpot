#!/usr/bin/env bash
# live_activity_producers.sh — zero-integration Live Activity observers.
#
# Watches system signals that already exist (no app cooperation needed) and
# publishes them as island Live Activities via /tmp/qs_live_activity:
#   * pacman/paru transaction   — /var/lib/pacman/db.lck + pacman.log tail
#   * in-flight downloads       — ~/Downloads/*.part|*.crdownload|*.download
#   * microphone in use         — pactl source-outputs (monitor streams excluded)
#   * camera in use             — fuser on /dev/video*
#
# Spawned by DynamicIsland.qml. Heartbeats every POLL seconds while a signal
# is active; the island prunes entries whose ttl lapses, so killing this
# script never leaves zombie cards. flock guards against double-spawn.

LOCK=/tmp/qs_la_producers.lock
exec 9>"$LOCK"
flock -n 9 || exit 0

OUT=/tmp/qs_live_activity
POLL=2
TTL=7000   # ms; > 2*POLL so one missed beat survives

emit() { printf '%s\n' "$1" >> "$OUT"; }

# Minimal JSON string escaping (backslash, quote, control chars we may meet)
jesc() {
    local s="$1"
    s=${s//\\/\\\\}; s=${s//\"/\\\"}
    s=${s//$'\n'/ }; s=${s//$'\t'/ }
    printf '%s' "$s"
}

pacman_active=0
declare -A dl_prev

while :; do
    # ── pacman / paru transaction ─────────────────────────────────────────
    if [ -e /var/lib/pacman/db.lck ]; then
        pkg=$(grep -aE '\] (installed|upgraded|removed|downgraded) ' /var/log/pacman.log 2>/dev/null \
              | tail -1 | sed 's/.*\] //')
        emit "{\"id\":\"pacman\",\"icon\":\"󰮯\",\"title\":\"System update\",\"subtitle\":\"$(jesc "${pkg:-preparing…}")\",\"progress\":-1,\"ttlMs\":$TTL,\"kind\":\"pacman\",\"urgency\":\"low\"}"
        pacman_active=1
    elif [ "$pacman_active" = 1 ]; then
        emit '{"id":"pacman","event":"end","status":"ok","subtitle":"transaction finished"}'
        pacman_active=0
    fi

    # ── in-flight downloads in ~/Downloads ────────────────────────────────
    declare -A dl_now=()
    shopt -s nullglob
    for f in "$HOME"/Downloads/*.part "$HOME"/Downloads/*.crdownload "$HOME"/Downloads/*.download; do
        base=${f##*/}
        name=${base%.*}
        id="dl-$(printf '%s' "$base" | md5sum | cut -c1-10)"
        sz=$(stat -c%s "$f" 2>/dev/null || echo 0)
        hsz=$(numfmt --to=iec --suffix=B "$sz" 2>/dev/null || echo "${sz}B")
        dl_now[$id]=1
        emit "{\"id\":\"$id\",\"icon\":\"󰇚\",\"title\":\"$(jesc "$name")\",\"subtitle\":\"downloading · $hsz\",\"progress\":-1,\"ttlMs\":$TTL,\"kind\":\"download\",\"urgency\":\"low\"}"
    done
    shopt -u nullglob
    # Files that vanished since last tick → finished (renamed to final name)
    for id in "${!dl_prev[@]}"; do
        [ -n "${dl_now[$id]}" ] || emit "{\"id\":\"$id\",\"event\":\"end\",\"status\":\"ok\",\"subtitle\":\"download complete\"}"
    done
    dl_prev=()
    for id in "${!dl_now[@]}"; do dl_prev[$id]=1; done

    # ── microphone in use (privacy indicator) ─────────────────────────────
    # Real capture streams only: exclude streams reading .monitor sources
    # (cava & friends) and corked (paused) streams.
    mons=$(pactl list short sources 2>/dev/null | awk '$2 ~ /\.monitor$/ {print $1}')
    apps=$(pactl list source-outputs 2>/dev/null | awk -v mons="$mons" '
        BEGIN { n = split(mons, mm, "\n"); for (i = 1; i <= n; i++) if (mm[i] != "") M[mm[i]] = 1 }
        function flush() { if (app != "" && !(src in M) && corked == "no") print app; src=""; app=""; corked="" }
        /^Source Output #/ { flush() }
        /^\tSource:/       { src = $2 }
        /^\tCorked:/       { corked = tolower($2) }
        /application\.name/ { line = $0; sub(/[^=]*= "/, "", line); sub(/"$/, "", line); app = line }
        END { flush() }
    ' | sort -u | head -3 | paste -sd ', ' -)
    if [ -n "$apps" ]; then
        emit "{\"id\":\"mic\",\"icon\":\"\",\"title\":\"Mic in use\",\"subtitle\":\"$(jesc "$apps")\",\"ttlMs\":$TTL,\"kind\":\"mic\",\"urgency\":\"high\"}"
    fi

    # ── camera in use ─────────────────────────────────────────────────────
    campids=$(fuser /dev/video* 2>/dev/null | tr -s ' ' '\n' | sort -u | head -5)
    if [ -n "$campids" ]; then
        camapps=$(for p in $campids; do ps -o comm= -p "$p" 2>/dev/null; done | sort -u | head -3 | paste -sd ', ' -)
        emit "{\"id\":\"cam\",\"icon\":\"󰄀\",\"title\":\"Camera in use\",\"subtitle\":\"$(jesc "${camapps:-unknown}")\",\"ttlMs\":$TTL,\"kind\":\"cam\",\"urgency\":\"high\"}"
    fi

    sleep "$POLL"
done
