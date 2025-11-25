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
    
    background: Rectangle {
        color: Theme.background
    }

    property int premisesId: 0
    property string premisesName: ""
    property string selectedDate: Qt.formatDate(new Date(), "yyyy-MM-dd")
    property string selectedTime: "18:30"
    property int selectedDuration: 120
    property string currentEndTime: ""
    property bool availabilityLoading: false
    property string availabilitySummary: "Укажите дату и время, чтобы увидеть свободные столы"
    property var durationOptions: [
        { "label": "1 ч", "minutes": 60 },
        { "label": "1.5 ч", "minutes": 90 },
        { "label": "2 ч", "minutes": 120 },
        { "label": "3 ч", "minutes": 180 }
    ]
    property var availabilityPalette: ({
        "free": "#6FCF97",
        "busy": "#F76C6C",
        "unknown": "#B0BEC5"
    })
    property bool isCompactLayout: width <= 640

    onIsCompactLayoutChanged: {
        if (!isCompactLayout && filtersDialog.visible) {
            filtersDialog.close()
        }
    }

    // Модель столов
    ListModel { id: tablesModel }
    BookingPopup {
        id: bookingPopup
        onBookingCreated: bookingPage.refreshAvailability()
    }

    Timer {
        id: availabilityDebounce
        interval: 350
        repeat: false
        onTriggered: bookingPage.refreshAvailability()
    }

    Component {
        id: filtersFormComponent
        ColumnLayout {
            spacing: Theme.spacingLarge

            GridLayout {
                columns: isCompactLayout ? 1 : 3
                Layout.fillWidth: true
                rowSpacing: Theme.spacingLarge
                columnSpacing: Theme.spacingLarge

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingSmall

                    Text {
                        text: Theme.iconCalendar + " Дата"
                        font.bold: true
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 54
                        radius: Theme.radiusLarge
                        color: Theme.surfaceDark
                        border.width: 1
                        border.color: dateInput.activeFocus ? Theme.primary : Theme.divider

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingSmall
                            spacing: Theme.spacingSmall

                            Text {
                                text: Theme.iconCalendar
                                font.pixelSize: Theme.fontSizeLarge
                                color: Theme.textSecondary
                            }

                            TextField {
                                id: dateInput
                                Layout.fillWidth: true
                                background: Item {}
                                text: selectedDate
                                inputMask: "9999-99-99"
                                validator: RegularExpressionValidator {
                                    regularExpression: /^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$/
                                }
                                font.pixelSize: Theme.fontSizeLarge
                                color: Theme.textPrimary
                                onTextChanged: {
                                    if (text !== selectedDate)
                                        selectedDate = text
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingSmall

                    Text {
                        text: Theme.iconTime + " Время начала"
                        font.bold: true
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 54
                        radius: Theme.radiusLarge
                        color: Theme.surfaceDark
                        border.width: 1
                        border.color: timeInput.activeFocus ? Theme.primary : Theme.divider

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingSmall
                            spacing: Theme.spacingSmall

                            Text {
                                text: Theme.iconTime
                                font.pixelSize: Theme.fontSizeLarge
                                color: Theme.textSecondary
                            }

                            TextField {
                                id: timeInput
                                Layout.fillWidth: true
                                background: Item {}
                                text: selectedTime
                                inputMask: "99:99"
                                validator: RegularExpressionValidator {
                                    regularExpression: /^([0-1][0-9]|2[0-3]):[0-5][0-9]$/
                                }
                                font.pixelSize: Theme.fontSizeLarge
                                color: Theme.textPrimary
                                onTextChanged: {
                                    if (text !== selectedTime)
                                        selectedTime = text
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingSmall

                    Text {
                        text: "⏱️ Длительность"
                        font.bold: true
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: Theme.spacingSmall
                        Repeater {
                            model: durationOptions
                            delegate: Rectangle {
                                width: isCompactLayout ? 88 : 72
                                height: 36
                                radius: Theme.radiusLarge
                                color: selectedDuration === modelData.minutes ? Theme.primary : Theme.surface
                                border.color: selectedDuration === modelData.minutes ? Theme.primaryDark : Theme.divider
                                border.width: 1

                                Text {
                                    text: modelData.label
                                    anchors.centerIn: parent
                                    color: selectedDuration === modelData.minutes ? "white" : Theme.textSecondary
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.bold: selectedDuration === modelData.minutes
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: selectedDuration = modelData.minutes
                                }
                            }
                        }
                    }

                    Text {
                        text: currentEndTime.length > 0 ? "Завершится около " + currentEndTime : ""
                        color: Theme.textHint
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }
            }
        }
    }

    Dialog {
        id: filtersDialog
        modal: true
        standardButtons: Dialog.NoButton
        title: ""
        width: Math.max(300, Math.min(bookingPage.width - Theme.spacingLarge * 2, 420))
        property real dialogMaxHeight: bookingPage.height - Theme.spacingLarge * 2
        height: Math.min(dialogColumn.implicitHeight + Theme.spacingLarge, dialogMaxHeight)
        x: (bookingPage.width - width) / 2
        y: Theme.spacingLarge
        padding: Theme.spacingMedium
        onRejected: close()
        background: Item {
            implicitWidth: parent ? parent.width : 0
            implicitHeight: parent ? parent.height : 0

            Rectangle {
                anchors.fill: parent
                anchors.margins: -6
                radius: Theme.radiusLarge + 6
                color: "#33000000"
                opacity: 0.4
            }

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusLarge
                border.color: Theme.divider
                border.width: 1
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#FFFFFF" }
                    GradientStop { position: 1.0; color: "#F3F6FB" }
                }
            }
        }

        contentItem: Flickable {
            clip: true
            anchors.fill: parent
            contentWidth: width
            contentHeight: dialogColumn.implicitHeight
            ScrollBar.vertical: ScrollBar { }

            Column {
                id: dialogColumn
                width: parent.width
                spacing: Theme.spacingMedium

                Rectangle {
                    width: parent.width
                    height: 56
                    radius: Theme.radiusLarge
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Theme.primary }
                        GradientStop { position: 1.0; color: Theme.primaryDark }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingSmall
                        Text {
                            text: "Настройка времени"
                            color: "white"
                            font.pixelSize: Theme.fontSizeLarge
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        ToolButton {
                            text: Theme.iconClose
                            contentItem: Text {
                                text: parent.text
                                color: "white"
                                font.pixelSize: Theme.fontSizeLarge
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle { color: "transparent" }
                            onClicked: filtersDialog.close()
                        }
                    }
                }

                Item {
                    width: parent.width
                    implicitHeight: filtersDialogLoader.item ? filtersDialogLoader.item.implicitHeight : 0

                    Loader {
                        id: filtersDialogLoader
                        anchors.fill: parent
                        sourceComponent: filtersFormComponent
                    }
                }

                Rectangle {
                    width: parent.width
                    radius: Theme.radiusLarge
                    color: Theme.surfaceDark
                    border.color: Theme.divider
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingMedium
                        spacing: Theme.spacingSmall

                        Text {
                            text: "Статус на выбранное время"
                            font.bold: true
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        Text {
                            text: availabilitySummary
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                            color: Theme.textPrimary
                            font.pixelSize: Theme.fontSizeMedium
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingSmall

                            BusyIndicator {
                                running: availabilityLoading
                                visible: availabilityLoading
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                            }

                            Item { Layout.fillWidth: true }

                            Button {
                                text: Theme.iconSearch + " Проверить"
                                Layout.preferredWidth: 160
                                Layout.preferredHeight: 40
                                background: Rectangle {
                                    radius: Theme.radiusLarge
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: Theme.primary }
                                        GradientStop { position: 1.0; color: Theme.primaryDark }
                                    }
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: bookingPage.handleAvailabilityCheck()
                            }
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 56

                    Button {
                        id: doneButton
                        text: "Готово"
                        height: 44
                        width: 140
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: filtersDialog.close()
                        background: Rectangle {
                            radius: Theme.radiusLarge
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Theme.primary }
                                GradientStop { position: 1.0; color: Theme.primaryDark }
                            }
                            border.color: "transparent"
                            border.width: 0
                        }
                        contentItem: Text {
                            text: doneButton.text
                            color: "white"
                            font.pixelSize: Theme.fontSizeMedium
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }
    }

    function loadTables() {
        tablesModel.clear()
        var tables = BackendApi.getTablesForPremises(premisesId)

        for(var i=0; i<tables.length; i++) {
            var t = tables[i]
            tablesModel.append({
                "dbId": t.id,
                "name": t.name,
                "x": t.x,
                "y": t.y,
                "width": t.width,
                "height": t.height,
                "shapeType": t.shapeType,
                "type": t.type || "table",
                "baseColor": t.color || "#81C784",
                "color": t.color || "#81C784",
                "availabilityState": "unknown",
                "rotation": t.rotation || 0
            })
        }

        recalcEndTimePreview()
        Qt.callLater(function() { bookingPage.refreshAvailability() })
    }

    function padNumber(val) {
        return (val < 10 ? "0" : "") + val
    }

    function recalcEndTimePreview() {
        var startDt = toDateTime(selectedDate, selectedTime)
        if (!startDt) {
            currentEndTime = ""
            return
        }
        var endDt = new Date(startDt.getTime() + selectedDuration * 60000)
        currentEndTime = formatTime(endDt)
    }

    function toDateTime(dateStr, timeStr) {
        if (!dateStr || dateStr.length < 10 || dateStr.indexOf("_") !== -1)
            return null
        if (!timeStr || timeStr.length < 5 || timeStr.indexOf("_") !== -1)
            return null
        return new Date(dateStr + "T" + timeStr + ":00")
    }

    function toQueryDate(dateStr) {
        if (!dateStr || dateStr.length < 10 || dateStr.indexOf("_") !== -1)
            return null
        var parts = dateStr.split("-")
        if (parts.length !== 3)
            return null
        return new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]))
    }

    function formatTime(dateObj) {
        if (!dateObj)
            return ""
        return padNumber(dateObj.getHours()) + ":" + padNumber(dateObj.getMinutes())
    }

    function parseSqlDateTime(value) {
        if (!value || value.length < 16)
            return null
        return new Date(value.replace(" ", "T"))
    }

    function intervalsOverlap(startA, endA, startB, endB) {
        if (!startA || !endA || !startB || !endB)
            return false
        return startA < endB && endA > startB
    }

    function scheduleAvailabilityUpdate() {
        availabilityDebounce.restart()
    }

    function refreshAvailability() {
        availabilityDebounce.stop()
        if (tablesModel.count === 0) {
            availabilitySummary = "В этом зале пока нет столов"
            availabilityLoading = false
            return
        }

        var startDt = toDateTime(selectedDate, selectedTime)
        if (!startDt) {
            availabilitySummary = "Введите корректные дату и время"
            availabilityLoading = false
            return
        }

        var endDt = new Date(startDt.getTime() + selectedDuration * 60000)
        var queryDate = toQueryDate(selectedDate)
        if (!queryDate) {
            availabilitySummary = "Введите корректную дату"
            availabilityLoading = false
            return
        }

        availabilityLoading = true
        var freeCount = 0
        var totalTables = 0

        for (var i = 0; i < tablesModel.count; i++) {
            var entry = tablesModel.get(i)
            if (entry.type !== "table")
                continue

            totalTables++
            var bookings = BackendApi.getBookingsForTable(entry.dbId, queryDate) || []
            var busy = false
            for (var j = 0; j < bookings.length; j++) {
                var booking = bookings[j]
                var bookingStart = parseSqlDateTime(booking.startTime)
                var bookingEnd = parseSqlDateTime(booking.endTime)
                if (intervalsOverlap(startDt, endDt, bookingStart, bookingEnd)) {
                    busy = true
                    break
                }
            }

            var color = busy ? availabilityPalette.busy : availabilityPalette.free
            tablesModel.setProperty(i, "color", color)
            tablesModel.setProperty(i, "availabilityState", busy ? "busy" : "free")
            if (!busy) {
                freeCount++
            }
        }

        availabilityLoading = false
        if (totalTables === 0) {
            availabilitySummary = "Нет доступных столов для отображения"
        } else {
            availabilitySummary = "Свободно " + freeCount + " из " + totalTables + " столов (" + selectedTime + " - " + formatTime(endDt) + ")"
        }
    }

    onSelectedDateChanged: scheduleAvailabilityUpdate()
    onSelectedTimeChanged: {
        recalcEndTimePreview()
        scheduleAvailabilityUpdate()
    }
    onSelectedDurationChanged: {
        recalcEndTimePreview()
        scheduleAvailabilityUpdate()
    }

    function handleAvailabilityCheck() {
        refreshAvailability()
        if (isCompactLayout && filtersDialog.visible) {
            filtersDialog.close()
        }
    }

    Component.onCompleted: loadTables()

    header: ToolBar {
        background: Rectangle {
            color: Theme.surface
        }
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            
            ToolButton {
                Text {
                    text: Theme.iconBack
                    font.pixelSize: 24
                    color: Theme.textPrimary
                    anchors.centerIn: parent
                }
                onClicked: bookingPage.StackView.view.pop()
            }
            
            Label {
                text: bookingPage.title
                font.bold: true
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.textPrimary
                Layout.fillWidth: true
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingMedium
        spacing: Theme.spacingMedium

        Button {
            visible: isCompactLayout
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            text: Theme.iconFilter + " Настроить время"
            background: Rectangle {
                radius: Theme.radiusMedium
                color: Theme.primary
                opacity: parent.pressed ? 0.85 : 1.0
            }
            contentItem: Text {
                text: parent.text
                color: "white"
                font.pixelSize: Theme.fontSizeMedium
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            onClicked: filtersDialog.open()
        }

        Rectangle {
            id: filtersCard
            visible: !isCompactLayout
            Layout.fillWidth: true
            color: Theme.surface
            radius: Theme.radiusLarge
            border.color: Theme.divider
            border.width: 1

            Loader {
                anchors.fill: parent
                anchors.margins: Theme.spacingMedium
                sourceComponent: filtersFormComponent
            }
        }

        Rectangle {
            id: compactSummaryCard
            visible: isCompactLayout && tablesModel.count > 0
            Layout.fillWidth: true
            color: Theme.surface
            radius: Theme.radiusLarge
            border.color: Theme.divider
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingMedium
                spacing: Theme.spacingMedium

                Text {
                    text: availabilitySummary
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                    color: Theme.textPrimary
                    font.pixelSize: Theme.fontSizeMedium
                }

                BusyIndicator {
                    running: availabilityLoading
                    visible: availabilityLoading
                    Layout.alignment: Qt.AlignVCenter
                }

                Button {
                    text: Theme.iconSearch
                    Layout.preferredWidth: 64
                    onClicked: handleAvailabilityCheck()
                }
            }
        }

        Item {
            id: hallContainer
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

    ZoomableHall {
        id: hallView
        anchors.fill: parent
        anchors.bottomMargin: hintBar.visible ? hintBar.height + Theme.spacingMedium : 0
        tablesModel: tablesModel
        editMode: false
        
        onTableClicked: (idx, dbId) => {
            var table = tablesModel.get(idx)
            bookingPopup.tableId = dbId
            bookingPopup.tableName = table.name
                    bookingPopup.prefill(selectedDate, selectedTime, currentEndTime || "")
            bookingPopup.open()
        }
        
        Connections {
            target: tablesModel
            function onCountChanged() {
                if (tablesModel.count > 0) {
                    Qt.callLater(function() {
                        if (hallView.centerOnObjects) {
                            hallView.centerOnObjects()
                        }
                    })
                }
            }
        }
        
        Component.onCompleted: {
            Qt.callLater(function() {
                if (tablesModel.count > 0 && hallView.centerOnObjects) {
                    hallView.centerOnObjects()
                }
            })
        }
    }
    
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: Theme.spacingMedium
                color: "#FFFFFFCC"
                radius: Theme.radiusMedium
                border.color: Theme.divider
                border.width: 1
                implicitWidth: selectionLabel.implicitWidth + Theme.spacingLarge
                implicitHeight: selectionLabel.implicitHeight + Theme.spacingMedium
                Text {
                    id: selectionLabel
                    text: selectedDate + " · " + selectedTime + (currentEndTime ? (" – " + currentEndTime) : "")
                    color: Theme.textPrimary
                    font.pixelSize: Theme.fontSizeMedium
                    font.bold: true
                    anchors.centerIn: parent
                }
            }

    Rectangle {
        id: hintBar
        anchors.left: parent.left
        anchors.right: parent.right
                anchors.bottom: parent.bottom
        anchors.margins: Theme.spacingMedium
                height: 64
        radius: Theme.radiusMedium
                color: Theme.surface
                border.color: Theme.divider
                border.width: 1
                visible: !isCompactLayout && tablesModel.count > 0
        z: 100
        
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingMedium
                    spacing: Theme.spacingLarge
                    Layout.alignment: Qt.AlignVCenter

                    RowLayout {
                        spacing: Theme.spacingSmall
        Rectangle {
                            width: 16
                            height: 16
                            radius: 8
                            color: availabilityPalette.free
                        }
                        Text {
                            text: "Свободно"
                            color: Theme.textPrimary
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    RowLayout {
            spacing: Theme.spacingSmall
                        Rectangle {
                            width: 16
                            height: 16
                            radius: 8
                            color: availabilityPalette.busy
                        }
                        Text {
                            text: "Занято"
                            color: Theme.textPrimary
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    Item { Layout.fillWidth: true; Layout.preferredHeight: 1 }
            
            Text {
                        text: "Тапните по столу, чтобы забронировать"
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSizeMedium
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    }
                }
            }

            Rectangle {
                id: compactHint
                visible: isCompactLayout && tablesModel.count > 0
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.spacingMedium
                radius: Theme.radiusMedium
                color: "#FFFFFFCC"
                border.color: Theme.divider
                border.width: 1
                implicitWidth: compactHintText.implicitWidth + Theme.spacingLarge
                implicitHeight: compactHintText.implicitHeight + Theme.spacingSmall
            
            Text {
                    id: compactHintText
                    anchors.margins: Theme.spacingSmall
                    anchors.centerIn: parent
                    text: "🪑 Выберите стол на плане"
                    color: Theme.textPrimary
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: true
                }
            }
        }
    }
}
