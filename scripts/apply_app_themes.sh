#!/usr/bin/env bash
# apply_app_themes.sh — propagate the active ActivSpot theme to GTK & Qt apps.
#
# Renders the island's palette (themes/Theme.qml is the source of truth —
# palettes here must stay in sync) into:
#   ~/.config/gtk-4.0/gtk.css        libadwaita @define-color overrides
#   ~/.config/gtk-3.0/gtk.css        same names (adw-gtk3 honors them) + legacy
#   ~/.config/qt6ct/colors/activspot.conf   qt6ct palette (+ qt5ct copy)
# and sets gsettings color-scheme / gtk-theme (adw-gtk3), with a theme flip
# so running GTK apps re-read the css. Flatpak apps get read-only access to
# the gtk config dirs (one-time override).
#
# Usage:
#   apply_app_themes.sh                # apply active topbarTheme (no-op if unchanged)
#   apply_app_themes.sh --force        # re-apply even if unchanged
#   apply_app_themes.sh --if-matugen   # only act when active theme is matugen
#                                      # (called from matugen_reload.sh on wallpaper change)
#
# Called automatically from DynamicIsland.qml on Theme.themeId change and
# from matugen_reload.sh after wallpaper-driven regeneration.

SETTINGS="$HOME/.config/hypr/settings.json"
QSCOLORS="$HOME/.config/hypr/scripts/quickshell/qs_colors.json"
STATE="$HOME/.cache/qs_app_theme"

FORCE=0; IF_MATUGEN=0
for a in "$@"; do
    case "$a" in
        --force)      FORCE=1 ;;
        --if-matugen) IF_MATUGEN=1 ;;
    esac
done

# ── Resolve palette (theme id + overrides + matugen merge) ───────────────────
eval "$(python3 - "$SETTINGS" "$QSCOLORS" <<'PY'
import json, sys, hashlib

MOCHA = dict(base="#1e1e2e", mantle="#181825", crust="#11111b",
    text="#cdd6f4", subtext0="#a6adc8", subtext1="#bac2de",
    surface0="#313244", surface1="#45475a", surface2="#585b70",
    overlay0="#6c7086", overlay1="#7f849c", overlay2="#9399b2",
    blue="#89b4fa", sapphire="#74c7ec", peach="#fab387",
    green="#a6e3a1", red="#f38ba8", mauve="#cba6f7",
    pink="#f5c2e7", yellow="#f9e2af", maroon="#eba0ac", teal="#94e2d5")
APPLE = dict(base="#f5f5f7", mantle="#ffffff", crust="#e5e5ea",
    text="#1d1d1f", subtext0="#6e6e73", subtext1="#3a3a3c",
    surface0="#ebebf0", surface1="#d1d1d6", surface2="#c7c7cc",
    overlay0="#aeaeb2", overlay1="#8e8e93", overlay2="#636366",
    blue="#007aff", sapphire="#5ac8fa", peach="#ff9500",
    green="#34c759", red="#ff3b30", mauve="#007aff",
    pink="#ff2d55", yellow="#ffcc00", maroon="#ff6961", teal="#5ac8fa")
NORD = dict(base="#2e3440", mantle="#272c36", crust="#1f242c",
    text="#eceff4", subtext0="#d8dee9", subtext1="#e5e9f0",
    surface0="#3b4252", surface1="#434c5e", surface2="#4c566a",
    overlay0="#616e88", overlay1="#7b88a1", overlay2="#8fbcbb",
    blue="#81a1c1", sapphire="#88c0d0", peach="#d08770",
    green="#a3be8c", red="#bf616a", mauve="#88c0d0",
    pink="#b48ead", yellow="#ebcb8b", maroon="#bf616a", teal="#8fbcbb")
CARBON = dict(base="#111111", mantle="#1a1a1a", crust="#0a0a0a",
    text="#f5f5f5", subtext0="#a1a1aa", subtext1="#d4d4d8",
    surface0="#242424", surface1="#2e2e2e", surface2="#3a3a3a",
    overlay0="#52525b", overlay1="#71717a", overlay2="#a1a1aa",
    blue="#60a5fa", sapphire="#93c5fd", peach="#fdba74",
    green="#86efac", red="#fca5a5", mauve="#d4d4d8",
    pink="#f0abfc", yellow="#fde68a", maroon="#fb923c", teal="#5eead4")
MIDNIGHT = dict(base="#08080f", mantle="#0f0f1a", crust="#04040a",
    text="#e2e2ff", subtext0="#9898c8", subtext1="#c4c4f0",
    surface0="#16162a", surface1="#1e1e38", surface2="#272748",
    overlay0="#4040a0", overlay1="#5858b8", overlay2="#7878d0",
    blue="#4fc3f7", sapphire="#93c5fd", peach="#fdba74",
    green="#4ade80", red="#f87171", mauve="#7c7cf5",
    pink="#e879f9", yellow="#fde68a", maroon="#fb923c", teal="#2dd4bf")

