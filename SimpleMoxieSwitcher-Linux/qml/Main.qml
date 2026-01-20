import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import "Components"

ApplicationWindow {
    id: root
    visible: true
    width: 1200
    height: 800
    title: "OpenMoxie Controller"
    color: "#1A1A1A"

    // Navigation sidebar
    Rectangle {
        id: sidebar
        width: 280
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#2A1A5A" }
            GradientStop { position: 1.0; color: "#0A0A0A" }
        }

        Column {
            anchors {
                fill: parent
                margins: 20
            }
            spacing: 10

            // Logo and title
            Item {
                width: parent.width
                height: 100

                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: "🤖"
                        font.pixelSize: 48
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: "OpenMoxie"
                        font.pixelSize: 24
                        font.bold: true
                        color: "white"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: "Controller"
                        font.pixelSize: 14
                        color: "#AAAAAA"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#333333"
            }

            // Navigation buttons
            NavButton {
                text: "💬 Chat"
                icon: "chat"
                onClicked: stackView.push("qrc:/qml/Chat/ChatInterfaceView.qml")
            }

            NavButton {
                text: "🎮 Games"
                icon: "games"
                onClicked: stackView.push("qrc:/qml/Games/GamesMenuView.qml")
            }

            NavButton {
                text: "📚 Language Learning"
                icon: "language"
                onClicked: stackView.push("qrc:/qml/LanguageLearning/LanguageLearningWizardView.qml")
            }

            NavButton {
                text: "📖 Story Time"
                icon: "story"
                onClicked: stackView.push("qrc:/qml/Story/StoryTimeView.qml")
            }

            NavButton {
                text: "🎛️ Controls"
                icon: "controls"
                onClicked: stackView.push("qrc:/qml/Controls/ControlsView.qml")
            }

            NavButton {
                text: "📊 Usage Analytics"
                icon: "analytics"
                onClicked: stackView.push("qrc:/qml/Analytics/UsageView.qml")
            }

            NavButton {
                text: "🧠 Memory"
                icon: "memory"
                onClicked: stackView.push("qrc:/qml/Analytics/MemoryView.qml")
            }

            Item {
                width: parent.width
                height: 20
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#333333"
            }

            NavButton {
                text: "⚙️ Settings"
                icon: "settings"
                onClicked: stackView.push("qrc:/qml/Settings/SettingsView.qml")
            }
        }
    }

    // Main content area
    Rectangle {
        anchors {
            left: sidebar.right
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }
        color: "#0A0A0A"

        StackView {
            id: stackView
            anchors.fill: parent
            initialItem: welcomeView
        }
    }

    // Welcome view component
    Component {
        id: welcomeView

        Rectangle {
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#FF6B35" }
                GradientStop { position: 0.5; color: "#F7931E" }
                GradientStop { position: 1.0; color: "#FDC830" }
            }

            Column {
                anchors.centerIn: parent
                spacing: 30

                Text {
                    text: "🤖"
                    font.pixelSize: 120
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "Welcome to OpenMoxie!"
                    font.pixelSize: 42
                    font.bold: true
                    color: "white"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "Select a feature from the sidebar to get started"
                    font.pixelSize: 18
                    color: "white"
                    opacity: 0.9
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Rectangle {
                    width: 300
                    height: 60
                    radius: 30
                    color: "white"
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        text: "🎮 Start Playing Games"
                        font.pixelSize: 16
                        font.bold: true
                        color: "#FF6B35"
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: stackView.push("qrc:/qml/Games/GamesMenuView.qml")
                    }
                }
            }
        }
    }
}
