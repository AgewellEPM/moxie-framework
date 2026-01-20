import SwiftUI

// MARK: - Parent Insights Dashboard (Quick At-a-Glance View for Busy Parents)
struct ParentInsightsDashboardView: View {
    @Environment(\.dismiss) var dismiss
    @State private var lastUpdated = Date()
    @State private var insights: DashboardInsights?
    @State private var isRefreshing = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(hex: "9D4EDD").opacity(0.05),
                    Color(hex: "7B2CBF").opacity(0.05)
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
                    if let insights = insights {
                        VStack(spacing: 20) {
                            // Quick Status
                            quickStatusSection(insights)

                            // Today's Summary
                            todaySummarySection(insights)

                            // Attention Needed
                            if !insights.attentionItems.isEmpty {
                                attentionSection(insights)
                            }

                            // Quick Actions
                            quickActionsSection

                            // Recent Activity
                            recentActivitySection(insights)

                            // Quick Stats Grid
                            quickStatsGrid(insights)
                        }
                        .padding()
                    } else {
                        loadingView
                    }
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .onAppear { loadInsights() }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Good \(timeOfDayGreeting)!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(hex: "9D4EDD"))

                Text("Here's what's happening with Moxie")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Last updated
            HStack(spacing: 8) {
                if isRefreshing {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                Text("Updated \(lastUpdated, style: .relative) ago")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .onTapGesture { refreshInsights() }

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
    }

    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Morning" }
        if hour < 17 { return "Afternoon" }
        return "Evening"
    }

    // MARK: - Quick Status Section

    private func quickStatusSection(_ insights: DashboardInsights) -> some View {
        HStack(spacing: 16) {
            // Child Status
            StatusBadge(
                title: "Status",
                value: insights.childStatus.rawValue,
                icon: insights.childStatus.icon,
                color: insights.childStatus.color
            )

            // Today's Time
            StatusBadge(
                title: "Today",
                value: formatDuration(insights.todayScreenTime),
                icon: "clock.fill",
                color: insights.todayScreenTime > 3600 ? .orange : .green
            )

            // Mood
            StatusBadge(
                title: "Mood",
                value: insights.currentMood.displayName,
                icon: "face.smiling.fill",
                color: moodColor(insights.currentMood)
            )

            // Safety
            StatusBadge(
                title: "Safety",
                value: insights.unreviewedFlags > 0 ? "\(insights.unreviewedFlags) flags" : "All clear",
                icon: insights.unreviewedFlags > 0 ? "exclamationmark.shield.fill" : "checkmark.shield.fill",
                color: insights.unreviewedFlags > 0 ? .red : .green
            )
        }
    }

    // MARK: - Today's Summary Section

    private func todaySummarySection(_ insights: DashboardInsights) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Highlights")
                .font(.headline)

            HStack(spacing: 24) {
                // Conversations
                HighlightCard(
                    number: "\(insights.todayConversations)",
                    label: "Conversations",
                    icon: "bubble.left.and.bubble.right.fill",
                    color: .blue
                )

                // Topics discussed
                HighlightCard(
                    number: "\(insights.topicsDiscussed.count)",
                    label: "Topics",
                    icon: "tag.fill",
                    color: .purple
                )

                // Learning activities
                HighlightCard(
                    number: "\(insights.learningActivities)",
                    label: "Learning",
                    icon: "graduationcap.fill",
                    color: .green
                )

                // Stories
                HighlightCard(
                    number: "\(insights.storiesRead)",
                    label: "Stories",
                    icon: "book.fill",
                    color: .orange
                )
            }

            // Top topics
            if !insights.topicsDiscussed.isEmpty {
                HStack {
                    Text("Talked about:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ForEach(insights.topicsDiscussed.prefix(5), id: \.self) { topic in
                        Text(topic)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }

    // MARK: - Attention Section

    private func attentionSection(_ insights: DashboardInsights) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
                Text("Needs Your Attention")
                    .font(.headline)
            }

            ForEach(insights.attentionItems) { item in
                AttentionItemRow(item: item)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(16)
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                title: "View Chats",
                icon: "bubble.left.and.bubble.right.fill",
                color: .blue
            ) {
                // Navigate to conversation logs
            }

            QuickActionButton(
                title: "Time Settings",
                icon: "clock.fill",
                color: .purple
            ) {
                // Navigate to time restrictions
            }

            QuickActionButton(
                title: "Safety Alerts",
                icon: "shield.fill",
                color: .red
            ) {
                // Navigate to safety alerts
            }

            QuickActionButton(
                title: "Weekly Report",
                icon: "doc.text.fill",
                color: .green
            ) {
                // Navigate to weekly report
            }
        }
    }

    // MARK: - Recent Activity Section

    private func recentActivitySection(_ insights: DashboardInsights) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                Spacer()
                Button("View All") {}
                    .font(.caption)
                    .foregroundColor(.blue)
            }

            ForEach(insights.recentActivities.prefix(5)) { activity in
                RecentActivityRow(activity: activity)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }

    // MARK: - Quick Stats Grid

    private func quickStatsGrid(_ insights: DashboardInsights) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                QuickStatItem(title: "Total Time", value: formatDuration(insights.weekScreenTime), icon: "clock")
                QuickStatItem(title: "Conversations", value: "\(insights.weekConversations)", icon: "bubble.left")
                QuickStatItem(title: "Avg Daily", value: formatDuration(insights.weekScreenTime / 7), icon: "chart.bar")
                QuickStatItem(title: "Mood Score", value: "\(Int(insights.moodScore * 100))%", icon: "face.smiling")
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading insights...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: 400)
    }

    // MARK: - Helpers

    private func loadInsights() {
        // Generate sample insights
        insights = DashboardInsights(
            childStatus: .playing,
            todayScreenTime: TimeInterval.random(in: 1200...4800),
            todayConversations: Int.random(in: 2...10),
            topicsDiscussed: ["Animals", "Space", "School", "Games"],
            learningActivities: Int.random(in: 0...5),
            storiesRead: Int.random(in: 0...3),
            currentMood: [.veryPositive, .positive, .neutral].randomElement()!,
            unreviewedFlags: Int.random(in: 0...2),
            attentionItems: Int.random(in: 0...3) > 1 ? [
                AttentionItem(id: UUID(), type: .safetyFlag, title: "New safety flag", description: "Review a flagged conversation", priority: .high),
            ] : [],
            recentActivities: [
                RecentActivity(id: UUID(), type: .conversation, title: "Talked with Moxie", time: Date().addingTimeInterval(-1800), personality: "Moxie"),
                RecentActivity(id: UUID(), type: .story, title: "Read 'The Space Adventure'", time: Date().addingTimeInterval(-7200), personality: nil),
                RecentActivity(id: UUID(), type: .learning, title: "Completed math quiz", time: Date().addingTimeInterval(-10800), personality: nil)
            ],
            weekScreenTime: TimeInterval.random(in: 10800...36000),
            weekConversations: Int.random(in: 15...50),
            moodScore: Double.random(in: 0.6...0.95)
        )
        lastUpdated = Date()
    }

    private func refreshInsights() {
        isRefreshing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            loadInsights()
            isRefreshing = false
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }

    private func moodColor(_ mood: Sentiment) -> Color {
        switch mood {
        case .veryPositive: return .green
        case .positive: return .blue
        case .neutral: return .gray
        case .negative: return .orange
        case .concerning: return .red
        }
    }
}

