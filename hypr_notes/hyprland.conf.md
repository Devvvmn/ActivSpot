# 🛰️ hyprland.conf

## 📝 Description
The main configuration file for the Hyprland compositor. It defines the window rules, input settings, monitors, keybindings, and startup applications.

## 🔍 Key Components & Interactions
- **Input/Monitors**: Configures how hardware interacts with the session.
- **Exec**: Used to launch background processes like `hyprpaper`, `hypridle`, or status bars.
- **Window Rules**: Defines behavior for specific application windows.
- **Keybinds**: The core logic for user interaction.

## 🔗 Dependencies
- 🖼️ `hyprpaper.conf` (via `exec-once = hyprpaper`)
- 💤 `hypridle.conf` (via `exec-once = hypridle`)
- 🔒 `hyprlock.conf` (called by `hypridle`)
