import SwiftUI

// MARK: - Mood Trends View
struct MoodTrendsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedPeriod: MoodPeriod = .week
    @State private var moodData: [MoodDataPoint] = []

    enum MoodPeriod: String, CaseIterable {
        case week = "7 Days"
        case twoWeeks = "14 Days"
        case month = "30 Days"

        var days: Int {
            switch self {
            case .week: return 7
            case .twoWeeks: return 14
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
                headerView
                    .padding()
                    .background(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)

                ScrollView {
                    VStack(spacing: 24) {
                        // Period Selector
                        periodSelector

                        // Mood Summary
                        moodSummarySection

                        // Mood Chart
                        moodChartSection

                        // Mood Distribution
                        moodDistributionSection

                        // Mood Patterns
                        moodPatternsSection

                        // Recommendations
                        recommendationsSection
                    }
                    .padding()
                }
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .onAppear { loadMoodData() }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title)
                        .foregroundColor(.blue)
                    Text("Mood Trends")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "9D4EDD"))
                }
                Text("Track your child's emotional patterns over time")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
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
            ForEach(MoodPeriod.allCases, id: \.self) { period in
                Button(action: {
                    selectedPeriod = period
                    loadMoodData()
                }) {
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

    // MARK: - Mood Summary

    private var moodSummarySection: some View {
        let averageMood = calculateAverageMood()
        let trend = calculateMoodTrend()

        return HStack(spacing: 16) {
            MoodSummaryCard(
                title: "Average Mood",
                emoji: averageMood.emoji,
                value: averageMood.displayName,
                color: moodColor(averageMood)
            )

            MoodSummaryCard(
                title: "Trend",
                emoji: trend.emoji,
                value: trend.description,
                color: trend.color
            )

            MoodSummaryCard(
                title: "Best Day",
                emoji: "📅",
                value: bestDay(),
                color: .green
            )

            MoodSummaryCard(
                title: "Conversations",
                emoji: "💬",
                value: "\(moodData.count)",
                color: .blue
            )
        }
    }

    // MARK: - Mood Chart

    private var moodChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mood Over Time")
                .font(.headline)

            MoodChartView(
                moodData: Array(moodData.suffix(selectedPeriod.days)),
                gridLabelProvider: gridLabel,
                pointColorProvider: pointColor
            )
            .frame(height: 220)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Mood Distribution

    private var moodDistributionSection: some View {
        let distribution = calculateMoodDistribution()

        return VStack(alignment: .leading, spacing: 16) {
            Text("Mood Distribution")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(Sentiment.allCases, id: \.self) { sentiment in
                    let percentage = distribution[sentiment] ?? 0
                    MoodDistributionBar(
                        sentiment: sentiment,
                        percentage: percentage
                    )
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Mood Patterns

    private var moodPatternsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Patterns Detected")
                .font(.headline)

            VStack(spacing: 12) {
                PatternRow(
                    icon: "sunrise.fill",
                    color: .orange,
                    title: "Morning Moods",
                    description: "Your child tends to be happiest in the morning conversations."
                )

                PatternRow(
                    icon: "calendar",
                    color: .blue,
                    title: "Weekend Effect",
                    description: "Mood is generally higher on weekends vs weekdays."
                )

                PatternRow(
                    icon: "book.fill",
                    color: .purple,
                    title: "Learning Impact",
                    description: "Positive mood often follows learning activities."
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Recommendations

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommendations")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                RecommendationRow(
                    icon: "lightbulb.fill",
                    color: .yellow,
                    text: "Schedule Moxie time during morning hours for best engagement."
                )

                RecommendationRow(
                    icon: "heart.fill",
                    color: .pink,
                    text: "Consider discussing any negative mood days with your child."
                )

                RecommendationRow(
                    icon: "star.fill",
                    color: .purple,
                    text: "Celebrate positive days with praise and recognition!"
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Helpers

    private func loadMoodData() {
        // Generate sample mood data
        var data: [MoodDataPoint] = []
        let calendar = Calendar.current

        for i in 0..<selectedPeriod.days {
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let sessionsPerDay = Int.random(in: 1...4)

            for _ in 0..<sessionsPerDay {
                data.append(MoodDataPoint(
                    date: date,
                    moodScore: Double.random(in: 2.5...5.0),
                    sentiment: [.veryPositive, .positive, .neutral, .negative].randomElement()!
                ))
            }
        }

        moodData = data.sorted { $0.date < $1.date }
    }

    private func calculateAverageMood() -> Sentiment {
        let avg = moodData.map { $0.moodScore }.reduce(0, +) / Double(max(moodData.count, 1))
        if avg >= 4.5 { return .veryPositive }
        if avg >= 3.5 { return .positive }
        if avg >= 2.5 { return .neutral }
        return .negative
    }

    private func calculateMoodTrend() -> (emoji: String, description: String, color: Color) {
        guard moodData.count >= 2 else { return ("➡️", "Not enough data", .gray) }

        let recentAvg = moodData.suffix(moodData.count / 2).map { $0.moodScore }.reduce(0, +) / Double(moodData.count / 2)
        let olderAvg = moodData.prefix(moodData.count / 2).map { $0.moodScore }.reduce(0, +) / Double(moodData.count / 2)

        let diff = recentAvg - olderAvg
        if diff > 0.3 { return ("📈", "Improving", .green) }
        if diff < -0.3 { return ("📉", "Declining", .orange) }
        return ("➡️", "Stable", .blue)
    }

    private func bestDay() -> String {
        let grouped = Dictionary(grouping: moodData) { Calendar.current.component(.weekday, from: $0.date) }
        let avgByDay = grouped.mapValues { points in
            points.map { $0.moodScore }.reduce(0, +) / Double(points.count)
        }

        guard let bestWeekday = avgByDay.max(by: { $0.value < $1.value })?.key else { return "N/A" }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let calendar = Calendar.current
        guard let date = calendar.date(bySetting: .weekday, value: bestWeekday, of: Date()) else { return "N/A" }
        return formatter.string(from: date)
    }

    private func calculateMoodDistribution() -> [Sentiment: Double] {
        guard !moodData.isEmpty else { return [:] }

        let grouped = Dictionary(grouping: moodData) { $0.sentiment }
        return grouped.mapValues { Double($0.count) / Double(moodData.count) }
    }

    private func moodColor(_ sentiment: Sentiment) -> Color {
        switch sentiment {
        case .veryPositive: return .green
        case .positive: return .blue
        case .neutral: return .gray
        case .negative: return .orange
        case .concerning: return .red
        }
    }

    private func gridLabel(for value: Int) -> String {
        switch value {
        case 5: return "😄"
        case 4: return "🙂"
        case 3: return "😐"
        case 2: return "😕"
        case 1: return "😟"
        default: return ""
        }
    }

    private func pointColor(for score: Double) -> Color {
        if score >= 4.5 { return .green }
        if score >= 3.5 { return .blue }
        if score >= 2.5 { return .gray }
        return .orange
    }
}

// MARK: - Supporting Models

struct MoodDataPoint {
    let date: Date
    let moodScore: Double // 1-5
    let sentiment: Sentiment
}

// MARK: - Supporting Views

struct MoodSummaryCard: View {
    let title: String
    let emoji: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(emoji)
                .font(.title)
            Text(value)
                .font(.headline)
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

struct MoodDistributionBar: View {
    let sentiment: Sentiment
    let percentage: Double

    var body: some View {
        VStack(spacing: 8) {
            Text(sentiment.emoji)
                .font(.title2)

            GeometryReader { geometry in
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(sentimentColor)
                        .frame(height: geometry.size.height * CGFloat(percentage))
                        .cornerRadius(4)
                }
            }
            .frame(height: 100)

            Text("\(Int(percentage * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    var sentimentColor: Color {
        switch sentiment {
        case .veryPositive: return .green
        case .positive: return .blue
        case .neutral: return .gray
        case .negative: return .orange
        case .concerning: return .red
        }
    }
}

struct PatternRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct RecommendationRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 12) {
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

// MARK: - Mood Chart View (extracted to help compiler)
struct MoodChartView: View {
    let moodData: [MoodDataPoint]
    let gridLabelProvider: (Int) -> String
    let pointColorProvider: (Double) -> Color

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height: CGFloat = 200
            let maxY: CGFloat = 5

            ZStack {
                gridView(height: height)
                if moodData.count > 1 {
                    chartLine(width: width, height: height, maxY: maxY)
                    chartPoints(width: width, height: height, maxY: maxY)
                }
            }
        }
    }

    private func gridView(height: CGFloat) -> some View {
        VStack(spacing: height / 5) {
            ForEach(0..<6, id: \.self) { i in
                HStack {
                    Text(gridLabelProvider(5 - i))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 30)
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 1)
                }
            }
        }
    }

    private func chartLine(width: CGFloat, height: CGFloat, maxY: CGFloat) -> some View {
        Path { path in
            for (index, point) in moodData.enumerated() {
                let x = CGFloat(index) / CGFloat(moodData.count - 1) * (width - 40) + 35
                let y = height - (CGFloat(point.moodScore) / maxY * height) + 10

                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
        .stroke(Color.purple, lineWidth: 2)
    }

    private func chartPoints(width: CGFloat, height: CGFloat, maxY: CGFloat) -> some View {
        ForEach(Array(moodData.enumerated()), id: \.offset) { index, point in
            let x = CGFloat(index) / CGFloat(moodData.count - 1) * (width - 40) + 35
            let y = height - (CGFloat(point.moodScore) / maxY * height) + 10

            Circle()
                .fill(pointColorProvider(point.moodScore))
                .frame(width: 8, height: 8)
                .position(x: x, y: y)
        }
    }
}

// Extend Sentiment to be CaseIterable for iteration
extension Sentiment: CaseIterable {
    static var allCases: [Sentiment] {
        [.veryPositive, .positive, .neutral, .negative, .concerning]
    }
}
