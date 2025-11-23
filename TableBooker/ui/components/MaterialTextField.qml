import QtQuick 2.15
import QtQuick.Controls 2.15
import "../Theme.js" as Theme

TextField {
    id: root
    
    property string iconText: ""
    property bool hasError: false
    
    background: Rectangle {
        color: Theme.surface
        border.color: root.hasError ? Theme.error : (root.activeFocus ? Theme.primary : Theme.divider)
        border.width: root.activeFocus ? 2 : 1
        radius: Theme.radiusSmall
        
        Behavior on border.color {
            ColorAnimation { duration: 200 }
        }
    }
    
    leftPadding: root.iconText !== "" ? 40 : 16
    rightPadding: 16
    topPadding: 12
    bottomPadding: 12
    
    font.pixelSize: Theme.fontSizeMedium
    color: Theme.textPrimary
    
    // Иконка слева
    Text {
        id: icon
        text: root.iconText
        font.pixelSize: 20
        color: root.hasError ? Theme.error : Theme.textSecondary
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        visible: root.iconText !== ""
    }
    
    // Placeholder стиль
    placeholderTextColor: Theme.textHint
}

