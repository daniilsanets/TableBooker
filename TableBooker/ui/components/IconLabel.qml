import QtQuick 2.15
import QtQuick.Controls 2.15

// Компонент для отображения Material Icons
Text {
    id: root
    font.family: "Material Icons"
    font.pixelSize: parent ? parent.height * 0.6 : 24
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
    
    // Если Material Icons не установлен, используем эмодзи как fallback
    property string icon: ""
    property string emojiFallback: ""
    
    text: {
        // Проверяем, поддерживается ли Material Icons
        // Если нет, используем эмодзи
        if (icon.length > 0 && icon.charCodeAt(0) > 0xE000) {
            return icon
        }
        return emojiFallback
    }
}

