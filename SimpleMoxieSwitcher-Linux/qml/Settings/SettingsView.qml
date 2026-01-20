import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    color: "#0A0A0A"

    Flickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            padding: 30
            spacing: 20

            Text {
                text: "⚙️ Settings"
                font.pixelSize: 32
                font.bold: true
                color: "white"
            }

            GroupBox {
                title: "Connection"
                width: parent.width - 60

                Column {
                    spacing: 10
                    width: parent.width

                    Label { text: "MQTT Broker"; color: "white" }
                    TextField {
                        width: parent.width
                        placeholderText: "localhost"
                    }

                    Label { text: "OpenMoxie Endpoint"; color: "white" }
                    TextField {
                        width: parent.width
                        placeholderText: "http://localhost:8003"
                    }
                }
            }

            GroupBox {
                title: "AI Providers"
                width: parent.width - 60

                Column {
                    spacing: 10
                    width: parent.width

                    Label { text: "OpenAI API Key"; color: "white" }
                    TextField {
                        width: parent.width
                        placeholderText: "sk-..."
                        echoMode: TextInput.Password
                    }

                    Label { text: "Anthropic API Key"; color: "white" }
                    TextField {
                        width: parent.width
                        placeholderText: "sk-ant-..."
                        echoMode: TextInput.Password
                    }
                }
            }

            Button {
                text: "Save Settings"
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