STATIC = {"mocha": MOCHA, "glass": MOCHA, "apple": APPLE, "nord": NORD,
          "carbon": CARBON, "midnight": MIDNIGHT}

try:
    st = json.load(open(sys.argv[1]))
except Exception:
    st = {}
theme = str(st.get("topbarTheme", "mocha")).lower()

pal = dict(STATIC.get(theme, MOCHA))
if theme == "matugen":
    try:
        mg = json.load(open(sys.argv[2]))
        for k in pal:
            v = mg.get(k)
            if isinstance(v, str) and v:
                pal[k] = v
    except Exception:
        pass

# config-ui per-color overrides (same merge Theme.qml does)
ov = (st.get("theme") or {}).get("overrides") or {}
for k, v in ov.items():
    if k in pal and isinstance(v, str) and v:
        pal[k] = v

light = theme == "apple"
digest = hashlib.md5((theme + json.dumps(pal, sort_keys=True)).encode()).hexdigest()[:12]

print(f'THEME_ID="{theme}"')
print(f'IS_LIGHT={"1" if light else "0"}')
print(f'HASH="{digest}"')
for k, v in pal.items():
    print(f'C_{k.upper()}="{v}"')
PY
)"

[ -z "$THEME_ID" ] && exit 1
if [ "$IF_MATUGEN" = 1 ] && [ "$THEME_ID" != "matugen" ]; then exit 0; fi
if [ "$FORCE" = 0 ] && [ -f "$STATE" ] && [ "$(cat "$STATE")" = "$HASH" ]; then exit 0; fi

# Accent foreground: dark accents want white text, pastel accents dark text.
if [ "$IS_LIGHT" = 1 ]; then ACCENT_FG="#ffffff"; else ACCENT_FG="$C_CRUST"; fi

# ── GTK (libadwaita named colors; adw-gtk3 honors the same names) ────────────
GTK_DEFINES="/* Generated by ActivSpot (apply_app_themes.sh) — theme: $THEME_ID */
@define-color accent_color $C_MAUVE;
@define-color accent_bg_color $C_MAUVE;
@define-color accent_fg_color $ACCENT_FG;
@define-color destructive_color $C_RED;
@define-color destructive_bg_color $C_RED;
@define-color destructive_fg_color $ACCENT_FG;
@define-color success_color $C_GREEN;
@define-color success_bg_color $C_GREEN;
@define-color success_fg_color $ACCENT_FG;
@define-color warning_color $C_PEACH;
@define-color warning_bg_color $C_PEACH;
@define-color warning_fg_color rgba(0, 0, 0, 0.8);
@define-color error_color $C_RED;
@define-color error_bg_color $C_RED;
@define-color error_fg_color $ACCENT_FG;
@define-color window_bg_color $C_BASE;
@define-color window_fg_color $C_TEXT;
@define-color view_bg_color $C_MANTLE;
@define-color view_fg_color $C_TEXT;
@define-color headerbar_bg_color $C_MANTLE;
@define-color headerbar_fg_color $C_TEXT;
@define-color headerbar_border_color $C_TEXT;
@define-color headerbar_backdrop_color @window_bg_color;
@define-color headerbar_shade_color rgba(0, 0, 0, 0.25);
@define-color headerbar_darker_shade_color rgba(0, 0, 0, 0.35);
@define-color sidebar_bg_color $C_MANTLE;
@define-color sidebar_fg_color $C_TEXT;
@define-color sidebar_backdrop_color @window_bg_color;
@define-color sidebar_shade_color rgba(0, 0, 0, 0.25);
@define-color sidebar_border_color rgba(0, 0, 0, 0.25);
@define-color secondary_sidebar_bg_color @sidebar_bg_color;
@define-color secondary_sidebar_fg_color @sidebar_fg_color;
@define-color secondary_sidebar_backdrop_color @sidebar_backdrop_color;
@define-color secondary_sidebar_shade_color @sidebar_shade_color;
@define-color secondary_sidebar_border_color @sidebar_border_color;
@define-color card_bg_color $C_SURFACE0;
@define-color card_fg_color $C_TEXT;
@define-color card_shade_color rgba(0, 0, 0, 0.25);
@define-color dialog_bg_color $C_MANTLE;
@define-color dialog_fg_color $C_TEXT;
@define-color popover_bg_color $C_SURFACE0;
@define-color popover_fg_color $C_TEXT;
@define-color popover_shade_color rgba(0, 0, 0, 0.25);
@define-color thumbnail_bg_color $C_SURFACE0;
@define-color thumbnail_fg_color $C_TEXT;
@define-color shade_color rgba(0, 0, 0, 0.25);
@define-color scrollbar_outline_color rgba(0, 0, 0, 0.5);"

