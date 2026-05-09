import QtQuick
import QtQuick.Effects
import "../themes"

// Animated weather scene using Meteocons (Bas Milius, MIT) static-fill SVGs
// as the visual atoms. Background gradient + drifting cloud parallax +
// hero weather icon + particle layer for rain/snow + lightning flash.
// Visuals are clipped to the island's rounded radius via MultiEffect mask.
Item {
    id: root
    property var island
    property string desc: ""
    property string timeStr: "12:00"

    readonly property bool reduceMotion: Theme.reduceMotion
    readonly property int hour: parseInt((timeStr || "12").substring(0,2)) || 12
    readonly property bool isNight: hour < 6 || hour >= 20

    // Time-of-day phase. Drives sky tint independently of weather state so
    // dawn/dusk read distinctly even on clear/cloudy days.
    readonly property string timeOfDay: {
        if (hour >= 5  && hour < 8)   return "dawn"   // 05-07: rose/peach horizon
        if (hour >= 8  && hour < 17)  return "day"    // 08-16: bright blue
        if (hour >= 17 && hour < 20)  return "dusk"   // 17-19: orange/violet
        return "night"                                // 20-04: dark indigo
    }

    // Time-of-day sky tint — top stop of the sky gradient. Weather state
    // overrides this for stormy/heavy weather; clear/cloudy/sunny states
    // blend into it via mixWeight.
    readonly property color _todTop: {
        switch (timeOfDay) {
        case "dawn":  return Qt.rgba(0.92, 0.62, 0.55, 0.45)  // rose
        case "day":   return Qt.rgba(0.36, 0.66, 0.95, 0.30)  // sky-blue
        case "dusk":  return Qt.rgba(0.96, 0.50, 0.30, 0.42)  // sunset orange
        case "night": return Qt.rgba(0.06, 0.08, 0.20, 0.65)  // indigo
        }
        return Qt.rgba(0.36, 0.66, 0.95, 0.30)
    }

    readonly property string state: {
        const d = (desc || "").toLowerCase()
        if (!d) return isNight ? "night-clear" : "default"
        if (d.indexOf("storm")    !== -1) return "storm"
        if (d.indexOf("snow")     !== -1) return "snow"
        if (d.indexOf("rain")     !== -1 || d.indexOf("shower") !== -1) return "rain"
        if (d.indexOf("mist")     !== -1 || d.indexOf("fog")    !== -1) return "fog"
        if (d === "clear")                return "night-clear"
        if (d === "sunny")                return "sunny"
        if (d.indexOf("overcast") !== -1) return isNight ? "overcast-night" : "overcast"
        if (d.indexOf("cloud")    !== -1) return isNight ? "cloudy-night" : "cloudy"
        return "default"
    }

    readonly property string heroIcon: {
        switch (state) {
        case "sunny":          return "../assets/weather/clear-day.svg"
        case "night-clear":    return "../assets/weather/clear-night.svg"
        case "cloudy":         return "../assets/weather/partly-cloudy-day.svg"
        case "cloudy-night":   return "../assets/weather/partly-cloudy-night.svg"
        case "overcast":       return "../assets/weather/overcast-day.svg"
        case "overcast-night": return "../assets/weather/overcast-night.svg"
        case "rain":           return "../assets/weather/rain.svg"
        case "snow":           return "../assets/weather/snow.svg"
        case "storm":          return isNight ? "../assets/weather/thunderstorms-night-rain.svg"
                                              : "../assets/weather/thunderstorms-day-rain.svg"
        case "fog":            return isNight ? "../assets/weather/fog-night.svg"
                                              : "../assets/weather/fog-day.svg"
        default:               return "../assets/weather/cloudy.svg"
        }
    }

    // ── Mask source: rounded-rect, used by MultiEffect to clip content ─
    Item {
        id: maskHost
        anchors.fill: parent
        visible: false
        layer.enabled: true
        Rectangle {
            anchors.fill: parent
            radius: island.s(26)
            color: "white"
        }
    }

    // ── Clipped content layer ──────────────────────────────────────────
    Item {
        id: content
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: maskHost
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }

        // ── Sky gradient ───────────────────────────────────────────────
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    // Heavy weather (storm/rain/snow/fog) overrides time-of-day
                    // for atmosphere; clear and cloudy states inherit `_todTop`
                    // so dawn/day/dusk/night reads distinctly.
                    color: {
                        switch (root.state) {
                        case "storm":          return Qt.rgba(0.08, 0.08, 0.16, 0.65)
                        case "rain":           return Qt.rgba(island.blue.r,  island.blue.g,  island.blue.b,  0.20)
                        case "snow":           return Qt.rgba(0.82, 0.88, 0.98, 0.22)
                        case "fog":            return Qt.rgba(0.55, 0.57, 0.62, 0.35)
                        case "overcast":
                        case "overcast-night":
                            // Overcast is mostly grey but inherits a hint of the
                            // current time-of-day tint via alpha-mix.
                            return Qt.rgba(
                                root._todTop.r * 0.4 + 0.32,
                                root._todTop.g * 0.4 + 0.32,
                                root._todTop.b * 0.4 + 0.34,
                                0.45)
                        default:
                            return root._todTop
                        }
                    }
                    Behavior on color { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(island.base.r, island.base.g, island.base.b, 0.0)
                }
            }
        }

        // ── Stars (night skies) ────────────────────────────────────────
        Repeater {
            model: 28
            delegate: Rectangle {
                id: star
                readonly property real seedX: Math.abs((Math.sin(index * 12.9898) * 43758.5453) % 1)
                readonly property real seedY: Math.abs((Math.cos(index * 78.233)  * 43758.5453) % 1)
                // Visible across all night states; dimmer with cloud cover.
                readonly property real starBase: {
                    switch (root.state) {
                    case "night-clear":    return 0.40
                    case "cloudy-night":   return 0.18
                    case "overcast-night": return 0.10
                    default:               return 0
                    }
                }
                width: island.s(1.5 + (index % 3)); height: width
                radius: width / 2
                color: "white"
                x: parent.width  * seedX * 0.95
                y: parent.height * seedY * 0.55
                opacity: star.starBase > 0 ? (star.starBase + (index % 5) * 0.10) : 0
                Behavior on opacity { NumberAnimation { duration: 800 } }
                SequentialAnimation on opacity {
                    running: !root.reduceMotion && star.starBase > 0
                    loops: Animation.Infinite
                    NumberAnimation { from: star.starBase * 0.85; to: star.starBase + 0.55; duration: 1400 + (index * 73) % 1800; easing.type: Easing.InOutSine }
                    NumberAnimation { from: star.starBase + 0.55; to: star.starBase * 0.85; duration: 1400 + (index * 53) % 1800; easing.type: Easing.InOutSine }
                }
            }
        }

        // ── Parallax cloud layer ───────────────────────────────────────
        // Clouds live in a horizon strip in the upper portion of the scene
        // so they don't compete with hero text below. Three depth tiers for
        // parallax: back (slow, faint, large) → front (fast, opaque, small).
        Repeater {
            id: cloudRepeater
            model: 4
            delegate: Image {
                readonly property bool show: root.state === "cloudy"     || root.state === "cloudy-night"
                                           || root.state === "overcast"  || root.state === "overcast-night"
                                           || root.state === "rain"      || root.state === "storm"
                                           || root.state === "fog"
                // Tier: 0=back, 1=mid, 2=front (cycles per index).
                readonly property int  tier: index % 3
                readonly property real cloudW: island.s(tier === 0 ? 160 : (tier === 1 ? 120 : 90))
                readonly property real speed:  island.s(tier === 0 ? 5  : (tier === 1 ? 10  : 18))
                readonly property real tierOpacity: tier === 0 ? 0.18
                                                  : (tier === 1 ? 0.28 : 0.38)

                source: "../assets/weather/cloudy.svg"
                width: cloudW; height: cloudW * 0.55
                sourceSize.width: cloudW * 2
                sourceSize.height: cloudW * 1.2
                // Horizon strip: clouds sit between 2% and 14% of scene height.
                y: parent.height * (0.02 + tier * 0.04 + (index % 2) * 0.02)
                x: -cloudW + (root.width + cloudW * 2) * (index / 4)
                z: tier
                fillMode: Image.PreserveAspectFit
                smooth: true
                opacity: show
                    ? (root.state === "fog" ? tierOpacity * 0.85
                       : (root.state === "overcast" || root.state === "overcast-night" || root.state === "storm"
                          ? tierOpacity * 1.15
                          : tierOpacity))
                    : 0
                Behavior on opacity { NumberAnimation { duration: 600 } }
            }
        }

        Timer {
            interval: 32
            repeat: true
            running: !root.reduceMotion
            property real prev: 0
            onTriggered: {
                const now = Date.now()
                const dt = prev === 0 ? 0.032 : Math.min(0.10, (now - prev) / 1000)
                prev = now
                for (let i = 0; i < cloudRepeater.count; i++) {
                    const c = cloudRepeater.itemAt(i)
                    if (!c || !c.show) continue
                    let nx = c.x + c.speed * dt
                    if (nx > root.width + c.cloudW) nx = -c.cloudW
                    c.x = nx
                }
            }
        }

        // ── Hero weather icon ──────────────────────────────────────────
        // Discrete "weather stamp" in the top-right. Hidden on cloudy/overcast/
        // rain/storm/fog states where the parallax cloud layer already
        // communicates the weather — would only clutter.
        Image {
            id: hero
            readonly property bool _showHero: root.state === "sunny"
                || root.state === "night-clear" || root.state === "snow"
            source: root.heroIcon
            width: island.s(96); height: width
            sourceSize.width: width * 2
            sourceSize.height: height * 2
            fillMode: Image.PreserveAspectFit
            smooth: true
            x: parent.width  * 0.85 - width / 2
            y: parent.height * 0.13 - height / 2
            opacity: _showHero ? 0.85 : 0.0
            visible: opacity > 0.001

            SequentialAnimation on scale {
                running: !root.reduceMotion
                loops: Animation.Infinite
                NumberAnimation { from: 1.0;  to: 1.05; duration: 2600; easing.type: Easing.InOutSine }
                NumberAnimation { from: 1.05; to: 1.0;  duration: 2600; easing.type: Easing.InOutSine }
            }

            RotationAnimation on rotation {
                running: !root.reduceMotion && root.state === "sunny"
                loops: Animation.Infinite
                from: 0; to: 360
                duration: 90000
            }

            Behavior on opacity { NumberAnimation { duration: 400 } }
        }

        // ── Rain / snow particle canvas ────────────────────────────────
        Canvas {
            id: precip
            anchors.fill: parent
            antialiasing: true
            opacity: (root.state === "rain" || root.state === "storm" || root.state === "snow") ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 500 } }

            property var drops: []
            property int dropCount: root.state === "snow" ? 40 : 70

            function reset() {
                drops = []
                for (let i = 0; i < dropCount; i++) {
                    drops.push({
                        x: Math.random() * width,
                        y: Math.random() * height,
                        v: root.state === "snow" ? (0.4 + Math.random() * 0.6)
                                                 : (4 + Math.random() * 5),
                        r: root.state === "snow" ? (1.3 + Math.random() * 1.8) : 0,
                        sway: Math.random() * Math.PI * 2,
                        len: 6 + Math.random() * 10
                    })
                }
            }

            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                if (root.state === "snow") {
                    ctx.fillStyle = "rgba(255,255,255,0.85)"
                    for (const d of drops) {
                        ctx.beginPath()
                        ctx.arc(d.x + Math.sin(d.sway) * 8, d.y, d.r, 0, Math.PI * 2)
                        ctx.fill()
                    }
                } else {
                    ctx.strokeStyle = root.state === "storm"
                        ? "rgba(180, 200, 255, 0.55)"
                        : "rgba(150, 180, 230, 0.55)"
                    ctx.lineWidth = 1.2
                    for (const d of drops) {
                        ctx.beginPath()
                        ctx.moveTo(d.x, d.y)
                        ctx.lineTo(d.x - 1, d.y + d.len)
                        ctx.stroke()
                    }
                }
            }

            Timer {
                interval: 33
                repeat: true
                running: precip.opacity > 0 && !root.reduceMotion
                onTriggered: {
                    for (const d of precip.drops) {
                        if (root.state === "snow") {
                            d.y += d.v
                            d.sway += 0.04
                            if (d.y > precip.height) { d.y = -4; d.x = Math.random() * precip.width }
                        } else {
                            d.y += d.v
                            d.x -= 0.6
                            if (d.y > precip.height) {
                                d.y = -d.len
                                d.x = Math.random() * (precip.width + 40)
                            }
                        }
                    }
                    precip.requestPaint()
                }
            }

            onWidthChanged:  reset()
            onHeightChanged: reset()
            Component.onCompleted: reset()
            Connections {
                target: root
                function onStateChanged() {
                    precip.dropCount = root.state === "snow" ? 40 : 70
                    precip.reset()
                }
            }
        }

        // ── Lightning flash (storm) ────────────────────────────────────
        Rectangle {
            id: flash
            anchors.fill: parent
            color: "white"
            opacity: 0
            visible: root.state === "storm"
        }
        Timer {
            running: root.state === "storm" && !root.reduceMotion
            repeat: true
            interval: 4500
            onTriggered: {
                interval = 3500 + Math.floor(Math.random() * 5000)
                flashAnim.restart()
            }
        }
        SequentialAnimation {
            id: flashAnim
            NumberAnimation { target: flash; property: "opacity"; from: 0; to: 0.55; duration: 80 }
            NumberAnimation { target: flash; property: "opacity"; to: 0.10; duration: 60 }
            NumberAnimation { target: flash; property: "opacity"; to: 0.45; duration: 70 }
            NumberAnimation { target: flash; property: "opacity"; to: 0;    duration: 220 }
        }

        // ── Content scrim ──────────────────────────────────────────────
        // Darker mid + bottom so hero clock and weather text read cleanly
        // over the parallax sky. Top stays clear so clouds remain visible.
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.00; color: Qt.rgba(island.base.r, island.base.g, island.base.b, 0.0) }
                GradientStop { position: 0.18; color: Qt.rgba(island.base.r, island.base.g, island.base.b, 0.10) }
                GradientStop { position: 0.45; color: Qt.rgba(island.base.r, island.base.g, island.base.b, 0.55) }
                GradientStop { position: 1.00; color: Qt.rgba(island.base.r, island.base.g, island.base.b, 0.78) }
            }
        }
    }
}
