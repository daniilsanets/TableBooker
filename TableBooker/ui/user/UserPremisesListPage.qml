import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import com.tablebooker.api 1.0
import "../components"
import "../Theme.js" as Theme

Page {
    id: userPremisesPage
    title: "Куда пойдем?"

    background: Rectangle {
        color: Theme.background
    }

    // --- ЛОГИКА ДАННЫХ ---
    property var allPremises: []
    property var filteredPremises: []
    property string searchText: ""
    property int sortMode: 0
    property bool isAdmin: BackendApi.currentUserRole === "admin"

    function loadData() {
        allPremises = BackendApi.getAllPremises()
        applyFilters()
    }

    function applyFilters() {
        var filtered = []
        for (var i = 0; i < allPremises.length; i++) {
            var premise = allPremises[i]
            if (searchText === "" || premise.name.toLowerCase().indexOf(searchText.toLowerCase()) !== -1) {
                filtered.push(premise)
            }
        }
        filtered.sort(function(a, b) {
            return sortMode === 0 ? a.name.localeCompare(b.name) : b.name.localeCompare(a.name)
        })
        filteredPremises = filtered
    }

    Component.onCompleted: loadData()

    // --- ВЕРХНЯЯ ПАНЕЛЬ (ОБНОВЛЕННАЯ) ---
    header: ToolBar {
        background: Rectangle { color: Theme.background }
        height: 60

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacingMedium
            anchors.rightMargin: Theme.spacingMedium

            // 1. СЛЕВА: Пустой слот (для балансировки заголовка)
            Item {
                width: 40
                height: 40
            }

            // 2. ЦЕНТР: Заголовок
            Column {
                Layout.fillWidth: true
                spacing: 0
                Label {
                    text: "TableBooker"
                    font.pixelSize: 12
                    color: Theme.textSecondary
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Label {
                    text: "Выбор заведения"
                    font.bold: true
                    font.pixelSize: Theme.fontSizeLarge
                    color: Theme.textPrimary
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            // 3. СПРАВА: Кнопка профиля
            Rectangle {
                width: 40
                height: 40
                radius: 20
                color: Theme.surface
                border.color: Theme.divider
                border.width: 1

                // Тень для кнопки профиля
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: "#20000000"
                    shadowBlur: 4
                    shadowVerticalOffset: 1
                }

                Text {
                    text: Theme.iconPerson
                    anchors.centerIn: parent
                    font.pixelSize: 20
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: userPremisesPage.StackView.view.push("ProfilePage.qml")
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // --- БЛОК ПОИСКА ---
        Rectangle {
            Layout.fillWidth: true
            height: 80
            color: "transparent"
            z: 10

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Theme.spacingMedium
                height: 50
                radius: 25
                color: Theme.surface

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: "#20000000"
                    shadowBlur: 10
                    shadowVerticalOffset: 4
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 10

                    Text {
                        text: Theme.iconSearch
                        font.pixelSize: 20
                        color: Theme.primary
                    }

                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: "Название ресторана..."
                        background: Item {}
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.textPrimary
                        onTextChanged: {
                            userPremisesPage.searchText = text
                            userPremisesPage.applyFilters()
                        }
                    }

                    Text {
                        text: "✕"
                        visible: searchField.text.length > 0
                        color: Theme.textSecondary
                        font.pixelSize: 18
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                searchField.text = ""
                                userPremisesPage.searchText = ""
                            }
                        }
                    }
                }
            }
        }

        // --- СПИСОК ЗАВЕДЕНИЙ ---
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: filteredPremises
            spacing: 20

            header: Item { height: 10 }
            footer: Item { height: 20 }

            delegate: Item {
                width: listView.width
                height: 240

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingMedium
                    anchors.rightMargin: Theme.spacingMedium
                    radius: Theme.radiusLarge
                    color: Theme.surface

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: "#15000000"
                        shadowBlur: 12
                        shadowVerticalOffset: 2
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        // Обложка
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 140
                            radius: Theme.radiusLarge

                            // Скрываем скругление снизу
                            Rectangle {
                                anchors.bottom: parent.bottom
                                height: 10
                                width: parent.width
                                color: parent.color
                            }

                            gradient: Gradient {
                                GradientStop { position: 0.0; color: getGradientColor(modelData.id, 0) }
                                GradientStop { position: 1.0; color: getGradientColor(modelData.id, 1) }
                            }

                            Text {
                                text: Theme.iconRestaurant
                                font.pixelSize: 48
                                anchors.centerIn: parent
                                color: "#FFFFFF"
                                style: Text.Raised
                                styleColor: "#20000000"
                            }

                            Rectangle {
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 12
                                width: 70
                                height: 24
                                radius: 12
                                color: "#CCFFFFFF"

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text { text: "●"; color: Theme.success; font.pixelSize: 10 }
                                    Text { text: "Open"; color: Theme.success; font.bold: true; font.pixelSize: 10 }
                                }
                            }
                        }

                        // Информация
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    Text {
                                        text: modelData.name
                                        font.bold: true
                                        font.pixelSize: Theme.fontSizeLarge
                                        color: Theme.textPrimary
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: "Европейская кухня • $$"
                                        color: Theme.textSecondary
                                        font.pixelSize: Theme.fontSizeSmall
                                    }
                                }

                                Button {
                                    text: "Забронировать"
                                    font.bold: true
                                    font.pixelSize: 13

                                    background: Rectangle {
                                        color: parent.pressed ? Theme.primaryDark : Theme.surface
                                        radius: 8
                                        border.color: Theme.primary
                                        border.width: 1
                                    }
                                    contentItem: Text {
                                        text: parent.text
                                        color: parent.pressed ? "white" : Theme.primary
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    onClicked: openBooking(modelData)
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        onClicked: openBooking(modelData)
                    }
                }
            }

            Text {
                visible: listView.count === 0
                text: "Ничего не найдено 😔"
                anchors.centerIn: parent
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSizeLarge
            }
        }
    }

    function openBooking(data) {
        userPremisesPage.StackView.view.push("BookingHallPage.qml", {
            "premisesId": data.id,
            "premisesName": data.name
        })
    }

    function getGradientColor(id, stop) {
        var colors = [
            ["#FF9A9E", "#FECFEF"],
            ["#a18cd1", "#fbc2eb"],
            ["#84fab0", "#8fd3f4"],
            ["#fccb90", "#d57eeb"],
            ["#e0c3fc", "#8ec5fc"]
        ];
        var index = id % colors.length;
        return colors[index][stop];
    }
}
