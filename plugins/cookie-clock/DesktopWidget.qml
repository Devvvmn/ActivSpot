import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Modules.DesktopWidgets
import qs.Widgets



DraggableDesktopWidget {
    id: root

    // Plugin API (injected by PluginService)
    property var pluginApi: null

    // ---- Settings with defaults ----
    readonly property int sides: widgetData?.sides ?? pluginApi?.manifest?.metadata?.defaultSettings?.sides ?? 9
    readonly property string dialStyle: widgetData?.dialStyle ?? pluginApi?.manifest?.metadata?.defaultSettings?.dialStyle ?? "dots" // "dots", "numbers", "full", "none"
    readonly property string hourHandStyle: widgetData?.hourHandStyle ?? pluginApi?.manifest?.metadata?.defaultSettings?.hourHandStyle ?? "fill" // "fill", "hollow", "classic", "hide"
    readonly property string minuteHandStyle: widgetData?.minuteHandStyle ?? pluginApi?.manifest?.metadata?.defaultSettings?.minuteHandStyle ?? "medium" // "bold", "medium", "thin", "classic", "hide"
    readonly property string secondHandStyle: widgetData?.secondHandStyle ?? pluginApi?.manifest?.metadata?.defaultSettings?.secondHandStyle ?? "dot" // "dot", "classic", "line", "hide"
    readonly property string dateStyle: widgetData?.dateStyle ?? pluginApi?.manifest?.metadata?.defaultSettings?.dateStyle ?? "bubble" // "bubble", "rect", "hide"
    readonly property bool showSeconds: widgetData?.showSeconds !== undefined
        ? widgetData.showSeconds : (pluginApi?.manifest?.metadata?.defaultSettings?.showSeconds ?? true)
    readonly property bool showHourMarks: widgetData?.showHourMarks !== undefined
        ? widgetData.showHourMarks : (pluginApi?.manifest?.metadata?.defaultSettings?.showHourMarks ?? false)
    readonly property real backgroundOpacity: widgetData?.backgroundOpacity !== undefined
        ? widgetData.backgroundOpacity : (pluginApi?.manifest?.metadata?.defaultSettings?.backgroundOpacity ?? 1.0)
    readonly property real clockSize: 230

    // ---- Clock data ----
    property var systemClock: SystemClock {
        id: sysClock
        precision: root.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }
    readonly property string timeString: Qt.locale().toString(sysClock.date, "hh:mm")
    readonly property list<string> clockNumbers: timeString.split(/[: ]/)
    readonly property int clockHour: parseInt(clockNumbers[0]) % 12
    readonly property int clockMinute: sysClock.minutes
    readonly property int clockSecond: sysClock.seconds

    // ---- Colors (from Noctalia theme) ----
    readonly property bool isDark: typeof Settings !== "undefined" && Settings.data && Settings.data.colorSchemes ? Settings.data.colorSchemes.darkMode : true
    readonly property color colBackground: Color.mSurfaceVariant
    readonly property color colOnBackground: Color.mOnSurfaceVariant
    readonly property color colHourHand: Color.mPrimary
    readonly property color colMinuteHand: Color.mTertiary
    readonly property color colSecondHand: Color.mPrimary
    readonly property color colBackgroundInfo: Color.mOnSurfaceVariant
    
    // Container colors
    readonly property color colTertiaryContainer: Color.mTertiary
    readonly property color colOnTertiaryContainer: Color.mOnTertiary
    readonly property color colSecondaryContainer: Color.mSecondary
    readonly property color colOnSecondaryContainer: Color.mOnSecondary
    readonly property color colSurfaceContainerHighest: Color.mSurfaceVariant
    readonly property color colOnSurface: Color.mOnSurface

    // Transparent background - the cookie shape IS the background
    showBackground: false

    // ---- Sizing ----
    readonly property real scaledClockSize: Math.round(clockSize * widgetScale)
    implicitWidth: scaledClockSize + Math.round(30 * widgetScale)
    implicitHeight: scaledClockSize + Math.round(30 * widgetScale)
    width: implicitWidth
    height: implicitHeight

    // ---- Main clock face ----
    Item {
        id: clockFace
        anchors.centerIn: parent
        width: root.scaledClockSize
        height: root.scaledClockSize

        // Cookie-shaped background with shadow
        DropShadow {
            source: cookieShape
            anchors.fill: cookieShape
            radius: 8
            samples: 17
            color: Qt.rgba(0, 0, 0, 0.4)
            transparentBorder: true
            visible: root.backgroundOpacity > 0
            opacity: root.backgroundOpacity
        }

        // Sine-wave cookie shape background
        SineCookieShape {
            id: cookieShape
            anchors.fill: parent
            visible: false
            sides: root.sides
            color: root.colBackground
        }

        // Dial marks (dots / numbers / lines)
        DialMarks {
            anchors {
                fill: parent
                margins: Math.round(10 * root.widgetScale)
            }
            color: root.colOnBackground
            style: root.dialStyle
            widgetScale: root.widgetScale
        }

        // Hour marks circle in center
        Loader {
            anchors.centerIn: parent
            active: root.showHourMarks
            visible: active
            sourceComponent: HourMarksCircle {
                circleSize: Math.round(135 * root.widgetScale)
                markLength: Math.round(12 * root.widgetScale)
                markWidth: Math.round(4 * root.widgetScale)
                color: root.colOnBackground
                markColor: root.colBackgroundInfo
            }
        }

        // Minute hand (z: 1)
        Loader {
            anchors.fill: parent
            z: 1
            active: root.minuteHandStyle !== "hide"
            visible: active
            sourceComponent: MinuteHandItem {
                anchors.fill: parent
                clockMinute: root.clockMinute
                style: root.minuteHandStyle
                color: root.colMinuteHand
                widgetScale: root.widgetScale
            }
        }

        // Hour hand (z: 0 or 2 depending on style)
        Loader {
            anchors.fill: parent
            z: root.hourHandStyle === "hollow" ? 0 : 2
            active: root.hourHandStyle !== "hide"
            visible: active
            sourceComponent: HourHandItem {
                anchors.fill: parent
                clockHour: root.clockHour
                clockMinute: root.clockMinute
                style: root.hourHandStyle
                color: root.colHourHand
                widgetScale: root.widgetScale
            }
        }

        // Center dot (z: 4)
        Rectangle {
            z: 4
            anchors.centerIn: parent
            visible: root.minuteHandStyle !== "bold" && root.minuteHandStyle !== "hide"
            width: Math.round(6 * root.widgetScale)
            height: width
            radius: width / 2
            color: root.minuteHandStyle === "medium" ? root.colBackground : root.colMinuteHand
        }

        // Second hand (z: 3)
        Loader {
            anchors.fill: parent
            z: 3
            active: root.showSeconds && root.secondHandStyle !== "hide"
            visible: active
            sourceComponent: SecondHandItem {
                anchors.fill: parent
                clockSecond: root.clockSecond
                style: root.secondHandStyle
                color: root.colSecondHand
                widgetScale: root.widgetScale
            }
        }

        // Date bubbles
        Loader {
            anchors.fill: parent
            active: root.dateStyle !== "hide"
            visible: active
            sourceComponent: DateIndicatorItem {
                anchors.fill: parent
                style: root.dateStyle
                clockDate: sysClock.date
                widgetScale: root.widgetScale
            }
        }
    }

    // ==========================================
    // INLINE COMPONENTS
    // ==========================================

    // ---- Sine-wave cookie shaped background ----
    component SineCookieShape: Item {
        id: sineCookie
        property real sides: 12
        property color color: "#000000"
        property real amplitude: width / 50
        property int renderPoints: 360

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: 0
                fillColor: sineCookie.color
                pathHints: ShapePath.PathSolid & ShapePath.PathNonIntersecting
                PathPolyline {
                    path: {
                        var points = []
                        var cx = sineCookie.width / 2
                        var cy = sineCookie.height / 2
                        var steps = sineCookie.renderPoints
                        var radius = sineCookie.width / 2 - sineCookie.amplitude
                        for (var i = 0; i <= steps; i++) {
                            var angle = (i / steps) * 2 * Math.PI
                            var wave = Math.sin(angle * sineCookie.sides + Math.PI / 2) * sineCookie.amplitude
                            var x = Math.cos(angle) * (radius + wave) + cx
                            var y = Math.sin(angle) * (radius + wave) + cy
                            points.push(Qt.point(x, y))
                        }
                        return points
                    }
                }
            }
        }
    }

    // ---- Dial marks (dots / numbers / full lines) ----
    component DialMarks: Item {
        id: dialMarksRoot
        property color color: "white"
        property string style: "dots"
        property real widgetScale: 1.0

        // 12 Dots
        Loader {
            anchors.fill: parent
            active: dialMarksRoot.style === "dots"
            visible: active
            opacity: active ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            sourceComponent: Item {
                anchors.fill: parent
                Repeater {
                    model: 12
                    Item {
                        required property int index
                        anchors.fill: parent
                        rotation: 360 / 12 * index
                        Rectangle {
                            anchors {
                                left: parent.left
                                verticalCenter: parent.verticalCenter
                                leftMargin: Math.round(12 * dialMarksRoot.widgetScale)
                            }
                            width: Math.round(12 * dialMarksRoot.widgetScale)
                            height: width
                            radius: width / 2
                            color: dialMarksRoot.color
                        }
                    }
                }
            }
        }

        // 3-6-9-12 hour numbers
        Loader {
            anchors.fill: parent
            active: dialMarksRoot.style === "numbers"
            visible: active
            opacity: active ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            sourceComponent: Item {
                anchors.fill: parent
                Repeater {
                    model: 4
                    Item {
                        required property int index
                        rotation: 360 / 4 * (index + 1)
                        anchors.fill: parent
                        Item {
                            width: Math.round(80 * dialMarksRoot.widgetScale)
                            height: width
                            anchors {
                                top: parent.top
                                horizontalCenter: parent.horizontalCenter
                                topMargin: Math.round(10 * dialMarksRoot.widgetScale)
                            }
                            NText {
                                anchors.centerIn: parent
                                color: dialMarksRoot.color
                                text: String(12 / 4 * (parent.parent.index + 1))
                                rotation: -parent.parent.rotation
                                pointSize: Math.round(Style.fontSizeXXXL * dialMarksRoot.widgetScale)
                                font.weight: Font.Black
                            }
                        }
                    }
                }
            }
        }

        // Full dial (hour + minute lines)
        Loader {
            anchors.fill: parent
            active: dialMarksRoot.style === "full"
            visible: active
            opacity: active ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            sourceComponent: Item {
                anchors.fill: parent
                // Hour lines
                Repeater {
                    model: 12
                    Item {
                        required property int index
                        rotation: 360 / 12 * index
                        anchors.fill: parent
                        Rectangle {
                            anchors {
                                left: parent.left
                                verticalCenter: parent.verticalCenter
                                leftMargin: Math.round(12 * dialMarksRoot.widgetScale)
                            }
                            width: Math.round(18 * dialMarksRoot.widgetScale)
                            height: Math.round(4 * dialMarksRoot.widgetScale)
                            radius: width / 2
                            color: dialMarksRoot.color
                        }
                    }
                }
                // Minute lines
                Repeater {
                    model: 60
                    Item {
                        required property int index
                        rotation: 360 / 60 * index
                        anchors.fill: parent
                        Rectangle {
                            anchors {
                                left: parent.left
                                verticalCenter: parent.verticalCenter
                                leftMargin: Math.round(12 * dialMarksRoot.widgetScale)
                            }
                            width: Math.round(7 * dialMarksRoot.widgetScale)
                            height: Math.round(2 * dialMarksRoot.widgetScale)
                            radius: width / 2
                            color: dialMarksRoot.color
                        }
                    }
                }
            }
        }
    }

    // ---- Hour marks circle ----
    component HourMarksCircle: Item {
        property real circleSize: 135
        property real markLength: 12
        property real markWidth: 4
        property color color: "gray"
        property color markColor: "gray"

        Rectangle {
            color: parent.color
            anchors.centerIn: parent
            width: parent.circleSize
            height: parent.circleSize
            radius: width / 2

            Repeater {
                model: 12
                Item {
                    required property int index
                    anchors.fill: parent
                    rotation: 360 / 12 * index
                    Rectangle {
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                            leftMargin: Math.round(8 * root.widgetScale)
                        }
                        width: parent.parent.parent.markLength
                        height: parent.parent.parent.markWidth
                        radius: width / 2
                        color: parent.parent.parent.parent.markColor
                    }
                }
            }
        }
    }

    // ---- Hour hand ----
    component HourHandItem: Item {
        id: hourHand
        required property int clockHour
        required property int clockMinute
        property string style: "fill"
        property color color: "#000000"
        property real widgetScale: 1.0
        property real handLength: Math.round(72 * widgetScale)
        property real handWidth: Math.round(20 * widgetScale)

        rotation: -90 + (360 / 12) * (clockHour + clockMinute / 60)
        Behavior on rotation {
            RotationAnimation {
                direction: RotationAnimation.Clockwise
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: (parent.width - hourHand.handWidth) / 2 - (hourHand.style === "classic" ? Math.round(15 * hourHand.widgetScale) : 0)
            width: hourHand.handLength
            height: hourHand.style === "classic" ? Math.round(8 * hourHand.widgetScale) : hourHand.handWidth
            radius: hourHand.style === "classic" ? Math.round(2 * hourHand.widgetScale) : hourHand.handWidth / 2
            color: hourHand.style === "hollow"
                ? "transparent"
                : hourHand.color
            border.color: hourHand.color
            border.width: Math.round(4 * hourHand.widgetScale)
        }
    }

    // ---- Minute hand ----
    component MinuteHandItem: Item {
        id: minuteHand
        required property int clockMinute
        property string style: "medium"
        property color color: "#000000"
        property real widgetScale: 1.0
        property real handLength: Math.round(95 * widgetScale)
        property real handWidth: {
            if (style === "bold") return Math.round(20 * widgetScale)
            if (style === "medium") return Math.round(12 * widgetScale)
            return Math.round(5 * widgetScale)  // thin, classic
        }

        rotation: -90 + (360 / 60) * clockMinute
        Behavior on rotation {
            RotationAnimation {
                direction: RotationAnimation.Clockwise
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: {
                let position = parent.width / 2 - minuteHand.handWidth / 2
                if (minuteHand.style === "classic") position -= Math.round(15 * minuteHand.widgetScale)
                return position
            }
            width: minuteHand.handLength
            height: minuteHand.handWidth
            radius: minuteHand.style === "classic" ? Math.round(2 * minuteHand.widgetScale) : minuteHand.handWidth / 2
            color: minuteHand.color
        }
    }

    // ---- Second hand ----
    component SecondHandItem: Item {
        id: secondHand
        required property int clockSecond
        property string style: "dot"
        property color color: "#000000"
        property real widgetScale: 1.0
        property real dotSize: Math.round(20 * widgetScale)
        property real handLength: Math.round(95 * widgetScale)
        property real handWidth: Math.round(2 * widgetScale)

        rotation: (360 / 60 * clockSecond) + 90

        Rectangle {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: Math.round(10 * secondHand.widgetScale) + (secondHand.style === "dot" ? secondHand.dotSize : 0)
            }
            width: secondHand.style === "dot" ? secondHand.dotSize : secondHand.handLength
            height: secondHand.style === "dot" ? secondHand.dotSize : secondHand.handWidth
            radius: Math.min(width, height) / 2
            color: secondHand.color
        }

        // Classic style dot
        Rectangle {
            visible: secondHand.style === "classic"
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: Math.round(40 * secondHand.widgetScale)
            }
            width: secondHand.style === "classic" ? Math.round(14 * secondHand.widgetScale) : 0
            height: width
            color: secondHand.color
            radius: Math.round(4 * secondHand.widgetScale)
        }
    }

    // ---- Date indicator ----
    component DateIndicatorItem: Item {
        id: dateIndicator
        property string style: "bubble"
        property var clockDate: new Date()
        property real widgetScale: 1.0
        property real bubbleSize: Math.round(64 * widgetScale)

        // Rectangle date (right side)
        Loader {
            active: dateIndicator.style === "rect"
            visible: active
            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
                rightMargin: Math.round(10 * dateIndicator.widgetScale)
            }
            sourceComponent: Rectangle {
                implicitWidth: Math.round(45 * dateIndicator.widgetScale)
                implicitHeight: Math.round(30 * dateIndicator.widgetScale)
                radius: Math.round(6 * dateIndicator.widgetScale)
                color: root.colSurfaceContainerHighest
                NText {
                    anchors.centerIn: parent
                    color: root.colOnSurface
                    text: Qt.locale().toString(dateIndicator.clockDate, "dd")
                    pointSize: Math.round(Style.fontSizeM * dateIndicator.widgetScale)
                    font.weight: Font.Black
                }
            }
        }

        // Bubble style: day of month (top-left)
        Loader {
            active: dateIndicator.style === "bubble"
            visible: active
            anchors {
                left: parent.left
                top: parent.top
            }
            sourceComponent: Rectangle {
                implicitWidth: dateIndicator.bubbleSize
                implicitHeight: dateIndicator.bubbleSize
                radius: width / 2
                color: root.colTertiaryContainer
                NText {
                    anchors.centerIn: parent
                    color: root.colOnTertiaryContainer
                    text: Qt.locale().toString(dateIndicator.clockDate, "d")
                    pointSize: Math.round(Style.fontSizeXL * dateIndicator.widgetScale)
                    font.weight: Font.Black
                }
            }
        }

        // Bubble style: month (bottom-right)
        Loader {
            active: dateIndicator.style === "bubble"
            visible: active
            anchors {
                right: parent.right
                bottom: parent.bottom
            }
            sourceComponent: Rectangle {
                implicitWidth: dateIndicator.bubbleSize
                implicitHeight: dateIndicator.bubbleSize
                radius: width / 2
                color: root.colSecondaryContainer
                NText {
                    anchors.centerIn: parent
                    color: root.colOnSecondaryContainer
                    text: Qt.locale().toString(dateIndicator.clockDate, "MM")
                    pointSize: Math.round(Style.fontSizeXL * dateIndicator.widgetScale)
                    font.weight: Font.Black
                }
            }
        }
    }

    Component.onCompleted: {
        Logger.i("Cookie Clock", "Cookie clock desktop widget loaded")
    }
}
