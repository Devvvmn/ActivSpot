import QtQuick
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

// Status bar button for the clipboard plugin.
// One instance is created per screen that has a bar.
//
// Clicking toggles the plugin's Panel. Right-clicking shows a small context
// menu (toggle / open settings) mirroring the clipper reference plugin
// (noctalia-dev/noctalia-plugins#clipper).
//
// Contracts followed:
//   - docs/specs/plugin-entry-point-contracts.md (NIconButton root, injected
//     props, togglePanel/closePanel usage).
//   - docs/specs/plugin-qml-idioms.md (null-guard pluginApi, translations via
//     pluginApi?.tr, capsule style tokens from qs.Commons).
NIconButton {
    id: root

    // --- Shell-injected properties ------------------------------------------
    // Always null-guard every pluginApi access with optional chaining (?.).
    property var pluginApi: null
    // ShellScreen is a Quickshell type. The entry-point contract
    // (docs/specs/plugin-entry-point-contracts.md, BarWidget section) names
    // `property ShellScreen screen` as the canonical declaration; the
    // noctalia-plugins AGENTS.md audit treats a missing typed declaration as
    // a merge blocker. The `import Quickshell` above makes the type visible
    // to the shell's QML engine (qmllint can't resolve shell-internal
    // modules in isolation — that's a tooling limitation, not a contract
    // concern).
    property ShellScreen screen
    // Identity / layout metadata — injected by the shell after instantiation.
    // They participate in BarService layout calculations; we surface them as
    // explicit properties so the shell can write to them.
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    // --- NIconButton styling ------------------------------------------------

    icon: "clipboard-data"
    // No `?? ""` fallback on tr() — the translation system returns the key
    // itself on a miss, which is the correct fallback per the upstream
    // AGENTS.md (noctalia-dev/noctalia-plugins). Adding `?? ""` silently
    // swallows misses and hides broken keys from translators.
    tooltipText: pluginApi?.tr("bar.tooltip")
    tooltipDirection: BarService.getTooltipDirection(screen?.name)
    baseSize: Style.getCapsuleHeightForScreen(screen?.name)
    // The bar renders at its own scale; we opt out of the extra UI scale so
    // the capsule heights line up with neighboring bar widgets.
    applyUiScale: false
    customRadius: Style.radiusL

    colorBg: Style.capsuleColor
    colorFg: Color.mOnSurface
    colorBgHover: Color.mHover
    colorFgHover: Color.mOnHover
    colorBorder: "transparent"
    colorBorderHover: "transparent"
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    // --- Interaction --------------------------------------------------------

    // Left-click: open the plugin panel anchored to this bar widget.
    //
    // The second argument — the `caller` — is what the shell's SmartPanel
    // wrapper uses to anchor the panel geometrically. Without it the panel
    // falls back to centered positioning (issue #16). The canonical pattern
    // (per docs/specs/plugin-entry-point-contracts.md and the clipper
    // reference plugin) is `pluginApi.openPanel(screen, this)`; using `root`
    // here is equivalent to `this` since `root` is the root `NIconButton`
    // item id.
    //
    // To recover the "click again to close" behavior that togglePanel gave
    // us, we check `pluginApi.isPanelOpen(screen)` first and route to
    // `closePanel` when the panel is already open on this screen. When the
    // API lacks `isPanelOpen` (older shells), we fall back to calling
    // `openPanel` unconditionally — the shell's own deduplication handles
    // the repeated-open case.
    onClicked: {
        if (!pluginApi) return;
        const alreadyOpen = pluginApi.isPanelOpen?.(screen) === true;
        if (alreadyOpen && pluginApi.closePanel) {
            pluginApi.closePanel(screen);
        } else if (pluginApi.openPanel) {
            pluginApi.openPanel(screen, root);
        }
    }

    // Right-click: show a lightweight context menu. The menu itself is a
    // child NPopupContextMenu; PanelService handles the visual attachment
    // (the same service also closes the menu when another panel opens).
    onRightClicked: {
        PanelService.showContextMenu(contextMenu, root, screen);
    }

    // --- Context menu -------------------------------------------------------

    NPopupContextMenu {
        id: contextMenu

        model: [
            {
                "label": pluginApi?.tr("context.toggle"),
                "action": "toggle",
                "icon": "clipboard-data"
            },
            {
                "label": pluginApi?.tr("context.settings"),
                "action": "open-settings",
                "icon": "settings"
            }
        ]

        onTriggered: action => {
            contextMenu.close();
            PanelService.closeContextMenu(screen);

            if (action === "toggle") {
                // Same anchoring concern as the left-click handler above:
                // always pass `root` as the caller so the panel attaches to
                // this bar widget rather than drifting to screen center.
                if (!pluginApi) return;
                const alreadyOpen = pluginApi.isPanelOpen?.(screen) === true;
                if (alreadyOpen && pluginApi.closePanel) {
                    pluginApi.closePanel(screen);
                } else if (pluginApi.openPanel) {
                    pluginApi.openPanel(screen, root);
                }
            } else if (action === "open-settings") {
                if (pluginApi?.manifest) {
                    BarService.openPluginSettings(screen, pluginApi.manifest);
                }
            }
        }
    }
}
