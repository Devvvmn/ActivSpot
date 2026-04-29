import QtQuick
import "../../plugins"

Item {
    id: root

    property var    bar
    property bool   editMode:       false
    property var    pluginManifest: null
    property string pluginDir:      ""
    property string _pluginId:      ""   // set by BarZone; used for retry on late plugin scan

    implicitWidth:  _widget.item ? _widget.item.implicitWidth  : (bar ? bar.barHeight : 32)
    implicitHeight: _widget.item ? _widget.item.implicitHeight : (bar ? bar.barHeight : 32)

    PluginApiShim {
        id: _api
        pluginDir: root.pluginDir
        manifest:  root.pluginManifest ?? ({})
    }

    // When PluginLoader finishes scanning (e.g. at startup), retry manifest injection.
    Connections {
        target: PluginLoader
        enabled: root.pluginManifest === null && root._pluginId !== ""
        function onPluginsChanged() {
            let plugin = PluginLoader.findPlugin(root._pluginId)
            if (plugin) {
                root.pluginManifest = plugin
                root.pluginDir      = plugin.pluginDir
            }
        }
    }

    // Stash widgetEntry so _main.onLoaded can activate it after mainInstance is ready.
    property string _pendingWidgetEntry: ""

    // Main.qml loads first. _widget activates in onLoaded so mainInstance is
    // always non-null when BarWidget.qml evaluates its bindings.
    Loader {
        id: _main
        active: false
        onStatusChanged: {
            if (status === Loader.Error)
                console.warn("[PluginApplet] Main.qml error:", root.pluginManifest?.id)
        }
        onLoaded: {
            _api.mainInstance = item
            if (root._pendingWidgetEntry) {
                _widget.setSource("file://" + root.pluginDir + "/" + root._pendingWidgetEntry,
                                  { "pluginApi": _api, "screen": root.bar ? root.bar.screen : null })
                _widget.active = true
            }
        }
    }

    // BarWidget.qml — activated after Main.qml is ready (or immediately if no main).
    Loader {
        id: _widget
        anchors.centerIn: parent
        active: false
        onStatusChanged: {
            if (status === Loader.Error)
                console.warn("[PluginApplet] BarWidget.qml error:", root.pluginManifest?.id)
        }
    }

    onPluginManifestChanged: _activate()
    onPluginDirChanged:      _activate()

    function _activate() {
        if (!pluginManifest || !pluginDir) return

        let mainEntry   = pluginManifest.entryPoints?.main     ?? ""
        let widgetEntry = pluginManifest.entryPoints?.barWidget ?? ""

        if (mainEntry) {
            root._pendingWidgetEntry = widgetEntry
            _main.setSource("file://" + pluginDir + "/" + mainEntry,
                            { "pluginApi": _api })
            _main.active = true
        } else if (widgetEntry) {
            _widget.setSource("file://" + pluginDir + "/" + widgetEntry,
                              { "pluginApi": _api, "screen": root.bar ? root.bar.screen : null })
            _widget.active = true
        }
    }

    // Error fallback: red ! when BarWidget explicitly failed to load
    Rectangle {
        anchors.centerIn: parent
        visible: _widget.status === Loader.Error
        width:  bar ? (bar.barHeight - bar.s(10)) : 22
        height: width
        radius: width / 2
        color:  Qt.rgba(1, 0.3, 0.3, 0.4)
        Text {
            anchors.centerIn: parent
            text: "!"
            font.family: "JetBrains Mono"
            font.pixelSize: parent.width * 0.5
            font.weight: Font.Bold
            color: "white"
        }
    }

    // No-widget fallback: puzzle icon for background-only plugins (no barWidget)
    Rectangle {
        anchors.centerIn: parent
        readonly property bool _noWidget: pluginManifest !== null && !pluginManifest?.entryPoints?.barWidget
        visible: _noWidget && _widget.status !== Loader.Error
        width:  bar ? (bar.barHeight - bar.s(8)) : 24
        height: width
        radius: width / 2
        color:  Qt.rgba(0.55, 0.48, 0.82, 0.18)
        Text {
            anchors.centerIn: parent
            text: "󰐱"
            font.family: "Iosevka Nerd Font"
            font.pixelSize: parent.width * 0.52
            color: Qt.rgba(0.73, 0.64, 0.96, 0.80)
        }
    }
}
