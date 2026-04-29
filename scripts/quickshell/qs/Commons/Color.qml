pragma Singleton
import QtQuick
import Quickshell
import "../../themes"

// ActivSpot compat shim for qs.Commons Color.
// Maps Noctalia Material Design 3 color tokens to the active Theme palette.
Singleton {
    id: root

    // Theme transition flag (plugins use this to skip their own animations)
    readonly property bool isTransitioning: false

    // ── Material Design 3 tokens mapped to Theme palette ──────────────────
    readonly property color mPrimary:            Theme.mauve
    readonly property color mOnPrimary:          Theme.crust
    readonly property color mPrimaryContainer:   Qt.rgba(Theme.mauve.r, Theme.mauve.g, Theme.mauve.b, 0.25)
    readonly property color mOnPrimaryContainer: Theme.text

    readonly property color mSecondary:            Theme.blue
    readonly property color mOnSecondary:          Theme.crust
    readonly property color mSecondaryContainer:   Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.20)
    readonly property color mOnSecondaryContainer: Theme.text

    readonly property color mTertiary:            Theme.teal
    readonly property color mOnTertiary:          Theme.crust
    readonly property color mTertiaryContainer:   Qt.rgba(Theme.teal.r, Theme.teal.g, Theme.teal.b, 0.20)
    readonly property color mOnTertiaryContainer: Theme.text

    readonly property color mError:            Theme.red
    readonly property color mOnError:          Theme.crust
    readonly property color mErrorContainer:   Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.20)
    readonly property color mOnErrorContainer: Theme.text

    readonly property color mBackground:   Theme.base
    readonly property color mOnBackground: Theme.text

    readonly property color mSurface:          Theme.base
    readonly property color mOnSurface:        Theme.text
    readonly property color mSurfaceVariant:   Theme.surface0
    readonly property color mOnSurfaceVariant: Theme.subtext0

    readonly property color mOutline:        Theme.overlay0
    readonly property color mOutlineVariant: Theme.surface2

    readonly property color mSurfaceContainer:      Theme.surface0
    readonly property color mSurfaceContainerLow:   Theme.mantle
    readonly property color mSurfaceContainerHigh:  Theme.surface1
    readonly property color mSurfaceContainerHighest: Theme.surface2

    readonly property color mInverseSurface:   Theme.text
    readonly property color mInverseOnSurface: Theme.base
    readonly property color mInversePrimary:   Theme.base

    // Hover / active state overlays
    readonly property color mHover:   Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.10)
    readonly property color mOnHover: Theme.text
    readonly property color mRipple:  Qt.rgba(Theme.mauve.r, Theme.mauve.g, Theme.mauve.b, 0.20)

    // ── Helper functions ──────────────────────────────────────────────────

    // Apply subtle background alpha (used for capsule backgrounds)
    function smartAlpha(col) {
        return Qt.rgba(col.r, col.g, col.b, 0.85)
    }

    // Resolve a named color key to a color value.
    // Noctalia uses string keys like "primary", "error", "none", "transparent".
    function resolveColorKey(key) {
        switch (key) {
            case "primary":   return mPrimary
            case "secondary": return mSecondary
            case "tertiary":  return mTertiary
            case "error":     return mError
            case "surface":   return mSurface
            case "outline":   return mOutline
            case "none":      return mOnSurface
            case "transparent": return "transparent"
            default:          return mOnSurface
        }
    }

    // Pass-through (Noctalia adjusts opacity based on settings; we ignore that)
    function adaptiveOpacity(val) { return val }
}
