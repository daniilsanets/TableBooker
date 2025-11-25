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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingMedium
        spacing: Theme.spacingMedium

        Rectangle {
            Layout.fillWidth: true
            height: 120
            radius: Theme.radiusLarge
            color: Theme.surface
            border.color: Theme.divider
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingMedium
                spacing: Theme.spacingMedium

                Rectangle {
                    width: 72
                    height: 72
                    radius: 36
                    color: Theme.primary
                    Text {
                        text: Theme.iconPerson
                        font.pixelSize: 34
                        anchors.centerIn: parent
                    }
                }

                    ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingSmall
                    Label {
                        text: username
                        font.bold: true
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.textPrimary
                    }
                    Label {
                        text: BackendApi.currentUserRole === "admin" ? "Администратор" : "Гость"
                        color: Theme.textSecondary
                    }
                }
            }
        }

        TabBar {
            id: profileTabs
            Layout.fillWidth: true
            TabButton { text: "Настройки" }
            TabButton { text: "Мои брони" }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: profileTabs.currentIndex

            // Настройки
            Flickable {
                clip: true
                contentWidth: width
                contentHeight: settingsColumn.implicitHeight
                ColumnLayout {
                    id: settingsColumn
                    width: parent.width
                    spacing: Theme.spacingMedium

                    Rectangle {
                        Layout.fillWidth: true
                        radius: Theme.radiusLarge
                        color: Theme.surface
                        border.color: Theme.divider
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingMedium
                            spacing: Theme.spacingMedium

                            Text {
                                text: "Настройки уведомлений"
                                font.bold: true
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeMedium
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: "Push-уведомления"; Layout.fillWidth: true }
                                Switch { checked: true; enabled: false }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: "Email-подтверждения"; Layout.fillWidth: true }
                                Switch { checked: false; enabled: false }
                            }
                        }
                    }

                    Button {
                        text: "ℹ️ О программе"
                        Layout.fillWidth: true
                        height: 48
                        background: Rectangle {
                            color: Theme.surface
                            radius: Theme.radiusMedium
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
                        onClicked: profilePage.StackView.view.push("../AboutPage.qml")
                    }

                    Button {
                        text: "🚪 Выйти из профиля"
                        Layout.fillWidth: true
                        height: 52
                        background: Rectangle {
                            radius: Theme.radiusMedium
                            color: Theme.error
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

            // Мои брони
            ColumnLayout {
                spacing: Theme.spacingSmall
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: bookingsList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Theme.spacingSmall
                    clip: true
                    model: bookingsModel

                    delegate: Rectangle {
                        width: bookingsList.width
                        height: 130
                        radius: Theme.radiusMedium
                        color: Theme.surface
                        border.color: Theme.divider
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingMedium
                            spacing: Theme.spacingSmall

                            Text {
                                text: (model.premisesName || "Заведение") + " · " + (model.tableName || ("Стол #" + model.tableId))
                                font.bold: true
                                color: Theme.textPrimary
                            }

                            Text {
                                text: formatDateTime(model.startTime) + " — " + formatDateTime(model.endTime)
                                color: Theme.textSecondary
                            }

                            Item { Layout.fillHeight: true }

                            Button {
                                text: "Отменить бронь"
                                Layout.fillWidth: true
                                height: 36
                                background: Rectangle {
                                    radius: Theme.radiusMedium
                                    color: Theme.surfaceDark
                                    border.color: Theme.divider
                                    border.width: 1
                                }
                                onClicked: handleCancel(model.id)
                            }
                        }
                    }

                    Text {
                        visible: bookingsList.count === 0
                        text: "У вас пока нет активных броней"
                        anchors.centerIn: parent
                        color: Theme.textSecondary
                    }
                }
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

