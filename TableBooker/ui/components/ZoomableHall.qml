import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../Theme.js" as Theme

Item {
    id: hallRoot
    clip: true

    property var tablesModel // Модель данных
    property bool editMode: false
    property int selectedIndex: -1 // Индекс выделенного элемента (синхронизируется с родителем)
    property bool skipCenterOnZoom: false

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

                    onInteractionStarted: flickable.interactive = false
                    onInteractionEnded: flickable.interactive = true

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
                    hallRoot.skipCenterOnZoom = true
                    zoomSlider.value = clampedScale
                    hallRoot.skipCenterOnZoom = false
                }
            }
        }
    }

    // Кнопка открытия панели зума
    Rectangle {
        id: zoomToggleButton
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        width: 48
        height: 48
        radius: 24
        color: zoomPanel.visible ? Theme.primaryDark : Theme.primary
        z: 1001
        border.width: 2
        border.color: "white"
        
        Text {
            text: "🔍"
            font.pixelSize: 20
            anchors.centerIn: parent
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: zoomPanel.visible = !zoomPanel.visible
        }
        
        Behavior on color {
            ColorAnimation { duration: 200 }
        }
    }
    
    // Панель управления зумом с слайдером - Скрываемая
    Rectangle {
        id: zoomPanel
        anchors.right: parent.right
        anchors.top: zoomToggleButton.bottom
        anchors.topMargin: 8
        anchors.margins: 12
        width: 240
        height: hallRoot.editMode ? 140 : 100
        color: Theme.surface
        radius: Theme.radiusMedium
        border.width: 1
        border.color: Theme.divider
        z: 1000
        visible: false
        
        opacity: visible ? 1 : 0
        
        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }
        
        Behavior on visible {
            PropertyAnimation { duration: 200 }
        }
        
        // Профессиональная тень
        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            z: -1
            color: "#30000000"
            radius: parent.radius + 3
            opacity: 0.2
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: -1
            z: -1
            color: "#15000000"
            radius: parent.radius + 1
            opacity: 0.1
        }
        
        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10
            
            // Заголовок
            Row {
                width: parent.width
                height: 24
                spacing: 8
                
                Text {
                    text: "🔍"
                    font.pixelSize: 16
                    height: parent.height
                }
                
                Text {
                    text: "Масштаб"
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: true
                    color: Theme.textPrimary
                    height: parent.height
                }
                
                Item { 
                    width: parent.width - 200
                    height: 1
                }
                
                // Индикатор зума
                Rectangle {
                    width: 50
                    height: 24
                    radius: 12
                    color: Theme.primary
                    
                    Text {
                        text: Math.round(flickable.scaleFactor * 100) + "%"
                        font.pixelSize: Theme.fontSizeSmall
                        font.bold: true
                        color: "white"
                        anchors.centerIn: parent
                    }
                }
            }
            
            // Слайдер зума
            Column {
                width: parent.width
                spacing: 6
                
                Row {
                    width: parent.width
                    height: 40
                    spacing: 12
                    
                    // Кнопка уменьшения
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: zoomOutMouse.pressed ? Theme.primaryDark : Theme.primary
                        
                        Text {
                            text: "−"
                            font.pixelSize: 20
                            font.bold: true
                            color: "white"
                            anchors.centerIn: parent
                        }
                        
                        MouseArea {
                            id: zoomOutMouse
                            anchors.fill: parent
                            onClicked: {
                                var newScale = Math.max(0.5, flickable.scaleFactor - 0.1)
                                flickable.scaleFactor = newScale
                                zoomSlider.value = newScale
                            }
                        }
                    }
                    
                    // Слайдер
                    Slider {
                        id: zoomSlider
                        width: parent.width - 80
                        height: parent.height
                        from: 0.5
                        to: 2.0
                        value: flickable.scaleFactor
                        stepSize: 0.05
                        onValueChanged: {
                            if (Math.abs(flickable.scaleFactor - value) > 0.01) {
                                flickable.scaleFactor = value
                            }
                            if (!hallRoot.skipCenterOnZoom) {
                                hallRoot.centerOnObjects()
                            }
                        }
                        
                        background: Rectangle {
                            x: zoomSlider.leftPadding
                            y: zoomSlider.topPadding + zoomSlider.availableHeight / 2 - height / 2
                            implicitWidth: 200
                            implicitHeight: 6
                            width: zoomSlider.availableWidth
                            height: implicitHeight
                            radius: 3
                            color: "#E0E0E0"
                            
                            Rectangle {
                                width: zoomSlider.visualPosition * parent.width
                                height: parent.height
                                color: Theme.primary
                                radius: 3
                            }
                        }
                        
                        handle: Rectangle {
                            x: zoomSlider.leftPadding + zoomSlider.visualPosition * (zoomSlider.availableWidth - width)
                            y: zoomSlider.topPadding + zoomSlider.availableHeight / 2 - height / 2
                            implicitWidth: 24
                            implicitHeight: 24
                            radius: 12
                            color: zoomSlider.pressed ? Theme.primaryDark : Theme.primary
                            border.color: "white"
                            border.width: 3
                            
                            // Внутренний круг для глубины
                            Rectangle {
                                anchors.centerIn: parent
                                width: 8
                                height: 8
                                radius: 4
                                color: "white"
                                opacity: 0.3
                            }
                        }
                    }
                    
                    // Кнопка увеличения
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: zoomInMouse.pressed ? Theme.primaryDark : Theme.primary
                        
                        Text {
                            text: "+"
                            font.pixelSize: 20
                            font.bold: true
                            color: "white"
                            anchors.centerIn: parent
                        }
                        
                        MouseArea {
                            id: zoomInMouse
                            anchors.fill: parent
                            onClicked: {
                                var newScale = Math.min(2.0, flickable.scaleFactor + 0.1)
                                flickable.scaleFactor = newScale
                                zoomSlider.value = newScale
                            }
                        }
                    }
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
                hallRoot.skipCenterOnZoom = true
                zoomSlider.value = flickable.scaleFactor
                hallRoot.skipCenterOnZoom = false
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

    // Возвращаем координаты центра видимой области в системе холла
    function viewportCenter() {
        var scale = flickable.scaleFactor || 1.0
        var centerX = (flickable.contentX + flickable.width / 2) / scale
        var centerY = (flickable.contentY + flickable.height / 2) / scale
        return { "x": centerX, "y": centerY }
    }
}
