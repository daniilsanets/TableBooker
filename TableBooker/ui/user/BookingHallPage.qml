import QtQuick 2.15
import QtQuick.Controls 2.15
import com.tablebooker.api 1.0
// Импортируем папку admin, чтобы использовать компонент столика (EditableTableItem)
// Если Qt ругается, можно просто скопировать компонент, но импорт лучше.
import "../admin"

Page {
    id: bookingPage
    title: premisesName

    property int premisesId: 0
    property string premisesName: ""

    // Модель столов
    ListModel { id: tablesModel }
    BookingPopup {id: bookingPopup}

    function loadTables() {
        tablesModel.clear()
        var tables = BackendApi.getTablesForPremises(premisesId)

        for(var i=0; i<tables.length; i++) {
            var t = tables[i]
            tablesModel.append({
                "dbId": t.id,
                "name": t.name,
                "x": t.x,
                "y": t.y,
                "width": t.width,
                "height": t.height,
                "shapeType": t.shapeType
            })
        }
    }

    Component.onCompleted: loadTables()

    header: ToolBar {
        ToolButton {
            text: "<- Назад"
            onClicked: bookingPage.StackView.view.pop()
        }
        Label {
            text: bookingPage.title
            anchors.centerIn: parent
        }
    }

    Flickable {
        anchors.fill: parent
        contentWidth: 1000; contentHeight: 1000

        // Пол
        Rectangle {
            width: 1000; height: 1000
            color: "#FFF8E1"
            border.color: "lightgray"
        }

        Repeater {
            model: tablesModel
            // Используем тот же компонент стола, что и у админа!
            delegate: EditableTableItem {
                x: model.x
                y: model.y
                width: model.width
                height: model.height
                text: model.name
                type: model.shapeType

                // ВАЖНО: Отключаем перетаскивание для пользователя
                enabled: true // Сам элемент активен (чтобы кликать)

                // Но переопределяем DragHandler внутри (или просто блокируем логику)
                // Самый простой способ - перекрыть MouseArea поверх
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        console.log("Хочу забронировать стол:", model.name)

                        bookingPopup.tableId = model.dbId
                        bookingPopup.tableName = model.name
                        bookingPopup.open()
                    }
                }
            }
        }
    }
}
