import SwiftUI

// MARK: - Mode Indicator Badge
struct ModeIndicatorBadge: View {
    @ObservedObject var modeContext = ModeContext.shared

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            Text(modeContext.currentMode.displayName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(ModeColors.primary(for: modeContext.currentMode))
        )
        .shadow(
            color: ModeColors.primary(for: modeContext.currentMode).opacity(0.3),
            radius: 4,
            x: 0,
            y: 2
        )
        .animation(ModeAnimations.modeTransition, value: modeContext.currentMode)
    }

    private var iconName: String {
        switch modeContext.currentMode {
        case .child:
            return "star.fill"
        case .adult:
            return "lock.shield.fill"
        }
    }
}

// MARK: - Mode Switch Banner
struct ModeSwitchBanner: View {
    let previousMode: OperationalMode
    let newMode: OperationalMode
    @State private var isVisible = true

    var body: some View {
        if isVisible {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 16, weight: .semibold))

                    Text("Switched to \(newMode.displayName)")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    ModeColors.gradient(for: newMode)
                        .cornerRadius(8)
                )
                .shadow(radius: 4)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            .onAppear {
                // Auto-dismiss after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        isVisible = false
                    }
                }
            }
        }
    }
}

// MARK: - Mode-Aware Message Bubble
struct ModeAwareMessageBubble: View {
    let message: ChatMessage
    @ObservedObject var modeContext = ModeContext.shared
    let personality: Personality?

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if message.role == "assistant" {
                // Moxie's avatar with mode-specific styling
                avatarView
            }

            VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: 4) {
                // Message content with emotion processing
                messageContent

                // Timestamp
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(ModeTypography.caption(for: modeContext.currentMode))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: message.role == "user" ? .trailing : .leading)

            if message.role == "user" {
                Spacer()
            }
        }
        .padding(.horizontal)
    }

    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(ModeColors.gradient(for: modeContext.currentMode))
                .frame(width: 36, height: 36)

            if modeContext.currentMode == .child {
                Text(personality?.emoji ?? "🤖")
                    .font(.system(size: 20))
            } else {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .shadow(
            color: ModeColors.primary(for: modeContext.currentMode).opacity(0.2),
            radius: 2,
            x: 0,
            y: 1
        )
    }

    private var messageContent: some View {
        Group {
            if message.role == "assistant" && modeContext.currentMode == .child {
                // Process emotion tags in child mode
                processedMessageText
            } else {
                // Regular text for user messages and adult mode
                Text(message.content)
                    .font(ModeTypography.body(for: modeContext.currentMode))
            }
        }
        .foregroundColor(message.role == "user" ? .primary : ModeColors.textColor(for: modeContext.currentMode))
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(bubbleColor)
        )
    }

    private var processedMessageText: some View {
        let (emotion, cleanContent) = extractEmotion(from: message.content)

        return VStack(alignment: .leading, spacing: 4) {
            if let emotion = emotion {
                HStack(spacing: 4) {
                    emotionIcon(for: emotion)
                        .font(.system(size: 14))
                    Text(emotion.capitalized)
                        .font(ModeTypography.caption(for: modeContext.currentMode))
                        .foregroundColor(ModeColors.accent(for: modeContext.currentMode))
                }
            }

            Text(cleanContent)
                .font(ModeTypography.body(for: modeContext.currentMode))
        }
    }

    private var bubbleColor: Color {
        if message.role == "user" {
            return Color.gray.opacity(0.2)
        } else {
            return ModeColors.bubble(for: modeContext.currentMode)
        }
    }

    private func extractEmotion(from content: String) -> (emotion: String?, cleanContent: String) {
        // Extract emotion tags like [emotion:happy]
        let pattern = #"\[emotion:(\w+)\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return (nil, content)
        }

        let nsString = content as NSString
        let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: nsString.length))

        guard let match = matches.first else {
            return (nil, content)
        }

        let emotionRange = match.range(at: 1)
        let emotion = nsString.substring(with: emotionRange)

        // Remove the emotion tag from the content
        let cleanContent = regex.stringByReplacingMatches(
            in: content,
            options: [],
            range: NSRange(location: 0, length: nsString.length),
            withTemplate: ""
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        return (emotion, cleanContent)
    }

    private func emotionIcon(for emotion: String) -> Image {
        let iconName = switch emotion.lowercased() {
        case "happy": "face.smiling"
        case "excited": "star.fill"
        case "curious": "questionmark.circle"
        case "surprised": "exclamationmark.circle"
        case "confused": "questionmark.square"
        case "neutral": "minus.circle"
        default: "face.smiling"
        }
        return Image(systemName: iconName)
    }
}

// MARK: - Mode Lock Indicator
struct ModeLockIndicator: View {
    @ObservedObject var modeContext = ModeContext.shared

    var body: some View {
        if modeContext.isCurrentlyLocked() {
            VStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 48))
                    .foregroundColor(ModeColors.primary(for: .child))

                Text("Moxie is taking a break")
                    .font(ModeTypography.title(for: .child))
                    .foregroundColor(ModeColors.textColor(for: .child))

                if let timeUntilUnlock = modeContext.timeUntilNextUnlock() {
                    Text("Back in \(formatTime(timeUntilUnlock))")
                        .font(ModeTypography.body(for: .child))
                        .foregroundColor(.secondary)
                }

                Button(action: {
                    // This would trigger the PIN entry screen
                    NotificationCenter.default.post(name: .requestParentMode, object: nil)
                }) {
                    Text("Parent Access")
                        .font(ModeTypography.button(for: .adult))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            ModeColors.gradient(for: .adult)
                                .cornerRadius(8)
                        )
                }
                .padding(.top, 8)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(radius: 10)
            )
        }
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") \(minutes) minute\(minutes == 1 ? "" : "s")"
        } else {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let requestParentMode = Notification.Name("requestParentMode")
    static let modeSwitched = Notification.Name("modeSwitched")
}

// MARK: - Preview Provider
struct ModeIndicatorBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ModeIndicatorBadge()

            ModeSwitchBanner(
                previousMode: .child,
                newMode: .adult
            )

            ModeAwareMessageBubble(
                message: ChatMessage(
                    role: "assistant",
                    content: "[emotion:happy] Hello! I'm excited to chat with you today! What would you like to talk about?",
                    timestamp: Date()
                ),
                personality: Personality.defaultMoxie
            )

            ModeLockIndicator()
        }
        .padding()
    }
}