import SwiftUI

struct DocumentationView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.4), Color.purple.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                Divider()

                // Content area
                ScrollView {
                    VStack(spacing: 24) {
                        Text("📖 Documentation")
                            .font(.system(size: 48))
                            .padding(.top, 40)

                        Text("Your Moxie documentation will appear here")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        // Placeholder for documentation content
                        VStack(alignment: .leading, spacing: 20) {
                            DocumentationSection(
                                title: "Getting Started",
                                icon: "🚀",
                                description: "Learn the basics of using your Moxie controller"
                            )

                            DocumentationSection(
                                title: "Personalities",
                                icon: "🎭",
                                description: "Explore different personality modes and create custom ones"
                            )

                            DocumentationSection(
                                title: "Games & Activities",
                                icon: "🎮",
                                description: "Discover educational games and interactive features"
                            )

                            DocumentationSection(
                                title: "Settings & Configuration",
                                icon: "⚙️",
                                description: "Customize your Moxie experience"
                            )

                            DocumentationSection(
                                title: "Troubleshooting",
                                icon: "🔧",
                                description: "Common issues and solutions"
                            )
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text("📖 Documentation")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Documentation Section

struct DocumentationSection: View {
    let title: String
    let icon: String
    let description: String
    @State private var isHovered = false

    var body: some View {
        Button(action: {
            // TODO: Navigate to specific documentation page
        }) {
            HStack(spacing: 16) {
                Text(icon)
                    .font(.system(size: 40))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding()
            .background(
                isHovered ?
                    Color.white.opacity(0.15) :
                    Color.white.opacity(0.1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    DocumentationView()
}
