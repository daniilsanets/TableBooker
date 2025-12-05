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

    // Скролл для адаптивности (как на экране входа)
    Flickable {
        id: flickable
        anchors.fill: parent
        contentHeight: Math.max(contentColumn.implicitHeight + 100, height)
        contentWidth: width
        clip: true

        // Контейнер для выравнивания по центру
        Item {
            width: parent.width
            height: flickable.contentHeight

            ColumnLayout {
                id: contentColumn
                width: Math.min(parent.width * 0.85, 400) // Ограничение ширины
                anchors.centerIn: parent
                spacing: Theme.spacingMedium

                // --- ЗАГОЛОВОК ---
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 10
                    spacing: Theme.spacingSmall

                    Text {
                        text: "Создание аккаунта"
                        font.bold: true
                        font.pixelSize: Theme.fontSizeXLarge
                        color: Theme.primary
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "Заполните данные для регистрации"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.textSecondary
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                // --- ПОЛЯ ВВОДА ---

                // 1. Имя (ФИО)
                MaterialTextField {
                    id: usernameField
                    Layout.fillWidth: true
                    placeholderText: "Полное имя"
                    iconText: Theme.iconPerson
                    onAccepted: emailField.forceActiveFocus()
                }

                // 2. Email
                MaterialTextField {
                    id: emailField
                    Layout.fillWidth: true
                    placeholderText: "Email"
                    iconText: Theme.iconEmail
                    inputMethodHints: Qt.ImhEmailCharactersOnly

                    // Валидация Email
                    property bool isValid: text.match(/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/)
                    hasError: text !== "" && !isValid

                    onAccepted: phoneLocalField.forceActiveFocus()
                }

                // 3. Телефон (С выбором кода)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingSmall

                    // Код страны (имитация комбобокса в стиле Material)
                    Rectangle {
                        Layout.preferredWidth: 90
                        Layout.preferredHeight: 56 // Высота как у MaterialTextField
                        color: Theme.surface
                        radius: Theme.radiusSmall
                        border.color: Theme.divider
                        border.width: 1

                        Text {
                            text: "🇧🇾 +375"
                            anchors.centerIn: parent
                            color: Theme.textPrimary
                            font.pixelSize: Theme.fontSizeMedium
                        }
                    }

                    // Номер
                    MaterialTextField {
                        id: phoneLocalField
                        Layout.fillWidth: true
                        placeholderText: "29 111 22 33"
                        inputMethodHints: Qt.ImhDigitsOnly
                        validator: RegularExpressionValidator { regularExpression: /^[0-9]{9}$/ }
                        iconText: Theme.iconPhone
                        onAccepted: nicknameField.forceActiveFocus()
                    }
                }

                // 4. Никнейм
                MaterialTextField {
                    id: nicknameField
                    Layout.fillWidth: true
                    placeholderText: "Никнейм"
                    iconText: Theme.iconPerson // Или другая иконка
                    onAccepted: passwordField.forceActiveFocus()
                }

                // 5. Пароль
                MaterialTextField {
                    id: passwordField
                    Layout.fillWidth: true
                    placeholderText: "Пароль (мин. 6 символов)"
                    iconText: Theme.iconLock
                    echoMode: regShowPass.checked ? TextInput.Normal : TextInput.Password
                    rightPadding: 48

                    hasError: text !== "" && text.length < 6

                    Item {
                        width: 40; height: 40
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        z: 10
                        Text {
                            text: regShowPass.checked ? Theme.iconVisibilityOff : Theme.iconVisibility
                            font.pixelSize: 22
                            color: Theme.textSecondary
                            anchors.centerIn: parent
                            opacity: 0.7
                        }
                        MouseArea {
                            id: regShowPass
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            property bool checked: false
                            onClicked: checked = !checked
                        }
                    }
                    onAccepted: registerAction()
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.spacingMedium
                    spacing: Theme.spacingMedium

                    // Кнопка "Зарегистрироваться" (Filled)
                    Button {
                        id: registerButton
                        text: "Зарегистрироваться"
                        Layout.fillWidth: true
                        height: 50

                        background: Rectangle {
                            color: Theme.primary
                            radius: Theme.radiusMedium
                            opacity: parent.pressed ? 0.8 : 1.0
                        }

                        contentItem: Text {
                            text: parent.text
                            color: "white" // Белый текст для основной кнопки
                            font.pixelSize: Theme.fontSizeMedium
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter // Центрирование по горизонтали
                            verticalAlignment: Text.AlignVCenter   // Центрирование по вертикали
                        }

                        onClicked: registerAction()
                    }

                    // Кнопка "Назад ко входу" (Flat/Text Button)
                    Button {
                        text: "Назад ко входу"
                        Layout.fillWidth: true
                        height: 50

                        background: Rectangle {
                            color: "transparent"
                            radius: Theme.radiusMedium
                            border.width: 0
                            opacity: parent.pressed ? 0.6 : 1.0
                        }

                        contentItem: Text {
                            text: parent.text
                            color: Theme.primary // Цвет текста такой же, как тема
                            font.pixelSize: Theme.fontSizeMedium
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter // Центрирование по горизонтали
                            verticalAlignment: Text.AlignVCenter   // Центрирование по вертикали
                        }

                        onClicked: registrationPage.StackView.view.pop()
                    }
                }
            }
        }
    }

    // --- ДИАЛОГ ОШИБКИ ---
    Dialog {
        id: errorDialog
        title: "Ошибка регистрации"
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
            spacing: Theme.spacingMedium
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

    // --- ЛОГИКА РЕГИСТРАЦИИ ---
    function registerAction() {
        // 1. Проверки
        if (usernameField.text === "" || nicknameField.text === "") {
            showError("Заполните имя и никнейм")
            return
        }

        // Проверка валидности Email через свойство, которое мы добавили выше
        if (emailField.text === "" || !emailField.isValid) {
            showError("Введите корректный Email")
            return
        }

        // Проверка телефона (9 цифр)
        if (phoneLocalField.text.length !== 9) {
            showError("Номер телефона должен содержать 9 цифр (без кода +375)")
            return
        }

        if (passwordField.text.length < 6) {
            showError("Пароль слишком короткий (минимум 6 символов)")
            return
        }

        // 2. Сбор данных
        var fullPhone = "+375" + phoneLocalField.text

        var userData = {
            "username": usernameField.text,  // В этой версии используем Имя как username для простоты, или можно добавить отдельное поле
            "password": passwordField.text,
            "email": emailField.text,
            "phone": fullPhone,
            "nickname": nicknameField.text
        }

        // 3. Отправка на бэкенд
        var isSuccess = BackendApi.registerUser(userData)

        if (isSuccess) {
            console.log("Регистрация успешна!")
            // Можно показать диалог успеха или сразу вернуться
            registrationPage.StackView.view.pop()
        } else {
            showError("Ошибка: Пользователь с таким логином, телефоном или почтой уже существует")
        }
    }

    function showError(msg) {
        errorDialog.text = msg
        errorDialog.open()
    }
}
