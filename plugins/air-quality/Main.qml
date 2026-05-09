import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.Location
import qs.Services.UI

Item {
  id: root
  property var pluginApi: null

  // Settings access
  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  // Shared state — consumed by BarWidget, Panel, DesktopWidget
  property int usAqi: 0
  property int europeanAqi: 0
  property real pm25: 0
  property real pm10: 0
  property real ozone: 0
  property real no2: 0
  property real co: 0
  property real so2: 0
  property string lastUpdate: ""
  property bool loading: false
  property bool hasData: false
  property string errorMessage: ""
  property string stationName: ""

  // Current scale from settings
  readonly property string aqiScale: cfg.aqiScale ?? defaults.aqiScale ?? "us"
  readonly property bool useNoctaliaLocation: cfg.useNoctaliaLocation ?? defaults.useNoctaliaLocation ?? true
  readonly property string dataSource: cfg.dataSource ?? defaults.dataSource ?? "open-meteo"
  readonly property string aqicnToken: cfg.aqicnToken ?? defaults.aqicnToken ?? ""

  Component.onCompleted: {
    Logger.i("Air Quality", "Plugin loaded, starting initial fetch...")
    refresh()
  }

  // Refresh timer
  Timer {
    interval: (root.cfg.refreshInterval ?? root.defaults.refreshInterval ?? 30) * 60000
    running: true
    repeat: true
    onTriggered: {
      Logger.d("Air Quality", "Timer refresh...")
      root.refresh()
    }
  }

  // IPC handler
  IpcHandler {
    target: "plugin:air-quality"

    function refresh() {
      Logger.d("Air Quality", "Refreshing through IPC...")
      root.refresh()
    }

    function toggle() {
      if (root.pluginApi) {
        root.pluginApi.withCurrentScreen(screen => {
          root.pluginApi.togglePanel(screen)
        })
      }
    }
  }

  // HTTP fetch process
  Process {
    id: fetchProcess
    onExited: (exitCode, exitStatus) => {
      if (exitCode !== 0) {
        Logger.w("Air Quality", "curl exited with code " + exitCode)
        root.loading = false
      }
    }
    stdout: StdioCollector {
      onStreamFinished: {
        var output = this.text.trim()
        if (!output) {
          Logger.w("Air Quality", "Empty response from API")
          root.loading = false
          return
        }
        try {
          var data = JSON.parse(output)
          if (data.current) {
            root.usAqi = data.current.us_aqi ?? 0
            root.europeanAqi = data.current.european_aqi ?? 0
            root.pm25 = data.current.pm2_5 ?? 0
            root.pm10 = data.current.pm10 ?? 0
            root.ozone = data.current.ozone ?? 0
            root.no2 = data.current.nitrogen_dioxide ?? 0
            root.co = data.current.carbon_monoxide ?? 0
            root.so2 = data.current.sulphur_dioxide ?? 0
            root.hasData = true

            var now = new Date()
            root.lastUpdate = Qt.formatTime(now, "HH:mm")

            Logger.i("Air Quality", "Data updated — US AQI: " + root.usAqi + ", EU AQI: " + root.europeanAqi)
          } else {
            Logger.w("Air Quality", "No 'current' field in API response")
          }
        } catch (e) {
          Logger.e("Air Quality", "Failed to parse API response: " + e.message)
        }
        root.loading = false
      }
    }
  }

  Process {
    id: aqicnFetchProcess
    onExited: (exitCode, exitStatus) => {
      if (exitCode !== 0) {
        Logger.w("Air Quality", "AQICN curl exited with code " + exitCode)
        root.loading = false
      }
    }
    stdout: StdioCollector {
      onStreamFinished: {
        var output = this.text.trim()
        if (!output) {
          Logger.w("Air Quality", "Empty response from AQICN API")
          root.loading = false
          return
        }
        try {
          var response = JSON.parse(output)
          if (response.status !== "ok") {
            root.errorMessage = pluginApi?.tr("errors.aqicnApiFailed")
            Logger.w("Air Quality", "AQICN API error: " + (response.data ?? "unknown"))
            root.loading = false
            return
          }
          var data = response.data
          root.usAqi = data.aqi ?? 0
          root.europeanAqi = 0
          root.pm25 = data.iaqi?.pm25?.v ?? 0
          root.pm10 = data.iaqi?.pm10?.v ?? 0
          root.ozone = data.iaqi?.o3?.v ?? 0
          root.no2 = data.iaqi?.no2?.v ?? 0
          root.co = data.iaqi?.co?.v ?? 0
          root.so2 = data.iaqi?.so2?.v ?? 0
          root.stationName = data.city?.name ?? ""
          root.hasData = true

          var now = new Date()
          root.lastUpdate = Qt.formatTime(now, "HH:mm")

          Logger.i("Air Quality", "AQICN data updated — AQI: " + root.usAqi + " Station: " + root.stationName)
        } catch (e) {
          Logger.e("Air Quality", "Failed to parse AQICN response: " + e.message)
        }
        root.loading = false
      }
    }
  }

  // Get current AQI value based on selected scale
  function getAqi() {
    return aqiScale === "eu" ? europeanAqi : usAqi
  }

  // Get color for a given AQI value
  function getAqiColor(value, scale) {
    if (!scale) scale = aqiScale
    if (scale === "eu") {
      if (value <= 20) return "#50F0E6"
      if (value <= 40) return "#50CCAA"
      if (value <= 60) return "#F0E641"
      if (value <= 80) return "#FF5050"
      if (value <= 100) return "#960032"
      return "#7D2181"
    }
    // US EPA scale
    if (value <= 50) return "#00E400"
    if (value <= 100) return "#FFFF00"
    if (value <= 150) return "#FF7E00"
    if (value <= 200) return "#FF0000"
    if (value <= 300) return "#8F3F97"
    return "#7E0023"
  }

  // Get level string key for i18n
  function getAqiLevel(value, scale) {
    if (!scale) scale = aqiScale
    if (scale === "eu") {
      if (value <= 20) return "levels.good"
      if (value <= 40) return "levels.fair"
      if (value <= 60) return "levels.moderate"
      if (value <= 80) return "levels.poor"
      if (value <= 100) return "levels.veryPoor"
      return "levels.extremelyPoor"
    }
    // US EPA scale
    if (value <= 50) return "levels.good"
    if (value <= 100) return "levels.moderate"
    if (value <= 150) return "levels.unhealthySensitive"
    if (value <= 200) return "levels.unhealthy"
    if (value <= 300) return "levels.veryUnhealthy"
    return "levels.hazardous"
  }

  // Get location name for display
  function getLocationName() {
    if (dataSource === "aqicn" && stationName) {
      return stationName
    }
    if (useNoctaliaLocation) {
      var name = Settings.data.location?.name ?? ""
      if (name) {
        var chunks = name.split(",")
        return chunks[0].trim()
      }
      return ""
    }
    return pluginApi?.tr("location.custom")
  }

  // Get pollutant-specific color (simplified scale)
  function getPollutantColor(pollutant, value) {
    // Simplified: map pollutant ranges to US AQI-like colors
    var thresholds = {
      "pm25":  [12, 35.4, 55.4, 150.4, 250.4],
      "pm10":  [54, 154, 254, 354, 424],
      "ozone": [54, 70, 85, 105, 200],
      "no2":   [53, 100, 360, 649, 1249],
      "co":    [4400, 9400, 12400, 15400, 30400],
      "so2":   [35, 75, 185, 304, 604]
    }
    var colors = ["#4CAF50", "#FFEB3B", "#FF9800", "#F44336", "#9C27B0", "#79000F"]
    var t = thresholds[pollutant]
    if (!t) return colors[0]
    for (var i = 0; i < t.length; i++) {
      if (value <= t[i]) return colors[i]
    }
    return colors[colors.length - 1]
  }

  function refresh() {
    if (loading) return
    root.errorMessage = ""

    var lat, lon
    if (useNoctaliaLocation) {
      // Try to get lat/lon from Noctalia's weather data
      if (!Settings.data.location?.weatherEnabled) {
        root.errorMessage = pluginApi?.tr("errors.weatherDisabled")
        Logger.w("Air Quality", "Weather/location not enabled in Noctalia settings")
        return
      }
      var weather = LocationService?.data?.weather
      if (weather && weather.latitude !== undefined) {
        lat = weather.latitude
        lon = weather.longitude
      } else {
        root.errorMessage = pluginApi?.tr("errors.locationUnavailable")
        Logger.w("Air Quality", "Noctalia location not available yet")
        return
      }
    } else {
      lat = (cfg.customLatitude ?? defaults.customLatitude ?? "").toString().trim()
      lon = (cfg.customLongitude ?? defaults.customLongitude ?? "").toString().trim()
      Logger.d("Air Quality", "Custom coordinates: lat=" + lat + " lon=" + lon)
      if (!lat || !lon) {
        Logger.w("Air Quality", "Custom coordinates not set")
        return
      }
    }

    root.loading = true
    root.stationName = ""

    if (root.dataSource === "aqicn") {
      if (!root.aqicnToken) {
        root.errorMessage = pluginApi?.tr("errors.aqicnTokenMissing")
        Logger.w("Air Quality", "AQICN token not configured")
        root.loading = false
        return
      }
      var aqicnUrl = "https://api.waqi.info/feed/geo:" + lat + ";" + lon + "/?token=" + root.aqicnToken
      Logger.d("Air Quality", "Fetching AQICN data for geo:" + lat + ";" + lon)
      aqicnFetchProcess.command = ["curl", "-s", aqicnUrl]
      aqicnFetchProcess.running = true
    } else {
      var url = "https://air-quality-api.open-meteo.com/v1/air-quality?latitude=" + lat + "&longitude=" + lon + "&current=us_aqi,european_aqi,pm2_5,pm10,ozone,nitrogen_dioxide,carbon_monoxide,sulphur_dioxide&timezone=auto"
      Logger.d("Air Quality", "Fetching Open-Meteo: " + url)
      fetchProcess.command = ["curl", "-s", url]
      fetchProcess.running = true
    }
  }
}
