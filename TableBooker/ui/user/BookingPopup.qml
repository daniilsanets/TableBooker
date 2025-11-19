import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import com.tablebooker.api 1.0

Dialog {
    id: root
    title: "Бронирование"
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    modal: true
    standardButtons: Dialog.Cancel

    // Свойства, которые мы передадим при открытии
    property int tableId: -1
    property string tableName: "?"

    ColumnLayout {
        spacing: 10

        Label {
            text: "Бронируем: " + root.tableName
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        // Простой ввод даты (по умолчанию - сегодня)
        TextField {
            id: dateField
            placeholderText: "YYYY-MM-DD"
            text: new Date().toISOString().slice(0,10)
            Layout.fillWidth: true
            inputMask: "9999-99-99"
            validator: RegularExpressionValidator {
                regularExpression: /^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$/
            }
        }

        RowLayout
        {
            TextField {
                id: startTimeField
                placeholderText: "Начало (HH:MM)"
                text: "18:00"
                Layout.fillWidth: true
                inputMask: "99:99"
                validator: RegularExpressionValidator { regularExpression: /^([0-1][0-9]|2[0-3]):[0-5][0-9]$/ }
            }

            Label { text: "-" }
            TextField {
                id: endTimeField
                placeholderText: "Конец (HH:MM)"
                text: "20:00"
                Layout.fillWidth: true
                inputMask: "99:99"

                validator: RegularExpressionValidator { regularExpression: /^([0-1][0-9]|2[0-3]):[0-5][0-9]$/ }
            }
        }

        Label
        {
            id: errorLabel
            color: "red"
            visible: false
            text: ""
        }

        Button
        {
            text: "Подтвердить"
            Layout.fillWidth: true
            highlighted: true
            onClicked: validateAndSend()
        }
    }

    function showError(msg)
    {
        errorLabel.text = msg
        errorLabel.visible = true
    }

    function validateAndSend()
    {
        var dateString = dateField.text + " " + startTimeField.text;

        var selectedDate = new Date(dateString);

        var now = new Date();

        if (selectedDate <= now) {
            console.log("⚠️ Ошибка: дата в прошлом!")
            showError("Нельзя забронировать столик в прошлом")
            return
        }
            // 1. Проверка на пустоту (с маской это менее актуально, но полезно)
        if (dateField.text.length < 10 || startTimeField.text.length < 5 || endTimeField.text.length < 5) {
            showError("Заполните все поля корректно")
            return
        }

        // 2. Логическая проверка времени
        if (startTimeField.text >= endTimeField.text) {
            showError("Время начала должно быть раньше конца")
            return
        }

        if (!startTimeField.acceptableInput || !endTimeField.acceptableInput) {
            showError("Некорректное время (формат HH:MM)")
            return
        }
        // Если всё ок — отправляем
        sendBooking()
    }

    function sendBooking()
    {
        var start = dateField.text + " " + startTimeField.text + ":00"
        var end = dateField.text + " " + endTimeField.text + ":00"

        var bookingData = {
            "tableId": root.tableId,
            "startTime": start,
            "endTime": end
        }

        var success = BackendApi.createBooking(bookingData)
        if (success) {
            console.log("✅ Бронь успешна!")
            root.close() // Закрываем окно сами
        } else {
            showError("Ошибка сервера (возможно, время занято)")
        }
    }

    onAccepted:
    {
        validateAndSend()
    }
}
