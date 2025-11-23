import QtQuick 2.15

Item {
    id: themeRoot
    
    // Цвета
    readonly property color primary: "#2196F3"
    readonly property color primaryDark: "#1976D2"
    readonly property color primaryLight: "#64B5F6"
    readonly property color accent: "#FF5722"
    readonly property color accentLight: "#FF8A65"
    
    readonly property color background: "#FAFAFA"
    readonly property color surface: "#FFFFFF"
    readonly property color surfaceDark: "#F5F5F5"
    
    readonly property color textPrimary: "#212121"
    readonly property color textSecondary: "#757575"
    readonly property color textHint: "#9E9E9E"
    
    readonly property color divider: "#BDBDBD"
    readonly property color error: "#F44336"
    readonly property color success: "#4CAF50"
    readonly property color warning: "#FF9800"
    
    // Размеры
    readonly property int spacingSmall: 8
    readonly property int spacingMedium: 16
    readonly property int spacingLarge: 24
    
    readonly property int radiusSmall: 4
    readonly property int radiusMedium: 8
    readonly property int radiusLarge: 16
    
    // Шрифты
    readonly property int fontSizeSmall: 12
    readonly property int fontSizeMedium: 14
    readonly property int fontSizeLarge: 18
    readonly property int fontSizeXLarge: 24
    readonly property int fontSizeXXLarge: 32
    
    // Иконки (эмодзи)
    readonly property string iconHome: "🏠"
    readonly property string iconRestaurant: "🍽️"
    readonly property string iconTable: "🪑"
    readonly property string iconCalendar: "📅"
    readonly property string iconTime: "🕐"
    readonly property string iconPerson: "👤"
    readonly property string iconLock: "🔒"
    readonly property string iconEmail: "📧"
    readonly property string iconPhone: "📱"
    readonly property string iconEdit: "✏️"
    readonly property string iconDelete: "🗑️"
    readonly property string iconAdd: "➕"
    readonly property string iconSave: "💾"
    readonly property string iconBack: "←"
    readonly property string iconMenu: "☰"
    readonly property string iconClose: "✕"
    readonly property string iconCheck: "✓"
    readonly property string iconInfo: "ℹ️"
    readonly property string iconSettings: "⚙️"
    readonly property string iconLogout: "🚪"
    readonly property string iconVisibility: "👁️"
    readonly property string iconVisibilityOff: "🙈"
    readonly property string iconSearch: "🔍"
    readonly property string iconFilter: "🔽"
    readonly property string iconZoomIn: "🔍+"
    readonly property string iconZoomOut: "🔍-"
    readonly property string iconRotateLeft: "↺"
    readonly property string iconRotateRight: "↻"
    
    // Скрываем визуально
    visible: false
    width: 0
    height: 0
}
