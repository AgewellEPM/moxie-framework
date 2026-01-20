import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    color: "#0A0A0A"

    gradient: Gradient {
        GradientStop { position: 0.0; color: "#1A0033" }
        GradientStop { position: 0.5; color: "#003366" }
        GradientStop { position: 1.0; color: "#0A0A0A" }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // Header
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "🗣️ Conversation Practice"
                font.pixelSize: 32
                font.bold: true
                color: "white"
            }

            Item { Layout.fillWidth: true }

            ComboBox {
                id: languageSelector
                model: ["Spanish", "French", "German", "Italian", "Japanese", "Chinese"]
                currentIndex: 0
            }

            ComboBox {
                id: levelSelector
                model: ["Beginner", "Elementary", "Intermediate", "Advanced"]
                currentIndex: 0
            }
        }

        // Scenario selector
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            color: "#1A1A1A"
            radius: 12

            GridLayout {
                anchors.fill: parent
                anchors.margins: 15
                columns: 4
                columnSpacing: 10

                Repeater {
                    model: [
                        { icon: "🏪", name: "Shopping" },
                        { icon: "🍽️", name: "Restaurant" },
                        { icon: "✈️", name: "Travel" },
                        { icon: "👋", name: "Greetings" },
                        { icon: "🏥", name: "Medical" },
                        { icon: "🎭", name: "Entertainment" },
                        { icon: "🏢", name: "Business" },
                        { icon: "🏠", name: "Home" }
                    ]

                    delegate: Button {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        text: modelData.icon + " " + modelData.name

                        background: Rectangle {
                            color: parent.hovered ? "#2A2A2A" : "#1A1A1A"
                            border.color: "#3A3A3A"
                            radius: 6
                        }

                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: loadScenario(modelData.name)
                    }
                }
            }
        }

        // Conversation area
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#1A1A1A"
            radius: 12

            ScrollView {
                anchors.fill: parent
                anchors.margins: 15

                ListView {
                    id: conversationView
                    model: ListModel {
                        ListElement { role: "ai"; text: "¡Hola! ¿Cómo estás hoy?"; translation: "Hello! How are you today?" }
                    }

                    delegate: Item {
                        width: ListView.view.width
                        height: bubble.height + 10

                        Rectangle {
                            id: bubble
                            width: parent.width * 0.7
                            height: contentColumn.height + 20
                            x: model.role === "user" ? parent.width - width : 0
                            radius: 12
                            color: model.role === "user" ? "#2A5BA5" : "#2A2A2A"

                            Column {
                                id: contentColumn
                                anchors.centerIn: parent
                                width: parent.width - 20
                                spacing: 5

                                Text {
                                    text: model.text
                                    color: "white"
                                    font.pixelSize: 16
                                    wrapMode: Text.Wrap
                                    width: parent.width
                                }

                                Text {
                                    text: model.translation || ""
                                    color: "#888"
                                    font.pixelSize: 14
                                    font.italic: true
                                    wrapMode: Text.Wrap
                                    width: parent.width
                                    visible: text !== ""
                                }
                            }
                        }
                    }
                }
            }
        }

        // Input area
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            TextField {
                id: inputField
                Layout.fillWidth: true
                placeholderText: "Type your response..."
                color: "white"

                background: Rectangle {
                    color: "#1A1A1A"
                    border.color: "#3A3A3A"
                    radius: 8
                }
            }

            Button {
                text: "🎤 Speak"
                onClicked: startVoiceInput()

                background: Rectangle {
                    color: parent.hovered ? "#3A5BA5" : "#2A5BA5"
                    radius: 8
                }

                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Button {
                text: "Send"
                onClicked: sendMessage()

                background: Rectangle {
                    color: parent.hovered ? "#4CAF50" : "#388E3C"
                    radius: 8
                }

                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        // Hints and tools
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Button {
                text: "💡 Hint"
                onClicked: showHint()
            }

            Button {
                text: "📖 Phrase Book"
                onClicked: openPhraseBook()
            }

            Button {
                text: "🔊 Pronunciation"
                onClicked: playPronunciation()
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "Streak: 🔥 5 days"
                color: "#FFA500"
                font.pixelSize: 14
            }
        }
    }

    function loadScenario(scenario) {
        console.log("Loading scenario:", scenario)
    }

    function sendMessage() {
        if (inputField.text.trim() !== "") {
            conversationView.model.append({
                role: "user",
                text: inputField.text,
                translation: ""
            })
            inputField.text = ""
        }
    }

    function startVoiceInput() {
        console.log("Starting voice input...")
    }

    function showHint() {
        console.log("Showing hint...")
    }

    function openPhraseBook() {
        console.log("Opening phrase book...")
    }

    function playPronunciation() {
        console.log("Playing pronunciation...")
    }
}