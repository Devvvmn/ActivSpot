# ActivSpot Design System

**ActivSpot** is a Dynamic Island for Hyprland — a Linux Wayland compositor. It recreates the macOS Dynamic Island experience as a floating pill-shaped UI widget that sits at the top-center of the screen, morphing contextually to show music, notifications, Discord calls, screen recording, clock/weather, and more. It also includes a full-width top bar with draggable applets.

Originally developed for personal use by **dxvmxn**, shared after community interest on Reddit.

---

## Sources

| Source | Path / URL |
|--------|-----------|
| Codebase | `hypr/` (mounted via File System Access API) |
| Entry point | `hypr/scripts/quickshell/Main.qml` |
| Island | `hypr/scripts/quickshell/DynamicIsland.qml` |
| Color tokens | `hypr/scripts/quickshell/qs_colors.json` |
| Settings | `hypr/settings.json` |

---

## Products / Surfaces

| Surface | Description |
|---------|-------------|
| **Dynamic Island** | Morphing pill at top-center. Shows: clock+weather, music player, discord call, screen recording, notifications, stash, app launcher |
| **Top Bar** | Full-width bar at top. Contains draggable applets: workspaces, keyboard, wifi, bluetooth, battery, system tray |
| **Popup Panels** | Large modal panels below the island: calendar, music player (expanded), battery, network, volume, wallpaper picker, focus timer |
| **App Launcher** | Spotlight-style search overlay, morphs from island position |
| **Lock Screen** | Full-screen lock (`Lock.qml`) |

---

## Stack

| Component | Technology |
|-----------|-----------|
| Shell | Quickshell |
| Language | QML |
| Compositor | Hyprland |
| IPC | inotifywait on /tmp/qs_* files |
| Music | playerctl |
| Weather | wttr.in |
| Clipboard | cliphist + wl-copy |
| Notifications | Custom daemon via Quickshell NotificationServer |
| Colors | Matugen (Material You, wallpaper-driven) with Catppuccin Mocha defaults |

---

## CONTENT FUNDAMENTALS

**Tone**: Minimal, technical, developer-friendly. No marketing fluff. Labels are functional, not decorative.

**Casing**: 
- Section headers: `ALL CAPS` with letter-spacing (e.g. `EQUALIZER`, `NOTIFICATIONS`, `STASH`)
- UI labels: Title Case or lowercase (e.g. `Clear`, `Flat`, `Bass`)
- Status text: Sentence case (e.g. `Not Charging`, `Clear Sky`)
- Time/date: System locale formatting

**Copy style**:
- Extremely terse. No sentences. Labels only.
- Preference for abbreviation: `DND`, `EQ`, `VPN`, `OSD`
- Technical jargon used freely (playerctl, pactl, wireguard, MPRIS)
- Russian appears in one empty-state label (`Нет уведомлений`) — the author's native language leaks in
- No emoji in UI (Nerd Font icon codepoints used instead)
- No decorative punctuation

**Formatting examples**:
- `11:17:53 PM` — time format
- `Tuesday, April 07` — date format
- `VIRA - I Don't Care` — music title
- `BY · VIOLENT VIRA ·` — artist with centered dots
- `00:27 / 03:01` — time remaining

---

## VISUAL FOUNDATIONS

