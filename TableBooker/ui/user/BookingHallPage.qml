import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import com.tablebooker.api 1.0
import "../admin"
import "../components"
import "../Theme.js" as Theme

Page {
    id: bookingPage
    title: premisesName

    background: Rectangle { color: Theme.background }

    property int premisesId: 0
    property string premisesName: ""
    property bool isAdmin: BackendApi.currentUserRole === "admin"
    property string selectedDate: Qt.formatDate(new Date(), "yyyy-MM-dd")
    property string selectedTime: "18:30"
    property int selectedDuration: 120
    property string currentEndTime: ""
    property bool availabilityLoading: false
    property string availabilitySummary: "Укажите время для проверки"

    property var durationOptions: [
        { "label": "1 ч", "minutes": 60 },
        { "label": "1.5 ч", "minutes": 90 },
        { "label": "2 ч", "minutes": 120 },
        { "label": "3 ч", "minutes": 180 }
    ]

    property var availabilityPalette: ({ "free": "#6FCF97", "busy": "#F76C6C", "unknown": "#B0BEC5" })
    property bool isCompactLayout: width <= 640

    onIsCompactLayoutChanged: { if (!isCompactLayout) filtersDialog.close() }

    ListModel { id: tablesModel }
    BookingPopup { id: bookingPopup; onBookingCreated: bookingPage.refreshAvailability() }
    Timer { id: availabilityDebounce; interval: 350; repeat: false; onTriggered: bookingPage.refreshAvailability() }

    // --- КОМПОНЕНТ ФОРМЫ НАСТРОЕК (Обновленный дизайн) ---
    Component {
        id: filtersFormComponent
        ColumnLayout {
            spacing: 20

            // 1. ДАТА И ВРЕМЯ
            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                // Дата
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Text { text: "Дата"; font.bold: true; color: "black"; font.pixelSize: 12 }

                    TextField {
                        id: dateInput
                        Layout.fillWidth: true
                        text: selectedDate
                        inputMask: "9999-99-99"
                        color: "black"
                        font.pixelSize: 16
                        background: Rectangle {
                            color: "#F5F5F5"; radius: 8
                            border.color: parent.activeFocus ? Theme.primary : "transparent"; border.width: 2
                        }
                        onTextChanged: if (text !== selectedDate) selectedDate = text
                    }
                }

                // Время
                ColumnLayout {
                    Layout.preferredWidth: 100
                    spacing: 6
                    Text { text: "Время"; font.bold: true; color: "black"; font.pixelSize: 12 }

                    TextField {
                        id: timeInput
                        Layout.fillWidth: true
                        text: selectedTime
                        inputMask: "99:99"
                        color: "black"
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter
                        background: Rectangle {
                            color: "#F5F5F5"; radius: 8
                            border.color: parent.activeFocus ? Theme.primary : "transparent"; border.width: 2
                        }
                        onTextChanged: if (text !== selectedTime) selectedTime = text
                    }
                }
            }

            // 2. ДЛИТЕЛЬНОСТЬ (Чипсы)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text { text: "Длительность"; font.bold: true; color: "black"; font.pixelSize: 12 }

                Flow {
                    Layout.fillWidth: true
                    spacing: 10

                    Repeater {
                        model: durationOptions
                        delegate: Rectangle {
                            width: 70; height: 36
                            radius: 18
                            // Выбранный: Синий фон, Белый текст. Невыбранный: Серый фон, Черный текст.
                            color: selectedDuration === modelData.minutes ? Theme.primary : "#F0F0F0"
                            border.width: 0

                            Text {
                                text: modelData.label
                                anchors.centerIn: parent
                                color: selectedDuration === modelData.minutes ? "white" : "black"
                                font.bold: true
                                font.pixelSize: 13
                            }
                            MouseArea { anchors.fill: parent; onClicked: selectedDuration = modelData.minutes }
                        }
                    }
                }

                Text {
                    text: currentEndTime.length > 0 ? "До " + currentEndTime : ""
                    color: Theme.textSecondary
                    font.pixelSize: 12
                }
            }
        }
    }

    // --- ДИАЛОГ ФИЛЬТРОВ (Выезжает снизу/центр) ---
    Dialog {
        id: filtersDialog
        modal: true
        title: ""
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: Math.min(parent.width * 0.9, 360)

        background: Rectangle {
            color: "white"
            radius: 16
            // Тень
            Rectangle { z: -1; anchors.fill: parent; anchors.margins: -4; color: "#40000000"; radius: 20 }
        }

        contentItem: ColumnLayout {
            spacing: 20

            // Шапка диалога
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Настройка поиска"; font.bold: true; font.pixelSize: 18; color: "black"; Layout.fillWidth: true }
                ToolButton {
                    text: "✕"
                    contentItem: Text { text: "✕"; color: "black"; font.pixelSize: 18; anchors.centerIn: parent }
                    background: Item {}
                    onClicked: filtersDialog.close()
                }
            }

            // Форма
            Loader {
                Layout.fillWidth: true
                sourceComponent: filtersFormComponent
            }

            // Кнопка применить
            Button {
                text: "Показать столы"
                Layout.fillWidth: true
                height: 48
                background: Rectangle { color: Theme.primary; radius: 12 }
                contentItem: Text { text: parent.text; color: "white"; font.bold: true; font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                onClicked: { bookingPage.handleAvailabilityCheck(); filtersDialog.close() }
            }
        }
    }

    // --- ЛОГИКА ---
    function loadTables() {
        tablesModel.clear()
        var tables = BackendApi.getTablesForPremises(premisesId)
        for(var i=0; i<tables.length; i++) {
            var t = tables[i]
            tablesModel.append({
                "dbId": t.id, "name": t.name, "x": t.x, "y": t.y,
                "width": t.width, "height": t.height,
                "shapeType": t.shapeType, "type": t.type || "table",
                "color": t.color || "#81C784", "baseColor": t.color || "#81C784",
                "availabilityState": "unknown", "rotation": t.rotation || 0
            })
        }
        recalcEndTimePreview()
        Qt.callLater(function() { bookingPage.refreshAvailability() })
    }

    function padNumber(val) { return (val < 10 ? "0" : "") + val }

    function recalcEndTimePreview() {
        var startDt = toDateTime(selectedDate, selectedTime)
        if (!startDt) { currentEndTime = ""; return }
        var endDt = new Date(startDt.getTime() + selectedDuration * 60000)
        currentEndTime = formatTime(endDt)
    }

    function toDateTime(dateStr, timeStr) {
        if (!dateStr || dateStr.length < 10 || dateStr.indexOf("_") !== -1) return null
        if (!timeStr || timeStr.length < 5 || timeStr.indexOf("_") !== -1) return null
        return new Date(dateStr + "T" + timeStr + ":00")
    }

    function toQueryDate(dateStr) {
        if (!dateStr || dateStr.length < 10) return null
        var parts = dateStr.split("-")
        return new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]))
    }

    function formatTime(dateObj) { return padNumber(dateObj.getHours()) + ":" + padNumber(dateObj.getMinutes()) }
    function parseSqlDateTime(value) { if (!value || value.length < 16) return null; return new Date(value.replace(" ", "T")) }
    function intervalsOverlap(startA, endA, startB, endB) { return startA < endB && endA > startB }

    function scheduleAvailabilityUpdate() { availabilityDebounce.restart() }

    function refreshAvailability() {
        availabilityDebounce.stop()
        if (tablesModel.count === 0) { availabilitySummary = "Нет столов"; availabilityLoading = false; return }

        var startDt = toDateTime(selectedDate, selectedTime)
        if (!startDt) { availabilitySummary = "Неверная дата"; availabilityLoading = false; return }

        var endDt = new Date(startDt.getTime() + selectedDuration * 60000)
        var queryDate = toQueryDate(selectedDate)
        availabilityLoading = true
        var freeCount = 0, totalTables = 0

        for (var i = 0; i < tablesModel.count; i++) {
            var entry = tablesModel.get(i)
            if (entry.type !== "table") continue
            totalTables++
            var bookings = BackendApi.getBookingsForTable(entry.dbId, queryDate) || []
            var busy = false
            for (var j = 0; j < bookings.length; j++) {
                if (intervalsOverlap(startDt, endDt, parseSqlDateTime(bookings[j].startTime), parseSqlDateTime(bookings[j].endTime))) {
                    busy = true; break;
                }
            }
            tablesModel.setProperty(i, "color", busy ? availabilityPalette.busy : availabilityPalette.free)
            tablesModel.setProperty(i, "availabilityState", busy ? "busy" : "free")
            if (!busy) freeCount++
        }
        availabilityLoading = false
        availabilitySummary = "Свободно: " + freeCount + " из " + totalTables
    }

    onSelectedDateChanged: scheduleAvailabilityUpdate()
    onSelectedTimeChanged: { recalcEndTimePreview(); scheduleAvailabilityUpdate() }
    onSelectedDurationChanged: { recalcEndTimePreview(); scheduleAvailabilityUpdate() }
    function handleAvailabilityCheck() { refreshAvailability() }
    Component.onCompleted: loadTables()

    // --- ИНТЕРФЕЙС СТРАНИЦЫ ---
    header: ToolBar {
        background: Rectangle { color: "white" }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8; anchors.rightMargin: 8

            ToolButton {
                Text { text: "←"; font.pixelSize: 24; color: "black"; anchors.centerIn: parent }
                onClicked: bookingPage.StackView.view.pop()
            }
            Label { text: bookingPage.title; font.bold: true; font.pixelSize: 18; color: "black"; Layout.fillWidth: true }
            ToolButton {
                visible: bookingPage.isAdmin
                Text { text: "⚙️"; font.pixelSize: 20; anchors.centerIn: parent }
                onClicked: bookingPage.StackView.view.push("../admin/HallEditorPage.qml", { "premisesId": bookingPage.premisesId, "premisesName": bookingPage.premisesName })
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // Кнопка фильтров (для мобильных)
        Button {
            visible: isCompactLayout
            Layout.fillWidth: true
            height: 48
            text: "📅 " + selectedDate + " " + selectedTime
            background: Rectangle { color: "#F5F5F5"; radius: 8; border.color: Theme.divider; border.width: 1 }
            contentItem: Text { text: parent.text; color: "black"; font.bold: true; font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            onClicked: filtersDialog.open()
        }

        // Панель фильтров (для десктопа)
        Rectangle {
            visible: !isCompactLayout
            Layout.fillWidth: true
            height: 120
            color: "white"; radius: 16; border.color: Theme.divider; border.width: 1
            Loader { anchors.fill: parent; anchors.margins: 16; sourceComponent: filtersFormComponent }
        }

        // Холст с залом
        Item {
            Layout.fillWidth: true; Layout.fillHeight: true
            clip: true

            ZoomableHall {
                id: hallView
                anchors.fill: parent
                tablesModel: tablesModel
                editMode: false
                onTableClicked: (idx, dbId) => {
                    var table = tablesModel.get(idx)
                    bookingPopup.tableId = dbId
                    bookingPopup.tableName = table.name
                    bookingPopup.prefill(selectedDate, selectedTime, currentEndTime || "")
                    bookingPopup.open()
                }
            }

            // Легенда (внизу справа)
            Rectangle {
                anchors.bottom: parent.bottom; anchors.right: parent.right; anchors.margins: 16
                width: 160; height: 40; radius: 20
                color: "white"; border.color: "#E0E0E0"; border.width: 1
                Row {
                    anchors.centerIn: parent; spacing: 10
                    Row { spacing: 4; Rectangle { width: 12; height: 12; radius: 6; color: availabilityPalette.free; anchors.verticalCenter: parent.verticalCenter } Text { text: "Свободно"; font.pixelSize: 10; color: "black" } }
                    Row { spacing: 4; Rectangle { width: 12; height: 12; radius: 6; color: availabilityPalette.busy; anchors.verticalCenter: parent.verticalCenter } Text { text: "Занято"; font.pixelSize: 10; color: "black" } }
                }
            }
        }
    }
}
