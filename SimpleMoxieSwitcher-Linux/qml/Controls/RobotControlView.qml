import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    color: "#0A0A0A"

    gradient: Gradient {
        GradientStop { position: 0.0; color: "#0A0A0A" }
        GradientStop { position: 0.5; color: "#1A1A2E" }
        GradientStop { position: 1.0; color: "#0A0A0A" }
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth

        ColumnLayout {
            width: parent.width
            spacing: 20

            // Header with connection status
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                color: "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 20

                    Text {
                        text: "🤖 Robot Control Center"
                        font.pixelSize: 32
                        font.bold: true
                        color: "white"
                    }

                    Item { Layout.fillWidth: true }

                    // Connection indicator
                    Rectangle {
                        width: 200
                        height: 40
                        radius: 20
                        color: controlsViewModel.isConnected ? "#1B5E20" : "#B71C1C"

                        RowLayout {
                            anchors.centerIn: parent

                            Rectangle {
                                width: 12
                                height: 12
                                radius: 6
                                color: controlsViewModel.isConnected ? "#4CAF50" : "#F44336"

                                SequentialAnimation on opacity {
                                    running: controlsViewModel.isConnected
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 1.0; to: 0.3; duration: 1000 }
                                    NumberAnimation { from: 0.3; to: 1.0; duration: 1000 }
                                }
                            }

                            Text {
                                text: controlsViewModel.isConnected ? "Connected" : "Disconnected"
                                color: "white"
                                font.pixelSize: 14
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (controlsViewModel.isConnected) {
                                    controlsViewModel.disconnectFromRobot()
                                } else {
                                    controlsViewModel.connectToRobot()
                                }
                            }
                        }
                    }
                }
            }

            // Main control panels
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 20
                spacing: 20

                // Left panel - Basic Controls
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 400
                    color: "#1A1A1A"
                    radius: 12

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 15

                        Text {
                            text: "Basic Controls"
                            color: "white"
                            font.pixelSize: 20
                            font.bold: true
                        }

                        // Volume control
                        ColumnLayout {
                            spacing: 5

                            RowLayout {
                                Text {
                                    text: "🔊 Volume"
                                    color: "white"
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: Math.round(volumeSlider.value) + "%"
                                    color: "#888"
                                }
                            }

                            Slider {
                                id: volumeSlider
                                Layout.fillWidth: true
                                from: 0
                                to: 100
                                value: controlsViewModel.volumeLevel
                                onValueChanged: controlsViewModel.volumeLevel = value
                            }
                        }

                        // Brightness control
                        ColumnLayout {
                            spacing: 5

                            RowLayout {
                                Text {
                                    text: "💡 Brightness"
                                    color: "white"
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: Math.round(brightnessSlider.value) + "%"
                                    color: "#888"
                                }
                            }

                            Slider {
                                id: brightnessSlider
                                Layout.fillWidth: true
                                from: 0
                                to: 100
                                value: controlsViewModel.brightness
                                onValueChanged: controlsViewModel.brightness = value
                            }
                        }

                        // Sleep mode
                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "😴 Sleep Mode"
                                color: "white"
                            }

                            Item { Layout.fillWidth: true }

                            Switch {
                                checked: controlsViewModel.isSleepMode
                                onCheckedChanged: controlsViewModel.isSleepMode = checked
                            }
                        }

                        // Auto shutdown
                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "⏰ Auto Shutdown"
                                color: "white"
                            }

                            Item { Layout.fillWidth: true }

                            Switch {
                                checked: controlsViewModel.autoShutdownEnabled
                                onCheckedChanged: controlsViewModel.autoShutdownEnabled = checked
                            }

                            SpinBox {
                                from: 5
                                to: 120
                                value: controlsViewModel.autoShutdownMinutes
                                suffix: " min"
                                enabled: controlsViewModel.autoShutdownEnabled
                                onValueChanged: controlsViewModel.autoShutdownMinutes = value
                            }
                        }

                        Item { Layout.fillHeight: true }

                        // Power controls
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Button {
                                text: "🔄 Reboot"
                                Layout.fillWidth: true
                                onClicked: controlsViewModel.rebootRobot()

                                background: Rectangle {
                                    color: parent.hovered ? "#FFA500" : "#FF8C00"
                                    radius: 8
                                }

                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            Button {
                                text: "⚡ Wake Up"
                                Layout.fillWidth: true
                                onClicked: controlsViewModel.wakeUpRobot()

                                background: Rectangle {
                                    color: parent.hovered ? "#4CAF50" : "#388E3C"
                                    radius: 8
                                }

                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            Button {
                                text: "🔴 Shutdown"
                                Layout.fillWidth: true
                                onClicked: controlsViewModel.shutdownRobot()

                                background: Rectangle {
                                    color: parent.hovered ? "#F44336" : "#D32F2F"
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
                }

                // Right panel - Status & Info
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 400
                    color: "#1A1A1A"
                    radius: 12

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 15

                        Text {
                            text: "Status & Information"
                            color: "white"
                            font.pixelSize: 20
                            font.bold: true
                        }

                        // Battery level
                        Rectangle {
                            Layout.fillWidth: true
                            height: 60
                            color: "#2A2A2A"
                            radius: 8

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10

                                Text {
                                    text: "🔋 Battery"
                                    color: "white"
                                    font.pixelSize: 16
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    width: 150
                                    height: 30
                                    radius: 15
                                    color: "#1A1A1A"

                                    Rectangle {
                                        width: parent.width * (controlsViewModel.batteryLevel / 100)
                                        height: parent.height
                                        radius: 15
                                        color: controlsViewModel.batteryLevel > 30 ? "#4CAF50" :
                                               controlsViewModel.batteryLevel > 15 ? "#FFA500" : "#F44336"
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: Math.round(controlsViewModel.batteryLevel) + "%"
                                        color: "white"
                                        font.bold: true
                                    }
                                }
                            }
                        }

                        // Robot status
                        Rectangle {
                            Layout.fillWidth: true
                            height: 50
                            color: "#2A2A2A"
                            radius: 8

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10

                                Text {
                                    text: "📡 Status:"
                                    color: "white"
                                }

                                Text {
                                    text: controlsViewModel.robotStatus
                                    color: "#4CAF50"
                                    font.bold: true
                                }

                                Item { Layout.fillWidth: true }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }

            // Animation controls
            Rectangle {
                Layout.fillWidth: true
                Layout.margins: 20
                Layout.preferredHeight: 150
                color: "#1A1A1A"
                radius: 12

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 10

                    Text {
                        text: "Animations & Expressions"
                        color: "white"
                        font.pixelSize: 18
                        font.bold: true
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 5
                        columnSpacing: 10
                        rowSpacing: 10

                        Repeater {
                            model: [
                                "😊 Happy", "😢 Sad", "😲 Surprised", "😴 Tired", "🤔 Thinking",
                                "👋 Wave", "💃 Dance", "🎉 Celebrate", "😄 Laugh", "🤗 Hug"
                            ]

                            delegate: Button {
                                text: modelData
                                Layout.fillWidth: true

                                background: Rectangle {
                                    color: parent.hovered ? "#3A3A3A" : "#2A2A2A"
                                    radius: 6
                                }

                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                onClicked: {
                                    let animName = modelData.split(" ")[1].toLowerCase()
                                    controlsViewModel.playAnimation(animName)
                                }
                            }
                        }
                    }
                }
            }

            // Speech input
            Rectangle {
                Layout.fillWidth: true
                Layout.margins: 20
                Layout.preferredHeight: 100
                color: "#1A1A1A"
                radius: 12

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 10

                    Text {
                        text: "💬 Make Robot Say:"
                        color: "white"
                        font.pixelSize: 16
                    }

                    TextField {
                        id: speechInput
                        Layout.fillWidth: true
                        placeholderText: "Enter text for robot to speak..."
                        color: "white"

                        background: Rectangle {
                            color: "#2A2A2A"
                            border.color: "#3A3A3A"
                            radius: 6
                        }
                    }

                    Button {
                        text: "🔊 Speak"
                        onClicked: {
                            if (speechInput.text.trim() !== "") {
                                controlsViewModel.sayPhrase(speechInput.text)
                                speechInput.text = ""
                            }
                        }

                        background: Rectangle {
                            color: parent.hovered ? "#2A5BA5" : "#1E88E5"
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

            Item { Layout.fillHeight: true }
        }
    }
}