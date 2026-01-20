import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    color: "#0A0A0A"

    Column {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            width: parent.width
            height: 60
            color: "#1A1A1A"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 15

                Text {
                    text: "💬"
                    font.pixelSize: 24
                }

                Text {
                    text: "Chat with Moxie"
                    font.pixelSize: 20
                    font.bold: true
                    color: "white"
                }

                Item { Layout.fillWidth: true }
            }
        }

        // Chat area
        Rectangle {
            width: parent.width
            height: parent.height - 120
            color: "transparent"

            Text {
                anchors.centerIn: parent
                text: "Chat interface coming soon...\nFull MQTT integration"
                font.pixelSize: 16
                color: "#AAAAAA"
                horizontalAlignment: Text.AlignHCenter
            }
        }

        // Input area
        Rectangle {
            width: parent.width
            height: 60
            color: "#1A1A1A"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                TextField {
                    Layout.fillWidth: true
                    placeholderText: "Type a message..."
                    color: "white"

                    background: Rectangle {
                        color: "#FFFFFF10"
                        radius: 20
                    }
                }

                Button {
                    text: "Send"
                    Layout.preferredWidth: 80
                }
            }
        }
    }
}
