import SwiftUI

// MARK: - Weekly Report Data
struct WeeklyReportData {
    let weekStartDate: Date
    let weekEndDate: Date
    let totalScreenTime: TimeInterval
    let averageDailyTime: TimeInterval
    let totalConversations: Int
    let topTopics: [TopicMention]
    let moodSummary: MoodSummary
    let learningProgress: LearningProgress
    let safetyFlags: Int
    let achievements: [RewardAchievement]

    struct TopicMention {
        let topic: String
        let count: Int
        let trend: Trend

        enum Trend { case up, down, same }
    }

    struct MoodSummary {
        let dominantMood: Sentiment
        let moodBreakdown: [Sentiment: Double]
        let trend: String
    }

    struct LearningProgress {
        let lessonsCompleted: Int
        let quizzesTaken: Int
        let averageScore: Double
        let newWordsLearned: Int
    }
}

// MARK: - Weekly Report Card View
struct WeeklyReportCardView: View {
    @Environment(\.dismiss) var dismiss
    @State private var report: WeeklyReportData?
    @State private var selectedWeek: Date = Date()

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
                        // Week Navigator
                        weekNavigator

                        // Report Card
                        if let report = report {
                            // Grade Summary
                            gradeSummaryCard(report)

                            // Key Stats
                            keyStatsSection(report)

                            // Mood Summary
                            moodSummarySection(report)

                            // Top Topics
                            topTopicsSection(report)

                            // Learning Progress
                            learningProgressSection(report)

                            // Achievements
                            achievementsSection(report)

                            // Parent Notes
                            parentNotesSection(report)
                        } else {
                            loadingView
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .onAppear { loadReport() }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .font(.title)
                        .foregroundColor(.purple)
                    Text("Weekly Report Card")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "9D4EDD"))
                }

                Text("A summary of your child's week with Moxie")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Export button
            Button(action: exportReport) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export PDF")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue)
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

    // MARK: - Week Navigator

    private var weekNavigator: some View {
        HStack {
            Button(action: previousWeek) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.purple)
            }
            .buttonStyle(.plain)

            Text(weekRangeText)
                .font(.headline)
                .frame(maxWidth: .infinity)

            Button(action: nextWeek) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(isCurrentWeek ? .gray : .purple)
            }
            .buttonStyle(.plain)
            .disabled(isCurrentWeek)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Grade Summary Card

    private func gradeSummaryCard(_ report: WeeklyReportData) -> some View {
        HStack(spacing: 24) {
            // Overall Grade
            VStack(spacing: 8) {
                Text(overallGrade(report))
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(gradeColor(overallGrade(report)))
                Text("Overall Grade")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(gradeColor(overallGrade(report)).opacity(0.1))
            .cornerRadius(16)

            // Grade Breakdown
            VStack(alignment: .leading, spacing: 12) {
                GradeRow(label: "Engagement", grade: engagementGrade(report))
                GradeRow(label: "Learning", grade: learningGrade(report))
                GradeRow(label: "Creativity", grade: creativityGrade(report))
                GradeRow(label: "Emotional Health", grade: moodGrade(report))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(16)
        }
    }

    // MARK: - Key Stats Section

    private func keyStatsSection(_ report: WeeklyReportData) -> some View {
        HStack(spacing: 16) {
            ReportStatCard(
                title: "Total Time",
                value: formatDuration(report.totalScreenTime),
                icon: "clock.fill",
                color: .blue
            )
            ReportStatCard(
                title: "Conversations",
                value: "\(report.totalConversations)",
                icon: "bubble.left.and.bubble.right.fill",
                color: .green
            )
            ReportStatCard(
                title: "Avg Daily",
                value: formatDuration(report.averageDailyTime),
                icon: "chart.line.uptrend.xyaxis",
                color: .orange
            )
            ReportStatCard(
                title: "Safety Flags",
                value: "\(report.safetyFlags)",
                icon: report.safetyFlags > 0 ? "exclamationmark.triangle.fill" : "checkmark.shield.fill",
                color: report.safetyFlags > 0 ? .red : .green
            )
        }
    }

    // MARK: - Mood Summary Section

    private func moodSummarySection(_ report: WeeklyReportData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Emotional Summary", systemImage: "face.smiling.fill")
                .font(.headline)

            HStack(spacing: 24) {
                // Dominant mood
                VStack(spacing: 8) {
                    Text(report.moodSummary.dominantMood.emoji)
                        .font(.system(size: 48))
                    Text(report.moodSummary.dominantMood.displayName)
                        .font(.headline)
                    Text("Most Common Mood")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                // Mood breakdown
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(report.moodSummary.moodBreakdown.sorted { $0.value > $1.value }), id: \.key) { mood, percentage in
                        HStack {
                            Text(mood.emoji)
                            Text(mood.displayName)
                                .font(.caption)
                            Spacer()
                            Text("\(Int(percentage * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                // Trend
                VStack(spacing: 8) {
                    Image(systemName: "arrow.up.right")
                        .font(.title)
                        .foregroundColor(.green)
                    Text(report.moodSummary.trend)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Top Topics Section

    private func topTopicsSection(_ report: WeeklyReportData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("What They Talked About", systemImage: "text.bubble.fill")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(report.topTopics, id: \.topic) { topic in
                    WeeklyTopicCard(topic: topic)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Learning Progress Section

    private func learningProgressSection(_ report: WeeklyReportData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Learning Progress", systemImage: "graduationcap.fill")
                .font(.headline)

            HStack(spacing: 16) {
                LearningStatCard(
                    title: "Lessons",
                    value: "\(report.learningProgress.lessonsCompleted)",
                    subtitle: "completed",
                    icon: "book.fill",
                    color: .blue
                )
                LearningStatCard(
                    title: "Quizzes",
                    value: "\(report.learningProgress.quizzesTaken)",
                    subtitle: "taken",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                LearningStatCard(
                    title: "Avg Score",
                    value: "\(Int(report.learningProgress.averageScore))%",
                    subtitle: "correct",
                    icon: "star.fill",
                    color: .yellow
                )
                LearningStatCard(
                    title: "New Words",
                    value: "\(report.learningProgress.newWordsLearned)",
                    subtitle: "learned",
                    icon: "textformat.abc",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Achievements Section

    private func achievementsSection(_ report: WeeklyReportData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Achievements Earned", systemImage: "medal.fill")
                .font(.headline)

            if report.achievements.isEmpty {
                Text("No new achievements this week")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(report.achievements) { achievement in
                        RewardAchievementBadge(achievement: achievement)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Parent Notes Section

    private func parentNotesSection(_ report: WeeklyReportData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Notes for Parents", systemImage: "lightbulb.fill")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                ParentNote(
                    icon: "star.fill",
                    color: .yellow,
                    text: "Your child showed great curiosity about science topics this week!"
                )

                if report.safetyFlags > 0 {
                    ParentNote(
                        icon: "exclamationmark.triangle.fill",
                        color: .orange,
                        text: "There were \(report.safetyFlags) safety flag(s) this week. Please review in the Safety Alerts section."
                    )
                }

                ParentNote(
                    icon: "heart.fill",
                    color: .pink,
                    text: "Consider asking about their favorite Moxie conversation this week to encourage sharing."
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading report...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: 400)
    }

    // MARK: - Helpers

    private var weekRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedWeek))!
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
        return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: endOfWeek))"
    }

    private var isCurrentWeek: Bool {
        Calendar.current.isDate(selectedWeek, equalTo: Date(), toGranularity: .weekOfYear)
    }

    private func previousWeek() {
        selectedWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedWeek)!
        loadReport()
    }

    private func nextWeek() {
        selectedWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedWeek)!
        loadReport()
    }

    private func loadReport() {
        // Generate sample report data
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedWeek))!
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!

        report = WeeklyReportData(
            weekStartDate: startOfWeek,
            weekEndDate: endOfWeek,
            totalScreenTime: TimeInterval.random(in: 7200...18000),
            averageDailyTime: TimeInterval.random(in: 1200...3600),
            totalConversations: Int.random(in: 10...40),
            topTopics: [
                .init(topic: "Animals", count: 15, trend: .up),
                .init(topic: "Space", count: 12, trend: .same),
                .init(topic: "Games", count: 10, trend: .down),
                .init(topic: "School", count: 8, trend: .up),
                .init(topic: "Friends", count: 6, trend: .same),
                .init(topic: "Drawing", count: 5, trend: .up)
            ],
            moodSummary: .init(
                dominantMood: .positive,
                moodBreakdown: [
                    .veryPositive: 0.3,
                    .positive: 0.45,
                    .neutral: 0.2,
                    .negative: 0.05
                ],
                trend: "Happier than last week!"
            ),
            learningProgress: .init(
                lessonsCompleted: Int.random(in: 3...12),
                quizzesTaken: Int.random(in: 2...8),
                averageScore: Double.random(in: 70...95),
                newWordsLearned: Int.random(in: 5...20)
            ),
            safetyFlags: Int.random(in: 0...2),
            achievements: [
                RewardAchievement(name: "Curious Cat", description: "Asked 10 questions", icon: "questionmark.circle.fill", color: "3B82F6", earnedDate: Date(), category: .conversation),
                RewardAchievement(name: "Story Lover", description: "Read 5 stories", icon: "book.fill", color: "8B5CF6", earnedDate: Date(), category: .creativity)
            ]
        )
    }

    private func exportReport() {
        // Export to PDF
        print("Exporting report...")
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private func overallGrade(_ report: WeeklyReportData) -> String {
        let score = (Double(report.totalConversations) / 30.0 * 25) +
                   (report.learningProgress.averageScore / 100.0 * 25) +
                   (report.moodSummary.moodBreakdown[.positive, default: 0] * 25 +
                    report.moodSummary.moodBreakdown[.veryPositive, default: 0] * 25) +
                   (report.safetyFlags == 0 ? 25 : 15)

        if score >= 90 { return "A" }
        if score >= 80 { return "B" }
        if score >= 70 { return "C" }
        if score >= 60 { return "D" }
        return "F"
    }

    private func gradeColor(_ grade: String) -> Color {
        switch grade {
        case "A": return .green
        case "B": return .blue
        case "C": return .yellow
        case "D": return .orange
        default: return .red
        }
    }

    private func engagementGrade(_ report: WeeklyReportData) -> String {
        let score = Double(report.totalConversations) / 30.0 * 100
        if score >= 90 { return "A" }
        if score >= 70 { return "B" }
        if score >= 50 { return "C" }
        return "D"
    }

    private func learningGrade(_ report: WeeklyReportData) -> String {
        if report.learningProgress.averageScore >= 90 { return "A" }
        if report.learningProgress.averageScore >= 80 { return "B" }
        if report.learningProgress.averageScore >= 70 { return "C" }
        return "D"
    }

    private func creativityGrade(_ report: WeeklyReportData) -> String {
        // Based on variety of topics
        if report.topTopics.count >= 6 { return "A" }
        if report.topTopics.count >= 4 { return "B" }
        if report.topTopics.count >= 2 { return "C" }
        return "D"
    }

    private func moodGrade(_ report: WeeklyReportData) -> String {
        let positivePercent = (report.moodSummary.moodBreakdown[.positive, default: 0] +
                              report.moodSummary.moodBreakdown[.veryPositive, default: 0]) * 100
        if positivePercent >= 70 { return "A" }
        if positivePercent >= 50 { return "B" }
        if positivePercent >= 30 { return "C" }
        return "D"
    }
}

// MARK: - Supporting Views

struct GradeRow: View {
    let label: String
    let grade: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(grade)
                .font(.headline.bold())
                .foregroundColor(gradeColor)
        }
    }

    var gradeColor: Color {
        switch grade {
        case "A": return .green
        case "B": return .blue
        case "C": return .yellow
        default: return .orange
        }
    }
}

struct ReportStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title2.bold())
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

struct WeeklyTopicCard: View {
    let topic: WeeklyReportData.TopicMention

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(topic.topic)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Image(systemName: trendIcon)
                    .font(.caption)
                    .foregroundColor(trendColor)
            }
            Text("\(topic.count) mentions")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }

    var trendIcon: String {
        switch topic.trend {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .same: return "arrow.right"
        }
    }

    var trendColor: Color {
        switch topic.trend {
        case .up: return .green
        case .down: return .red
        case .same: return .gray
        }
    }
}

struct LearningStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.title3.bold())
            Text("\(title)")
                .font(.caption.bold())
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ParentNote: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}
