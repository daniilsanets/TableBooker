import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root

    property string type: "table"
    property string shapeType: "rect"
    property string text: ""
    property color itemColor: "#E0E0E0"
    property bool isSelected: false

    // Если тип "room", мы его кладем ниже всех (z: -1). Остальные - 1.
    z: type === "room" ? -1 : 1

    // Размеры по умолчанию
    width: 80
    height: 80

    // Ограничения на минимальный размер
    property int minSize: 20

    // Визуальная рамка выделения
    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        color: "transparent"
        border.color: "#2979FF"
        border.width: 2
        visible: root.isSelected
        radius: parent.radius + 2
    }

    // === ЛОГИКА ОТРИСОВКИ ===
    Loader {
        anchors.fill: parent
        sourceComponent: {
            switch(root.type) {
                case "wall": return wallComponent;
                case "window": return windowComponent;
                case "wc": return wcComponent;
                case "plant": return plantComponent;
                case "room": return roomComponent; // Новый тип
                default: return tableComponent;
            }
        }
    }

    // --- КОМПОНЕНТЫ ---

    Component {
        id: tableComponent
        Rectangle {
            color: root.itemColor
            border.color: "#555"
            border.width: 1
            radius: root.shapeType === "ellipse" ? width/2 : 8
            Text {
                text: root.text
                anchors.centerIn: parent
                font.bold: true
            }
        }
    }

    Component { id: wallComponent; Rectangle { color: "#424242" } }

    Component {
        id: windowComponent
        Rectangle {
            color: "#B3E5FC"; border.color: "#0288D1"; border.width: 2
            Rectangle { width: 2; height: parent.height; color: "#0288D1"; anchors.centerIn: parent }
        }
    }

    Component {
        id: wcComponent
        Rectangle {
            color: "#E0E0E0"; border.color: "gray"
            Text { text: "WC"; font.bold: true; anchors.centerIn: parent }
        }
    }

    Component {
        id: plantComponent
        Item {
            Text { text: "🌿"; font.pixelSize: Math.min(parent.width, parent.height) * 0.8; anchors.centerIn: parent }
        }
    }

    // Новый компонент КОМНАТА (ПОЛ)
    Component {
        id: roomComponent
        Rectangle {
            color: root.itemColor // Цвет пола передается при создании
            border.color: "#BDBDBD"
            border.width: 1
            Text {
                text: root.text // Название комнаты, например "Зал 1"
                anchors.centerIn: parent
                color: "#9E9E9E"
                font.pixelSize: 20
            }
        }
    }

    // === УПРАВЛЕНИЕ ===

    // 1. Клик для выделения (пробрасываем наверх)
    MouseArea {
        anchors.fill: parent
        onPressed: (mouse) => {
            root.forceActiveFocus()
            mouse.accepted = false // Пропускаем дальше для DragHandler
        }
    }

    // 2. Перетаскивание (работает, если НЕ тянем за ручку ресайза)
    DragHandler {
        target: root
        // Сетка 10px
        onActiveChanged: {
            if (!active) {
                root.x = Math.round(root.x / 10) * 10
                root.y = Math.round(root.y / 10) * 10
            }
        }
    }

    // 3. РУЧКА ИЗМЕНЕНИЯ РАЗМЕРА (RESIZE HANDLE)
    // Появляется только если объект выбран
    Rectangle {
        id: resizeHandle
        width: 15; height: 15
        color: "#2979FF"
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: root.isSelected
        radius: 5

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeFDiagCursor
            drag.target: parent // Тянем саму ручку (визуально, но мы перехватим координаты)
            drag.axis: Drag.XAndYAxis

            property int startX: 0
            property int startY: 0
            property int startWidth: 0
            property int startHeight: 0

            onPressed: {
                startX = mouseX
                startY = mouseY
                startWidth = root.width
                startHeight = root.height
            }

            onPositionChanged: {
                if (pressed) {
                    // Вычисляем дельту
                    var newW = startWidth + (mouseX - startX)
                    var newH = startHeight + (mouseY - startY)

                    // Применяем с сеткой 10px
                    newW = Math.round(newW / 10) * 10
                    newH = Math.round(newH / 10) * 10

                    if (newW >= root.minSize) root.width = newW
                    if (newH >= root.minSize) root.height = newH
                }
            }
        }
    }
}
