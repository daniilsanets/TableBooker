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

        // Добавляем в центр видимой области
        var centerX = 1500
        var centerY = 1500

        tablesModel.append({
            "dbId": -1, "name": newName,
            "x": centerX, "y": centerY,
            "width": w, "height": h,
            "rotation": 0, "type": itemType,
            "shapeType": shape, "color": col
        })
        
        // Автоматически выбираем новый элемент
        selectedIndex = tablesModel.count - 1
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
        anchors.bottomMargin: propertiesPanel.visible ? propertiesPanel.height : 0
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
        
        Behavior on anchors.bottomMargin {
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

    // 2. ПАНЕЛЬ СВОЙСТВ (Профессиональная панель редактирования)
    Rectangle {
        id: propertiesPanel
        width: parent.width
        height: propertiesColumn.height + Theme.spacingMedium * 2
        color: Theme.surface
        anchors.bottom: parent.bottom
        visible: page.selectedIndex >= 0
        z: 200
        border.color: Theme.divider
        border.width: 1

        // Профессиональная тень сверху
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

        ColumnLayout {
            id: propertiesColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.spacingMedium
            spacing: Theme.spacingSmall

            // Заголовок с именем объекта
        RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingMedium

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
                text: Theme.iconDelete
                background: Rectangle {
                    color: Theme.error
                    radius: Theme.radiusSmall
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    font.pixelSize: Theme.fontSizeMedium
                }
                onClicked: removeSelected()
            }
            }

            // Основные контролы
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSmall

                // Позиция X
                Column {
                    spacing: 4
                    Label {
                        text: "X"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.textSecondary
                    }
                    SpinBox {
                        id: posXSpinBox
                        from: 0
                        to: 10000
                        stepSize: 10
                        value: {
                            var item = getSelectedItem()
                            return item ? item.x : 0
                        }
                        property bool updating: false
                        onValueChanged: {
                            if (!updating && selectedIndex >= 0) {
                                var item = getSelectedItem()
                                if (item && value !== item.x) {
                                    setSelectedProperty("x", value)
                                }
                            }
                        }
                        Component.onCompleted: {
                            page.selectedIndexChanged.connect(function() {
                                updating = true
                                var item = getSelectedItem()
                                if (item) value = item.x
                                updating = false
                            })
                        }
                        background: Rectangle {
                            color: Theme.surfaceDark
                            radius: Theme.radiusSmall
                        }
                    }
                }

                // Позиция Y
                Column {
                    spacing: 4
                    Label {
                        text: "Y"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.textSecondary
                    }
                    SpinBox {
                        id: posYSpinBox
                        from: 0
                        to: 10000
                        stepSize: 10
                        value: {
                            var item = getSelectedItem()
                            return item ? item.y : 0
                        }
                        property bool updating: false
                        onValueChanged: {
                            if (!updating && selectedIndex >= 0) {
                                var item = getSelectedItem()
                                if (item && value !== item.y) {
                                    setSelectedProperty("y", value)
                                }
                            }
                        }
                        Component.onCompleted: {
                            page.selectedIndexChanged.connect(function() {
                                updating = true
                                var item = getSelectedItem()
                                if (item) value = item.y
                                updating = false
                            })
                        }
                        background: Rectangle {
                            color: Theme.surfaceDark
                            radius: Theme.radiusSmall
                        }
                    }
                }

                // Ширина
                Column {
                    spacing: 4
                    Label {
                        text: "Ш"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.textSecondary
                    }
                    SpinBox {
                        id: widthSpinBox
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
                            color: Theme.surfaceDark
                            radius: Theme.radiusSmall
                        }
                    }
                }

                // Высота
                Column {
                    spacing: 4
                    Label {
                        text: "В"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.textSecondary
                    }
                    SpinBox {
                        id: heightSpinBox
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
                            color: Theme.surfaceDark
                            radius: Theme.radiusSmall
                        }
                    }
                }

                // Поворот
                Column {
                    spacing: 4
                    Label {
                        text: "°"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.textSecondary
                    }
                    SpinBox {
                        id: rotationSpinBox
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
                            color: Theme.surfaceDark
                            radius: Theme.radiusSmall
                        }
                    }
                }
            }

            // Быстрые кнопки
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSmall

                Button {
                    text: Theme.iconRotateLeft + " -15°"
                    Layout.fillWidth: true
                    background: Rectangle {
                        color: Theme.surfaceDark
                        radius: Theme.radiusSmall
                    }
                    contentItem: Text {
                        text: parent.text
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignHCenter
                    }
                    onClicked: modifySelected("rotation", -15)
                }

                Button {
                    text: Theme.iconRotateRight + " +15°"
                    Layout.fillWidth: true
                    background: Rectangle {
                        color: Theme.surfaceDark
                        radius: Theme.radiusSmall
                    }
                    contentItem: Text {
                        text: parent.text
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignHCenter
                    }
                    onClicked: modifySelected("rotation", 15)
                }

                Button {
                    text: Theme.iconRotateLeft + " -45°"
                    Layout.fillWidth: true
                    background: Rectangle {
                        color: Theme.surfaceDark
                        radius: Theme.radiusSmall
                    }
                    contentItem: Text {
                        text: parent.text
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignHCenter
                    }
                    onClicked: modifySelected("rotation", -45)
                }

                Button {
                    text: Theme.iconRotateRight + " +45°"
                    Layout.fillWidth: true
                    background: Rectangle {
                        color: Theme.surfaceDark
                        radius: Theme.radiusSmall
                    }
                    contentItem: Text {
                        text: parent.text
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignHCenter
                    }
                    onClicked: modifySelected("rotation", 45)
                }
            }
        }

        Behavior on height {
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
        anchors.bottomMargin: propertiesPanel.visible ? propertiesPanel.height + 16 : (addDrawer.isOpen ? addDrawer.height + 16 : 16)
        anchors.rightMargin: 16
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
        
        Behavior on anchors.bottomMargin {
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
        
        // Затемнение фона
        Rectangle {
            anchors.fill: parent.parent
            color: "#80000000"
            z: -2
            visible: addDrawer.isOpen
            opacity: addDrawer.isOpen ? 1 : 0
            MouseArea {
                anchors.fill: parent
                onClicked: addDrawer.close()
            }
            Behavior on opacity {
                NumberAnimation { duration: 300 }
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
                        onClicked: { addItem("table", 50, 50, "", "ellipse", "#FFF59D"); addDrawer.close() } 
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
                        onClicked: { addItem("table", 50, 50, "", "rect", "#FFF59D"); addDrawer.close() } 
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
                    onClicked: { addItem("room", 400, 300, "Зал", "rect", "#F5F5F5"); addDrawer.close() } 
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
                    onClicked: { addItem("wall", 150, 10, "", "rect", "#424242"); addDrawer.close() } 
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
                    onClicked: { addItem("window", 100, 15, "", "rect", "#81D4FA"); addDrawer.close() } 
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
                        onClicked: { addItem("wc", 50, 50, "WC", "rect", "#FFFFFF"); addDrawer.close() } 
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
                        onClicked: { addItem("plant", 40, 40, "", "rect", "transparent"); addDrawer.close() } 
                    }
                }
            }
        }
    }
}
