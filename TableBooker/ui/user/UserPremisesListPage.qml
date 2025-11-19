import QtQuick 2.15
import QtQuick.Controls 2.15

Page {
    title: "Выбор заведения"

    Column {
        anchors.centerIn: parent
        spacing: 10

        Label {
            text: "Кафе и Рестораны"
            font.pixelSize: 24
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            text: "Здесь будет список доступных мест"
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
