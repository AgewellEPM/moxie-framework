import SwiftUI

struct MovementControls: View {
    let onMove: (MoveDirection) -> Void

    var body: some View {
        VStack(spacing: 10) {
            DirectionButton(
                icon: "⬆️",
                text: "Forward",
                color: .blue
            ) {
                onMove(.forward)
            }

            HStack(spacing: 10) {
                DirectionButton(
                    icon: "⬅️",
                    text: "Left",
                    color: .blue
                ) {
                    onMove(.left)
                }

                DirectionButton(
                    icon: "➡️",
                    text: "Right",
                    color: .blue
                ) {
                    onMove(.right)
                }
            }

            DirectionButton(
                icon: "⬇️",
                text: "Backward",
                color: .blue
            ) {
                onMove(.backward)
            }
        }
    }
}

struct HeadControls: View {
    let onLook: (LookDirection) -> Void

    var body: some View {
        VStack(spacing: 10) {
            DirectionButton(
                icon: "⬆️",
                text: "Look Up",
                color: .purple
            ) {
                onLook(.up)
            }

            HStack(spacing: 10) {
                DirectionButton(
                    icon: "⬅️",
                    text: "Look Left",
                    color: .purple
                ) {
                    onLook(.left)
                }

                DirectionButton(
                    icon: "🎯",
                    text: "Center",
                    color: .purple
                ) {
                    onLook(.center)
                }

                DirectionButton(
                    icon: "➡️",
                    text: "Look Right",
                    color: .purple
                ) {
                    onLook(.right)
                }
            }

            DirectionButton(
                icon: "⬇️",
                text: "Look Down",
                color: .purple
            ) {
                onLook(.down)
            }
        }
    }
}

struct ArmControls: View {
    let onArmMove: (ArmSide, ArmPosition) -> Void

    var body: some View {
        HStack(spacing: 15) {
            // Left Arm
            VStack(spacing: 8) {
                Text("Left Arm")
                    .font(.caption)
                    .foregroundColor(.secondary)

                DirectionButton(
                    icon: "⬆️",
                    text: "Up",
                    color: .orange
                ) {
                    onArmMove(.left, .up)
                }

                DirectionButton(
                    icon: "⬇️",
                    text: "Down",
                    color: .orange
                ) {
                    onArmMove(.left, .down)
                }
            }

            // Right Arm
            VStack(spacing: 8) {
                Text("Right Arm")
                    .font(.caption)
                    .foregroundColor(.secondary)

                DirectionButton(
                    icon: "⬆️",
                    text: "Up",
                    color: .orange
                ) {
                    onArmMove(.right, .up)
                }

                DirectionButton(
                    icon: "⬇️",
                    text: "Down",
                    color: .orange
                ) {
                    onArmMove(.right, .down)
                }
            }
        }
    }
}

struct DirectionButton: View {
    let icon: String
    let text: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(icon) \(text)")
                .frame(maxWidth: .infinity)
                .padding()
                .background(color.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
}