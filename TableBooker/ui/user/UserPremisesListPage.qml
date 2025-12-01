import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import com.tablebooker.api 1.0
import "../components"
import "../Theme.js" as Theme

Page {
    id: userPremisesPage
    title: "Заведения"
    
    background: Rectangle {
        color: Theme.background
    }

    // Модель данных
    property var allPremises: []
    property var filteredPremises: []
    property string searchText: ""
    property int sortMode: 0 // 0 - по имени, 1 - по имени (обратно)

    property bool isAdmin: BackendApi.currentUserRole === "admin"

    function loadData() {
        allPremises = BackendApi.getAllPremises()
        applyFilters()
    }
    
    function applyFilters() {
        var filtered = []
        
        // Поиск
        for (var i = 0; i < allPremises.length; i++) {
            var premise = allPremises[i]
            if (searchText === "" || premise.name.toLowerCase().indexOf(searchText.toLowerCase()) !== -1) {
                filtered.push(premise)
            }
        }
        
        // Сортировка
        filtered.sort(function(a, b) {
            if (sortMode === 0) {
                return a.name.localeCompare(b.name)
            } else {
                return b.name.localeCompare(a.name)
            }
        })
        
        filteredPremises = filtered
    }

    Component.onCompleted: loadData()

    header: ToolBar {
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10; anchors.rightMargin: 10

            // Кнопка Профиля слева
            ToolButton {
                text: "👤"
                font.pixelSize: 18
                onClicked: userPremisesPage.StackView.view.push("ProfilePage.qml")
            }

            Label {
                text: userPremisesPage.title
                font.bold: true
                Layout.fillWidth: true
                horizontalAlignment: Qt.AlignHCenter
            }

            // Справа пусто или кнопка "О программе" (можно убрать, т.к. она теперь в профиле)
            Item { width: 40 }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Поиск и сортировка
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 16
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.bottomMargin: 8
            height: 100
            color: "transparent"
            
            Column {
                anchors.fill: parent
                spacing: 8
                
                // Поле поиска
                Rectangle {
                    width: parent.width
                    height: 48
                    color: Theme.surface
                    radius: Theme.radiusSmall
                    border.color: searchField.activeFocus ? Theme.primary : Theme.divider
                    border.width: searchField.activeFocus ? 2 : 1
                    
                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 12
                        
                        Text {
                            text: Theme.iconSearch
                            font.pixelSize: 20
                            color: Theme.textSecondary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        TextField {
                            id: searchField
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 40
                            placeholderText: "Поиск заведений..."
                            background: Item {}
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.textPrimary
                            onTextChanged: {
                                userPremisesPage.searchText = text
                                userPremisesPage.applyFilters()
                            }
                        }
                    }
                }
                
                // Кнопка сортировки
                Row {
                    spacing: 8
                    
                    Button {
                        text: sortMode === 0 ? "А-Я" : "Я-А"
                        height: 32
                        width: 80
                        background: Rectangle {
                            color: parent.pressed ? Theme.surfaceDark : Theme.surface
                            radius: Theme.radiusSmall
                            border.color: Theme.divider
                            border.width: 1
                        }
                        contentItem: Text {
                            text: parent.text
                            color: Theme.textPrimary
                            font.pixelSize: Theme.fontSizeSmall
                            horizontalAlignment: Text.AlignHCenter
                        }
                        onClicked: {
                            userPremisesPage.sortMode = userPremisesPage.sortMode === 0 ? 1 : 0
                            userPremisesPage.applyFilters()
                        }
                    }
                    
                    Text {
                        text: "Найдено: " + filteredPremises.length
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.textSecondary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        // Список заведений
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: filteredPremises
            spacing: 12
            
            delegate: Rectangle {
                width: listView.width - Theme.spacingMedium * 2
                height: 140
                x: Theme.spacingMedium
                color: Theme.surface
                radius: Theme.radiusMedium
                border.color: Theme.divider
                border.width: 1
                
                // Профессиональная тень
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -3
                    z: -1
                    color: "#0D000000"
                    radius: parent.radius + 3
                    opacity: 0.15
                }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -1
                    z: -1
                    color: "#1A000000"
                    radius: parent.radius + 1
                    opacity: 0.08
                }
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingMedium
                    spacing: Theme.spacingMedium
                    
                    // Иконка заведения
                    Rectangle {
                        Layout.preferredWidth: 80
                        Layout.preferredHeight: 80
                        radius: Theme.radiusMedium
                        color: Theme.primary
                        opacity: 0.9
                        
                        Text {
                            text: Theme.iconRestaurant
                            font.pixelSize: 36
                            anchors.centerIn: parent
                        }
                        
                        // Градиент для глубины
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#00000000" }
                                GradientStop { position: 1.0; color: "#20000000" }
                            }
                        }
                    }
                    
                    // Информация
                    Column {
                        Layout.fillWidth: true
                        spacing: Theme.spacingSmall
                        
                        Text {
                            text: modelData.name
                            font.pixelSize: Theme.fontSizeLarge
                            font.bold: true
                            font.weight: Font.DemiBold
                            color: Theme.textPrimary
                        }
                        
                        Text {
                            text: "Нажмите для бронирования"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.textSecondary
                        }
                    }
                    
                    // Стрелка
                    Text {
                        text: "→"
                        font.pixelSize: 20
                        color: Theme.primary
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        console.log("Клиент выбрал кафе ID:", modelData.id)
                        userPremisesPage.StackView.view.push("BookingHallPage.qml", {
                            "premisesId": modelData.id,
                            "premisesName": modelData.name
                        })
                    }
                }
            }

            // Пустое состояние
            Text {
                visible: listView.count === 0
                text: "Нет доступных заведений"
                anchors.centerIn: parent
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSizeMedium
            }
        }
    }
}
