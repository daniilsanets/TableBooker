import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import com.tablebooker.api 1.0

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
        title: "Ошибка"
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        standardButtons: Dialog.Ok
        Label { text: "Неверный логин или пароль" }
    }
}
