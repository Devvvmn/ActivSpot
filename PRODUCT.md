# Product

## Register

product

## Users

General Hyprland users who install ActivSpot and actively rice their desktop. They return frequently to tune themes, bubble timing, monitor settings, and bindings as part of an ongoing customization workflow. Context: a terminal-native power user at their desk, multiple monitors, probably dark room, using the configurator alongside their actual Hyprland session.

## Product Purpose

A settings UI that exposes ActivSpot's settings.json and Quickshell shell configuration through a structured, visual interface. Success means the user can make a change, see it reflected on the island immediately, and never have to hand-edit JSON unless they want to. The Raw JSON section is a power-user escape hatch, not the primary path.

## Brand Personality

Modern, stylish, innovative, clean. A tool that takes its own aesthetic seriously: sharp edges, deliberate whitespace, expressive use of the Catppuccin palette. It looks like it was designed, not assembled. It should feel like a first-party companion to the shell it configures.

## Anti-references

- Ultra-clean product UIs (Linear, Notion, Raycast): too minimal, no personality.
- SaaS dashboard softness: rounded cards, gradient metrics, pastel tints.
- Generic Linux dark-mode settings (GNOME/KDE): slate-gray, anonymous, no character.

## Design Principles

1. **Opinionated clarity.** Every choice is made; nothing is left to convention. Hard edges and monospace type are not "brutalist defaults", they are a statement.
2. **Show the system.** The UI should feel structurally transparent, like you can see how it works. Labels are precise, hierarchy is through weight and position, not decoration.
3. **Color earns its place.** Catppuccin accents are used loudly when they signal something (active state, accent action, status) and not as decoration.
4. **Fast feedback loop.** Changes feel immediate. The save/reload path is short and visible at all times.
5. **Power-user respect.** The Raw JSON section is never hidden. Users who want to bypass the GUI should never feel blocked.

## Accessibility & Inclusion

No strict requirements. prefers-reduced-motion is already handled in the stylesheet. Reasonable contrast as a default; no WCAG enforcement needed.
