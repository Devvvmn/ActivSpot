pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property real   latitude:  0.0
    readonly property real   longitude: 0.0
    readonly property string city:      ""
    readonly property string country:   ""
    readonly property bool   available: false
}
