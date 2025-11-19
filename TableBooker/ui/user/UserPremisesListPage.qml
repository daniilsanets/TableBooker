import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import com.tablebooker.api 1.0

Page {
    id: userPremisesPage
    title: "Выберите заведение"

    // Модель данных
    property var premisesList: []

    function loadData() {
        // Запрашиваем ВСЕ заведения (метод уже есть в C++)
        premisesList = BackendApi.getAllPremises()
    }

    Component.onCompleted: loadData()

    header:
        ToolBar
        {
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10

                Label {
                    text: userPremisesPage.title
                    font.bold: true
                    Layout.fillWidth: true
                }

                ToolButton {
                    text: "?"
                    font.bold: true
                    onClicked: {
                         // Go up one folder (..) to find AboutPage
                        userPremisesPage.StackView.view.push("../AboutPage.qml")
                    }
                }
            }
        }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10

        Label {
            text: "Где хотите поесть?"
            font.pixelSize: 20
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: premisesList

            delegate: ItemDelegate {
                width: listView.width

                // modelData - это доступ к данным из QVariantList
                text: modelData.name

                // Иконка для красоты
                icon.source: "qrc:/qt-project.org/imports/QtQuick/Controls.2/images/arrow-indicator.png"

                onClicked: {
                    console.log("Клиент выбрал кафе ID:", modelData.id)

                    // Переход на схему зала (файл создадим следующим шагом)
                    // Обрати внимание: путь user/BookingHallPage.qml
                    userPremisesPage.StackView.view.push("BookingHallPage.qml", {
                        "premisesId": modelData.id,
                        "premisesName": modelData.name
                    })
                }
            }

            Text {
                visible: listView.count === 0
                text: "Нет доступных заведений"
                anchors.centerIn: parent
                color: "gray"
            }
        }

        Button {
            text: "Выйти"
            Layout.fillWidth: true
            flat: true
            onClicked: userPremisesPage.StackView.view.pop()
        }
    }
}
