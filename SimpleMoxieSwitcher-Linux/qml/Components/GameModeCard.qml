import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root
    width: (parent.width - 16) / 2
    height: 280
    radius: 16

    property string gameType: ""
    property string icon: "🎮"
    property string description: ""
    property int gamesPlayed: 0
    property color gradientStart: "#9B59B6"
    property color gradientEnd: "#E91E63"

    signal clicked()

    gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.rgba(root.gradientStart.r, root.gradientStart.g, root.gradientStart.b, 0.3) }
        GradientStop { position: 1.0; color: Qt.rgba(root.gradientEnd.r, root.gradientEnd.g, root.gradientEnd.b, 0.3) }
    }

    // Glass overlay
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: mouseArea.containsMouse ? "#FFFFFF15" : "#FFFFFF10"

        Behavior on color {
            ColorAnimation { duration: 200 }
        }
    }

    // Neon glow on hover
    layer.enabled: mouseArea.containsMouse
    layer.effect: ShaderEffect {
        property color glowColor: root.gradientStart
        fragmentShader: "
            uniform lowp float qt_Opacity;
            uniform sampler2D source;
            varying highp vec2 qt_TexCoord0;
            void main() {
                gl_FragColor = texture2D(source, qt_TexCoord0) * qt_Opacity;
            }
        "
    }

    Column {
        anchors.centerIn: parent
        spacing: 16
        width: parent.width - 40

        Text {
            text: root.icon
            font.pixelSize: 60
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Column {
            width: parent.width
            spacing: 4

            Text {
                text: root.gameType
                font.pixelSize: 18
                font.bold: true
                color: "white"
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
                wrapMode: Text.WordWrap
            }

            Text {
                text: root.description
                font.pixelSize: 13
                color: "#AAAAAA"
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
                wrapMode: Text.WordWrap
                maximumLineCount: 3
            }
        }

        Text {
            text: root.gamesPlayed > 0 ? "Played " + root.gamesPlayed + " time" + (root.gamesPlayed > 1 ? "s" : "") : ""
            font.pixelSize: 11
            color: "#999999"
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.gamesPlayed > 0
        }

        Rectangle {
            width: 120
            height: 40
            radius: 20
            anchors.horizontalCenter: parent.horizontalCenter

            gradient: Gradient {
                GradientStop { position: 0.0; color: root.gradientStart }
                GradientStop { position: 1.0; color: root.gradientEnd }
            }

            Row {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: "Play"
                    font.pixelSize: 14
                    font.bold: true
                    color: "white"
                }

                Text {
                    text: "→"
                    font.pixelSize: 14
                    color: "white"
                }
            }
        }
    }

    // Border
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.color: mouseArea.containsMouse ? Qt.rgba(root.gradientStart.r, root.gradientStart.g, root.gradientStart.b, 0.8) : "#FFFFFF30"
        border.width: mouseArea.containsMouse ? 2 : 1

        Behavior on border.color {
            ColorAnimation { duration: 200 }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    // Scale animation
    scale: mouseArea.containsMouse ? 1.05 : 1.0

    Behavior on scale {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }
}
