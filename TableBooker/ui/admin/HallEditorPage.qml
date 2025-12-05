import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import com.tablebooker.api 1.0
import "../components"
import "../Theme.js" as Theme

Page {
    id: page
    title: premisesName
    background: Rectangle { color: "#F0F2F5" }

    property int premisesId: -1
    property string premisesName: ""
    property int selectedIndex: -1
    property bool showGrid: true

    ListModel { id: tablesModel }

    // --- ЛОГИКА (БЕЗ ИЗМЕНЕНИЙ) ---
    Timer {
        id: autoSaveTimer
        interval: 1000; repeat: false
        onTriggered: saveTables()
    }
    function scheduleSave() { statusText.text = "Сохранение..."; autoSaveTimer.restart() }

    function loadTables() {
        tablesModel.clear()
        var tables = BackendApi.getTablesForPremises(premisesId)
        for (var i = 0; i < tables.length; i++) {
            var t = tables[i]
            tablesModel.append({
                "dbId": t.id, "name": t.name, "x": t.x, "y": t.y,
                "width": t.width, "height": t.height,
                "type": t.type || "table", "rotation": t.rotation || 0,
                "color": t.color || "#81C784", "shapeType": t.shapeType || "rect"
            })
        }
        Qt.callLater(function(){ if (tables.length > 0) hallView.centerOnObjects() })
    }

    function saveTables() {
        var tablesToSave = []
        for (var i = 0; i < tablesModel.count; i++) {
            var t = tablesModel.get(i)
            tablesToSave.push({
                "id": t.dbId, "name": t.name, "x": t.x, "y": t.y,
                "width": t.width, "height": t.height,
                "type": t.type, "rotation": t.rotation,
                "color": t.color, "shapeType": t.shapeType
            })
        }
        var success = BackendApi.saveTableLayout(premisesId, tablesToSave)
        statusText.text = success ? "Все изменения сохранены" : "Ошибка сохранения"
    }

    // Функции добавления/изменения (аналогично прошлому разу)
    function addItem(itemType, w, h, namePrefix, shape, col) {
        var newName = namePrefix
        if (itemType === "table") {
            var count = 0
            for(var i=0; i<tablesModel.count; i++) { if (tablesModel.get(i).type === "table") count++ }
            newName = "Стол " + (count + 1)
        } else if (itemType === "room") newName = "Зона"

        var center = hallView.viewportCenter()
        tablesModel.append({
            "dbId": -1, "name": newName, "x": center.x - w/2, "y": center.y - h/2,
            "width": w, "height": h, "rotation": 0, "type": itemType, "shapeType": shape, "color": col
        })
        selectedIndex = tablesModel.count - 1
        scheduleSave()
    }

    function modifySelected(param, value) {
        if (selectedIndex < 0) return
        var currentVal = tablesModel.get(selectedIndex)[param]
        tablesModel.setProperty(selectedIndex, param, currentVal + value)
        scheduleSave()
    }

    function setSelectedProperty(param, value) {
        if (selectedIndex < 0) return
        if (tablesModel.get(selectedIndex)[param] !== value) {
            tablesModel.setProperty(selectedIndex, param, value)
            scheduleSave()
        }
    }

    function removeSelected() {
        if (selectedIndex >= 0) {
            tablesModel.remove(selectedIndex)
            selectedIndex = -1
            scheduleSave()
        }
    }

    function duplicateSelected() {
        var item = getSelectedItem()
        if (!item) return
        tablesModel.append({
            "dbId": -1, "name": item.name + " (копия)",
            "x": item.x + 20, "y": item.y + 20,
            "width": item.width, "height": item.height,
            "rotation": item.rotation, "type": item.type,
            "shapeType": item.shapeType, "color": item.color
        })
        selectedIndex = tablesModel.count - 1
        scheduleSave()
    }

    function getSelectedItem() {
        if (selectedIndex >= 0 && selectedIndex < tablesModel.count) return tablesModel.get(selectedIndex)
        return null
    }

    Component.onCompleted: loadTables()

    // --- ИНТЕРФЕЙС ---
    header: Item { height: 0 }

    // Хедер
    Rectangle {
        id: topBar
        width: parent.width - 32; height: 50
        anchors.top: parent.top; anchors.topMargin: 16; anchors.horizontalCenter: parent.horizontalCenter
        z: 100; radius: 25; color: Theme.surface
        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#15000000"; shadowBlur: 10; shadowVerticalOffset: 4 }

        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 4; anchors.rightMargin: 16; spacing: 8

            // Кнопка назад
            Button {
                Layout.preferredWidth: 42; Layout.preferredHeight: 42
                background: Rectangle { radius: 21; color: parent.pressed ? "#F5F5F5" : "transparent" }
                contentItem: Text {
                    text: Theme.iconBack; font.pixelSize: 20; color: Theme.textPrimary;
                    anchors.centerIn: parent; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }
                onClicked: { saveTables(); page.StackView.view.pop() }
            }

            Text { text: page.premisesName; font.bold: true; font.pixelSize: Theme.fontSizeMedium; color: Theme.textPrimary; Layout.fillWidth: true }
            Text { id: statusText; text: "Готово"; font.pixelSize: 10; color: Theme.success }

            // Кнопка сетки
            Button {
                Layout.preferredWidth: 42; Layout.preferredHeight: 42
                background: Rectangle { radius: 21; color: showGrid ? Theme.primaryLight : "transparent"; opacity: showGrid ? 0.2 : 1 }
                contentItem: Text {
                    text: "#"; font.bold: true; color: showGrid ? Theme.primary : Theme.textSecondary;
                    anchors.centerIn: parent; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }
                onClicked: showGrid = !showGrid
            }
        }
    }

    // Холст
    ZoomableHall {
        id: hallView
        anchors.fill: parent
        anchors.bottomMargin: propertyPanel.visible ? propertyPanel.height : 0
        tablesModel: tablesModel
        editMode: true
        selectedIndex: page.selectedIndex
        onTableClicked: (idx, dbId) => { page.selectedIndex = idx; addItemSheet.close() }
        onCanvasTapped: { page.selectedIndex = -1 }
        onTableModified: scheduleSave()
        Behavior on anchors.bottomMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    }

    // FAB
    Rectangle {
        id: fab
        width: 56; height: 56; radius: 28; color: Theme.accent
        anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 24
        visible: selectedIndex === -1 && !addItemSheet.visible
        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#40000000"; shadowBlur: 10; shadowVerticalOffset: 4 }
        Text { text: "+"; font.pixelSize: 32; color: "white"; anchors.centerIn: parent }
        MouseArea { anchors.fill: parent; onClicked: addItemSheet.open() }
    }

    // ПАНЕЛЬ СВОЙСТВ
    Rectangle {
        id: propertyPanel
        width: parent.width; height: 280; color: Theme.surface
        anchors.bottom: parent.bottom
        y: selectedIndex >= 0 ? 0 : height
        visible: selectedIndex >= 0; z: 200
        radius: 20
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 20; color: Theme.surface }
        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#15000000"; shadowBlur: 20; shadowVerticalOffset: -5 }

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 20; spacing: 16

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Rectangle { width: 40; height: 40; radius: 12; color: getSelectedItem() ? getSelectedItem().color : "#eee"; Text { text: "✏️"; anchors.centerIn: parent } }

                TextField {
                    Layout.fillWidth: true; text: getSelectedItem() ? getSelectedItem().name : ""; placeholderText: "Название"
                    font.bold: true; font.pixelSize: 16; color: Theme.textPrimary
                    background: Rectangle { color: Theme.surfaceDark; radius: 8; border.color: parent.activeFocus ? Theme.primary : "transparent"; border.width: 2 }
                    onEditingFinished: setSelectedProperty("name", text)
                }

                Button {
                    Layout.preferredWidth: 40; Layout.preferredHeight: 40
                    background: Rectangle { color: "#F5F5F5"; radius: 12 }
                    contentItem: Text {
                        text: "❐"; color: Theme.textPrimary; anchors.centerIn: parent;
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: duplicateSelected()
                }

                Button {
                    Layout.preferredWidth: 40; Layout.preferredHeight: 40
                    background: Rectangle { color: "#FFEBEE"; radius: 12 }
                    contentItem: Text {
                        text: Theme.iconDelete; color: Theme.error; anchors.centerIn: parent;
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: removeSelected()
                }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 20
                ColumnLayout {
                    Layout.fillWidth: true
                    Text { text: "Поворот: " + (getSelectedItem() ? getSelectedItem().rotation : 0) + "°"; font.pixelSize: 12; color: Theme.textSecondary }
                    Slider {
                        Layout.fillWidth: true; from: 0; to: 360; stepSize: 15
                        value: getSelectedItem() ? getSelectedItem().rotation : 0
                        onMoved: { if(getSelectedItem()) setSelectedProperty("rotation", value) }
                        background: Rectangle {
                            x: parent.leftPadding; y: parent.topPadding + parent.availableHeight / 2 - height / 2
                            width: parent.availableWidth; height: 4; radius: 2; color: "#E0E0E0"
                            Rectangle { width: parent.visualPosition * parent.width; height: 4; color: Theme.primary; radius: 2 }
                        }
                        handle: Rectangle {
                            x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                            y: parent.topPadding + parent.availableHeight / 2 - height / 2
                            width: 20; height: 20; radius: 10; color: "white"; border.color: Theme.primary; border.width: 2
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Text { text: "Размер"; font.pixelSize: 12; color: Theme.textSecondary }
                    RowLayout {
                        Button {
                            Layout.preferredWidth: 30; Layout.preferredHeight: 30
                            background: Rectangle { radius: 15; color: "#F5F5F5" }
                            contentItem: Text { text: "-"; font.bold: true; anchors.centerIn: parent; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            onClicked: { modifySelected("width", -10); modifySelected("height", -10) }
                        }
                        Text { text: getSelectedItem() ? Math.round(getSelectedItem().width) : "0"; font.bold: true }
                        Button {
                            Layout.preferredWidth: 30; Layout.preferredHeight: 30
                            background: Rectangle { radius: 15; color: "#F5F5F5" }
                            contentItem: Text { text: "+"; font.bold: true; anchors.centerIn: parent; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            onClicked: { modifySelected("width", 10); modifySelected("height", 10) }
                        }
                    }
                }
            }

            ScrollView {
                Layout.fillWidth: true; Layout.preferredHeight: 50
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                RowLayout {
                    spacing: 10
                    Rectangle {
                        width: 80; height: 40; radius: 20; color: "#F5F5F5"
                        Row {
                            anchors.centerIn: parent; spacing: 10
                            Text { text: "⬜"; font.pixelSize: 18; opacity: (getSelectedItem() && getSelectedItem().shapeType === "rect") ? 1 : 0.3; MouseArea { anchors.fill: parent; onClicked: setSelectedProperty("shapeType", "rect") } }
                            Text { text: "⚪"; font.pixelSize: 18; opacity: (getSelectedItem() && getSelectedItem().shapeType === "ellipse") ? 1 : 0.3; MouseArea { anchors.fill: parent; onClicked: setSelectedProperty("shapeType", "ellipse") } }
                        }
                    }
                    Repeater {
                        model: ["#81C784", "#64B5F6", "#FFB74D", "#E57373", "#BA68C8", "#90A4AE", "#4E342E"]
                        delegate: Rectangle {
                            width: 36; height: 36; radius: 18; color: modelData
                            border.width: (getSelectedItem() && getSelectedItem().color == modelData) ? 3 : 0
                            border.color: Theme.primary
                            scale: (getSelectedItem() && getSelectedItem().color == modelData) ? 1.1 : 1.0
                            Behavior on scale { NumberAnimation { duration: 150 } }
                            MouseArea { anchors.fill: parent; onClicked: setSelectedProperty("color", modelData) }
                        }
                    }
                }
            }
        }
    }

    // --- МЕНЮ ДОБАВЛЕНИЯ ---
    Drawer {
        id: addItemSheet
        width: parent.width; height: 380; edge: Qt.BottomEdge; interactive: true
        background: Rectangle { color: Theme.surface; radius: 20; Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 20; color: Theme.surface } }

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 20; spacing: 20
            Rectangle { Layout.alignment: Qt.AlignHCenter; width: 40; height: 4; radius: 2; color: Theme.divider }
            Text { text: "Что добавим?"; font.bold: true; font.pixelSize: 18; color: Theme.textPrimary }

            GridLayout {
                columns: 4; Layout.fillWidth: true; rowSpacing: 16; columnSpacing: 16
                Repeater {
                    model: ListModel {
                        ListElement { label: "Стол 4"; icon: "🪑"; type: "table"; w: 80; h: 80; shape: "rect"; color: "#81C784" }
                        ListElement { label: "Круг"; icon: "⚪"; type: "table"; w: 90; h: 90; shape: "ellipse"; color: "#81C784" }
                        ListElement { label: "Стол 2"; icon: "☕"; type: "table"; w: 60; h: 60; shape: "rect"; color: "#FFF176" }
                        ListElement { label: "Большой"; icon: "🍽️"; type: "table"; w: 140; h: 80; shape: "rect"; color: "#FFB74D" }
                        ListElement { label: "Стена"; icon: "🧱"; type: "wall"; w: 120; h: 10; shape: "rect"; color: "#424242" }
                        ListElement { label: "Окно"; icon: "🪟"; type: "window"; w: 100; h: 10; shape: "rect"; color: "#81D4FA" }
                        ListElement { label: "Пол"; icon: "⬚"; type: "room"; w: 300; h: 200; shape: "rect"; color: "#F5F5F5" }
                        ListElement { label: "WC"; icon: "🚻"; type: "wc"; w: 60; h: 60; shape: "rect"; color: "#BDBDBD" }
                    }
                    delegate: Column {
                        Layout.alignment: Qt.AlignHCenter; spacing: 6
                        Rectangle {
                            width: 60; height: 60; radius: 16; color: Theme.surfaceDark
                            border.color: mouseArea.pressed ? Theme.primary : "transparent"; border.width: 2
                            Text { text: model.icon; font.pixelSize: 28; anchors.centerIn: parent }
                            MouseArea {
                                id: mouseArea; anchors.fill: parent
                                onClicked: { addItem(model.type, model.w, model.h, "", model.shape, model.color); addItemSheet.close() }
                            }
                        }
                        Text { text: model.label; font.pixelSize: 11; color: Theme.textSecondary; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                }
            }
            Item { Layout.fillHeight: true }
        }
    }
}
