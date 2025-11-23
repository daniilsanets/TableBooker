import QtQuick 2.15
import QtQuick.Controls 2.15
import "../Theme.js" as Theme

Rectangle {
    id: root
    
    property alias content: contentContainer.children
    property bool clickable: false
    
    color: Theme.surface
    radius: Theme.radiusMedium
    border.color: Theme.divider
    border.width: 1
    
    // Профессиональная многослойная тень
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
    
    // Контейнер для контента
    Item {
        id: contentContainer
        anchors.fill: parent
        anchors.margins: Theme.spacingMedium
    }
    
    // Эффект нажатия
    MouseArea {
        anchors.fill: parent
        enabled: root.clickable
        onClicked: root.clicked()
        cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
    
    signal clicked()
    
    Behavior on scale {
        NumberAnimation { duration: 150 }
    }
    
    states: [
        State {
            name: "pressed"
            when: root.clickable && mouseArea.pressed
            PropertyChanges { target: root; scale: 0.98 }
        }
    ]
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.clickable
    }
}