### Color System
The color system is **dynamically generated** via [Matugen](https://github.com/InioX/matugen) (Material You algorithm applied to the current wallpaper). The defaults are **Catppuccin Mocha** — a warm dark purple palette. Colors are stored in `qs_colors.json` and hot-reloaded every second.

**Base palette (Catppuccin Mocha defaults):**

| Role | Hex | Usage |
|------|-----|-------|
| base | `#1e1e2e` | Deepest background (island pill bg) |
| mantle | `#181825` | Secondary background |
| crust | `#11111b` | Darkest layer |
| text | `#cdd6f4` | Primary text, light |
| subtext0 | `#a6adc8` | Secondary text, muted |
| subtext1 | `#bac2de` | Tertiary text |
| surface0 | `#313244` | Card/container background |
| surface1 | `#45475a` | Hover state background |
| surface2 | `#585b70` | Active/pressed background |
| overlay0 | `#6c7086` | Disabled / placeholder |
| mauve | `#cba6f7` | **Primary accent** — buttons, highlights, gradients |
| blue | `#89b4fa` | Secondary accent — gradient endpoint |
| peach | `#fab387` | Warm accent — temperature, warnings |
| green | `#a6e3a1` | Success states |
| red | `#f38ba8` | Error, destructive |
| teal | `#94e2d5` | Tertiary accent |
| pink | `#f5c2e7` | Soft accent |
| yellow | `#f9e2af` | Warm highlight |
| maroon | `#eba0ac` | Error-adjacent |

**Primary gradient**: `mauve → blue` (horizontal), used for progress bars, EQ fills, sliders.

**Cava bar gradient** (per-bar, vertical): `blue, mauve, pink, peach, pink, blue` cycling across 6 bars.

**Battery gradient**: Dynamic — green (charged) → peach (medium) → red (low), lighter variant on right endpoint.

### Typography
- **Primary**: `JetBrains Mono` (monospace) — used for ALL text in the UI
- **Icons**: `Iosevka Nerd Font` — Nerd Font variant used exclusively for iconography (no SVG icons)
- **No serif, no variable, no display fonts**

**Type scale** (scaled by screen width via `Scaler.qml`):
| Role | Size | Weight | Notes |
|------|------|--------|-------|
| Display time | 50px | Black (900) | Clock page |
| Heading | 20px | Black | Music title |
| Section label | 11px | Black | ALL CAPS, letter-spacing 1.5–2 |
| Body | 13px | Regular/Bold | General text |
| Artist / meta | 13px | Regular | Subtext color |
| Caption | 10–11px | Regular | Timestamps, labels |
| Tiny | 8px | Regular | EQ frequency labels |

### Spacing & Layout
- Base unit: scaled via `scaler.s(v)` — maps logical px to screen-width-relative px
- Island pill vertical offset from screen top: `s(8)px`
- Island expanded width: `min(s(760), screen - s(32))`
- Top bar height: `65px`
- Card/panel padding: `s(20)–s(28)` all sides, `s(68)–s(72)` bottom (navigation area)
- Element spacing: `s(4)`, `s(6)`, `s(8)`, `s(12)`, `s(16)`, `s(20)` — multiples of 4

### Corner Radii
- Island pill (collapsed): fully round — `height/2`
- Island pill (expanded): large radius, continuous with collapsed
- Cards/containers: `s(12)–s(16)`
- Small chips/badges: `s(10)–s(14)` (fully round for small items)
- Control buttons: `s(22)–s(30)` (circular)
- Album art: `s(14)`
- Avatar/icon containers: `s(9)`
- Border accent strip: `s(2)` (notification left accent)

### Shadows & Depth
- Island drop shadow: `rgba(0,0,0, 0.28–0.38)`, blurred via MultiEffect (`blurMax: 28`), slightly offset top (+10px)
- Shadow radius matches pill radius + padding
- Shadow stretches elastically with volume drag (scale transform on x-axis)
- Play button glow: `shadowColor: mauve`, `shadowOpacity: 0.4`, `shadowBlur: 0.8`
- No inner shadows

### Borders
- Card borders: `1px solid rgba(text, 0.05–0.08)` — barely visible in dark theme
- Active chip border: `1px solid rgba(mauve, 0.4–0.8)`
- Edit mode zone border: `1px solid rgba(mauve, 0.22)`
- No border by default on interactive elements (border appears on hover/active)

### Backgrounds
- Island pill: solid `base` color
- Popup panels: slightly transparent `surface0` (rgba ~0.55) — semi-glassmorphism
- Cards within panels: `rgba(surface0, 0.55)` with subtle border
- No full-bleed images in UI (wallpaper visible behind transparent panels)
- Wallpaper always shows through — the entire UI is designed to float above it

### Animation & Motion
| Property | Duration | Easing | Notes |
|----------|----------|--------|-------|
| Island width | 540ms | OutExpo | Main morph |
| Island height | 540ms | OutExpo | With optional 220ms delay for notifs |
| Island opacity | 200ms | OutCubic | Show/hide launcher |
| Island scale (hover) | 280ms | OutExpo | 1.025x on hover |
| Bubble reposition | 160ms | OutExpo | Fast tracking |
| Bubble snap (post-drag) | spring 4.5 / damping 0.6 | SpringAnimation | Bouncy slot snap |
| Page transition enter | 400ms | OutExpo + OutBack (scale) | 0.98→1.0 |
| Page transition exit | 300ms | InExpo | Fade + 1.0→1.02 scale |
| Widget morph (main) | 500ms | OutExpo | Panel open/close |
| Color transitions | 150–300ms | ColorAnimation | Hover state colors |
| Notification pulse | 900ms loop | InOutSine | Opacity 0.3→0.9 |
| Music pulse | 1000ms loop | InOutSine | Opacity 0.22→0.72 |
| Recording dot blink | 620ms loop | InOutSine | Opacity 0.15→1.0 |
| Edit mode wiggle | ~180ms loop | InOutSine | ±1.2° rotation (iOS style) |
| Startup slide | 800ms | OutBack (overshoot 1.1) | Bar zones slide in from sides |
| Bar zone fade-in | 600ms | OutCubic | On ready |

**No animation**: Content within the island (text, icons) does not animate in/out by default — the container morphs, content is static.

### Hover & Press States
- **Hover**: background changes to `surface1` or `rgba(surface1, 0.7)`, scale 1.05 (buttons)
- **Active/pressed**: color deepens, play button scale 1.06 with OutBack easing
- **Edit mode drag**: scale 1.08, border becomes brighter (`rgba(mauve, 0.7)`)
- All color transitions: 120–180ms ColorAnimation

### Imagery
- Wallpaper: Full-bleed desktop wallpaper (user's own, not part of design system)
- Album art: Embedded MPRIS art, cropped to square, displayed in rounded rect
- App icons: GTK icon theme (`image://theme/<name>`) — system icons
- No custom illustrations or decorative imagery

---

## ICONOGRAPHY

Icons are provided exclusively by **Iosevka Nerd Font** — Unicode codepoints rendered as text elements with `font.family: "Iosevka Nerd Font"`. No SVG icons, no PNG icons, no emoji.

**Examples of icon codepoints used:**
| Icon | Codepoint | Usage |
|------|-----------|-------|
| `󰒮` | U+F04AE | Previous track |
| `󰏤` | U+F03E4 | Pause |
| `󰐊` | U+F040A | Play |
| `󰒭` | U+F04AD | Next track |
| `󰋗` | U+F02D7 | Help |
| `󰕰` | U+F0170 | Workspaces |
| `󰌌` | U+F030C | Keyboard |
| `󰤨` | U+F0928 | WiFi |
| `󰂱` | U+F00B1 | Bluetooth |
| `󰁹` | U+F0079 | Battery |
| `󱒔` | U+F0494 | System tray |
| `󰂛` | U+F009B | DND on |
| `󰂚` | U+F009A | DND off |
| `󰅖` | U+F0156 | Dismiss/close |
| `󰵙` | U+F0559 | Fallback notification |
| `󰖔` | U+F05D4 | Weather (no data) |

**Icon sizing**: Nerd Font icons sized proportionally to surrounding text (13–40px range). Weather icon displayed large (36px) as a visual element.

**No icon system CDN** — all icons come from the installed Nerd Font. Substitute with [Nerd Fonts CDN](https://www.nerdfonts.com/) or use Lucide/Heroicons if building for web.

---

## File Index

```
README.md                        ← This file
SKILL.md                         ← Agent skill definition
colors_and_type.css              ← CSS custom properties for colors + typography
assets/                          ← Visual assets
  preview_music.png              ← Music player screenshot
  preview_calendar.png           ← Calendar/clock popup screenshot
  preview_battery.png            ← Battery popup screenshot
  preview_network.png            ← Network popup screenshot
  preview_volume.png             ← Volume popup screenshot
  preview_wallpaper.png          ← Wallpaper picker screenshot
  preview_focustime.png          ← Focus timer screenshot
  preview_monitors.png           ← Monitor settings screenshot
  preview_stewart.png            ← Pet pill (Stewart) screenshot
preview/                         ← Design system card previews (registered in DS tab)
ui_kits/
  activspot/                     ← UI kit for the ActivSpot shell UI
    index.html                   ← Interactive prototype
    DynamicIsland.jsx            ← Island component
    TopBar.jsx                   ← Top bar component
    Bubbles.jsx                  ← Mini-bubble components
    Panels.jsx                   ← Popup panel components
    README.md                    ← UI kit notes
```
