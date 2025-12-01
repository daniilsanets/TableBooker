import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import com.tablebooker.api 1.0
import "../Theme.js" as Theme

Page {
    id: profilePage
    title: "Профиль"

    background: Rectangle { color: Theme.background }

    ListModel { id: bookingsModel }

    property string username: BackendApi.currentUserName || ("Пользователь #" + BackendApi.currentUserId)
    property bool isCompactLayout: width <= 560
    property int profileSectionIndex: 0
    property var profilePalette: ({
        "heroStart": "#4C5FDD",
        "heroEnd": "#7986F8",
        "chipBg": "#33FFFFFF",
        "chipBorder": "#55FFFFFF",
        "statBg": "#1FFFFFFF",
        "statBorder": "#3DFFFFFF",
        "actionBg": "#29FFFFFF",
        "actionBorder": "#4DFFFFFF",
        "cardBorder": "#40FFFFFF"
    })

    function loadBookings() {
        username = BackendApi.currentUserName || ("Пользователь #" + BackendApi.currentUserId)
        bookingsModel.clear()
        var data = BackendApi.getUserBookings()
        if (!data) return
        for (var i = 0; i < data.length; i++) {
            bookingsModel.append(data[i])
        }
    }

    function formatDateTime(value) {
        if (!value || value.length < 16) return value || ""
        var date = new Date(value.replace(" ", "T"))
        return Qt.formatDateTime(date, "dd MMM HH:mm")
    }

    function handleCancel(bookingId) {
        confirmDialog.bookingId = bookingId
        confirmDialog.open()
    }

    function performLogout() {
        BackendApi.logout()
        var stack = profilePage.StackView.view
        stack.clear()
        stack.push("../LoginScreen.qml")
    }

    Component.onCompleted: loadBookings()
    onVisibleChanged: if (visible) loadBookings()

    header: ToolBar {
        background: Rectangle { color: Theme.surface }
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
                onClicked: profilePage.StackView.view.pop()
            }
            Label {
                text: "Профиль"
                font.bold: true
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.textPrimary
                Layout.fillWidth: true
            }
        }
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentColumn.implicitHeight + Theme.spacingLarge * 2
        clip: true

        ColumnLayout {
            id: contentColumn
            width: Math.min(profilePage.width - Theme.spacingLarge * 2, 860)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.margins: Theme.spacingLarge
            spacing: Theme.spacingLarge

        Rectangle {
                id: heroCard
            Layout.fillWidth: true
                implicitHeight: implicitContent.implicitHeight + Theme.spacingLarge * 2
                radius: Theme.radiusLarge * 1.5
            border.width: 1
                border.color: profilePalette.cardBorder
                gradient: Gradient {
                    GradientStop { position: 0.0; color: profilePalette.heroStart }
                    GradientStop { position: 1.0; color: profilePalette.heroEnd }
                }
                antialiasing: true
                clip: true

                Rectangle { anchors.fill: parent; color: "#FFFFFF"; opacity: 0.08 }

                Column {
                    id: implicitContent
                    width: parent.width - Theme.spacingLarge * 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: Theme.spacingLarge
                    anchors.bottomMargin: Theme.spacingLarge
                    spacing: Theme.spacingLarge

            RowLayout {
                        width: parent.width
                        spacing: Theme.spacingLarge
                        Layout.alignment: Qt.AlignTop

                Rectangle {
                            width: isCompactLayout ? 84 : 96
                            height: width
                            radius: width / 2
                            border.width: 2
                            border.color: "#FFFFFFAA"
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#FFFFFF44" }
                                GradientStop { position: 1.0; color: "#FFFFFF11" }
                            }
                    Text {
                        text: Theme.iconPerson
                                font.pixelSize: isCompactLayout ? 36 : 42
                        anchors.centerIn: parent
                    }
                }

                        Column {
                            width: parent.width - (isCompactLayout ? 84 : 96) - Theme.spacingLarge
                    spacing: Theme.spacingSmall

                            Text {
                        text: username
                                font.pixelSize: isCompactLayout ? Theme.fontSizeXLarge : Theme.fontSizeXXLarge
                        font.bold: true
                                color: "white"
                                wrapMode: Text.Wrap
                            }

                            Rectangle {
                                height: 36
                                radius: 18
                                color: profilePalette.chipBg
                                border.color: profilePalette.chipBorder
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingSmall
                                    spacing: Theme.spacingSmall
                                    Text {
                        text: BackendApi.currentUserRole === "admin" ? "Администратор" : "Гость"
                                        color: "white"
                                        font.pixelSize: Theme.fontSizeMedium
                                        font.bold: true
                                    }
                                    Text {
                                        text: "#" + BackendApi.currentUserId
                                        color: "#F2F5FFDD"
                                        font.pixelSize: Theme.fontSizeSmall
                                    }
                                }
                            }

                            Text {
                                text: "Всего броней: " + bookingsModel.count
                                color: "#F2F5FF"
                                font.pixelSize: Theme.fontSizeMedium
                            }
                        }
                    }

                    GridLayout {
                        id: statsLayout
                        Layout.fillWidth: true
                        columns: isCompactLayout ? 1 : 3
                        columnSpacing: Theme.spacingSmall
                        rowSpacing: Theme.spacingSmall

                        Repeater {
                            model: [
                                { label: "Роль", value: BackendApi.currentUserRole === "admin" ? "Админ" : "Гость" },
                                { label: "Брони", value: bookingsModel.count },
                                { label: "ID", value: BackendApi.currentUserId }
                            ]

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredWidth: statsLayout.width / statsLayout.columns
                                implicitHeight: 68
                                radius: Theme.radiusLarge
                                color: profilePalette.statBg
                                border.color: profilePalette.statBorder
                                antialiasing: true

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 2
                                    Text {
                                        text: modelData.label
                                        color: "#F7F8FF"
                                        font.pixelSize: Theme.fontSizeSmall
                                        opacity: 0.85
                                    }
                                    Text {
                                        text: modelData.value
                                        font.bold: true
                                        color: "white"
                                        font.pixelSize: Theme.fontSizeLarge
                                    }
                                }
                            }
                        }
                    }

                    GridLayout {
                        id: actionsLayout
                        Layout.fillWidth: true
                        columns: isCompactLayout ? 1 : 2
                        columnSpacing: Theme.spacingSmall
                        rowSpacing: Theme.spacingSmall

                        Button {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            text: Theme.iconSettings + " Настройки"
                            background: Rectangle {
                                radius: Theme.radiusMedium
                                color: profilePalette.actionBg
                                border.color: profilePalette.actionBorder
                            }
                            contentItem: Text {
                                text: parent.text
                                color: "white"
                                font.pixelSize: Theme.fontSizeMedium
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: profileSectionIndex = 0
                        }

                        Button {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            text: Theme.iconCalendar + " Мои брони"
                            background: Rectangle {
                                radius: Theme.radiusMedium
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "#66FFFFFF" }
                                    GradientStop { position: 1.0; color: "#29FFFFFF" }
                                }
                                border.color: profilePalette.actionBorder
                            }
                            contentItem: Text {
                                text: parent.text
                                color: "white"
                                font.pixelSize: Theme.fontSizeMedium
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: profileSectionIndex = 1
                        }
                    }
                }
            }

                    Rectangle {
                id: contentCard
                        Layout.fillWidth: true
                        radius: Theme.radiusLarge
                        color: Theme.surface
                        border.color: Theme.divider
                        border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingLarge
                    spacing: Theme.spacingLarge

                    TabBar {
                        id: profileTabs
                        width: parent.width
                        currentIndex: profileSectionIndex
                        onCurrentIndexChanged: profileSectionIndex = currentIndex
                        padding: 4
                        spacing: Theme.spacingSmall
                        background: Rectangle {
                            radius: Theme.radiusMedium
                            color: Theme.surfaceDark
                            border.color: Theme.divider
                        }

                        TabButton {
                            text: "Настройки"
                            background: Rectangle {
                                radius: Theme.radiusMedium
                                color: control.checked ? Theme.primary : "transparent"
                                border.color: control.checked ? Theme.primary : "transparent"
                            }
                            contentItem: Text {
                                text: control.text
                                font.pixelSize: Theme.fontSizeMedium
                                font.bold: control.checked
                                color: control.checked ? "white" : Theme.textSecondary
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        TabButton {
                            text: "Мои брони"
                            background: Rectangle {
                                radius: Theme.radiusMedium
                                color: control.checked ? Theme.primary : "transparent"
                                border.color: control.checked ? Theme.primary : "transparent"
                            }
                            contentItem: Text {
                                text: control.text
                                font.pixelSize: Theme.fontSizeMedium
                                font.bold: control.checked
                                color: control.checked ? "white" : Theme.textSecondary
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    Loader {
                        id: contentLoader
                        width: parent.width
                        sourceComponent: profileSectionIndex === 0 ? settingsViewComponent : bookingsViewComponent
                    }
                }
            }
        }
    }

    Component {
        id: settingsViewComponent
        Column {
            width: contentLoader.width
            spacing: Theme.spacingLarge

            Rectangle {
                width: parent.width
                radius: Theme.radiusLarge
                color: Theme.surfaceDark
                border.color: Theme.divider
                border.width: 1

                Column {
                            anchors.fill: parent
                    anchors.margins: Theme.spacingLarge
                            spacing: Theme.spacingMedium

                            Text {
                                text: "Настройки уведомлений"
                                font.bold: true
                                color: Theme.textPrimary
                        font.pixelSize: Theme.fontSizeLarge
                    }

                    Text {
                        text: "Уведомления синхронизируются между всеми устройствами. Включение опций скоро будет доступно."
                        wrapMode: Text.Wrap
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    Repeater {
                        model: [
                            { icon: Theme.iconPush ? Theme.iconPush : "🔔", label: "Push-уведомления", enabled: false, checked: true },
                            { icon: Theme.iconEmail, label: "Email-подтверждения", enabled: false, checked: false }
                        ]

                        delegate: RowLayout {
                            width: parent.width
                            spacing: Theme.spacingSmall
                            Label {
                                text: modelData.icon
                                Layout.preferredWidth: 24
                                horizontalAlignment: Text.AlignLeft
                            }
                            Label {
                                text: modelData.label
                                Layout.fillWidth: true
                                color: Theme.textPrimary
                            }
                            Switch {
                                checked: modelData.checked
                                enabled: modelData.enabled
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                radius: Theme.radiusLarge
                color: Theme.surface
                border.color: Theme.divider
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingLarge
                    spacing: Theme.spacingMedium

                    Text {
                        text: "Действия"
                        font.pixelSize: Theme.fontSizeLarge
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    Text {
                        text: "Перейдите к информации о приложении или выйдите из профиля."
                        wrapMode: Text.Wrap
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    Button {
                        text: Theme.iconInfo + " О программе"
                        Layout.fillWidth: true
                        height: 48
                        background: Rectangle {
                            radius: Theme.radiusMedium
                            color: Theme.surfaceDark
                            border.color: Theme.divider
                            border.width: 1
                        }
                        contentItem: Text {
                            text: parent.text
                            color: Theme.textPrimary
                            font.pixelSize: Theme.fontSizeMedium
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: profilePage.StackView.view.push("../AboutPage.qml")
                    }

                    Button {
                        text: Theme.iconLogout + " Выйти из профиля"
                        Layout.fillWidth: true
                        height: 52
                        background: Rectangle {
                            radius: Theme.radiusMedium
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Theme.error }
                                GradientStop { position: 1.0; color: "#A61F1F" }
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
                        onClicked: performLogout()
                    }
                }
            }
        }
    }

    Component {
        id: bookingsViewComponent
        Column {
            width: contentLoader.width
            spacing: Theme.spacingMedium

            Repeater {
                    model: bookingsModel
                    delegate: Rectangle {
                    width: parent.width
                    height: 150
                    radius: Theme.radiusLarge
                    border.width: 1
                        border.color: Theme.divider
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#F8FAFF" }
                        GradientStop { position: 1.0; color: "#EEF2FF" }
                    }

                        ColumnLayout {
                            anchors.fill: parent
                        anchors.margins: Theme.spacingLarge
                            spacing: Theme.spacingSmall

                            Text {
                                text: (model.premisesName || "Заведение") + " · " + (model.tableName || ("Стол #" + model.tableId))
                                font.bold: true
                            font.pixelSize: Theme.fontSizeLarge
                                color: Theme.textPrimary
                            }

                            Text {
                                text: formatDateTime(model.startTime) + " — " + formatDateTime(model.endTime)
                                color: Theme.textSecondary
                            }

                            Item { Layout.fillHeight: true }

                            Button {
                            text: Theme.iconDelete + " Отменить бронь"
                                Layout.fillWidth: true
                            height: 40
                                background: Rectangle {
                                    radius: Theme.radiusMedium
                                color: Theme.surface
                                    border.color: Theme.divider
                                    border.width: 1
                                }
                            contentItem: Text {
                                text: parent.text
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeMedium
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: handleCancel(model.id)
                        }
                            }
                        }
                    }

                    Text {
                visible: bookingsModel.count === 0
                        text: "У вас пока нет активных броней"
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
                        color: Theme.textSecondary
            }
        }
    }

    Dialog {
        id: confirmDialog
        property int bookingId: -1
        title: "Отмена брони"
        standardButtons: Dialog.Ok | Dialog.Cancel
        contentItem: Label {
            text: "Точно отменить эту бронь?"
            wrapMode: Text.WordWrap
        }
        onAccepted: {
            if (bookingId >= 0) {
                if (BackendApi.cancelBooking(bookingId)) {
                    loadBookings()
                }
            }
        }
    }
}

