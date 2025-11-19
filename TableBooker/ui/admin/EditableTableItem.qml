import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root
    property string type: "rect" // "rect" или "ellipse"
    property alias text: label.text
    property bool isSelected: false // Для выделения (на будущее)

    // Размеры по умолчанию (если не заданы)
    width: 80
    height: 80

    // Визуальная часть (Сам стол)
    Rectangle {
        anchors.fill: parent
        color: dragHandler.active ? "#81C784" : "#E0E0E0" // Зеленеет, когда тащим
        border.color: "black"
        border.width: 2
        radius: root.type === "ellipse" ? width / 2 : 5 // Круг или скругленный квадрат

        Text {
            id: label
            anchors.centerIn: parent
            font.bold: true
        }
    }

    // Магия перетаскивания
    DragHandler {
        id: dragHandler
        target: root // Указываем, что таскать будем весь этот Item (root)
    }
}
