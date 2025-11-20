import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import com.tablebooker.api 1.0

Page {
    id: page
    title: "Редактор: " + premisesName

    property int premisesId: -1
    property string premisesName: ""
    property int selectedIndex: -1

    ListModel { id: tablesModel }

    // --- ЛОГИКА ---

    function loadTables() {
        tablesModel.clear()
        var tables = BackendApi.getTablesForPremises(premisesId)
        console.log("Загружено объектов:", tables.length)
        for (var i = 0; i < tables.length; i++) {
            var t = tables[i]
            tablesModel.append({
                "dbId": t.id, "name": t.name, "x": t.x, "y": t.y,
                "width": t.width, "height": t.height,
                "type": t.type || "table",
                "rotation": t.rotation || 0,
                "color": t.color || "#E0E0E0",
                "shapeType": t.shapeType || "rect"
            })
        }
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
        BackendApi.saveTableLayout(premisesId, tablesToSave)
    }

    // УМНОЕ ДОБАВЛЕНИЕ
    function addItem(itemType, w, h, namePrefix, shape, col) {
        // Генерируем имя
        var newName = ""
        if (itemType === "table") {
            // Считаем, сколько уже столов, чтобы дать номер T-5
            var count = 0
            for(var i=0; i<tablesModel.count; i++) {
                if (tablesModel.get(i).type === "table") count++
            }
            newName = "T-" + (count + 1)
        } else {
            newName = namePrefix
        }

        // Добавляем в центр видимой области (примерно)
        var centerX = flickable.contentX + 100
        var centerY = flickable.contentY + 100

        tablesModel.append({
            "dbId": -1, "name": newName,
            "x": centerX, "y": centerY,
            "width": w, "height": h,
            "rotation": 0, "type": itemType,
            "shapeType": shape, "color": col
        })
    }

    function modifySelected(param, value) {
        if (selectedIndex < 0) return
        var currentVal = tablesModel.get(selectedIndex)[param]
        tablesModel.setProperty(selectedIndex, param, currentVal + value)
    }

    function removeSelected() {
        if (selectedIndex >= 0) {
            tablesModel.remove(selectedIndex)
            selectedIndex = -1
        }
    }

    Component.onCompleted: loadTables()

    // --- ИНТЕРФЕЙС ---

    header: ToolBar {
        RowLayout {
            anchors.fill: parent
            ToolButton { text: "<- Назад"; onClicked: page.StackView.view.pop() }
            Label { text: page.title; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; font.bold: true }
            ToolButton { text: "Сохранить"; font.bold: true; onClicked: saveTables() }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // СЛЕВА: Область редактора (Flickable)
        Flickable {
            id: flickable
            Layout.fillHeight: true
            Layout.fillWidth: true
            clip: true

            // Размер поля делаем большим (3000x3000), чтобы можно было строить огромные схемы
            contentWidth: 3000
            contentHeight: 3000

            // Позволяет тянуть за любое свободное место
            interactive: true
            boundsBehavior: Flickable.StopAtBounds

            // СЕТКА (Рисуем кодом на Canvas размером с контент)
            Canvas {
                width: flickable.contentWidth
                height: flickable.contentHeight
                z: -10
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    ctx.strokeStyle = "#e0e0e0"
                    ctx.lineWidth = 1
                    ctx.beginPath()
                    for (var x = 0; x < width; x += 20) { ctx.moveTo(x, 0); ctx.lineTo(x, height); }
                    for (var y = 0; y < height; y += 20) { ctx.moveTo(0, y); ctx.lineTo(width, y); }
                    ctx.stroke()
                }
            }

            // Рендерим объекты
            Repeater {
                model: tablesModel
                delegate: EditableTableItem {
                    // Привязка свойств
                    x: model.x; y: model.y
                    width: model.width; height: model.height
                    rotation: model.rotation
                    type: model.type; shapeType: model.shapeType
                    text: model.name; itemColor: model.color

                    isSelected: index === page.selectedIndex

                    // Обратная связь (когда двигаем или ресайзим)
                    onXChanged: model.x = x
                    onYChanged: model.y = y
                    onWidthChanged: model.width = width
                    onHeightChanged: model.height = height

                    // Клик для выбора
                    MouseArea {
                        anchors.fill: parent
                        propagateComposedEvents: true
                        onClicked: (mouse) => {
                            page.selectedIndex = index
                            mouse.accepted = false
                        }
                        onPressed: (mouse) => {
                             page.selectedIndex = index
                             mouse.accepted = false
                        }
                    }
                }
            }
        }

        // СПРАВА: Панель инструментов
        Rectangle {
            Layout.preferredWidth: 140
            Layout.fillHeight: true
            color: "#f5f5f5"

            Rectangle { width: 1; color: "#bdbdbd"; anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom }

            ScrollView {
                anchors.fill: parent; anchors.leftMargin: 5
                clip: true

                ColumnLayout {
                    width: parent.width - 10; spacing: 8
                    Label { text: "Добавить:"; font.bold: true; Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 10 }

                    // Кнопки добавления
                    Button { text: "Стол (Круг)"; Layout.fillWidth: true;
                        onClicked: addItem("table", 80, 80, "", "ellipse", "#FFF59D") }

                    Button { text: "Стол (Кв)"; Layout.fillWidth: true;
                        onClicked: addItem("table", 80, 80, "", "rect", "#FFF59D") }

                    Button { text: "Комната (Пол)"; Layout.fillWidth: true;
                        // Создаем большой блок
                        onClicked: addItem("room", 400, 300, "Main Hall", "rect", "#FFFFFF") }

                    Button { text: "Стена"; Layout.fillWidth: true;
                        onClicked: addItem("wall", 150, 10, "", "rect", "#424242") }

                    Button { text: "Окно"; Layout.fillWidth: true;
                        onClicked: addItem("window", 100, 15, "", "rect", "#81D4FA") }

                    Button { text: "WC"; Layout.fillWidth: true;
                        onClicked: addItem("wc", 60, 60, "WC", "rect", "#FFFFFF") }

                    Button { text: "Декор 🌿"; Layout.fillWidth: true;
                        onClicked: addItem("plant", 50, 50, "", "rect", "transparent") }

                    Item { height: 20; Layout.fillWidth: true }

                    Label { text: "Свойства:"; font.bold: true; Layout.alignment: Qt.AlignHCenter; visible: selectedIndex >= 0 }

                    RowLayout {
                        visible: selectedIndex >= 0; Layout.alignment: Qt.AlignHCenter
                        Button { text: "↺"; Layout.preferredWidth: 40; onClicked: modifySelected("rotation", -45) }
                        Button { text: "↻"; Layout.preferredWidth: 40; onClicked: modifySelected("rotation", 45) }
                    }

                    Button {
                        text: "Удалить"; Layout.fillWidth: true; visible: selectedIndex >= 0
                        contentItem: Text { text: parent.text; color: "red"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        onClicked: removeSelected()
                    }
                }
            }
        }
    }
}
