import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls
import QtCore
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: window

    Scaler {
        id: scaler
        currentWidth: Screen.width
    }
    
    function s(val) { 
        return scaler.s(val); 
    }

    MatugenColors { id: _theme }
    readonly property color base: _theme.base
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2
    readonly property color text: _theme.text
    readonly property color subtext0: _theme.subtext0
    readonly property color red: _theme.red
    readonly property color mauve: _theme.mauve
    readonly property color blue: _theme.blue

    property string pulseRate: "72"
    property string pulseIcon: "󰏤"
    property var pulseHistory: []

    // Fetch data from API
    Process {
        id: apiPoller
        running: true
        command: ["curl", "-s", "http://127.0.0.1:7334/pulse"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text.trim());
                    window.pulseRate = data.rate;
                    window.pulseIcon = data.icon;
                    window.pulseHistory = data.history || [];
                } catch(e) {}
                apiWaiter.running = true;
            }
        }
    }

    Process {
        id: apiWaiter
        command: ["bash", "-c", "inotifywait -qq -t 30 -e close_write,moved_to /tmp/qs_pulse_update 2>/dev/null; sleep 0.1"]
        onExited: apiPoller.running = true
    }

    // Introductory animation
    property real intro: 0
    NumberAnimation {
        target: window
        property: "intro"
        from: 0; to: 1.0
        duration: 500
        easing.type: Easing.OutQuart
        running: true
    }

    Rectangle {
        anchors.fill: parent
        radius: window.s(20)
        color: window.base
        border.color: window.surface1 
        border.width: 1
        opacity: window.intro
        scale: 0.95 + (0.05 * window.intro)
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: window.s(25)
            spacing: window.s(15)

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: window.s(15)

                Rectangle {
                    width: window.s(64); height: window.s(64)
                    radius: window.s(16)
                    color: window.surface0
                    
                    Text {
                        anchors.centerIn: parent
                        text: window.pulseIcon
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: window.s(36)
                        color: window.red
                        
                        SequentialAnimation on scale {
                            loops: Animation.Infinite
                            NumberAnimation { to: 1.15; duration: 400; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0; duration: 400; easing.type: Easing.InOutSine }
                        }
                    }
                }

                ColumnLayout {
                    spacing: 0
                    Text {
                        text: "Heart Rate"
                        font.family: "JetBrains Mono"
                        font.pixelSize: window.s(20)
                        font.weight: Font.Bold
                        color: window.text
                    }
                    Text {
                        text: "REST API Backend Active"
                        font.family: "JetBrains Mono"
                        font.pixelSize: window.s(12)
                        color: window.subtext0
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                Text {
                    text: window.pulseRate
                    font.family: "JetBrains Mono"
                    font.pixelSize: window.s(32)
                    font.weight: Font.Black
                    color: window.text
                }
                Text {
                    text: "BPM"
                    font.family: "JetBrains Mono"
                    font.pixelSize: window.s(14)
                    font.weight: Font.Bold
                    color: window.subtext0
                    Layout.alignment: Qt.AlignBottom
                    Layout.bottomMargin: window.s(6)
                }
            }

            // Simple Graph Visualization
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: window.surface0
                radius: window.s(16)
                border.color: window.surface1
                border.width: 1
                clip: true

                Row {
                    anchors.fill: parent
                    anchors.margins: window.s(15)
                    anchors.bottomMargins: window.s(25)
                    spacing: window.s(4)
                    
                    Repeater {
                        model: 20
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: (parent.width - (19 * window.s(4))) / 20
                            height: {
                                if (index < window.pulseHistory.length) {
                                    let val = parseInt(window.pulseHistory[index].rate) || 60;
                                    // Scale 60-120 BPM to 10%-90% height
                                    return Math.max(parent.height * 0.1, 
                                           Math.min(parent.height * 0.9, 
                                           (val - 50) / 70 * parent.height));
                                }
                                return parent.height * 0.05;
                            }
                            radius: window.s(4)
                            color: index === window.pulseHistory.length - 1 ? window.red : window.mauve
                            opacity: index < window.pulseHistory.length ? 0.8 : 0.2
                            
                            Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
                        }
                    }
                }
                
                Text {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: window.s(6)
                    text: "Real-time History (Last 20 readings)"
                    font.family: "JetBrains Mono"
                    font.pixelSize: window.s(10)
                    color: window.subtext0
                }
            }

            // Footer
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: window.s(40)
                color: "transparent"
                
                RowLayout {
                    anchors.fill: parent
                    Text {
                        text: "Endpoint: http://127.0.0.1:7334/pulse"
                        font.family: "JetBrains Mono"
                        font.pixelSize: window.s(11)
                        color: window.subtext0
                        Layout.fillWidth: true
                    }
                    
                    Rectangle {
                        width: window.s(80); height: window.s(24)
                        radius: window.s(6)
                        color: window.surface1
                        Text {
                            anchors.centerIn: parent
                            text: "REFRESH"
                            font.family: "JetBrains Mono"
                            font.pixelSize: window.s(10)
                            font.weight: Font.Bold
                            color: window.text
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: apiPoller.running = true
                        }
                    }
                }
            }
        }
    }
}