# Legacy GTK3 names for non-adw-gtk3 themes/apps
GTK3_LEGACY="
@define-color theme_bg_color $C_BASE;
@define-color theme_fg_color $C_TEXT;
@define-color theme_base_color $C_MANTLE;
@define-color theme_text_color $C_TEXT;
@define-color theme_selected_bg_color $C_MAUVE;
@define-color theme_selected_fg_color $ACCENT_FG;
@define-color theme_unfocused_bg_color $C_BASE;
@define-color theme_unfocused_fg_color $C_SUBTEXT0;
@define-color borders $C_SURFACE0;
@define-color unfocused_borders $C_SURFACE0;"

_write_css() {
    local dir="$1" body="$2"
    mkdir -p "$dir"
    # Preserve a user's own gtk.css once — only ours (marker) gets rewritten
    if [ -f "$dir/gtk.css" ] && ! grep -q "Generated by ActivSpot" "$dir/gtk.css"; then
        mv "$dir/gtk.css" "$dir/gtk.css.pre-activspot.bak"
    fi
    printf '%s\n' "$body" > "$dir/gtk.css"
}
_write_css "$HOME/.config/gtk-4.0" "$GTK_DEFINES"
_write_css "$HOME/.config/gtk-3.0" "$GTK_DEFINES$GTK3_LEGACY"

# ── Qt (qt6ct + qt5ct palette) ───────────────────────────────────────────────
# QPalette rows: WindowText Button Light Midlight Dark Mid Text BrightText
# ButtonText Base Window Shadow Highlight HighlightedText Link LinkVisited
# AlternateBase ToolTipBase ToolTipText PlaceholderText Accent
QT_ACTIVE="$C_TEXT, $C_SURFACE0, $C_SURFACE2, $C_SURFACE1, $C_CRUST, $C_OVERLAY0, $C_TEXT, #ffffff, $C_TEXT, $C_MANTLE, $C_BASE, #000000, $C_MAUVE, $ACCENT_FG, $C_BLUE, $C_MAUVE, $C_SURFACE0, $C_SURFACE0, $C_TEXT, $C_SUBTEXT0, $C_MAUVE"
QT_DISABLED="$C_OVERLAY0, $C_SURFACE0, $C_SURFACE2, $C_SURFACE1, $C_CRUST, $C_OVERLAY0, $C_OVERLAY0, #ffffff, $C_OVERLAY0, $C_MANTLE, $C_BASE, #000000, $C_SURFACE1, $C_OVERLAY0, $C_BLUE, $C_MAUVE, $C_SURFACE0, $C_SURFACE0, $C_OVERLAY0, $C_OVERLAY0, $C_SURFACE1"

for qt in qt6ct qt5ct; do
    mkdir -p "$HOME/.config/$qt/colors"
    cat > "$HOME/.config/$qt/colors/activspot.conf" <<EOF
[ColorScheme]
active_colors=$QT_ACTIVE
disabled_colors=$QT_DISABLED
inactive_colors=$QT_ACTIVE
EOF
    # Point the qt*ct config at our scheme (create minimal config if absent)
    CONF="$HOME/.config/$qt/$qt.conf"
    python3 - "$CONF" "$HOME/.config/$qt/colors/activspot.conf" <<'PY'
import configparser, sys, os
conf, scheme = sys.argv[1], sys.argv[2]
cp = configparser.ConfigParser()
cp.optionxform = str
if os.path.exists(conf):
    cp.read(conf)
if not cp.has_section("Appearance"):
    cp.add_section("Appearance")
cp.set("Appearance", "custom_palette", "true")
cp.set("Appearance", "color_scheme_path", scheme)
if not cp.get("Appearance", "style", fallback=""):
    cp.set("Appearance", "style", "Fusion")
with open(conf, "w") as f:
    cp.write(f, space_around_delimiters=False)
PY
done

# ── gsettings + live reload flip ─────────────────────────────────────────────
if command -v gsettings >/dev/null 2>&1; then
    if [ "$IS_LIGHT" = 1 ]; then
        SCHEME="prefer-light"; GTK_THEME="adw-gtk3"
    else
        SCHEME="prefer-dark"; GTK_THEME="adw-gtk3-dark"
    fi
    [ -d "/usr/share/themes/$GTK_THEME" ] || GTK_THEME=""
    gsettings set org.gnome.desktop.interface color-scheme "$SCHEME" 2>/dev/null
    if [ -n "$GTK_THEME" ]; then
        # Flip forces running GTK3 apps to re-read gtk.css
        gsettings set org.gnome.desktop.interface gtk-theme "Adwaita" 2>/dev/null
        sleep 0.3
        gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null
    fi
fi

# ── Flatpak: let sandboxed apps read the generated css (idempotent) ─────────
if command -v flatpak >/dev/null 2>&1; then
    flatpak override --user \
        --filesystem=xdg-config/gtk-4.0:ro \
        --filesystem=xdg-config/gtk-3.0:ro 2>/dev/null
fi

echo "$HASH" > "$STATE"
