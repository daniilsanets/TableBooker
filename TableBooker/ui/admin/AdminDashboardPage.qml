import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import com.tablebooker.api 1.0
import "../components"
import "../Theme.js" as Theme

Page {
    id: adminDashboard
    title: "Админ-панель"

    background: Rectangle {
        color: Theme.background
    }

    property var premisesModel: []

    function refreshData() {
        var adminId = BackendApi.currentUserId
        console.log("Загрузка заведений для админа ID:", adminId)
        premisesModel = BackendApi.getPremisesForAdmin(adminId)
    }

    Component.onCompleted: refreshData()

    // Hide standard header
    header: Item { height: 0 }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // --- HEADER ---
        Rectangle {
            Layout.fillWidth: true
            height: 160
            z: 10

            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.primaryDark }
                GradientStop { position: 1.0; color: Theme.primary }
            }

            // Decor
            Rectangle { width: 200; height: 200; radius: 100; color: "white"; opacity: 0.05; x: -50; y: -50 }
            Rectangle { width: 120; height: 120; radius: 60; color: "white"; opacity: 0.05; x: parent.width - 60; y: 30 }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingMedium
                spacing: 4

                // Top Bar
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "⚙️ Панель управления"
                        color: "white"
                        font.bold: true
                        font.pixelSize: 20
                        Layout.fillWidth: true
                    }

                    // Profile Button
                    Rectangle {
                        width: 40; height: 40; radius: 20
                        color: "#30FFFFFF"
                        border.color: "#50FFFFFF"; border.width: 1

                        Text { text: Theme.iconPerson; anchors.centerIn: parent; color: "white"; font.pixelSize: 20 }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: adminDashboard.StackView.view.push("../user/ProfilePage.qml")
                        }
                    }
                }

                // Stats / Welcome text
                Text {
                    text: "Управляйте заведениями и планировкой"
                    color: "#CCFFFFFF"
                    font.pixelSize: Theme.fontSizeSmall
                }

                Item { Layout.fillHeight: true }
            }
        }

        // --- CONTENT ---
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: contentCol.height + 100
            clip: true

            ColumnLayout {
                id: contentCol
                width: parent.width
                spacing: Theme.spacingMedium

                // 1. QUICK ACTIONS
                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: 16
                    spacing: 12

                    // Card: Add New
                    Rectangle {
                        Layout.fillWidth: true
                        height: 100
                        radius: Theme.radiusMedium
                        color: Theme.surface
                        border.color: Theme.divider; border.width: 1

                        layer.enabled: true
                        layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#10000000"; shadowBlur: 10; shadowVerticalOffset: 2 }

                        Column {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: Theme.iconAdd; font.pixelSize: 32; color: Theme.primary; anchors.horizontalCenter: parent.horizontalCenter }
                            Text { text: "Новое заведение"; font.bold: true; color: Theme.textPrimary; anchors.horizontalCenter: parent.horizontalCenter }
                        }
                        MouseArea { anchors.fill: parent; onClicked: createDialog.open() }
                    }

                    // Card: User View
                    Rectangle {
                        Layout.fillWidth: true
                        height: 100
                        radius: Theme.radiusMedium
                        color: Theme.surface
                        border.color: Theme.divider; border.width: 1

                        layer.enabled: true
                        layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#10000000"; shadowBlur: 10; shadowVerticalOffset: 2 }

                        Column {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { text: Theme.iconTable; font.pixelSize: 32; color: Theme.accent; anchors.horizontalCenter: parent.horizontalCenter }
                            Text { text: "Режим клиента"; font.bold: true; color: Theme.textPrimary; anchors.horizontalCenter: parent.horizontalCenter }
                        }
                        MouseArea { anchors.fill: parent; onClicked: adminDashboard.StackView.view.push("../user/UserPremisesListPage.qml") }
                    }
                }

                // 2. PREMISES LIST TITLE
                Text {
                    text: "Ваши заведения"
                    font.bold: true
                    font.pixelSize: Theme.fontSizeLarge
                    color: Theme.textPrimary
                    Layout.leftMargin: 16
                    Layout.topMargin: 10
                }

                // 3. LIST
                ListView {
                    id: listView
                    Layout.fillWidth: true
                    height: contentHeight
                    implicitHeight: count * 100 // Approximation
                    model: premisesModel
                    interactive: false // Scroll handled by parent Flickable

                    delegate: Item {
                        width: parent.width
                        height: 100

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 8
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            color: Theme.surface
                            radius: Theme.radiusMedium
                            border.color: Theme.divider
                            border.width: 1

                            layer.enabled: true
                            layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#0D000000"; shadowBlur: 8; shadowVerticalOffset: 2 }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 16

                                // Icon Box
                                Rectangle {
                                    Layout.preferredWidth: 50; Layout.preferredHeight: 50
                                    radius: 12
                                    color: Theme.primaryLight
                                    opacity: 0.2
                                    Text {
                                        text: Theme.iconRestaurant
                                        font.pixelSize: 24
                                        color: Theme.primary
                                        anchors.centerIn: parent
                                    }
                                }

                                // Info
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    Text {
                                        text: modelData.name
                                        font.bold: true
                                        font.pixelSize: 16
                                        color: Theme.textPrimary
                                    }
                                    Text {
                                        text: "Нажмите для настройки схемы зала"
                                        font.pixelSize: 12
                                        color: Theme.textSecondary
                                    }
                                }

                                // Arrow
                                Rectangle {
                                    width: 32; height: 32; radius: 16
                                    color: Theme.background
                                    Text { text: "✏️"; anchors.centerIn: parent; font.pixelSize: 14 }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    console.log("Редактируем ID:", modelData.id)
                                    adminDashboard.StackView.view.push("HallEditorPage.qml", {
                                        "premisesId": modelData.id,
                                        "premisesName": modelData.name
                                    })
                                }
                            }
                        }
                    }
                }

                // Empty State
                Column {
                    visible: premisesModel.length === 0
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 40
                    spacing: 10

                    Text { text: "📂"; font.pixelSize: 48; anchors.horizontalCenter: parent.horizontalCenter }
                    Text {
                        text: "У вас пока нет заведений"
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSizeMedium
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }

    // --- DIALOG (CREATE) ---
    Dialog {
        id: createDialog
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.9, 360)
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        focus: true

        background: Rectangle {
            color: Theme.surface
            radius: Theme.radiusLarge
            Rectangle { z: -1; anchors.fill: parent; anchors.margins: -4; color: "#20000000"; radius: 20 }
        }

        contentItem: ColumnLayout {
            spacing: 20

            Column {
                Layout.fillWidth: true
                spacing: 8
                Text { text: "✨ Новое заведение"; font.bold: true; font.pixelSize: 20; color: Theme.textPrimary }
                Text { text: "Введите название ресторана или кафе"; color: Theme.textSecondary; font.pixelSize: 14; wrapMode: Text.WordWrap; width: parent.width }
            }

            TextField {
                id: newPremiseName
                Layout.fillWidth: true
                placeholderText: "Например: Lounge Bar"
                font.pixelSize: 16
                color: Theme.textPrimary
                background: Rectangle {
                    color: Theme.surfaceDark; radius: 8
                    border.color: parent.activeFocus ? Theme.primary : "transparent"; border.width: 2
                }
                Component.onCompleted: createDialog.opened.connect(() => { forceActiveFocus() })
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Button {
                    text: "Отмена"
                    Layout.fillWidth: true
                    flat: true
                    contentItem: Text { text: parent.text; color: Theme.textSecondary; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: "transparent" }
                    onClicked: createDialog.close()
                }

                Button {
                    text: "Создать"
                    Layout.fillWidth: true
                    enabled: newPremiseName.text.length > 0
                    background: Rectangle { color: parent.enabled ? Theme.primary : Theme.divider; radius: 8 }
                    contentItem: Text { text: parent.text; color: "white"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    onClicked: {
                        if (newPremiseName.text === "") return
                        var data = { "name": newPremiseName.text, "bgImagePath": "" }
                        var success = BackendApi.createPremises(data)
                        if (success) {
                            newPremiseName.text = ""
                            refreshData()
                            createDialog.close()
                        }
                    }
                }
            }
        }
    }

    // FAB (Floating Action Button) at the bottom right
    Rectangle {
        width: 56; height: 56; radius: 28
        color: Theme.accent
        anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.margins: 24

        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#40000000"; shadowBlur: 10; shadowVerticalOffset: 4 }

        Text { text: "+"; font.pixelSize: 32; color: "white"; anchors.centerIn: parent; font.bold: true }
        MouseArea { anchors.fill: parent; onClicked: createDialog.open() }
    }
}
