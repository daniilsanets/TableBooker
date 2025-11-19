import QtQuick 2.15
import QtQuick.Controls
import QtQuick.Layouts
import com.tablebooker.api 1.0

Page {
    id: registrationpPage
    title: "Регистрация в TableBooker"

    ColumnLayout {
        spacing: 20
        anchors.top: parent.top
        anchors.topMargin: 150
        anchors.horizontalCenter: parent.horizontalCenter

        TextField {
            id: usernameField
            placeholderText: qsTr("Введите имя")
            Layout.fillWidth: true
        }

        TextField {
            id: emailField
            placeholderText: qsTr("Введите email")
            Layout.fillWidth: true
        }

        TextField {
            id: phoneField
            placeholderText: qsTr("Введите телефон")
            Layout.fillWidth: true
        }

        TextField {
            id: nicknameField
            placeholderText: qsTr("Введите имя пользователя")
            Layout.fillWidth: true
        }

        TextField {
            id: passwordField
            placeholderText: qsTr("Введите пароль")
            Layout.fillWidth: true
            echoMode: TextInput.Password
        }

        Button {
            text: "Зарегистрироваться"

            onClicked: {

                var userData = {
                        "username": usernameField.text,
                        "password": passwordField.text,
                        "email": emailField.text,
                        "phone": phoneField.text,
                        "nickname": nicknameField.text

                    }

                var isSuccess = BackendApi.registerUser(userData)

                if (isSuccess) {
                    console.log("Регистрация успешна! Теперь можно войти.")
                } else {
                    console.log("Ошибка регистрации (возможно, логин занят)")
                }
            }
        }
    }
}
