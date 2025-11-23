import QtQuick 2.15
import QtQuick.Controls 2.15
import "../Theme.js" as Theme

Button {
    id: root
    
    property bool isPrimary: true
    property bool isFlat: false
    property string iconText: ""
    
    background: Rectangle {
        color: {
            if (root.isFlat) return "transparent"
            return root.isPrimary ? Theme.primary : Theme.surface
        }
        radius: Theme.radiusMedium
        border.color: root.isPrimary ? "transparent" : Theme.divider
        border.width: root.isPrimary ? 0 : 1
        
        opacity: root.pressed ? 0.8 : 1.0
        
        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }
    }
    
    contentItem: Row {
        spacing: Theme.spacingSmall
        anchors.centerIn: parent
        
        Text {
            text: root.iconText
            font.pixelSize: 20
            color: root.isPrimary ? "white" : Theme.textPrimary
            visible: root.iconText !== ""
            anchors.verticalCenter: parent.verticalCenter
        }
        
        Text {
            text: root.text
            color: root.isPrimary ? "white" : Theme.textPrimary
            font.pixelSize: Theme.fontSizeMedium
            font.bold: root.isPrimary
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    
    height: 48
    font.pixelSize: Theme.fontSizeMedium
}

