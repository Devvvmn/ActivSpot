import QtQuick
import QtQuick.Effects

// Fake glass — QML-based blurred refraction without compositor plugin.
//
// Usage:
//   1. Place a single ScreencopyView at the window root (anchors.fill: parent,
//      opacity: 0, layer.enabled: true) and expose it as `screencopySource`
//      on the bar/window root.
//   2. Drop FakeGlassSurface inside any rounded area; it will sample the
//      screen rect under itself, blur it, mask to `radius`, and overlay tint.
//
// Why opacity: 0 + layer.enabled: true on the ScreencopyView:
//   `visible: false` skips render (FBO empty); `opacity: 0` alone makes
//   ShaderEffectSource read transparent pixels. layer.enabled forces an
//   offscreen FBO so the source has real pixel data.

Item {
    id: glass
    clip: true

    property var  source                 // the ScreencopyView item
    property var  bar                    // for tint colors
    property real radius:    16
    property real tintAlpha: 0.10
    property real blurAmount: 1.0        // 0..1 → MultiEffect.blur
    property real blurMax:    64
    property real edgeAlpha:  0.35

    // sub-rect of source to sample = our position mapped into the source item
    readonly property rect srcRect: {
        if (!source) return Qt.rect(0, 0, 1, 1)
        let p = glass.mapToItem(source, 0, 0)
        return Qt.rect(p.x, p.y, glass.width, glass.height)
    }

    ShaderEffectSource {
        id: shot
        anchors.fill: parent
        sourceItem: glass.source
        sourceRect: glass.srcRect
        live: true
        smooth: true
        hideSource: false
        visible: false
        layer.enabled: true
    }

    MultiEffect {
        id: blurred
        anchors.fill: parent
        source: shot
        blurEnabled: true
        blur: glass.blurAmount
        blurMax: glass.blurMax
        blurMultiplier: 1.0
        saturation: 0.15
        brightness: 0.04
        visible: false
        layer.enabled: true
    }

    // Rounded mask
    Item {
        id: maskItem
        anchors.fill: parent
        visible: false
        layer.enabled: true
        Rectangle {
            anchors.fill: parent
            radius: glass.radius
            color: "white"
        }
    }

    MultiEffect {
        anchors.fill: parent
        source: blurred
        maskEnabled: true
        maskSource: maskItem
        maskThresholdMin: 0.5
    }

    // Tint + edge highlight
    Rectangle {
        anchors.fill: parent
        radius: glass.radius
        color: glass.bar
            ? Qt.rgba(glass.bar.mauve.r, glass.bar.mauve.g, glass.bar.mauve.b, glass.tintAlpha)
            : Qt.rgba(0.79, 0.65, 0.97, glass.tintAlpha)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, glass.edgeAlpha)

        // Inner top-rim highlight
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: parent.height * 0.5
            radius: glass.radius
            color:  "transparent"
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.12) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }
}
