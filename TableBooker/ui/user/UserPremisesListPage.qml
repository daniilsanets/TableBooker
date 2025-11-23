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
    property var premisesList: []

    function loadData() {
        premisesList = BackendApi.getAllPremises()
    }

    Component.onCompleted: loadData()

    header: ToolBar {
        background: Rectangle {
            color: Theme.surface
        }
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16

            Text {
                text: "🍽️"
                font.pixelSize: 24
            }
            
            Label {
                text: "Выберите заведение"
                font.bold: true
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.textPrimary
                Layout.fillWidth: true
            }

            ToolButton {
                Text {
                    text: Theme.iconInfo
                    font.pixelSize: 24
                    color: Theme.textSecondary
                    anchors.centerIn: parent
                }
                onClicked: {
                    userPremisesPage.StackView.view.push("../AboutPage.qml")
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Заголовок секции
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacingMedium
            Layout.leftMargin: Theme.spacingMedium
            Layout.rightMargin: Theme.spacingMedium
            height: 40
            color: "transparent"
            
            Text {
                text: "Где хотите поесть?"
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                color: Theme.textPrimary
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Список заведений
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: premisesList
            spacing: Theme.spacingMedium
            
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
