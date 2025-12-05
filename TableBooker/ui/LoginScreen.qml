import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import com.tablebooker.api 1.0
import "components"
import "Theme.js" as Theme

Page {
    id: loginPage
    title: "Вход в TableBooker"

    background: Rectangle {
        color: Theme.background
    }

    // Flickable для прокрутки на небольших экранах
    Flickable {
        id: flickable
        anchors.fill: parent
        // Высота контента: либо высота колонки с отступами, либо высота экрана (чтобы центрировать, если контент маленький)
        contentHeight: Math.max(layout.implicitHeight + 100, height)
        contentWidth: width
        clip: true

        // Контейнер для выравнивания
        Item {
            width: parent.width
            height: flickable.contentHeight

            ColumnLayout {
                id: layout
                width: Math.min(parent.width * 0.85, 400) // Ограничиваем ширину формы
                anchors.centerIn: parent // Центрируем форму внутри Flickable
                spacing: Theme.spacingLarge

                // --- ЛОГОТИП И ЗАГОЛОВОК ---
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Theme.spacingSmall

                    // Логотип
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 100
                        height: 100
                        radius: 50
                        color: Theme.surface
                        border.color: Theme.primary
                        border.width: 2

                        Text {
                            text: Theme.iconRestaurant
                            font.pixelSize: 48
                            anchors.centerIn: parent
                        }

                        // Тень логотипа
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -4
                            z: -1
                            radius: 54
                            color: Theme.primary
                            opacity: 0.1
                        }
                    }

                    // Название
                    Text {
                        text: "TableBooker"
                        font.bold: true
                        font.pixelSize: Theme.fontSizeXXLarge
                        color: Theme.primary

                        Layout.alignment: Qt.AlignHCenter
                        horizontalAlignment: Text.AlignHCenter
                        Layout.topMargin: Theme.spacingMedium
                    }

                    // Подзаголовок
                    Text {
                        text: "Бронируйте лучшие места"
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.textSecondary

                        Layout.alignment: Qt.AlignHCenter
                        horizontalAlignment: Text.AlignHCenter
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
                            width: 40
                            height: 40
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
                    spacing: Theme.spacingMedium

                    // Кнопка "Войти" (Явно задаем стиль и центрирование)
                    Button {
                        id: loginButton
                        text: "Войти"
                        Layout.fillWidth: true
                        height: 50 // Чуть выше стандартного для удобства

                        background: Rectangle {
                            color: Theme.primary
                            radius: Theme.radiusMedium
                            opacity: parent.pressed ? 0.8 : 1.0
                        }

                        // Явное центрирование текста
                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            font.pixelSize: Theme.fontSizeMedium
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: loginButtonAction()
                    }

                    // Кнопка "Создать аккаунт" (Стиль Flat)
                    Button {
                        text: "Создать аккаунт"
                        Layout.fillWidth: true
                        height: 50

                        background: Rectangle {
                            color: "transparent"
                            radius: Theme.radiusMedium
                            border.color: Theme.primary // Добавил рамку для четкости
                            border.width: 1
                            opacity: parent.pressed ? 0.6 : 1.0
                        }

                        // Явное центрирование текста
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
            radius: Theme.radiusMedium
        }

        Label {
            id: errorLabel
            text: ""
            color: Theme.textPrimary
            wrapMode: Text.Wrap
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
