import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.Theming
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property var pluginApi: null

  readonly property var geometryPlaceholder: panelContainer
  property real contentPreferredWidth: 480 * Style.uiScaleRatio
  property real contentPreferredHeight: editorLayout.implicitHeight + Style.margin2L
  readonly property bool allowAttach: true

  // ── State ────────────────────────────────────────────────────
  property var editingScheme: null
  property string editingVariant: "dark"
  property string pickerTargetKey: ""
  property bool previewActive: false
  property var originalColors: null
  property string pendingSchemeName: ""

  // Restore colors when panel is destroyed (closes) while preview is active
  Component.onDestruction: {
    root.stopPreview();
  }


  readonly property var colorRoles: [
    {
      key: "mPrimary",
      label: "Primary"
    },
    {
      key: "mOnPrimary",
      label: "On Primary"
    },
    {
      key: "mSecondary",
      label: "Secondary"
    },
    {
      key: "mOnSecondary",
      label: "On Secondary"
    },
    {
      key: "mTertiary",
      label: "Tertiary"
    },
    {
      key: "mOnTertiary",
      label: "On Tertiary"
    },
    {
      key: "mError",
      label: "Error"
    },
    {
      key: "mOnError",
      label: "On Error"
    },
    {
      key: "mSurface",
      label: "Surface"
    },
    {
      key: "mOnSurface",
      label: "On Surface"
    },
    {
      key: "mSurfaceVariant",
      label: "Surface Variant"
    },
    {
      key: "mOnSurfaceVariant",
      label: "On Surface Variant"
    },
    {
      key: "mOutline",
      label: "Outline"
    },
    {
      key: "mShadow",
      label: "Shadow"
    },
    {
      key: "mHover",
      label: "Hover"
    },
    {
      key: "mOnHover",
      label: "On Hover"
    }
  ]

  anchors.fill: parent

  // pluginApi is set AFTER Component.onCompleted fires, so we initialize here
  onPluginApiChanged: {
    if (!pluginApi)
      return;
    var wip = pluginApi.pluginSettings?.wip;
    if (wip && wip.dark && wip.light) {
      root.editingScheme = {
        dark: wip.dark,
        light: wip.light
      };
      nameInput.text = wip.name ?? "";
    } else {
      seedEditor();
    }
  }

  onEditingSchemeChanged: saveWip()

  function saveWip() {
    if (!pluginApi || !root.editingScheme)
      return;
    pluginApi.pluginSettings.wip = {
      name: nameInput.text,
      dark: root.editingScheme.dark,
      light: root.editingScheme.light
    };
    pluginApi.saveSettings();
  }

  function clearWip() {
    if (!pluginApi)
      return;
    pluginApi.pluginSettings.wip = null;
    pluginApi.saveSettings();
  }

  // ── Scheme File Reader ────────────────────────────────────────
  FileView {
    id: schemeFileReader
    onLoaded: {
      try {
        var data = JSON.parse(text());
        if (data && data.dark && data.light) {
          root.editingScheme = {
            dark: data.dark,
            light: data.light
          };
        } else {
          root.editingScheme = root.fallbackScheme();
        }
      } catch (e) {
        root.editingScheme = root.fallbackScheme();
      }
      clearWip();
    }
  }

  // ── Processes ─────────────────────────────────────────────────
  Process {
    id: writeProcess
    running: false
    stdout: StdioCollector {}
    stderr: StdioCollector {}
    onExited: function(code) {
      if (code === 0) {
        var name = root.pendingSchemeName;
        var filePath = Settings.configDir + "colorschemes/" + name + "/" + name + ".json";
        Settings.data.colorSchemes.useWallpaperColors = false;
        Settings.data.colorSchemes.predefinedScheme = name;
        ColorSchemeService.applyScheme(filePath);
        ColorSchemeService.loadColorSchemes();
        ToastService.showNotice(pluginApi?.tr("panel.title"), pluginApi?.tr("notifications.saved"));
      } else {
        ToastService.showError(pluginApi?.tr("panel.title"), pluginApi?.tr("notifications.save-error"));
      }
      root.pendingSchemeName = "";
    }
  }

  // ── Color Picker Dialog ───────────────────────────────────────
  NColorPickerDialog {
    id: colorPicker
    screen: pluginApi?.panelOpenScreen
    liveMode: root.previewActive
    onColorSelected: function(color) {
      if (!root.editingScheme || !root.pickerTargetKey)
        return;
      var updated = JSON.parse(JSON.stringify(root.editingScheme));
      updated[root.editingVariant][root.pickerTargetKey] = color.toString();
      root.editingScheme = updated;
      if (root.previewActive)
        root.applyPreview();
    }
  }

  // ── Logic ─────────────────────────────────────────────────────
  function seedColors() {
    return {
      mPrimary: Color.mPrimary.toString(),
      mOnPrimary: Color.mOnPrimary.toString(),
      mSecondary: Color.mSecondary.toString(),
      mOnSecondary: Color.mOnSecondary.toString(),
      mTertiary: Color.mTertiary.toString(),
      mOnTertiary: Color.mOnTertiary.toString(),
      mError: Color.mError.toString(),
      mOnError: Color.mOnError.toString(),
      mSurface: Color.mSurface.toString(),
      mOnSurface: Color.mOnSurface.toString(),
      mSurfaceVariant: Color.mSurfaceVariant.toString(),
      mOnSurfaceVariant: Color.mOnSurfaceVariant.toString(),
      mOutline: Color.mOutline.toString(),
      mShadow: Color.mShadow.toString(),
      mHover: Color.mHover.toString(),
      mOnHover: Color.mOnHover.toString()
    };
  }

  function fallbackScheme() {
    // Used only when no predefined scheme is available (e.g. wallpaper colors).
    // Both variants start from the active Color.m* — user will need to adjust the other manually.
    var seed = seedColors();
    return {
      dark: seed,
      light: JSON.parse(JSON.stringify(seed))
    };
  }

  function startPreview() {
    if (root.previewActive)
      return;
    root.originalColors = seedColors();
    root.previewActive = true;
    applyPreview();
  }

  function stopPreview() {
    if (!root.previewActive)
      return;
    root.previewActive = false;
    if (root.originalColors) {
      ColorSchemeService.writeColorsToDisk(root.originalColors);
      root.originalColors = null;
    }
  }

  function applyPreview() {
    if (!root.previewActive || !root.editingScheme)
      return;
    var variant = Settings.data.colorSchemes.darkMode ? root.editingScheme.dark : root.editingScheme.light;
    ColorSchemeService.writeColorsToDisk(variant);
  }

  function seedEditor() {
    root.stopPreview();
    nameInput.text = "";
    root.editingVariant = "dark";
    // Try to read the predefined scheme file to get real dark+light variants
    var schemeName = Settings.data.colorSchemes.predefinedScheme;
    if (!Settings.data.colorSchemes.useWallpaperColors && schemeName) {
      var path = ColorSchemeService.resolveSchemePath(schemeName);
      if (path) {
        schemeFileReader.path = "";
        schemeFileReader.path = path;
        return; // editingScheme will be set in schemeFileReader.onLoaded
      }
    }
    root.editingScheme = fallbackScheme();
    clearWip();
  }

  // Derive terminal ANSI colors from MD3 color roles so terminal themes generate correctly.
  // green and yellow have no MD3 equivalents so we synthesize them from the primary's
  // saturation/value at standard ANSI hues (135° green, 55° yellow).
  function generateTerminalColors(variant) {
    var surface = Qt.color(variant.mSurface);
    var isDark = (surface.r + surface.g + surface.b) / 3 < 0.5;

    var primary = Qt.color(variant.mPrimary);
    var sat = primary.hsvSaturation > 0.3 ? primary.hsvSaturation : (isDark ? 0.70 : 0.65);
    var val = isDark ? 0.80 : 0.55;

    function colorAt(hueDeg) {
      return Qt.hsva(hueDeg / 360, sat, val, 1).toString().toUpperCase();
    }

    function brighten(hexColor) {
      var c = Qt.color(hexColor);
      var h = c.hsvHue < 0 ? 0 : c.hsvHue;
      return Qt.hsva(h, Math.max(0, c.hsvSaturation - 0.1), Math.min(1.0, c.hsvValue + (isDark ? 0.15 : 0.20)), 1).toString().toUpperCase();
    }

    var normGreen = colorAt(135);
    var normYellow = colorAt(55);

    return {
      normal: {
        black: surface.toString().toUpperCase(),
        red: Qt.color(variant.mError).toString().toUpperCase(),
        green: normGreen,
        yellow: normYellow,
        blue: Qt.color(variant.mPrimary).toString().toUpperCase(),
        magenta: Qt.color(variant.mSecondary).toString().toUpperCase(),
        cyan: Qt.color(variant.mTertiary).toString().toUpperCase(),
        white: Qt.color(variant.mOnSurface).toString().toUpperCase()
      },
      bright: {
        black: Qt.color(variant.mSurfaceVariant).toString().toUpperCase(),
        red: brighten(variant.mError),
        green: brighten(normGreen),
        yellow: brighten(normYellow),
        blue: brighten(variant.mPrimary),
        magenta: brighten(variant.mSecondary),
        cyan: brighten(variant.mTertiary),
        white: isDark ? "#FFFFFF" : brighten(variant.mOnSurface)
      },
      foreground: Qt.color(variant.mOnSurface).toString().toUpperCase(),
      background: surface.toString().toUpperCase(),
      selectionFg: Qt.color(variant.mOnPrimary).toString().toUpperCase(),
      selectionBg: Qt.color(variant.mPrimary).toString().toUpperCase(),
      cursor: Qt.color(variant.mPrimary).toString().toUpperCase(),
      cursorText: Qt.color(variant.mOnPrimary).toString().toUpperCase()
    };
  }

  function saveScheme() {
    var name = nameInput.text.trim();
    if (!name)
      return;
    var dir = Settings.configDir + "colorschemes/" + name;
    var filePath = dir + "/" + name + ".json";
    var darkVariant = JSON.parse(JSON.stringify(root.editingScheme.dark));
    var lightVariant = JSON.parse(JSON.stringify(root.editingScheme.light));
    darkVariant.terminal = generateTerminalColors(root.editingScheme.dark);
    lightVariant.terminal = generateTerminalColors(root.editingScheme.light);
    var payload = {
      dark: darkVariant,
      light: lightVariant
    };
    var json = JSON.stringify(payload, null, 2);
    root.pendingSchemeName = name;
    writeProcess.command = ["python3", "-c", "import sys, os, json; d=json.loads(sys.argv[1]); os.makedirs(sys.argv[2], exist_ok=True); open(sys.argv[3],'w').write(json.dumps(d, indent=2))", json, dir, filePath];
    writeProcess.running = true;
    // Clear preview state without restoring — saved colors are already applied
    root.previewActive = false;
    root.originalColors = null;
    clearWip();
    seedEditor();
  }

  // ── Panel Container ───────────────────────────────────────────
  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    ColumnLayout {
      id: editorLayout
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      // Header
      NBox {
        Layout.fillWidth: true
        implicitHeight: headerContent.implicitHeight + Style.margin2M

        RowLayout {
          id: headerContent
          anchors {
            fill: parent
            margins: Style.marginM
          }

          NIcon {
            icon: "palette"
            pointSize: Style.fontSizeXXL
            color: Color.mPrimary
          }

          NText {
            text: pluginApi?.tr("panel.title")
            pointSize: Style.fontSizeL
            font.weight: Style.fontWeightBold
            color: Color.mOnSurface
            Layout.fillWidth: true
          }

          NIconButton {
            icon: "close"
            tooltipText: I18n.tr("common.close")
            baseSize: Style.baseWidgetSize * 0.8
            onClicked: pluginApi.closePanel(pluginApi.panelOpenScreen)
          }
        }
      }

      // Color roles — two columns: Dark | Light
      NBox {
        Layout.fillWidth: true
        implicitHeight: colorList.implicitHeight + Style.margin2M

        ColumnLayout {
          id: colorList
          anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: Style.marginM
          }
          spacing: Style.marginXS

          // Column headers
          RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: Style.marginXS

            Item {
              Layout.preferredWidth: 150 * Style.uiScaleRatio
            }

            NText {
              text: pluginApi?.tr("panel.dark")
              color: Color.mOnSurfaceVariant
              pointSize: Style.fontSizeS
              font.weight: Font.Medium
              horizontalAlignment: Text.AlignHCenter
              Layout.fillWidth: true
            }

            NText {
              text: pluginApi?.tr("panel.light")
              color: Color.mOnSurfaceVariant
              pointSize: Style.fontSizeS
              font.weight: Font.Medium
              horizontalAlignment: Text.AlignHCenter
              Layout.fillWidth: true
            }
          }

          Repeater {
            model: root.colorRoles

            RowLayout {
              required property var modelData
              Layout.fillWidth: true
              spacing: Style.marginS

              NText {
                text: modelData.label
                color: Color.mOnSurface
                Layout.preferredWidth: 150 * Style.uiScaleRatio
                elide: Text.ElideRight
              }

              // Dark swatch
              Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 25 * Style.uiScaleRatio

                Rectangle {
                  anchors.centerIn: parent
                  width: 25 * Style.uiScaleRatio
                  height: 25 * Style.uiScaleRatio
                  radius: Style.radiusS
                  color: root.editingScheme?.dark?.[modelData.key] ?? "#000000"
                  border.color: Color.mOutline
                  border.width: Style.borderS

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      root.editingVariant = "dark";
                      root.pickerTargetKey = modelData.key;
                      colorPicker.selectedColor = root.editingScheme?.dark?.[modelData.key] ?? "#000000";
                      colorPicker.open();
                    }
                  }
                }
              }

              // Light swatch
              Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 25 * Style.uiScaleRatio

                Rectangle {
                  anchors.centerIn: parent
                  width: 25 * Style.uiScaleRatio
                  height: 25 * Style.uiScaleRatio
                  radius: Style.radiusS
                  color: root.editingScheme?.light?.[modelData.key] ?? "#000000"
                  border.color: Color.mOutline
                  border.width: Style.borderS

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      root.editingVariant = "light";
                      root.pickerTargetKey = modelData.key;
                      colorPicker.selectedColor = root.editingScheme?.light?.[modelData.key] ?? "#000000";
                      colorPicker.open();
                    }
                  }
                }
              }
            }
          }
        }
      }

      // Footer
      NBox {
        Layout.fillWidth: true
        implicitHeight: footerRow.implicitHeight + Style.margin2M

        RowLayout {
          id: footerRow
          anchors {
            fill: parent
            margins: Style.marginM
          }
          spacing: Style.marginM

          NTextInput {
            id: nameInput
            Layout.fillWidth: true
            placeholderText: pluginApi?.tr("panel.scheme-name-placeholder")
            onTextChanged: root.saveWip()
          }

          NButton {
            text: pluginApi?.tr("panel.preview")
            icon: root.previewActive ? "eye-off" : "eye"
            outlined: !root.previewActive
            onClicked: root.previewActive ? root.stopPreview() : root.startPreview()
          }

          NButton {
            text: pluginApi?.tr("panel.reset")
            outlined: true
            onClicked: root.seedEditor()
          }

          NButton {
            text: pluginApi?.tr("panel.save")
            icon: "device-floppy"
            enabled: nameInput.text.trim().length > 0
            onClicked: root.saveScheme()
          }
        }
      }
    }
  }
}
