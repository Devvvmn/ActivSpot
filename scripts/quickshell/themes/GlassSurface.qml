import QtQuick

// Glassmorphism surface — visual effects handled by HyprGlass compositor plugin.
// This item just provides a transparent background so HyprGlass detects the region
// and applies blur/refraction/aberration at the compositor level.

Item {
    id: glass
    clip: true

    property var  bar
    property real radius:    bar ? bar.s(16) : 16
    property real tintAlpha: 0.06

    // Rounded tint + border — HyprGlass handles blur/refraction behind this
    Rectangle {
        anchors.fill: parent
        radius:       glass.radius
        color: glass.bar
            ? Qt.rgba(glass.bar.mauve.r, glass.bar.mauve.g, glass.bar.mauve.b, glass.tintAlpha)
            : Qt.rgba(0.79, 0.65, 0.97, glass.tintAlpha)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.25)

        // Inner top-rim highlight
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: parent.height * 0.45
            radius: glass.radius
            color:  "transparent"
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.09) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }
}
