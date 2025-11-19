import QtQuick 2.15
import QtQuick.Controls 2.15

Page {
    title: "Админ-панель"

    Column {
        anchors.centerIn: parent
        spacing: 10

        Label {
            text: "Панель Администратора"
            font.pixelSize: 24
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            text: "Здесь будет управление заведениями"
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
