import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Effects
import com.tablebooker.api 1.0
import "../components"
import "../Theme.js" as Theme

Page {
    id: page
    property int premisesId: -1
    property string premisesName: ""
    property int selectedIndex: -1 // Индекс выделенного объекта в модели

    title: premisesName

    ListModel { id: tablesModel }

    // --- ЛОГИКА ДАННЫХ (из вашего кода) ---
    function loadTables() {
        tablesModel.clear()
        var tables = BackendApi.getTablesForPremises(premisesId)
        for (var i = 0; i < tables.length; i++) {
            var t = tables[i]
            tablesModel.append({
                "dbId": t.id, "name": t.name, "x": t.x, "y": t.y,
                "width": t.width, "height": t.height,
                "type": t.type || "table",
                "rotation": t.rotation || 0,
                "color": t.color || "#E0E0E0",
                "shapeType": t.shapeType || "rect"
            })
        }
    }

    function saveTables() {
        var tablesToSave = []
        for (var i = 0; i < tablesModel.count; i++) {
            var t = tablesModel.get(i)
            tablesToSave.push({
                "id": t.dbId, "name": t.name, "x": t.x, "y": t.y,
                "width": t.width, "height": t.height,
                "type": t.type, "rotation": t.rotation,
                "color": t.color, "shapeType": t.shapeType
            })
        }
        BackendApi.saveTableLayout(premisesId, tablesToSave)
    }

    // Умное добавление (адаптировано под мобилку)
    function addItem(itemType, w, h, namePrefix, shape, col) {
        console.log("HallEditorPage.addItem called, type:", itemType, "current count:", tablesModel.count)
        // Генерируем имя
        var newName = namePrefix
        if (itemType === "table") {
            var count = 0
            for(var i=0; i<tablesModel.count; i++) {
                if (tablesModel.get(i).type === "table") count++
            }
            newName = "T-" + (count + 1)
        } else if (itemType === "room") {
            var roomCount = 0
            for(var i=0; i<tablesModel.count; i++) {
                if (tablesModel.get(i).type === "room") roomCount++
            }
            newName = namePrefix || ("Зал " + (roomCount + 1))
        } else if (itemType === "wc") {
            newName = "WC"
        }

        // Пока упрощаем: добавляем в разумный центр сцены
        var centerX = 1500 - w / 2
        var centerY = 1500 - h / 2

        tablesModel.append({
            "dbId": -1, "name": newName,
            "x": centerX, "y": centerY,
            "width": w, "height": h,
            "rotation": 0, "type": itemType,
            "shapeType": shape, "color": col
        })
        
        // Автоматически выбираем новый элемент
        selectedIndex = tablesModel.count - 1
        console.log("HallEditorPage.addItem appended, new index:", selectedIndex, "total:", tablesModel.count)
        Qt.callLater(function() {
            if (hallView && hallView.ensureItemVisible)
                hallView.ensureItemVisible(selectedIndex)
        })
    }

    function modifySelected(param, value) {
        if (selectedIndex < 0) return
        var currentVal = tablesModel.get(selectedIndex)[param]
        tablesModel.setProperty(selectedIndex, param, currentVal + value)
    }
    
    function setSelectedProperty(param, value) {
        if (selectedIndex < 0) return
        tablesModel.setProperty(selectedIndex, param, value)
    }

    function removeSelected() {
        if (selectedIndex >= 0) {
            tablesModel.remove(selectedIndex)
            selectedIndex = -1
        }
    }

    function getSelectedItem() {
        if (selectedIndex >= 0 && selectedIndex < tablesModel.count) {
            return tablesModel.get(selectedIndex)
        }
        return null
    }

    Component.onCompleted: {
        loadTables()
        // Центрируем на объектах после загрузки
        Qt.callLater(function() {
            if (tablesModel.count > 0 && hallView.centerOnObjects) {
                hallView.centerOnObjects()
            }
        })
    }

    // --- ИНТЕРФЕЙС ---

    header: ToolBar {
        background: Rectangle { 
            color: Theme.primary
        }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            
            ToolButton { 
                Text {
                    text: Theme.iconBack
                    font.pixelSize: 24
                    color: "white"
                    anchors.centerIn: parent
                }
                onClicked: page.StackView.view.pop() 
            }
            Label { 
                text: page.title
                font.bold: true
                font.pixelSize: Theme.fontSizeLarge
                color: "white"
                Layout.fillWidth: true 
            }
            Button {
                text: Theme.iconSave + " Сохранить"
                flat: true
                font.bold: true
                palette.buttonText: "white"
                onClicked: saveTables()
            }
        }
    }

    // 1. ОСНОВНОЕ ПОЛЕ (ЗУМ И СКРОЛЛ)
    ZoomableHall {
        id: hallView
        anchors.fill: parent
        anchors.rightMargin: propertiesPanel.visible ? propertiesPanel.width : 0
        tablesModel: tablesModel
        editMode: true
        selectedIndex: page.selectedIndex
        z: 1

        onTableClicked: (idx, dbId) => {
            page.selectedIndex = idx
            // Прокручиваем к выбранному элементу, чтобы он был виден
            Qt.callLater(function() {
                hallView.ensureItemVisible(idx)
            })
        }

        onCanvasTapped: {
            page.selectedIndex = -1 // Сброс выделения
        }
        
        Behavior on anchors.rightMargin {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
    }
    
    // Отслеживаем изменения выбранного элемента для автоматической прокрутки
    Connections {
        target: page
        function onSelectedIndexChanged() {
            if (page.selectedIndex >= 0) {
                Qt.callLater(function() {
                    hallView.ensureItemVisible(page.selectedIndex)
                })
            }
        }
    }

    // 2. ПАНЕЛЬ СВОЙСТВ (Справа для маленьких экранов)
    Rectangle {
        id: propertiesPanel
        width: Math.min(320, parent.width * 0.4)
        height: parent.height
        color: Theme.surface
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        visible: page.selectedIndex >= 0
        z: 200
        border.color: Theme.divider
        border.width: 1

        // Профессиональная тень слева
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: 16
            z: -1
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#30000000" }
                GradientStop { position: 0.5; color: "#15000000" }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        ScrollView {
            anchors.fill: parent
            anchors.margins: 10
            clip: true
            
            ColumnLayout {
                id: propertiesColumn
                width: propertiesPanel.width - 20
                spacing: 12

                // Заголовок с именем объекта
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

        Rectangle {
                        width: 40
                        height: 40
                        radius: 20
                        color: Theme.primary
                        opacity: 0.1
                        
                        Text {
                            text: "✏️"
                            font.pixelSize: 20
                            anchors.centerIn: parent
                        }
                    }

                    Label { 
                        text: {
                            var item = getSelectedItem()
                            if (item) return item.name || "Объект"
                            return "Объект"
                        }
                        font.bold: true
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.textPrimary
                        Layout.fillWidth: true
                    }

            Button {
                        width: 40
                        height: 40
                background: Rectangle {
                            color: Theme.error
                            radius: 20
                        }
                        contentItem: Text {
                            text: Theme.iconDelete
                            color: "white"
                            font.pixelSize: 18
                            anchors.centerIn: parent
                        }
                        onClicked: removeSelected()
                    }
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.divider
                }

                // Основные контролы - Вертикальная компоновка
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    // Поворот
                    Column {
                        Layout.fillWidth: true
                        spacing: 4
                        
                        Label {
                            text: "Поворот (°)"
                            font.pixelSize: Theme.fontSizeSmall
                            font.bold: true
                            color: Theme.textSecondary
                        }
                        SpinBox {
                            id: rotationSpinBox
                            width: parent.width
                            from: -360
                            to: 360
                            stepSize: 15
                            value: {
                                var item = getSelectedItem()
                                return item ? item.rotation : 0
                            }
                            property bool updating: false
                            onValueChanged: {
                                if (!updating && selectedIndex >= 0) {
                                    var item = getSelectedItem()
                                    if (item && value !== item.rotation) {
                                        setSelectedProperty("rotation", value)
                                    }
                                }
                            }
                            Component.onCompleted: {
                                page.selectedIndexChanged.connect(function() {
                                    updating = true
                                    var item = getSelectedItem()
                                    if (item) value = item.rotation
                                    updating = false
                                })
                            }
                            background: Rectangle {
                                color: "#FFFFFF"
                                radius: Theme.radiusSmall
                                border.width: 2
                                border.color: Theme.primary
                            }
                            contentItem: Text {
                                text: rotationSpinBox.value
                                font.pixelSize: Theme.fontSizeLarge
                                font.bold: true
                                color: "#212121"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    // Ширина
                    Column {
                        Layout.fillWidth: true
                        spacing: 4
                        
                        Label {
                            text: "Ширина"
                            font.pixelSize: Theme.fontSizeSmall
                            font.bold: true
                            color: Theme.textSecondary
                        }
                        SpinBox {
                            id: widthSpinBox
                            width: parent.width
                            from: 20
                            to: 1000
                            stepSize: 10
                            value: {
                                var item = getSelectedItem()
                                return item ? item.width : 80
                            }
                            property bool updating: false
                            onValueChanged: {
                                if (!updating && selectedIndex >= 0) {
                                    var item = getSelectedItem()
                                    if (item && value !== item.width) {
                                        setSelectedProperty("width", value)
                                    }
                                }
                            }
                            Component.onCompleted: {
                                page.selectedIndexChanged.connect(function() {
                                    updating = true
                                    var item = getSelectedItem()
                                    if (item) value = item.width
                                    updating = false
                                })
                            }
                            background: Rectangle {
                                color: "#FFFFFF"
                                radius: Theme.radiusSmall
                                border.width: 2
                                border.color: Theme.primary
                            }
                            contentItem: Text {
                                text: widthSpinBox.value
                                font.pixelSize: Theme.fontSizeLarge
                                font.bold: true
                                color: "#212121"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    // Высота
                    Column {
                        Layout.fillWidth: true
                        spacing: 4

            Label { 
                            text: "Высота"
                            font.pixelSize: Theme.fontSizeSmall
                font.bold: true
                color: Theme.textSecondary
                        }
                        SpinBox {
                            id: heightSpinBox
                            width: parent.width
                            from: 20
                            to: 1000
                            stepSize: 10
                            value: {
                                var item = getSelectedItem()
                                return item ? item.height : 80
                            }
                            property bool updating: false
                            onValueChanged: {
                                if (!updating && selectedIndex >= 0) {
                                    var item = getSelectedItem()
                                    if (item && value !== item.height) {
                                        setSelectedProperty("height", value)
                                    }
                                }
                            }
                            Component.onCompleted: {
                                page.selectedIndexChanged.connect(function() {
                                    updating = true
                                    var item = getSelectedItem()
                                    if (item) value = item.height
                                    updating = false
                                })
                            }
                            background: Rectangle {
                                color: "#FFFFFF"
                                radius: Theme.radiusSmall
                                border.width: 2
                                border.color: Theme.primary
                            }
                            contentItem: Text {
                                text: heightSpinBox.value
                                font.pixelSize: Theme.fontSizeLarge
                                font.bold: true
                                color: "#212121"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.divider
                }

                // Быстрые кнопки поворота
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Button {
                        text: "↺ -15°"
                        Layout.fillWidth: true
                        height: 36
                        background: Rectangle {
                            color: parent.pressed ? Theme.primaryDark : Theme.primary
                            radius: Theme.radiusSmall
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            font.pixelSize: Theme.fontSizeSmall
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                        onClicked: modifySelected("rotation", -15)
                    }

                    Button {
                        text: "↻ +15°"
                        Layout.fillWidth: true
                        height: 36
                        background: Rectangle {
                            color: parent.pressed ? Theme.primaryDark : Theme.primary
                            radius: Theme.radiusSmall
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            font.pixelSize: Theme.fontSizeSmall
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                        onClicked: modifySelected("rotation", 15)
            }

            Button {
                        text: "↺ -45°"
                        Layout.fillWidth: true
                        height: 36
                background: Rectangle {
                            color: parent.pressed ? Theme.primaryDark : Theme.primary
                    radius: Theme.radiusSmall
                }
                contentItem: Text {
                    text: parent.text
                            color: "white"
                            font.pixelSize: Theme.fontSizeSmall
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                        onClicked: modifySelected("rotation", -45)
            }

            Button {
                        text: "↻ +45°"
                        Layout.fillWidth: true
                        height: 36
                background: Rectangle {
                            color: parent.pressed ? Theme.primaryDark : Theme.primary
                    radius: Theme.radiusSmall
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                            font.pixelSize: Theme.fontSizeSmall
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                        onClicked: modifySelected("rotation", 45)
                    }
                }
            }
        }

        Behavior on width {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
    }

    // 3. FAB - Кнопка "Добавить" (Скрываем, если открыта панель свойств или drawer)
    Rectangle {
        id: fabButton
        width: 56
        height: 56
        radius: 28
        color: Theme.accent
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: addDrawer.isOpen ? addDrawer.height + 16 : 16
        anchors.rightMargin: propertiesPanel.visible ? propertiesPanel.width + 16 : 16
        visible: page.selectedIndex === -1 && !addDrawer.isOpen
        z: 1000
        
        // Профессиональная тень для FAB
        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            z: -1
            color: "#40000000"
            radius: parent.radius + 2
        }
        
        Text {
            text: Theme.iconAdd
            font.pixelSize: 28
            color: "white"
            anchors.centerIn: parent
        }
        
        MouseArea {
            id: fabMouseArea
            anchors.fill: parent
            onClicked: addDrawer.open()
            
            states: [
                State {
                    name: "pressed"
                    when: fabMouseArea.pressed
                    PropertyChanges { target: fabButton; scale: 0.9 }
                }
            ]
        }
        
        Behavior on scale {
            NumberAnimation { duration: 150 }
        }
        
        Behavior on anchors.rightMargin {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
    }

    // 4. МЕНЮ ДОБАВЛЕНИЯ (Drawer) - Исправленная версия
    Rectangle {
        id: addDrawer
        width: parent.width
        height: Math.min(500, parent.height * 0.7)
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        color: Theme.surface
        z: 1500
        visible: false
        
        // Скругление сверху
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: Theme.radiusLarge
            color: parent.color
        }
        
        // Тень сверху
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 12
            z: -1
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#20000000" }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
        
        property bool isOpen: false
        
        function open() {
            isOpen = true
            visible = true
        }
        
        function close() {
            isOpen = false
            visible = false
        }
        
        y: isOpen ? parent.height - height : parent.height

        Behavior on y {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }
        
        // Прозрачная зона для закрытия по клику вне карточки (не перекрывает сам drawer)
        Rectangle {
            id: overlay
            parent: page
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: addDrawer.top
            color: "transparent"
            z: 1499
            visible: addDrawer.isOpen
            MouseArea {
                anchors.fill: parent
                onClicked: addDrawer.close()
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingMedium
            spacing: Theme.spacingMedium

            // Заголовок
            RowLayout {
                Layout.fillWidth: true
                
                Text {
                    text: Theme.iconAdd
                    font.pixelSize: 28
                    color: Theme.textPrimary
                }
                
                Label { 
                    text: "Добавить объект"
                    font.bold: true
                    font.pixelSize: Theme.fontSizeLarge
                    color: Theme.textPrimary
                    Layout.fillWidth: true
                }
                
                ToolButton {
                    width: 40
                    height: 40
                    Text {
                        text: Theme.iconClose
                        font.pixelSize: 24
                        color: Theme.textSecondary
                        anchors.centerIn: parent
                    }
                    onClicked: addDrawer.close()
                }
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.divider
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                
                GridLayout {
                    width: addDrawer.width - Theme.spacingMedium * 2
                    columns: 2
                    columnSpacing: Theme.spacingSmall
                    rowSpacing: Theme.spacingSmall

                // Столы
                Button { 
                    text: Theme.iconTable + "\nСтол (Круг)"
                    Layout.fillWidth: true
                        Layout.preferredHeight: 90
                    background: Rectangle {
                        color: Theme.primaryLight
                        radius: Theme.radiusMedium
                            border.width: 1
                            border.color: Theme.divider
                    }
                    contentItem: Text {
                        text: parent.text
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontSizeMedium
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: { 
                        console.log("Add button pressed: round table")
                        addItem("table", 50, 50, "", "ellipse", "#FFF59D"); 
                        addDrawer.close()
                    } 
                }
                
                Button { 
                    text: Theme.iconTable + "\nСтол (Квадрат)"
                    Layout.fillWidth: true
                        Layout.preferredHeight: 90
                    background: Rectangle {
                        color: Theme.primaryLight
                        radius: Theme.radiusMedium
                            border.width: 1
                            border.color: Theme.divider
                    }
                    contentItem: Text {
                        text: parent.text
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontSizeMedium
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: { 
                        console.log("Add button pressed: square table")
                        addItem("table", 50, 50, "", "rect", "#FFF59D"); 
                        addDrawer.close()
                    } 
                }
                
                // Комната (пол)
                Button { 
                    text: "🏢\nКомната"
                    Layout.fillWidth: true
                        Layout.preferredHeight: 90
                    background: Rectangle {
                        color: Theme.surfaceDark
                        radius: Theme.radiusMedium
                            border.width: 1
                            border.color: Theme.divider
                    }
                    contentItem: Text {
                        text: parent.text
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontSizeMedium
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: { 
                        console.log("Add button pressed: room")
                        addItem("room", 400, 300, "Зал", "rect", "#F5F5F5"); 
                        addDrawer.close() 
                    } 
                }

                // Стены и окна
                Button { 
                    text: "🧱\nСтена"
                    Layout.fillWidth: true
                        Layout.preferredHeight: 90
                    background: Rectangle {
                        color: Theme.surfaceDark
                        radius: Theme.radiusMedium
                            border.width: 1
                            border.color: Theme.divider
                    }
                    contentItem: Text {
                        text: parent.text
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontSizeMedium
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: { 
                        console.log("Add button pressed: wall")
                        addItem("wall", 150, 10, "", "rect", "#424242"); 
                        addDrawer.close() 
                    } 
                }
                
                Button { 
                    text: "🪟\nОкно"
                    Layout.fillWidth: true
                        Layout.preferredHeight: 90
                    background: Rectangle {
                        color: Theme.surfaceDark
                        radius: Theme.radiusMedium
                            border.width: 1
                            border.color: Theme.divider
                    }
                    contentItem: Text {
                        text: parent.text
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontSizeMedium
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: { 
                        console.log("Add button pressed: window")
                        addItem("window", 100, 15, "", "rect", "#81D4FA"); 
                        addDrawer.close() 
                    } 
                }

                // Прочее
                Button { 
                    text: "🚻\nWC"
                    Layout.fillWidth: true
                        Layout.preferredHeight: 90
                    background: Rectangle {
                        color: Theme.surfaceDark
                        radius: Theme.radiusMedium
                            border.width: 1
                            border.color: Theme.divider
                    }
                    contentItem: Text {
                        text: parent.text
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontSizeMedium
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: { 
                        console.log("Add button pressed: wc")
                        addItem("wc", 50, 50, "WC", "rect", "#FFFFFF"); 
                        addDrawer.close() 
                    } 
                }
                
                Button { 
                    text: "🌿\nДекор"
                    Layout.fillWidth: true
                        Layout.preferredHeight: 90
                    background: Rectangle {
                        color: Theme.surfaceDark
                        radius: Theme.radiusMedium
                            border.width: 1
                            border.color: Theme.divider
                    }
                    contentItem: Text {
                        text: parent.text
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontSizeMedium
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: { 
                        console.log("Add button pressed: plant")
                        addItem("plant", 40, 40, "", "rect", "transparent"); 
                        addDrawer.close() 
                    } 
                    }
                }
            }
        }
    }
}
