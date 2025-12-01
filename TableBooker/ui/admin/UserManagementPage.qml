import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import com.tablebooker.api 1.0

Page {
    id: userMgmtPage
    title: "Управление правами"

    property var usersList: []

    function loadUsers() {
        usersList = BackendApi.getAllUsers()
    }

    Component.onCompleted: loadUsers()

    header: ToolBar {
        ToolButton { text: "<- Назад"; onClicked: userMgmtPage.StackView.view.pop() }
        Label { text: "Пользователи"; anchors.centerIn: parent }
    }

    ListView {
        anchors.fill: parent
        model: usersList
        clip: true

        delegate: ItemDelegate {
            width: parent.width

            contentItem: RowLayout {
                spacing: 10

                // Иконка
                Text { text: modelData.role === "admin" ? "😎" : "🙂"; font.pixelSize: 24 }

                // Инфо
                ColumnLayout {
                    Layout.fillWidth: true
                    Label {
                        text: modelData.nickname + " (@" + modelData.username + ")"
                        font.bold: true
                    }
                    Label {
                        text: modelData.phone
                        color: "gray"
                        font.pixelSize: 12
                    }
                }

                // Переключатель прав
                Switch {
                    checked: modelData.role === "admin" || modelData.role === "superadmin"
                    // Блокируем свитч, если это супер-админ (хотя мы их фильтруем)
                    enabled: modelData.role !== "superadmin"

                    onToggled: {
                        var success = BackendApi.changeUserRole(modelData.id, checked)
                        if (success) {
                            console.log("Роль изменена")
                            // Обновляем иконку локально (хак для UI)
                            modelData.role = checked ? "admin" : "user"
                        } else {
                            checked = !checked // Возвращаем обратно при ошибке
                        }
                    }
                }
            }
        }

        Text {
            visible: usersList.length === 0
            text: "Нет других пользователей"
            anchors.centerIn: parent
            color: "gray"
        }
    }
}
