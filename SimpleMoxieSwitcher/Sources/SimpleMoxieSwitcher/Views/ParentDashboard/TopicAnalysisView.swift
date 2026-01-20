import SwiftUI

// MARK: - Topic Analysis View
struct TopicAnalysisView: View {
    @Environment(\.dismiss) var dismiss
    @State private var topics: [TopicData] = []
    @State private var selectedPeriod: AnalysisPeriod = .week

    enum AnalysisPeriod: String, CaseIterable {
        case week = "This Week"
        case month = "This Month"
        case allTime = "All Time"
    }

    var body: some View {
        ZStack {
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
                        periodSelector
                        topTopicsSection
                        topicCategoriesSection
                        topicTrendsSection
                        conversationExamplesSection
                    }
                    .padding()
                }
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .onAppear { loadTopics() }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "text.bubble.fill")
                        .font(.title)
                        .foregroundColor(.purple)
                    Text("Topic Analysis")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "9D4EDD"))
                }
                Text("Discover what your child is curious about")
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
            ForEach(AnalysisPeriod.allCases, id: \.self) { period in
                Button(action: {
                    selectedPeriod = period
                    loadTopics()
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

    // MARK: - Top Topics

    private var topTopicsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Top Topics")
                    .font(.headline)
                Spacer()
                Text("\(topics.count) topics detected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(topics.prefix(10)) { topic in
                    TopicAnalysisCard(topic: topic)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Topic Categories

    private var topicCategoriesSection: some View {
        let categories = groupTopicsByCategory()

        return VStack(alignment: .leading, spacing: 16) {
            Text("By Category")
                .font(.headline)

            ForEach(Array(categories.sorted { $0.value > $1.value }), id: \.key) { category, count in
                CategoryRow(category: category, count: count, total: topics.map { $0.mentions }.reduce(0, +))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Topic Trends

    private var topicTrendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trending Topics")
                .font(.headline)

            HStack(spacing: 16) {
                TrendCard(
                    title: "Rising",
                    topics: topics.filter { $0.trend == .rising }.prefix(3).map { $0.name },
                    color: .green,
                    icon: "arrow.up.right"
                )

                TrendCard(
                    title: "Consistent",
                    topics: topics.filter { $0.trend == .stable }.prefix(3).map { $0.name },
                    color: .blue,
                    icon: "arrow.right"
                )

                TrendCard(
                    title: "Declining",
                    topics: topics.filter { $0.trend == .declining }.prefix(3).map { $0.name },
                    color: .orange,
                    icon: "arrow.down.right"
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Conversation Examples

    private var conversationExamplesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Example Questions Your Child Asked")
                .font(.headline)

            VStack(spacing: 12) {
                ExampleQuestionRow(
                    question: "Why is the sky blue?",
                    topic: "Science",
                    date: Date().addingTimeInterval(-86400)
                )

                ExampleQuestionRow(
                    question: "Can dinosaurs come back?",
                    topic: "Animals",
                    date: Date().addingTimeInterval(-172800)
                )

                ExampleQuestionRow(
                    question: "How do rockets work?",
                    topic: "Space",
                    date: Date().addingTimeInterval(-259200)
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Helpers

    private func loadTopics() {
        topics = [
            TopicData(name: "Animals", category: "Nature", mentions: 45, trend: .rising, emoji: "🐾"),
            TopicData(name: "Space", category: "Science", mentions: 38, trend: .stable, emoji: "🚀"),
            TopicData(name: "Dinosaurs", category: "Nature", mentions: 32, trend: .rising, emoji: "🦕"),
            TopicData(name: "Games", category: "Play", mentions: 28, trend: .stable, emoji: "🎮"),
            TopicData(name: "School", category: "Education", mentions: 25, trend: .declining, emoji: "🏫"),
            TopicData(name: "Friends", category: "Social", mentions: 22, trend: .stable, emoji: "👫"),
            TopicData(name: "Drawing", category: "Art", mentions: 20, trend: .rising, emoji: "🎨"),
            TopicData(name: "Music", category: "Art", mentions: 18, trend: .stable, emoji: "🎵"),
            TopicData(name: "Food", category: "Daily Life", mentions: 15, trend: .declining, emoji: "🍕"),
            TopicData(name: "Sports", category: "Play", mentions: 12, trend: .rising, emoji: "⚽️")
        ]
    }

    private func groupTopicsByCategory() -> [String: Int] {
        var result: [String: Int] = [:]
        for topic in topics {
            result[topic.category, default: 0] += topic.mentions
        }
        return result
    }
}

// MARK: - Data Models

struct TopicData: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let mentions: Int
    let trend: TopicTrend
    let emoji: String

    enum TopicTrend {
        case rising, stable, declining
    }
}

// MARK: - Supporting Views

struct TopicAnalysisCard: View {
    let topic: TopicData

    var body: some View {
        HStack(spacing: 12) {
            Text(topic.emoji)
                .font(.title)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(topic.name)
                        .font(.subheadline.weight(.medium))
                    Image(systemName: trendIcon)
                        .font(.caption)
                        .foregroundColor(trendColor)
                }
                Text("\(topic.mentions) mentions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(topic.category)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }

    var trendIcon: String {
        switch topic.trend {
        case .rising: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }

    var trendColor: Color {
        switch topic.trend {
        case .rising: return .green
        case .stable: return .blue
        case .declining: return .orange
        }
    }
}

struct CategoryRow: View {
    let category: String
    let count: Int
    let total: Int

    var body: some View {
        HStack {
            Text(category)
                .font(.subheadline)

            Spacer()

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)

                    Rectangle()
                        .fill(Color.purple)
                        .frame(width: geometry.size.width * CGFloat(count) / CGFloat(max(total, 1)), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(width: 200, height: 8)

            Text("\(count)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 40)
        }
        .padding(.vertical, 4)
    }
}

struct TrendCard: View {
    let title: String
    let topics: [String]
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline.weight(.medium))
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(topics, id: \.self) { topic in
                    Text("• \(topic)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if topics.isEmpty {
                    Text("No topics")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ExampleQuestionRow: View {
    let question: String
    let topic: String
    let date: Date

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "questionmark.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text("\"\(question)\"")
                    .font(.subheadline)
                    .italic()
                HStack {
                    Text(topic)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                    Text(date, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}
