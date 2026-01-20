import SwiftUI

// MARK: - Screen Time Data
struct ScreenTimeData: Codable {
    var sessions: [ScreenTimeSession] = []

    struct ScreenTimeSession: Codable, Identifiable {
        let id: UUID
        let date: Date
        let duration: TimeInterval // in seconds
        let feature: FeatureType
        let personality: String?

        init(id: UUID = UUID(), date: Date = Date(), duration: TimeInterval, feature: FeatureType, personality: String? = nil) {
            self.id = id
            self.date = date
            self.duration = duration
            self.feature = feature
            self.personality = personality
        }
    }

    // Get total time for a date range
    func totalTime(from startDate: Date, to endDate: Date) -> TimeInterval {
        sessions
            .filter { $0.date >= startDate && $0.date <= endDate }
            .reduce(0) { $0 + $1.duration }
    }

    // Get time by feature
    func timeByFeature(from startDate: Date, to endDate: Date) -> [FeatureType: TimeInterval] {
        var result: [FeatureType: TimeInterval] = [:]
        for session in sessions.filter({ $0.date >= startDate && $0.date <= endDate }) {
            result[session.feature, default: 0] += session.duration
        }
        return result
    }

    // Get daily totals
    func dailyTotals(for days: Int) -> [(date: Date, duration: TimeInterval)] {
        var result: [(Date, TimeInterval)] = []
        let calendar = Calendar.current

        for i in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { continue }

            let total = totalTime(from: startOfDay, to: endOfDay)
            result.append((startOfDay, total))
        }

        return result.reversed()
    }
}

// MARK: - Screen Time Dashboard View
struct ScreenTimeDashboardView: View {
    @Environment(\.dismiss) var dismiss
    @State private var screenTimeData = ScreenTimeData()
    @State private var selectedPeriod: TimePeriod = .week
    @State private var dailyGoal: TimeInterval = 3600 // 1 hour default

    enum TimePeriod: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"

