import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import com.tablebooker.api 1.0
import "components"
import "Theme.js" as Theme

Page {
    id: registrationPage
    title: "Регистрация"
    
    background: Rectangle {
        color: Theme.background
    }

    Dialog {
        id: errorDialog
        title: "Ошибка"
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: parent.width * 0.8
        modal: true
        standardButtons: Dialog.Ok
        property alias text: errorLabel.text
        
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

    Flickable {
        anchors.fill: parent
        contentHeight: contentColumn.height + 40
        clip: true
        
        ColumnLayout {
            id: contentColumn
            width: parent.width * 0.9
            spacing: Theme.spacingMedium
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 20

            // Заголовок
            Column {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: Theme.spacingLarge
                spacing: Theme.spacingSmall
                
                Text {
                    text: "Создание аккаунта"
                    font.bold: true
                    font.pixelSize: Theme.fontSizeXLarge
                    color: Theme.textPrimary
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                Text {
                    text: "Заполните все поля для регистрации"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.textSecondary
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            // Поле имени
            Rectangle {
                Layout.fillWidth: true
                height: 56
                color: Theme.surface
                radius: Theme.radiusMedium
                border.color: usernameField.activeFocus ? Theme.primary : Theme.divider
                border.width: usernameField.activeFocus ? 2 : 1
                
                Item {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    height: 40
                    
                    Row {
                        anchors.fill: parent
                        spacing: 12
                        
                        Text {
                            text: Theme.iconPerson
                            font.pixelSize: 24
                            color: Theme.textSecondary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        TextField {
                            id: usernameField
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.parent.width - 60
                            placeholderText: "Полное имя"
                            background: Item {}
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.textPrimary
                        }
                    }
                }
            }

            // Поле Email
            Rectangle {
                Layout.fillWidth: true
                height: 56
                color: Theme.surface
                radius: Theme.radiusMedium
                border.color: emailField.activeFocus ? Theme.primary : (emailField.acceptableInput || emailField.text === "" ? Theme.divider : Theme.error)
                border.width: emailField.activeFocus ? 2 : 1
                
                Item {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    height: 40
                    
                    Row {
                        anchors.fill: parent
                        spacing: 12
                        
                        Text {
                            text: Theme.iconEmail
                            font.pixelSize: 24
                            color: Theme.textSecondary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        TextField {
                            id: emailField
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.parent.width - 60
                            placeholderText: "Email"
                            inputMethodHints: Qt.ImhEmailCharactersOnly
                            validator: RegularExpressionValidator {
                                regularExpression: /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/
                            }
                            background: Item {}
                            font.pixelSize: Theme.fontSizeMedium
                            color: acceptableInput || text === "" ? Theme.textPrimary : Theme.error
                        }
                    }
                }
            }

            // Поле телефона
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSmall

                Rectangle {
                    Layout.preferredWidth: 120
                    height: 56
                    color: Theme.surface
                    radius: Theme.radiusMedium
                    border.color: Theme.divider
                    border.width: 1
                    
                    ComboBox {
                        id: countrySelector
                        anchors.fill: parent
                        anchors.margins: 4
                        
                        background: Item {}
                        
                        model: ListModel {
                            ListElement { code: "+375"; flag: "🇧🇾"; text: "🇧🇾 +375" }
                        }

                        textRole: "text"
                        currentIndex: 0
                        
                        contentItem: Text {
                            text: countrySelector.displayText
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.textPrimary
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 8
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 56
                    color: Theme.surface
                    radius: Theme.radiusMedium
                    border.color: phoneLocalField.activeFocus ? Theme.primary : (phoneLocalField.acceptableInput || phoneLocalField.text === "" ? Theme.divider : Theme.error)
                    border.width: phoneLocalField.activeFocus ? 2 : 1
                    
                    Item {
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        height: 40
                        
                        Row {
                            anchors.fill: parent
                            spacing: 12
                            
                            Text {
                                text: Theme.iconPhone
                                font.pixelSize: 24
                                color: Theme.textSecondary
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            
                            TextField {
                                id: phoneLocalField
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.parent.width - 60
                                placeholderText: "29 111 22 33"
                                inputMethodHints: Qt.ImhDigitsOnly
                                validator: RegularExpressionValidator {
                                    regularExpression: /^(25|29|33|44)[0-9]{7}$/
                                }
                                background: Item {}
                                font.pixelSize: Theme.fontSizeMedium
                                color: acceptableInput || text === "" ? Theme.textPrimary : Theme.error
                                onTextChanged: {
                                    if (text.length >= 2) {
                                        var code = text.substring(0, 2)
                                        if (code !== "25" && code !== "29" && code !== "33" && code !== "44") {
                                            // Показываем ошибку только если поле не пустое
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Поле никнейма
            Rectangle {
                Layout.fillWidth: true
                height: 56
                color: Theme.surface
                radius: Theme.radiusMedium
                border.color: nicknameField.activeFocus ? Theme.primary : Theme.divider
                border.width: nicknameField.activeFocus ? 2 : 1
                
                Item {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    height: 40
                    
                    Row {
                        anchors.fill: parent
                        spacing: 12
                        
                        Text {
                            text: Theme.iconPerson
                            font.pixelSize: 24
                            color: Theme.textSecondary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        TextField {
                            id: nicknameField
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.parent.width - 60
                            placeholderText: "Никнейм"
                            background: Item {}
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.textPrimary
                        }
                    }
                }
            }

            // Поле пароля
            Rectangle {
                Layout.fillWidth: true
                height: 56
                color: Theme.surface
                radius: Theme.radiusMedium
                border.color: passwordField.activeFocus ? Theme.primary : (passwordField.text.length >= 6 || passwordField.text === "" ? Theme.divider : Theme.error)
                border.width: passwordField.activeFocus ? 2 : 1
                
                Item {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    height: 40
                    
                    Row {
                        anchors.fill: parent
                        spacing: 12
                        
                        TextField {
                            id: passwordField
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.parent.width - 60
                            placeholderText: "Пароль (мин. 6 символов)"
                            echoMode: regShowPass.checked ? TextInput.Normal : TextInput.Password
                            background: Item {}
                            font.pixelSize: Theme.fontSizeMedium
                            color: text.length >= 6 || text === "" ? Theme.textPrimary : Theme.error
                        }
                        
                        MouseArea {
                            id: regShowPass
                            width: 40
                            height: 40
                            anchors.right: parent.right
                            anchors.rightMargin: 0
                            anchors.verticalCenter: parent.verticalCenter
                            
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

            // Кнопка регистрации
            Button {
                id: registerButton
                text: "Зарегистрироваться"
                Layout.fillWidth: true
                Layout.topMargin: Theme.spacingMedium
                height: 56

                background: Rectangle {
                    color: Theme.primary
                    radius: Theme.radiusMedium
                    opacity: registerButton.pressed ? 0.8 : 1.0
                    
                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }
                }
                
                contentItem: Text {
                    text: registerButton.text
                    color: "white"
                    font.pixelSize: Theme.fontSizeLarge
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    if (usernameField.text === "" || nicknameField.text === "") {
                        showError("Заполните имя и никнейм")
                        return
                    }

                    if (!emailField.acceptableInput) {
                        showError("Некорректный Email")
                        return
                    }

                    if (!phoneLocalField.acceptableInput) {
                        showError("Номер телефона должен содержать 9 цифр (без кода)")
                        return
                    }

                    if (passwordField.text.length < 6) {
                        showError("Пароль слишком короткий")
                        return
                    }

                    var code = countrySelector.model.get(countrySelector.currentIndex).code
                    var fullPhone = code + phoneLocalField.text

                    var userData = {
                        "username": usernameField.text,
                        "password": passwordField.text,
                        "email": emailField.text,
                        "phone": fullPhone,
                        "nickname": nicknameField.text
                    }

                    var isSuccess = BackendApi.registerUser(userData)

                    if (isSuccess) {
                        console.log("Регистрация успешна!")
                        registrationPage.StackView.view.pop()
                    } else {
                        showError("Ошибка: Пользователь с таким логином/телефоном уже есть")
                    }
                }
            }

            // Кнопка назад
            Button {
                text: "Назад"
                Layout.fillWidth: true
                Layout.bottomMargin: 20
                flat: true
                
                contentItem: Text {
                    text: parent.text
                    color: Theme.primary
                    font.pixelSize: Theme.fontSizeMedium
                    horizontalAlignment: Text.AlignHCenter
                }
                
                onClicked: registrationPage.StackView.view.pop()
            }
        }
    }

    function showError(msg) {
        errorDialog.text = msg
        errorDialog.open()
    }
}
