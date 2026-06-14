---
name: ActivSpot
description: A Dynamic Island shell for Hyprland. HUD-first, shell-second — ambient intelligence at rest, precision instrument on demand.
colors:
  muted-iris: "#cba6f7"
  sky-blue: "#89b4fa"
  soft-peach: "#fab387"
  sage-green: "#a6e3a1"
  blush-red: "#f38ba8"
  cool-teal: "#94e2d5"
  rose-pink: "#f5c2e7"
  warm-yellow: "#f9e2af"
  near-black-indigo: "#1e1e2e"
  collapsed-void: "#181825"
  ink-base: "#11111b"
  lifted-plum: "#313244"
  raised-surface: "#45475a"
  high-surface: "#585b70"
  pale-sky: "#cdd6f4"
  faded-cloud: "#a6adc8"
  soft-mist: "#bac2de"
  muted-fog: "#6c7086"
typography:
  display:
    fontFamily: "SF Pro Display, system-ui, sans-serif"
    fontSize: "54px"
    fontWeight: 100
    lineHeight: 1.0
    letterSpacing: "-0.5px"
  headline:
    fontFamily: "SF Pro Text, system-ui, sans-serif"
    fontSize: "26px"
    fontWeight: 700
    lineHeight: 1.2
  title:
    fontFamily: "JetBrains Mono, monospace"
    fontSize: "15px"
    fontWeight: 900
    lineHeight: 1.1
    letterSpacing: "-0.3px"
  body:
    fontFamily: "SF Pro Text, system-ui, sans-serif"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: 1.4
  label:
    fontFamily: "JetBrains Mono, monospace"
    fontSize: "10px"
    fontWeight: 500
    lineHeight: 1.2
    letterSpacing: "1.5px"
rounded:
  xs: "6px"
  sm: "10px"
  md: "14px"
  lg: "20px"
  xl: "28px"
spacing:
  sp1: "4px"
  sp2: "8px"
  sp3: "12px"
  sp4: "16px"
  sp5: "24px"
  sp6: "32px"
components:
  island-pill:
    backgroundColor: "{colors.collapsed-void}"
    rounded: "{rounded.xl}"
  island-pill-glass:
    backgroundColor: "rgba(255,255,255,0.09)"
    rounded: "{rounded.xl}"
  minibubble:
    backgroundColor: "{colors.lifted-plum}"
    rounded: "{rounded.xl}"
    padding: "6px 10px"
  page-action-button:
    backgroundColor: "{colors.lifted-plum}"
    textColor: "{colors.pale-sky}"
    rounded: "{rounded.sm}"
    padding: "8px 12px"
  page-action-button-active:
    backgroundColor: "{colors.lifted-plum}"
    textColor: "{colors.muted-iris}"
    rounded: "{rounded.sm}"
    padding: "8px 12px"
  applet-chip:
    backgroundColor: "transparent"
    textColor: "{colors.faded-cloud}"
    rounded: "{rounded.sm}"
    padding: "4px 8px"
  applet-chip-active:
    backgroundColor: "{colors.lifted-plum}"
    textColor: "{colors.muted-iris}"
    rounded: "{rounded.sm}"
    padding: "4px 8px"
---

# Design System: ActivSpot

## 1. Overview

**Creative North Star: "The Ambient Intelligence"**

ActivSpot is a system that breathes at rest and sharpens on interaction — like a lens that only focuses when you need it to. At its default state, the collapsed island pill is a hairline presence at the top of the screen: a faint capsule shape against whatever wallpaper is beneath it, offering just enough information to be useful without demanding attention. On expansion, it becomes a precise, full-featured surface: music controls, notifications, timer, system state — everything immediately legible. The two states feel like the same object, not two different screens. That continuity is the point.

