#!/usr/bin/env bash
# Launches the ActivSpot configuration web app.
# - First run: npm install + vite build
# - Starts the local server (port 7331) if not already running
# - Opens the URL in the user's default browser
set -euo pipefail

ROOT="${HOME}/.config/hypr/config-ui"
PORT="${CONFIG_UI_PORT:-7331}"
URL="http://127.0.0.1:${PORT}"
LOG="${XDG_RUNTIME_DIR:-/tmp}/activspot-config-ui.log"
PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/activspot-config-ui.pid"

cd "$ROOT"

# Install deps on first run
if [ ! -d "node_modules" ]; then
  notify-send "ActivSpot Config" "Installing dependencies (first run)…" 2>/dev/null || true
  npm install --no-audit --no-fund --silent
fi

# Build static bundle if missing or stale (older than newest src file)
needs_build=0
if [ ! -f "dist/index.html" ]; then
  needs_build=1
else
  newest_src=$(find src index.html vite.config.ts -type f -printf '%T@\n' 2>/dev/null | sort -n | tail -1)
  built_at=$(stat -c '%Y' dist/index.html 2>/dev/null || echo 0)
  if awk -v a="$newest_src" -v b="$built_at" 'BEGIN{exit !(a>b)}'; then
    needs_build=1
  fi
fi
if [ "$needs_build" -eq 1 ]; then
  notify-send "ActivSpot Config" "Building UI…" 2>/dev/null || true
  npm run build --silent
fi

# Start server if not already up
if ! curl -fsS "${URL}/api/health" >/dev/null 2>&1; then
  # Kill any stale pid
  if [ -f "$PIDFILE" ]; then
    kill "$(cat "$PIDFILE")" 2>/dev/null || true
    rm -f "$PIDFILE"
  fi
  CONFIG_UI_PORT="$PORT" nohup node server/server.mjs >"$LOG" 2>&1 &
  echo $! > "$PIDFILE"
  # Wait briefly for the server
  for _ in $(seq 1 30); do
    sleep 0.1
    if curl -fsS "${URL}/api/health" >/dev/null 2>&1; then break; fi
  done
fi

# Open in browser (xdg-open picks the user's default)
if command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$URL" >/dev/null 2>&1 &
elif command -v google-chrome >/dev/null 2>&1; then
  google-chrome --new-window "$URL" >/dev/null 2>&1 &
elif command -v chromium >/dev/null 2>&1; then
  chromium --new-window "$URL" >/dev/null 2>&1 &
fi
