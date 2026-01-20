import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: controlsRoot
    color: "#0A0A0A"

    property bool isConnected: false
    property int volume: 50
    property string currentEmotion: "neutral"

    ScrollView {
        anchors.fill: parent
        anchors.margins: 30
        clip: true

        ColumnLayout {
            width: controlsRoot.width - 60
            spacing: 24

            // Header
            Text {
                text: "🎛️ Robot Controls"
                font.pixelSize: 32
                font.bold: true
                color: "white"
            }

            // Connection status
            Rectangle {
                Layout.fillWidth: true
                height: 80
                color: isConnected ? "#1B4332" : "#3D1F1F"
                radius: 12
                border.color: isConnected ? "#2D6A4F" : "#6B2D2D"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 16

                    Rectangle {
                        width: 16
                        height: 16
                        radius: 8
                        color: isConnected ? "#40C057" : "#E03131"
                    }

                    Text {
                        text: isConnected ? "Connected to Moxie" : "Not Connected"
                        font.pixelSize: 18
                        font.bold: true
                        color: "white"
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        text: isConnected ? "Disconnect" : "Connect"
                        onClicked: isConnected = !isConnected

                        background: Rectangle {
                            color: parent.hovered ? "#444" : "#333"
                            radius: 8
                        }

                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }

            // Movement controls
            Rectangle {
                Layout.fillWidth: true
                height: 300
                color: "#1A1A1A"
                radius: 16
                border.color: "#333"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 16

                    Text {
                        text: "Movement"
                        font.pixelSize: 18
                        font.bold: true
                        color: "white"
                    }

                    // D-Pad style controls
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        // Up
                        ControlButton {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: 10
                            text: "▲"
                            onClicked: sendCommand("move_forward")
                        }

                        // Left
                        ControlButton {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: parent.width / 2 - 100
                            text: "◀"
                            onClicked: sendCommand("turn_left")
                        }

                        // Center (Stop)
                        ControlButton {
                            anchors.centerIn: parent
                            text: "⬛"
                            buttonColor: "#E03131"
                            onClicked: sendCommand("stop")
                        }

                        // Right
                        ControlButton {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: parent.width / 2 - 100
                            text: "▶"
                            onClicked: sendCommand("turn_right")
                        }

                        // Down
                        ControlButton {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 10
                            text: "▼"
                            onClicked: sendCommand("move_backward")
                        }
                    }
                }
            }

            // Volume and emotions row
            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                // Volume control
                Rectangle {
                    Layout.fillWidth: true
                    height: 150
                    color: "#1A1A1A"
                    radius: 16
                    border.color: "#333"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 12

                        Text {
                            text: "🔊 Volume: " + volume + "%"
                            font.pixelSize: 16
                            font.bold: true
                            color: "white"
                        }

                        Slider {
                            Layout.fillWidth: true
                            from: 0
                            to: 100
                            value: volume
                            onValueChanged: volume = value

                            background: Rectangle {
                                x: parent.leftPadding
                                y: parent.topPadding + parent.availableHeight / 2 - height / 2
                                width: parent.availableWidth
                                height: 8
                                radius: 4
                                color: "#333"

                                Rectangle {
                                    width: parent.parent.visualPosition * parent.width
                                    height: parent.height
                                    radius: 4
                                    color: "#FF6B35"
                                }
                            }

                            handle: Rectangle {
                                x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                                y: parent.topPadding + parent.availableHeight / 2 - height / 2
                                width: 24
                                height: 24
                                radius: 12
                                color: parent.pressed ? "#FFA500" : "#FF6B35"
                            }
                        }

                        RowLayout {
                            spacing: 8
                            Button {
                                text: "🔇"
                                onClicked: volume = 0
                                background: Rectangle { color: "#333"; radius: 6 }
                                contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter }
                            }
                            Button {
                                text: "🔉"
                                onClicked: volume = Math.max(0, volume - 10)
                                background: Rectangle { color: "#333"; radius: 6 }
                                contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter }
                            }
                            Button {
                                text: "🔊"
                                onClicked: volume = Math.min(100, volume + 10)
                                background: Rectangle { color: "#333"; radius: 6 }
                                contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter }
                            }
                        }
                    }
                }

                // Emotion selector
                Rectangle {
                    Layout.fillWidth: true
                    height: 150
                    color: "#1A1A1A"
                    radius: 16
                    border.color: "#333"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 12

                        Text {
                            text: "😊 Emotion"
                            font.pixelSize: 16
                            font.bold: true
                            color: "white"
                        }

                        GridLayout {
                            columns: 4
                            columnSpacing: 8
                            rowSpacing: 8

                            Repeater {
                                model: [
                                    { emoji: "😊", name: "happy" },
                                    { emoji: "😢", name: "sad" },
                                    { emoji: "😠", name: "angry" },
                                    { emoji: "😮", name: "surprised" },
                                    { emoji: "😐", name: "neutral" },
                                    { emoji: "🤩", name: "excited" },
                                    { emoji: "😴", name: "sleepy" },
                                    { emoji: "😕", name: "confused" }
                                ]

                                Button {
                                    text: modelData.emoji
                                    Layout.preferredWidth: 50
                                    Layout.preferredHeight: 50

                                    background: Rectangle {
                                        color: currentEmotion === modelData.name ? "#FF6B35" : (parent.hovered ? "#444" : "#333")
                                        radius: 8
                                    }

                                    contentItem: Text {
                                        text: parent.text
                                        font.pixelSize: 24
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    onClicked: {
                                        currentEmotion = modelData.name
                                        sendCommand("emotion_" + modelData.name)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function sendCommand(cmd) {
        console.log("Sending command:", cmd)
        // Would call MQTTService to send command to robot
    }

    component ControlButton: Button {
        property string buttonColor: "#FF6B35"
        width: 60
        height: 60

        background: Rectangle {
            color: parent.pressed ? Qt.darker(buttonColor, 1.2) : (parent.hovered ? Qt.lighter(buttonColor, 1.1) : buttonColor)
            radius: 12
        }

        contentItem: Text {
            text: parent.text
            font.pixelSize: 24
            color: "white"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
