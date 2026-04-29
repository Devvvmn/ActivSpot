import QtQuick
import qs.Commons

// Compat NText: styled text matching ActivSpot's JetBrains Mono typography.
Text {
    property real pointSize:    Style.fontSizeM
    property bool applyUiScale: true

    font.family: "JetBrains Mono"
    font.pointSize: pointSize
    color: Color.mOnSurface
}
