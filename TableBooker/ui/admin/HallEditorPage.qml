import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import com.tablebooker.api 1.0
import "../components"

Page {
    id: page
    property int premisesId: -1
    property string premisesName: ""
    property int selectedIndex: -1 // Индекс выделенного объекта в модели

    title: premisesName

    ListModel { id: tablesModel }

    // --- ЛОГИКА ДАННЫХ (из вашего кода) ---
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

    // Умное добавление (адаптировано под мобилку)
    function addItem(itemType, w, h, namePrefix, shape, col) {
        // Генерируем имя
        var newName = namePrefix
        if (itemType === "table") {
            var count = 0
            for(var i=0; i<tablesModel.count; i++) {
                if (tablesModel.get(i).type === "table") count++
            }
            newName = "T-" + (count + 1)
        }

        // Добавляем в центр экрана (учитывая скролл ZoomableHall)
        // Доступ к flickable внутри ZoomableHall сложен, упростим:
        var centerX = 500 // Или брать из hallView.contentX
        var centerY = 500

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
        background: Rectangle { color: "white" }
        RowLayout {
            anchors.fill: parent
            ToolButton { text: "←"; onClicked: page.StackView.view.pop() }
            Label { text: page.title; font.bold: true; Layout.fillWidth: true }
            Button {
                text: "Сохранить"
                flat: true
                font.bold: true
                palette.buttonText: "#2196F3"
                onClicked: saveTables()
            }
        }
    }

    // 1. ОСНОВНОЕ ПОЛЕ (ЗУМ И СКРОЛЛ)
    ZoomableHall {
        id: hallView
        anchors.fill: parent
        tablesModel: tablesModel
        editMode: true

        // Прокидываем индекс выделения внутрь компонента (если добавили свойство)
        // property alias selectedIndex: page.selectedIndex (в ZoomableHall)

        onTableClicked: (idx, dbId) => {
            console.log("Выбран индекс:", idx)
            page.selectedIndex = idx
        }

        onCanvasTapped: {
            page.selectedIndex = -1 // Сброс выделения
        }
    }

    // 2. ПАНЕЛЬ СВОЙСТВ (Появляется снизу, когда выбран предмет)
    Rectangle {
        id: propertiesPanel
        width: parent.width
        height: 80
        color: "white"
        anchors.bottom: parent.bottom
        visible: page.selectedIndex >= 0 // Видна только при выделении
        z: 200

        // Тень сверху панели
        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: true; shadowVerticalOffset: -2; shadowBlur: 0.2 }

        RowLayout {
            anchors.centerIn: parent
            spacing: 30

            ToolButton {
                text: "↺ -45°"
                font.bold: true
                onClicked: modifySelected("rotation", -45)
            }

            Label { text: "Правка"; font.bold: true; color: "gray" }

            ToolButton {
                text: "↻ +45°"
                font.bold: true
                onClicked: modifySelected("rotation", 45)
            }

            ToolButton {
                text: "🗑️"
                palette.buttonText: "red"
                onClicked: removeSelected()
            }
        }
    }

    // 3. FAB - Кнопка "Добавить" (Скрываем, если открыта панель свойств)
    RoundButton {
        text: "+"
        font.pixelSize: 30
        width: 56; height: 56; radius: 28
        highlighted: true
        palette.button: "#FF5722"
        palette.buttonText: "white"

        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 20
        visible: page.selectedIndex === -1 // Скрываем, когда редактируем объект

        onClicked: addDrawer.open()
    }

    // 4. МЕНЮ ДОБАВЛЕНИЯ (Drawer)
    Drawer {
        id: addDrawer
        width: parent.width
        height: 350 // Повыше, чтобы всё влезло
        edge: Qt.BottomEdge

        background: Rectangle { color: "white"; radius: 16 }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            Label { text: "Добавить объект"; font.bold: true; font.pixelSize: 18; Layout.alignment: Qt.AlignHCenter }

            GridLayout {
                columns: 3
                columnSpacing: 10
                rowSpacing: 10
                Layout.fillWidth: true

                // ГЕНЕРАТОР КНОПОК
                // Столы
                Button { text: "Стол (Круг)"; Layout.fillWidth: true; onClicked: { addItem("table", 80, 80, "", "ellipse", "#FFF59D"); addDrawer.close() } }
                Button { text: "Стол (Кв)"; Layout.fillWidth: true; onClicked: { addItem("table", 80, 80, "", "rect", "#FFF59D"); addDrawer.close() } }

                // Помещения
                Button { text: "Пол (Зал)"; Layout.fillWidth: true; onClicked: { addItem("room", 400, 300, "Main Hall", "rect", "#FFFFFF"); addDrawer.close() } }

                // Стены и окна
                Button { text: "Стена"; Layout.fillWidth: true; onClicked: { addItem("wall", 150, 10, "", "rect", "#424242"); addDrawer.close() } }
                Button { text: "Окно"; Layout.fillWidth: true; onClicked: { addItem("window", 100, 15, "", "rect", "#81D4FA"); addDrawer.close() } }

                // Прочее
                Button { text: "WC"; Layout.fillWidth: true; onClicked: { addItem("wc", 60, 60, "WC", "rect", "#FFFFFF"); addDrawer.close() } }
                Button { text: "Декор 🌿"; Layout.fillWidth: true; onClicked: { addItem("plant", 50, 50, "", "rect", "transparent"); addDrawer.close() } }
            }
        }
    }
}
