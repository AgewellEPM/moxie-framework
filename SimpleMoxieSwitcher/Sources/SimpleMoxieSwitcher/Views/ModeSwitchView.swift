import SwiftUI

// MARK: - Mode Switch View (Badge Component)
struct ModeSwitchView: View {
    @StateObject private var modeContext = ModeContext.shared
    @State private var showParentAuth = false
    @State private var isAnimating = false
    @State private var breatheScale: CGFloat = 1.0
    @State private var childName: String = ""

    var body: some View {
        HStack(spacing: 12) {
            // Mode badge
            modeBadge
                .onTapGesture {
                    handleModeSwitch()
                }
                .accessibilityElement()
                .accessibilityLabel("Current mode: \(modeContext.currentMode.displayName)")
                .accessibilityHint("Tap to switch modes")

            // Time lock indicator
            if modeContext.isCurrentlyLocked() {
                timeLockIndicator
            }
        }
        .sheet(isPresented: $showParentAuth) {
            ParentAuthView {
                // Successfully authenticated - mode already switched
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isAnimating = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    isAnimating = false
                }
            }
        }
        .onAppear {
            loadChildName()
            startBreathingAnimation()
        }
    }

    // MARK: - Mode Badge
    private var modeBadge: some View {
        ZStack {
            // Background with gradient
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: modeContext.currentMode == .child ?
                            [Color(hex: "#00D4FF"), Color(hex: "#00B8E6")] :
                            [Color(hex: "#9D4EDD"), Color(hex: "#7B2CBF")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(
                    color: modeContext.currentMode == .child ?
                        Color(hex: "#00D4FF").opacity(0.6) :
                        Color(hex: "#9D4EDD").opacity(0.6),
                    radius: 10,
                    x: 0,
                    y: 5
                )

            // Content
            HStack(spacing: 8) {
                // Icon
                Text(modeContext.currentMode == .child ? "👋" : "🔒")
                    .font(.system(size: 20))
                    .scaleEffect(breatheScale)

                // Text
                if modeContext.currentMode == .child {
                    Text("Hi \(childName.isEmpty ? "Friend" : childName)!")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                } else {
                    Text("Parent Console")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }

                // Switch indicator
                Image(systemName: "chevron.down.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .rotationEffect(.degrees(isAnimating ? 180 : 0))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(height: 40)
        .scaleEffect(isAnimating ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAnimating)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: modeContext.currentMode.rawValue)
    }

    // MARK: - Time Lock Indicator
    private var timeLockIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.clock.fill")
                .font(.system(size: 14))
                .foregroundColor(.orange)

            if let timeRemaining = modeContext.timeUntilNextUnlock() {
                Text("Locked until \(formatTime(timeRemaining))")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else {
                Text("Time restricted")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(16)
    }

    // MARK: - Helper Methods

    private func handleModeSwitch() {
        if modeContext.currentMode == .child {
            // Switching to parent mode - require PIN
            showParentAuth = true
        } else {
            // Switching to child mode - no PIN required
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                modeContext.switchMode(to: .child)
                isAnimating = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                isAnimating = false
            }
        }
    }

    private func startBreathingAnimation() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            breatheScale = 1.15
        }
    }

    private func loadChildName() {
        // Load child profile name
        if let profileData = UserDefaults.standard.data(forKey: "activeChildProfile"),
           let profile = try? JSONDecoder().decode(ChildProfile.self, from: profileData) {
            childName = profile.name
        }
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        let futureDate = Date().addingTimeInterval(interval)
        return formatter.string(from: futureDate)
    }
}

// MARK: - Standalone Mode Switcher View
struct StandaloneModeSwitcherView: View {
    @StateObject private var modeContext = ModeContext.shared
    @State private var showParentAuth = false
    @State private var pulseAnimation = false

    var body: some View {
        ZStack {
            // Background gradient based on mode
            LinearGradient(
                colors: modeContext.currentMode == .child ?
                    [Color(hex: "#E0F7FA"), Color(hex: "#B2EBF2")] :
                    [Color(hex: "#F3E5F5"), Color(hex: "#E1BEE7")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 1.0), value: modeContext.currentMode)

            VStack(spacing: 40) {
                // Current mode display
                VStack(spacing: 20) {
                    // Mode icon
                    ZStack {
                        Circle()
                            .fill(
                                modeContext.currentMode == .child ?
                                    Color(hex: "#00D4FF").opacity(0.2) :
                                    Color(hex: "#9D4EDD").opacity(0.2)
                            )
                            .frame(width: 120, height: 120)
                            .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)

                        Text(modeContext.currentMode == .child ? "🧒" : "👨‍👩‍👧")
                            .font(.system(size: 60))
                    }

                    // Mode title
                    Text(modeContext.currentMode.displayName)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(
                            modeContext.currentMode == .child ?
                                Color(hex: "#00D4FF") :
                                Color(hex: "#9D4EDD")
                        )

                    // Mode description
                    Text(modeDescription)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                // Switch button
                Button(action: {
                    if modeContext.currentMode == .child {
                        showParentAuth = true
                    } else {
                        switchToChildMode()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: switchIcon)
                            .font(.title3)
                        Text(switchButtonTitle)
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: modeContext.currentMode == .child ?
                                [Color(hex: "#9D4EDD"), Color(hex: "#7B2CBF")] :
                                [Color(hex: "#00D4FF"), Color(hex: "#00B8E6")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(
                        color: modeContext.currentMode == .child ?
                            Color(hex: "#9D4EDD").opacity(0.4) :
                            Color(hex: "#00D4FF").opacity(0.4),
                        radius: 15,
                        x: 0,
                        y: 8
                    )
                }
                .buttonStyle(.plain)
                .scaleEffect(pulseAnimation ? 1.05 : 1.0)

                // Security info
                if modeContext.currentMode == .child {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("PIN required for Parent Console")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .sheet(isPresented: $showParentAuth) {
            ParentAuthView {
                // Successfully authenticated
            }
        }
        .onAppear {
            pulseAnimation = true
        }
    }

    // MARK: - Helper Properties & Methods

    private var modeDescription: String {
        if modeContext.currentMode == .child {
            return "Safe, fun mode for children with age-appropriate content and features"
        } else {
            return "Full access to parental controls, conversation logs, and settings"
        }
    }

    private var switchButtonTitle: String {
        modeContext.currentMode == .child ?
            "Switch to Parent Console" :
            "Switch to Child Mode"
    }

    private var switchIcon: String {
        modeContext.currentMode == .child ?
            "person.2.fill" :
            "face.smiling.fill"
    }

    private func switchToChildMode() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            modeContext.switchMode(to: .child)
        }
    }
}

// MARK: - Floating Mode Badge (For ContentView Integration)
struct FloatingModeBadge: View {
    @StateObject private var modeContext = ModeContext.shared
    @State private var showModeSwitcher = false

    var body: some View {
        VStack {
            HStack {
                Spacer()
                ModeSwitchView()
                    .padding(.trailing, 20)
                    .padding(.top, 20)
            }
            Spacer()
        }
        .allowsHitTesting(true)
        .sheet(isPresented: $showModeSwitcher) {
            StandaloneModeSwitcherView()
                .frame(minWidth: 500, minHeight: 600)
        }
    }
}

// MARK: - Preview
struct ModeSwitchView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Badge preview
            ModeSwitchView()
                .padding()
                .background(Color.gray.opacity(0.2))
                .previewDisplayName("Mode Badge")

            // Full switcher preview
            StandaloneModeSwitcherView()
                .previewDisplayName("Mode Switcher")
        }
    }
}