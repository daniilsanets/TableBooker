import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    id: aboutPage
    title: "О программе"

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width * 0.9
        spacing: 20

        Label {
            text: "TableBooker v1.0"
            font.bold: true
            font.pixelSize: 24
            Layout.alignment: Qt.AlignHCenter
        }

        Label {
            text: "Лабораторная работа: Система бронирования столиков.\n" +
                  "Приложение позволяет администраторам создавать схемы залов,\n" +
                  "а пользователям — бронировать столики на удобное время."
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Rectangle {
            height: 1
            color: "gray"
            Layout.fillWidth: true
        }

        Label {
            text: "Разработал:\nСтудент группы СУ-31\n Санец Д.С."
            font.italic: true
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
        }

        Button {
            text: "Назад"
            Layout.alignment: Qt.AlignHCenter
            onClicked: aboutPage.StackView.view.pop()
        }
    }
}
