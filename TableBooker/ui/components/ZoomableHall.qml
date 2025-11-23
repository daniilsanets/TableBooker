import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: hallRoot
    clip: true

    property var tablesModel // Модель данных
    property bool editMode: false
    property int selectedIndex: -1 // Индекс выделенного элемента (синхронизируется с родителем)

    // Сигналы
    signal tableModified(int id, int x, int y, int w, int h)
    signal tableClicked(int index, int dbId) // Изменили сигнатуру
    signal canvasTapped()
    
    // Функция для обеспечения видимости элемента (вызывается извне)
    function ensureItemVisible(index) {
        if (index < 0 || index >= tablesModel.count) return
        
        var item = tablesModel.get(index)
        var itemX = item.x
        var itemY = item.y
        var itemW = item.width
        var itemH = item.height
        
        var scale = flickable.scaleFactor || 1.0
        var scaledX = itemX * scale
        var scaledY = itemY * scale
        var scaledW = itemW * scale
        var scaledH = itemH * scale
        
        // Центрируем элемент в видимой области
        var targetX = scaledX + scaledW/2 - flickable.width/2
        var targetY = scaledY + scaledH/2 - flickable.height/2
        
        // Ограничиваем границами
        targetX = Math.max(0, Math.min(targetX, flickable.contentWidth - flickable.width))
        targetY = Math.max(0, Math.min(targetY, flickable.contentHeight - flickable.height))
        
        flickable.contentX = targetX
        flickable.contentY = targetY
    }

    Flickable
    {
        id: flickable
        anchors.fill: parent

        contentWidth: contentContainer.width * scaleFactor
        contentHeight: contentContainer.height * scaleFactor

        // Начальная позиция скролла (центр) - с задержкой для правильной инициализации
        Component.onCompleted: {
            Qt.callLater(function() {
                contentX = (contentWidth - width) / 2
                contentY = (contentHeight - height) / 2
            })
        }

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
                    opacity: 0.4
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.strokeStyle = "#9E9E9E"
                        ctx.lineWidth = 0.5
                        ctx.beginPath()
                        // Рисуем сетку 10x10 для точного позиционирования
                        var gridSize = 10
                        for (var i = 0; i < width; i += gridSize) {
                            ctx.moveTo(i, 0); ctx.lineTo(i, height)
                        }
                        for (var j = 0; j < height; j += gridSize) {
                            ctx.moveTo(0, j); ctx.lineTo(width, j)
                        }
                        ctx.stroke()
                        
                        // Более жирные линии каждые 50px
                        ctx.strokeStyle = "#757575"
                        ctx.lineWidth = 1
                        ctx.beginPath()
                        for (var i2 = 0; i2 < width; i2 += 50) {
                            ctx.moveTo(i2, 0); ctx.lineTo(i2, height)
                        }
                        for (var j2 = 0; j2 < height; j2 += 50) {
                            ctx.moveTo(0, j2); ctx.lineTo(width, j2)
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

    // Панель управления зумом
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        width: 120
        height: 40
        color: Theme.surface
        radius: Theme.radiusSmall
        border.width: 1
        border.color: Theme.divider
        z: 1000
        visible: hallRoot.editMode
        
        // Тень
        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            z: -1
            color: "#20000000"
            radius: parent.radius + 2
            opacity: 0.15
        }
        
        Row {
            anchors.centerIn: parent
            spacing: 8
            
            // Кнопка уменьшения
            Rectangle {
                width: 32
                height: 32
                radius: 4
                color: zoomOutMouse.pressed ? Theme.surfaceDark : "transparent"
                Text {
                    text: "−"
                    font.pixelSize: 20
                    font.bold: true
                    color: Theme.textPrimary
                    anchors.centerIn: parent
                }
                MouseArea {
                    id: zoomOutMouse
                    anchors.fill: parent
                    onClicked: {
                        var newScale = Math.max(0.5, flickable.scaleFactor - 0.25)
                        flickable.scaleFactor = newScale
                    }
                }
            }
            
            // Индикатор зума
            Text {
                text: Math.round(flickable.scaleFactor * 100) + "%"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.textPrimary
                width: 40
                horizontalAlignment: Text.AlignHCenter
                anchors.verticalCenter: parent.verticalCenter
            }
            
            // Кнопка увеличения
            Rectangle {
                width: 32
                height: 32
                radius: 4
                color: zoomInMouse.pressed ? Theme.surfaceDark : "transparent"
                Text {
                    text: "+"
                    font.pixelSize: 20
                    font.bold: true
                    color: Theme.textPrimary
                    anchors.centerIn: parent
                }
                MouseArea {
                    id: zoomInMouse
                    anchors.fill: parent
                    onClicked: {
                        var newScale = Math.min(2.0, flickable.scaleFactor + 0.25)
                        flickable.scaleFactor = newScale
                    }
                }
            }
            
            // Кнопка сброса
            Rectangle {
                width: 32
                height: 32
                radius: 4
                color: resetMouse.pressed ? Theme.surfaceDark : "transparent"
                Text {
                    text: "⌂"
                    font.pixelSize: 16
                    color: Theme.textPrimary
                    anchors.centerIn: parent
                }
                MouseArea {
                    id: resetMouse
                    anchors.fill: parent
                    onClicked: {
                        flickable.scaleFactor = 1.0
                        flickable.contentX = (flickable.contentWidth - flickable.width) / 2
                        flickable.contentY = (flickable.contentHeight - flickable.height) / 2
                    }
                }
            }
        }
    }
    
    // Кнопка сброса зума для режима просмотра
    Button {
        text: Math.round(flickable.scaleFactor * 100) + "%"
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        visible: !hallRoot.editMode && flickable.scaleFactor !== 1.0
        onClicked: {
            flickable.scaleFactor = 1.0
            flickable.contentX = (flickable.contentWidth - flickable.width) / 2
            flickable.contentY = (flickable.contentHeight - flickable.height) / 2
        }
        background: Rectangle { 
            color: Theme.surface
            radius: Theme.radiusSmall
            border.width: 1
            border.color: Theme.divider
        }
        z: 1000
    }
}
