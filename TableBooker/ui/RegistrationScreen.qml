import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import com.tablebooker.api 1.0

Page {
    id: registrationPage
    title: "Регистрация"

    Dialog {
        id: errorDialog
        title: "Ошибка"
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        standardButtons: Dialog.Ok
        property alias text: errorLabel.text

        Label {
            id: errorLabel
            text: ""
        }
    }

    ColumnLayout {
        width: parent.width * 0.85
        spacing: 15
        anchors.centerIn: parent

        Label {
            text: "Создание аккаунта"
            font.bold: true
            font.pixelSize: 20
            Layout.alignment: Qt.AlignHCenter
        }

        TextField {
            id: usernameField
            placeholderText: "Полное имя"
            Layout.fillWidth: true
        }

        TextField {
            id: emailField
            placeholderText: "Email"
            Layout.fillWidth: true
            inputMethodHints: Qt.ImhEmailCharactersOnly
            validator: RegularExpressionValidator {
                regularExpression: /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/
            }
            color: acceptableInput || text === "" ? "black" : "red"
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            ComboBox {
                id: countrySelector
                Layout.preferredWidth: 140

                model: ListModel {
                    ListElement { code: "+375"; flag: "🇧🇾"; text: "🇧🇾 +375" }
                    // В будущем можно добавить:
                    // ListElement { code: "+7"; flag: "🇷🇺"; text: "🇷🇺 +7" }
                }

                textRole: "text"
                currentIndex: 0
            }

            TextField
            {
                id: phoneLocalField
                placeholderText: "29 111 22 33"
                Layout.fillWidth: true
                inputMethodHints: Qt.ImhDigitsOnly

                validator: RegularExpressionValidator {
                                regularExpression: /^(25|29|33|44)[0-9]{7}$/
                            }
                color: acceptableInput || text === "" ? "black" : "red"
                onTextChanged:
                {
                    if (text.length >= 2) {
                        var code = text.substring(0, 2)
                        if (code !== "25" && code !== "29" && code !== "33" && code !== "44")
                        {
                                       showError("Неверный код оператора")
                        }
                    }
                }
            }
        }

        TextField {
            id: nicknameField
            placeholderText: "Никнейм"
            Layout.fillWidth: true
        }

        TextField
        {
            id: passwordField
            placeholderText: "Пароль (мин. 6 символов)"
            Layout.fillWidth: true
            echoMode: regShowPass.checked ? TextInput.Normal : TextInput.Password

            color: text.length >= 6 || text === "" ? "black" : "red"
            rightPadding: 50

            Text
            {
                id: regEyeIcon
                text: regShowPass.checked ? "🙈" : "👁️"
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 10
                color: "gray"
                z: 1
            }

            MouseArea
            {
                id: regShowPass
                anchors.fill: regEyeIcon
                anchors.margins: -10
                property bool checked: false
                onClicked: checked = !checked
            }
        }

        Button {
            text: "Зарегистрироваться"
            Layout.fillWidth: true
            highlighted: true

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

        Button {
            text: "Назад"
            flat: true
            Layout.fillWidth: true
            onClicked: registrationPage.StackView.view.pop()
        }
    }

    function showError(msg) {
        errorDialog.text = msg
        errorDialog.open()
    }
}
