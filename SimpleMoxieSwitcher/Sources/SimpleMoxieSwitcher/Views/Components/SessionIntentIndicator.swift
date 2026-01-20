import SwiftUI

/// Visual indicator showing the current session intent
struct SessionIntentIndicator: View {
    let sessionState: SessionState

    var body: some View {
        HStack(spacing: 12) {
            // Intent icon
            Text(sessionState.currentIntent.icon)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                // Intent name
                Text(sessionState.currentIntent.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)

                // Confidence bar
                HStack(spacing: 4) {
                    Text("Confidence:")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 4)

                            // Confidence fill
                            RoundedRectangle(cornerRadius: 2)
                                .fill(intentColor)
                                .frame(width: geometry.size.width * sessionState.confidence, height: 4)
                        }
                    }
                    .frame(width: 60, height: 4)

                    Text("\(Int(sessionState.confidence * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 35, alignment: .trailing)
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(intentColor.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(intentColor.opacity(0.3), lineWidth: 1)
        )
    }

    private var intentColor: Color {
        let rgb = sessionState.currentIntent.color
        return Color(
            red: rgb.red,
            green: rgb.green,
            blue: rgb.blue
        )
    }
}

/// Banner showing redirection suggestion when drift is detected
struct RedirectionSuggestionBanner: View {
    let suggestion: String
    let onAccept: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.title3)
                .foregroundColor(.orange)

            // Suggestion text
            Text(suggestion)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            // Actions
            HStack(spacing: 8) {
                Button(action: onDismiss) {
                    Text("Not now")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)

                Button(action: onAccept) {
                    Text("Yes!")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.orange.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

/// Compact session info for conversation list
struct SessionIntentBadge: View {
    let intent: SessionIntent

    var body: some View {
        HStack(spacing: 4) {
            Text(intent.icon)
                .font(.caption2)
            Text(intent.displayName)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(intentColor.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(intentColor.opacity(0.3), lineWidth: 1)
        )
    }

    private var intentColor: Color {
        let rgb = intent.color
        return Color(
            red: rgb.red,
            green: rgb.green,
            blue: rgb.blue
        )
    }
}

// MARK: - Previews
#if DEBUG
struct SessionIntentIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SessionIntentIndicator(
                sessionState: SessionState(intent: .play)
            )

            SessionIntentIndicator(
                sessionState: {
                    var state = SessionState(intent: .learn(subject: "math"))
                    state.confidence = 0.85
                    return state
                }()
            )

            SessionIntentIndicator(
                sessionState: {
                    var state = SessionState(intent: .comfort)
                    state.confidence = 0.92
                    return state
                }()
            )

            RedirectionSuggestionBanner(
                suggestion: "I notice you're curious about learning something new! Want to start a lesson together?",
                onAccept: {},
                onDismiss: {}
            )

            HStack {
                SessionIntentBadge(intent: .play)
                SessionIntentBadge(intent: .learn(subject: "science"))
                SessionIntentBadge(intent: .comfort)
            }
        }
        .padding()
        .frame(width: 400)
    }
}
#endif