// MARK: - Data Models

struct DashboardInsights {
    let childStatus: ChildStatus
    let todayScreenTime: TimeInterval
    let todayConversations: Int
    let topicsDiscussed: [String]
    let learningActivities: Int
    let storiesRead: Int
    let currentMood: Sentiment
    let unreviewedFlags: Int
    let attentionItems: [AttentionItem]
    let recentActivities: [RecentActivity]
    let weekScreenTime: TimeInterval
    let weekConversations: Int
    let moodScore: Double

    enum ChildStatus: String {
        case playing = "Playing"
        case learning = "Learning"
        case reading = "Reading"
        case idle = "Idle"
        case offline = "Offline"

        var icon: String {
            switch self {
            case .playing: return "gamecontroller.fill"
            case .learning: return "graduationcap.fill"
            case .reading: return "book.fill"
            case .idle: return "moon.fill"
            case .offline: return "wifi.slash"
            }
        }

        var color: Color {
            switch self {
            case .playing: return .blue
            case .learning: return .green
            case .reading: return .purple
            case .idle: return .gray
            case .offline: return .gray
            }
        }
    }
}

struct AttentionItem: Identifiable {
    let id: UUID
    let type: AttentionType
    let title: String
    let description: String
    let priority: Priority

    enum AttentionType { case safetyFlag, timeExceeded, moodConcern, newAchievement }
    enum Priority { case low, medium, high }
}

struct RecentActivity: Identifiable {
    let id: UUID
    let type: ActivityType
    let title: String
    let time: Date
    let personality: String?

    enum ActivityType { case conversation, story, learning, game }
}

// MARK: - Supporting Views

struct StatusBadge: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.subheadline.weight(.semibold))
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct HighlightCard: View {
    let number: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(number)
                .font(.title.bold())
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AttentionItemRow: View {
    let item: AttentionItem

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(priorityColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline.weight(.medium))
                Text(item.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Review") {}
                .font(.caption.weight(.medium))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange)
                .cornerRadius(8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
    }

    var priorityColor: Color {
        switch item.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .yellow
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct RecentActivityRow: View {
    let activity: RecentActivity

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activityIcon)
                .font(.title3)
                .foregroundColor(activityColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.subheadline)
                if let personality = activity.personality {
                    Text("with \(personality)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text(activity.time, style: .relative)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }

    var activityIcon: String {
        switch activity.type {
        case .conversation: return "bubble.left.fill"
        case .story: return "book.fill"
        case .learning: return "graduationcap.fill"
        case .game: return "gamecontroller.fill"
        }
    }

    var activityColor: Color {
        switch activity.type {
        case .conversation: return .blue
        case .story: return .purple
        case .learning: return .green
        case .game: return .orange
        }
    }
}

struct QuickStatItem: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}
