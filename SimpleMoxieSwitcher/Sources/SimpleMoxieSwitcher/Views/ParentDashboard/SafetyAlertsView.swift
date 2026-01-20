import SwiftUI

// MARK: - Safety Alert Settings
struct SafetyAlertSettings: Codable {
    var emailOnFlag: Bool = true
    var emailOnPINFailure: Bool = true
    var emailOnTimeExtension: Bool = true
    var dailySummary: Bool = false
    var weeklySummary: Bool = true
    var instantNotifications: Bool = true

    // Per-category settings
    var categorySettings: [String: CategoryAlertSetting] = [:]

    struct CategoryAlertSetting: Codable {
        var enabled: Bool = true
        var emailNotify: Bool = true
        var pushNotify: Bool = true
        var minimumSeverity: String = "low"
    }
}

// MARK: - Safety Alerts View
struct SafetyAlertsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var settings = SafetyAlertSettings()
    @State private var showSaveSuccess = false
    @State private var recentFlags: [ContentFlag] = []

    private let settingsKey = "moxie_safety_alert_settings"

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
                        // Quick Stats
                        quickStatsSection

                        // Notification Methods
                        notificationMethodsSection

                        // Category Settings
                        categorySettingsSection

                        // Summary Reports
                        summaryReportsSection

                        // Recent Flags
                        recentFlagsSection
                    }
                    .padding()
                }
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .onAppear {
            loadSettings()
            loadRecentFlags()
        }
        .overlay(saveSuccessOverlay)
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "bell.badge.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                    Text("Safety Alerts")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "#9D4EDD"))
                }

                Text("Configure how you're notified about safety concerns")
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

    // MARK: - Quick Stats Section

    private var quickStatsSection: some View {
        HStack(spacing: 16) {
            AlertStatCard(
                title: "This Week",
                value: "\(recentFlags.count)",
                subtitle: "flags detected",
                icon: "flag.fill",
                color: .orange
            )

            AlertStatCard(
                title: "Unreviewed",
                value: "\(recentFlags.filter { !$0.reviewed }.count)",
                subtitle: "need attention",
                icon: "eye.slash.fill",
                color: .red
            )

            AlertStatCard(
                title: "Critical",
                value: "\(recentFlags.filter { $0.severity == .critical }.count)",
                subtitle: "high priority",
                icon: "exclamationmark.triangle.fill",
                color: .red
            )

            AlertStatCard(
                title: "Notifications",
                value: settings.instantNotifications ? "ON" : "OFF",
                subtitle: "real-time alerts",
                icon: "bell.fill",
                color: settings.instantNotifications ? .green : .gray
            )
        }
    }

    // MARK: - Notification Methods Section

    private var notificationMethodsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Notification Methods", systemImage: "bell.and.waves.left.and.right")
                .font(.headline)

            VStack(spacing: 12) {
                AlertToggle(
                    title: "Instant Push Notifications",
                    description: "Get notified immediately when flags are detected",
                    icon: "iphone.radiowaves.left.and.right",
                    color: .blue,
                    isOn: $settings.instantNotifications
                )

                AlertToggle(
                    title: "Email on Content Flags",
                    description: "Receive email for flagged content (high/critical)",
                    icon: "envelope.fill",
                    color: .red,
                    isOn: $settings.emailOnFlag
                )

                AlertToggle(
                    title: "Email on PIN Failures",
                    description: "Get notified of multiple failed PIN attempts",
                    icon: "lock.trianglebadge.exclamationmark.fill",
                    color: .orange,
                    isOn: $settings.emailOnPINFailure
                )

                AlertToggle(
                    title: "Email on Time Extension Requests",
                    description: "Know when your child requests more time",
                    icon: "clock.badge.questionmark.fill",
                    color: .purple,
                    isOn: $settings.emailOnTimeExtension
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Category Settings Section

    private var categorySettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Alert Categories", systemImage: "tag.fill")
                .font(.headline)

            Text("Configure alerts for each category of concerning content")
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                ForEach(FlagCategory.allCases, id: \.self) { category in
                    CategoryAlertRow(
                        category: category,
                        setting: getCategorySetting(for: category),
                        onUpdate: { newSetting in
                            settings.categorySettings[category.rawValue] = newSetting
                        }
                    )
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Summary Reports Section

    private var summaryReportsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Summary Reports", systemImage: "doc.text.fill")
                .font(.headline)

            Text("Receive regular summaries of your child's activity")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                SummaryReportCard(
                    title: "Daily Summary",
                    description: "Quick overview every evening",
                    icon: "sun.max.fill",
                    isEnabled: settings.dailySummary,
                    onToggle: { settings.dailySummary.toggle() }
                )

                SummaryReportCard(
                    title: "Weekly Report",
                    description: "Detailed report every Sunday",
                    icon: "calendar",
                    isEnabled: settings.weeklySummary,
                    onToggle: { settings.weeklySummary.toggle() }
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Recent Flags Section

    private var recentFlagsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Recent Flags", systemImage: "flag.fill")
                    .font(.headline)
                Spacer()
                Button("View All") {
                    // Navigate to full flag list
                }
                .font(.caption)
                .foregroundColor(.blue)
            }

            if recentFlags.isEmpty {
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.title)
                        .foregroundColor(.green)
                    VStack(alignment: .leading) {
                        Text("No recent flags")
                            .font(.headline)
                        Text("Your child's conversations have been safe")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            } else {
                ForEach(recentFlags.prefix(5)) { flag in
                    RecentFlagRow(flag: flag)
                }
            }
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
                        Text("Alert settings saved")
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

    // MARK: - Helpers

    private func getCategorySetting(for category: FlagCategory) -> SafetyAlertSettings.CategoryAlertSetting {
        settings.categorySettings[category.rawValue] ?? SafetyAlertSettings.CategoryAlertSetting()
    }

    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(SafetyAlertSettings.self, from: data) {
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

    private func loadRecentFlags() {
        // Load from SafetyLogService
        Task {
            // Sample data for now
            recentFlags = []
        }
    }
}

// MARK: - Supporting Views

struct AlertStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title.bold())
                .foregroundColor(.primary)

            VStack(spacing: 2) {
                Text(title)
                    .font(.caption.bold())
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AlertToggle: View {
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

struct CategoryAlertRow: View {
    let category: FlagCategory
    @State var setting: SafetyAlertSettings.CategoryAlertSetting
    let onUpdate: (SafetyAlertSettings.CategoryAlertSetting) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: categoryIcon)
                .font(.title3)
                .foregroundColor(categoryColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.displayName)
                    .font(.subheadline.weight(.medium))
                Text(category.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Severity picker
            Picker("", selection: Binding(
                get: { setting.minimumSeverity },
                set: { newValue in
                    setting.minimumSeverity = newValue
                    onUpdate(setting)
                }
            )) {
                Text("All").tag("low")
                Text("Med+").tag("medium")
                Text("High+").tag("high")
                Text("Critical").tag("critical")
            }
            .pickerStyle(.segmented)
            .frame(width: 200)

            Toggle("", isOn: Binding(
                get: { setting.enabled },
                set: { newValue in
                    setting.enabled = newValue
                    onUpdate(setting)
                }
            ))
            .toggleStyle(.switch)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }

    var categoryIcon: String {
        switch category {
        case .inappropriateLanguage: return "text.badge.xmark"
        case .bullyingMention: return "person.fill.xmark"
        case .sadnessRepeated: return "cloud.rain.fill"
        case .angerRepeated: return "flame.fill"
        case .selfHarmLanguage: return "heart.slash.fill"
        case .abuseIndicators: return "exclamationmark.shield.fill"
        case .privacyRisk: return "lock.open.fill"
        }
    }

    var categoryColor: Color {
        switch category {
        case .inappropriateLanguage: return .orange
        case .bullyingMention: return .red
        case .sadnessRepeated: return .blue
        case .angerRepeated: return .red
        case .selfHarmLanguage: return .purple
        case .abuseIndicators: return .red
        case .privacyRisk: return .yellow
        }
    }
}

struct SummaryReportCard: View {
    let title: String
    let description: String
    let icon: String
    let isEnabled: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(isEnabled ? .white : .gray)

                Text(title)
                    .font(.headline)
                    .foregroundColor(isEnabled ? .white : .primary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(isEnabled ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)

                Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isEnabled ? .white : .gray.opacity(0.3))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isEnabled ? Color.purple : Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct RecentFlagRow: View {
    let flag: ContentFlag

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(severityColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(flag.category.displayName)
                        .font(.subheadline.weight(.medium))
                    Text(flag.severity.emoji)
                    if !flag.reviewed {
                        Text("NEW")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .cornerRadius(4)
                    }
                }
                Text(flag.messageContent.prefix(60) + "...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(flag.formattedTimestamp)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(flag.reviewed ? Color.clear : Color.orange.opacity(0.05))
        .cornerRadius(8)
    }

    var severityColor: Color {
        switch flag.severity {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}
