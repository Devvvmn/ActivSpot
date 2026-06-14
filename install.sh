#!/usr/bin/env bash
# ActivSpot TUI Installer Launcher
# Thin bootstrap that ensures the beautiful Rust TUI installer is built and launched.

set -euo pipefail

INSTALLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/installer" && pwd)"
BINARY="$INSTALLER_DIR/target/release/activspot-installer"

echo "ActivSpot TUI Installer"
echo "======================="
echo

if ! command -v cargo &>/dev/null; then
    echo "Rust (cargo) is required to build the TUI installer."
    echo "It will also be needed later for the hypr-dock component."
    echo
    read -rp "Install rustup via pacman now? [y/N] " ans
    if [[ "${ans,,}" == "y" ]]; then
        sudo pacman -S --needed --noconfirm rustup
        rustup default stable
    else
        echo "Please install Rust manually and re-run this script."
        exit 1
    fi
fi

if [[ ! -f "$BINARY" ]]; then
    echo "Building the TUI installer (first run, this may take a minute)..."
    echo
    (cd "$INSTALLER_DIR" && cargo build --release)
    echo
fi

echo "Launching ActivSpot Installer TUI..."
echo
exec "$BINARY" "$@"