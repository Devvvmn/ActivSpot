import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import "../"

ShellRoot {
    id: root

    PamContext {
        id: pam
        Component.onCompleted: pam.start()
        onCompleted: (result) => {
            lockUI.authenticating = false;
            if (result === PamResult.Success) {
                try { lockIcon.text = "󰍁"; lockIcon.color = "#4ade80"; lockIconPop.restart(); } catch(e) {}
                rootLock.locked = false;
                Qt.quit();
            } else {
                lockUI.failed = true;
                lockUI.statusText = "Incorrect password";
                pam.start();
            }
        }
    }

    Process { id: suspendProcess;  command: ["systemctl", "suspend"] }
    Process { id: poweroffProcess; command: ["systemctl", "poweroff"] }
    Process { id: reloadProcess;   command: ["systemctl", "reboot"] }

    QtObject {
        id: lockUI
        property bool failed: false
        property bool authenticating: false
        property string statusText: ""
        property bool showPassword: false
    }

    Settings {
        id: lockSettings
        category: "QuickshellLockscreen"
        property bool hidePassword: false
    }

    WlSessionLock {
        id: rootLock
        locked: true

        WlSessionLockSurface {
            Item {
                id: screenRoot
                anchors.fill: parent

                Scaler { id: scaler; currentWidth: screenRoot.width > 0 ? screenRoot.width : Screen.width }
                readonly property real sc: scaler.baseScale

                property string staticWallpaperPath: ""
                property string currentUser: "user"
                property string faceIconPath: ""
                property string kbLayout: "US"
                property string batPct: "100"
                property string batStatus: "Full"
                property string weatherIcon: ""
                property string weatherTemp: "--°"
                property bool isDesktop: false
                property bool powerMenuOpen: false
                property bool inputActive: false
                property real introOpacity: 0.0

                Component.onCompleted: introAnim.start()

                NumberAnimation {
                    id: introAnim
                    target: screenRoot; property: "introOpacity"
                    from: 0.0; to: 1.0
                    duration: 700; easing.type: Easing.OutCubic
                }

                // ── Data pollers ──────────────────────────────────────────────

                Process {
                    id: wallpaperPoller
                    running: true
                    command: ["cat", "/home/dxvmxn/.cache/wallpaper_picker/current"]
                    stdout: StdioCollector {
                        onStreamFinished: {
                            let p = this.text.trim();
                            if (p !== "")
                                screenRoot.staticWallpaperPath = p.startsWith("file://") ? p : "file://" + p;
                        }
                    }
                }

                Process {
                    id: chassisDetector
                    running: true
                    command: ["bash", "-c", "ls /sys/class/power_supply/BAT* 1>/dev/null 2>&1 && echo laptop || echo desktop"]
                    stdout: StdioCollector {
                        onStreamFinished: { screenRoot.isDesktop = (this.text.trim() === "desktop"); }
                    }
                }

                Process {
                    id: userPoller
                    command: ["bash", "-c",
                        "U=$(whoami); P=''; [ -f ~/.face.icon ] && P=$(readlink -f ~/.face.icon) || { [ -f ~/.face ] && P=$(readlink -f ~/.face); }; echo -n \"$U|$P\""]
                    stdout: StdioCollector {
                        onStreamFinished: {
                            let parts = this.text.trim().split("|");
                            if (parts[0] !== "") screenRoot.currentUser = parts[0];
                            if (parts.length > 1 && parts[1].trim() !== "") {
                                let path = parts[1].trim();
                                screenRoot.faceIconPath = path.startsWith("file://") ? path : "file://" + path;
                            }
                        }
                    }
                    Component.onCompleted: running = true
                }

                Process {
                    id: kbPoller
                    command: ["bash", "-c",
                        "hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .active_keymap' | head -n1 | cut -c1-2 | tr '[:lower:]' '[:upper:]'"]
                    stdout: StdioCollector {
                        onStreamFinished: {
                            let l = this.text.trim();
                            if (l !== "" && l !== "null") screenRoot.kbLayout = l;
                        }
                    }
                }
                Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: kbPoller.running = true }

                Process {
                    id: batPoller
                    running: !screenRoot.isDesktop
                    command: ["bash", "-c",
                        "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1 || echo 100; cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1 || echo AC"]
                    stdout: StdioCollector {
                        onStreamFinished: {
                            let lines = this.text.trim().split("\n");
                            if (lines.length >= 2) { screenRoot.batPct = lines[0]; screenRoot.batStatus = lines[1]; }
                        }
                    }
                }
                Timer { interval: 5000; running: !screenRoot.isDesktop; repeat: true; triggeredOnStart: true; onTriggered: batPoller.running = true }

                Process {
                    id: weatherPoller
                    property string scriptPath: Qt.resolvedUrl("calendar/weather.sh").toString().replace(/^file:\/\//, "")
                    command: ["bash", "-c", '"' + scriptPath + '" --current-icon; "' + scriptPath + '" --current-temp']
                    stdout: StdioCollector {
                        onStreamFinished: {
                            let lines = this.text.trim().split("\n");
                            if (lines.length >= 2) { screenRoot.weatherIcon = lines[0]; screenRoot.weatherTemp = lines[1]; }
                        }
                    }
                }
                Timer { interval: 900000; running: true; repeat: true; triggeredOnStart: true; onTriggered: weatherPoller.running = true }

                // ── Background ────────────────────────────────────────────────

                Rectangle {
                    anchors.fill: parent
                    color: "black"
                }

                Image {
                    id: bgWallpaper
                    anchors.fill: parent
                    source: screenRoot.staticWallpaperPath
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    visible: status === Image.Ready
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        blurEnabled: true
                        blurMax: 64
                        blur: 1.0
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, bgWallpaper.status === Image.Ready ? 0.38 : 0.72)
                    Behavior on color { ColorAnimation { duration: 600 } }
                }

                // ── Global click handler ──────────────────────────────────────

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (screenRoot.powerMenuOpen) { screenRoot.powerMenuOpen = false; return; }
                        if (!screenRoot.inputActive) screenRoot.inputActive = true;
                        inputField.forceActiveFocus();
                    }
                }

                // ── All UI fades in ───────────────────────────────────────────

                Item {
                    anchors.fill: parent
                    opacity: screenRoot.introOpacity

                    // ── Clock ─────────────────────────────────────────────────
                    Column {
                        id: clockBlock
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: parent.height * 0.13
                        spacing: screenRoot.sc * 6

                        opacity: screenRoot.inputActive ? 0.0 : 1.0
                        scale: screenRoot.inputActive ? 0.92 : 1.0
                        transformOrigin: Item.Top
                        Behavior on opacity { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
                        Behavior on scale   { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                        Text {
                            id: clockLabel
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatTime(new Date(), "hh:mm")
                            font.family: "Inter"
                            font.weight: Font.Thin
                            font.pixelSize: screenRoot.sc * 132
                            font.letterSpacing: screenRoot.sc * -2
                            color: "white"

                            property string _pending: ""

                            SequentialAnimation {
                                id: clockFlip
                                NumberAnimation { target: clockLabel; property: "opacity"; to: 0.0; duration: 180; easing.type: Easing.InQuad }
                                ScriptAction { script: clockLabel.text = clockLabel._pending }
                                NumberAnimation { target: clockLabel; property: "opacity"; to: 1.0; duration: 220; easing.type: Easing.OutCubic }
                            }
                        }

                        Text {
                            id: dateLabel
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDate(new Date(), "dddd, MMMM d")
                            font.family: "Inter"
                            font.weight: Font.Light
                            font.pixelSize: screenRoot.sc * 17
                            color: Qt.rgba(1, 1, 1, 0.55)
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Click to unlock"
                            font.family: "Inter"
                            font.weight: Font.Light
                            font.pixelSize: screenRoot.sc * 14
                            color: Qt.rgba(1, 1, 1, 0.38)
                            opacity: screenRoot.inputActive ? 0.0 : 1.0
                            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                        }

                        Timer {
                            interval: 1000; running: true; repeat: true
                            onTriggered: {
                                let t = Qt.formatTime(new Date(), "hh:mm");
                                if (t !== clockLabel.text) {
                                    clockLabel._pending = t;
                                    clockFlip.restart();
                                }
                                dateLabel.text = Qt.formatDate(new Date(), "dddd, MMMM d");
                            }
                        }
                    }

                    // ── Auth section ──────────────────────────────────────────

                    Item {
                        id: authWrapper
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: screenRoot.inputActive ? screenRoot.sc * -16 : screenRoot.sc * 64

                        width: authBlock.implicitWidth + screenRoot.sc * 52
                        height: authBlock.implicitHeight + screenRoot.sc * 52

                        opacity: screenRoot.inputActive ? 1.0 : 0.0
                        scale: screenRoot.inputActive ? 1.0 : 0.93
                        Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 500; easing.type: Easing.OutExpo } }
                        Behavior on opacity { NumberAnimation { duration: 340; easing.type: Easing.OutCubic } }
                        Behavior on scale   { NumberAnimation { duration: 420; easing.type: Easing.OutBack } }
                        Behavior on height  { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                        Rectangle {
                            anchors.fill: parent
                            radius: screenRoot.sc * 24
                            color: Qt.rgba(1, 1, 1, 0.07)
                            border.color: Qt.rgba(1, 1, 1, 0.11)
                            border.width: 1
                        }

                        Column {
                            id: authBlock
                            anchors.centerIn: parent
                            spacing: screenRoot.sc * 14

                            // Avatar
                            Item {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: screenRoot.sc * 88; height: width

                                Rectangle {
                                    anchors.fill: parent
                                    radius: height / 2
                                    color: Qt.rgba(1, 1, 1, 0.14)
                                    border.color: Qt.rgba(1, 1, 1, 0.25)
                                    border.width: 1
                                    visible: avatarImg.status !== Image.Ready
                                    Text {
                                        anchors.centerIn: parent
                                        text: screenRoot.currentUser.charAt(0).toUpperCase()
                                        font.family: "Inter"
                                        font.weight: Font.Light
                                        font.pixelSize: screenRoot.sc * 38
                                        color: "white"
                                    }
                                }

                                Image {
                                    id: avatarImg
                                    anchors.fill: parent
                                    source: screenRoot.faceIconPath
                                    fillMode: Image.PreserveAspectCrop
                                    visible: false
                                    cache: false
                                    asynchronous: true
                                }
                                Rectangle {
                                    id: avatarMask
                                    anchors.fill: parent
                                    radius: height / 2
                                    visible: false
                                    layer.enabled: true
                                }
                                MultiEffect {
                                    source: avatarImg
                                    anchors.fill: avatarImg
                                    maskEnabled: true
                                    maskSource: avatarMask
                                    visible: avatarImg.status === Image.Ready
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: height / 2
                                    color: "transparent"
                                    border.color: lockUI.failed
                                        ? "#f87171"
                                        : (lockUI.authenticating ? Qt.rgba(1,1,1,0.7) : Qt.rgba(1,1,1,0.28))
                                    border.width: lockUI.failed ? 2 : 1
                                    Behavior on border.color { ColorAnimation { duration: 250 } }
                                }
                            }

                            // Lock icon — turns green and opens on success
                            Text {
                                id: lockIcon
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "󰌾"
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: screenRoot.sc * 15
                                color: Qt.rgba(1, 1, 1, 0.45)
                                Behavior on color { ColorAnimation { duration: 250 } }

                                NumberAnimation {
                                    id: lockIconPop
                                    target: lockIcon; property: "scale"
                                    from: 1.0; to: 1.4
                                    duration: 320; easing.type: Easing.OutBack
                                }
                            }

                            // Username
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: screenRoot.currentUser
                                font.family: "Inter"
                                font.weight: Font.Medium
                                font.pixelSize: screenRoot.sc * 16
                                color: "white"
                            }

                            // Status text
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: lockUI.statusText
                                visible: lockUI.statusText !== ""
                                font.family: "Inter"
                                font.pixelSize: screenRoot.sc * 13
                                color: lockUI.failed ? "#f87171" : Qt.rgba(1, 1, 1, 0.5)
                                Behavior on color { ColorAnimation { duration: 220 } }
                            }

                            // Password pill + submit arrow
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: screenRoot.sc * 8

                                Rectangle {
                                    id: pillBg
                                    width: screenRoot.sc * 246
                                    height: screenRoot.sc * 40
                                    radius: height / 2
                                    color: lockUI.failed
                                        ? Qt.rgba(0.97, 0.44, 0.44, 0.20)
                                        : Qt.rgba(1, 1, 1, 0.16)
                                    border.color: lockUI.failed
                                        ? "#f87171"
                                        : (inputField.text.length > 0
                                            ? Qt.rgba(1, 1, 1, 0.55)
                                            : Qt.rgba(1, 1, 1, 0.22))
                                    border.width: 1
                                    clip: true
                                    Behavior on color        { ColorAnimation { duration: 220 } }
                                    Behavior on border.color { ColorAnimation { duration: 220 } }

                                    transform: Translate { id: shakeT; x: 0 }
                                    SequentialAnimation {
                                        id: shakeAnim
                                        NumberAnimation { target: shakeT; property: "x"; from: 0;   to: -8;  duration: 55 }
                                        NumberAnimation { target: shakeT; property: "x"; from: -8;  to: 8;   duration: 75 }
                                        NumberAnimation { target: shakeT; property: "x"; from: 8;   to: -5;  duration: 55 }
                                        NumberAnimation { target: shakeT; property: "x"; from: -5;  to: 5;   duration: 55 }
                                        NumberAnimation { target: shakeT; property: "x"; from: 5;   to: 0;   duration: 55 }
                                    }
                                    Connections {
                                        target: lockUI
                                        function onFailedChanged() { if (lockUI.failed) shakeAnim.restart(); }
                                    }

                                    // Placeholder
                                    Text {
                                        anchors {
                                            left: parent.left; leftMargin: screenRoot.sc * 18
                                            verticalCenter: parent.verticalCenter
                                        }
                                        text: "Enter Password"
                                        font.family: "Inter"
                                        font.pixelSize: screenRoot.sc * 14
                                        color: Qt.rgba(1, 1, 1, 0.28)
                                        visible: inputField.text.length === 0
                                    }

                                    TextInput {
                                        id: inputField
                                        anchors { fill: parent; leftMargin: screenRoot.sc * 18; rightMargin: screenRoot.sc * 46 }
                                        verticalAlignment: TextInput.AlignVCenter
                                        echoMode: lockUI.showPassword ? TextInput.Normal : TextInput.Password
                                        passwordCharacter: "●"
                                        color: "white"
                                        font.family: "Inter"
                                        font.pixelSize: screenRoot.sc * 15
                                        selectionColor: Qt.rgba(1, 1, 1, 0.3)
                                        cursorVisible: activeFocus && text.length === 0

                                        Component.onCompleted: forceActiveFocus()

                                        onActiveFocusChanged: {
                                            if (!activeFocus && !screenRoot.powerMenuOpen)
                                                forceActiveFocus();
                                        }

                                        Keys.onPressed: (event) => {
                                            if (!screenRoot.inputActive) screenRoot.inputActive = true;
                                            if (event.key === Qt.Key_Escape) {
                                                screenRoot.inputActive = false;
                                                text = "";
                                                lockUI.failed = false;
                                                lockUI.statusText = "";
                                                event.accepted = true;
                                            }
                                        }

                                        onAccepted: {
                                            if (text.length > 0 && pam.responseRequired && !lockUI.authenticating) {
                                                lockUI.authenticating = true;
                                                lockUI.statusText = "Verifying…";
                                                lockUI.failed = false;
                                                pam.respond(text);
                                                text = "";
                                            }
                                        }

                                        onTextChanged: {
                                            if (!screenRoot.inputActive && text.length > 0)
                                                screenRoot.inputActive = true;
                                            if (text.length > 0) {
                                                lockUI.failed = false;
                                                lockUI.statusText = "";
                                            }
                                            if (lockUI.authenticating) return;
                                        }
                                    }

                                    // Eye toggle — show/hide password
                                    Rectangle {
                                        anchors {
                                            right: parent.right; rightMargin: screenRoot.sc * 5
                                            verticalCenter: parent.verticalCenter
                                        }
                                        width: screenRoot.sc * 32; height: width
                                        radius: height / 2
                                        color: eyeMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                                        Behavior on color { ColorAnimation { duration: 120 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: lockUI.showPassword ? "󰈈" : "󰈉"
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: screenRoot.sc * 14
                                            color: Qt.rgba(1, 1, 1, 0.5)
                                        }

                                        MouseArea {
                                            id: eyeMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                lockUI.showPassword = !lockUI.showPassword;
                                                inputField.forceActiveFocus();
                                            }
                                        }
                                    }
                                }

                                // Submit arrow
                                Rectangle {
                                    width: screenRoot.sc * 40; height: screenRoot.sc * 40
                                    radius: height / 2
                                    color: arrowMa.pressed
                                        ? Qt.rgba(1, 1, 1, 0.38)
                                        : (arrowMa.containsMouse ? Qt.rgba(1, 1, 1, 0.24) : Qt.rgba(1, 1, 1, 0.14))
                                    border.color: Qt.rgba(1, 1, 1, 0.22)
                                    border.width: 1
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    scale: arrowMa.pressed ? 0.92 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: lockUI.authenticating ? "…" : "→"
                                        font.family: "Inter"
                                        font.weight: Font.Light
                                        font.pixelSize: screenRoot.sc * 18
                                        color: "white"
                                    }
                                    MouseArea {
                                        id: arrowMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: inputField.accepted()
                                    }
                                }
                            }
                        }
                    }

                    // ── Bottom system pills ───────────────────────────────────

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: screenRoot.sc * 36
                        spacing: screenRoot.sc * 10

                        // Keyboard layout
                        Rectangle {
                            height: screenRoot.sc * 30
                            width: kbRow.implicitWidth + screenRoot.sc * 26
                            radius: height / 2
                            color: Qt.rgba(1, 1, 1, 0.10)
                            border.color: Qt.rgba(1, 1, 1, 0.18)
                            border.width: 1
                            Row {
                                id: kbRow
                                anchors.centerIn: parent
                                spacing: screenRoot.sc * 6
                                Text {
                                    text: "󰌌"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: screenRoot.sc * 13
                                    color: Qt.rgba(1, 1, 1, 0.6)
                                    verticalAlignment: Text.AlignVCenter
                                }
                                Text {
                                    text: screenRoot.kbLayout
                                    font.family: "Inter"
                                    font.weight: Font.Medium
                                    font.pixelSize: screenRoot.sc * 12
                                    color: "white"
                                }
                            }
                        }

                        // Battery
                        Rectangle {
                            visible: !screenRoot.isDesktop
                            height: screenRoot.sc * 30
                            width: batRow.implicitWidth + screenRoot.sc * 26
                            radius: height / 2
                            color: Qt.rgba(1, 1, 1, 0.10)
                            border.color: Qt.rgba(1, 1, 1, 0.18)
                            border.width: 1
                            Row {
                                id: batRow
                                anchors.centerIn: parent
                                spacing: screenRoot.sc * 6
                                Text {
                                    text: screenRoot.batStatus === "Charging" ? "󰂄" : "󰁹"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: screenRoot.sc * 13
                                    color: Qt.rgba(1, 1, 1, 0.6)
                                }
                                Text {
                                    text: screenRoot.batPct + "%"
                                    font.family: "Inter"
                                    font.weight: Font.Medium
                                    font.pixelSize: screenRoot.sc * 12
                                    color: "white"
                                }
                            }
                        }

                        // Weather
                        Rectangle {
                            visible: screenRoot.weatherIcon !== ""
                            height: screenRoot.sc * 30
                            width: weatherRow.implicitWidth + screenRoot.sc * 26
                            radius: height / 2
                            color: Qt.rgba(1, 1, 1, 0.10)
                            border.color: Qt.rgba(1, 1, 1, 0.18)
                            border.width: 1
                            Row {
                                id: weatherRow
                                anchors.centerIn: parent
                                spacing: screenRoot.sc * 6
                                Text {
                                    text: screenRoot.weatherIcon
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: screenRoot.sc * 13
                                    color: "white"
                                }
                                Text {
                                    text: screenRoot.weatherTemp
                                    font.family: "Inter"
                                    font.weight: Font.Medium
                                    font.pixelSize: screenRoot.sc * 12
                                    color: "white"
                                }
                            }
                        }
                    }

                    // ── Power button (bottom right) ────────────────────────────

                    Rectangle {
                        id: powerBtn
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        anchors.margins: screenRoot.sc * 32
                        width: screenRoot.sc * 44; height: width
                        radius: height / 2
                        color: screenRoot.powerMenuOpen
                            ? Qt.rgba(1, 1, 1, 0.22)
                            : (powerBtnMa.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.09))
                        border.color: Qt.rgba(1, 1, 1, screenRoot.powerMenuOpen ? 0.32 : 0.18)
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 180 } }
                        scale: powerBtnMa.pressed ? 0.91 : 1.0
                        Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutBack } }

                        Text {
                            anchors.centerIn: parent
                            text: "⏻"
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: screenRoot.sc * 18
                            color: screenRoot.powerMenuOpen ? "#f87171" : "white"
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                        MouseArea {
                            id: powerBtnMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                screenRoot.powerMenuOpen = !screenRoot.powerMenuOpen;
                                if (!screenRoot.powerMenuOpen) inputField.forceActiveFocus();
                            }
                        }
                    }

                    // ── Power menu (above power button) ────────────────────────

                    Rectangle {
                        id: powerMenu
                        anchors.right: parent.right
                        anchors.bottom: powerBtn.top
                        anchors.rightMargin: screenRoot.sc * 32
                        anchors.bottomMargin: screenRoot.sc * 10
                        width: screenRoot.sc * 210
                        height: screenRoot.powerMenuOpen ? (pmCol.implicitHeight + screenRoot.sc * 14) : 0
                        radius: screenRoot.sc * 18
                        color: Qt.rgba(0.06, 0.06, 0.06, 0.90)
                        border.color: Qt.rgba(1, 1, 1, 0.10)
                        border.width: 1
                        clip: true
                        z: 50
                        Behavior on height  { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                        opacity: screenRoot.powerMenuOpen ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        Column {
                            id: pmCol
                            anchors.top: parent.top
                            anchors.topMargin: screenRoot.sc * 7
                            anchors.left: parent.left
                            anchors.right: parent.right
                            spacing: screenRoot.sc * 2

                            Repeater {
                                model: [
                                    { label: "Restart",   icon: "󰜉", clr: "#60a5fa" },
                                    { label: "Sleep",     icon: "󰒲", clr: "#c084fc" },
                                    { label: "Shut Down", icon: "󰐥", clr: "#f87171" }
                                ]
                                delegate: Rectangle {
                                    width: parent.width
                                    height: screenRoot.sc * 44
                                    color: pmMa.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 130 } }
                                    scale: pmMa.pressed ? 0.97 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 100 } }

                                    Row {
                                        anchors.fill: parent
                                        anchors.leftMargin: screenRoot.sc * 18
                                        spacing: screenRoot.sc * 12

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.icon
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: screenRoot.sc * 16
                                            color: modelData.clr
                                        }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.label
                                            font.family: "Inter"
                                            font.weight: Font.Medium
                                            font.pixelSize: screenRoot.sc * 14
                                            color: "white"
                                        }
                                    }

                                    MouseArea {
                                        id: pmMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            screenRoot.powerMenuOpen = false;
                                            if      (modelData.label === "Restart")   reloadProcess.running   = true;
                                            else if (modelData.label === "Sleep")     suspendProcess.running  = true;
                                            else                                      poweroffProcess.running = true;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
