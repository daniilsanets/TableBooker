import QtQuick 2.15
import QtQuick.Controls 2.15
import com.tablebooker.api 1.0

Page {
    id: page
    property int premisesId: -1
    property string premisesName: ""

    title: "Редактор: " + premisesName

    // Модель для хранения столиков на экране
    ListModel {
        id: tablesModel
    }

    // 1. ЗАГРУЗКА ДАННЫХ
    function loadTables() {
        tablesModel.clear()
        // Получаем список из C++
        var tables = BackendApi.getTablesForPremises(premisesId)
        console.log("Загружено столов:", tables.length)

        for (var i = 0; i < tables.length; i++) {
            var t = tables[i]
            // Добавляем в ListModel. Важно: ключи должны совпадать с тем, что используем в делегате
            tablesModel.append({
                "dbId": t.id, // ID из базы (чтобы знать, кого обновлять)
                "name": t.name,
                "x": t.x,
                "y": t.y,
                "width": t.width,
                "height": t.height,
                "shapeType": t.shapeType
            })
        }
    }

    // 2. СОХРАНЕНИЕ ДАННЫХ
    function saveTables() {
        var tablesToSave = []
        for (var i = 0; i < tablesModel.count; i++) {
            var t = tablesModel.get(i)
            tablesToSave.push({
                "id": t.dbId,
                "name": t.name,
                "x": t.x,     // Координаты обновились благодаря привязке в делегате
                "y": t.y,
                "width": t.width,
                "height": t.height,
                "shapeType": t.shapeType
            })
        }

        // Отправляем в C++
        var success = BackendApi.saveTableLayout(premisesId, tablesToSave)
        if (success) {
            console.log("Схема сохранена!")
            loadTables() // Перезагружаем, чтобы убедиться, что всё ок
        } else {
            console.log("Ошибка сохранения")
        }
    }

    Component.onCompleted: loadTables()

    // --- ИНТЕРФЕЙС ---

    header: ToolBar {
        Row {
            spacing: 10
            anchors.verticalCenter: parent.verticalCenter

            ToolButton { text: "<- Назад"; onClicked: page.StackView.view.pop() }
            Label { text: "Столики"; anchors.verticalCenter: parent.verticalCenter }

            // Кнопка добавления
            Button {
                text: "+ Стол"
                onClicked: {
                    // Добавляем новый стол в модель (по центру экрана примерно)
                    tablesModel.append({
                        "dbId": -1, // Новый стол
                        "name": "T-" + (tablesModel.count + 1),
                        "x": 100,
                        "y": 100,
                        "width": 80,
                        "height": 80,
                        "shapeType": "rect"
                    })
                }
            }

            Button {
                text: "Сохранить"
                highlighted: true
                onClicked: saveTables()
            }
        }
    }

    // Область зала
    Flickable {
        anchors.fill: parent
        contentWidth: 1000
        contentHeight: 1000
        clip: true

        // Фон (пол)
        Rectangle {
            width: 1000; height: 1000
            color: "#FFF8E1" // Цвет паркета :)
            border.color: "gray"
        }

        // Рендер столиков
        Repeater {
            model: tablesModel
            delegate: EditableTableItem {
                // Привязываем свойства компонента к данным модели
                x: model.x
                y: model.y
                width: model.width
                height: model.height
                text: model.name
                type: model.shapeType

                // ВАЖНО: Когда таскаем стол, обновляем модель
                // DragHandler меняет x/y, а этот код записывает новые x/y обратно в ListModel
                onXChanged: model.x = x
                onYChanged: model.y = y
            }
        }
    }
}
