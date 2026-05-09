import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
  id: root
  implicitWidth: 600
  implicitHeight: 500
  property var pluginApi: null

  readonly property var cs: pluginApi?.pluginSettings?.claude || ({})

  function set(key, value) {
    if (!pluginApi) { return; }
    if (!pluginApi.pluginSettings.claude) { pluginApi.pluginSettings.claude = {}; }
    pluginApi.pluginSettings.claude[key] = value;
    pluginApi.saveSettings();
  }

  function setTop(key, value) {
    if (!pluginApi) { return; }
    pluginApi.pluginSettings[key] = value;
    pluginApi.saveSettings();
  }

  function parseList(raw) {
    if (!raw) { return []; }
    return String(raw).split(/[,\n]/).map(function (s) { return s.trim(); }).filter(function (s) { return s !== ""; });
  }

  NScrollView {
    id: scroller
    anchors.fill: parent
    contentWidth: availableWidth
    clip: true

    ColumnLayout {
      width: root.width
      spacing: Style.marginL

      // ===== GENERAL =====
      NText { text: pluginApi?.tr("settings.sectionGeneral"); font.weight: Font.Bold; pointSize: Style.fontSizeL }

      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.binary")
        text: cs.binary || "claude"
        onEditingFinished: set("binary", text)
      }

      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.workingDir")
        description: pluginApi?.tr("settings.workingDirHelp")
        text: cs.workingDir || ""
        placeholderText: "/home/you/project"
        onEditingFinished: set("workingDir", text)
      }

      // ===== PERMISSIONS =====
      NText { text: pluginApi?.tr("settings.sectionPermissions"); font.weight: Font.Bold; pointSize: Style.fontSizeL }

      NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.permissionMode")
        model: [
          { key: "default",           name: pluginApi?.tr("settings.permModeDefault") },
          { key: "acceptEdits",       name: pluginApi?.tr("settings.permModeAccept") },
          { key: "plan",              name: pluginApi?.tr("settings.permModePlan") },
          { key: "bypassPermissions", name: pluginApi?.tr("settings.permModeBypass") }
        ]
        currentKey: cs.permissionMode || "default"
        onSelected: key => {
          if (key === "bypassPermissions" && (cs.requireConfirmBypass !== false)) {
            bypassConfirm.open();
          } else {
            set("permissionMode", key);
          }
        }
      }

      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.allowedTools")
        description: pluginApi?.tr("settings.allowedToolsHelp")
        text: (cs.allowedTools || []).join(",")
        placeholderText: "Read,Edit,Bash(git:*),WebFetch"
        onEditingFinished: set("allowedTools", parseList(text))
      }

      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.disallowedTools")
        text: (cs.disallowedTools || []).join(",")
        placeholderText: "Bash(rm:*),WebFetch"
        onEditingFinished: set("disallowedTools", parseList(text))
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
          label: pluginApi?.tr("settings.additionalDirs")
          description: pluginApi?.tr("settings.additionalDirsHelp")
        }
        TextArea {
          Layout.fillWidth: true
          Layout.preferredHeight: 72
          text: (cs.additionalDirs || []).join("\n")
          placeholderText: "/home/you/notes\n/tmp/scratch"
          onEditingFinished: set("additionalDirs", parseList(text))
        }
      }

      // Dangerously-skip toggle — always last, visually separated
      Rectangle {
        Layout.fillWidth: true
        color: cs.dangerouslySkipPermissions ? Qt.rgba(0.9, 0.2, 0.2, 0.15) : "transparent"
        border.color: cs.dangerouslySkipPermissions ? Color.mError : Color.mOutline
        border.width: Style.borderS
        radius: Style.radiusM
        implicitHeight: dangerousCol.implicitHeight + Style.marginS * 2

        ColumnLayout {
          id: dangerousCol
          anchors.fill: parent
          anchors.margins: Style.marginS
          spacing: Style.marginXS

          NCheckbox {
            Layout.fillWidth: true
            label: pluginApi?.tr("settings.dangerouslySkip")
            description: pluginApi?.tr("settings.dangerouslySkipHelp")
            checked: cs.dangerouslySkipPermissions === true
            onToggled: checked => {
              if (checked) { bypassConfirm.forSkip = true; bypassConfirm.open(); }
              else         { set("dangerouslySkipPermissions", false); }
            }
          }
          NCheckbox {
            Layout.fillWidth: true
            label: pluginApi?.tr("settings.confirmBypass")
            checked: cs.requireConfirmBypass !== false
            onToggled: checked => set("requireConfirmBypass", checked)
          }
        }
      }

      // ===== SESSION & MODEL =====
      NText { text: pluginApi?.tr("settings.sectionSession"); font.weight: Font.Bold; pointSize: Style.fontSizeL }

      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.model")
        description: pluginApi?.tr("settings.modelHelp")
        text: cs.model || ""
        placeholderText: "claude-opus-4-7"
        onEditingFinished: set("model", text)
      }

      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.fallbackModel")
        text: cs.fallbackModel || ""
        placeholderText: "claude-sonnet-4-6"
        onEditingFinished: set("fallbackModel", text)
      }

      NCheckbox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.autoResume")
        checked: cs.autoResume !== false
        onToggled: checked => set("autoResume", checked)
      }

      NSpinBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.maxTurns")
        from: 0
        to: 9999
        stepSize: 1
        value: cs.maxTurns || 0
        onValueChanged: set("maxTurns", value)
      }

      NCheckbox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.includePartialMessages")
        checked: cs.includePartialMessages === true
        onToggled: checked => set("includePartialMessages", checked)
      }

      NCheckbox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.injectNoctaliaContext")
        description: pluginApi?.tr("settings.injectNoctaliaContextHelp")
        checked: cs.injectNoctaliaContext !== false
        onToggled: checked => set("injectNoctaliaContext", checked)
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
          label: pluginApi?.tr("settings.appendSystemPrompt")
        }
        TextArea {
          Layout.fillWidth: true
          Layout.preferredHeight: 72
          text: cs.appendSystemPrompt || ""
          onEditingFinished: set("appendSystemPrompt", text)
        }
      }

      // ===== MCP =====
      NText { text: pluginApi?.tr("settings.sectionMcp"); font.weight: Font.Bold; pointSize: Style.fontSizeL }

      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.mcpConfigPath")
        text: cs.mcpConfigPath || ""
        placeholderText: "/home/you/.config/claude/mcp.json"
        onEditingFinished: set("mcpConfigPath", text)
      }

      NCheckbox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.mcpStrict")
        checked: cs.strictMcpConfig === true
        onToggled: checked => set("strictMcpConfig", checked)
      }

      // ===== PANEL =====
      NText { text: pluginApi?.tr("settings.sectionPanel"); font.weight: Font.Bold; pointSize: Style.fontSizeL }

      NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.panelPosition")
        model: [
          { key: "right",  name: "right" },
          { key: "left",   name: "left" },
          { key: "center", name: "center" },
          { key: "top",    name: "top" },
          { key: "bottom", name: "bottom" }
        ]
        currentKey: pluginApi?.pluginSettings?.panelPosition || "right"
        onSelected: key => setTop("panelPosition", key)
      }

      NCheckbox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.panelDetached")
        checked: pluginApi?.pluginSettings?.panelDetached ?? true
        onToggled: checked => setTop("panelDetached", checked)
      }

      NSpinBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.panelWidth")
        from: 320
        to: 1600
        stepSize: 10
        value: pluginApi?.pluginSettings?.panelWidth ?? 620
        onValueChanged: setTop("panelWidth", value)
      }

      NSpinBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.panelHeightRatio")
        from: 30
        to: 100
        stepSize: 1
        value: Math.round((pluginApi?.pluginSettings?.panelHeightRatio ?? 0.9) * 100)
        onValueChanged: setTop("panelHeightRatio", value / 100)
      }
    }
  }

  // ----- Bypass confirmation dialog -----
  Dialog {
    id: bypassConfirm
    modal: true
    title: "Confirm"
    width: 420
    property bool forSkip: false

    contentItem: ColumnLayout {
      spacing: Style.marginS
      NText {
        text: bypassConfirm.forSkip
              ? pluginApi?.tr("dialog.bypassSkipWarning")
              : pluginApi?.tr("dialog.bypassModeWarning")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        color: Color.mError
      }
      NText {
        text: pluginApi?.tr("dialog.proceed")
        font.weight: Font.Bold
      }
    }

    standardButtons: Dialog.Ok | Dialog.Cancel
    onAccepted: {
      if (forSkip) {
        set("dangerouslySkipPermissions", true);
        ToastService.showError(pluginApi?.tr("toast.bypassEnabled"));
      } else {
        set("permissionMode", "bypassPermissions");
        ToastService.showError(pluginApi?.tr("toast.bypassEnabled"));
      }
      forSkip = false;
    }
    onRejected: {
      ToastService.showNotice(pluginApi?.tr("toast.bypassCancelled"));
      forSkip = false;
    }
  }
}
