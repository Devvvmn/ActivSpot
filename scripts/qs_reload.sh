#!/usr/bin/env bash
# Trigger Quickshell to re-read its QML.
#
# Quickshell auto-reloads the root file each instance was launched with when
# that file changes on disk. Multiple instances may exist (Main.qml, TopBar.qml,
# DynamicIsland.qml, …) — we touch every running root so each picks up changes.
#
# Do NOT send SIGUSR2: Quickshell does not handle it, so the default action
# (terminate) kills the shell.
set -euo pipefail

QS_DIR="${HOME}/.config/hypr/scripts/quickshell"

mapfile -t ROOTS < <(ps -o args= -C quickshell 2>/dev/null \
  | awk '{ for (i=1;i<=NF;i++) if ($i ~ /\.qml$/) print $i }' \
  | sort -u)

if [ "${#ROOTS[@]}" -eq 0 ]; then
  for f in "$QS_DIR"/*.qml; do
    [ -f "$f" ] && touch -c -- "$f"
  done
  echo "reloaded 0 root(s) (no running quickshell — touched entrypoints)"
else
  for f in "${ROOTS[@]}"; do
    [ -f "$f" ] && touch -c -- "$f"
  done
  echo "reloaded ${#ROOTS[@]} root(s)"
fi
