# ActivSpot UI Kit

Interactive HTML prototype of the ActivSpot shell — Dynamic Island + Top Bar + Popup Panels.

## Files

| File | Description |
|------|-------------|
| `index.html` | Main entry — desktop prototype, click-through interactive |
| `DynamicIsland.jsx` | Island pill with collapsed/expanded states, page switching, cat sprite |
| `TopBar.jsx` | Full-width top bar with applets |
| `Bubbles.jsx` | Mini-bubble slots (music, discord, VPN, rec, notif, clock) |
| `Panels.jsx` | Popup panels: music, calendar, battery, network, volume |

## Interactions

- **Click island** → expands to current page (clock, music, notifs)
- **Click outside** → collapses
- **Hover island** → 1.025× scale
- **Click bubbles** → expand island to related page
- **Top bar applets** → open popup panels
- **EQ chips** → switch preset
- **Music controls** → prev/pause/next (visual feedback)

## Design notes

- Colors: Catppuccin Mocha (default). Override by changing CSS vars in `:root`.
- Fonts: JetBrains Mono (loaded from Google Fonts). Iosevka Nerd Font icons substituted with Unicode.
- Cat sprite rendered on `<canvas>` — pixel-art 8×8 grid, 3× scaled.
- All animations match QML easing: OutExpo for morphs, SpringAnimation for bubbles.
