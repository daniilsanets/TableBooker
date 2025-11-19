import QtQuick 2.15
import QtQuick.Controls
import QtQuick.Layouts
import com.tablebooker.api 1.0

Page {
    id: loginPage
    title: "Вход в TableBooker"

    ColumnLayout {
        width: parent.width * 0.85
        spacing: parent.height * 0.02
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.2
        anchors.horizontalCenter: parent.horizontalCenter

        TextField {
            id: phoneField
            placeholderText: qsTr("Введите телефон")
            Layout.fillWidth: true
        }

        TextField {
            id: passwordField
            placeholderText: qsTr("Введите пароль")
            echoMode: TextInput.Password
        }

        Button {
            text: "Войти"

            onClicked: {
                var user = BackendApi.authenticateUser(phoneField.text, passwordField.text)

                if (user.id) {
                    console.log("Успех! ID пользователя: " + user.id)
                } else {
                    console.log("Ошибка: Неверный логин или пароль")
                }
            }
        }
    }
}
