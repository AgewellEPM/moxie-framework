import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    gradient: Gradient {
        gradient: RadialGradient {
            centerX: parent.width / 2
            centerY: parent.height / 2
            centerRadius: 300
            GradientStop { position: 0.0; color: "#2A1A5A" }
            GradientStop { position: 1.0; color: "#0A0A0A" }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 30

        Text {
            text: "🧠"
            font.pixelSize: 100
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "Memory Visualization"
            font.pixelSize: 32
            font.bold: true
            color: "white"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "3-panel memory browser\n(Full implementation coming soon)"
            font.pixelSize: 16
            color: "#AAAAAA"
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
