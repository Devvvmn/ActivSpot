import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import "../"
import "../themes"

// Addon install confirmation — opened via 'plugininstall:<path>' IPC
// (a .qsplugin dropped on the island). Shows the manifest like a permissions
// screen; nothing is touched until the user presses Install.
Item {
    id: root

    property string widgetArg: ""   // absolute path to the .qsplugin file

    Scaler { id: scaler; currentWidth: Screen.width }
    function s(v) { return scaler.s(v) }

    // loading | ready | installing | done | error
    property string phase: "loading"
    property var    manifest: ({})
    property string resultText: ""

    function closePopup() {
        Quickshell.execDetached(["bash", "-c", "echo close > /tmp/qs_widget_state"])
    }

    Process {
        id: inspectProc
        running: true
        command: ["bash", "-c",
            "~/.config/hypr/scripts/plugin_install.sh inspect \"$1\" 2>&1", "qs", root.widgetArg]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim()
                try {
                    root.manifest = JSON.parse(t)
                    root.phase = "ready"
                } catch (e) {
                    root.resultText = t !== "" ? t : "could not read package"
                    root.phase = "error"
                }
            }
        }
    }

    Process {
        id: installProc
        command: ["bash", "-c",
            "~/.config/hypr/scripts/plugin_install.sh install \"$1\" 2>&1", "qs", root.widgetArg]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim()
                if (t.indexOf("installed:") !== -1) {
                    root.resultText = qsTr("Installed ✓")
                    root.phase = "done"
                } else {
                    root.resultText = t
                    root.phase = "error"
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.s(24)
        color: Theme.base
        border.color: Qt.rgba(1, 1, 1, 0.10)
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: root.s(28)
            spacing: root.s(14)

            // ── Header ────────────────────────────────────────────────────
            Row {
                spacing: root.s(12)
                Text {
                    text: "󰏗"
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: root.s(26)
                    color: Theme.accent
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: qsTr("Install add-on")
                    font.family: "JetBrains Mono"
                    font.pixelSize: root.s(20)
                    font.bold: true
                    color: Theme.text
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Rectangle { width: parent.width; height: 1; color: Qt.rgba(1,1,1,0.08) }

            // ── Loading / error ───────────────────────────────────────────
            Text {
                visible: root.phase === "loading"
                text: qsTr("Reading package…")
                font.family: "JetBrains Mono"; font.pixelSize: root.s(13)
                color: Theme.subtext0
            }

            // ── Manifest info ─────────────────────────────────────────────
            Column {
                visible: root.phase === "ready" || root.phase === "installing" || root.phase === "done"
                width: parent.width
                spacing: root.s(10)

                Row {
                    width: parent.width
                    Text {
                        text: root.manifest.name || root.manifest.id || ""
                        font.family: "JetBrains Mono"; font.pixelSize: root.s(17)
                        font.bold: true
                        color: Theme.text
                        elide: Text.ElideRight
                        width: parent.width - verLabel.width
                    }
                    Text {
                        id: verLabel
                        text: root.manifest.version ? "v" + root.manifest.version : ""
                        font.family: "JetBrains Mono"; font.pixelSize: root.s(13)
                        color: Theme.subtext0
                    }
                }

                Text {
                    visible: (root.manifest.description || "") !== ""
                    text: root.manifest.description || ""
                    width: parent.width
                    wrapMode: Text.WordWrap
                    font.family: "JetBrains Mono"; font.pixelSize: root.s(12)
                    color: Theme.subtext0
                }

                Item { width: 1; height: root.s(4) }

                Text {
                    text: qsTr("This add-on will install:")
                    font.family: "JetBrains Mono"; font.pixelSize: root.s(13)
                    color: Theme.text
                }

                // Permission-style rows
                Column {
                    width: parent.width
                    spacing: root.s(6)

                    Repeater {
                        model: {
                            const m = root.manifest
                            const rows = []
                            rows.push({ icon: "󰈔", warn: false,
                                text: (m._files || 0) + qsTr(" files (") + (m._sizeKb || 0) + qsTr(" KB) → plugins/") + (m.id || "") })
                            if (m._hasHypr)
                                rows.push({ icon: "󰣇", warn: true,
                                    text: qsTr("Hyprland config snippet (keybinds / rules / autostart)") })
                            if ((m._scriptCount || 0) > 0)
                                rows.push({ icon: "󰆍", warn: true,
                                    text: m._scriptCount + qsTr(" shell script(s)") })
                            if (m._hasHooks)
                                rows.push({ icon: "󱐋", warn: true,
                                    text: qsTr("install hook — runs code on install") })
                            if (m._installed)
                                rows.push({ icon: "󰚰", warn: false,
                                    text: qsTr("already installed — will be replaced") })
                            return rows
                        }
                        delegate: Row {
                            required property var modelData
                            spacing: root.s(10)
                            Text {
                                text: modelData.icon
                                font.family: "Iosevka Nerd Font"; font.pixelSize: root.s(14)
                                color: modelData.warn ? Theme.warning : Theme.accent
                            }
                            Text {
                                text: modelData.text
                                font.family: "JetBrains Mono"; font.pixelSize: root.s(12)
                                color: modelData.warn ? Theme.warning : Theme.subtext0
                            }
                        }
                    }
                }
            }

            // ── Result line ───────────────────────────────────────────────
            Text {
                visible: root.resultText !== ""
                text: root.resultText
                width: parent.width
                wrapMode: Text.WordWrap
                font.family: "JetBrains Mono"; font.pixelSize: root.s(12)
                color: root.phase === "done" ? Theme.positive : Theme.danger
            }
        }

        // ── Buttons ───────────────────────────────────────────────────────
        Row {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: root.s(28)
            spacing: root.s(12)

            Rectangle {
                width: root.s(120); height: root.s(38); radius: root.s(10)
                color: cancelMa.containsMouse ? Theme.surface1 : Theme.surface0
                border.color: Qt.rgba(1,1,1,0.10); border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: root.phase === "done" ? qsTr("Close") : qsTr("Cancel")
                    font.family: "JetBrains Mono"; font.pixelSize: root.s(13)
                    color: Theme.text
                }
                MouseArea {
                    id: cancelMa; anchors.fill: parent
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: root.closePopup()
                }
            }

            Rectangle {
                visible: root.phase === "ready" || root.phase === "installing"
                width: root.s(140); height: root.s(38); radius: root.s(10)
                color: installMa.containsMouse ? Qt.lighter(Theme.accent, 1.15) : Theme.accent
                opacity: root.phase === "installing" ? 0.6 : 1.0
                Text {
                    anchors.centerIn: parent
                    text: root.phase === "installing" ? qsTr("Installing…") : qsTr("Install")
                    font.family: "JetBrains Mono"; font.pixelSize: root.s(13)
                    font.bold: true
                    color: Theme.base
                }
                MouseArea {
                    id: installMa; anchors.fill: parent
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    enabled: root.phase === "ready"
                    onClicked: {
                        root.phase = "installing"
                        installProc.running = false
                        installProc.running = true
                    }
                }
            }
        }
    }
}
