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
        layer.enabled: root.type !== "room" && root.type !== "floor"
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#40000000"
            shadowBlur: 0.5
            shadowHorizontalOffset: 2
            shadowVerticalOffset: 2
        }

        // Текст (имя стола или метка WC)
        Text {
            anchors.centerIn: parent
            text: root.itemName
            visible: root.type === "table" || root.type === "wc"
            font.pixelSize: 14
            font.bold: true
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

    // ЛОГИКА ПЕРЕМЕЩЕНИЯ
    DragHandler {
        target: root
        enabled: root.isEditable && root.type !== "room" // Комнату двигать нельзя (обычно)
        onActiveChanged: if (active) root.clicked() // Выделяем при нажатии
        onTranslationChanged: root.moved(root.x, root.y)
    }

    // КЛИК (ВЫДЕЛЕНИЕ)
    TapHandler {
        enabled: root.isEditable
        onTapped: root.clicked()
    }

    // РУЧКА ИЗМЕНЕНИЯ РАЗМЕРА (Resize Handle)
    Rectangle {
        width: 24; height: 24
        color: "#FF5722"
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        radius: 12
        visible: root.isEditable && root.isSelected && root.type !== "plant"

        DragHandler {
            target: null
            property real startW: 0; property real startH: 0
            onActiveChanged: { if (active) { startW = root.width; startH = root.height } }
            onTranslationChanged: {
                if (active) {
                    var newW = Math.max(20, startW + translation.x)
                    var newH = Math.max(20, startH + translation.y)
                    root.width = newW
                    root.height = newH
                    root.resized(newW, newH)
                }
            }
        }
    }

    // Обработчик для Юзера (просто клик)
    TapHandler {
        enabled: !root.isEditable
        onTapped: root.clicked()
    }
}
