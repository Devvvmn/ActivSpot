# Air Quality

Displays real-time air quality data with EPA color coding.
Shows AQI index (US EPA or European scale) and pollutant breakdown for PM2.5, PM10, O3, NO2, CO, and SO2.

## Data Sources

| Source | Type | API Key | AQI Scales |
|--------|------|---------|------------|
| **Open-Meteo** (default) | Forecasting (CAMS atmospheric models) | Not required | US EPA, European |
| **AQICN** | Real monitoring station data | Free token required | US EPA only |

- **Open-Meteo** uses Copernicus CAMS atmospheric models at 11-40km resolution. No API key needed, but values are forecasted estimates.
- **AQICN** provides real-time data from the nearest EPA monitoring station. Requires a free API token from [aqicn.org/data-platform/token](https://aqicn.org/data-platform/token). Shows the station name in the location pill.

## Features

**Bar Widget**
- AQI number colored by level (EPA color scale)
- Tooltip with full pollutant breakdown
- Left click to open panel
- Right click for context menu
- Middle click to refresh

**Panel**
- Large AQI number with level indicator
- Location pill with last update time (shows station name when using AQICN)
- Pollutant rows with colored indicators
- Refresh and settings buttons

**Desktop Widget**
- Draggable AQI display with level and city
- PM2.5 and PM10 values
- Left click to open panel
- Middle click to refresh

**Settings**
- Data source: Open-Meteo (forecasting) or AQICN (real station data)
- AQICN API token field (visible when AQICN selected)
- AQI scale: US AQI (EPA) or European AQI (disabled when using AQICN)
- Location: use Noctalia location or custom coordinates
- Refresh interval (5-120 minutes)
- Bold text toggle

**IPC**
- Refresh: `qs -c noctalia-shell ipc call plugin:air-quality refresh`
- Toggle panel: `qs -c noctalia-shell ipc call plugin:air-quality toggle`
