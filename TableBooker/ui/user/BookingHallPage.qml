import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import com.tablebooker.api 1.0
import "../admin"
import "../components"
import "../Theme.js" as Theme

Page {
    id: bookingPage
    title: premisesName
    
    background: Rectangle {
        color: Theme.background
    }

    property int premisesId: 0
    property string premisesName: ""

    // Модель столов
    ListModel { id: tablesModel }
    BookingPopup {id: bookingPopup}

    function loadTables() {
        tablesModel.clear()
        var tables = BackendApi.getTablesForPremises(premisesId)

        for(var i=0; i<tables.length; i++) {
            var t = tables[i]
            tablesModel.append({
                "dbId": t.id,
                "name": t.name,
                "x": t.x,
                "y": t.y,
                "width": t.width,
                "height": t.height,
                "shapeType": t.shapeType,
                "type": t.type || "table",
                "color": t.color || "#81C784"
            })
        }
    }

    Component.onCompleted: loadTables()

    header: ToolBar {
        background: Rectangle {
            color: Theme.surface
        }
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            
            ToolButton {
                Text {
                    text: Theme.iconBack
                    font.pixelSize: 24
                    color: Theme.textPrimary
                    anchors.centerIn: parent
                }
                onClicked: bookingPage.StackView.view.pop()
            }
            
            Label {
                text: bookingPage.title
                font.bold: true
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.textPrimary
                Layout.fillWidth: true
            }
        }
    }

    ZoomableHall {
        id: hallView
        anchors.fill: parent
        anchors.bottomMargin: hintBar.visible ? hintBar.height + Theme.spacingMedium : 0
        tablesModel: tablesModel
        editMode: false
        
        onTableClicked: (idx, dbId) => {
            var table = tablesModel.get(idx)
            console.log("Хочу забронировать стол:", table.name)
            
            bookingPopup.tableId = dbId
            bookingPopup.tableName = table.name
            bookingPopup.open()
        }
        
        // Центрируем план помещения при загрузке
        Connections {
            target: tablesModel
            function onCountChanged() {
                if (tablesModel.count > 0) {
                    Qt.callLater(function() {
                        // Находим центр всех столов
                        var minX = 999999, minY = 999999, maxX = 0, maxY = 0
                        for (var i = 0; i < tablesModel.count; i++) {
                            var t = tablesModel.get(i)
                            minX = Math.min(minX, t.x)
                            minY = Math.min(minY, t.y)
                            maxX = Math.max(maxX, t.x + t.width)
                            maxY = Math.max(maxY, t.y + t.height)
                        }
                        var centerX = (minX + maxX) / 2
                        var centerY = (minY + maxY) / 2
                        
                        // Используем функцию ensureItemVisible или напрямую обращаемся к flickable
                        // Прокручиваем к центру через функцию компонента
                        if (hallView.ensureItemVisible) {
                            // Если есть функция, используем её для первого элемента
                            hallView.ensureItemVisible(0)
                        }
                    })
                }
            }
        }
        
        Component.onCompleted: {
            // Центрируем после загрузки данных
            Qt.callLater(function() {
                if (tablesModel.count > 0) {
                    // Используем стандартную позицию центра холла
                    var flick = hallView.children[0]
                    if (flick && flick.contentWidth > 0) {
                        flick.contentX = (flick.contentWidth - flick.width) / 2
                        flick.contentY = (flick.contentHeight - flick.height) / 2
                    }
                }
            })
        }
    }
    
    // Профессиональная подсказка
    Rectangle {
        id: hintBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.spacingMedium
        height: 48
        color: Theme.primary
        radius: Theme.radiusMedium
        visible: tablesModel.count > 0
        z: 100
        
        // Тень
        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            z: -1
            color: "#0D000000"
            radius: parent.radius + 2
            opacity: 0.2
        }
        
        Row {
            anchors.centerIn: parent
            spacing: Theme.spacingSmall
            
            Text {
                text: Theme.iconTable
                font.pixelSize: 20
                color: "white"
                anchors.verticalCenter: parent.verticalCenter
            }
            
            Text {
                text: "Нажмите на стол для бронирования"
                color: "white"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
