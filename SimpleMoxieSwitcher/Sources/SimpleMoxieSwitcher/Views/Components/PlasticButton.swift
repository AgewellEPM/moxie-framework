import SwiftUI

/// Reusable plastic-styled button with glossy effect
struct PlasticButton: View {
    let titleKey: String  // Changed to key instead of localized string
    let emoji: String
    let baseColor: Color
    let action: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false
    @State private var breatheScale: CGFloat = 1.0
    @ObservedObject private var localization = LocalizationService.shared

    init(
        titleKey: String,  // Changed parameter name
        emoji: String,
        baseColor: Color = .blue,
        action: @escaping () -> Void
    ) {
        self.titleKey = titleKey
        self.emoji = emoji
        self.baseColor = baseColor
        self.action = action
    }

    var body: some View {
        Button(action: {
            // Trigger press animation
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }

            // Perform action and reset after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                action()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
        }) {
            VStack(spacing: 10) {
                Text(emoji)
                    .font(.system(size: isPressed ? 45 : (isHovered ? 60 : 50)))
                    .scaleEffect(isHovered ? breatheScale : 1.0)
                    .rotationEffect(.degrees(isHovered ? sin(Double(breatheScale) * Double.pi * 2.0) * 5.0 : 0))
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: breatheScale)
                Text(localization.localize(titleKey))  // Localize here so it updates
                    .font(.caption)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .foregroundColor(.white)
            .frame(width: 150, height: 100)
            .background(plasticBackground)
            .cornerRadius(18)
            .overlay(glossyOverlay)
            // Enhanced shadow effects with pressed state
            .shadow(color: isPressed ? baseColor : baseColor.opacity(isHovered ? 0.9 : 0.6),
                    radius: isPressed ? 30 : (isHovered ? 20 : 15),
                    x: 0,
                    y: isPressed ? 5 : (isHovered ? 12 : 8))
            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
            // Additional glow when pressed
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isPressed ? baseColor.opacity(0.8) : Color.clear, lineWidth: 3)
                    .blur(radius: isPressed ? 5 : 0)
                    .animation(.easeInOut(duration: 0.1), value: isPressed)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.92 : (isHovered ? 1.15 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                // Start breathing animation
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    breatheScale = 1.15
                }
            } else {
                // Stop breathing animation
                withAnimation(.easeOut(duration: 0.3)) {
                    breatheScale = 1.0
                }
            }
        }
    }

    private var plasticBackground: some View {
        ZStack {
            // Base plastic color gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    baseColor.opacity(0.9),
                    baseColor.opacity(0.7)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )

            // Glossy highlight at top
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.6),
                    Color.white.opacity(0.0)
                ]),
                startPoint: .top,
                endPoint: .center
            )
        }
    }

    private var glossyOverlay: some View {
        RoundedRectangle(cornerRadius: 18)
            .stroke(Color.white.opacity(0.6), lineWidth: 2)
            .blur(radius: 1)
    }
}

// MARK: - Convenience Extensions
extension PlasticButton {
    static func customCreator(action: @escaping () -> Void) -> PlasticButton {
        PlasticButton(
            titleKey: "custom_creator",
            emoji: "✨",
            baseColor: Color(red: 0.8, green: 0.2, blue: 0.9),  // Purple/Magenta
            action: action
        )
    }

    static func childProfile(action: @escaping () -> Void) -> PlasticButton {
        PlasticButton(
            titleKey: "child_profile",
            emoji: "👶",
            baseColor: Color(red: 0.3, green: 0.7, blue: 0.95),  // Light Blue
            action: action
        )
    }

    static func appearance(action: @escaping () -> Void) -> PlasticButton {
        PlasticButton(
            titleKey: "appearance",
            emoji: "💇",
            baseColor: Color(red: 0.15, green: 0.45, blue: 0.75),  // Darker Blue
            action: action
        )
    }

    static func chat(action: @escaping () -> Void) -> PlasticButton {
        PlasticButton(
            titleKey: "conversations",
            emoji: "💬",
            baseColor: Color(red: 0.2, green: 0.8, blue: 0.4),  // Green
            action: action
        )
    }

