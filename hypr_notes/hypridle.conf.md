# 💤 hypridle.conf

## 📝 Description
Configuration for `hypridle`, the idle management daemon. It monitors user inactivity and executes commands when thresholds are met.

## 🔍 Key Components
- **listener**: Defines time intervals (sec).
- **lock**: Commands to execute when idle (e.g., `hyprlock`).
- **dpms**: Maniodling monitor power states.

## 🔗 Dependencies
- 🛰️ `hyprland.conf` (Launched as a process)
- 🔒 `hyprlock.conf` (Triggered during idle state)