The palette lives in a deep indigo-violet darkness. Not a neutral dark — a tinted one. The Near-Black Indigo base (#1e1e2e) has a deliberate blue-violet cast that separates it from the flat grays of generic dark themes and keeps every surface in the same color family as the Muted Iris accent. When the accent appears, it reads as an intensification of the background rather than a foreign intrusion. The glass theme extends this further: compositor-blurred surfaces let the wallpaper bleed through, tinted with the same mauve hue, so the island feels embedded in the desktop rather than placed on top of it.

This system explicitly rejects the utilitarian flatness of generic Waybar setups, the visual clutter of widget-heavy shells, the derivative feel of macOS recreation, and the neon overload of r/unixporn maximalism. Every decision here is a vote for precision over prettiness — the kind of design where removing one element would make the whole thing feel unfinished.

**Key Characteristics:**
- Dark indigo-violet base with accent used sparingly as a signal, not a decoration
- Three-font stack: SF Pro Text for prose, JetBrains Mono for data/time/labels, Iosevka Nerd Font for icons
- Two surface modes: solid (mantle at full opacity) and glass (compositor blur, 9% white tint)
- Apple-grade depth model: large-blur, low-opacity shadows that lift without casting
- Motion serves state changes; no choreography for its own sake
- All tokens scale with display resolution via a linear `s()` function at 1920px base

## 2. Colors: The Indigo-Violet System

The palette is structured around a single hue family — blue-indigo-violet — expressed across 8 tonal background layers, two distinct text weights, and a set of semantic accent colors. The accent colors are drawn from Catppuccin Mocha and carry semantic meaning (Muted Iris for primary signal, Soft Peach for warning, Sage Green for success, Blush Red for danger). The 6 named themes (Mocha, Nord, Apple, Carbon, Midnight, Matugen) swap this palette at the token level; layout and hierarchy are invariant.

### Primary
- **Muted Iris** (#cba6f7 / oklch(72% 0.17 293)): The primary signal color. Used on active states, focused elements, accent text, the island's primary highlight, and notification source labels. Its rarity against the dark base is what makes it register as signal. Never used as a background fill.

### Secondary
- **Sky Blue** (#89b4fa / oklch(74% 0.13 258)): Secondary information accent. Used for weather icons, secondary emphasis in pages, and the `accentAlt` alias. Cooler than Muted Iris, reads as factual rather than interactive.
- **Soft Peach** (#fab387 / oklch(78% 0.13 46)): Warning and warm-data color. Used for temperature display, OSD values, and the `warning` semantic alias. Warm enough to attract attention without reading as error.
- **Sage Green** (#a6e3a1 / oklch(87% 0.12 141)): Positive and active state. Used for success feedback, active recording indicator, authenticated lock state. The `positive` alias.
- **Blush Red** (#f38ba8 / oklch(72% 0.17 7)): Danger and error. Used for the `danger` alias, failed authentication, destructive actions. Close in lightness to Muted Iris so errors are noticed without being alarming.

### Tertiary
- **Cool Teal** (#94e2d5 / oklch(87% 0.10 183)): File stash and secondary cool accent.
- **Rose Pink** (#f5c2e7 / oklch(83% 0.09 345)): Tertiary warm accent. Used sparingly for the volume/drag applet.
- **Warm Yellow** (#f9e2af / oklch(91% 0.09 87)): Caution and timer-expiry state.

### Neutral
- **Near-Black Indigo** (#1e1e2e): Primary background. The base all surfaces sit on. Slight violet cast is intentional — it keeps the surface in the accent's hue family.
- **Collapsed Void** (#181825): Island pill surface (solid mode). Slightly darker than base so the pill reads as its own layer, not as a cutout.
- **Ink Base** (#11111b): Deepest layer. Lock screen ground, shadow reference color.
- **Lifted Plum** (#313244): First elevated surface. Cards, action buttons, expanded page containers.
- **Raised Surface** (#45475a): Second elevation tier. Hover states, focused inputs, secondary containers.
- **High Surface** (#585b70): Third tier. Rarely used directly; mostly appears as the disabled-state background.
- **Pale Sky** (#cdd6f4): Primary text. Has a warm blue cast that harmonizes with the indigo base.
- **Faded Cloud** (#a6adc8): Secondary text. Metadata, timestamps, supporting labels.
- **Muted Fog** (#6c7086): Disabled and placeholder text. Overlay states and dividers.

### Named Rules
**The Rarity Rule.** Muted Iris appears on ≤15% of any surface at rest. When it appears, it means something. Never use it as a container fill or generic highlight.

**The Hue-Family Rule.** Every background layer (base, mantle, surface0-2) shares the same blue-violet hue family. Introducing a neutral gray (e.g. #2a2a2a with no hue) breaks the system. New surfaces must be tinted toward the violet family, not neutralized.

## 3. Typography

**Display Font:** SF Pro Display (with system-ui, sans-serif fallback)
**Body Font:** SF Pro Text (with system-ui, sans-serif fallback)
**Data/Label Font:** JetBrains Mono (monospace fallback)
**Icon Font:** Iosevka Nerd Font (icon-only; not a prose fallback)

**Character:** SF Pro Display in Thin weight carries the hero moments — onboarding slides and large clock displays — with the precision of an instrument readout. SF Pro Text handles all readable prose. JetBrains Mono owns numbers and data: time, temperature, timestamps. The stack is legible at 10px and structured at 54px; the three fonts never appear in the same role.

### Hierarchy
- **Display** (Thin/100, 54px, lh 1.0, ls -0.5px): Hero slides only. Onboarding intro/outro (`hello.` and `it's all yours.`). Nothing else at this scale.
- **Headline** (Bold/700, 26px, lh 1.2): Section headers inside expanded pages. Feature names in the onboarding carousel.
- **Title** (Black/900, 15px JetBrains Mono, lh 1.1, ls -0.3px): Time display. Primary data values (temperature, BPM). The weight and the mono font together make numbers feel like instruments.
- **Body** (Regular/400, 13-14px SF Pro Text, lh 1.4): Notification body text. Music track titles. Page content. The workhorse.
- **Label** (Medium/500, 10-11px JetBrains Mono, lh 1.2, ls 1.5px): Dates, timestamps, source names, app labels. Uppercase tracking is used on notification category labels only.

### Named Rules
**The Mono-for-Data Rule.** Every number that represents a measured value (time, temperature, percentage, elapsed seconds) uses JetBrains Mono at Black weight. SF Pro Text is for language; Mono is for measurement. Never render a clock or OSD value in SF Pro.

## 4. Elevation

ActivSpot uses a hybrid depth model: tonal layering via the 8-step neutral stack (near-black-indigo through high-surface) carries structural depth at rest. Apple-grade shadow tokens (large gaussian blur, low opacity, small vertical offset) carry interactive depth for elements that need to lift above their context.

Three shadow tiers, applied via QML `MultiEffect`:

### Shadow Vocabulary
- **elev1 — Signal Lift** (opacity 18%, blur radius 24px, vertical offset 2px): Applied to minibubbles and interactive chips. Lifts elements just enough to separate them from the base surface without announcing themselves.
- **elev2 — Surface Float** (opacity 22%, blur radius 40px, vertical offset 6px): Applied to expanded popups, sheets, and the island in expanded state. The blur radius is large relative to the offset — this is an ambient shadow, not a drop shadow.
- **elev3 — Hero Depth** (opacity 28%, blur radius 64px, vertical offset 12px): Used for album art, the lock screen surface, and modal-level content. At this tier, the shadow is an atmospheric condition, not a border.

The shadow color is always pure black (#000000). On light themes (Apple palette), all three opacity values are reduced: elev1 8%, elev2 10%, elev3 12%.

### Named Rules
**The Ambient Rule.** Shadow is atmosphere, not outline. If a shadow appears to define an edge, the blur radius is too small or the opacity is too high. Increase blur, reduce opacity, until the shadow reads as depth rather than border.

**The Halo Distinction.** The primary minibubble carries a breathing halo shadow (opacity 0.25, blur 32px, 480ms InOutCubic morph). This is the only context where a shadow has animation. All other shadows are static.

## 5. Components

### Island Pill (Collapsed State)
The resting face of the island. Solid mode: Collapsed Void (#181825) at full opacity. Glass mode: 9% white tint over compositor blur, same rounded shape. Radius: `radXl` (28px). Hairline border at text color 12% alpha (barely there, just enough to define the edge against the wallpaper in glass mode). Internal content uses 12px horizontal spacing (sp3). No padding on the pill itself — content is positioned absolutely within.

### Minibubbles
Status pills that float around the island. Same radius as the pill (`radXl`, 28px). Background: Lifted Plum (#313244) at ~90% opacity. Shadow: elev1 (Signal Lift) always present. Primary bubble carries an animated halo shadow (opacity 0.25) and is scaled to 1.0; satellite bubbles scale to 0.82 with 480ms InOutCubic transition. Press feedback: scale 0.92.

- **Primary state:** Full opacity, full scale (1.0), halo shadow active
- **Satellite state:** Full opacity, scale 0.82, no halo
- **Hidden:** opacity 0, no shadow

### Expanded Page
The island in expanded state. Background: Near-Black Indigo at full opacity (solid mode) or transparent over compositor blur (glass). Radius: `radXl` (28px), matching the collapsed pill so the expansion reads as the same object morphing. Page-specific backgrounds (music: drifting color blobs) are composited inside this container and masked to the island shape. Internal padding: 16px (sp4) horizontal, 12px (sp3) vertical.

### Action Buttons (Page Controls)
- **Shape:** Gently curved (10px, radSm)
- **Default:** Lifted Plum (#313244) background, Pale Sky text
- **Active / Selected:** Muted Iris text, same Lifted Plum background — color shift only, no shape change
- **Hover:** Raised Surface (#45475a) background
- **Press:** Scale 0.92, Raised Surface background
- **Transition:** 120ms (durFast) background; no transition on text color

### Applet Chips (Topbar)
- **Default:** Transparent background, Faded Cloud (#a6adc8) text
- **Active / Focused:** Lifted Plum (#313244) background, Muted Iris text, radSm (10px) radius
- **Dividers:** 1px vertical hairline at text 10% alpha between chip groups
- **Icons:** Iosevka Nerd Font, matched to the chip's text color

### Notification Row
- **App icon:** Iosevka Nerd Font glyph, 24px, in the notification source's accent color (defaults to Muted Iris)
- **Source label:** JetBrains Mono Black, 11px, 1.5px letter-spacing, Muted Iris — uppercase. This is the only place uppercase tracking is used.
- **Title:** SF Pro Text DemiBold, 14px, Pale Sky
- **Body:** SF Pro Text Regular, 11-12px, Faded Cloud
- **Timestamp:** JetBrains Mono, 10px, Muted Fog
- **Separator:** 1px horizontal line at text 8% alpha

### Clock Display (Collapsed)
Time string in JetBrains Mono Black (15px, ls -0.3px) in Pale Sky. Date in JetBrains Mono Medium (10px) in Faded Cloud. Separated by a 1px vertical hairline at text 10% alpha, 16px tall. Weather icon at 22px Iosevka Nerd Font in Muted Iris; temperature in JetBrains Mono Black (16px) in Soft Peach.

## 6. Do's and Don'ts

### Do:
- **Do** use Muted Iris exclusively as a signal: active states, focused elements, interactive labels. Its rarity is the design.
- **Do** use JetBrains Mono Black for every numeric value that represents a measurement (time, temperature, OSD values, percentages).
- **Do** keep resting-state surfaces below `lifted-plum` (#313244). The island must recede when inactive. Base (#1e1e2e) and mantle (#181825) are the resting palette.
- **Do** use large-blur, low-opacity shadows (elev tokens). If a shadow looks like a border, reduce opacity and increase blur until it reads as atmosphere.
- **Do** animate at 120-320ms with `easeOutCubic` or `OutExpo` for transitions, `OutBack` (overshoot ≤1.2) for press-feedback scale and entry animations. Press feedback at 90–94% scale. Motion confirms state; it does not perform.
- **Do** tint every new surface toward the blue-violet hue family. No neutral grays. Minimum chroma ~0.02 at the near-black end.
- **Do** use the semantic aliases (`accent`, `accentAlt`, `warning`, `danger`, `positive`) in new components. Theme-switching is guaranteed to work only through these aliases.
- **Do** treat glass mode as a separate surface contract: tintAlpha 6-9%, compositor blur handles depth. Never add additional blur effects on top of HyprGlass regions.

### Don't:
- **Don't** make Muted Iris a background fill or container color. It is a text and icon accent only. Background use at any significant area breaks the Rarity Rule.
- **Don't** use flat neutral grays (e.g. #2a2a2a, #333333 with no hue) in any surface. They break the hue-family system and read as dropped in from a different design language.
- **Don't** recreate the macOS Dynamic Island pixel-for-pixel. Derivative shape and behavior choices with no original design identity are explicitly out of scope.
- **Don't** add neon or heavily-saturated accent colors outside the 6 defined themes. Neon primaries, glow effects for decoration, and anime-rice aesthetics are anti-references.
- **Don't** use `border-left` or `border-right` greater than 1px as a colored accent stripe on any container. Rewrite with full borders, background tints, or leading icons.
- **Don't** use gradient text (`background-clip: text` + gradient). Emphasis is weight and color, not gradients applied to letterforms.
- **Don't** animate layout properties (width, height, x, y directly except via Behavior on x/y for repositioning). Animate opacity, scale, and color.
- **Don't** add glassmorphism decoratively. Glass mode is a system-level surface contract (HyprGlass compositor, not QML blur). Blurred QML items on top of glass surfaces double-blur and look murky.
- **Don't** render the island at lower than `radXl` (28px) in any expanded or collapsed state. The pill identity is the radius.
- **Don't** introduce a Generic Waybar aesthetic: flat layout, no surface depth, uniform icon-and-text rows with zero spacing rhythm. The island has hierarchy; replicate it.
