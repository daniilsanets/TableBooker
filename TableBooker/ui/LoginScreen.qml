import QtQuick 2.15
import QtQuick.Controls
import QtQuick.Layouts
import com.tablebooker.api 1.0
import "admin"
import "user"

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
            id: loginField
            placeholderText: qsTr("Телефон, Email или Логин")
            Layout.fillWidth: true
        }

        TextField
        {
            id: passwordField
            placeholderText: qsTr("Введите пароль")
            echoMode: showPassArea.checked ? TextInput.Normal : TextInput.Password
            Layout.fillWidth: true

            // Отступ справа, чтобы текст пароля не налез на кнопку
            rightPadding: 50

            Text
            {
                id: eyeIcon
                text: showPassArea.checked ? "🙈" : "👁️"

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 10

                font.pixelSize: 14
                color: "gray"
                // Чтобы текст был всегда поверх поля
                z: 1
            }

            MouseArea
            {
                id: showPassArea
                anchors.fill: eyeIcon
                anchors.margins: -10

                property bool checked: false
                onClicked: checked = !checked
            }
        }

        Button
        {
            text: "Войти"
            Layout.fillWidth: true
            highlighted: true

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
                    console.log("Ошибка: Неверный логин или пароль")
                    // Тут можно добавить Dialog с ошибкой
                }
            }
        }

        Button
        {
            text: "Нет аккаунта? Зарегистрироваться"
            flat: true
            Layout.fillWidth: true

            onClicked: loginPage.StackView.view.push("RegistrationScreen.qml")
        }
    }
}
