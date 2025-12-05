import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import com.tablebooker.api 1.0
import "../components"
import "../Theme.js" as Theme

Page {
    id: userMgmtPage
    title: "Пользователи"

    background: Rectangle {
        color: Theme.background
    }

    property var allUsers: []
    property var filteredUsers: []
    property string searchText: ""

    // Функция загрузки данных с бэкенда
    function loadUsers() {
        allUsers = BackendApi.getAllUsers()
        applyFilters()
    }

    // Фильтрация
    function applyFilters() {
        if (searchText === "") {
            filteredUsers = allUsers
        } else {
            var lowerSearch = searchText.toLowerCase()
            var res = []
            for (var i = 0; i < allUsers.length; i++) {
                var u = allUsers[i]
                if (u.nickname.toLowerCase().indexOf(lowerSearch) !== -1 ||
                    u.username.toLowerCase().indexOf(lowerSearch) !== -1 ||
                    u.phone.indexOf(lowerSearch) !== -1) {
                    res.push(u)
                }
            }
            filteredUsers = res
        }
    }

    Component.onCompleted: loadUsers()

    header: Item { height: 0 }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // --- ШАПКА ---
        Rectangle {
            Layout.fillWidth: true
            height: 140
            z: 10

            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.primaryDark }
                GradientStop { position: 1.0; color: Theme.primary }
            }
            // Декор
            Rectangle { width: 150; height: 150; radius: 75; color: "white"; opacity: 0.05; x: -40; y: -40 }
            Rectangle { width: 100; height: 100; radius: 50; color: "white"; opacity: 0.05; x: parent.width - 50; y: 20 }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingMedium
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    ToolButton {
                        contentItem: Text { text: Theme.iconBack; color: "white"; font.pixelSize: 24 }
                        background: Item {}
                        onClicked: userMgmtPage.StackView.view.pop()
                    }
                    Text {
                        text: "Управление правами"
                        color: "white"
                        font.bold: true
                        font.pixelSize: Theme.fontSizeLarge
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Item { width: 40 }
                }

                // Поиск
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: 20
                    color: "white"
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 8
                        Text { text: Theme.iconSearch; color: Theme.textHint; font.pixelSize: 18 }
                        TextField {
                            id: searchField
                            Layout.fillWidth: true
                            placeholderText: "Поиск по имени, логину или телефону..."
                            background: Item {}
                            color: Theme.textPrimary
                            font.pixelSize: Theme.fontSizeMedium
                            onTextChanged: {
                                userMgmtPage.searchText = text
                                applyFilters()
                            }
                        }
                        Text {
                            text: "✕"
                            color: Theme.textSecondary
                            visible: searchField.text.length > 0
                            font.pixelSize: 16
                            MouseArea {
                                anchors.fill: parent
                                onClicked: { searchField.text = ""; userMgmtPage.searchText = ""; applyFilters() }
                            }
                        }
                    }
                }
            }
        }

        // --- СПИСОК ---
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: filteredUsers
            spacing: 12

            header: Item { height: 16 }
            footer: Item { height: 20 }

            Text {
                visible: listView.count === 0
                text: "Пользователи не найдены"
                anchors.centerIn: parent
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSizeMedium
            }

            delegate: Item {
                width: listView.width
                height: 90

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    color: Theme.surface
                    radius: Theme.radiusMedium

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true; shadowColor: "#10000000"
                        shadowBlur: 8; shadowVerticalOffset: 2
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 16

                        // Аватар
                        Rectangle {
                            Layout.preferredWidth: 50; Layout.preferredHeight: 50; radius: 25
                            color: modelData.role === "admin" ? Theme.primaryLight : "#EEEEEE"
                            Text {
                                text: modelData.nickname ? modelData.nickname.charAt(0).toUpperCase() : "?"
                                anchors.centerIn: parent
                                color: modelData.role === "admin" ? Theme.primary : Theme.textSecondary
                                font.bold: true; font.pixelSize: 24
                            }
                        }

                        // Инфо
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 2
                            RowLayout {
                                spacing: 6
                                Text { text: modelData.nickname; font.bold: true; font.pixelSize: 16; color: Theme.textPrimary }
                                Rectangle {
                                    visible: modelData.role === "admin"
                                    width: 50; height: 18; radius: 4; color: Theme.primary
                                    Text { text: "ADMIN"; color: "white"; font.bold: true; font.pixelSize: 10; anchors.centerIn: parent }
                                }
                            }
                            Text { text: "@" + modelData.username; color: Theme.textSecondary; font.pixelSize: 13 }
                            Text { text: modelData.phone; color: Theme.textHint; font.pixelSize: 12 }
                        }

                        // Переключатель (ИСПРАВЛЕННАЯ ЛОГИКА)
                        Column {
                            spacing: 4
                            Layout.alignment: Qt.AlignVCenter

                            Switch {
                                id: roleSwitch
                                checked: modelData.role === "admin"
                                enabled: modelData.role !== "superadmin"

                                onToggled: {
                                    // 1. Отправляем запрос
                                    var success = BackendApi.changeUserRole(modelData.id, checked)

                                    if (success) {
                                        // 2. Если успешно — просто обновляем весь список через функцию страницы
                                        // Это надежно обновит UI без "хаков" с моделью
                                        userMgmtPage.loadUsers()
                                    } else {
                                        // 3. Если ошибка — возвращаем переключатель назад
                                        checked = !checked
                                    }
                                }
                            }

                            Text {
                                text: roleSwitch.checked ? "Админ" : "Юзер"
                                font.pixelSize: 10
                                color: roleSwitch.checked ? Theme.primary : Theme.textHint
                                anchors.horizontalCenter: roleSwitch.horizontalCenter
                            }
                        }
                    }
                }
            }
        }
    }
}
