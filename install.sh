#!/usr/bin/env bash
# Hyprland dotfiles installer — Arch Linux only

set -euo pipefail

# ── colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${CYAN}  ➜${NC}  $*"; }
success() { echo -e "${GREEN}  ✓${NC}  $*"; }
warn()    { echo -e "${YELLOW}  ⚠${NC}  $*"; }
die()     { echo -e "${RED}  ✗${NC}  $*" >&2; exit 1; }
header()  { echo -e "\n${BOLD}${BLUE}══ $* ══${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── sanity checks ────────────────────────────────────────────────────────────
[[ -f /etc/arch-release ]] || die "This script is for Arch Linux only."
[[ $EUID -ne 0 ]]          || die "Do not run as root — sudo will be called when needed."

# ── AUR helper ───────────────────────────────────────────────────────────────
header "AUR helper"
if command -v paru &>/dev/null; then
    AUR=paru
    success "paru found"
elif command -v yay &>/dev/null; then
    AUR=yay
    success "yay found"
else
    info "Installing paru…"
    sudo pacman -S --needed --noconfirm git base-devel
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/paru.git "$tmpdir/paru"
    (cd "$tmpdir/paru" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
    AUR=paru
    success "paru installed"
fi

# ── official packages ─────────────────────────────────────────────────────────
header "Official packages (pacman)"
PACMAN_PKGS=(
    # Hyprland core
    hyprland hypridle
    xdg-desktop-portal-hyprland xdg-utils
    xorg-xwayland qt5-wayland qt6-wayland

    # Terminal & browser & files
    kitty chromium nautilus

    # Shell utilities
    inotify-tools ffmpeg socat brightnessctl nmap

    # Wallpaper & colour
    matugen

    # Media & audio
    playerctl cava pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber
    easyeffects swaync

    # Clipboard
    cliphist wl-clipboard

    # Screen recording
    wl-screenrec

    # Fonts
    noto-fonts noto-fonts-emoji
    ttf-jetbrains-mono
    ttf-roboto ttf-ubuntu-font-family

    # GTK theme
    adw-gtk-theme

    # Python (for focus_daemon)
    python
)

info "Syncing package database…"
sudo pacman -Sy --noconfirm

MISSING_PAC=()
for pkg in "${PACMAN_PKGS[@]}"; do
    pacman -Qq "$pkg" &>/dev/null || MISSING_PAC+=("$pkg")
done

if [[ ${#MISSING_PAC[@]} -gt 0 ]]; then
    info "Installing: ${MISSING_PAC[*]}"
    sudo pacman -S --needed --noconfirm "${MISSING_PAC[@]}"
else
    success "All official packages already installed"
fi

# ── AUR packages ─────────────────────────────────────────────────────────────
header "AUR packages ($AUR)"
AUR_PKGS=(
    quickshell-git
    awww
    ttf-martian-mono-nerd
    ttf-iosevka-nerd
    localsend-bin
)

MISSING_AUR=()
for pkg in "${AUR_PKGS[@]}"; do
    pacman -Qq "$pkg" &>/dev/null || MISSING_AUR+=("$pkg")
done

if [[ ${#MISSING_AUR[@]} -gt 0 ]]; then
    info "Installing from AUR: ${MISSING_AUR[*]}"
    $AUR -S --needed --noconfirm "${MISSING_AUR[@]}"
else
    success "All AUR packages already installed"
fi

# ── copy dotfiles ─────────────────────────────────────────────────────────────
header "Dotfiles"
TARGET="$HOME/.config/hypr"
if [[ "$SCRIPT_DIR" != "$TARGET" ]]; then
    info "Copying configs from $SCRIPT_DIR → $TARGET"
    mkdir -p "$TARGET"
    cp -r "$SCRIPT_DIR"/. "$TARGET/"
    success "Copied to $TARGET"
else
    success "Already in $TARGET, skipping copy"
fi

# ── script permissions ────────────────────────────────────────────────────────
header "Script permissions"
find "$TARGET/scripts" -name "*.sh" -exec chmod +x {} \; 2>/dev/null && \
    success "chmod +x on all scripts"

# ── cache directories ─────────────────────────────────────────────────────────
header "Cache directories"
mkdir -p "$HOME/.cache/quickshell" "$HOME/.cache/matugen"
mkdir -p "$HOME/Downloads/qs_stash"
success "Cache dirs ready"

# ── wallpaper directory ───────────────────────────────────────────────────────
header "Wallpaper directory"
WALL_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
if [[ ! -d "$WALL_DIR" ]]; then
    mkdir -p "$WALL_DIR"
    warn "Created $WALL_DIR — add some wallpapers there!"
else
    count=$(find "$WALL_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) 2>/dev/null | wc -l)
    success "$WALL_DIR exists ($count wallpapers found)"
fi

# ── systemd / pipewire ────────────────────────────────────────────────────────
header "Systemd user services"
for svc in pipewire pipewire-pulse wireplumber; do
    if ! systemctl --user is-enabled "$svc" &>/dev/null; then
        systemctl --user enable --now "$svc" && success "Enabled $svc"
    else
        success "$svc already enabled"
    fi
done

# ── hyprpm plugins ────────────────────────────────────────────────────────────
header "Hyprland plugins (hyprpm)"
HYPRPM_REPOS=(
    "https://github.com/yayuuu/hyprland-scroll-overview"
    "https://github.com/hyprnux/hyprglass"
)
for repo in "${HYPRPM_REPOS[@]}"; do
    name=$(basename "$repo")
    if hyprpm list 2>/dev/null | grep -q "$name"; then
        success "hyprpm: $name already added"
    else
        info "hyprpm: adding $repo"
        hyprpm add "$repo"
    fi
done
info "hyprpm: enabling plugins"
hyprpm enable scrolloverview
hyprpm enable hyprglass
success "Plugins enabled (will load on next Hyprland start via hyprpm reload)"

# ── done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}Installation complete!${NC}"
echo ""
echo -e "  ${CYAN}Next steps:${NC}"
echo -e "  1. Log out and select ${BOLD}Hyprland${NC} in your display manager"
echo -e "  2. Or run: ${BOLD}Hyprland${NC} from a TTY"
echo -e "  3. Add wallpapers to ${BOLD}${WALL_DIR}${NC}"
echo ""
