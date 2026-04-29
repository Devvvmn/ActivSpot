pragma Singleton
import QtQuick
import Quickshell
import "../../themes"

// ActivSpot compat shim for qs.Commons Style.
// Maps Noctalia Style API to reasonable values for ActivSpot's visual style.
Singleton {
    id: root

    // Font sizes (pt)
    readonly property real fontSizeXXS:  8
    readonly property real fontSizeXS:   9
    readonly property real fontSizeS:    10
    readonly property real fontSizeM:    11
    readonly property real fontSizeL:    13
    readonly property real fontSizeXL:   16
    readonly property real fontSizeXXL:  18
    readonly property real fontSizeXXXL: 24

    // Font weights
    readonly property int fontWeightRegular:  400
    readonly property int fontWeightMedium:   500
    readonly property int fontWeightSemiBold: 600
    readonly property int fontWeightBold:     700

    // Container radii
    readonly property int radiusXXXS: 3
    readonly property int radiusXXS:  4
    readonly property int radiusXS:   8
    readonly property int radiusS:    12
    readonly property int radiusM:    16
    readonly property int radiusL:    20

    // Input radii
    readonly property int iRadiusXXXS: 3
    readonly property int iRadiusXXS:  4
    readonly property int iRadiusXS:   8
    readonly property int iRadiusS:    12
    readonly property int iRadiusM:    16
    readonly property int iRadiusL:    20

    readonly property int screenRadius: 20

    // Borders
    readonly property int borderS: 1
    readonly property int borderM: 2
    readonly property int borderL: 3

    // Margins
    readonly property int marginXXXS: 1
    readonly property int marginXXS:  2
    readonly property int marginXS:   4
    readonly property int marginS:    6
    readonly property int marginM:    9
    readonly property int marginL:    13
    readonly property int marginXL:   18

    readonly property int margin2XXXS: 2
    readonly property int margin2XXS:  4
    readonly property int margin2XS:   8
    readonly property int margin2S:    12
    readonly property int margin2M:    18
    readonly property int margin2L:    26
    readonly property int margin2XL:   36

    // Opacity
    readonly property real opacityNone:   0.0
    readonly property real opacityLight:  0.25
    readonly property real opacityMedium: 0.5
    readonly property real opacityHeavy:  0.75
    readonly property real opacityAlmost: 0.95
    readonly property real opacityFull:   1.0

    // Animations (ms)
    readonly property int animationFastest: 75
    readonly property int animationFast:    150
    readonly property int animationNormal:  200
    readonly property int animationMedium:  250
    readonly property int animationSlow:    400
    readonly property int animationSlowest: 600

    // Scale ratio (no per-monitor scaling in ActivSpot compat layer)
    readonly property real uiScaleRatio: 1.0

    // Widget size for bar icons
    readonly property real baseWidgetSize: 32

    function getCapsuleHeightForScreen(screenName) { return 32 }
    function getBarFontSizeForScreen(screenName)   { return fontSizeS }

    // Round to nearest odd integer (for pixel-perfect icon centering)
    function toOdd(n) {
        let r = Math.round(n)
        return (r % 2 === 0) ? r + 1 : r
    }

    // Center child of size `inner` inside parent of size `outer`
    function pixelAlignCenter(outer, inner) {
        return Math.floor((outer - inner) / 2)
    }

    // ── Bar capsule style (used by Noctalia BarWidget plugins) ───────────
    // These mirror Noctalia's bar appearance settings with ActivSpot-sensible defaults.
    readonly property real  capsuleHeight:      32
    readonly property color capsuleColor:       Qt.rgba(Theme.surface0.r, Theme.surface0.g, Theme.surface0.b, 0.85)
    readonly property color capsuleBorderColor: "transparent"
    readonly property int   capsuleBorderWidth: 0
}
