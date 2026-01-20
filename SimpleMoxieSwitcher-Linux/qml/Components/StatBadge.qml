import QtQuick 2.15

Column {
    property string icon: "🎮"
    property string label: "Label"
    property var value: 0

    spacing: 4
    width: 100

    Text {
        text: icon
        font.pixelSize: 28
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Text {
        text: typeof value === "number" ? value.toString() : value
        font.pixelSize: 24
        font.bold: true
        color: "white"
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Text {
        text: label
        font.pixelSize: 12
        color: "#AAAAAA"
        anchors.horizontalCenter: parent.horizontalCenter
    }
}
