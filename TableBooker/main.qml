import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import "ui"

ApplicationWindow {
    id: window
    width: 360
    height: 640
    visible: true
    title: qsTr("TableBooker")

    Material.theme: Material.Light
    Material.accent: Material.Blue

    // --- ЛОГИКА КНОПКИ НАЗАД (ANDROID) ---

    // Таймер для двойного нажатия
    Timer {
        id: doubleBackTimer
        interval: 2000 // 2 секунды на второе нажатие
        repeat: false
    }

    // Перехват нажатий
    Item {
        focus: true // Важно: этот элемент должен иметь фокус, чтобы ловить нажатия
        anchors.fill: parent

        Keys.onReleased: (event) => {
            if (event.key === Qt.Key_Back) {
                event.accepted = true // Говорим системе, что мы сами обработали нажатие

                // 1. Если в стеке есть страницы (мы не на главной) -> идем назад
                if (stackView.depth > 1) {
                    stackView.pop()
                    return
                }

                // 2. Если мы на корневой странице (например, LoginScreen или Главная после входа, если стек очищен)
                if (doubleBackTimer.running) {
                    // Таймер еще тикает -> это второе нажатие -> выход
                    Qt.quit()
                } else {
                    // Первое нажатие -> запускаем таймер и показываем сообщение
                    doubleBackTimer.start()
                    toast.show("Нажмите еще раз для выхода")
                }
            }
        }

        StackView {
            id: stackView
            anchors.fill: parent
            initialItem: LoginScreen {}

            // Анимации переходов для красоты
            pushEnter: Transition {
                PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
                PropertyAnimation { property: "x"; from: stackView.width; to: 0; duration: 200; easing.type: Easing.OutCubic }
            }
            pushExit: Transition {
                PropertyAnimation { property: "opacity"; from: 1; to: 0; duration: 200 }
                PropertyAnimation { property: "x"; from: 0; to: -100; duration: 200; easing.type: Easing.OutCubic }
            }
            popEnter: Transition {
                PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
                PropertyAnimation { property: "x"; from: -100; to: 0; duration: 200; easing.type: Easing.OutCubic }
            }
            popExit: Transition {
                PropertyAnimation { property: "opacity"; from: 1; to: 0; duration: 200 }
                PropertyAnimation { property: "x"; from: 0; to: stackView.width; duration: 200; easing.type: Easing.OutCubic }
            }
        }
    }

    // --- КОМПОНЕНТ УВЕДОМЛЕНИЯ (TOAST) ---
    Rectangle {
        id: toast
        visible: false
        color: "#323232"
        radius: 20
        height: 40
        width: toastText.implicitWidth + 40
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 50
        z: 1000 // Поверх всего
        opacity: 0

        Text {
            id: toastText
            text: ""
            color: "white"
            anchors.centerIn: parent
            font.pixelSize: 14
        }

        // Анимация появления/исчезновения
        SequentialAnimation {
            id: toastAnim

            // Появление
            PropertyAction { target: toast; property: "visible"; value: true }
            NumberAnimation { target: toast; property: "opacity"; to: 1.0; duration: 200 }

            // Пауза
            PauseAnimation { duration: 2000 }

            // Исчезновение
            NumberAnimation { target: toast; property: "opacity"; to: 0.0; duration: 200 }
            PropertyAction { target: toast; property: "visible"; value: false }
        }

        function show(msg) {
            toastText.text = msg
            if (toastAnim.running) toastAnim.stop()
            toastAnim.start()
        }
    }
}
