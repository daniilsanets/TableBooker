import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import com.tablebooker.api 1.0
import "../components"
import "../Theme.js" as Theme

Dialog {
    id: root
    title: "Бронирование столика"
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: Math.min(parent.width * 0.9, 400)
    modal: true
    standardButtons: Dialog.Cancel
    
    background: Rectangle {
        color: Theme.surface
        radius: Theme.radiusLarge
    }

    // Свойства, которые мы передадим при открытии
    property int tableId: -1
    property string tableName: "?"

    ColumnLayout {
        spacing: Theme.spacingMedium
        anchors.fill: parent
        anchors.margins: Theme.spacingMedium

        // Заголовок
        Column {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            spacing: Theme.spacingSmall
            
            Text {
                text: Theme.iconTable
                font.pixelSize: 48
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Label {
                text: "Бронируем: " + root.tableName
                font.bold: true
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.textPrimary
                Layout.alignment: Qt.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        // Поле даты
        Rectangle {
            Layout.fillWidth: true
            height: 56
            color: Theme.surfaceDark
            radius: Theme.radiusMedium
            border.color: dateField.activeFocus ? Theme.primary : Theme.divider
            border.width: dateField.activeFocus ? 2 : 1
            
            Item {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                height: 40
                
                Row {
                    anchors.fill: parent
                    spacing: 12
                    
                    Text {
                        text: Theme.iconCalendar
                        font.pixelSize: 24
                        color: Theme.textSecondary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    TextField {
                        id: dateField
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.parent.width - 60
                        placeholderText: "YYYY-MM-DD"
                        text: new Date().toISOString().slice(0,10)
                        inputMask: "9999-99-99"
                        validator: RegularExpressionValidator {
                            regularExpression: /^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$/
                        }
                        background: Item {}
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.textPrimary
                    }
                }
            }
        }

        // Поля времени
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSmall
            
            Rectangle {
                Layout.fillWidth: true
                height: 56
                color: Theme.surfaceDark
                radius: Theme.radiusMedium
                border.color: startTimeField.activeFocus ? Theme.primary : Theme.divider
                border.width: startTimeField.activeFocus ? 2 : 1
                
                Item {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    height: 40
                    
                    Row {
                        anchors.fill: parent
                        spacing: 12
                        
                        Text {
                            text: Theme.iconTime
                            font.pixelSize: 24
                            color: Theme.textSecondary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        TextField {
                            id: startTimeField
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.parent.width - 60
                            placeholderText: "Начало (HH:MM)"
                            text: "18:00"
                            inputMask: "99:99"
                            validator: RegularExpressionValidator { 
                                regularExpression: /^([0-1][0-9]|2[0-3]):[0-5][0-9]$/ 
                            }
                            background: Item {}
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.textPrimary
                        }
                    }
                }
            }
            
            Text {
                text: "—"
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.textSecondary
                Layout.alignment: Qt.AlignVCenter
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 56
                color: Theme.surfaceDark
                radius: Theme.radiusMedium
                border.color: endTimeField.activeFocus ? Theme.primary : Theme.divider
                border.width: endTimeField.activeFocus ? 2 : 1
                
                Item {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    height: 40
                    
                    Row {
                        anchors.fill: parent
                        spacing: 12
                        
                        Text {
                            text: Theme.iconTime
                            font.pixelSize: 24
                            color: Theme.textSecondary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        TextField {
                            id: endTimeField
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.parent.width - 60
                            placeholderText: "Конец (HH:MM)"
                            text: "20:00"
                            inputMask: "99:99"
                            validator: RegularExpressionValidator { 
                                regularExpression: /^([0-1][0-9]|2[0-3]):[0-5][0-9]$/ 
                            }
                            background: Item {}
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.textPrimary
                        }
                    }
                }
            }
        }

        Label {
            id: errorLabel
            color: Theme.error
            visible: false
            text: ""
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Button {
            id: confirmButton
            text: "Подтвердить бронирование"
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacingSmall
            height: 56
            
            background: Rectangle {
                color: Theme.primary
                radius: Theme.radiusMedium
                opacity: confirmButton.pressed ? 0.8 : 1.0
                
                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }
            }
            
            contentItem: Text {
                text: confirmButton.text
                color: "white"
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            
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
            // Очищаем поля
            dateField.text = new Date().toISOString().slice(0,10)
            startTimeField.text = "18:00"
            endTimeField.text = "20:00"
            errorLabel.visible = false
            root.close() // Закрываем окно сами
        } else {
            showError("Ошибка: Возможно, это время уже занято или произошла ошибка сервера")
        }
    }

    onAccepted:
    {
        validateAndSend()
    }
}
