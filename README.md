# ActivSpot — Dynamic Island for Hyprland

<img width="1946" height="95" alt="image" src="https://github.com/user-attachments/assets/a7ede955-5f4f-4315-ab26-dc21555a0c17" />


My vision of a dynamic island for Hyprland. Originally developed for personal use, shared after genuine interest from the Reddit community.

> Based on [nixos-configuration](https://github.com/ilyamiro/nixos-configuration) by ilyamiro

---

## Features

**Contextual content** — automatically switches based on system state:
- Music player (album art, title, artist, progress)
- Discord voice call (live timer, mute button)
- Screen recording indicator
- Notifications with expand-to-read
- Clock + weather (default)

**Dual bubble** — Discord call pill appears alongside music player simultaneously  
**App Launcher** — island morphs into Spotlight-style launcher with fuzzy search and icons  
**Clipboard Viewer** — cliphist-based history with image/text detection  
**VPN badge** — lock icon with snap-shut animation under temperature  
**Pet pill** — animated cat reacts to music and notifications  

---

## Stack

| Component     | Technology              |
|---------------|-------------------------|
| Shell         | Quickshell              |
| Language      | QML                     |
| Compositor    | Hyprland                |
| IPC           | inotifywait on /tmp/qs_* |
| Music         | playerctl               |
| Weather       | wttr.in                 |
| Clipboard     | cliphist + wl-copy      |
| Notifications | custom daemon           |

---

## Dependencies
quickshell inotify-tools playerctl cliphist wl-clipboard
python3 gtk-launch flatpak (optional)
JetBrains Mono, Iosevka Nerd Font

---

## Installation

Clone repo

Run instalation script

---

## Keybinds

| Bind          | Action           |
|---------------|------------------|
| Super + Space | App Launcher     |
| Super + C     | Clipboard Viewer |

---

## Architecture

Each component is a separate `PanelWindow`. IPC works via `inotifywait` on `/tmp/qs_*` files — no sockets, no daemons. The island hides itself when the launcher opens via `/tmp/qs_launcher_state`, creating a morph illusion since both windows share the same top-center position.
