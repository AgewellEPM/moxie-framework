import QtQuick 2.15
import QtQuick.Controls 2.15

Button {
    id: root
    property string icon: ""

    width: parent.width
    height: 50

    background: Rectangle {
        radius: 10
        color: root.hovered ? "#FFFFFF15" : "#FFFFFF08"

        Behavior on color {
            ColorAnimation { duration: 200 }
        }
    }

    contentItem: Text {
        text: root.text
        font.pixelSize: 14
        font.bold: root.hovered
        color: "white"
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        leftPadding: 15
    }

    scale: root.pressed ? 0.98 : 1.0

    Behavior on scale {
        NumberAnimation {
            duration: 100
            easing.type: Easing.OutCubic
        }
    }
}
