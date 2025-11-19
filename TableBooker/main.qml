import QtQuick
import QtQuick.Controls // <--- Нужно для StackView и Controls
import "ui"

Window {
    width: 360
    height: 640
    visible: true
    title: qsTr("TableBooker")

    StackView {
        id: stackView
        anchors.fill: parent

        initialItem: LoginScreen {}
    }
}
