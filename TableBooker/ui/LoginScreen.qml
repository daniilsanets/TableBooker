import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import com.tablebooker.api 1.0
import "components"
import "Theme.js" as Theme

Page {
    id: loginPage
    title: "Вход в TableBooker"

    background: Rectangle {
        color: Theme.background
    }

    Flickable {
        id: flickable
        anchors.fill: parent
        contentHeight: Math.max(layout.implicitHeight + 100, height)
        contentWidth: width
        clip: true

        Item {
            width: parent.width
            height: flickable.contentHeight

            ColumnLayout {
                id: layout
                width: Math.min(parent.width * 0.85, 400)
                anchors.centerIn: parent
                // Сдвигаем форму вверх от геометрического центра
                anchors.verticalCenterOffset: -60
                spacing: Theme.spacingLarge

                // --- ЛОГОТИП И ЗАГОЛОВОК ---
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Theme.spacingSmall

                    // Логотип с тенью
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 100; height: 100
                        radius: 50
                        color: Theme.surface
                        border.color: Theme.primary
                        border.width: 2

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: "#20000000"
                            shadowBlur: 16
                            shadowVerticalOffset: 4
                        }

                        Text {
                            text: Theme.iconRestaurant
                            font.pixelSize: 48
                            anchors.centerIn: parent
                        }
                    }

                    Text {
                        text: "TableBooker"
                        font.bold: true
                        font.pixelSize: Theme.fontSizeXXLarge
                        color: Theme.primary
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: Theme.spacingMedium
                    }

                    Text {
                        text: "Бронируйте лучшие места"
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.textSecondary
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                // --- ПОЛЯ ВВОДА ---
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingMedium

                    MaterialTextField {
                        id: loginField
                        Layout.fillWidth: true
                        placeholderText: "Телефон или логин"
                        iconText: Theme.iconPerson
                        onAccepted: passwordField.forceActiveFocus()
                    }

                    MaterialTextField {
                        id: passwordField
                        Layout.fillWidth: true
                        placeholderText: "Пароль"
                        iconText: Theme.iconLock
                        echoMode: showPassArea.checked ? TextInput.Normal : TextInput.Password
                        rightPadding: 48

                        Item {
                            width: 40; height: 40
                            anchors.right: parent.right
                            anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            z: 10
                            Text {
                                text: showPassArea.checked ? Theme.iconVisibilityOff : Theme.iconVisibility
                                font.pixelSize: 22
                                color: Theme.textSecondary
                                anchors.centerIn: parent
                                opacity: 0.7
                            }
                            MouseArea {
                                id: showPassArea
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                property bool checked: false
                                onClicked: checked = !checked
                            }
                        }
                        onAccepted: loginButtonAction()
                    }

                    Text {
                        text: "Забыли пароль?"
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSizeSmall
                        Layout.alignment: Qt.AlignRight
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: console.log("Восстановление...")
                        }
                    }
                }

                // --- КНОПКИ ---
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.spacingMedium
                    spacing: 16

                    // Кнопка "Войти" (Градиент + Тень)
                    Button {
                        id: loginButton
                        text: "Войти"
                        Layout.fillWidth: true
                        height: 56 // Кнопка выше и удобнее

                        background: Rectangle {
                            radius: 28 // Полное скругление (Pill shape)
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Theme.primary }
                                GradientStop { position: 1.0; color: Theme.primaryDark }
                            }

                            // Тень кнопки
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowColor: "#40000000" // Полупрозрачная тень
                                shadowBlur: 10
                                shadowVerticalOffset: 4
                            }

                            // Эффект нажатия (затемнение)
                            Rectangle {
                                anchors.fill: parent
                                radius: 28
                                color: "black"
                                opacity: parent.parent.pressed ? 0.1 : 0
                            }
                        }

                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            font.pixelSize: Theme.fontSizeLarge
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: loginButtonAction()
                    }

                    // Кнопка "Создать аккаунт" (Outline Style)
                    Button {
                        text: "Создать аккаунт"
                        Layout.fillWidth: true
                        height: 56

                        background: Rectangle {
                            color: parent.pressed ? "#F5F5F5" : "transparent"
                            radius: 28
                            border.color: Theme.primary
                            border.width: 2
                        }

                        contentItem: Text {
                            text: parent.text
                            color: Theme.primary
                            font.pixelSize: Theme.fontSizeMedium
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: loginPage.StackView.view.push("RegistrationScreen.qml")
                    }
                }
            }
        }
    }

    // --- ЛОГИКА ---
    function loginButtonAction() {
        if (loginField.text === "" || passwordField.text === "") {
            errorDialog.text = "Введите логин и пароль"
            errorDialog.open()
            return
        }

        var user = BackendApi.authenticateUser(loginField.text, passwordField.text)

        if (user.id) {
            loginPage.StackView.view.replace("user/UserPremisesListPage.qml")
        } else {
            errorDialog.text = "Неверный логин или пароль"
            errorDialog.open()
        }
    }

    Dialog {
        id: errorDialog
        title: "Ошибка"
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: Math.min(parent.width * 0.8, 300)
        modal: true
        standardButtons: Dialog.Ok
        property alias text: errorLabel.text

        background: Rectangle {
            color: Theme.surface
            radius: Theme.radiusLarge
        }

        contentItem: ColumnLayout {
            spacing: 16
            Text {
                text: "⚠️"
                font.pixelSize: 32
                Layout.alignment: Qt.AlignHCenter
            }
            Label {
                id: errorLabel
                text: ""
                color: Theme.textPrimary
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }
        }
    }
}
