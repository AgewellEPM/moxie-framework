import SwiftUI

// MARK: - RewardAchievement Model
struct RewardAchievement: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let icon: String
    let color: String
    let earnedDate: Date?
    let category: RewardAchievementCategory
    let requirement: Int
    let progress: Int

    var colorValue: Color {
        Color(hex: color)
    }

    var isEarned: Bool {
        earnedDate != nil
    }

    var progressPercentage: Double {
        min(Double(progress) / Double(requirement), 1.0)
    }

    enum RewardAchievementCategory: String, Codable, CaseIterable {
        case conversation = "Conversation"
        case learning = "Learning"
        case creativity = "Creativity"
        case consistency = "Consistency"
        case special = "Special"

        var icon: String {
            switch self {
            case .conversation: return "bubble.left.and.bubble.right.fill"
            case .learning: return "graduationcap.fill"
            case .creativity: return "paintbrush.fill"
            case .consistency: return "calendar"
            case .special: return "star.fill"
            }
        }

        var color: Color {
            switch self {
            case .conversation: return .blue
            case .learning: return .green
            case .creativity: return .purple
            case .consistency: return .orange
            case .special: return .yellow
            }
        }
    }

    init(id: UUID = UUID(), name: String, description: String, icon: String, color: String, earnedDate: Date? = nil, category: RewardAchievementCategory = .special, requirement: Int = 1, progress: Int = 0) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.color = color
        self.earnedDate = earnedDate
        self.category = category
        self.requirement = requirement
        self.progress = progress
    }
}

// MARK: - Rewards System View
struct RewardsSystemView: View {
    @Environment(\.dismiss) var dismiss
    @State private var achievements: [RewardAchievement] = []
    @State private var selectedCategory: RewardAchievement.RewardAchievementCategory?
    @State private var totalPoints: Int = 0

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
                        // Points Summary
                        pointsSummarySection

                        // Category Filter
                        categoryFilterSection

                        // RewardAchievements Grid
                        achievementsSection

                        // Recent RewardAchievements
                        recentRewardAchievementsSection

