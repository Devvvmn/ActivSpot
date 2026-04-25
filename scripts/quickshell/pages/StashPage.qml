import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io

Item {
    id: root
    width: parent ? parent.width : 0
    height: parent ? parent.height : 0
    property var island

    // ── Compression state ─────────────────────────────────────────────────────
    property bool   isCompressingMode:    false
    property string activeCompressFile:   ""
    property string activeCompressOutPath: ""
    property string activeCompressName:   ""
    property string activeCompressType:   ""
    property string activeCompressSize:   ""
    property string compressedFileSize:   ""
    property real   compressProgress:     0.0
    property bool   compressFinished:     false

    property int modelCount: island && island.stashModel ? island.stashModel.count : 0
    onModelCountChanged:      updateHeight()
    onIsCompressingModeChanged: updateHeight()
    onIslandChanged:          updateHeight()

    function updateHeight() {
        if (!island) return
        if (isCompressingMode) {
            island.stashExpandedHeight = 180
        } else {
            var rows = Math.min(3, Math.ceil(Math.max(1, modelCount) / 4.0))
            island.stashExpandedHeight = (128 * rows) + 32
        }
    }

    // ── LocalSend state ───────────────────────────────────────────────────────
    property string pendingFile: ""
    property string lsState: "idle"   // idle | scanning | ready | sending

    ListModel { id: deviceModel }

    Component.onCompleted: island.exec("mkdir -p ~/Downloads/qs_stash")

    // ── Processes ─────────────────────────────────────────────────────────────
    Process {
        id: compressProcess
        property string originalPath: ""
        property string outPath: ""
        command: ["bash", "-c",
            "size=$(stat -c%s \"" + originalPath + "\" 2>/dev/null || echo 0); echo \"SIZE|$size\";" +
            "f=\"" + originalPath + "\"; out=\"" + outPath + "\"; q=5; step=0;" +
            "while true; do" +
            "  ffmpeg -y -i \"$f\" -q:v $q -loglevel error \"$out\";" +
            "  size=$(stat -c%s \"$out\" 2>/dev/null || echo 0);" +
            "  step=$((step+1)); echo \"STEP|$step\";" +
            "  if [ \"$size\" -lt 1048576 ] || [ $q -ge 31 ]; then break; fi;" +
            "  q=$((q+4));" +
            "done; echo \"CSIZE|$size\""
        ]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                var text = line.trim()
                if (text.startsWith("SIZE|")) {
                    var sz = parseInt(text.split("|")[1])
                    root.activeCompressSize = sz > 1048576 ? (sz/1048576).toFixed(1)+" MB" : (sz/1024).toFixed(0)+" KB"
                } else if (text.startsWith("CSIZE|")) {
                    var sz = parseInt(text.split("|")[1])
                    root.compressedFileSize = sz > 1048576 ? (sz/1048576).toFixed(1)+" MB" : (sz/1024).toFixed(0)+" KB"
                } else if (text.startsWith("STEP|")) {
                    root.compressProgress = Math.min(0.99, parseInt(text.split("|")[1]) / 7.0)
                }
            }
        }
        onExited: {
            root.compressProgress = 1.0
            root.compressFinished = true
            island.stashModel.insert(0, { fileURL: "file://"+outPath, filePath: outPath, isFav: false, isDir: false })
        }
    }

    Process {
        id: moreCompressProcess
        property string inPath: ""
        property string outPath: ""
        command: ["bash", "-c",
            "ffmpeg -y -i \"" + inPath + "\" -vf scale=iw/2:ih/2 -q:v 31 -loglevel error \"" + outPath + "\";" +
            "size=$(stat -c%s \"" + outPath + "\" 2>/dev/null || echo 0); echo \"CSIZE|$size\""
        ]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                var text = line.trim()
                if (text.startsWith("CSIZE|")) {
                    var sz = parseInt(text.split("|")[1])
                    root.compressedFileSize = sz > 1048576 ? (sz/1048576).toFixed(1)+" MB" : (sz/1024).toFixed(0)+" KB"
                }
            }
        }
        onExited: {
            root.compressProgress = 1.0
            root.compressFinished = true
            island.stashModel.insert(0, { fileURL: "file://"+outPath, filePath: outPath, isFav: false, isDir: false })
            root.activeCompressOutPath = outPath
        }
    }

    Process {
        id: discoverProc
        command: ["bash", "-c", "exec \"$HOME/.config/hypr/scripts/quickshell/stash/localsend_discover.sh\""]
        stdout: StdioCollector { id: discoverOut }
        onExited: {
            if (root.lsState !== "scanning") return
            deviceModel.clear()
            var lines = discoverOut.text.trim().split('\n')
            for (var i = 0; i < lines.length; i++) {
                var parts = lines[i].split('\t')
                if (parts.length >= 2)
                    deviceModel.append({ alias: parts[0].trim(), ip: parts[1].trim() })
            }
            root.lsState = "ready"
        }
    }

    Process {
        id: sendProc
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: { root.lsState = "idle"; root.pendingFile = "" }
    }

    function openSendPicker(file) {
        pendingFile = file
        deviceModel.clear()
        lsState = "scanning"
        discoverProc.running = true
    }

    function sendTo(ip) {
        lsState = "sending"
        sendProc.command = ["bash", "-c",
            "\"$HOME/.config/hypr/scripts/quickshell/stash/localsend_send.sh\" '" + pendingFile + "' '" + ip + "'"]
        sendProc.running = true
    }

    HoverHandler { id: pageHover }

    // ── Main layout ───────────────────────────────────────────────────────────
    RowLayout {
        anchors.fill: parent
        anchors.margins: island.s(12)
        spacing: island.s(12)

        // ── Left panel: grid / compress detail ────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // ── LocalSend device picker overlay ───────────────────────────────
            Rectangle {
                anchors.fill: parent
                radius: island.s(12)
                color: Qt.rgba(island.base.r, island.base.g, island.base.b, 0.97)
                visible: root.lsState !== "idle"
                z: 20

                RowLayout {
                    id: pickerHeader
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: island.s(12)
                    anchors.topMargin: island.s(10)
                    height: island.s(26)
                    spacing: island.s(8)

                    Image {
                        Layout.preferredWidth: island.s(16)
                        Layout.preferredHeight: island.s(16)
                        Layout.alignment: Qt.AlignVCenter
                        source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='white'><path d='M18 16.08c-.76 0-1.44.3-1.96.77L8.91 12.7c.05-.23.09-.46.09-.7s-.04-.47-.09-.7l7.05-4.11c.54.5 1.25.81 2.04.81 1.66 0 3-1.34 3-3s-1.34-3-3-3-3 1.34-3 3c0 .24.04.47.09.7L8.04 9.81C7.5 9.31 6.79 9 6 9c-1.66 0-3 1.34-3 3s1.34 3 3 3c.79 0 1.5-.31 2.04-.81l7.12 4.16c-.05.21-.08.43-.08.65 0 1.61 1.31 2.92 2.92 2.92 1.61 0 2.92-1.31 2.92-2.92s-1.31-2.92-2.92-2.92z'/></svg>"
                        fillMode: Image.PreserveAspectFit
                    }
                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: root.lsState === "scanning" ? "Scanning…"
                            : root.lsState === "sending"  ? "Sending…"
                            : deviceModel.count === 0     ? "No devices found"
                            : "Send to"
                        color: island.text
                        font.family: "JetBrains Mono"
                        font.pixelSize: island.s(13)
                        font.weight: Font.Bold
                    }
                    Rectangle {
                        Layout.preferredWidth: island.s(14)
                        Layout.preferredHeight: island.s(14)
                        Layout.alignment: Qt.AlignVCenter
                        radius: width / 2
                        color: "transparent"
                        border.width: island.s(2)
                        border.color: island.teal
                        visible: root.lsState === "scanning" || root.lsState === "sending"
                        Rectangle {
                            width: island.s(3); height: island.s(3); radius: width / 2
                            color: island.teal
                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            transform: Rotation {
                                origin.x: 0; origin.y: island.s(7); angle: 0
                                RotationAnimation on angle {
                                    running: root.lsState === "scanning" || root.lsState === "sending"
                                    from: 0; to: 360; duration: 900; loops: Animation.Infinite
                                }
                            }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        Layout.preferredWidth: island.s(20)
                        Layout.preferredHeight: island.s(20)
                        Layout.alignment: Qt.AlignVCenter
                        radius: width / 2
                        color: lsCloseMouse.containsMouse
                            ? Qt.rgba(island.surface2.r, island.surface2.g, island.surface2.b, 0.8)
                            : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text { anchors.centerIn: parent; text: "✕"; color: island.subtext0; font.pixelSize: island.s(10); font.family: "JetBrains Mono" }
                        MouseArea {
                            id: lsCloseMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: { root.lsState = "idle"; root.pendingFile = ""; discoverProc.running = false }
                        }
                    }
                }

                ListView {
                    anchors.top: pickerHeader.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: island.s(8)
                    anchors.topMargin: island.s(4)
                    model: deviceModel
                    clip: true
                    spacing: island.s(4)

                    delegate: Rectangle {
                        width: parent ? parent.width : 0
                        height: island.s(34)
                        radius: island.s(8)
                        color: deviceHover.containsMouse
                            ? Qt.rgba(island.teal.r, island.teal.g, island.teal.b, 0.18)
                            : Qt.rgba(island.surface0.r, island.surface0.g, island.surface0.b, 0.6)
                        Behavior on color { ColorAnimation { duration: 120 } }
                        RowLayout {
                            anchors.left: parent.left; anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: island.s(12); anchors.rightMargin: island.s(8)
                            spacing: island.s(10)
                            Text { text: "󱁞"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(16); color: island.teal; Layout.alignment: Qt.AlignVCenter }
                            Column {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.fillWidth: true
                                Text { text: model.alias; color: island.text; font.family: "JetBrains Mono"; font.pixelSize: island.s(12); font.weight: Font.Medium }
                                Text { text: model.ip; color: island.subtext0; font.family: "JetBrains Mono"; font.pixelSize: island.s(10) }
                            }
                        }
                        MouseArea {
                            id: deviceHover
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: root.lsState === "ready"
                            onClicked: root.sendTo(model.ip)
                        }
                    }
                }
            }

            // ── File grid (normal mode) ───────────────────────────────────────
            Item {
                anchors.fill: parent
                visible: !root.isCompressingMode

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: island.s(8)
                    visible: island.stashModel.count === 0

                    Image {
                        source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='white'><path d='M4 6C4 4.895 4.895 4 6 4H18C19.105 4 20 4.895 20 6C20 7.105 19.105 8 18 8H6C4.895 8 4 7.105 4 6ZM5 10C5 8.895 5.895 8 7 8H17C18.105 8 19 8.895 19 10V18C19 19.105 18.105 20 17 20H7C5.895 20 5 19.105 5 18V10Z'/><path d='M9 12C9 11.448 9.448 11 10 11H14C14.552 11 15 11.448 15 12C15 12.552 14.552 13 14 13H10C9.448 13 9 12.552 9 12Z' fill='%231e1e2e'/></svg>"
                        Layout.preferredWidth: island.s(32); Layout.preferredHeight: island.s(32)
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text { text: "Files Tray"; color: "white"; font.family: "JetBrains Mono"; font.pixelSize: island.s(16); font.bold: true; Layout.alignment: Qt.AlignHCenter }
                    Text { text: "Drag and drop files"; color: island.subtext0; font.family: "JetBrains Mono"; font.pixelSize: island.s(14); Layout.alignment: Qt.AlignHCenter }
                }

                GridView {
                    id: imageGrid
                    anchors.left: parent.left; anchors.leftMargin: island.s(8)
                    anchors.top: parent.top; anchors.topMargin: island.s(4)
                    anchors.bottom: parent.bottom
                    width: cellWidth * 4
                    model: island.stashModel
                    cellWidth: island.s(128); cellHeight: island.s(128)
                    clip: true

                    delegate: Item {
                        width: imageGrid.cellWidth; height: imageGrid.cellHeight

                        MouseArea {
                            id: delegateMouse
                            anchors.fill: parent; anchors.margins: island.s(4)
                            drag.target: dragItem
                            hoverEnabled: true

                            Rectangle {
                                anchors.fill: parent
                                color: island.surface1; radius: island.s(8); clip: true

                                Image {
                                    id: imgPreview
                                    anchors.fill: parent
                                    source: isDir ? "" : fileURL
                                    fillMode: Image.PreserveAspectCrop
                                    visible: !isDir && status === Image.Ready
                                    layer.enabled: true
                                    layer.effect: MultiEffect {
                                        maskEnabled: true
                                        maskSource: ShaderEffectSource {
                                            sourceItem: Rectangle { width: imgPreview.width; height: imgPreview.height; radius: island.s(8) }
                                            hideSource: true
                                        }
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: {
                                        if (isDir) return filePath.indexOf("/group_") !== -1 ? "" : "󰉋"
                                        if (imgPreview.status === Image.Ready) return ""
                                        var ext = filePath.split('.').pop().toLowerCase()
                                        if (['pdf'].includes(ext))                        return "󰈦"
                                        if (['txt','md','log','csv'].includes(ext))       return "󰈙"
                                        if (['zip','tar','gz','rar','7z'].includes(ext))  return "󰛫"
                                        if (['mp3','wav','flac'].includes(ext))           return "󰎆"
                                        if (['mp4','mkv','avi','mov'].includes(ext))      return "󰕧"
                                        return "󰈔"
                                    }
                                    color: island.text; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(48)
                                    visible: isDir || (imgPreview.status !== Image.Ready && imgPreview.status !== Image.Loading)
                                }

                                Item {
                                    id: dragItem
                                    width: parent.width; height: parent.height
                                    Drag.active: delegateMouse.drag.active
                                    Drag.dragType: Drag.Automatic
                                    Drag.supportedActions: Qt.CopyAction
                                    Drag.mimeData: { "text/uri-list": fileURL }
                                    Drag.onActiveChanged: {
                                        if (Drag.active) outOfBoundsTimer.start()
                                        else { outOfBoundsTimer.stop(); island.expanded = false }
                                    }
                                    Timer {
                                        id: outOfBoundsTimer; interval: 200; repeat: true
                                        onTriggered: { if (dragItem.Drag.active && !pageHover.hovered) island.expanded = false }
                                    }
                                }

                                // Action buttons
                                Row {
                                    anchors.top: parent.top; anchors.right: parent.right
                                    anchors.margins: island.s(6); spacing: island.s(5)
                                    opacity: delegateMouse.containsMouse ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 150 } }

                                    Rectangle {
                                        width: island.s(24); height: island.s(24); radius: width/2
                                        color: Qt.rgba(island.base.r, island.base.g, island.base.b, 0.75)
                                        border.color: isFav ? Qt.rgba(island.yellow.r, island.yellow.g, island.yellow.b, 0.8) : "transparent"
                                        border.width: island.s(1)
                                        Text { anchors.centerIn: parent; text: isFav ? "󰓎" : "󰓒"; color: isFav ? island.yellow : island.subtext0; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(13) }
                                        MouseArea { anchors.fill: parent; onClicked: { var f = !isFav; island.stashModel.setProperty(index, "isFav", f); island.stashModel.move(index, f ? 0 : island.stashModel.count-1, 1) } }
                                    }

                                    Rectangle {
                                        width: island.s(24); height: island.s(24); radius: width/2
                                        color: Qt.rgba(island.teal.r, island.teal.g, island.teal.b, 0.85)
                                        Image {
                                            anchors.centerIn: parent
                                            width: parent.width * 0.58; height: parent.height * 0.58
                                            source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='white'><path d='M18 16.08c-.76 0-1.44.3-1.96.77L8.91 12.7c.05-.23.09-.46.09-.7s-.04-.47-.09-.7l7.05-4.11c.54.5 1.25.81 2.04.81 1.66 0 3-1.34 3-3s-1.34-3-3-3-3 1.34-3 3c0 .24.04.47.09.7L8.04 9.81C7.5 9.31 6.79 9 6 9c-1.66 0-3 1.34-3 3s1.34 3 3 3c.79 0 1.5-.31 2.04-.81l7.12 4.16c-.05.21-.08.43-.08.65 0 1.61 1.31 2.92 2.92 2.92 1.61 0 2.92-1.31 2.92-2.92s-1.31-2.92-2.92-2.92z'/></svg>"
                                            fillMode: Image.PreserveAspectFit
                                        }
                                        MouseArea { anchors.fill: parent; onClicked: root.openSendPicker(filePath) }
                                    }

                                    Rectangle {
                                        width: island.s(24); height: island.s(24); radius: width/2
                                        color: Qt.rgba(island.red.r, island.red.g, island.red.b, 0.85)
                                        Text { anchors.centerIn: parent; text: "󰆴"; color: "white"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(13) }
                                        MouseArea { anchors.fill: parent; onClicked: { island.exec("rm -rf '" + filePath + "'"); island.stashModel.remove(index); if (island.stashModel.count === 0) island.expanded = false } }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Compress detail (compress mode) ───────────────────────────────
            Item {
                anchors.fill: parent
                visible: root.isCompressingMode

                RowLayout {
                    anchors.fill: parent; anchors.margins: island.s(12); spacing: island.s(16)

                    Rectangle {
                        Layout.preferredWidth: island.s(120); Layout.preferredHeight: island.s(120)
                        Layout.alignment: Qt.AlignVCenter
                        color: island.surface1; radius: island.s(12); clip: true
                        Image {
                            id: stashImg; anchors.fill: parent
                            source: root.activeCompressFile !== "" ? "file://" + root.activeCompressFile : ""
                            fillMode: Image.PreserveAspectCrop
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                maskEnabled: true
                                maskSource: ShaderEffectSource {
                                    sourceItem: Rectangle { width: stashImg.width; height: stashImg.height; radius: island.s(12) }
                                    hideSource: true
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true; Layout.fillHeight: true; spacing: island.s(4)

                        Text { text: root.activeCompressName; font.family: "JetBrains Mono"; font.pixelSize: island.s(16); font.bold: true; color: "white"; Layout.fillWidth: true; elide: Text.ElideRight }

                        RowLayout {
                            spacing: island.s(8)
                            Text { text: "󰈔 " + root.activeCompressType; color: island.subtext0; font.family: "JetBrains Mono"; font.pixelSize: island.s(10) }
                            Text { text: "|"; color: island.surface2; font.pixelSize: island.s(10) }
                            Text {
                                text: "󰋊 " + root.activeCompressSize + (root.compressFinished && root.compressedFileSize !== "" ? "  →  " + root.compressedFileSize : "")
                                color: island.subtext0; font.family: "JetBrains Mono"; font.pixelSize: island.s(10)
                            }
                        }

                        Item { Layout.fillHeight: true }

                        // Progress pill
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: island.s(26)
                            color: "transparent"; border.color: island.surface2; border.width: island.s(1); radius: island.s(16); clip: true

                            Rectangle {
                                anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                                width: parent.width * root.compressProgress
                                color: Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.3)
                                visible: root.compressProgress > 0.0 && !root.compressFinished
                            }
                            RowLayout {
                                anchors.centerIn: parent; spacing: island.s(8)
                                visible: root.compressProgress > 0.0 && !root.compressFinished
                                Text { text: "󱑀"; color: island.mauve; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(12); RotationAnimator on rotation { running: root.compressProgress > 0.0 && !root.compressFinished; from: 0; to: 360; duration: 1000; loops: Animation.Infinite } }
                                Text { text: "Compressing " + Math.round(root.compressProgress * 100) + "%"; color: "white"; font.family: "JetBrains Mono"; font.pixelSize: island.s(10) }
                            }
                            RowLayout {
                                anchors.centerIn: parent; spacing: island.s(8)
                                visible: root.compressFinished || root.compressProgress === 0.0
                                Text { text: root.compressFinished ? "󰄬" : "󰆚"; color: "white"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(12) }
                                Text { text: root.compressFinished ? "Compressed successfully" : "Ready to compress"; color: "white"; font.family: "JetBrains Mono"; font.pixelSize: island.s(10) }
                            }
                        }

                        // Buttons
                        RowLayout {
                            spacing: island.s(8); Layout.fillWidth: true

                            Rectangle {
                                Layout.preferredWidth: island.s(72); Layout.preferredHeight: island.s(28)
                                radius: island.s(10); color: copyMouse.containsMouse ? island.surface1 : "transparent"
                                border.color: island.surface2; border.width: island.s(1)
                                RowLayout { anchors.centerIn: parent; spacing: island.s(6)
                                    Text { text: "󰆏"; color: "white"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(14) }
                                    Text { text: "Copy"; color: island.subtext0; font.family: "JetBrains Mono"; font.pixelSize: island.s(10) }
                                }
                                MouseArea { id: copyMouse; anchors.fill: parent; hoverEnabled: true
                                    onClicked: { if (root.activeCompressOutPath !== "") { island.exec("wl-copy -t image/jpeg < '" + root.activeCompressOutPath + "'"); island.playSound("notification") } }
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: island.s(72); Layout.preferredHeight: island.s(28)
                                visible: root.compressFinished
                                radius: island.s(10); color: moreMouse.containsMouse ? island.surface1 : "transparent"
                                border.color: island.surface2; border.width: island.s(1)
                                RowLayout { anchors.centerIn: parent; spacing: island.s(6)
                                    Text { text: "󰩨"; color: "white"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(14) }
                                    Text { text: "Resize"; color: island.subtext0; font.family: "JetBrains Mono"; font.pixelSize: island.s(10) }
                                }
                                MouseArea { id: moreMouse; anchors.fill: parent; hoverEnabled: true
                                    onClicked: {
                                        if (root.activeCompressOutPath !== "") {
                                            root.compressFinished = false; root.compressProgress = 0.5
                                            var newOut = root.activeCompressOutPath.replace(".jpg", "_min.jpg")
                                            moreCompressProcess.inPath = root.activeCompressOutPath
                                            moreCompressProcess.outPath = newOut
                                            moreCompressProcess.running = true
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                Layout.preferredWidth: island.s(72); Layout.preferredHeight: island.s(28)
                                radius: island.s(10); color: compCloseMouse.containsMouse ? island.surface1 : "transparent"
                                border.color: island.surface2; border.width: island.s(1)
                                RowLayout { anchors.centerIn: parent; spacing: island.s(6)
                                    Text { text: "󰅖"; color: "white"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(14) }
                                    Text { text: "Close"; color: island.subtext0; font.family: "JetBrains Mono"; font.pixelSize: island.s(10) }
                                }
                                MouseArea { id: compCloseMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.isCompressingMode = false }
                            }
                        }
                    }
                }
            }
        }

        // ── Right panel: compress drop zone ──────────────────────────────────
        Rectangle {
            id: compressZone
            Layout.preferredWidth: island.s(90)
            Layout.fillHeight: true
            color: island.surface0; radius: island.s(16)

            Image {
                anchors.fill: parent
                source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg'><rect width='100%' height='100%' fill='none' rx='16' stroke='%23585b70' stroke-width='2' stroke-dasharray='8'/></svg>"
                fillMode: Image.Stretch
            }

            ColumnLayout {
                anchors.centerIn: parent; spacing: island.s(8)
                Text { text: "󱇤"; font.family: "Iosevka Nerd Font"; font.pixelSize: island.s(28); color: island.text; Layout.alignment: Qt.AlignHCenter }
                Text { text: "Compress"; font.family: "JetBrains Mono"; font.pixelSize: island.s(12); font.bold: true; color: island.text; Layout.alignment: Qt.AlignHCenter }
                Text { text: "Drop file"; font.family: "JetBrains Mono"; font.pixelSize: island.s(10); color: island.subtext0; Layout.alignment: Qt.AlignHCenter }
            }

            DropArea {
                anchors.fill: parent
                keys: ["text/uri-list"]
                property bool isHovered: false
                onEntered: { isHovered = true; island.isDragHovered = true }
                onExited:  { isHovered = false; island.isDragHovered = false }

                Rectangle {
                    anchors.fill: parent; radius: island.s(16)
                    color: parent.isHovered ? Qt.rgba(island.green.r, island.green.g, island.green.b, 0.2) : "transparent"
                }

                onDropped: (drop) => {
                    isHovered = false
                    island._dropJustOccurred = true
                    island.isDragHovered = false
                    if (!drop.hasUrls) return
                    var url = drop.urls[0].toString().trim()
                    if (!url.startsWith("file://")) return
                    var filePath = decodeURIComponent(url.replace("file://", ""))
                    var fileName = filePath.split('/').pop()
                    var baseName = fileName.substring(0, fileName.lastIndexOf('.')) || fileName
                    var stashDir = filePath.substring(0, filePath.lastIndexOf('/') + 1)
                    var outPath = stashDir + baseName + "_compressed.jpg"

                    root.activeCompressFile = filePath
                    root.activeCompressOutPath = outPath
                    root.activeCompressName = fileName
                    root.activeCompressType = fileName.split('.').pop().toUpperCase() + " Image"
                    root.compressProgress = 0.0
                    root.compressFinished = false
                    root.isCompressingMode = true

                    compressProcess.originalPath = filePath
                    compressProcess.outPath = outPath
                    compressProcess.running = true
                    drop.accept()
                }
            }
        }
    }
}
