import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: hallRoot
    clip: true

    property var tablesModel // Модель данных
    property bool editMode: false
    property int selectedIndex: -1 // Индекс выделенного элемента

    // Сигналы
    signal tableModified(int id, int x, int y, int w, int h)
    signal tableClicked(int index, int dbId) // Изменили сигнатуру
    signal canvasTapped()

    Flickable
    {
        id: flickable
        anchors.fill: parent

        contentWidth: contentContainer.width * scaleFactor
        contentHeight: contentContainer.height * scaleFactor

        // Начальная позиция скролла (центр)
        contentX: (contentWidth - width) / 2
        contentY: (contentHeight - height) / 2

        property real scaleFactor: 1.0

        Item {
            id: contentContainer
            width: 3000; height: 3000
            scale: flickable.scaleFactor
            transformOrigin: Item.TopLeft

            // 1. ПОЛ (Фон + Сетка)
            Rectangle {
                anchors.fill: parent
                color: "#F5F5F5"
                z: -100

                Canvas {
                    anchors.fill: parent
                    visible: hallRoot.editMode
                    opacity: 0.3
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.strokeStyle = "#BDBDBD"
                        ctx.lineWidth = 1
                        ctx.beginPath()
                        // Рисуем сетку 50x50
                        for (var i = 0; i < width; i += 50) {
                            ctx.moveTo(i, 0); ctx.lineTo(i, height)
                        }
                        for (var j = 0; j < height; j += 50) {
                            ctx.moveTo(0, j); ctx.lineTo(width, j)
                        }
                        ctx.stroke()
                    }
                }

                TapHandler {
                    onTapped: hallRoot.canvasTapped()
                }
            }

            // 2. СТОЛЫ И ОБЪЕКТЫ
            Repeater {
                model: hallRoot.tablesModel
                delegate: TableWidget {
                    // Биндинг координат
                    x: model.x
                    y: model.y
                    width: model.width
                    height: model.height

                    // БЕЗОПАСНЫЕ БИНДИНГ (защита от undefined)
                    rotation: (model.rotation !== undefined) ? model.rotation : 0
                    itemColor: (model.color !== undefined) ? model.color : "#FFFFFF"
                    type: (model.type !== undefined) ? model.type : "table"
                    shapeType: (model.shapeType !== undefined) ? model.shapeType : "rect"

                    // Исправлено: itemName вместо tableName
                    itemName: model.name
                    dbId: model.dbId

                    isEditable: hallRoot.editMode
                    // Выделяем, если индекс совпадает с выбранным в HallEditorPage
                    isSelected: hallRoot.editMode && (index === hallRoot.selectedIndex)

                    // Обратная связь
                    onMoved: (nx, ny) => { model.x = nx; model.y = ny }
                    onResized: (nw, nh) => { model.width = nw; model.height = nh }

                    // Исправлено: Передаем index модели
                    onClicked: hallRoot.tableClicked(index, model.dbId)
                }
            }
        }

        PinchHandler {
            target: null
            onActiveChanged: flickable.interactive = !active
            onScaleChanged: (delta) => {
                var newScale = flickable.scaleFactor * delta
                flickable.scaleFactor = Math.min(Math.max(0.5, newScale), 2.0)
            }
        }
    }

    // Кнопка сброса зума
    Button {
        text: Math.round(flickable.scaleFactor * 100) + "%"
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        visible: flickable.scaleFactor !== 1.0
        onClicked: flickable.scaleFactor = 1.0
        background: Rectangle { color: "white"; radius: 4; opacity: 0.8 }
    }
}
