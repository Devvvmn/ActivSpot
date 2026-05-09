# Cloudflare WARP

Toggle Cloudflare WARP on/off from the Noctalia bar. Shows real-time connection status and current mode.

## Features

- Bar widget with Cloudflare icon and connection status indicator
- Diagonal line overlay on icon when disconnected
- Panel with connect/disconnect button and current WARP mode
- Color customization for connected/disconnected states
- Toast notifications on connect/disconnect
- 16 translations: de, en, es, fr, hu, it, ja, ku, nl, pl, pt, ru, tr, uk-UA, vi, zh-CN

## Requirements

- [Cloudflare WARP for Linux](https://developers.cloudflare.com/warp-client/get-started/linux/) (`warp-cli` must be in PATH)

## Settings

| Setting | Description | Default |
|---|---|---|
| Connected color | Icon color when WARP is connected | primary |
| Disconnected color | Icon color when WARP is disconnected | none (neutral) |
| Refresh interval | How often to poll `warp-cli` for status | 5000 ms |
