import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

RowLayout {
  id: root

  // The active model used for the popup list (source model or filtered results)
  readonly property var activeModel: isFiltered ? filteredModel : root.model
  property string currentKey: ""

  // Filtered model for search results
  property ListModel filteredModel: ListModel {
  }

  // Whether we're using filtered results or the source model directly
  property bool isFiltered: false
  property real minimumWidth: 280
  property ListModel model: ListModel {
  }
  property string placeholder: ""
  property real popupHeight: 180
  readonly property real preferredHeight: Math.round(Style.baseWidgetSize * 1.1)
  property string searchPlaceholder: "Search..."
  property string searchText: ""

  signal selected(string key)

  function filterModel() {
    // Check if model exists and has items
    if (!root.model || root.model.count === undefined || root.model.count === 0) {
      filteredModel.clear();
      isFiltered = false;
      return;
    }

    var query = searchText.trim();
    if (query === "") {
      // No search text - use source model directly, don't copy
      filteredModel.clear();
      isFiltered = false;
      return;
    }

    // We have search text - need to filter
    isFiltered = true;
    filteredModel.clear();

    // Convert ListModel to array for fuzzy search
    var items = [];
    for (var i = 0; i < root.model.count; i++) {
      items.push(root.model.get(i));
    }

    // Use fuzzy search if available, fallback to simple search
    if (typeof FuzzySort !== 'undefined') {
      var fuzzyResults = FuzzySort.go(query, items, {
        "key": "name",
        "threshold": -1000,
        "limit": 50
      });

      // Add results in order of relevance
      for (var j = 0; j < fuzzyResults.length; j++) {
        filteredModel.append(fuzzyResults[j].obj);
      }
    } else {
      // Fallback to simple search
      var searchLower = query.toLowerCase();
      for (var i = 0; i < items.length; i++) {
        var item = items[i];
        if (item.name.toLowerCase().includes(searchLower)) {
          filteredModel.append(item);
        }
      }
    }
  }
  function findIndexByKey(key) {
    if (!root.model)
      return -1;
    for (var i = 0; i < root.model.count; i++) {
      if (root.model.get(i).key === key) {
        return i;
      }
    }
    return -1;
  }
  function findIndexInActiveModel(key) {
    if (!activeModel || activeModel.count === undefined)
      return -1;
    for (var i = 0; i < activeModel.count; i++) {
      if (activeModel.get(i).key === key) {
        return i;
      }
    }
    return -1;
  }

  onSearchTextChanged: filterModel()

  ComboBox {
    id: combo

    Layout.fillWidth: true
    Layout.minimumWidth: Math.round(root.minimumWidth * Style.uiScaleRatio)
    Layout.preferredHeight: Math.round(root.preferredHeight * Style.uiScaleRatio)
    currentIndex: findIndexInActiveModel(currentKey)
    model: root.activeModel

    background: Rectangle {
      border.color: combo.activeFocus ? Color.mSecondary : Color.mOutline
      border.width: Style.borderS
      color: Color.mSurface
      // implicitWidth: Math.round(Style.baseWidgetSize * 3.75 * Style.uiScaleRatio)
      implicitHeight: Math.round(root.preferredHeight * Style.uiScaleRatio)
      radius: Style.iRadiusM

      Behavior on border.color {
        ColorAnimation {
          duration: Style.animationFast
        }
      }
    }
    contentItem: NText {
      readonly property bool hasSelection: root.model && sourceIndex >= 0 && sourceIndex < root.model.count

      // Look up current selection directly in source model by key
      readonly property int sourceIndex: root.findIndexByKey(root.currentKey)

      color: hasSelection ? Color.mOnSurface : Color.mOnSurfaceVariant
      elide: Text.ElideRight
      leftPadding: Style.marginL
      pointSize: Style.fontSizeM
      rightPadding: combo.indicator.width + Style.marginL
      text: hasSelection ? root.model.get(sourceIndex).name : root.placeholder
      verticalAlignment: Text.AlignVCenter
    }
    indicator: NIcon {
      icon: "caret-down"
      pointSize: Style.fontSizeL
      x: combo.width - width - Style.marginM
      y: combo.topPadding + (combo.availableHeight - height) / 2
    }
    popup: Popup {
      height: Math.round((root.popupHeight + 60) * Style.uiScaleRatio)
      padding: Style.marginM
      width: combo.width
      y: combo.height + Style.marginS

      background: Rectangle {
        border.color: Color.mOutline
        border.width: Style.borderS
        color: Color.mSurfaceVariant
        radius: Style.iRadiusM
      }
      contentItem: ColumnLayout {
        spacing: Style.marginS

        // Search input
        NTextInput {
          id: searchInput

          Layout.fillWidth: true
          fontSize: Style.fontSizeS
          inputIconName: "search"
          placeholderText: root.searchPlaceholder
          text: root.searchText

          onTextChanged: root.searchText = text
        }
        NListView {
          id: listView

          Layout.fillHeight: true
          Layout.fillWidth: true
          horizontalPolicy: ScrollBar.AlwaysOff
          // Use activeModel (source model when not filtering, filtered results when searching)
          model: combo.popup.visible ? root.activeModel : null
          verticalPolicy: ScrollBar.AsNeeded

          delegate: ItemDelegate {
            id: delegateRoot

            bottomPadding: Style.marginS
            highlighted: ListView.view.currentIndex === index
            hoverEnabled: true
            leftPadding: Style.marginM
            rightPadding: Style.marginM
            topPadding: Style.marginS
            width: listView.width

            background: Rectangle {
              anchors.fill: parent
              color: highlighted ? Color.mHover : "transparent"
              radius: Style.iRadiusS

              Behavior on color {
                ColorAnimation {
                  duration: Style.animationFast
                }
              }
            }
            contentItem: NText {
              color: highlighted ? Color.mOnHover : Color.mOnSurface
              elide: Text.ElideRight
              pointSize: Style.fontSizeM
              text: name
              verticalAlignment: Text.AlignVCenter

              Behavior on color {
                ColorAnimation {
                  duration: Style.animationFast
                }
              }
            }

            onClicked: {
              var selectedKey = listView.model.get(index).key;
              root.selected(selectedKey);
              combo.popup.close();
            }
            onHoveredChanged: {
              if (hovered) {
                ListView.view.currentIndex = index;
              }
            }
          }
        }
      }
    }

    onActivated: {
      if (combo.currentIndex >= 0 && root.activeModel && combo.currentIndex < root.activeModel.count) {
        root.selected(root.activeModel.get(combo.currentIndex).key);
      }
    }

    // Update the currentIndex if the currentKey is changed externally
    Connections {
      function onCurrentKeyChanged() {
        combo.currentIndex = root.findIndexInActiveModel(root.currentKey);
      }

      target: root
    }

    // Focus search input when popup opens and ensure model is filtered
    Connections {
      function onVisibleChanged() {
        if (combo.popup.visible) {
          // Ensure the model is filtered when popup opens
          filterModel();
          // Small delay to ensure the popup is fully rendered
          Qt.callLater(() => {
            if (searchInput && searchInput.inputItem) {
              searchInput.inputItem.forceActiveFocus();
            }
          });
        }
      }

      target: combo.popup
    }
  }
}
