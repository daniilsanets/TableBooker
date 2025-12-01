import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import com.tablebooker.api 1.0

Page {
    id: profilePage
    title: "Мой профиль"

    property string userRole: BackendApi.currentUserRole
    property string userName: "Загрузка..." // Можно подтянуть из BackendApi, если добавить туда геттер

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width * 0.85
        spacing: 20

        // Аватарка (заглушка)
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 100; height: 100
            radius: 50
            color: "lightgray"
            Text {
                anchors.centerIn: parent
                text: "👤"
                font.pixelSize: 40
            }
        }

        Label {
            text: "Ваш ID: " + BackendApi.currentUserId
            Layout.alignment: Qt.AlignHCenter
            color: "gray"
        }

        Label {
            text: "Роль: " + (userRole === "superadmin" ? "👑 Создатель" : (userRole === "admin" ? "😎 Администратор" : "🙂 Гость"))
            Layout.alignment: Qt.AlignHCenter
            font.bold: true
            color: userRole === "superadmin" ? "gold" : "black"
        }

        // --- Блок кнопок ---

        // Кнопка ТОЛЬКО для Супер-Админа
        Button {
            text: "👥 Управление пользователями"
            Layout.fillWidth: true
            visible: userRole === "superadmin"
            highlighted: true
            onClicked: profilePage.StackView.view.push("../admin/UserManagementPage.qml")
        }

        // Кнопка для Админа (управление заведениями)
        Button {
            text: "🏢 Мои заведения"
            Layout.fillWidth: true
            visible: userRole === "admin" || userRole === "superadmin"
            onClicked: profilePage.StackView.view.push("../admin/AdminDashboardPage.qml")
        }

        Button {
            text: "О приложении"
            Layout.fillWidth: true
            onClicked: profilePage.StackView.view.push("../AboutPage.qml")
        }

        // Разделитель
        Item { Layout.fillHeight: true; height: 20 }

        Button {
            text: "Выйти из аккаунта"
            Layout.fillWidth: true
            flat: true
            palette.buttonText: "red"
            onClicked: {
                var stack = profilePage.StackView.view
                stack.clear()
                stack.push("../LoginScreen.qml")
            }
        }
    }
}