    // Big prominent button for starting conversations
    static func startConversation(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text("💬")
                    .font(.system(size: 50))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Start Conversation")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Continue talking with Moxie")
                        .font(.caption)
                        .opacity(0.8)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.2, green: 0.8, blue: 0.4),
                        Color(red: 0.1, green: 0.7, blue: 0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .blur(radius: 1)
            )
            .shadow(color: Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.6), radius: 20, x: 0, y: 10)
            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    static func settings(action: @escaping () -> Void) -> PlasticButton {
        PlasticButton(
            titleKey: "settings",
            emoji: "⚙️",
            baseColor: Color(red: 0.95, green: 0.75, blue: 0.15),  // Gold/Yellow
            action: action
        )
    }

    static func storyTime(action: @escaping () -> Void) -> PlasticButton {
        PlasticButton(
            titleKey: "story_time",
            emoji: "📚",
            baseColor: Color(red: 0.6, green: 0.3, blue: 0.9),  // Purple
            action: action
        )
    }

    static func learning(action: @escaping () -> Void) -> PlasticButton {
        PlasticButton(
            titleKey: "learning",
            emoji: "🎓",
            baseColor: Color(red: 0.15, green: 0.7, blue: 0.25),  // Forest Green
            action: action
        )
    }

    static func language(action: @escaping () -> Void) -> PlasticButton {
        PlasticButton(
            titleKey: "language",
            emoji: "🌍",
            baseColor: Color(red: 0.5, green: 0.3, blue: 0.85),  // Indigo/Purple
            action: action
        )
    }

    static func music(action: @escaping () -> Void) -> PlasticButton {
        PlasticButton(
            titleKey: "music",
            emoji: "🎤",
            baseColor: Color(red: 0.95, green: 0.25, blue: 0.5),  // Hot Pink
            action: action
        )
    }

    static func smartHome(action: @escaping () -> Void) -> PlasticButton {
        PlasticButton(
            titleKey: "smart_home",
            emoji: "🏠",
            baseColor: Color(red: 0.35, green: 0.55, blue: 0.85),  // Blue
            action: action
        )
    }

    static func puppetMode(action: @escaping () -> Void) -> PlasticButton {
        PlasticButton(
            titleKey: "puppet_mode",
            emoji: "🎭",
            baseColor: Color(red: 0.9, green: 0.45, blue: 0.15),  // Orange/Brown
            action: action
        )
    }

    static func games(action: @escaping () -> Void) -> PlasticButton {
        PlasticButton(
            titleKey: "games",
            emoji: "🎮",
            baseColor: Color(red: 0.95, green: 0.4, blue: 0.2),  // Orange/Red
            action: action
        )
    }

    static func learningTile(tile: LearningTile, action: @escaping () -> Void) -> PlasticButton {
        PlasticButton(
            titleKey: tile.title,  // Assuming tile.title is already a key
            emoji: tile.emoji,
            baseColor: Color(red: 0.2, green: 0.7, blue: 0.3),
            action: action
        )
    }

    static func storyTile(tile: StoryTile, action: @escaping () -> Void) -> PlasticButton {
        PlasticButton(
            titleKey: tile.title,  // Assuming tile.title is already a key
            emoji: tile.emoji,
            baseColor: Color(red: 0.6, green: 0.4, blue: 0.9),
            action: action
        )
    }

    static func startDocker(action: @escaping () -> Void) -> PlasticButton {
        PlasticButton(
            titleKey: "start_docker",
            emoji: "🐳",
            baseColor: Color(red: 0.0, green: 0.5, blue: 0.9),  // Docker Blue
            action: action
        )
    }

    static func documentation(action: @escaping () -> Void) -> PlasticButton {
        PlasticButton(
            titleKey: "documentation",
            emoji: "📖",
            baseColor: Color(red: 0.4, green: 0.6, blue: 0.85),  // Book Blue
            action: action
        )
    }

    static func lyricMode(action: @escaping () -> Void) -> PlasticButton {
        PlasticButton(
            titleKey: "lyric_mode",
            emoji: "🎵",
            baseColor: Color(red: 0.85, green: 0.3, blue: 0.7),  // Pink/Magenta
            action: action
        )
    }
}