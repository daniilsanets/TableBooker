import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root

    property int dbId: -1
    property string itemName: ""
    property string type: "table"
    property string shapeType: "rect"
    property color itemColor: "#FFFFFF"

    property bool isEditable: false
    property bool isSelected: false

    signal clicked()
    signal moved(int newX, int newY)
    signal resized(int newW, int newH)
    signal interactionStarted()
    signal interactionEnded()

    property int gridSize: 10
    property int minSize: 20

    z: isSelected ? 1000 : (type === "room" ? -1 : 10)

    // Тело
    Rectangle {
        id: body
        anchors.fill: parent
        color: root.itemColor
        border.color: root.isSelected ? "#2962FF" : (root.type === "room" ? "#E0E0E0" : "#757575")
        border.width: root.isSelected ? 2 : 1
        radius: root.shapeType === "ellipse" ? width / 2 : 0
        opacity: root.type === "plant" ? 0.8 : 1.0

        Rectangle { // Тень
            visible: root.type !== "room" && root.type !== "floor" && root.type !== "wall"
            anchors.fill: parent; anchors.margins: -4; z: -1
            color: "#000000"; opacity: 0.15; radius: parent.radius + 4
        }

        Text {
            anchors.centerIn: parent
            text: root.itemName
            visible: root.type === "table" || root.type === "wc" || root.type === "room"
            font.pixelSize: Math.max(10, Math.min(14, root.width * 0.2))
            font.bold: true
            color: (root.type === "room") ? "#BDBDBD" : "#212121"
            rotation: -root.rotation
        }
        Text { anchors.centerIn: parent; text: "🌿"; visible: root.type === "plant"; font.pixelSize: Math.min(root.width, root.height)*0.6; rotation: -root.rotation }
    }

    // Индикатор размера
    Rectangle {
        anchors.bottom: parent.top; anchors.bottomMargin: 8; anchors.horizontalCenter: parent.horizontalCenter
        width: sizeText.width + 16; height: 24; radius: 4; color: "#212121"; z: 2000
        visible: (dragArea.drag.active || resizeMouseArea.pressed)
        Text { id: sizeText; text: Math.round(root.width) + " x " + Math.round(root.height); color: "white"; font.bold: true; font.pixelSize: 12; anchors.centerIn: parent }
    }

    // Драг и Клик
    MouseArea {
        id: dragArea
        anchors.fill: parent
        drag.target: root.isEditable && root.type !== "room" ? root : null
        drag.axis: Drag.XAndYAxis
        drag.threshold: 10 // Увеличил порог для мобилок

        onPressed: {
            root.interactionStarted()
            // Сразу сообщаем о клике, чтобы обновить selectedIndex в родителе
            root.clicked()
        }

        onReleased: {
            root.interactionEnded()
            if (root.isEditable && root.type !== "room") {
                root.x = Math.round(root.x / root.gridSize) * root.gridSize
                root.y = Math.round(root.y / root.gridSize) * root.gridSize
                root.moved(root.x, root.y)
            }
        }
    }

    // Ресайз (только если выбран)
    Rectangle {
        width: 24; height: 24
        color: "#2962FF"; radius: 12
        anchors.bottom: parent.bottom; anchors.right: parent.right
        anchors.margins: -8 // Вылезает за границы для удобства хватания
        visible: root.isEditable && root.isSelected && root.type !== "plant" && root.type !== "room"
        z: 2000
        border.width: 2; border.color: "white"

        MouseArea {
            id: resizeMouseArea
            anchors.fill: parent
            anchors.margins: -10 // Большая зона клика
            cursorShape: Qt.SizeFDiagCursor

            property real startX: 0; property real startY: 0

            onPressed: (mouse) => {
                root.interactionStarted()
                var globalPos = mapToItem(root.parent, mouse.x, mouse.y)
                startX = globalPos.x
                startY = globalPos.y
            }

            onPositionChanged: (mouse) => {
                if (pressed) {
                    var globalPos = mapToItem(root.parent, mouse.x, mouse.y)
                    var newWidth = Math.round((globalPos.x - root.x) / root.gridSize) * root.gridSize
                    var newHeight = Math.round((globalPos.y - root.y) / root.gridSize) * root.gridSize
                    root.width = Math.max(root.minSize, newWidth)
                    root.height = Math.max(root.minSize, newHeight)
                    root.resized(root.width, root.height)
                }
            }
            onReleased: root.interactionEnded()
        }
    }
}
