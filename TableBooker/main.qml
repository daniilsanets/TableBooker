import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import "ui"

ApplicationWindow {
    width: 360
    height: 640
    visible: true
    title: qsTr("TableBooker")
    
    Material.theme: Material.Light
    Material.accent: Material.Blue

    StackView {
        id: stackView
        anchors.fill: parent

        initialItem: LoginScreen {}
    }
}
