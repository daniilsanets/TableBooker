import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import com.tablebooker.api 1.0
import "admin"
import "user"
import "components"
import "Theme.js" as Theme

Page {
    id: loginPage
    title: "Вход"
    
    background: Rectangle {
        color: Theme.background
    }

    ColumnLayout {
        width: parent.width * 0.9
        spacing: Theme.spacingLarge
        anchors.centerIn: parent

        // Логотип и заголовок
        Column {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 40
            spacing: Theme.spacingMedium
            
            Text {
                text: "🍽️"
                font.pixelSize: 80
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Text {
                text: "TableBooker"
                font.pixelSize: Theme.fontSizeXXLarge
                font.bold: true
                color: Theme.textPrimary
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Text {
                text: "Бронирование столиков"
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.textSecondary
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        // Поля ввода
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingMedium
            
            // Поле логина
            Rectangle {
                Layout.fillWidth: true
                height: 56
                color: Theme.surface
                radius: Theme.radiusMedium
                border.color: loginField.activeFocus ? Theme.primary : Theme.divider
                border.width: loginField.activeFocus ? 2 : 1
                
                // Тонкая тень
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -1
                    z: -1
                    color: "#08000000"
                    radius: parent.radius + 1
                    opacity: loginField.activeFocus ? 0.1 : 0.05
                }
                
                Item {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    height: 40
                    
                    TextField {
                        id: loginField
                        anchors.fill: parent
                        placeholderText: "Телефон, Email или Логин"
                        background: Item {}
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.textPrimary
                    }
                }
            }
            
            // Поле пароля
            Rectangle {
                Layout.fillWidth: true
                height: 56
                color: Theme.surface
                radius: Theme.radiusMedium
                border.color: passwordField.activeFocus ? Theme.primary : Theme.divider
                border.width: passwordField.activeFocus ? 2 : 1
                
                // Тонкая тень
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -1
                    z: -1
                    color: "#08000000"
                    radius: parent.radius + 1
                    opacity: passwordField.activeFocus ? 0.1 : 0.05
                }
                
                Item {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    height: 40
                    
                    Row {
                        width: parent.width
                        height: parent.height
                        spacing: 12
                        
                        TextField {
                            id: passwordField
                            width: parent.width - 52
                            height: parent.height
                            placeholderText: "Пароль"
                            echoMode: showPassArea.checked ? TextInput.Normal : TextInput.Password
                            background: Item {}
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.textPrimary
                        }
                        
                        MouseArea {
                            id: showPassArea
                            width: 40
                            height: 40
                        
                            property bool checked: false
                            
                            Text {
                                text: parent.checked ? Theme.iconVisibilityOff : Theme.iconVisibility
                                font.pixelSize: 24
                                color: Theme.textSecondary
                                anchors.centerIn: parent
                            }
                            
                            onClicked: checked = !checked
                        }
                    }
            }
        }

        // Кнопка входа
        Button {
            id: loginButton
            text: "Войти"
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacingMedium
            height: 56
            
            background: Rectangle {
                color: Theme.primary
                radius: Theme.radiusMedium
                opacity: loginButton.pressed ? 0.9 : 1.0
                
                // Тень для кнопки
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -2
                    z: -1
                    color: Theme.primary
                    radius: parent.radius + 2
                    opacity: 0.3
                }
                
                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }
            }
            
            contentItem: Text {
                text: loginButton.text
                color: "white"
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            onClicked: {
                var user = BackendApi.authenticateUser(loginField.text, passwordField.text)

                if (user.id) {
                    console.log("Успех! Роль: " + user.role)

                    if (user.role == "admin"){
                        loginPage.StackView.view.push("admin/AdminDashboardPage.qml")
                    } else {
                        loginPage.StackView.view.push("user/UserPremisesListPage.qml")
                    }

                } else {
                    errorDialog.text = "Неверный логин или пароль"
                    errorDialog.open()
                }
            }
        }

        // Кнопка регистрации
        Button {
            text: "Нет аккаунта? Зарегистрироваться"
            Layout.fillWidth: true
            flat: true
            
            contentItem: Text {
                text: parent.text
                color: Theme.primary
                font.pixelSize: Theme.fontSizeMedium
                horizontalAlignment: Text.AlignHCenter
            }

            onClicked: loginPage.StackView.view.push("RegistrationScreen.qml")
        }
    }
    
    // Диалог ошибки
    Dialog {
        id: errorDialog
        property alias text: errorLabel.text
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: parent.width * 0.8
        modal: true
        standardButtons: Dialog.Ok
        
        background: Rectangle {
            color: Theme.surface
            radius: Theme.radiusMedium
        }
        
        Label {
            id: errorLabel
            text: ""
            color: Theme.error
            wrapMode: Text.WordWrap
        }
    }
}
}
