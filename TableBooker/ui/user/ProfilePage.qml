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

    // Загрузка списка бронирований
    function loadBookings() {
        userBookings = BackendApi.getUserBookings()
    }

    // Отмена бронирования
    function cancelBooking(id) {
        var success = BackendApi.cancelBooking(id)
        if (success) {
            loadBookings() // Обновляем список
        }
    }

    Component.onCompleted: loadBookings()

    // Шапка страницы (Header)
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

            // Кнопка обновления
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

    // Основной контент с прокруткой
    Flickable {
        anchors.fill: parent
        contentHeight: contentColumn.height + 40
        clip: true

        ColumnLayout {
            id: contentColumn
            width: parent.width
            spacing: Theme.spacingMedium

            // 1. КАРТОЧКА ПРОФИЛЯ
            Rectangle {
                Layout.fillWidth: true
                height: 140
                radius: 0 // На всю ширину
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Theme.primary }
                    GradientStop { position: 1.0; color: Theme.primaryDark }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingLarge
                    spacing: Theme.spacingMedium

                    // Аватар
                    Rectangle {
                        Layout.preferredWidth: 70
                        Layout.preferredHeight: 70
                        radius: 35
                        color: "white"
                        opacity: 0.9
                        Text {
                            text: "👤"
                            font.pixelSize: 32
                            anchors.centerIn: parent
                        }
                    }

                    // Инфо
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: userName
                            color: "white"
                            font.bold: true
                            font.pixelSize: Theme.fontSizeXLarge
                        }

                        Rectangle {
                            color: "white"
                            radius: 4
                            opacity: 0.2
                            Layout.preferredHeight: 24
                            Layout.preferredWidth: roleLabel.width + 16

                            Text {
                                id: roleLabel
                                text: userRole === "superadmin" ? "👑 Основатель" : (userRole === "admin" ? "Администратор" : "Гость")
                                color: "white" // Для контраста на темном фоне лучше белый
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                anchors.centerIn: parent
                            }
                        }

                        Text {
                            text: "ID: " + BackendApi.currentUserId
                            color: "#E0E0E0"
                            font.pixelSize: Theme.fontSizeSmall
                        }
                    }
                }
            }

            // 2. СЕКЦИЯ БРОНИРОВАНИЙ
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
                    Layout.topMargin: Theme.spacingMedium
                }

                // Список броней (через Repeater внутри ColumnLayout, чтобы скроллилось вместе со всей страницей)
                Repeater {
                    model: userBookings
                    delegate: Card {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 110

                        content: RowLayout {
                            anchors.fill: parent
                            spacing: Theme.spacingMedium

                            // Дата (слева, крупно)
                            Column {
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2
                                width: 50

                                Text {
                                    // Парсим дату "YYYY-MM-DD HH:MM:SS" -> Число
                                    text: modelData.startTime.substring(8, 10)
                                    font.bold: true
                                    font.pixelSize: 24
                                    color: Theme.primary
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                Text {
                                    // Месяц (упрощенно)
                                    text: "Дата"
                                    font.pixelSize: 10
                                    color: Theme.textSecondary
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }

                            Rectangle {
                                width: 1
                                height: parent.height * 0.8
                                color: Theme.divider
                                Layout.alignment: Qt.AlignVCenter
                            }

                            // Детали
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Text {
                                    text: modelData.premisesName
                                    font.bold: true
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.textPrimary
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Row {
                                    spacing: 4
                                    Text { text: "🪑"; font.pixelSize: 12 }
                                    Text {
                                        text: modelData.tableName
                                        color: Theme.textSecondary
                                        font.pixelSize: Theme.fontSizeSmall
                                    }
                                }

                                Row {
                                    spacing: 4
                                    Text { text: "🕒"; font.pixelSize: 12 }
                                    Text {
                                        // Время: "18:00 - 20:00"
                                        text: modelData.startTime.substring(11, 16) + " - " + modelData.endTime.substring(11, 16)
                                        color: Theme.textSecondary
                                        font.pixelSize: Theme.fontSizeSmall
                                    }
                                }
                            }

                            // Кнопка отмены
                            Button {
                                text: "✕"
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40
                                background: Rectangle {
                                    color: parent.pressed ? "#FFEBEE" : "transparent"
                                    radius: 20
                                    border.color: Theme.error
                                    border.width: 1
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: Theme.error
                                    anchors.centerIn: parent
                                    font.pixelSize: 16
                                }
                                onClicked: cancelBooking(modelData.id)
                            }
                        }
                    }
                }

                // Заглушка, если пусто
                Item {
                    Layout.fillWidth: true
                    height: 100
                    visible: userBookings.length === 0

                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: "📅"
                            font.pixelSize: 40
                            anchors.horizontalCenter: parent.horizontalCenter
                            opacity: 0.5
                        }
                        Text {
                            text: "У вас пока нет активных бронирований"
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontSizeMedium
                        }
                    }
                }
            }

            // 3. МЕНЮ ДЕЙСТВИЙ (Внизу)
            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: Theme.spacingMedium
                Layout.topMargin: Theme.spacingLarge
                spacing: Theme.spacingMedium

                // Админские кнопки
                ColumnLayout {
                    visible: userRole === "admin" || userRole === "superadmin"
                    Layout.fillWidth: true
                    spacing: Theme.spacingMedium

                    Text {
                        text: "Управление"
                        font.bold: true
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSizeSmall
                    }

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

                // Общие кнопки
                Text {
                    text: "Приложение"
                    font.bold: true
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontSizeSmall
                    Layout.topMargin: 8
                }

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

                    contentItem: Text {
                        text: parent.text
                        color: Theme.error
                        font.pixelSize: Theme.fontSizeMedium
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        BackendApi.logout() // Вызываем логаут в C++ (если есть метод, или просто чистим стек)
                        var stack = profilePage.StackView.view
                        stack.clear()
                        stack.push("../LoginScreen.qml")
                    }
                }
            }
        }
    }
}
