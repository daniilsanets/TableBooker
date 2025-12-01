import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import com.tablebooker.api 1.0
import "Theme.js" as Theme

Page {
    id: loginPage
    title: "Вход в TableBooker"

    // Оборачиваем всё в Flickable, чтобы экран можно было прокручивать,
    // если вылезет клавиатура
    Flickable {
        anchors.fill: parent
        contentHeight: layout.height + 100 // Высота контента + запас
        clip: true

        ColumnLayout {
            id: layout
            width: parent.width * 0.85
            spacing: 20

            // Прибиваем к верху, отступ всего 40 пикселей
            anchors.top: parent.top
            anchors.topMargin: 40
            anchors.horizontalCenter: parent.horizontalCenter

            // Логотип или заголовок (опционально)
            Label {
                text: "TableBooker"
                font.bold: true
                font.pixelSize: 32
                color: "#2196F3"
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 20
            }

            TextField {
                id: loginField
                placeholderText: qsTr("Логин или телефон")
                Layout.fillWidth: true
                // При нажатии Enter переходим к паролю
                onAccepted: passwordField.forceActiveFocus()
            }

            TextField {
                id: passwordField
                placeholderText: qsTr("Пароль")
                echoMode: showPassArea.checked ? TextInput.Normal : TextInput.Password
                Layout.fillWidth: true
                rightPadding: 50
                // При нажатии Enter жмется кнопка "Войти"
                onAccepted: loginButton.clicked()

                Text {
                    id: eyeIcon
                    text: showPassArea.checked ? "🙈" : "👁️"
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: 10
                    color: "gray"
                    z: 1
                }

                MouseArea {
                    id: showPassArea
                    anchors.fill: eyeIcon
                    anchors.margins: -10
                    property bool checked: false
                    onClicked: checked = !checked
                }
            }

            Button {
                id: loginButton
                text: "Войти"
                Layout.fillWidth: true
                highlighted: true

                onClicked: {
                    console.log("Попытка входа...")
                    var user = BackendApi.authenticateUser(loginField.text, passwordField.text)

                    if (user.id) {
                        console.log("Успешный вход! ID:", user.id)

                        // Переход на главный экран
                        // ВАЖНО: Мы используем replace, чтобы нельзя было вернуться назад кнопкой "Назад"
                        loginPage.StackView.view.replace("user/UserPremisesListPage.qml")
                    } else {
                        console.log("Ошибка входа")
                        errorDialog.open()
                    }
                }
            }

            Button {
                text: "Регистрация"
                flat: true
                Layout.fillWidth: true
                onClicked: loginPage.StackView.view.push("RegistrationScreen.qml")
            }
        }
    }

    Dialog {
            id: errorDialog
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.8, 300)
            modal: true
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

            background: Rectangle {
                color: Theme.surface
                radius: Theme.radiusLarge
                // Простая тень без Effects (для совместимости)
                Rectangle {
                    z: -1
                    anchors.fill: parent
                    anchors.topMargin: 4
                    color: "#20000000"
                    radius: parent.radius
                }
            }

            contentItem: ColumnLayout {
                spacing: 20

                Text {
                    text: "🔐"
                    font.pixelSize: 40
                    Layout.alignment: Qt.AlignHCenter
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "Не удалось войти"
                        font.bold: true
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.textPrimary
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: "Проверьте логин и пароль"
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSizeMedium
                        anchors.horizontalCenter: parent.horizontalCenter
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                Button {
                    text: "Попробовать снова"
                    Layout.fillWidth: true
                    background: Rectangle {
                        color: Theme.error // Красная кнопка для ошибки
                        radius: Theme.radiusMedium
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: errorDialog.close()
                }
            }

            enter: Transition {
                NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 150 }
                NumberAnimation { property: "scale"; from: 0.9; to: 1.0; duration: 150; easing.type: Easing.OutBack }
            }
        }
}
