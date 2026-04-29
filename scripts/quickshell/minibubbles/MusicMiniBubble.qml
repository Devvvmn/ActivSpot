import QtQuick
import QtQuick.Effects

BaseBubble {
    id: root

    bubbleId: "music"
    onTapped: island.currentPage = "music"

    readonly property bool shouldShow: island.isMediaActive
        && island.currentPage !== "music"
        && !island.expanded

    property int bubbleH: island.s(36)
    height: bubbleH
    width: bubbleRow.implicitWidth + island.s(24)

    opacity: shouldShow ? 1.0 : 0.0
    visible: opacity > 0.001
    scale:   shouldShow ? 1.0 : 0.05
    transformOrigin: Item.Right

    Behavior on opacity { NumberAnimation { duration: island.expanded ? 0 : 360; easing.type: Easing.OutCubic } }
    Behavior on scale   { SpringAnimation { spring: 5.5; damping: 0.7 } }

    // Soft mauve halo behind the pill — gently breathes opacity instead of
    // pulsing the rim. Narrow amplitude + heavy blur reads as ambient glow.
    Rectangle {
        anchors.centerIn: pillBg
        width: pillBg.width + island.s(10)
        height: pillBg.height + island.s(10)
        radius: height / 2
        color: "transparent"
        border.width: island.s(2)
        border.color: island.mauve
        // musicPulse animates 0.22→0.72; remap to a tight 0.10→0.28 band
        opacity: 0.10 + (island.musicPulse - 0.22) * 0.36
        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blurMax: 24
            blur: 1.0
        }
    }

    Rectangle {
        id: pillBg
        anchors.fill: parent
        radius: parent.height / 2
        color: island.glassTheme
            ? Qt.rgba(island.surface2.r, island.surface2.g, island.surface2.b, 0.45)
            : Qt.rgba(island.base.r, island.base.g, island.base.b, 0.94)
        border.width: 1
        border.color: island.glassTheme
            ? Qt.rgba(1, 1, 1, 0.18)
            : Qt.rgba(island.text.r, island.text.g, island.text.b, 0.06)
        Behavior on color        { ColorAnimation { duration: 520; easing.type: Easing.InOutCubic } }
        Behavior on border.color { ColorAnimation { duration: 520; easing.type: Easing.InOutCubic } }
    }

    Row {
        id: bubbleRow
        anchors.centerIn: parent
        spacing: island.s(6)

        Rectangle {
            width: root.bubbleH - island.s(12)
            height: root.bubbleH - island.s(12)
            radius: island.s(5)
            clip: true
            color: island.surface0
            anchors.verticalCenter: parent.verticalCenter

            Image {
                anchors.fill: parent
                source: island.musicData.artUrl || ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        Item {
            id: cavaBubble
            width: island.s(28)
            height: root.bubbleH - island.s(16)
            anchors.verticalCenter: parent.verticalCenter

            Repeater {
                model: 6
                Rectangle {
                    property color barColor: index === 0 ? island.blue
                        : index === 1 ? island.mauve
                        : index === 2 ? island.pink
                        : index === 3 ? island.peach
                        : index === 4 ? island.pink
                        : island.blue
                    property real barVal: index === 0 ? island.cavaBar0
                        : index === 1 ? island.cavaBar1
                        : index === 2 ? island.cavaBar2
                        : index === 3 ? island.cavaBar3
                        : index === 4 ? island.cavaBar4
                        : island.cavaBar5
                    property real halfMax: cavaBubble.height / 2
                    property real halfH: island.musicData.status !== "Playing"
                        ? Math.max(1, halfMax * 0.10)
                        : Math.max(1, halfMax * barVal)

                    x: index * island.s(5)
                    width: island.s(3)
                    radius: island.s(1.5)
                    y: cavaBubble.height / 2 - halfH
                    height: halfH * 2
                    Behavior on height { NumberAnimation { duration: 60; easing.type: Easing.Linear } }
                    Behavior on y      { NumberAnimation { duration: 60; easing.type: Easing.Linear } }

                    opacity: island.musicData.status === "Playing" ? 1.0 : 0.35
                    Behavior on opacity { NumberAnimation { duration: 300 } }

                    color: barColor
                }
            }
        }
    }
}
