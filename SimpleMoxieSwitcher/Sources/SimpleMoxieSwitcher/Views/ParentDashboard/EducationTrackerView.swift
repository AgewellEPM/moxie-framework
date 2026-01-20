import SwiftUI

// MARK: - Education Progress Data
struct EducationProgressData {
    var subjects: [SubjectProgress]
    var recentActivities: [LearningActivity]
    var streakDays: Int
    var totalLessons: Int
    var averageScore: Double

    struct SubjectProgress: Identifiable {
        let id = UUID()
        let subject: String
        let icon: String
        let color: Color
        let lessonsCompleted: Int
        let totalLessons: Int
        let averageScore: Double
        let lastActivity: Date
    }

    struct LearningActivity: Identifiable {
        let id = UUID()
        let subject: String
        let title: String
        let score: Int?
        let date: Date
        let duration: TimeInterval
    }
}

// MARK: - Education Tracker View
struct EducationTrackerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var progressData: EducationProgressData?
    @State private var selectedSubject: String?

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
                    if let data = progressData {
                        VStack(spacing: 24) {
                            overviewSection(data)
                            streakSection(data)
                            subjectsSection(data)
                            recentActivitySection(data)
                            recommendationsSection
                        }
                        .padding()
                    } else {
                        loadingView
                    }
                }
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .onAppear { loadProgressData() }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "graduationcap.fill")
                        .font(.title)
                        .foregroundColor(.green)
                    Text("Learning Progress")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "9D4EDD"))
                }
                Text("Track your child's educational journey with Moxie")
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

    // MARK: - Overview Section

    private func overviewSection(_ data: EducationProgressData) -> some View {
        HStack(spacing: 16) {
            EducationStatCard(
                title: "Total Lessons",
                value: "\(data.totalLessons)",
                icon: "book.fill",
                color: .blue
            )
            EducationStatCard(
                title: "Average Score",
                value: "\(Int(data.averageScore))%",
                icon: "star.fill",
                color: .yellow
            )
            EducationStatCard(
                title: "Subjects",
                value: "\(data.subjects.count)",
                icon: "square.grid.2x2.fill",
                color: .purple
            )
            EducationStatCard(
                title: "This Week",
                value: "\(data.recentActivities.filter { isThisWeek($0.date) }.count)",
                icon: "calendar",
                color: .green
            )
        }
    }

    // MARK: - Streak Section

    private func streakSection(_ data: EducationProgressData) -> some View {
        HStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("🔥")
                    .font(.system(size: 48))
                Text("\(data.streakDays) Day Streak!")
                    .font(.headline)
                Text("Keep learning every day!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(0.2)
            )
            .cornerRadius(16)

            // Weekly activity
            VStack(alignment: .leading, spacing: 12) {
                Text("This Week")
                    .font(.subheadline.weight(.medium))

                HStack(spacing: 8) {
                    ForEach(0..<7, id: \.self) { day in
                        let hasActivity = Bool.random()
                        Circle()
                            .fill(hasActivity ? Color.green : Color.gray.opacity(0.2))
                            .frame(width: 24, height: 24)
                            .overlay(
                                hasActivity ? Image(systemName: "checkmark").font(.caption2).foregroundColor(.white) : nil
                            )
                    }
                }

                Text("5 of 7 days with learning!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.white)
            .cornerRadius(16)
        }
    }

    // MARK: - Subjects Section

    private func subjectsSection(_ data: EducationProgressData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Subject Progress")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(data.subjects) { subject in
                    SubjectProgressCard(subject: subject)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Recent Activity Section

    private func recentActivitySection(_ data: EducationProgressData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Learning Activities")
                    .font(.headline)
                Spacer()
                Button("View All") {}
                    .font(.caption)
                    .foregroundColor(.blue)
            }

            ForEach(data.recentActivities.prefix(5)) { activity in
                LearningActivityRow(activity: activity)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Recommendations Section

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommended Next Steps")
                .font(.headline)

            VStack(spacing: 12) {
                RecommendationCard(
                    icon: "lightbulb.fill",
                    color: .yellow,
                    title: "Try Science!",
                    description: "Based on interest in space, try a science lesson about planets."
                )

                RecommendationCard(
                    icon: "star.fill",
                    color: .purple,
                    title: "Math Challenge",
                    description: "Ready for the next level! Try harder math problems."
                )

                RecommendationCard(
                    icon: "book.fill",
                    color: .blue,
                    title: "Reading Time",
                    description: "A new story about dinosaurs is available!"
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
            Text("Loading progress...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: 400)
    }

    // MARK: - Helpers

    private func loadProgressData() {
        progressData = EducationProgressData(
            subjects: [
                .init(subject: "Math", icon: "number", color: .blue, lessonsCompleted: 12, totalLessons: 20, averageScore: 85, lastActivity: Date().addingTimeInterval(-86400)),
                .init(subject: "Reading", icon: "book.fill", color: .green, lessonsCompleted: 8, totalLessons: 15, averageScore: 92, lastActivity: Date().addingTimeInterval(-3600)),
                .init(subject: "Science", icon: "atom", color: .purple, lessonsCompleted: 5, totalLessons: 12, averageScore: 88, lastActivity: Date().addingTimeInterval(-172800)),
                .init(subject: "Language", icon: "globe", color: .orange, lessonsCompleted: 15, totalLessons: 25, averageScore: 78, lastActivity: Date().addingTimeInterval(-259200))
            ],
            recentActivities: [
                .init(subject: "Math", title: "Addition Practice", score: 90, date: Date().addingTimeInterval(-3600), duration: 600),
                .init(subject: "Reading", title: "The Little Prince", score: nil, date: Date().addingTimeInterval(-7200), duration: 1200),
                .init(subject: "Science", title: "Solar System Quiz", score: 85, date: Date().addingTimeInterval(-86400), duration: 900),
                .init(subject: "Language", title: "Spanish Colors", score: 100, date: Date().addingTimeInterval(-172800), duration: 480)
            ],
            streakDays: 5,
            totalLessons: 40,
            averageScore: 86
        )
    }

    private func isThisWeek(_ date: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
    }
}

// MARK: - Supporting Views

struct EducationStatCard: View {
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

struct SubjectProgressCard: View {
    let subject: EducationProgressData.SubjectProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: subject.icon)
                    .font(.title2)
                    .foregroundColor(subject.color)
                Text(subject.subject)
                    .font(.headline)
                Spacer()
                Text("\(Int(subject.averageScore))%")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(subject.color)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)

                    Rectangle()
                        .fill(subject.color)
                        .frame(width: geometry.size.width * CGFloat(subject.lessonsCompleted) / CGFloat(subject.totalLessons), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(subject.lessonsCompleted)/\(subject.totalLessons) lessons")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(subject.lastActivity, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(subject.color.opacity(0.05))
        .cornerRadius(12)
    }
}

struct LearningActivityRow: View {
    let activity: EducationProgressData.LearningActivity

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(subjectColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "book.fill")
                        .foregroundColor(subjectColor)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.subheadline.weight(.medium))
                HStack {
                    Text(activity.subject)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(formatDuration(activity.duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let score = activity.score {
                Text("\(score)%")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(scoreColor(score))
            }

            Text(activity.date, style: .relative)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }

    var subjectColor: Color {
        switch activity.subject {
        case "Math": return .blue
        case "Reading": return .green
        case "Science": return .purple
        case "Language": return .orange
        default: return .gray
        }
    }

    func scoreColor(_ score: Int) -> Color {
        if score >= 90 { return .green }
        if score >= 70 { return .blue }
        if score >= 50 { return .orange }
        return .red
    }

    func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        return "\(minutes) min"
    }
}

struct RecommendationCard: View {
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

            Spacer()

            Button("Start") {}
                .font(.caption.weight(.medium))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(color)
                .cornerRadius(8)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}
