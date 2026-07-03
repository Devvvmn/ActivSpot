import QtQuick
import "../themes"

BaseBubble {
    id: root

    bubbleId: "activity"
    onTapped: island.currentPage = "activity"

    readonly property bool shouldShow: island.hasActivities
        && island.currentPage !== "activity"
        && !island.expanded

    readonly property bool isDone: island.laTopStatus !== "live"
    readonly property bool isFail: island.laTopStatus === "fail"
    readonly property color accent: isDone ? (isFail ? island.red : island.green) : island.teal

    property int bubbleH: island.s(36)
    height: bubbleH
    width: row.implicitWidth + island.s(24)

    opacity: shouldShow ? 1.0 : 0.0
    visible: opacity > 0.001
    scale:   shouldShow ? 1.0 : 0.05
    transformOrigin: Item.Right

    Behavior on scale { SpringAnimation { spring: 4.0; damping: 0.38 } }

    // Indeterminate spinner rotation — only spins while the top activity is
    // live with no numeric progress
    property real _spin: 0
    NumberAnimation on _spin {
        running: root.shouldShow && !root.isDone && island.laTopProgress === -1 && !Theme.reduceMotion
        loops: Animation.Infinite
        from: 0; to: 360; duration: 1100
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.height / 2
        color: island.glassTheme
            ? Qt.rgba(island.surface2.r, island.surface2.g, island.surface2.b, 0.45)
            : Qt.rgba(island.base.r, island.base.g, island.base.b, 0.94)
        border.width: 1.5
        border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.55)
        Behavior on color        { ColorAnimation { duration: 520; easing.type: Easing.InOutCubic } }
        Behavior on border.color { ColorAnimation { duration: 200 } }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: island.s(6)

        // Progress ring around the activity icon
        Item {
            width: root.bubbleH * 0.62
            height: root.bubbleH * 0.62
            anchors.verticalCenter: parent.verticalCenter

            Canvas {
                id: ring
                anchors.fill: parent
                rotation: island.laTopProgress === -1 && !root.isDone ? root._spin : -90
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    const w = width, c = w / 2, r = c - island.s(1.5)
                    ctx.lineWidth = island.s(2)
                    ctx.lineCap = "round"
                    // Track
                    ctx.strokeStyle = "rgba(255,255,255,0.14)"
                    ctx.beginPath()
                    ctx.arc(c, c, r, 0, Math.PI * 2)
                    ctx.stroke()
                    // Value arc: fraction for numeric progress, fixed 25% arc
                    // for the rotating indeterminate spinner
                    const p = root.isDone ? 1.0
                        : (island.laTopProgress >= 0 ? island.laTopProgress : 0.25)
                    if (island.laTopProgress === -2 && !root.isDone) return
                    ctx.strokeStyle = ring.arcColor()
                    ctx.beginPath()
                    ctx.arc(c, c, r, 0, Math.PI * 2 * Math.max(0.02, Math.min(1, p)))
                    ctx.stroke()
                }
                function arcColor() {
                    const a = root.accent
                    return Qt.rgba(a.r, a.g, a.b, 0.95).toString()
                }
            }
            // Repaint only on discrete inputs (IPC updates / status flips) —
            // never on the Behavior-animated spin (rotation is free)
            Connections {
                target: island
                function onLaTopProgressChanged() { ring.requestPaint() }
                function onLaTopStatusChanged()   { ring.requestPaint() }
            }
            Component.onCompleted: ring.requestPaint()

            Text {
                anchors.centerIn: parent
                text: root.isDone ? (root.isFail ? "󰅖" : "󰄬") : island.laTopIcon
                font.family: "Iosevka Nerd Font"
                font.pixelSize: root.bubbleH * 0.34
                color: root.accent
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }

        Text {
            text: {
                let t = island.laTopTitle
                if (t.length > 16) t = t.substring(0, 15) + "…"
                return t
            }
            font.family: "JetBrains Mono"
            font.pixelSize: root.bubbleH * 0.32
            font.weight: Font.Bold
            color: island.text
            anchors.verticalCenter: parent.verticalCenter
        }

        // Numeric percent when known
        Text {
            visible: island.laTopProgress >= 0 && !root.isDone
            text: Math.round(island.laTopProgress * 100) + "%"
            font.family: "JetBrains Mono"
            font.pixelSize: root.bubbleH * 0.30
            font.weight: Font.Bold
            color: root.accent
            anchors.verticalCenter: parent.verticalCenter
        }

        // Count badge when several activities run at once
        Rectangle {
            visible: island.laCount > 1
            width: island.s(16); height: island.s(16)
            radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.18)
            Text {
                anchors.centerIn: parent
                text: island.laCount
                font.family: "JetBrains Mono"
                font.pixelSize: island.s(9)
                font.weight: Font.Black
                color: root.accent
            }
        }
    }
}
