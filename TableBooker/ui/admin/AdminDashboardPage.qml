import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import com.tablebooker.api 1.0
import "../components"
import "../Theme.js" as Theme

Page {
    id: adminDashboard
    title: "Админ-панель"
    
    background: Rectangle {
        color: Theme.background
    }

    property var premisesModel: []

    function refreshData() {
        var adminId = BackendApi.currentUserId
        console.log("Загрузка заведений для админа ID:", adminId)
        premisesModel = BackendApi.getPremisesForAdmin(adminId)
    }

    Component.onCompleted: refreshData()

    header: ToolBar {
        background: Rectangle {
            color: Theme.primary
        }
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16

            Text {
                text: "⚙️"
                font.pixelSize: 24
            }
            
            Label {
                text: "Админ-панель"
                font.bold: true
                font.pixelSize: Theme.fontSizeLarge
                color: "white"
                Layout.fillWidth: true
            }

            ToolButton {
                Text {
                    text: Theme.iconPerson
                    font.pixelSize: 24
                    color: "white"
                    anchors.centerIn: parent
                }
                onClicked: adminDashboard.StackView.view.push("../user/ProfilePage.qml")
            }
        }
    }

    Dialog {
            id: createDialog
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.9, 360)
            modal: true
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

            // Переменные для фокуса (чтобы клавиатура не закрывала диалог)
            focus: true

            background: Rectangle {
                color: Theme.surface
                radius: Theme.radiusLarge
                // Тень
                Rectangle {
                    z: -1; anchors.fill: parent; anchors.margins: -4
                    color: "#20000000"; radius: parent.radius + 4
                }
            }

            contentItem: ColumnLayout {
                spacing: 20

                // Заголовок
                Column {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "✨ Новое заведение"
                        font.bold: true
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.textPrimary
                    }

                    Text {
                        text: "Введите название, чтобы начать планировку зала."
                        color: Theme.accent
                        font.pixelSize: Theme.fontSizeSmall
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }
                }

                // Поле ввода
                TextField {
                    id: newPremiseName
                    Layout.fillWidth: true
                    placeholderText: "Например: Lounge Bar"
                    font.pixelSize: Theme.fontSizeMedium

                    background: Rectangle {
                        color: Theme.surfaceDark
                        radius: Theme.radiusMedium
                        border.color: parent.activeFocus ? Theme.primary : "transparent"
                        border.width: 2
                    }
                    // Авто-фокус при открытии
                    Component.onCompleted: createDialog.opened.connect(() => { forceActiveFocus() })
                }

                // Кнопки
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Button {
                        text: "Отмена"
                        Layout.fillWidth: true
                        flat: true
                        contentItem: Text {
                            text: parent.text
                            color: Theme.textSecondary
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle { color: "transparent" }
                        onClicked: createDialog.close()
                    }

                    Button {
                        text: "Создать"
                        Layout.fillWidth: true
                        enabled: newPremiseName.text.length > 0

                        background: Rectangle {
                            color: parent.enabled ? Theme.primary : Theme.divider
                            radius: Theme.radiusMedium
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            if (newPremiseName.text === "") return
                            var data = { "name": newPremiseName.text, "bgImagePath": "" }
                            var success = BackendApi.createPremises(data)
                            if (success) {
                                newPremiseName.text = ""
                                refreshData()
                                createDialog.close()
                            }
                        }
                    }
                }
            }

            enter: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 200 }
                    NumberAnimation { property: "y"; from: parent.height; to: (parent.height - height)/2; duration: 250; easing.type: Easing.OutCubic }
                }
            }
            exit: Transition {
                NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 150 }
            }
        }
    // --- Основной интерфейс ---
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Заголовок секции - строгий стиль
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 16
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.bottomMargin: 8
            height: 32
            color: "transparent"
            
            Text {
                text: "Мои заведения"
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                font.weight: Font.DemiBold
                color: Theme.textPrimary
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Список заведений
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: premisesModel
            spacing: 12

            delegate: Rectangle {
                width: listView.width - Theme.spacingMedium * 2
                height: 80
                x: Theme.spacingMedium
                color: Theme.surface
                radius: Theme.radiusSmall
                border.color: Theme.divider
                border.width: 1
                
                // Профессиональная тень
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -3
                    z: -1
                    color: "#0D000000"
                    radius: parent.radius + 3
                    opacity: 0.15
                }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -1
                    z: -1
                    color: "#1A000000"
                    radius: parent.radius + 1
                    opacity: 0.08
                }
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    anchors.topMargin: 12
                    anchors.bottomMargin: 12
                    spacing: 16
                    
                    // Иконка - более компактная
                    Rectangle {
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        radius: Theme.radiusSmall
                        color: Theme.accent
                        
                        Text {
                            text: Theme.iconRestaurant
                            font.pixelSize: 20
                            anchors.centerIn: parent
                        }
                    }
                    
                    // Информация
                    Column {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2
                        
                        Text {
                            text: modelData.name
                            font.pixelSize: Theme.fontSizeLarge
                            font.bold: true
                            font.weight: Font.DemiBold
                            color: Theme.textPrimary
                        }
                        
                        Text {
                            text: "Нажмите для редактирования"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.textSecondary
                        }
                    }
                    
                    // Стрелка - минимальный отступ
                    Text {
                        text: "›"
                        font.pixelSize: 20
                        color: Theme.textSecondary
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 16
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        console.log("Редактируем ID:", modelData.id)
                        adminDashboard.StackView.view.push("HallEditorPage.qml", {
                            "premisesId": modelData.id,
                            "premisesName": modelData.name
                        })
                    }
                }
            }

            // Пустое состояние
            Text {
                anchors.centerIn: parent
                text: "Нет заведений. Создайте первое!"
                visible: listView.count === 0
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSizeMedium
            }
        }

        // Кнопки действий
        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: 16
            spacing: 12
            
            Button {
                id: addButton
                text: Theme.iconAdd + " Добавить заведение"
                Layout.fillWidth: true
                height: 56
                
                background: Rectangle {
                    color: Theme.primary
                    radius: Theme.radiusMedium
                    opacity: addButton.pressed ? 0.8 : 1.0
                    
                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }
                }
                
                contentItem: Text {
                    text: addButton.text
                    color: "white"
                    font.pixelSize: Theme.fontSizeLarge
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                onClicked: createDialog.open()
            }

            Button {
                text: Theme.iconTable + " Перейти к бронированию"
                Layout.fillWidth: true
                height: 48
                
                background: Rectangle {
                    color: Theme.surface
                    radius: Theme.radiusMedium
                    border.color: Theme.divider
                    border.width: 1
                }
                
                contentItem: Text {
                    text: parent.text
                    color: Theme.textPrimary
                    font.pixelSize: Theme.fontSizeMedium
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                onClicked: adminDashboard.StackView.view.push("../user/UserPremisesListPage.qml")
            }

        }
    }
}