                        // Goals Section
                        goalsSection
                    }
                    .padding()
                }
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .onAppear { loadRewardAchievements() }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "medal.fill")
                        .font(.title)
                        .foregroundColor(.yellow)
                    Text("Rewards & RewardAchievements")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "9D4EDD"))
                }
                Text("Celebrate your child's accomplishments!")
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

    // MARK: - Points Summary

    private var pointsSummarySection: some View {
        HStack(spacing: 16) {
            // Total Points
            VStack(spacing: 8) {
                Text("⭐️")
                    .font(.system(size: 48))
                Text("\(totalPoints)")
                    .font(.system(size: 36, weight: .bold))
                Text("Total Points")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.yellow.opacity(0.3), .orange.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)

            // RewardAchievements Stats
            VStack(spacing: 16) {
                HStack(spacing: 24) {
                    StatItem(
                        value: "\(earnedCount)",
                        label: "Earned",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                    StatItem(
                        value: "\(achievements.count - earnedCount)",
                        label: "Remaining",
                        icon: "circle.dashed",
                        color: .gray
                    )
                    StatItem(
                        value: "\(Int(Double(earnedCount) / Double(max(achievements.count, 1)) * 100))%",
                        label: "Complete",
                        icon: "percent",
                        color: .purple
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(16)
        }
    }

    private var earnedCount: Int {
        achievements.filter { $0.isEarned }.count
    }

    // MARK: - Category Filter

    private var categoryFilterSection: some View {
        HStack(spacing: 8) {
            CategoryFilterButton(
                title: "All",
                isSelected: selectedCategory == nil,
                color: .purple
            ) {
                selectedCategory = nil
            }

            ForEach(RewardAchievement.RewardAchievementCategory.allCases, id: \.self) { category in
                CategoryFilterButton(
                    title: category.rawValue,
                    isSelected: selectedCategory == category,
                    color: category.color
                ) {
                    selectedCategory = category
                }
            }

            Spacer()
        }
    }

    // MARK: - RewardAchievements Section

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("RewardAchievements")
                .font(.headline)

            let filtered = filteredRewardAchievements
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(filtered) { achievement in
                    RewardAchievementCard(achievement: achievement)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    private var filteredRewardAchievements: [RewardAchievement] {
        if let category = selectedCategory {
            return achievements.filter { $0.category == category }
        }
        return achievements
    }

    // MARK: - Recent RewardAchievements Section

    private var recentRewardAchievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recently Earned")
                .font(.headline)

            let recent = achievements.filter { $0.isEarned }.sorted { ($0.earnedDate ?? .distantPast) > ($1.earnedDate ?? .distantPast) }.prefix(3)

            if recent.isEmpty {
                Text("No achievements earned yet. Keep playing!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(Array(recent)) { achievement in
                    RecentRewardAchievementRow(achievement: achievement)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Goals Section

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Goals in Progress")
                .font(.headline)

            let inProgress = achievements.filter { !$0.isEarned && $0.progress > 0 }.prefix(3)

            ForEach(Array(inProgress)) { achievement in
                GoalProgressRow(achievement: achievement)
            }

            if inProgress.isEmpty {
                Text("Start using Moxie to make progress on achievements!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Helpers

    private func loadRewardAchievements() {
        achievements = [
            // Conversation achievements
            RewardAchievement(name: "First Chat", description: "Have your first conversation with Moxie", icon: "bubble.left.fill", color: "3B82F6", earnedDate: Date().addingTimeInterval(-604800), category: .conversation, requirement: 1, progress: 1),
            RewardAchievement(name: "Chatty Friend", description: "Have 10 conversations", icon: "bubble.left.and.bubble.right.fill", color: "3B82F6", earnedDate: Date().addingTimeInterval(-172800), category: .conversation, requirement: 10, progress: 10),
            RewardAchievement(name: "Social Butterfly", description: "Have 50 conversations", icon: "person.3.fill", color: "3B82F6", category: .conversation, requirement: 50, progress: 23),
            RewardAchievement(name: "Curious Cat", description: "Ask 20 questions", icon: "questionmark.circle.fill", color: "3B82F6", earnedDate: Date().addingTimeInterval(-86400), category: .conversation, requirement: 20, progress: 20),

            // Learning achievements
            RewardAchievement(name: "Scholar", description: "Complete 5 learning lessons", icon: "book.fill", color: "10B981", earnedDate: Date(), category: .learning, requirement: 5, progress: 5),
            RewardAchievement(name: "Math Whiz", description: "Score 100% on a math quiz", icon: "number", color: "10B981", category: .learning, requirement: 1, progress: 0),
            RewardAchievement(name: "Word Master", description: "Learn 50 new vocabulary words", icon: "textformat.abc", color: "10B981", category: .learning, requirement: 50, progress: 32),
            RewardAchievement(name: "Science Explorer", description: "Complete 10 science lessons", icon: "atom", color: "10B981", category: .learning, requirement: 10, progress: 4),

            // Creativity achievements
            RewardAchievement(name: "Storyteller", description: "Read 5 stories", icon: "book.closed.fill", color: "8B5CF6", earnedDate: Date().addingTimeInterval(-259200), category: .creativity, requirement: 5, progress: 5),
            RewardAchievement(name: "Author", description: "Create 3 custom stories", icon: "pencil.and.scribble", color: "8B5CF6", category: .creativity, requirement: 3, progress: 1),
            RewardAchievement(name: "Music Lover", description: "Listen to 10 songs", icon: "music.note", color: "8B5CF6", category: .creativity, requirement: 10, progress: 7),

            // Consistency achievements
            RewardAchievement(name: "Daily Friend", description: "Use Moxie 3 days in a row", icon: "calendar", color: "F59E0B", earnedDate: Date().addingTimeInterval(-432000), category: .consistency, requirement: 3, progress: 3),
            RewardAchievement(name: "Week Warrior", description: "Use Moxie 7 days in a row", icon: "calendar.badge.clock", color: "F59E0B", category: .consistency, requirement: 7, progress: 5),
            RewardAchievement(name: "Monthly Champion", description: "Use Moxie 30 days in a row", icon: "crown.fill", color: "F59E0B", category: .consistency, requirement: 30, progress: 5),

            // Special achievements
            RewardAchievement(name: "Early Bird", description: "Chat before 8 AM", icon: "sunrise.fill", color: "EAB308", earnedDate: Date().addingTimeInterval(-518400), category: .special, requirement: 1, progress: 1),
            RewardAchievement(name: "Night Owl", description: "Chat after 8 PM", icon: "moon.stars.fill", color: "EAB308", category: .special, requirement: 1, progress: 0),
            RewardAchievement(name: "Birthday Star", description: "Chat on your birthday", icon: "birthday.cake.fill", color: "EAB308", category: .special, requirement: 1, progress: 0)
        ]

        totalPoints = achievements.filter { $0.isEarned }.count * 100
    }
}

// MARK: - Supporting Views

struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : Color.gray.opacity(0.1))
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct RewardAchievementCard: View {
    let achievement: RewardAchievement

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(achievement.isEarned ? achievement.colorValue.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 60, height: 60)

                Image(systemName: achievement.icon)
                    .font(.title)
                    .foregroundColor(achievement.isEarned ? achievement.colorValue : .gray)
            }

            Text(achievement.name)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.center)

            Text(achievement.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            if !achievement.isEarned && achievement.progress > 0 {
                ProgressView(value: achievement.progressPercentage)
                    .tint(achievement.colorValue)

                Text("\(achievement.progress)/\(achievement.requirement)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if achievement.isEarned {
                Text("✓ Earned")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.green)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(achievement.isEarned ? achievement.colorValue.opacity(0.05) : Color.gray.opacity(0.03))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(achievement.isEarned ? achievement.colorValue.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
}

struct RecentRewardAchievementRow: View {
    let achievement: RewardAchievement

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: achievement.icon)
                .font(.title2)
                .foregroundColor(achievement.colorValue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.name)
                    .font(.subheadline.weight(.medium))
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let date = achievement.earnedDate {
                Text(date, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(achievement.colorValue.opacity(0.1))
        .cornerRadius(12)
    }
}

struct GoalProgressRow: View {
    let achievement: RewardAchievement

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: achievement.icon)
                .font(.title2)
                .foregroundColor(achievement.colorValue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(achievement.name)
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Text("\(achievement.progress)/\(achievement.requirement)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                ProgressView(value: achievement.progressPercentage)
                    .tint(achievement.colorValue)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - RewardAchievement Badge (for use in other views)
struct RewardAchievementBadge: View {
    let achievement: RewardAchievement

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(achievement.colorValue.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundColor(achievement.colorValue)
            }

            Text(achievement.name)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 80)
    }
}
