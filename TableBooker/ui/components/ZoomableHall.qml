import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../Theme.js" as Theme

Item {
    id: hallRoot
    clip: true

    property var tablesModel
    property bool editMode: false
    property int selectedIndex: -1
    property bool skipCenterOnZoom: false

    onEditModeChanged: {
        if (flickable) {
            flickable.scaleFactor = editMode ? 1.0 : 0.5
            if (zoomSlider) zoomSlider.value = flickable.scaleFactor
            Qt.callLater(function() { centerOnObjects() })
        }
    }

    signal tableModified(int id, int x, int y, int w, int h)
    signal tableClicked(int index, int dbId)
    signal canvasTapped()

    // --- УМНЫЙ ЗУМ (Сохранение центра) ---
    function setZoomPreservingCenter(newScale) {
        var clampedScale = Math.min(Math.max(0.2, newScale), 3.0)
        if (Math.abs(flickable.scaleFactor - clampedScale) < 0.001) return

        // 1. Находим текущий центр экрана в координатах контента
        var centerX = flickable.contentX + flickable.width / 2
        var centerY = flickable.contentY + flickable.height / 2

        // 2. Переводим в координаты Item (без масштаба)
        var itemX = centerX / flickable.scaleFactor
        var itemY = centerY / flickable.scaleFactor

        // 3. Применяем новый масштаб
        flickable.scaleFactor = clampedScale
        if (zoomSlider) zoomSlider.value = clampedScale

        // 4. Вычисляем новый contentX/Y, чтобы вернуть центр на место
        var newContentX = itemX * clampedScale - flickable.width / 2
        var newContentY = itemY * clampedScale - flickable.height / 2

        flickable.contentX = newContentX
        flickable.contentY = newContentY
    }

    Flickable {
        id: flickable
        anchors.fill: parent
        contentWidth: contentContainer.width * scaleFactor
        contentHeight: contentContainer.height * scaleFactor
        property real scaleFactor: hallRoot.editMode ? 1.0 : 0.5

        Component.onCompleted: {
            Qt.callLater(function() {
                if (hallRoot.centerOnObjects) hallRoot.centerOnObjects()
                else {
                    contentX = (contentWidth - width) / 2
                    contentY = (contentHeight - height) / 2
                }
            })
        }

        Item {
            id: contentContainer
            width: 3000; height: 3000
            scale: flickable.scaleFactor
            transformOrigin: Item.TopLeft

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
                        ctx.strokeStyle = "#9E9E9E"; ctx.lineWidth = 0.5; ctx.beginPath()
                        for (var i = 0; i < width; i += 10) { ctx.moveTo(i, 0); ctx.lineTo(i, height) }
                        for (var j = 0; j < height; j += 10) { ctx.moveTo(0, j); ctx.lineTo(width, j) }
                        ctx.stroke()
                        ctx.strokeStyle = "#757575"; ctx.lineWidth = 1; ctx.beginPath()
                        for (var i2 = 0; i2 < width; i2 += 50) { ctx.moveTo(i2, 0); ctx.lineTo(i2, height) }
                        for (var j2 = 0; j2 < height; j2 += 50) { ctx.moveTo(0, j2); ctx.lineTo(width, j2) }
                        ctx.stroke()
                    }
                }
                TapHandler { onTapped: { zoomPanel.visible = false; hallRoot.canvasTapped() } }
            }

            Repeater {
                model: hallRoot.tablesModel
                delegate: TableWidget {
                    x: model.x; y: model.y; width: model.width; height: model.height
                    rotation: (model.rotation !== undefined) ? model.rotation : 0
                    itemColor: (model.color !== undefined) ? model.color : "#FFFFFF"
                    type: (model.type !== undefined) ? model.type : "table"
                    shapeType: (model.shapeType !== undefined) ? model.shapeType : "rect"
                    itemName: model.name; dbId: model.dbId
                    isEditable: hallRoot.editMode
                    isSelected: hallRoot.editMode && (index === hallRoot.selectedIndex)
                    onMoved: (nx, ny) => { model.x = nx; model.y = ny; hallRoot.tableModified(model.dbId, nx, ny, width, height) }
                    onResized: (nw, nh) => { model.width = nw; model.height = nh; hallRoot.tableModified(model.dbId, x, y, nw, nh) }
                    onInteractionStarted: flickable.interactive = false
                    onInteractionEnded: flickable.interactive = true
                    onClicked: { if (hallRoot.editMode || model.type === "table") hallRoot.tableClicked(index, model.dbId) }
                }
            }
        }

        // --- ЖЕСТ ЩИПКА (PINCH) ---
        PinchHandler {
            target: null
            onActiveChanged: flickable.interactive = !active
            onScaleChanged: (delta) => {
                setZoomPreservingCenter(flickable.scaleFactor * delta)
            }
        }
    }

    // --- КНОПКА ЗУМА (Сдвинута ниже) ---
    Rectangle {
        id: zoomToggleButton
        anchors.right: parent.right; anchors.top: parent.top
        anchors.margins: 12
        anchors.topMargin: 80 // <-- Исправление перекрытия
        width: 48; height: 48; radius: 24
        color: zoomPanel.visible ? Theme.primaryDark : Theme.primary
        z: 1001; border.width: 2; border.color: "white"
        Rectangle { z: -1; anchors.fill: parent; anchors.margins: -2; color: "#40000000"; radius: 26 }
        Text { text: "🔍"; font.pixelSize: 20; anchors.centerIn: parent }
        MouseArea { anchors.fill: parent; onClicked: zoomPanel.visible = !zoomPanel.visible }
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    // --- ПАНЕЛЬ ЗУМА ---
    Rectangle {
        id: zoomPanel
        anchors.right: parent.right; anchors.top: zoomToggleButton.bottom
        anchors.topMargin: 8; anchors.rightMargin: 12
        width: 240; height: hallRoot.editMode ? 140 : 100
        color: Theme.surface; radius: Theme.radiusMedium
        border.width: 1; border.color: Theme.divider
        z: 1000; visible: false; opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Rectangle { anchors.fill: parent; anchors.margins: -3; z: -1; color: "#30000000"; radius: parent.radius + 3; opacity: 0.2 }

        Column {
            anchors.fill: parent; anchors.margins: 12; spacing: 10
            Row {
                width: parent.width; height: 24; spacing: 8
                Text { text: "🔍"; font.pixelSize: 16; height: parent.height; verticalAlignment: Text.AlignVCenter }
                Text { text: "Масштаб"; font.pixelSize: Theme.fontSizeSmall; font.bold: true; color: Theme.textPrimary; height: parent.height; verticalAlignment: Text.AlignVCenter }
                Item { width: 1; Layout.fillWidth: true }
                Rectangle {
                    width: 50; height: 24; radius: 12; color: Theme.primary
                    Text { text: Math.round(flickable.scaleFactor * 100) + "%"; font.pixelSize: Theme.fontSizeSmall; font.bold: true; color: "white"; anchors.centerIn: parent }
                }
            }

            Row {
                width: parent.width; height: 40; spacing: 12
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: zoomOutMouse.pressed ? Theme.primaryDark : Theme.primary
                    Text { text: "−"; font.pixelSize: 20; font.bold: true; color: "white"; anchors.centerIn: parent }
                    MouseArea { id: zoomOutMouse; anchors.fill: parent; onClicked: setZoomPreservingCenter(flickable.scaleFactor - 0.1) }
                }

                Slider {
                    id: zoomSlider
                    width: parent.width - 88; height: parent.height
                    from: 0.2; to: 3.0; value: flickable.scaleFactor; stepSize: 0.05
                    // Используем onMoved, чтобы зум был плавным, но не вызывал loop
                    onMoved: { if (Math.abs(flickable.scaleFactor - value) > 0.01) setZoomPreservingCenter(value) }
                    background: Rectangle {
                        x: parent.leftPadding; y: parent.topPadding + parent.availableHeight / 2 - height / 2
                        width: parent.availableWidth; height: 4; radius: 2; color: "#E0E0E0"
                        Rectangle { width: parent.visualPosition * parent.width; height: parent.height; color: Theme.primary; radius: 2 }
                    }
                    handle: Rectangle {
                        x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                        y: parent.topPadding + parent.availableHeight / 2 - height / 2
                        width: 20; height: 20; radius: 10
                        color: parent.pressed ? Theme.primaryDark : Theme.primary; border.color: "white"; border.width: 2
                    }
                }

                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: zoomInMouse.pressed ? Theme.primaryDark : Theme.primary
                    Text { text: "+"; font.pixelSize: 20; font.bold: true; color: "white"; anchors.centerIn: parent }
                    MouseArea { id: zoomInMouse; anchors.fill: parent; onClicked: setZoomPreservingCenter(flickable.scaleFactor + 0.1) }
                }
            }

            Button {
                visible: hallRoot.editMode; width: parent.width; height: 32
                background: Rectangle { color: parent.pressed ? Theme.surfaceDark : Theme.surface; radius: Theme.radiusSmall; border.color: Theme.divider; border.width: 1 }
                contentItem: Text { text: "Центрировать вид"; color: Theme.textPrimary; font.pixelSize: Theme.fontSizeSmall; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                onClicked: hallRoot.centerOnObjects()
            }
        }
    }

    function centerOnObjects() {
        if (!tablesModel || tablesModel.count === 0) {
            flickable.contentX = (flickable.contentWidth - flickable.width) / 2
            flickable.contentY = (flickable.contentHeight - flickable.height) / 2
            return
        }
        var minX = 999999, minY = 999999, maxX = 0, maxY = 0, hasObjects = false
        for (var i = 0; i < tablesModel.count; i++) {
            var item = tablesModel.get(i)
            if (editMode || item.type === "table") {
                minX = Math.min(minX, item.x); minY = Math.min(minY, item.y)
                maxX = Math.max(maxX, item.x + item.width); maxY = Math.max(maxY, item.y + item.height)
                hasObjects = true
            }
        }
        if (hasObjects) {
            var centerX = (minX + maxX) / 2
            var centerY = (minY + maxY) / 2
            var scale = flickable.scaleFactor || 1.0
            flickable.contentX = centerX * scale - flickable.width / 2
            flickable.contentY = centerY * scale - flickable.height / 2
        }
    }

    function viewportCenter() {
        var scale = flickable.scaleFactor || 1.0
        var centerX = (flickable.contentX + flickable.width / 2) / scale
        var centerY = (flickable.contentY + flickable.height / 2) / scale
        return { "x": centerX, "y": centerY }
    }
}
