import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root
    spacing: Style.marginM

    // Plugin API (injected by the settings dialog system)
    property var pluginApi: null

    // Widget settings object (injected by the settings dialog system)
    property var widgetSettings: null

    // Local state - initialize from widgetSettings.data with metadata fallback
    property int valueSides: widgetSettings?.data?.sides ?? pluginApi?.manifest?.metadata?.defaultSettings?.sides ?? 9
    property string valueDialStyle: widgetSettings?.data?.dialStyle ?? pluginApi?.manifest?.metadata?.defaultSettings?.dialStyle ?? "dots"
    property string valueHourHandStyle: widgetSettings?.data?.hourHandStyle ?? pluginApi?.manifest?.metadata?.defaultSettings?.hourHandStyle ?? "fill"
    property string valueMinuteHandStyle: widgetSettings?.data?.minuteHandStyle ?? pluginApi?.manifest?.metadata?.defaultSettings?.minuteHandStyle ?? "medium"
    property string valueSecondHandStyle: widgetSettings?.data?.secondHandStyle ?? pluginApi?.manifest?.metadata?.defaultSettings?.secondHandStyle ?? "dot"
    property string valueDateStyle: widgetSettings?.data?.dateStyle ?? pluginApi?.manifest?.metadata?.defaultSettings?.dateStyle ?? "bubble"
    property bool valueShowSeconds: widgetSettings?.data?.showSeconds ?? pluginApi?.manifest?.metadata?.defaultSettings?.showSeconds ?? true
    property bool valueShowHourMarks: widgetSettings?.data?.showHourMarks ?? pluginApi?.manifest?.metadata?.defaultSettings?.showHourMarks ?? false
    property real valueBackgroundOpacity: widgetSettings?.data?.backgroundOpacity ?? pluginApi?.manifest?.metadata?.defaultSettings?.backgroundOpacity ?? 1.0

    NComboBox {
        Layout.fillWidth: true
        label: root.pluginApi?.tr("desktopWidgetSettings.dial-style-label")
        description: root.pluginApi?.tr("desktopWidgetSettings.dial-style-description")
        model: [
            { "key": "dots", "name": root.pluginApi?.tr("desktopWidgetSettings.style-dots") },
            { "key": "numbers", "name": root.pluginApi?.tr("desktopWidgetSettings.style-numbers") },
            { "key": "full", "name": root.pluginApi?.tr("desktopWidgetSettings.style-full") },
            { "key": "none", "name": root.pluginApi?.tr("desktopWidgetSettings.style-none") }
        ]
        currentKey: root.valueDialStyle
        onSelected: key => {
            root.valueDialStyle = key;
            saveSettings();
        }
    }

    NComboBox {
        Layout.fillWidth: true
        label: root.pluginApi?.tr("desktopWidgetSettings.hour-hand-label")
        description: root.pluginApi?.tr("desktopWidgetSettings.hour-hand-description")
        model: [
            { "key": "fill", "name": root.pluginApi?.tr("desktopWidgetSettings.style-fill") },
            { "key": "hollow", "name": root.pluginApi?.tr("desktopWidgetSettings.style-hollow") },
            { "key": "classic", "name": root.pluginApi?.tr("desktopWidgetSettings.style-classic") },
            { "key": "hide", "name": root.pluginApi?.tr("desktopWidgetSettings.style-hide") }
        ]
        currentKey: root.valueHourHandStyle
        onSelected: key => {
            root.valueHourHandStyle = key;
            saveSettings();
        }
    }

    NComboBox {
        Layout.fillWidth: true
        label: root.pluginApi?.tr("desktopWidgetSettings.minute-hand-label")
        description: root.pluginApi?.tr("desktopWidgetSettings.minute-hand-description")
        model: [
            { "key": "bold", "name": root.pluginApi?.tr("desktopWidgetSettings.style-bold") },
            { "key": "medium", "name": root.pluginApi?.tr("desktopWidgetSettings.style-medium") },
            { "key": "thin", "name": root.pluginApi?.tr("desktopWidgetSettings.style-thin") },
            { "key": "classic", "name": root.pluginApi?.tr("desktopWidgetSettings.style-classic") },
            { "key": "hide", "name": root.pluginApi?.tr("desktopWidgetSettings.style-hide") }
        ]
        currentKey: root.valueMinuteHandStyle
        onSelected: key => {
            root.valueMinuteHandStyle = key;
            saveSettings();
        }
    }
    
    NComboBox {
        Layout.fillWidth: true
        label: root.pluginApi?.tr("desktopWidgetSettings.second-hand-label")
        description: root.pluginApi?.tr("desktopWidgetSettings.second-hand-description")
        model: [
            { "key": "dot", "name": root.pluginApi?.tr("desktopWidgetSettings.style-dot") },
            { "key": "classic", "name": root.pluginApi?.tr("desktopWidgetSettings.style-classic") },
            { "key": "line", "name": root.pluginApi?.tr("desktopWidgetSettings.style-line") },
            { "key": "hide", "name": root.pluginApi?.tr("desktopWidgetSettings.style-hide") }
        ]
        currentKey: root.valueSecondHandStyle
        onSelected: key => {
            root.valueSecondHandStyle = key;
            saveSettings();
        }
    }

    NComboBox {
        Layout.fillWidth: true
        label: root.pluginApi?.tr("desktopWidgetSettings.date-style-label")
        description: root.pluginApi?.tr("desktopWidgetSettings.date-style-description")
        model: [
            { "key": "bubble", "name": root.pluginApi?.tr("desktopWidgetSettings.style-bubble") },
            { "key": "hide", "name": root.pluginApi?.tr("desktopWidgetSettings.style-hide") }
        ]
        currentKey: root.valueDateStyle
        onSelected: key => {
            root.valueDateStyle = key;
            saveSettings();
        }
    }

    NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginS
        Layout.bottomMargin: Style.marginS
    }

    NToggle {
        Layout.fillWidth: true
        label: root.pluginApi?.tr("desktopWidgetSettings.show-hour-marks-label")
        description: root.pluginApi?.tr("desktopWidgetSettings.show-hour-marks-description")
        checked: root.valueShowHourMarks
        onToggled: checked => {
            root.valueShowHourMarks = checked;
            saveSettings();
        }
        defaultValue: false
    }

    NValueSlider {
        property real _value: root.valueBackgroundOpacity * 100
        Layout.fillWidth: true
        label: root.pluginApi?.tr("desktopWidgetSettings.background-opacity-label")
        description: root.pluginApi?.tr("desktopWidgetSettings.background-opacity-description")
        value: _value
        text: Math.round(_value) + "%"
        from: 0
        to: 100
        stepSize: 1
        defaultValue: 100
        onMoved: value => _value = value
        onPressedChanged: (pressed, value) => {
            if (!pressed) { 
                root.valueBackgroundOpacity = value / 100; 
                root.saveSettings(); 
            }
        }
    }

    NValueSlider {
        property int _value: root.valueSides
        Layout.fillWidth: true
        label: root.pluginApi?.tr("desktopWidgetSettings.cookie-shape-label")
        description: root.pluginApi?.tr("desktopWidgetSettings.cookie-shape-description")
        value: _value
        text: String(_value)
        from: 3
        to: 20
        stepSize: 1
        defaultValue: 9
        onMoved: value => _value = Math.round(value)
        onPressedChanged: (pressed, value) => {
            if (!pressed) { 
                root.valueSides = Math.round(value); 
                root.saveSettings(); 
            }
        }
    }

    function saveSettings() {
        if (!widgetSettings) return;
        
        // Use object assignment to ensure data is created properly if null
        var data = widgetSettings.data || {};
        
        data.sides = root.valueSides;
        data.dialStyle = root.valueDialStyle;
        data.hourHandStyle = root.valueHourHandStyle;
        data.minuteHandStyle = root.valueMinuteHandStyle;
        data.secondHandStyle = root.valueSecondHandStyle;
        data.dateStyle = root.valueDateStyle;
        data.showSeconds = root.valueShowSeconds;
        data.showHourMarks = root.valueShowHourMarks;
        data.backgroundOpacity = root.valueBackgroundOpacity;
        
        widgetSettings.data = data;
        widgetSettings.save();
    }
}
