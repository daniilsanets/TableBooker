import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import com.tablebooker.api 1.0
import "../components"
import "../Theme.js" as Theme

Page {
    id: page
    title: premisesName
    background: Rectangle { color: Theme.background }

    property int premisesId: -1
    property string premisesName: ""

    property int selectedIndex: -1
    property bool isWideScreen: width > 600

    ListModel { id: tablesModel }

    // --- АВТОСОХРАНЕНИЕ ---
    Timer {
        id: autoSaveTimer
        interval: 1000
        repeat: false
        onTriggered: saveTables()
    }

    function scheduleSave() {
        saveStatusLabel.text = "Сохранение..."
        saveStatusLabel.color = Theme.textSecondary
        autoSaveTimer.restart()
    }

    // --- ЛОГИКА ---
    function loadTables() {
        tablesModel.clear()
        var tables = BackendApi.getTablesForPremises(premisesId)
        for (var i = 0; i < tables.length; i++) {
            var t = tables[i]
            tablesModel.append({
                                   "dbId": t.id, "name": t.name, "x": t.x, "y": t.y,
                                   "width": t.width, "height": t.height,
                                   "type": t.type || "table",
                                   "rotation": t.rotation || 0,
                                   "color": t.color || "#81C784",
                                   "shapeType": t.shapeType || "rect"
                               })
        }
        Qt.callLater(function(){
            if (tables.length > 0) hallView.centerOnObjects()
        })
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
        if (success) {
            saveStatusLabel.text = "✓ Сохранено"
            saveStatusLabel.color = Theme.success
            resetStatusTimer.restart()
        } else {
            saveStatusLabel.text = "Ошибка сохранения!"
            saveStatusLabel.color = Theme.error
            console.log("Save failed. Hint: Reinstall app to update DB schema.")
        }
    }
    Timer { id: resetStatusTimer; interval: 2000; onTriggered: saveStatusLabel.text = "" }

    function addItem(itemType, w, h, namePrefix, shape, col) {
        var newName = namePrefix
        if (itemType === "table") {
            var count = 0
            for(var i=0; i<tablesModel.count; i++) { if (tablesModel.get(i).type === "table") count++ }
            newName = "Стол " + (count + 1)
        } else if (itemType === "room") {
            var rCount = 0
            for(var j=0; j<tablesModel.count; j++) { if (tablesModel.get(j).type === "room") rCount++ }
            newName = namePrefix || ("Зал " + (rCount + 1))
        }

        var center = hallView.viewportCenter()

        tablesModel.append({
                               "dbId": -1, "name": newName,
                               "x": center.x - w/2, "y": center.y - h/2,
                               "width": w, "height": h,
                               "rotation": 0, "type": itemType,
                               "shapeType": shape, "color": col
                           })

        selectedIndex = tablesModel.count - 1
        scheduleSave()
    }

    function duplicateSelected() {
        var item = getSelectedItem()
        if (!item) return
        tablesModel.append({
                               "dbId": -1, "name": item.name + " (копия)",
                               "x": item.x + 30, "y": item.y + 30,
                               "width": item.width, "height": item.height,
                               "rotation": item.rotation, "type": item.type,
                               "shapeType": item.shapeType, "color": item.color
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

    function getSelectedItem() {
        if (selectedIndex >= 0 && selectedIndex < tablesModel.count) return tablesModel.get(selectedIndex)
        return null
    }

    Component.onCompleted: loadTables()

    // --- UI ---

    header: ToolBar {
        background: Rectangle { color: Theme.surface }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8; anchors.rightMargin: 16

            ToolButton {
                Text { text: Theme.iconBack; font.pixelSize: 24; anchors.centerIn: parent; color: Theme.textPrimary }
                onClicked: { saveTables(); page.StackView.view.pop() }
            }

            Column {
                Layout.fillWidth: true
                spacing: 0
                Label {
                    text: page.title
                    font.bold: true; font.pixelSize: Theme.fontSizeLarge; color: Theme.textPrimary
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Label {
                    id: saveStatusLabel
                    text: ""
                    font.pixelSize: 10; color: Theme.textSecondary
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.bold: true
                }
            }

            ToolButton {
                visible: selectedIndex >= 0
                Text { text: "❐"; font.pixelSize: 20; anchors.centerIn: parent; color: Theme.primary }
                onClicked: duplicateSelected()
            }
        }
    }

    // 1. ХОЛСТ
    ZoomableHall {
        id: hallView
        anchors.fill: parent
        anchors.bottomMargin: (!isWideScreen && selectedIndex >= 0) ? propertySheet.height : 0
        anchors.rightMargin: (isWideScreen && selectedIndex >= 0) ? propertySheet.width : 0

        tablesModel: tablesModel
        editMode: true
        selectedIndex: page.selectedIndex

        onTableClicked: (idx, dbId) => {
                            page.selectedIndex = idx
                            addDrawer.close()
                        }

        onCanvasTapped: { page.selectedIndex = -1 }
        onTableModified: scheduleSave()

        Behavior on anchors.bottomMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on anchors.rightMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    }

    // 2. КНОПКА (+)
    Item {
        id: fabContainer
        width: 56; height: 56
        anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.margins: 24

        // Отступ снизу учитывает панель свойств
        property int bottomOffset: (!isWideScreen && selectedIndex >= 0) ? propertySheet.height + 24 : 24
        anchors.bottomMargin: bottomOffset

        visible: !addDrawer.visible
        property bool showClose: selectedIndex >= 0

        Rectangle {
            anchors.fill: parent; anchors.topMargin: 4
            radius: 28; color: "#000000"; opacity: 0.2
        }

        Button {
            anchors.fill: parent
            background: Rectangle {
                radius: 28
                color: fabContainer.showClose ? Theme.surface : Theme.accent
                border.width: fabContainer.showClose ? 1 : 0
                border.color: Theme.divider
            }
            contentItem: Text {
                text: fabContainer.showClose ? "✕" : "＋"
                font.pixelSize: 32;
                color: fabContainer.showClose ? Theme.textPrimary : "white";
                anchors.centerIn: parent
                font.bold: true
            }
            onClicked: {
                if (fabContainer.showClose) selectedIndex = -1
                else addDrawer.open()
            }
        }

        Behavior on anchors.bottomMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    }

    // 3. ПАНЕЛЬ СВОЙСТВ
    Rectangle {
        id: propertySheet
        width: isWideScreen ? 320 : parent.width
        height: isWideScreen ? parent.height : 320 // Чуть выше для удобства
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        transform: Translate {
            y: (!isWideScreen && selectedIndex < 0) ? propertySheet.height : 0
            x: (isWideScreen && selectedIndex < 0) ? propertySheet.width : 0
            Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        }

        color: Theme.surface

        // Тень
        Rectangle {
            visible: !isWideScreen
            anchors.bottom: parent.top; width: parent.width; height: 12
            gradient: Gradient { GradientStop { position: 0.0; color: "transparent" } GradientStop { position: 1.0; color: "#15000000" } }
        }

        ScrollView {
            anchors.fill: parent
            contentWidth: availableWidth // Блокируем горизонтальный скролл
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            clip: true

            ColumnLayout {
                width: parent.width; anchors.margins: 16
                spacing: 16

                // Отступ сверху
                Item { height: 8; width: 1 }

                // Заголовок
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 16; Layout.rightMargin: 16

                    TextField {
                        text: getSelectedItem() ? getSelectedItem().name : ""
                        placeholderText: "Название"
                        Layout.fillWidth: true
                        font.bold: true; font.pixelSize: Theme.fontSizeLarge
                        color: "black" // Явный черный цвет

                        background: Rectangle {
                            color: "transparent";
                            border.width: parent.activeFocus ? 2 : 1;
                            border.color: parent.activeFocus ? Theme.primary : Theme.divider;
                            radius: 8
                        }
                        onEditingFinished: setSelectedProperty("name", text)
                    }
                    Button {
                        text: Theme.iconDelete; flat: true; palette.buttonText: Theme.error; font.pixelSize: 22;
                        onClicked: removeSelected()
                    }
                }

                Rectangle { height: 1; Layout.fillWidth: true; color: Theme.divider }

                // Вращение
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 16; Layout.rightMargin: 16

                    Label { text: "Поворот"; color: Theme.textSecondary; font.pixelSize: 12 }
                    RowLayout {
                        spacing: 10; Layout.fillWidth: true
                        Button {
                            Layout.fillWidth: true; height: 40
                            background: Rectangle { color: parent.pressed ? Theme.primaryDark : Theme.primary; radius: 8 }
                            contentItem: Text { text: "↺ -45°"; color: "white"; font.bold: true; anchors.centerIn: parent }
                            onClicked: modifySelected("rotation", -45)
                        }
                        Button {
                            Layout.fillWidth: true; height: 40
                            background: Rectangle { color: parent.pressed ? Theme.primaryDark : Theme.primary; radius: 8 }
                            contentItem: Text { text: "+45° ↻"; color: "white"; font.bold: true; anchors.centerIn: parent }
                            onClicked: modifySelected("rotation", 45)
                        }
                    }
                }

                // Цвет
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 16; Layout.rightMargin: 16

                    Label { text: "Цвет"; color: Theme.textSecondary; font.pixelSize: 12 }
                    Flow {
                        Layout.fillWidth: true; spacing: 12
                        Repeater {
                            model: ["#81C784", "#64B5F6", "#FFB74D", "#E57373", "#BA68C8", "#90A4AE", "#4E342E", "#F5F5F5"]
                            delegate: Rectangle {
                                width: 36; height: 36; radius: 18
                                color: modelData
                                border.width: (getSelectedItem() && getSelectedItem().color == modelData) ? 3 : 1
                                border.color: (getSelectedItem() && getSelectedItem().color == modelData) ? Theme.primary : Theme.divider
                                MouseArea { anchors.fill: parent; onClicked: setSelectedProperty("color", modelData) }
                                Text {
                                    text: "✓"; color: "white"; anchors.centerIn: parent; font.bold: true
                                    visible: (getSelectedItem() && getSelectedItem().color == modelData)
                                }
                            }
                        }
                    }
                }

                // Форма и размер
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 16; Layout.rightMargin: 16

                    Label { text: "Параметры (Ш x В)"; color: Theme.textSecondary; font.pixelSize: 12 }
                    RowLayout {
                        Layout.fillWidth: true

                        Button {
                            text: "⬜"; Layout.preferredWidth: 50
                            background: Rectangle { color: (getSelectedItem() && getSelectedItem().shapeType === "rect") ? Theme.primaryLight : "transparent"; radius: 4; border.width: 1; border.color: Theme.divider }
                            onClicked: setSelectedProperty("shapeType", "rect");
                        }
                        Button {
                            text: "⚪"; Layout.preferredWidth: 50
                            background: Rectangle { color: (getSelectedItem() && getSelectedItem().shapeType === "ellipse") ? Theme.primaryLight : "transparent"; radius: 4; border.width: 1; border.color: Theme.divider }
                            onClicked: setSelectedProperty("shapeType", "ellipse");
                        }

                        Item { Layout.fillWidth: true }

                        // Поля размеров с ЧЕРНЫМ текстом
                        SpinBox {
                            id: wSpin
                            from: 10; to: 1000; stepSize: 10
                            value: getSelectedItem() ? getSelectedItem().width : 0
                            onValueModified: setSelectedProperty("width", value)
                            Layout.preferredWidth: 90
                            editable: true

                            contentItem: TextInput {
                                text: wSpin.textFromValue(wSpin.value, wSpin.locale)
                                font.pixelSize: Theme.fontSizeMedium
                                color: "black" // Черный цвет
                                selectionColor: Theme.primary
                                horizontalAlignment: Qt.AlignHCenter
                                verticalAlignment: Qt.AlignVCenter
                                readOnly: !wSpin.editable
                                validator: wSpin.validator
                                inputMethodHints: Qt.ImhDigitsOnly
                            }
                        }

                        Text { text: "x"; color: "black" }

                        SpinBox {
                            id: hSpin
                            from: 10; to: 1000; stepSize: 10
                            value: getSelectedItem() ? getSelectedItem().height : 0
                            onValueModified: setSelectedProperty("height", value)
                            Layout.preferredWidth: 90
                            editable: true

                            contentItem: TextInput {
                                text: hSpin.textFromValue(hSpin.value, hSpin.locale)
                                font.pixelSize: Theme.fontSizeMedium
                                color: "black" // Черный цвет
                                selectionColor: Theme.primary
                                horizontalAlignment: Qt.AlignHCenter
                                verticalAlignment: Qt.AlignVCenter
                                readOnly: !hSpin.editable
                                validator: hSpin.validator
                                inputMethodHints: Qt.ImhDigitsOnly
                            }
                        }
                    }
                }

                Item { height: 20; Layout.fillWidth: true } // Отступ снизу
            }
        }
    }

    // 4. МЕНЮ ДОБАВЛЕНИЯ (ИСПРАВЛЕННОЕ)
    Drawer {
        id: addDrawer
        width: isWideScreen ? 360 : parent.width
        height: parent.height
        edge: isWideScreen ? Qt.RightEdge : Qt.BottomEdge
        interactive: true

        property real mobileHeight: 400
        y: isWideScreen ? 0 : (visible ? parent.height - mobileHeight : parent.height)

        background: Rectangle {
            color: Theme.surface; radius: isWideScreen ? 0 : 16
        }

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 16; spacing: 16

            // Ручка (mobile only)
            Rectangle {
                visible: !isWideScreen
                Layout.alignment: Qt.AlignHCenter
                width: 40; height: 4; radius: 2; color: Theme.divider
            }

            Label { text: "Добавить объект"; font.bold: true; font.pixelSize: Theme.fontSizeLarge; color: "black"; Layout.alignment: Qt.AlignHCenter }

            GridLayout {
                columns: 3
                Layout.fillWidth: true; rowSpacing: 20; columnSpacing: 16

                Repeater {
                    model: ListModel {
                        // Исправил иконки и названия
                        ListElement { type: "table"; label: "Стол (Кв.)"; icon: "⬛"; w: 80; h: 80; color: "#81C784"; shape: "rect" }
                        ListElement { type: "table_round"; label: "Стол (Кр.)"; icon: "●"; w: 80; h: 80; color: "#81C784"; shape: "ellipse" }
                        ListElement { type: "room"; label: "Пол (Зал)"; icon: "⬚"; w: 300; h: 200; color: "#F5F5F5"; shape: "rect" }
                        ListElement { type: "wall"; label: "Стена"; icon: "▬"; w: 120; h: 15; color: "#424242"; shape: "rect" }
                        ListElement { type: "window"; label: "Окно"; icon: "🪟"; w: 80; h: 15; color: "#81D4FA"; shape: "rect" }
                        ListElement { type: "wc"; label: "WC"; icon: "🚽"; w: 60; h: 60; color: "#E0E0E0"; shape: "rect" }
                        ListElement { type: "plant"; label: "Декор"; icon: "🌿"; w: 50; h: 50; color: "transparent"; shape: "rect" }
                    }

                    delegate: Column {
                        spacing: 6
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true

                        Rectangle {
                            width: 64; height: 64; radius: 16
                            color: Theme.surfaceDark
                            border.color: mouseA.pressed ? Theme.primary : Theme.divider
                            border.width: mouseA.pressed ? 2 : 1
                            anchors.horizontalCenter: parent.horizontalCenter

                            Text { text: model.icon; font.pixelSize: 32; anchors.centerIn: parent }

                            MouseArea {
                                id: mouseA
                                anchors.fill: parent
                                onClicked: {
                                    var realType = (model.type === "table_round") ? "table" : model.type
                                    addItem(realType, model.w, model.h, "", model.shape, model.color)
                                    addDrawer.close()
                                }
                            }
                        }
                        Text { text: model.label; font.pixelSize: 12; color: Theme.textPrimary; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                }
            }
            Item { Layout.fillHeight: true }
        }
    }
}
