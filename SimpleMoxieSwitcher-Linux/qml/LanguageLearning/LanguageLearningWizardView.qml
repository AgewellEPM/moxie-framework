import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: languageRoot
    color: "#0A0A0A"

    property string selectedLanguage: ""
    property string proficiencyLevel: "beginner"
    property int currentStep: 0

    ScrollView {
        anchors.fill: parent
        anchors.margins: 30
        clip: true

        ColumnLayout {
            width: languageRoot.width - 60
            spacing: 24

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                Text {
                    text: "🌍 Language Learning"
                    font.pixelSize: 32
                    font.bold: true
                    color: "white"
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: selectedLanguage.length > 0 ? "Learning: " + selectedLanguage : "Select a language"
                    font.pixelSize: 14
                    color: "#888"
                }
            }

            // Language selection grid
            Rectangle {
                Layout.fillWidth: true
                height: 350
                color: "#1A1A1A"
                radius: 16
                border.color: "#333"
                visible: selectedLanguage.length === 0

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 20

                    Text {
                        text: "Choose a Language to Learn"
                        font.pixelSize: 20
                        font.bold: true
                        color: "white"
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 4
                        columnSpacing: 16
                        rowSpacing: 16

                        Repeater {
                            model: [
                                { flag: "🇪🇸", name: "Spanish", code: "es" },
                                { flag: "🇫🇷", name: "French", code: "fr" },
                                { flag: "🇩🇪", name: "German", code: "de" },
                                { flag: "🇮🇹", name: "Italian", code: "it" },
                                { flag: "🇵🇹", name: "Portuguese", code: "pt" },
                                { flag: "🇯🇵", name: "Japanese", code: "ja" },
                                { flag: "🇨🇳", name: "Chinese", code: "zh" },
                                { flag: "🇰🇷", name: "Korean", code: "ko" }
                            ]

                            Rectangle {
                                Layout.fillWidth: true
                                height: 100
                                color: mouseArea.containsMouse ? "#2A2A2A" : "#222"
                                radius: 12
                                border.color: mouseArea.containsMouse ? "#FF6B35" : "#333"
                                border.width: mouseArea.containsMouse ? 2 : 1

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 8

                                    Text {
                                        text: modelData.flag
                                        font.pixelSize: 36
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    Text {
                                        text: modelData.name
                                        font.pixelSize: 14
                                        color: "white"
                                        font.bold: true
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }

                                MouseArea {
                                    id: mouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        selectedLanguage = modelData.name
                                        currentStep = 1
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Proficiency selection
            Rectangle {
                Layout.fillWidth: true
                height: 250
                color: "#1A1A1A"
                radius: 16
                border.color: "#333"
                visible: selectedLanguage.length > 0 && currentStep === 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 20

                    Text {
                        text: "What's your current level?"
                        font.pixelSize: 20
                        font.bold: true
                        color: "white"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        Repeater {
                            model: [
                                { level: "beginner", emoji: "🌱", label: "Beginner", desc: "Just starting out" },
                                { level: "intermediate", emoji: "🌿", label: "Intermediate", desc: "Know the basics" },
                                { level: "advanced", emoji: "🌳", label: "Advanced", desc: "Quite comfortable" }
                            ]

                            Rectangle {
                                Layout.fillWidth: true
                                height: 120
                                color: proficiencyLevel === modelData.level ? "#2D4A3E" : "#222"
                                radius: 12
                                border.color: proficiencyLevel === modelData.level ? "#4CAF50" : "#333"
                                border.width: proficiencyLevel === modelData.level ? 2 : 1

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 8

                                    Text {
                                        text: modelData.emoji
                                        font.pixelSize: 32
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    Text {
                                        text: modelData.label
                                        font.pixelSize: 16
                                        font.bold: true
                                        color: "white"
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    Text {
                                        text: modelData.desc
                                        font.pixelSize: 12
                                        color: "#888"
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: proficiencyLevel = modelData.level
                                }
                            }
                        }
                    }

                    Button {
                        Layout.alignment: Qt.AlignRight
                        text: "Start Learning →"
                        onClicked: currentStep = 2

                        background: Rectangle {
                            color: parent.hovered ? "#FF8C00" : "#FF6B35"
                            radius: 8
                        }

                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            padding: 12
                        }
                    }
                }
            }

            // Learning dashboard
            Rectangle {
                Layout.fillWidth: true
                Layout.minimumHeight: 500
                color: "#1A1A1A"
                radius: 16
                border.color: "#333"
                visible: currentStep === 2

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 20

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "📚 Your " + selectedLanguage + " Journey"
                            font.pixelSize: 20
                            font.bold: true
                            color: "white"
                        }

                        Item { Layout.fillWidth: true }

                        Button {
                            text: "Change Language"
                            onClicked: {
                                selectedLanguage = ""
                                currentStep = 0
                            }

                            background: Rectangle {
                                color: "#333"
                                radius: 6
                            }

                            contentItem: Text {
                                text: parent.text
                                color: "#888"
                                font.pixelSize: 12
                            }
                        }
                    }

                    // Progress stats
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        Repeater {
                            model: [
                                { value: "0", label: "Words Learned", color: "#4CAF50" },
                                { value: "0", label: "Lessons Complete", color: "#2196F3" },
                                { value: "0", label: "Day Streak", color: "#FF9800" },
                                { value: proficiencyLevel.charAt(0).toUpperCase() + proficiencyLevel.slice(1), label: "Level", color: "#9C27B0" }
                            ]

                            Rectangle {
                                Layout.fillWidth: true
                                height: 80
                                color: "#252525"
                                radius: 12

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        text: modelData.value
                                        font.pixelSize: 24
                                        font.bold: true
                                        color: modelData.color
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    Text {
                                        text: modelData.label
                                        font.pixelSize: 12
                                        color: "#888"
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }
                            }
                        }
                    }

                    // Lesson categories
                    Text {
                        text: "Choose a Lesson Type"
                        font.pixelSize: 16
                        font.bold: true
                        color: "white"
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 3
                        columnSpacing: 16
                        rowSpacing: 16

                        Repeater {
                            model: [
                                { icon: "📖", title: "Vocabulary", desc: "Learn new words" },
                                { icon: "📝", title: "Grammar", desc: "Sentence structure" },
                                { icon: "💬", title: "Conversation", desc: "Practice speaking" },
                                { icon: "🗣️", title: "Pronunciation", desc: "Sound practice" },
                                { icon: "👂", title: "Listening", desc: "Comprehension" },
                                { icon: "✍️", title: "Writing", desc: "Written practice" }
                            ]

                            Rectangle {
                                Layout.fillWidth: true
                                height: 100
                                color: lessonMouse.containsMouse ? "#2A2A2A" : "#222"
                                radius: 12
                                border.color: lessonMouse.containsMouse ? "#FF6B35" : "#333"

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 8

                                    Text {
                                        text: modelData.icon
                                        font.pixelSize: 28
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    Text {
                                        text: modelData.title
                                        font.pixelSize: 14
                                        font.bold: true
                                        color: "white"
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    Text {
                                        text: modelData.desc
                                        font.pixelSize: 11
                                        color: "#888"
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }

                                MouseArea {
                                    id: lessonMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: console.log("Starting", modelData.title, "lesson")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
