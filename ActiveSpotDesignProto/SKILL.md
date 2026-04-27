---
name: activspot-design
description: Use this skill to generate well-branded interfaces and assets for ActivSpot — a Dynamic Island shell for Hyprland (Linux/Wayland). Contains essential design guidelines, color tokens, typography, pixel-art cat sprite, and UI kit components for prototyping shell UIs, widgets, and applets.
user-invocable: true
---

Read the README.md file within this skill, and explore the other available files.

If creating visual artifacts (slides, mocks, throwaway prototypes, etc), copy assets out and create static HTML files for the user to view. If working on production code (QML/Quickshell), you can read the rules here to become an expert in designing with this brand.

If the user invokes this skill without any other guidance, ask them what they want to build or design, ask some questions, and act as an expert designer who outputs HTML artifacts _or_ production QML code, depending on the need.

Key things to know before building:
- Color system is Catppuccin Mocha by default, dynamically overridden by Matugen (Material You). Always use CSS vars from colors_and_type.css.
- Primary accent: `--mauve` (#cba6f7). Gradient: mauve → blue.
- Fonts: JetBrains Mono for ALL text; Iosevka Nerd Font for icons (never emoji).
- The cat sprite (Stewart) is a pixel-art 8×8 canvas element — see ui_kits/activspot/DynamicIsland.jsx for the implementation.
- Animations: OutExpo (540ms morph), SpringAnimation (snap), InOutSine (pulse loops).
- All UI floats above the wallpaper — no opaque full-screen backgrounds.
