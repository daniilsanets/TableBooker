import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import com.tablebooker.api 1.0 // Импорт нашего C++ API

Page {
    id: adminDashboard
    title: "Управление заведениями"

    property var premisesModel: []

    function refreshData() {
        var adminId = BackendApi.currentUserId
        console.log("Загрузка заведений для админа ID:", adminId)

        premisesModel = BackendApi.getPremisesForAdmin(adminId)
    }

    Component.onCompleted: refreshData()

    header:
        ToolBar
    {
        RowLayout { // Use RowLayout for better spacing
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10

            Label {
                text: "Админ-панель"
                font.bold: true
                Layout.fillWidth: true
            }

            ToolButton {
                text: "?"
                font.bold: true
                onClicked: {
                adminDashboard.StackView.view.push("../AboutPage.qml")
                }
            }
        }
    }

    Dialog
    {
        id: createDialog
        title: "Новое заведение"
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel

        ColumnLayout
        {
            spacing: 10
            TextField {
                id: newPremiseName
                placeholderText: "Название (например, Летняя терраса)"
                Layout.fillWidth: true
            }
            // Можно добавить поле для пути к картинке фона, если нужно
        }

        onAccepted:
        {
            if (newPremiseName.text === "") return

            // Собираем объект для отправки в C++
            var data = {
                "name": newPremiseName.text,
                "bgImagePath": "" // Пока пусто
            }

            var success = BackendApi.createPremises(data)
            if (success) {
                console.log("Заведение создано!")
                newPremiseName.text = "" // Очистить поле
                refreshData() // Обновить список
            } else {
                console.log("Ошибка создания")
            }
        }
    }

    // --- Основной интерфейс ---
    ColumnLayout
    {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // Список заведений
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            // Привязываем нашу модель
            model: premisesModel

            // Как выглядит один элемент списка
            delegate: ItemDelegate {
                width: listView.width
                text: modelData.name // modelData - это доступ к QVariantMap элемента

                icon.source: "qrc:/qt-project.org/imports/QtQuick/Controls.2/images/check.png" // Иконка-заглушка

                onClicked: {
                    console.log("Редактируем ID:", modelData.id)
                    // Переход в редактор с передачей параметров
                    // Важно: используем adminDashboard.StackView.view
                    adminDashboard.StackView.view.push("HallEditorPage.qml", {
                        "premisesId": modelData.id,
                        "premisesName": modelData.name
                    })
                }
            }

            // Если список пуст
            Text {
                anchors.centerIn: parent
                text: "Нет заведений. Создайте первое!"
                visible: listView.count === 0
                color: "gray"
            }
        }

        // Кнопка добавления
        Button {
            text: "+ Добавить заведение"
            Layout.fillWidth: true
            highlighted: true
            onClicked: createDialog.open()
        }

        Button
        {
            text: "Перейти к бронированию"
            Layout.fillWidth: true
            onClicked: adminDashboard.StackView.view.push("../user/UserPremisesListPage.qml")
        }

        Button {
            text: "Выйти"
            Layout.fillWidth: true
            flat: true
            onClicked: adminDashboard.StackView.view.pop()
        }
    }
}
