import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    gradient: Gradient {
        GradientStop { position: 0.0; color: "#1A1A1A" }
        GradientStop { position: 0.5; color: "#0F3460" }
        GradientStop { position: 1.0; color: "#1A1A1A" }
    }

    Column {
        anchors.centerIn: parent
        spacing: 30

        Text {
            text: "📊"
            font.pixelSize: 100
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "Usage Analytics"
            font.pixelSize: 32
            font.bold: true
            color: "white"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "Track AI costs and usage trends\n(Full implementation coming soon)"
            font.pixelSize: 16
            color: "#AAAAAA"
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
