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

        // Начальная позиция скролла будет установлена через centerOnObjects
        Component.onCompleted: {
            Qt.callLater(function() {
                if (hallRoot.centerOnObjects) {
                    hallRoot.centerOnObjects()
                } else {
                    contentX = (contentWidth - width) / 2
                    contentY = (contentHeight - height) / 2
                }
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

                    // Исправлено: Передаем index модели только для столов
                    onClicked: {
                        // В режиме редактирования - все элементы кликабельны
                        // В режиме бронирования - только столы
                        if (hallRoot.editMode || model.type === "table") {
                            hallRoot.tableClicked(index, model.dbId)
                        }
                    }
                }
            }
        }

        PinchHandler {
            target: null
            onActiveChanged: flickable.interactive = !active
            onScaleChanged: (delta) => {
                var newScale = flickable.scaleFactor * delta
                var clampedScale = Math.min(Math.max(0.5, newScale), 2.0)
                flickable.scaleFactor = clampedScale
                // Синхронизируем слайдер
                if (Math.abs(zoomSlider.value - clampedScale) > 0.05) {
                    zoomSlider.value = clampedScale
                }
            }
        }
    }

    // Панель управления зумом с слайдером
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        width: 200
        height: hallRoot.editMode ? 120 : 80
        color: Theme.surface
        radius: Theme.radiusSmall
        border.width: 1
        border.color: Theme.divider
        z: 1000
        
        // Тень
        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            z: -1
            color: "#20000000"
            radius: parent.radius + 2
            opacity: 0.15
        }
        
        Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8
            
            // Слайдер зума
            Column {
                width: parent.width
                spacing: 4
                
                Row {
                    width: parent.width
                    spacing: 8
                    
                    Text {
                        text: "−"
                        font.pixelSize: 18
                        font.bold: true
                        color: Theme.textPrimary
                        width: 24
                        horizontalAlignment: Text.AlignHCenter
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    Slider {
                        id: zoomSlider
                        width: parent.width - 60
                        from: 0.5
                        to: 2.0
                        value: flickable.scaleFactor
                        stepSize: 0.1
                        onValueChanged: {
                            flickable.scaleFactor = value
                        }
                        
                        background: Rectangle {
                            x: zoomSlider.leftPadding
                            y: zoomSlider.topPadding + zoomSlider.availableHeight / 2 - height / 2
                            implicitWidth: 200
                            implicitHeight: 4
                            width: zoomSlider.availableWidth
                            height: implicitHeight
                            radius: 2
                            color: Theme.surfaceDark
                            
                            Rectangle {
                                width: zoomSlider.visualPosition * parent.width
                                height: parent.height
                                color: Theme.primary
                                radius: 2
                            }
                        }
                        
                        handle: Rectangle {
                            x: zoomSlider.leftPadding + zoomSlider.visualPosition * (zoomSlider.availableWidth - width)
                            y: zoomSlider.topPadding + zoomSlider.availableHeight / 2 - height / 2
                            implicitWidth: 20
                            implicitHeight: 20
                            radius: 10
                            color: zoomSlider.pressed ? Theme.primaryDark : Theme.primary
                            border.color: "white"
                            border.width: 2
                        }
                    }
                    
                    Text {
                        text: "+"
                        font.pixelSize: 18
                        font.bold: true
                        color: Theme.textPrimary
                        width: 24
                        horizontalAlignment: Text.AlignHCenter
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                
                // Индикатор зума
                Text {
                    text: Math.round(flickable.scaleFactor * 100) + "%"
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: true
                    color: Theme.textPrimary
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                }
            }
            
            // Кнопки управления (только для режима редактирования)
            Row {
                width: parent.width
                spacing: 8
                visible: hallRoot.editMode
                
                Button {
                    text: "⌂"
                    width: (parent.width - 8) / 2
                    height: 32
                    background: Rectangle {
                        color: parent.pressed ? Theme.surfaceDark : Theme.surface
                        radius: Theme.radiusSmall
                        border.color: Theme.divider
                        border.width: 1
                    }
                    contentItem: Text {
                        text: parent.text
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignHCenter
                    }
                    onClicked: {
                        flickable.scaleFactor = 1.0
                        centerOnObjects()
                    }
                }
                
                Button {
                    text: "Центр"
                    width: (parent.width - 8) / 2
                    height: 32
                    background: Rectangle {
                        color: parent.pressed ? Theme.surfaceDark : Theme.surface
                        radius: Theme.radiusSmall
                        border.color: Theme.divider
                        border.width: 1
                    }
                    contentItem: Text {
                        text: parent.text
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignHCenter
                    }
                    onClicked: {
                        centerOnObjects()
                    }
                }
            }
        }
    }
    
    // Синхронизация слайдера с зумом
    Connections {
        target: flickable
        function onScaleFactorChanged() {
            if (Math.abs(zoomSlider.value - flickable.scaleFactor) > 0.05) {
                zoomSlider.value = flickable.scaleFactor
            }
        }
    }
    
    // Функция центрирования на объектах
    function centerOnObjects() {
        if (!tablesModel || tablesModel.count === 0) {
            flickable.contentX = (flickable.contentWidth - flickable.width) / 2
            flickable.contentY = (flickable.contentHeight - flickable.height) / 2
            return
        }
        
        // Находим границы всех объектов (или только столов для пользователя)
        var minX = 999999, minY = 999999, maxX = 0, maxY = 0
        var hasObjects = false
        
        for (var i = 0; i < tablesModel.count; i++) {
            var item = tablesModel.get(i)
            // Для пользователя - только столы, для админа - все объекты
            if (editMode || item.type === "table") {
                minX = Math.min(minX, item.x)
                minY = Math.min(minY, item.y)
                maxX = Math.max(maxX, item.x + item.width)
                maxY = Math.max(maxY, item.y + item.height)
                hasObjects = true
            }
        }
        
        if (hasObjects) {
            var centerX = (minX + maxX) / 2
            var centerY = (minY + maxY) / 2
            var scale = flickable.scaleFactor || 1.0
            
            flickable.contentX = centerX * scale - flickable.width / 2
            flickable.contentY = centerY * scale - flickable.height / 2
        } else {
            flickable.contentX = (flickable.contentWidth - flickable.width) / 2
            flickable.contentY = (flickable.contentHeight - flickable.height) / 2
        }
    }
}
