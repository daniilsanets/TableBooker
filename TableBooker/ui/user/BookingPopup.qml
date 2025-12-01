import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import com.tablebooker.api 1.0
import "../components"
import "../Theme.js" as Theme

Dialog {
    id: root

    // Центрирование
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: Math.min(parent.width * 0.9, 360)

    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property int tableId: -1
    property string tableName: "?"

    signal bookingCreated()

    // Фон диалога: Чистый белый с тенью
    background: Rectangle {
        color: "white"
        radius: 16
        layer.enabled: true
        // Эмуляция тени прямоугольником (для совместимости)
        Rectangle {
            z: -1; anchors.fill: parent; anchors.margins: -4
            color: "#40000000"; radius: 20
        }
    }

    contentItem: ColumnLayout {
        spacing: 20

        // 1. ЗАГОЛОВОК
        RowLayout {
            Layout.fillWidth: true

            Column {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: "Бронирование"
                    font.bold: true
                    font.pixelSize: 22
                    color: "black" // Черный текст
                }

                Row {
                    spacing: 6
                    Text { text: "🪑"; font.pixelSize: 14 }
                    Text {
                        text: root.tableName
                        font.pixelSize: 14
                        color: "#424242" // Темно-серый
                        font.bold: true
                    }
                }
            }

            // Кнопка закрытия
            ToolButton {
                text: "✕"
                contentItem: Text {
                    text: parent.text
                    color: "black"
                    font.pixelSize: 20
                    anchors.centerIn: parent
                }
                background: Rectangle { color: "transparent" }
                onClicked: root.close()
            }
        }

        // Разделитель
        Rectangle { Layout.fillWidth: true; height: 1; color: "#EEEEEE" }

        // 2. ПОЛЯ ВВОДА
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 16

            // Дата
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                Text { text: "Дата"; color: "black"; font.bold: true; font.pixelSize: 12 }

                TextField {
                    id: dateField
                    Layout.fillWidth: true
                    placeholderText: "YYYY-MM-DD"
                    text: new Date().toISOString().slice(0,10)
                    inputMask: "9999-99-99"
                    color: "black" // Черный текст ввода
                    font.pixelSize: 16

                    background: Rectangle {
                        color: "#F5F5F5"
                        radius: 8
                        border.color: parent.activeFocus ? Theme.primary : "transparent"
                        border.width: 2
                    }
                }
            }

            // Время (Начало и Конец)
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Начало
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Text { text: "Начало"; color: "black"; font.bold: true; font.pixelSize: 12 }

                    TextField {
                        id: startTimeField
                        Layout.fillWidth: true
                        text: "18:00"
                        inputMask: "99:99"
                        color: "black"
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter

                        background: Rectangle {
                            color: "#F5F5F5"
                            radius: 8
                            border.color: parent.activeFocus ? Theme.primary : "transparent"
                            border.width: 2
                        }
                    }
                }

                Text {
                    text: "➔"
                    color: "#9E9E9E"
                    Layout.alignment: Qt.AlignVCenter
                    Layout.topMargin: 16
                }

                // Конец
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Text { text: "Конец"; color: "black"; font.bold: true; font.pixelSize: 12 }

                    TextField {
                        id: endTimeField
                        Layout.fillWidth: true
                        text: "20:00"
                        inputMask: "99:99"
                        color: "black"
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter

                        background: Rectangle {
                            color: "#F5F5F5"
                            radius: 8
                            border.color: parent.activeFocus ? Theme.primary : "transparent"
                            border.width: 2
                        }
                    }
                }
            }
        }

        // Сообщение об ошибке
        Label {
            id: errorLabel
            visible: false
            color: Theme.error
            font.pixelSize: 12
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }

        // 3. КНОПКА ПОДТВЕРЖДЕНИЯ
        Button {
            text: "Подтвердить"
            Layout.fillWidth: true
            Layout.topMargin: 10
            height: 50

            background: Rectangle {
                color: Theme.primary
                radius: 10
                opacity: parent.pressed ? 0.8 : 1.0
            }

            contentItem: Text {
                text: parent.text
                color: "white"
                font.bold: true
                font.pixelSize: 16
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            onClicked: validateAndSend()
        }
    }

    // --- ЛОГИКА ---
    function prefill(dateValue, startTimeValue, endTimeValue) {
        if (dateValue && dateValue.length === 10) dateField.text = dateValue
        if (startTimeValue && startTimeValue.length === 5) startTimeField.text = startTimeValue
        if (endTimeValue && endTimeValue.length === 5) endTimeField.text = endTimeValue
        errorLabel.visible = false
    }

    function showError(msg) {
        errorLabel.text = msg
        errorLabel.visible = true
    }

    function validateAndSend() {
        var dateString = dateField.text + " " + startTimeField.text;
        var selectedDate = new Date(dateString);
        var now = new Date();

        if (selectedDate <= now) {
            showError("Нельзя выбрать время в прошлом")
            return
        }
        if (dateField.text.length < 10 || startTimeField.text.length < 5 || endTimeField.text.length < 5) {
            showError("Заполните все поля")
            return
        }
        if (startTimeField.text >= endTimeField.text) {
            showError("Начало должно быть раньше конца")
            return
        }

        var start = dateField.text + " " + startTimeField.text + ":00"
        var end = dateField.text + " " + endTimeField.text + ":00"

        var bookingData = {
            "tableId": root.tableId,
            "startTime": start,
            "endTime": end
        }

        var success = BackendApi.createBooking(bookingData)
        if (success) {
            root.bookingCreated()
            root.close()
        } else {
            showError("Время занято или ошибка сервера")
        }
    }
}
