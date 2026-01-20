import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: storyRoot
    color: "#0A0A0A"

    property var storySegments: []
    property var currentChoices: []
    property bool isLoading: false
    property string currentGenre: "Adventure"

    ScrollView {
        anchors.fill: parent
        anchors.margins: 30
        clip: true

        ColumnLayout {
            width: storyRoot.width - 60
            spacing: 24

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                Text {
                    text: "📖 Story Time"
                    font.pixelSize: 32
                    font.bold: true
                    color: "white"
                }

                Item { Layout.fillWidth: true }

                ComboBox {
                    id: genreSelector
                    model: ["Adventure", "Fantasy", "Mystery", "Science Fiction", "Fairy Tale"]
                    currentIndex: 0
                    onCurrentTextChanged: currentGenre = currentText

                    background: Rectangle {
                        color: "#2A2A2A"
                        radius: 8
                        border.color: "#444"
                    }

                    contentItem: Text {
                        text: genreSelector.displayText
                        color: "white"
                        padding: 10
                    }
                }

                Button {
                    text: "🔄 New Story"
                    onClicked: startNewStory()

                    background: Rectangle {
                        color: parent.hovered ? "#FF8C00" : "#FF6B35"
                        radius: 8
                    }

                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            // Story display area
            Rectangle {
                Layout.fillWidth: true
                Layout.minimumHeight: 400
                color: "#1A1A1A"
                radius: 16
                border.color: "#333"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 16

                    // Story content
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        Text {
                            id: storyText
                            width: parent.width
                            text: storySegments.length > 0 ? storySegments.join("\n\n") :
                                  "Click 'New Story' to begin your interactive adventure!\n\n" +
                                  "You'll make choices that shape the story as it unfolds. " +
                                  "Each decision leads to a unique path in your tale."
                            color: "white"
                            font.pixelSize: 16
                            lineHeight: 1.6
                            wrapMode: Text.WordWrap
                        }
                    }

                    // Loading indicator
                    BusyIndicator {
                        Layout.alignment: Qt.AlignHCenter
                        running: isLoading
                        visible: isLoading
                    }

                    // Choice buttons
                    Rectangle {
                        Layout.fillWidth: true
                        height: choicesColumn.height + 24
                        color: "#252525"
                        radius: 12
                        visible: currentChoices.length > 0

                        Column {
                            id: choicesColumn
                            anchors.centerIn: parent
                            width: parent.width - 48
                            spacing: 12

                            Text {
                                text: "What do you do?"
                                color: "#AAAAAA"
                                font.pixelSize: 14
                                font.bold: true
                            }

                            Repeater {
                                model: currentChoices

                                Button {
                                    width: choicesColumn.width
                                    height: 50
                                    text: modelData

                                    background: Rectangle {
                                        color: parent.hovered ? "#4A4A4A" : "#3A3A3A"
                                        radius: 10
                                        border.color: parent.hovered ? "#FF6B35" : "#555"
                                        border.width: parent.hovered ? 2 : 1
                                    }

                                    contentItem: Text {
                                        text: parent.text
                                        color: "white"
                                        font.pixelSize: 14
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    onClicked: makeChoice(index)
                                }
                            }
                        }
                    }
                }
            }

            // Story stats
            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                Rectangle {
                    Layout.preferredWidth: 150
                    height: 80
                    color: "#1A1A1A"
                    radius: 12
                    border.color: "#333"

                    Column {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: storySegments.length.toString()
                            font.pixelSize: 28
                            font.bold: true
                            color: "#FF6B35"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: "Chapters"
                            color: "#888"
                            font.pixelSize: 12
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 150
                    height: 80
                    color: "#1A1A1A"
                    radius: 12
                    border.color: "#333"

                    Column {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: currentGenre
                            font.pixelSize: 16
                            font.bold: true
                            color: "#9B59B6"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: "Genre"
                            color: "#888"
                            font.pixelSize: 12
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }
    }

    function startNewStory() {
        storySegments = []
        currentChoices = []
        isLoading = true

        // Simulate story generation (would call AI service)
        Qt.callLater(function() {
            storySegments = [
                "Once upon a time, in a magical kingdom far away, there lived a young adventurer named Alex. " +
                "The kingdom was peaceful, but rumors had spread about a mysterious treasure hidden in the Enchanted Forest.",

                "One morning, Alex woke up to find a strange map tucked under their pillow. " +
                "The map showed a path through the forest, leading to what appeared to be an ancient temple."
            ]
            currentChoices = [
                "Follow the map into the forest",
                "Show the map to the village elder",
                "Ignore the map and continue daily routine"
            ]
            isLoading = false
        })
    }

    function makeChoice(index) {
        var choice = currentChoices[index]
        storySegments.push("You decided to: " + choice)
        isLoading = true
        currentChoices = []

        // Simulate continuing the story
        Qt.callLater(function() {
            if (index === 0) {
                storySegments.push("Alex ventured into the forest, following the ancient map. " +
                    "The trees grew taller and the path darker, but determination drove them forward.")
                currentChoices = ["Continue deeper into the forest", "Look for a safe place to rest"]
            } else if (index === 1) {
                storySegments.push("The village elder studied the map with wide eyes. " +
                    "'This is the map of the Lost Temple!' he exclaimed. 'Many have sought it, but none have returned.'")
                currentChoices = ["Ask for the elder's guidance", "Take the map and leave alone"]
            } else {
                storySegments.push("Alex tried to ignore the mysterious map, but curiosity was too strong. " +
                    "That night, dreams of adventure filled their sleep.")
                currentChoices = ["Wake up and follow the map", "Burn the map and forget about it"]
            }
            isLoading = false
        })
    }
}