        var days: Int {
            switch self {
            case .today: return 1
            case .week: return 7
            case .month: return 30
            }
        }
    }

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
                    VStack(spacing: 24) {
                        // Period Selector
                        periodSelector

                        // Summary Cards
                        summaryCardsSection

                        // Daily Chart
                        dailyChartSection

                        // Feature Breakdown
                        featureBreakdownSection

                        // Daily Goal Setting
                        dailyGoalSection

                        // Session History
                        sessionHistorySection
                    }
                    .padding()
                }
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .onAppear { loadScreenTimeData() }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "hourglass.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                    Text("Screen Time")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "9D4EDD"))
                }

                Text("Monitor how much time your child spends with Moxie")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Close button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        HStack(spacing: 8) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Button(action: { selectedPeriod = period }) {
                    Text(period.rawValue)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(selectedPeriod == period ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedPeriod == period ? Color.purple : Color.gray.opacity(0.1))
                        .cornerRadius(20)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    // MARK: - Summary Cards Section

    private var summaryCardsSection: some View {
        let totalTime = getTotalTimeForPeriod()
        let averageTime = totalTime / Double(max(selectedPeriod.days, 1))
        let goalProgress = min(totalTime / dailyGoal, 1.0)

        return HStack(spacing: 16) {
            ScreenTimeSummaryCard(
                title: "Total Time",
                value: formatDuration(totalTime),
                subtitle: selectedPeriod.rawValue,
                icon: "clock.fill",
                color: .blue
            )

            ScreenTimeSummaryCard(
                title: "Daily Average",
                value: formatDuration(averageTime),
                subtitle: "per day",
                icon: "chart.bar.fill",
                color: .green
            )

            ScreenTimeSummaryCard(
                title: "Goal Progress",
                value: "\(Int(goalProgress * 100))%",
                subtitle: "of \(formatDuration(dailyGoal))/day",
                icon: "target",
                color: goalProgress > 1 ? .red : .purple
            )

            ScreenTimeSummaryCard(
                title: "Sessions",
                value: "\(getSessionCount())",
                subtitle: "conversations",
                icon: "bubble.left.and.bubble.right.fill",
                color: .orange
            )
        }
    }

    // MARK: - Daily Chart Section

    private var dailyChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Daily Usage", systemImage: "chart.bar.xaxis")
                .font(.headline)

            let dailyData = screenTimeData.dailyTotals(for: selectedPeriod.days)
            let maxTime = dailyData.map { $0.duration }.max() ?? 3600

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(dailyData.enumerated()), id: \.offset) { index, data in
                    VStack(spacing: 4) {
                        // Bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(barColor(for: data.duration))
                            .frame(width: 30, height: max(10, CGFloat(data.duration / maxTime) * 150))

                        // Day label
                        Text(dayLabel(for: data.date))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 180)
            .frame(maxWidth: .infinity)

            // Legend
            HStack(spacing: 20) {
                LegendItem(color: .green, label: "Under goal")
                LegendItem(color: .orange, label: "Near goal")
                LegendItem(color: .red, label: "Over goal")
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Feature Breakdown Section

    private var featureBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Time by Activity", systemImage: "pie.chart.fill")
                .font(.headline)

            let featureTime = getFeatureBreakdown()
            let totalTime = featureTime.values.reduce(0, +)

            VStack(spacing: 12) {
                ForEach(FeatureType.allCases, id: \.self) { feature in
                    let time = featureTime[feature] ?? 0
                    let percentage = totalTime > 0 ? time / totalTime : 0

                    HStack(spacing: 12) {
                        Text(feature.icon)
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(feature.displayName)
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                Text(formatDuration(time))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 8)
                                        .cornerRadius(4)

                                    Rectangle()
                                        .fill(featureColor(feature))
                                        .frame(width: geometry.size.width * CGFloat(percentage), height: 8)
                                        .cornerRadius(4)
                                }
                            }
                            .frame(height: 8)
                        }

                        Text("\(Int(percentage * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 40)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Daily Goal Section

    private var dailyGoalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Daily Time Goal", systemImage: "target")
                .font(.headline)

            HStack(spacing: 16) {
                GoalButton(minutes: 30, selected: Int(dailyGoal) / 60) { dailyGoal = 1800 }
                GoalButton(minutes: 60, selected: Int(dailyGoal) / 60) { dailyGoal = 3600 }
                GoalButton(minutes: 90, selected: Int(dailyGoal) / 60) { dailyGoal = 5400 }
                GoalButton(minutes: 120, selected: Int(dailyGoal) / 60) { dailyGoal = 7200 }
            }

            Text("Your child's daily screen time goal with Moxie is \(formatDuration(dailyGoal))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Session History Section

    private var sessionHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Recent Sessions", systemImage: "clock.arrow.circlepath")
                    .font(.headline)
                Spacer()
                Button("View All") {}
                    .font(.caption)
                    .foregroundColor(.blue)
            }

            if screenTimeData.sessions.isEmpty {
                HStack {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.title)
                        .foregroundColor(.gray)
                    Text("No sessions recorded yet")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ForEach(screenTimeData.sessions.prefix(10)) { session in
                    SessionRow(session: session)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Helpers

    private func loadScreenTimeData() {
        // Load from storage - generate sample data for now
        let calendar = Calendar.current
        var sessions: [ScreenTimeData.ScreenTimeSession] = []

        for i in 0..<14 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let sessionsPerDay = Int.random(in: 1...4)

            for _ in 0..<sessionsPerDay {
                let hour = Int.random(in: 8...20)
                guard let sessionDate = calendar.date(bySettingHour: hour, minute: Int.random(in: 0...59), second: 0, of: date) else { continue }

                sessions.append(ScreenTimeData.ScreenTimeSession(
                    date: sessionDate,
                    duration: TimeInterval(Int.random(in: 300...1800)),
                    feature: FeatureType.allCases.randomElement() ?? .conversation,
                    personality: ["Moxie", "Professor Spark", "Captain Adventure"].randomElement()
                ))
            }
        }

        screenTimeData.sessions = sessions.sorted { $0.date > $1.date }
    }

    private func getTotalTimeForPeriod() -> TimeInterval {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -selectedPeriod.days, to: endDate) else { return 0 }
        return screenTimeData.totalTime(from: startDate, to: endDate)
    }

    private func getSessionCount() -> Int {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -selectedPeriod.days, to: endDate) else { return 0 }
        return screenTimeData.sessions.filter { $0.date >= startDate && $0.date <= endDate }.count
    }

    private func getFeatureBreakdown() -> [FeatureType: TimeInterval] {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -selectedPeriod.days, to: endDate) else { return [:] }
        return screenTimeData.timeByFeature(from: startDate, to: endDate)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private func barColor(for duration: TimeInterval) -> Color {
        let percentage = duration / dailyGoal
        if percentage < 0.8 { return .green }
        if percentage < 1.0 { return .orange }
        return .red
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = selectedPeriod == .today ? "ha" : "EEE"
        return formatter.string(from: date)
    }

    private func featureColor(_ feature: FeatureType) -> Color {
        switch feature {
        case .conversation: return .blue
        case .story: return .purple
        case .learning: return .green
        case .music: return .pink
        case .language: return .orange
        case .other: return .gray
        }
    }
}

// MARK: - Supporting Views

struct ScreenTimeSummaryCard: View {
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
                .font(.title2.bold())
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

struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct GoalButton: View {
    let minutes: Int
    let selected: Int
    let action: () -> Void

    var isSelected: Bool { minutes == selected }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(minutes)")
                    .font(.title2.bold())
                Text("min")
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

struct SessionRow: View {
    let session: ScreenTimeData.ScreenTimeSession

    var body: some View {
        HStack(spacing: 12) {
            Text(session.feature.icon)
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.feature.displayName)
                    .font(.subheadline.weight(.medium))
                if let personality = session.personality {
                    Text("with \(personality)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDuration(session.duration))
                    .font(.subheadline.weight(.medium))
                Text(formatDate(session.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        return "\(minutes) min"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
