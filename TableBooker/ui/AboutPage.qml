import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "components"
import "Theme.js" as Theme

Page {
    id: aboutPage
    title: "О программе"
    
    background: Rectangle {
        color: Theme.background
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width * 0.9
        spacing: Theme.spacingLarge

        // Логотип
        Text {
            text: "🍽️"
            font.pixelSize: 80
            Layout.alignment: Qt.AlignHCenter
        }

        Label {
            text: "TableBooker v1.0"
            font.bold: true
            font.pixelSize: Theme.fontSizeXXLarge
            color: Theme.textPrimary
            Layout.alignment: Qt.AlignHCenter
        }

        Label {
            text: "Система бронирования столиков\n\n" +
                  "Приложение позволяет администраторам создавать схемы залов,\n" +
                  "а пользователям — бронировать столики на удобное время."
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSizeMedium
        }

        Rectangle {
            height: 1
            color: Theme.divider
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacingMedium
            Layout.bottomMargin: Theme.spacingMedium
        }

        Label {
            text: "Разработал:\nСтудент группы СУ-31\nСанец Д.С."
            font.italic: true
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSizeMedium
        }

        Button {
            id: backButton
            text: Theme.iconBack + " Назад"
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Theme.spacingLarge
            height: 48
            width: 200
            
            background: Rectangle {
                color: Theme.primary
                radius: Theme.radiusMedium
                opacity: backButton.pressed ? 0.8 : 1.0
                
                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }
            }
            
            contentItem: Text {
                text: backButton.text
                color: "white"
                font.pixelSize: Theme.fontSizeMedium
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            
            onClicked: aboutPage.StackView.view.pop()
        }
    }
}
