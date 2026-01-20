import SwiftUI

// MARK: - Privacy Settings
struct PrivacySettings: Codable {
    var loggingLevel: LoggingLevel = .balanced
    var saveConversationTranscripts: Bool = true
    var enableSentimentAnalysis: Bool = true
    var enableTopicExtraction: Bool = true
    var enableSafetyFlags: Bool = true
    var dataRetentionDays: Int = 90
    var allowAnonymousAnalytics: Bool = false
    var customBlockedKeywords: [String] = []
}

// MARK: - Privacy Settings View
struct PrivacySettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var settings = PrivacySettings()
    @State private var newKeyword = ""
    @State private var showSaveSuccess = false

    private let settingsKey = "moxie_privacy_settings"

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(hex: "#9D4EDD").opacity(0.05),
                    Color(hex: "#7B2CBF").opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView
                    .padding()
                    .background(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)

                ScrollView {
                    VStack(spacing: 24) {
                        // Logging Level Section
                        loggingLevelSection

                        // Data Collection Section
                        dataCollectionSection

                        // Data Retention Section
                        dataRetentionSection

                        // Custom Blocked Keywords
                        customKeywordsSection

                        // Data Management Section
                        dataManagementSection
                    }
                    .padding()
                }
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .onAppear { loadSettings() }
        .overlay(saveSuccessOverlay)
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "eye.slash.fill")
                        .font(.title)
                        .foregroundColor(.green)
                    Text("Privacy Settings")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "#9D4EDD"))
                }

                Text("Control what data is collected and how long it's stored")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Save button
            Button(action: saveSettings) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Save")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.green)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)

            // Close button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Logging Level Section

    private var loggingLevelSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Monitoring Level", systemImage: "slider.horizontal.3")
                .font(.headline)

            Text("Choose how much data Moxie collects about your child's activity")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(LoggingLevel.allCases, id: \.self) { level in
                LoggingLevelCard(
                    level: level,
                    isSelected: settings.loggingLevel == level,
                    onSelect: { settings.loggingLevel = level }
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Data Collection Section

    private var dataCollectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Data Collection", systemImage: "doc.text.magnifyingglass")
                .font(.headline)

            VStack(spacing: 12) {
                PrivacyToggle(
                    title: "Save Conversation Transcripts",
                    description: "Store full conversation text for review",
                    icon: "text.bubble.fill",
                    color: .blue,
                    isOn: $settings.saveConversationTranscripts
                )

                PrivacyToggle(
                    title: "Sentiment Analysis",
                    description: "Analyze emotional tone of conversations",
                    icon: "face.smiling.fill",
                    color: .orange,
                    isOn: $settings.enableSentimentAnalysis
                )

                PrivacyToggle(
                    title: "Topic Extraction",
                    description: "Identify topics your child discusses",
                    icon: "tag.fill",
                    color: .purple,
                    isOn: $settings.enableTopicExtraction
                )

                PrivacyToggle(
                    title: "Safety Flags",
                    description: "Flag concerning content for review",
                    icon: "exclamationmark.shield.fill",
                    color: .red,
                    isOn: $settings.enableSafetyFlags
                )

                PrivacyToggle(
                    title: "Anonymous Analytics",
                    description: "Help improve Moxie with anonymous usage data",
                    icon: "chart.bar.fill",
                    color: .green,
                    isOn: $settings.allowAnonymousAnalytics
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Data Retention Section

    private var dataRetentionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Data Retention", systemImage: "clock.arrow.circlepath")
                .font(.headline)

            Text("How long to keep conversation history and logs")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                RetentionButton(days: 30, selected: settings.dataRetentionDays) {
                    settings.dataRetentionDays = 30
                }
                RetentionButton(days: 90, selected: settings.dataRetentionDays) {
                    settings.dataRetentionDays = 90
                }
                RetentionButton(days: 180, selected: settings.dataRetentionDays) {
                    settings.dataRetentionDays = 180
                }
                RetentionButton(days: 365, selected: settings.dataRetentionDays) {
                    settings.dataRetentionDays = 365
                }
            }

            Text("Data older than \(settings.dataRetentionDays) days will be automatically deleted")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Custom Keywords Section

    private var customKeywordsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Custom Blocked Keywords", systemImage: "textformat.abc.dottedunderline")
                .font(.headline)

            Text("Add words or phrases that should trigger safety flags")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                TextField("Add keyword...", text: $newKeyword)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                Button(action: addKeyword) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .disabled(newKeyword.isEmpty)
            }

            if !settings.customBlockedKeywords.isEmpty {
                KeywordFlowLayout(spacing: 8) {
                    ForEach(settings.customBlockedKeywords, id: \.self) { keyword in
                        KeywordTag(keyword: keyword) {
                            settings.customBlockedKeywords.removeAll { $0 == keyword }
                        }
                    }
                }
            } else {
                Text("No custom keywords added")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Data Management Section

    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Data Management", systemImage: "externaldrive.fill")
                .font(.headline)

            HStack(spacing: 16) {
                Button(action: exportData) {
                    VStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up.fill")
                            .font(.title2)
                        Text("Export Data")
                            .font(.caption.bold())
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)

                Button(action: {}) {
                    VStack(spacing: 8) {
                        Image(systemName: "trash.fill")
                            .font(.title2)
                        Text("Delete All Data")
                            .font(.caption.bold())
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }

            Text("Deleting data is permanent and cannot be undone")
                .font(.caption)
                .foregroundColor(.red.opacity(0.8))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Save Success Overlay

    private var saveSuccessOverlay: some View {
        Group {
            if showSaveSuccess {
                VStack {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Privacy settings saved")
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color.green.opacity(0.9))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .shadow(radius: 5)
                    Spacer()
                }
                .padding(.top, 50)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Actions

    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(PrivacySettings.self, from: data) {
            settings = decoded
        }
    }

    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }

        withAnimation {
            showSaveSuccess = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSaveSuccess = false
            }
        }
    }

    private func addKeyword() {
        let trimmed = newKeyword.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !trimmed.isEmpty && !settings.customBlockedKeywords.contains(trimmed) {
            settings.customBlockedKeywords.append(trimmed)
            newKeyword = ""
        }
    }

    private func exportData() {
        // Export functionality
        print("Exporting data...")
    }
}

// MARK: - Supporting Views

struct LoggingLevelCard: View {
    let level: LoggingLevel
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                Image(systemName: level.icon)
                    .font(.title2)
                    .foregroundColor(level.color)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(level.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(level.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? level.color : .gray.opacity(0.3))
            }
            .padding()
            .background(isSelected ? level.color.opacity(0.1) : Color.gray.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? level.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct PrivacyToggle: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .toggleStyle(.switch)
        .padding(.vertical, 4)
    }
}

struct RetentionButton: View {
    let days: Int
    let selected: Int
    let action: () -> Void

    var isSelected: Bool { days == selected }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(days)")
                    .font(.title2.bold())
                Text("days")
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.purple : Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct KeywordTag: View {
    let keyword: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(keyword)
                .font(.caption)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.red.opacity(0.1))
        .foregroundColor(.red)
        .cornerRadius(16)
    }
}

// Simple flow layout for keywords
struct KeywordFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > width && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: width, height: y + rowHeight)
        }
    }
}
