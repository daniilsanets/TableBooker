import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Effects

Item {
    id: root

    // Данные из модели
    property int dbId: -1
    property string itemName: ""
    property string type: "table" // table, wall, window, etc.
    property string shapeType: "rect"
    property color itemColor: "#FFFFFF"

    property bool isEditable: false
    property bool isSelected: false

    // Сигналы
    signal clicked()
    signal moved(int newX, int newY)
    signal resized(int newW, int newH)
    // Вращение теперь меняется снаружи, но можно добавить логику и здесь

    // Важно: привязка размеров и вращения к свойствам Item
    // width и height управляются извне или DragHandler-ом

    z: isSelected ? 1000 : (type === "room" ? -1 : 10) // Пол ниже, столы выше

    // Визуальное тело
    Rectangle {
        id: body
        anchors.fill: parent
        color: root.itemColor
        border.color: root.isSelected ? "#2962FF" : "#616161"
        border.width: root.isSelected ? 3 : 1
        radius: root.shapeType === "ellipse" ? width / 2 : 0
        opacity: root.type === "plant" ? 0.7 : 1.0

        // Тень (только для мебели, не для пола)
        Rectangle {
            visible: root.type !== "room" && root.type !== "floor"
            anchors.fill: parent
            anchors.margins: -3
            z: -1
            color: "#40000000"
            radius: parent.radius + 3
            opacity: 0.3
        }

        // Текст (имя стола или метка WC)
        Text {
            anchors.centerIn: parent
            text: root.itemName
            visible: root.type === "table" || root.type === "wc"
            font.pixelSize: Math.max(10, Math.min(14, root.width * 0.15))
            font.bold: true
            color: root.type === "table" ? "#212121" : "#616161"
            rotation: -root.rotation // Чтобы текст оставался горизонтальным (опционально)
        }

        // Иконка для декора (пример)
        Text {
            anchors.centerIn: parent
            text: "🌿"
            visible: root.type === "plant"
            font.pixelSize: Math.min(root.width, root.height) * 0.6
        }
    }

    // Единый обработчик клика и перетаскивания
    MouseArea {
        id: mainMouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        drag.target: root.isEditable && root.type !== "room" && root.type !== "floor" ? root : null
        drag.axis: Drag.XAndYAxis
        drag.minimumX: 0
        drag.minimumY: 0
        hoverEnabled: true
        
        onClicked: {
            root.clicked()
        }
        
        onReleased: {
            if (root.isEditable) {
                // Применяем сетку при отпускании (сетка 10px)
                root.x = Math.round(root.x / 10) * 10
                root.y = Math.round(root.y / 10) * 10
                root.moved(root.x, root.y)
            }
        }
        
        onPositionChanged: {
            if (pressed && root.isEditable) {
                // Применяем сетку во время перетаскивания для плавности
                root.x = Math.round(root.x / 10) * 10
                root.y = Math.round(root.y / 10) * 10
            }
        }
    }

    // РУЧКА ИЗМЕНЕНИЯ РАЗМЕРА (Resize Handle) - Исправленная версия
    Rectangle {
        id: resizeHandle
        width: 20; height: 20
        color: "#2196F3"
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        radius: 10
        visible: root.isEditable && root.isSelected && root.type !== "plant" && root.type !== "room"
        z: 1000
        border.width: 3
        border.color: "white"
        
        // Внутренний индикатор
        Rectangle {
            anchors.centerIn: parent
            width: 8
            height: 8
            radius: 4
            color: "white"
            opacity: 0.8
        }

        MouseArea {
            id: resizeMouseArea
            anchors.fill: parent
            anchors.margins: -6 // Увеличиваем область клика для удобства
            cursorShape: Qt.SizeFDiagCursor
            property real startW: 0
            property real startH: 0
            property real startRootX: 0
            property real startRootY: 0
            property real startMouseX: 0
            property real startMouseY: 0
            
            onPressed: (mouse) => {
                startW = root.width
                startH = root.height
                startRootX = root.x
                startRootY = root.y
                // Сохраняем координаты мыши относительно родителя TableWidget
                startMouseX = mouse.x
                startMouseY = mouse.y
            }
            
            onPositionChanged: (mouse) => {
                if (pressed) {
                    // Вычисляем дельту относительно начальной позиции мыши
                    var deltaX = mouse.x - startMouseX
                    var deltaY = mouse.y - startMouseY
                    
                    // Применяем сетку 10px
                    var newW = Math.max(20, Math.round((startW + deltaX) / 10) * 10)
                    var newH = Math.max(20, Math.round((startH + deltaY) / 10) * 10)
                    
                    root.width = newW
                    root.height = newH
                    root.resized(newW, newH)
                }
            }
        }
    }
    
    // Дополнительные ручки для изменения размера (опционально, для больших объектов)
    Rectangle {
        width: 12; height: 12
        color: "#2196F3"
        anchors.top: parent.top
        anchors.right: parent.right
        radius: 6
        visible: root.isEditable && root.isSelected && root.type !== "plant" && root.type !== "room" && root.width > 100
        z: 1000
        border.width: 2
        border.color: "white"
    }
    
    Rectangle {
        width: 12; height: 12
        color: "#2196F3"
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        radius: 6
        visible: root.isEditable && root.isSelected && root.type !== "plant" && root.type !== "room" && root.width > 100
        z: 1000
        border.width: 2
        border.color: "white"
    }
    
    Rectangle {
        width: 12; height: 12
        color: "#2196F3"
        anchors.top: parent.top
        anchors.left: parent.left
        radius: 6
        visible: root.isEditable && root.isSelected && root.type !== "plant" && root.type !== "room" && root.width > 100
        z: 1000
        border.width: 2
        border.color: "white"
    }
}
