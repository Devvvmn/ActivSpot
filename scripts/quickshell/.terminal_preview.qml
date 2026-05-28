import QtQuick
import Quickshell

FloatingWindow {
    visible: true
    color: "transparent"
    
    // Native QML auto-sizing: window follows content size
    width: loader.item ? loader.item.implicitWidth : 100
    height: loader.item ? loader.item.implicitHeight : 100
    
    Loader {
        id: loader
        anchors.fill: parent
        source: "hello/HelloPopup.qml"
        onStatusChanged: {
            if (status == Loader.Error) console.error("Loader Error: " + sourceComponent.errorString())
        }
    }
}
