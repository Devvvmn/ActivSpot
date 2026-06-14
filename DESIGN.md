---
name: ActivSpot Configurator
description: A brutalist settings UI for the ActivSpot Dynamic Island — monospace-forward, Catppuccin-accented, zero radii.
colors:
  accent-violet: "#cba6f7"
  midnight: "#000000"
  midnight-1: "#0a0a0c"
  midnight-2: "#141418"
  ink: "#ffffff"
  ink-muted: "#b8b8c0"
  ink-soft: "#707078"
  ink-faint: "#3a3a40"
  divider: "#2a2a2e"
  signal-green: "#a6e3a1"
  signal-yellow: "#f9e2af"
  signal-red: "#f38ba8"
  signal-blue: "#89b4fa"
  signal-peach: "#fab387"
typography:
  display:
    fontFamily: "'JetBrains Mono', 'Fira Code', ui-monospace, monospace"
    fontSize: "56px"
    fontWeight: 900
    lineHeight: 0.95
    letterSpacing: "-0.04em"
    fontFeature: '"ss01", "cv11"'
  headline:
    fontFamily: "'JetBrains Mono', 'Fira Code', ui-monospace, monospace"
    fontSize: "18px"
    fontWeight: 900
    lineHeight: 1.2
    letterSpacing: "0.04em"
  title:
    fontFamily: "'JetBrains Mono', 'Fira Code', ui-monospace, monospace"
    fontSize: "13px"
    fontWeight: 900
    lineHeight: 1
    letterSpacing: "0.22em"
  body:
    fontFamily: "'JetBrains Mono', 'Fira Code', ui-monospace, monospace"
    fontSize: "13px"
    fontWeight: 600
    lineHeight: 1.6
    letterSpacing: "normal"
    fontFeature: '"ss01", "cv11", "tnum"'
  label:
    fontFamily: "'JetBrains Mono', 'Fira Code', ui-monospace, monospace"
    fontSize: "10px"
    fontWeight: 900
    lineHeight: 1
    letterSpacing: "0.26em"
rounded:
  none: "0px"
spacing:
  xs: "6px"
  sm: "10px"
  md: "18px"
  lg: "28px"
  xl: "44px"
components:
  button-primary:
    backgroundColor: "{colors.accent-violet}"
    textColor: "{colors.midnight}"
    rounded: "{rounded.none}"
    padding: "8px 14px"
  button-default:
    backgroundColor: "{colors.midnight}"
    textColor: "{colors.ink}"
    rounded: "{rounded.none}"
    padding: "8px 14px"
  button-ghost:
    backgroundColor: "transparent"
    textColor: "{colors.ink-muted}"
    rounded: "{rounded.none}"
    padding: "8px 14px"
  button-danger:
    backgroundColor: "{colors.signal-red}"
    textColor: "{colors.midnight}"
    rounded: "{rounded.none}"
    padding: "8px 14px"
  chip-default:
    backgroundColor: "{colors.midnight}"
    textColor: "{colors.ink-muted}"
    rounded: "{rounded.none}"
    padding: "6px 12px"
  chip-active:
    backgroundColor: "{colors.accent-violet}"
    textColor: "{colors.midnight}"
    rounded: "{rounded.none}"
    padding: "6px 12px"
  input:
    backgroundColor: "{colors.midnight}"
    textColor: "{colors.ink}"
    rounded: "{rounded.none}"
    padding: "8px 12px"
---

# Design System: ActivSpot Configurator

## 1. Overview

**Creative North Star: "The Zine Config"**

ActivSpot Configurator is a settings tool with a self-published personality. The aesthetic is DIY-sharp: cut-and-paste grids, uppercase labels set tight, hard structural borders as the layout skeleton, and the Catppuccin palette used loud rather than tastefully. Nothing is soft. Nothing is neutral. This is a configuration interface that knows what it looks like, and it looks like it was made by someone who cares.

The system runs on a single monospace typeface (JetBrains Mono) at high weights throughout. Hierarchy is achieved through scale, weight contrast, and spatial rhythm — not through color variety or card separation. Backgrounds are near-pure black with minimal tonal elevation; surfaces are differentiated by thick white structural lines, not by subtle depth. The preview rail and content area are separated by a 3px white border. The sidebar is separated by a 3px white border. Borders are the architecture.

