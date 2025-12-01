import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import com.tablebooker.api 1.0
import "../components"
import "../Theme.js" as Theme

Page {
    id: profilePage
    title: "Профиль"

    background: Rectangle {
        color: Theme.background
    }

    property string userRole: BackendApi.currentUserRole
    property string userName: BackendApi.currentUserName !== "" ? BackendApi.currentUserName : "Пользователь"
    property var userBookings: []

    // Хелпер для названий месяцев
    readonly property var monthNames: ["Янв", "Фев", "Мар", "Апр", "Май", "Июн", "Июл", "Авг", "Сен", "Окт", "Ноя", "Дек"]

    function loadBookings() {
        userBookings = BackendApi.getUserBookings()
    }

    function cancelBooking(id) {
        var success = BackendApi.cancelBooking(id)
        if (success) {
            loadBookings()
        }
    }

    // Парсим дату "YYYY-MM-DD HH:MM:SS"
    function getDay(dateStr) {
        return dateStr.substring(8, 10)
    }

    function getMonth(dateStr) {
        var monthIndex = parseInt(dateStr.substring(5, 7)) - 1
        if (monthIndex >= 0 && monthIndex < 12) return monthNames[monthIndex]
        return ""
    }

    function getTime(dateStr) {
        return dateStr.substring(11, 16)
    }

    Component.onCompleted: loadBookings()

    header: ToolBar {
        background: Rectangle { color: Theme.surface }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 16

            ToolButton {
                text: Theme.iconBack
                contentItem: Text {
                    text: parent.text
                    font.pixelSize: 24
                    color: Theme.textPrimary
                    anchors.centerIn: parent
                }
                onClicked: profilePage.StackView.view.pop()
            }

            Label {
                text: profilePage.title
                font.bold: true
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.textPrimary
                Layout.fillWidth: true
            }

            ToolButton {
                text: Theme.iconRotateRight
                contentItem: Text {
                    text: parent.text
                    font.pixelSize: 20
                    color: Theme.primary
                    anchors.centerIn: parent
                }
                onClicked: loadBookings()
            }
        }
    }

    Flickable {
        anchors.fill: parent
        contentHeight: contentColumn.height + 40
        clip: true

        ColumnLayout {
            id: contentColumn
            width: parent.width
            spacing: Theme.spacingMedium

            // --- КАРТОЧКА ПРОФИЛЯ ---
            Rectangle {
                Layout.fillWidth: true
                height: 130
                radius: 0
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Theme.primary }
                    GradientStop { position: 1.0; color: Theme.primaryDark }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingLarge
                    spacing: Theme.spacingMedium

                    Rectangle {
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 64
                        radius: 32
                        color: "white"
                        opacity: 0.95
                        Text {
                            text: "👤"
                            font.pixelSize: 32
                            anchors.centerIn: parent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: userName
                            color: "white"
                            font.bold: true
                            font.pixelSize: 20
                        }

                        Row {
                            spacing: 6
                            Rectangle {
                                color: "white"
                                radius: 4
                                opacity: 0.25
                                width: roleLabel.width + 12
                                height: 20
                                Text {
                                    id: roleLabel
                                    text: userRole === "superadmin" ? "👑 Основатель" : (userRole === "admin" ? "Админ" : "Гость")
                                    color: "white"
                                    font.pixelSize: 11
                                    font.bold: true
                                    anchors.centerIn: parent
                                }
                            }
                            Text {
                                text: "ID: " + BackendApi.currentUserId
                                color: "#E0E0E0"
                                font.pixelSize: 12
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }

            // --- СПИСОК БРОНИРОВАНИЙ ---
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.spacingMedium
                Layout.rightMargin: Theme.spacingMedium
                spacing: Theme.spacingSmall

                Text {
                    text: "Мои бронирования"
                    font.bold: true
                    font.pixelSize: Theme.fontSizeLarge
                    color: Theme.textPrimary
                    Layout.topMargin: 8
                    Layout.bottomMargin: 8
                }

                Repeater {
                    model: userBookings
                    delegate: Card {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 90 // Компактная высота

                        content: RowLayout {
                            anchors.fill: parent
                            spacing: Theme.spacingMedium

                            // 1. БЛОК ДАТЫ (Слева)
                            Rectangle {
                                Layout.preferredWidth: 56
                                Layout.fillHeight: true
                                radius: Theme.radiusMedium
                                color: Qt.alpha(Theme.primary, 0.1) // Прозрачный синий фон

                                Column {
                                    anchors.centerIn: parent
                                    spacing: -2 // Чуть сближаем

                                    Text {
                                        text: getDay(modelData.startTime)
                                        font.bold: true
                                        font.pixelSize: 22
                                        color: Theme.primary
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Text {
                                        text: getMonth(modelData.startTime)
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        color: Theme.primary
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }
                            }

                            // 2. ИНФОРМАЦИЯ (Центр)
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 4

                                Text {
                                    text: modelData.premisesName
                                    font.bold: true
                                    font.pixelSize: 16
                                    color: Theme.textPrimary
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                RowLayout {
                                    spacing: 12

                                    // Время
                                    Row {
                                        spacing: 4
                                        Text { text: "🕒"; font.pixelSize: 12 }
                                        Text {
                                            text: getTime(modelData.startTime) + " - " + getTime(modelData.endTime)
                                            color: Theme.textPrimary
                                            font.bold: true
                                            font.pixelSize: 13
                                        }
                                    }

                                    // Стол
                                    Row {
                                        spacing: 4
                                        Text { text: "🪑"; font.pixelSize: 12 }
                                        Text {
                                            text: modelData.tableName
                                            color: Theme.textSecondary
                                            font.pixelSize: 13
                                        }
                                    }
                                }
                            }

                            // 3. КНОПКА ОТМЕНЫ (Круглая справа)
                            Rectangle {
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                radius: 18
                                color: cancelMouseArea.pressed ? "#FFEBEE" : "transparent"
                                border.color: Theme.error
                                border.width: 1
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    text: "✕"
                                    color: Theme.error
                                    font.pixelSize: 14
                                    font.bold: true
                                    anchors.centerIn: parent // Идеальный центр
                                    anchors.verticalCenterOffset: -1 // Микро-коррекция для шрифта
                                }

                                MouseArea {
                                    id: cancelMouseArea
                                    anchors.fill: parent
                                    onClicked: cancelBooking(modelData.id)
                                }
                            }
                        }
                    }
                }

                // Заглушка (если нет броней)
                Item {
                    Layout.fillWidth: true
                    height: 120
                    visible: userBookings.length === 0

                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: "📅"
                            font.pixelSize: 48
                            anchors.horizontalCenter: parent.horizontalCenter
                            opacity: 0.3
                        }
                        Text {
                            text: "У вас пока нет активных бронирований"
                            color: Theme.textHint
                            font.pixelSize: Theme.fontSizeMedium
                        }
                    }
                }
            }

            // --- НИЖНЕЕ МЕНЮ ---
            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: Theme.spacingMedium
                Layout.topMargin: 20
                spacing: Theme.spacingMedium

                ColumnLayout {
                    visible: userRole === "admin" || userRole === "superadmin"
                    Layout.fillWidth: true
                    spacing: Theme.spacingMedium

                    Text { text: "Управление"; font.bold: true; color: Theme.textSecondary; font.pixelSize: 12 }

                    MaterialButton {
                        text: "Мои заведения"
                        iconText: Theme.iconRestaurant
                        isPrimary: false
                        Layout.fillWidth: true
                        onClicked: profilePage.StackView.view.push("../admin/AdminDashboardPage.qml")
                    }

                    MaterialButton {
                        visible: userRole === "superadmin"
                        text: "Пользователи"
                        iconText: "👥"
                        isPrimary: false
                        Layout.fillWidth: true
                        onClicked: profilePage.StackView.view.push("../admin/UserManagementPage.qml")
                    }
                }

                Text { text: "Приложение"; font.bold: true; color: Theme.textSecondary; font.pixelSize: 12; Layout.topMargin: 8 }

                MaterialButton {
                    text: "О программе"
                    iconText: Theme.iconInfo
                    isPrimary: false
                    Layout.fillWidth: true
                    onClicked: profilePage.StackView.view.push("../AboutPage.qml")
                }

                MaterialButton {
                    text: "Выйти"
                    iconText: Theme.iconLogout
                    isFlat: true
                    Layout.fillWidth: true
                    onClicked: {
                        BackendApi.logout()
                        var stack = profilePage.StackView.view
                        stack.clear()
                        stack.push("../LoginScreen.qml")
                    }
                    contentItem: Text {
                        text: parent.text
                        color: Theme.error
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
