import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import QtCore

Item {
    id: root
    property var island

    // Ensure the stash directory exists
    Component.onCompleted: {
        island.exec("mkdir -p ~/Downloads/qs_stash")
    }

    // The model is now hosted in DynamicIsland.qml as island.stashModel

    Item {
        anchors.fill: parent
        anchors.margins: island.s(12)

        Rectangle {
            id: dropZone
            anchors.fill: parent
            color: island.isDragHovered ? Qt.rgba(island.mauve.r, island.mauve.g, island.mauve.b, 0.2) : "transparent"
            radius: island.s(16)

            ColumnLayout {
                anchors.centerIn: parent
                spacing: island.s(8)
                visible: island.stashModel.count === 0

                Image {
                    source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='white'><path d='M4 6C4 4.895 4.895 4 6 4H18C19.105 4 20 4.895 20 6C20 7.105 19.105 8 18 8H6C4.895 8 4 7.105 4 6ZM5 10C5 8.895 5.895 8 7 8H17C18.105 8 19 8.895 19 10V18C19 19.105 18.105 20 17 20H7C5.895 20 5 19.105 5 18V10Z'/><path d='M9 12C9 11.448 9.448 11 10 11H14C14.552 11 15 11.448 15 12C15 12.552 14.552 13 14 13H10C9.448 13 9 12.552 9 12Z' fill='%231e1e2e'/></svg>"
                    Layout.preferredWidth: island.s(32)
                    Layout.preferredHeight: island.s(32)
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Files Tray"
                    color: "white"
                    font.family: "JetBrains Mono"
                    font.pixelSize: island.s(16)
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Drag and drop files"
                    color: island.subtext0 || "lightgray"
                    font.family: "JetBrains Mono"
                    font.pixelSize: island.s(14)
                    textFormat: Text.RichText
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            GridView {
                id: imageGrid
                anchors.fill: parent
                anchors.margins: 0
                model: island.stashModel
                cellWidth: island.s(110)
                cellHeight: island.s(110)
                clip: true

                delegate: Item {
                    width: imageGrid.cellWidth
                    height: imageGrid.cellHeight

                    MouseArea {
                        id: delegateMouse
                        anchors.fill: parent
                        anchors.margins: island.s(5)
                        drag.target: dragItem
                        hoverEnabled: true

                        Rectangle {
                            anchors.fill: parent
                            color: island.surface1
                            radius: island.s(8)
                            clip: true

                            Image {
                                id: imgPreview
                                anchors.fill: parent
                                source: isDir ? "" : fileURL
                                fillMode: Image.PreserveAspectCrop
                                visible: !isDir && status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    if (isDir) {
                                        if (filePath.indexOf("/group_") !== -1) return ""; // box icon
                                        return "󰉋";
                                    }
                                    if (imgPreview.status === Image.Ready) return "";
                                    var ext = filePath.split('.').pop().toLowerCase();
                                    if (['pdf'].includes(ext)) return "󰈦";
                                    if (['txt', 'md', 'log', 'csv'].includes(ext)) return "󰈙";
                                    if (['zip', 'tar', 'gz', 'rar', '7z'].includes(ext)) return "󰛫";
                                    if (['mp3', 'wav', 'flac'].includes(ext)) return "󰎆";
                                    if (['mp4', 'mkv', 'avi', 'mov'].includes(ext)) return "󰕧";
                                    return "󰈔";
                                }
                                color: island.text
                                font.family: "Iosevka Nerd Font"
                                font.pixelSize: island.s(48)
                                visible: isDir || (imgPreview.status !== Image.Ready && imgPreview.status !== Image.Loading)
                            }

                            Item {
                                id: dragItem
                                width: parent.width
                                height: parent.height
                                Drag.active: delegateMouse.drag.active
                                Drag.dragType: Drag.Automatic
                                Drag.supportedActions: Qt.CopyAction
                                Drag.mimeData: { "text/uri-list": fileURL }
                                Drag.onActiveChanged: {
                                    if (Drag.active) {
                                        island.expanded = false;
                                    }
                                }
                            }

                            Row {
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: island.s(6)
                                spacing: island.s(6)
                                opacity: delegateMouse.containsMouse ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 150 } }

                                Rectangle {
                                    width: island.s(24)
                                    height: island.s(24)
                                    radius: island.s(12)
                                    color: Qt.rgba(island.base.r, island.base.g, island.base.b, 0.7)
                                    border.color: isFav ? island.yellow : "transparent"
                                    border.width: island.s(1)

                                    Text {
                                        anchors.centerIn: parent
                                        text: isFav ? "󰓎" : "󰓒"
                                        color: isFav ? island.yellow : island.text
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: island.s(14)
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            var newFav = !isFav;
                                            island.stashModel.setProperty(index, "isFav", newFav)
                                            if (newFav) {
                                                island.stashModel.move(index, 0, 1)
                                            } else {
                                                island.stashModel.move(index, island.stashModel.count - 1, 1)
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    width: island.s(24)
                                    height: island.s(24)
                                    radius: island.s(12)
                                    color: Qt.rgba(island.red.r, island.red.g, island.red.b, 0.8)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰆴" // trash icon
                                        color: island.base
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: island.s(14)
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            island.exec("rm -rf '" + filePath + "'")
                                            island.stashModel.remove(index)
                                            if (island.stashModel.count === 0) {
                                                island.expanded = false
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
}
