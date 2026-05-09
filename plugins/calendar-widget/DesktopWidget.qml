import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.Commons
import qs.Modules.DesktopWidgets
import qs.Widgets

DraggableDesktopWidget {
  id: root

  property var pluginApi: null
  property var widgetSettings: null

  property bool showBackground: true
  property bool roundedCorners: true

  readonly property int effectiveFirstDay: {
    let stored = Settings.data.location.firstDayOfWeek;

    if (stored === undefined || stored === null)
      stored = -1;

    if (stored === -1) {
      let qtDay = Qt.locale().firstDayOfWeek;
      return qtDay === 7 ? 0 : qtDay;
    }

    return stored;
  }

  // --- Sizing ---
  // Fixed height for 6 rows (42 days) ensures the widget doesn't "jump" size
  implicitWidth: Math.round(265 * widgetScale)
  implicitHeight: Math.round(287 * widgetScale)
  width: implicitWidth
  height: implicitHeight

  // --- Date Logic ---
  property date currentDate: new Date()
  property int liveDay: new Date().getDate()
  property int liveMonth: new Date().getMonth()
  property int liveYear: new Date().getFullYear()

  function refreshDate() {
    let now = new Date();
    currentDate = now;
    liveDay = now.getDate();
    liveMonth = now.getMonth();
    liveYear = now.getFullYear();
  }

  onVisibleChanged: if (visible) refreshDate()

  Timer {
    interval: 60000
    running: true
    repeat: true
    onTriggered: root.refreshDate()
  }

  readonly property var days: {
    if (effectiveFirstDay === 6)
      return ["SA", "SU", "MO", "TU", "WE", "TH", "FR"];
    if (effectiveFirstDay === 0)
      return ["SU", "MO", "TU", "WE", "TH", "FR", "SA"];
    return ["MO", "TU", "WE", "TH", "FR", "SA", "SU"];
  }

  readonly property int firstDayOffset: {
    let jsDay = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1).getDay();
    if (effectiveFirstDay === 1)
      return jsDay === 0 ? 6 : jsDay - 1;
    if (effectiveFirstDay === 0)
      return jsDay;
    return jsDay === 6 ? 0 : jsDay + 1;
  }

  readonly property int daysInMonth: new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 0).getDate()

  // --- UI Layout ---
  ColumnLayout {
    id: contentLayout

    anchors.fill: parent
    anchors.margins: Math.round(Style.marginL * widgetScale)
    spacing: Math.round(Style.marginXXXS * widgetScale)

    NText {
      text: currentDate.toLocaleDateString(Qt.locale(), "MMMM yyyy").toUpperCase()
      color: Color.mPrimary
      font.weight: Font.Bold
      font.letterSpacing: Math.round(Style.marginS * widgetScale)
      font.pointSize: Math.round(Style.fontSizeL * widgetScale)
      Layout.alignment: Qt.AlignHCenter

      layer.enabled: !root.isScaling
      layer.effect: MultiEffect {
        shadowEnabled: true
        shadowBlur: 0.5
        shadowOpacity: 0.3
      }
    }

    NDivider {
      Layout.fillWidth: true
      Layout.topMargin: Math.round(Style.marginS * widgetScale)
      Layout.bottomMargin: Math.round(Style.marginS * widgetScale)
    }

    GridLayout {
      columns: 7
      rowSpacing: Math.round(Style.marginS * widgetScale)
      columnSpacing: Math.round(Style.marginS * widgetScale)
      Layout.fillWidth: true

      // Weekday Headers
      Repeater {
        model: root.days
        NText {
          text: modelData
          color: Color.mPrimary
          font.weight: Font.Bold
          font.pointSize: Math.round(Style.fontSizeS * widgetScale)
          Layout.fillWidth: true
          horizontalAlignment: Text.AlignHCenter
        }
      }

      // Leading Padding (Empty spaces before the 1st of the month)
      Repeater {
        model: root.firstDayOffset
        Item {
          Layout.preferredWidth: 28 * widgetScale
          Layout.preferredHeight: 28 * widgetScale
        }
      }

      // Actual Days of the Month
      Repeater {
        model: root.daysInMonth
        Rectangle {
          readonly property int dayNum: index + 1
          readonly property bool isActuallyToday: dayNum === root.liveDay &&
          root.currentDate.getMonth() === root.liveMonth &&
          root.currentDate.getFullYear() === root.liveYear

          Layout.preferredWidth: 28 * widgetScale
          Layout.preferredHeight: 28 * widgetScale

          color: isActuallyToday ? Color.mSecondary : "transparent"
          radius: Math.round(Style.radiusS * widgetScale)

          NText {
            anchors.centerIn: parent
            text: dayNum
            color: isActuallyToday ? Color.mOnPrimary : Color.mOnSurface
            font.weight: isActuallyToday ? Font.Bold : Font.Light
            font.pointSize: Math.round(Style.fontSizeS * widgetScale)
          }
        }
      }

      // Trailing Padding (Fills the grid to exactly 6 rows / 42 cells)
      Repeater {
        model: 42 - (root.firstDayOffset + root.daysInMonth)
        Item {
          Layout.preferredWidth: 28 * widgetScale
          Layout.preferredHeight: 28 * widgetScale
        }
      }
    }
  }
}
