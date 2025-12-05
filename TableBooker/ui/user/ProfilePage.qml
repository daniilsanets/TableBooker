import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import com.tablebooker.api 1.0
import "../components"
import "../Theme.js" as Theme

Page {
    id: profilePage
    title: "Профиль"

    background: Rectangle {
        color: Theme.background
    }

    // Данные из API
    property string userRole: BackendApi.currentUserRole
    property int userId: BackendApi.currentUserId
    property var bookingsList: []

    function loadBookings() {
        bookingsList = BackendApi.getUserBookings()
    }

    function cancelBooking(id) {
        var success = BackendApi.cancelBooking(id)
        if (success) loadBookings()
    }

    // Убираем стандартный хедер
    header: Item { height: 0 }

    // --- ОСНОВНОЙ КОНТЕНТ ---
    Flickable {
        id: flickableArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: bottomPanel.top // Контент заканчивается над кнопкой выхода
        contentHeight: contentColumn.height + 40
        clip: true

        // Хедер с градиентом
        Rectangle {
            width: parent.width
            height: 220
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.primaryDark }
                GradientStop { position: 1.0; color: Theme.primary }
            }
            // Декор
            Rectangle { width: 200; height: 200; radius: 100; color: "white"; opacity: 0.05; x: -50; y: -50 }
            Rectangle { width: 150; height: 150; radius: 75; color: "white"; opacity: 0.05; x: parent.width - 80; y: 40 }

            // Кнопка назад
            ToolButton {
                anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 10
                contentItem: Text { text: Theme.iconBack; color: "white"; font.pixelSize: 24 }
                background: Item {}
                onClicked: profilePage.StackView.view.pop()
            }
            // Заголовок
            Text {
                text: "Мой профиль"
                color: "white"; font.bold: true; font.pixelSize: Theme.fontSizeLarge
                anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter; anchors.topMargin: 15
            }
        }

        ColumnLayout {
            id: contentColumn
            width: parent.width
            spacing: 0

            // 1. АВАТАР
            Item {
                Layout.fillWidth: true; Layout.preferredHeight: 140; Layout.topMargin: 80
                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    // Круг аватара
                    Rectangle {
                        width: 100; height: 100; radius: 50; color: Theme.surface
                        border.color: Theme.surface; border.width: 4
                        anchors.horizontalCenter: parent.horizontalCenter
                        layer.enabled: true
                        layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#40000000"; shadowBlur: 16; shadowVerticalOffset: 4 }

                        Text { text: Theme.iconPerson; font.pixelSize: 50; anchors.centerIn: parent; color: Theme.primary }
                    }

                    // Текст под аватаром
                    Column {
                        spacing: 4
                        anchors.horizontalCenter: parent.horizontalCenter
                        Text {
                            text: "Пользователь #" + userId
                            font.bold: true; font.pixelSize: Theme.fontSizeXLarge; color: Theme.textPrimary
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        // Роль
                        Rectangle {
                            height: 24
                            width: roleText.implicitWidth + 24
                            radius: 12
                            color: userRole === "superadmin" ? Theme.primary : (userRole === "admin" ? Theme.primaryLight : "#E0E0E0")
                            anchors.horizontalCenter: parent.horizontalCenter

                            Text {
                                id: roleText
                                text: userRole === "superadmin" ? "Создатель" : (userRole === "admin" ? "Администратор" : "Гость")
                                color: userRole === "superadmin" ? "white" : (userRole === "admin" ? "white" : Theme.textSecondary)
                                font.pixelSize: Theme.fontSizeSmall; font.bold: true
                                anchors.centerIn: parent
                            }
                        }
                    }
                }
            }

            // 2. МЕНЮ (Текст теперь будет виден!)
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: Math.min(parent.width * 0.9, 400)
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 30
                spacing: Theme.spacingMedium

                Rectangle {
                    Layout.fillWidth: true
                    height: menuColumn.implicitHeight + 20
                    color: Theme.surface
                    radius: Theme.radiusLarge
                    layer.enabled: true
                    layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#10000000"; shadowBlur: 20; shadowVerticalOffset: 5 }

                    ColumnLayout {
                        id: menuColumn
                        anchors.fill: parent; anchors.margins: 10; spacing: 0

                        // Пункты меню
                        ProfileMenuItem {
                            icon: Theme.iconCalendar
                            text: "Мои бронирования"
                            onClicked: { loadBookings(); bookingsDialog.open() }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider; Layout.leftMargin: 50 }

                        ProfileMenuItem {
                            visible: userRole === "superadmin"
                            icon: Theme.iconPerson
                            text: "Управление пользователями"
                            onClicked: profilePage.StackView.view.push("../admin/UserManagementPage.qml")
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider; visible: userRole === "superadmin"; Layout.leftMargin: 50 }

                        ProfileMenuItem {
                            visible: userRole === "admin" || userRole === "superadmin"
                            icon: Theme.iconRestaurant
                            text: "Управление заведениями"
                            onClicked: profilePage.StackView.view.push("../admin/AdminDashboardPage.qml")
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider; visible: userRole === "admin" || userRole === "superadmin"; Layout.leftMargin: 50 }

                        ProfileMenuItem {
                            icon: Theme.iconInfo
                            text: "О приложении"
                            onClicked: profilePage.StackView.view.push("../AboutPage.qml")
                        }
                    }
                }

                Text {
                    text: "v1.0.0"
                    color: Theme.textHint
                    font.pixelSize: Theme.fontSizeSmall
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 10
                }
            }
        }
    }

    // --- НИЖНЯЯ ПАНЕЛЬ (Кнопка Выйти) ---
    Rectangle {
        id: bottomPanel
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 80
        color: Theme.surface

        // Линия разделитель
        Rectangle {
            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
            height: 1; color: Theme.divider
        }

        Button {
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.8, 300)
            height: 48

            background: Rectangle {
                color: parent.pressed ? "#FFEBEE" : "transparent"
                radius: 24
                border.color: Theme.error
                border.width: 1
            }

            contentItem: Text {
                text: "Выйти"
                color: Theme.error
                font.bold: true
                font.pixelSize: Theme.fontSizeMedium
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            onClicked: {
                BackendApi.logout()
                profilePage.StackView.view.clear()
                profilePage.StackView.view.push("../LoginScreen.qml")
            }
        }
    }

    // --- ДИАЛОГ МОИ БРОНИРОВАНИЯ ---
    Dialog {
        id: bookingsDialog
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: Math.min(parent.width * 0.9, 400)
        height: Math.min(parent.height * 0.8, 500)
        modal: true

        background: Rectangle { color: Theme.surface; radius: Theme.radiusLarge }

        header: ColumnLayout {
            spacing: 0
            Rectangle {
                Layout.fillWidth: true; height: 60; color: "transparent"
                Text { text: "Мои бронирования"; font.bold: true; font.pixelSize: Theme.fontSizeLarge; color: Theme.textPrimary; anchors.centerIn: parent }
                ToolButton { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: "✕"; onClicked: bookingsDialog.close() }
            }
            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider }
        }

        contentItem: ListView {
            clip: true; model: bookingsList; spacing: 12

            Text {
                visible: bookingsList.length === 0
                text: "У вас пока нет активных броней"
                color: Theme.textSecondary
                anchors.centerIn: parent
                font.pixelSize: Theme.fontSizeMedium
            }

            delegate: Rectangle {
                width: parent ? parent.width : 0
                height: 90
                color: Theme.surface
                radius: Theme.radiusMedium
                border.color: Theme.divider
                border.width: 1

                RowLayout {
                    anchors.fill: parent; anchors.margins: 12; spacing: 12
                    Rectangle {
                        Layout.preferredWidth: 50; Layout.preferredHeight: 50; radius: 12; color: Theme.primaryLight; opacity: 0.2
                        Text { text: Theme.iconCalendar; font.pixelSize: 24; color: Theme.primary; anchors.centerIn: parent }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        Text { text: modelData.premisesName; font.bold: true; font.pixelSize: 15; color: Theme.textPrimary }
                        Text { text: "Стол: " + modelData.tableName; font.pixelSize: 13; color: Theme.textSecondary }
                        Text {
                            text: { var dt = modelData.startTime.split(" "); return dt[0] + " в " + dt[1].substring(0, 5) }
                            font.pixelSize: 13; color: Theme.primary; font.bold: true
                        }
                    }
                    Button {
                        Layout.preferredWidth: 40; Layout.preferredHeight: 40
                        background: Rectangle { color: parent.pressed ? "#FFEBEE" : "transparent"; radius: 20 }
                        contentItem: Text { text: Theme.iconDelete; color: Theme.error; font.pixelSize: 20; anchors.centerIn: parent }
                        onClicked: cancelBooking(modelData.id)
                    }
                }
            }
        }
    }

    // --- ИСПРАВЛЕННЫЙ КОМПОНЕНТ МЕНЮ ---
    component ProfileMenuItem : Rectangle {
        id: menuItemRoot // ВАЖНО: Добавил ID для корня компонента
        property string icon: ""
        property string text: ""
        signal clicked()

        Layout.fillWidth: true
        Layout.preferredHeight: 56
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: mouseArea.pressed ? Theme.surfaceDark : "transparent"
            radius: Theme.radiusSmall
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 15

            Rectangle {
                width: 36; height: 36; radius: 18; color: Theme.background
                Text { text: icon; anchors.centerIn: parent; font.pixelSize: 18; color: Theme.textSecondary }
            }

            // ТЕКСТ: Теперь ссылаемся через ID компонента (menuItemRoot.text)
            // parent.text НЕ РАБОТАЛ, так как parent здесь это RowLayout
            Text {
                text: menuItemRoot.text
                color: Theme.textPrimary
                font.pixelSize: Theme.fontSizeMedium
                Layout.fillWidth: true
            }

            Text {
                text: "›"
                color: Theme.textSecondary
                font.pixelSize: 24
                font.bold: true
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            onClicked: parent.clicked()
        }
    }
}