Catppuccin accents appear as loud, functional signals: the active nav item is filled with Signal Violet (#cba6f7), not merely accented. Status colors (green for live, yellow for dirty/unsaved, red for error) are used at full Catppuccin saturation. Color is not decoration here; it is information.

This is not SaaS. It is not GNOME Settings in dark mode. It is not a Linear-style ultra-minimal tool. It is a zine that also configures your Dynamic Island.

**Key Characteristics:**
- Pure black canvas, near-zero tonal layering between surfaces
- 3px solid white structural borders as the primary layout tool
- JetBrains Mono exclusively, from 10px caption to 56px display
- Hard offset box-shadows (blur 0) as the only elevation mechanism
- Catppuccin Mocha accents at full saturation for active and status states
- All UI chrome uppercase; body descriptions mixed-case
- steps()-based animations: discrete snaps, no easing curves, no duration > 200ms


## 2. Colors: The Zine Palette

A pure black field with Catppuccin Mocha accents used unfiltered — not "inspired by" Catppuccin, but the actual Mocha hex values at full intensity.

### Primary
- **Signal Violet** (#cba6f7): The active-state color. Every selected nav item, active chip, focused interactive element, and offset shadow on hover. Used exclusively for state, never as decoration.

### Secondary
- **Signal Green** (#a6e3a1): Positive states. The "live" status dot, "All saved" pill, healthy shell indicator. Means the system is running.
- **Signal Yellow** (#f9e2af): Warning and unsaved state. The full save-dock bar background turns this color when changes exist. Means action is required.
- **Signal Red** (#f38ba8): Error and danger. Toast error border, danger button fill, bad-state shadow. Means something failed.
- **Signal Blue** (#89b4fa): Informational secondary. Bindings section secondary data.
- **Signal Peach** (#fab387): Warm category labels. The `.kind` badge in the bindings table.

### Neutral
- **Midnight** (#000000): Primary background. The canvas everything sits on.
- **Midnight Lift** (#0a0a0c): Slightly elevated surface. Hovered list rows, the preview stage background. Nearly invisible on midnight.
- **Midnight Surface** (#141418): Second elevation step. Rarely needed.
- **Ink** (#ffffff): Primary text and all structural borders. The 3px lines scaffolding the layout are this color.
- **Ink Muted** (#b8b8c0): Secondary text. Nav labels at rest, descriptions, subdued values.
- **Ink Soft** (#707078): Tertiary text. Icons at rest, hint text, helper labels.
- **Ink Faint** (#3a3a40): Dividers and disabled states. The lightest value that still reads as a line.
- **Hair** (#2a2a2e): Subtle row separators within a section.

### Named Rules
**The Loud Accent Rule.** Signal Violet is never used at reduced opacity or as a tint. When it appears, it appears at full #cba6f7. `rgba(203,166,247,0.x)` backgrounds are prohibited except the single `kb-row.modified` case already in the codebase.

**The Status Purity Rule.** Signal Green, Yellow, Red, and Blue are reserved for semantic status exclusively. No decorative use of any status color.


## 3. Typography

**Primary Font:** JetBrains Mono (Fira Code, ui-monospace, monospace fallback)
**Icon Font:** Symbols Nerd Font / Iosevka Nerd Font (`.nf` utility class, weight 400)

**Character:** A single-font system with extreme weight contrast. 900 for display and UI chrome; 600 for body; 800 for labels. The monospace grid creates inherent alignment discipline. Tabular numerals (`tnum`) and OpenType features (`ss01`, `cv11`) are always active.

### Hierarchy
- **Display** (900 weight, 56px, line-height 0.95, letter-spacing -0.04em, uppercase): Page titles. The largest thing on screen. One per view. Tightened tracking at this size reads like a stamp, not a heading.
- **Headline** (900 weight, 18px, letter-spacing 0.04em, uppercase): Section and monitor headings.
- **Title** (900 weight, 13px, letter-spacing 0.22em, uppercase): Subsection headers, nav items, structural labels. The voice of the chrome.
- **Body** (600 weight, 13px, line-height 1.6, max 64ch): Descriptions and helper text. The only reading-weight in the system.
- **Label** (800–900 weight, 9.5–11px, letter-spacing 0.16–0.32em, uppercase): Meta captions, status badges, breadcrumb elements. These read as stamps, not prose.

### Named Rules
**The One-Font Rule.** JetBrains Mono is the only typeface. No variable-font tricks, no secondary humanist sans for body text. The monospace grid is the design.

**The Uppercase Chrome Rule.** All UI chrome (nav labels, breadcrumbs, section titles, status badges, button labels) is uppercase. Body descriptions are mixed-case. This separation is the only case logic in the system.


## 4. Elevation

Flat by default, hard offset on interaction. Surfaces do not layer with tonal depth; they are differentiated structurally by 3px white borders. The two midnight-1 and midnight-2 values exist for subtle surface lifts (hovered rows, preview backgrounds) but are nearly invisible on a pure black field.

Depth is a discrete statement. When an element gains elevation, it gets an offset shadow positioned 4–6px down-right, with the shadow color equal to the accent or status color, never `rgba(0,0,0,x)`.

### Shadow Vocabulary
- **Accent Lift** (`box-shadow: 6px 6px 0 0 #cba6f7`): Buttons at hover, inputs on focus, raw editor container, preview stage. The dominant elevation expression.
- **Ink Lift** (`box-shadow: 3px 3px 0 0 #ffffff`): Small icon buttons, brand mark, secondary interactive elements.
- **Status Lift — Error** (`box-shadow: 6px 6px 0 0 #f38ba8`): Error toast. Red lift means the message is urgent.
- **Status Lift — Success** (`box-shadow: 6px 6px 0 0 #a6e3a1`): Success toast. Green lift means the operation completed.
- **Dock Shadow** (`box-shadow: 0 -6px 0 0 #ffffff`): Save dock. Upward offset indicates the panel rising from the bottom edge.

### Named Rules
**The Zero Blur Rule.** Every shadow in this system has a blur radius of 0. No ambient glows, no soft shadows, no `backdrop-filter`. If it blurs, it does not belong.

**The Offset-Is-State Rule.** Shadows appear in response to interaction, never at rest. A surface at rest is flat. The shadow is not decoration — it is the hover state.


## 5. Components

### Buttons
Labeled switches, not invitations. Every button reads as a control on a panel.

- **Shape:** Zero radius (0px). Hard corners everywhere, no exceptions.
- **Typography:** 11.5px, weight 900, letter-spacing 0.14em, uppercase.
- **Transitions:** 60ms linear (transform, shadow); 80ms linear (background, color).
- **Primary:** Signal Violet fill, #000 text, 2px white border. Rest shadow: `4px 4px 0 0 #fff`. Hover: white fill, #000 text, `6px 6px 0 0 #cba6f7` shadow, `translate(-2px, -2px)`. Active: `translate(4px, 4px)`, shadow collapses to 0.
- **Default:** Midnight fill, white text, 2px white border. Hover: white fill, #000 text, `4px 4px 0 0 #cba6f7` shadow, `translate(-2px, -2px)`.
- **Ghost:** Transparent fill, ink-faint border, ink-muted text. Hover: white fill, #000 text, `3px 3px 0 0 #3a3a40` shadow.
- **Danger:** Signal Red fill, #000 text, white border. Hover: white fill, signal-red text, `4px 4px 0 0 #f38ba8` shadow.
- **Disabled:** `opacity: 0.4`. All shadow and transform suppressed.
- **Focus:** `outline: 3px solid #cba6f7`, `outline-offset: 2px`.

### Chips / Tags
Selection and filter controls. Active/inactive distinction is decisive, not gradual.

- **Shape:** Zero radius. 11px text, weight 800, uppercase, letter-spacing 0.1em.
- **Inactive:** Midnight fill, ink-faint border, ink-muted text.
- **Hover:** White fill, #000 text, white border, `translate(-1px, -1px)`, `2px 2px 0 0 #cba6f7` shadow.
- **Active:** Signal Violet fill, #000 text, white border, `2px 2px 0 0 #ffffff` shadow.

### Inputs / Text Fields
Hardware inputs: bracketed by white borders, offset on focus.

- **Shape:** Zero radius. 2px solid white border, midnight background, 8px 12px padding.
- **Focus:** `box-shadow: 4px 4px 0 0 #cba6f7`, `transform: translate(-2px, -2px)`. No ring, no glow.
- **Placeholder:** Ink Soft (#707078), weight 600.
- **Number inputs:** Right-aligned, tabular numerals, 92px width.
- **Textarea:** Resize vertical only; minimum 80px height; 1.6 line-height.

### Toggles
Square block switches with discrete jump animation.

- **Off state:** Midnight fill, 2px white border. White knob (18×22px), zero radius.
- **On state:** Signal Violet fill, black knob, `translateX(26px)`.
- **Animation:** 120ms `steps(3)` — the knob jumps, it does not slide.
- **Focus:** `outline: 3px solid #cba6f7`, `outline-offset: 2px`.

### Navigation (Sidebar)
The primary wayfinding rail. Active items fill completely; no partial accent treatment.

- **At rest:** Transparent background, ink-muted label, 4px transparent left border.
- **Hover:** `#0a0a0c` background, white label, ink-faint left border.
- **Active:** Signal Violet background throughout; #000 for all child text and icons.
- **Typography:** Main label 13px weight 900 uppercase; sublabel 9.5px weight 700 letter-spacing 0.16em.
- **Transition:** 80ms linear background, color, border-color.

### Variant Grid (Theme Picker)
The theme selector: a tiled grid where active cells fill with accent.

- **Container:** 3px solid white outer border. 2px white inner cell borders.
- **Cell at rest:** Midnight background, ink label, ink-soft description.
- **Active cell:** Signal Violet fill, #000 text throughout. A `▌ACTIVE` stamp (9px, weight 900, letter-spacing 0.18em) appears top-right in Signal Violet on a black backing.

### Save Dock
Fixed bottom bar that rises from below when unsaved changes exist.

- **Background:** Signal Yellow (#f9e2af), #000 text. 4px solid black top border. `box-shadow: 0 -6px 0 0 #ffffff`.
- **Appear animation:** `translateY(100%)` to `translateY(0)`, 200ms `steps(4)`. Snaps up, does not slide.
- **Dismiss:** Collapses with 120ms linear `opacity`.

### Toast Notifications
Bottom-right feedback, ephemeral (2400ms).

- **Structure:** Midnight fill, 3px white border. 11.5px weight 800 uppercase. Inline icon (13px).
- **Rest shadow:** `6px 6px 0 0 #cba6f7`. Success: green border + shadow. Error: red border + shadow.
- **Appear animation:** `translate(20px, 20px)` at opacity 0 to `translate(0,0)` at opacity 1, 200ms `steps(3)`.


## 6. Do's and Don'ts

### Do:
- **Do** use `border-radius: 0` on every interactive and structural element. A single rounded corner breaks the system.
- **Do** use `box-shadow: Xpx Xpx 0 0 {color}` with blur = 0 and spread = 0. The hard offset shadow is the only depth mechanism.
- **Do** use Signal Violet at full #cba6f7 — never dilute it with opacity or lightness adjustments.
- **Do** use `steps()` for toggles, appear animations, and discrete state snaps. The system has no easing curves.
- **Do** uppercase all UI chrome labels, button text, nav items, and status badges.
- **Do** use 3px solid white (`--line`) for primary structural divisions; 2px for secondary; 1px (`--hair`) for within-section row separators.
- **Do** use large weight contrast for hierarchy (900 vs 600). Weight 400 does not exist in this system.
- **Do** use `font-variant-numeric: tabular-nums` for all numeric values displayed in the UI.
- **Do** add `font-feature-settings: "ss01", "cv11", "tnum"` on body to activate JetBrains Mono's typographic features.

### Don't:
- **Don't** add `border-radius` to any element. Zero tolerance, zero exceptions.
- **Don't** use blur in shadows (`box-shadow: 0 4px 12px rgba(...)`) or `backdrop-filter`. See: the Zero Blur Rule.
- **Don't** use opacity-reduced accent as a tint (`rgba(203,166,247,0.1)` backgrounds). The only permitted exception is the existing `kb-row.modified` indicator.
- **Don't** build anything that looks like GNOME Settings, a default KDE panel, or any system preferences UI with soft edges and slate grays.
- **Don't** use linear or radial gradients as backgrounds. The palette is flat solids.
- **Don't** introduce a second typeface. JetBrains Mono is the only type decision. No humanist sans for body text.
- **Don't** smooth-animate toggle or discrete state changes. `cubic-bezier` easing is wrong for this system's snapping transitions.
- **Don't** use status colors (green, yellow, red, blue) for decoration. They are reserved for actual system state.
- **Don't** use nested containers or card grids. This system has no cards. Structural separation is done with 3px borders, not containment boxes.
- **Don't** add ambient shadow (`box-shadow: 0 2px 8px rgba(0,0,0,0.4)`) to any element at rest. Resting surfaces are flat.
