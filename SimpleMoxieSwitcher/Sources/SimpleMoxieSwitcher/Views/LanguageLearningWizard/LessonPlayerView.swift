import SwiftUI

/// Interactive lesson player where you practice with Moxie
struct LessonPlayerView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: LessonPlayerViewModel

    init(session: LanguageLearningSession) {
        _viewModel = StateObject(wrappedValue: LessonPlayerViewModel(session: session))
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.purple.opacity(0.4), Color.blue.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                Divider()

                // Main content
                if let currentLesson = viewModel.currentLesson {
                    lessonContentView(lesson: currentLesson)
                } else {
                    completionView
                }
            }
        }
        .frame(minWidth: 900, minHeight: 700)
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                // Language info
                HStack(spacing: 12) {
                    Text(viewModel.session.languageFlag)
                        .font(.largeTitle)
                    VStack(alignment: .leading) {
                        Text(viewModel.session.language)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text(viewModel.session.proficiencyLevel.rawValue)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                Spacer()

                // Progress
                Text("Lesson \(viewModel.currentLessonIndex + 1)/\(viewModel.session.lessons.count)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.green, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progressPercentage, height: 6)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Lesson Content

    private func lessonContentView(lesson: LanguageLesson) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Moxie greeting
                MoxieSpeechBubble(
                    message: viewModel.getMoxieGreeting(for: lesson),
                    personality: "Teacher"
                )
                .padding(.top)

                // Lesson header
                VStack(spacing: 12) {
                    Text(lesson.category.icon)
                        .font(.system(size: 60))

                    Text(lesson.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text(lesson.description)
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)

                    // Difficulty indicator
                    HStack(spacing: 4) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < lesson.difficultyLevel ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(index < lesson.difficultyLevel ? .yellow : .white.opacity(0.3))
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)

                // Practice button
                Button(action: {
                    viewModel.startLesson()
                }) {
                    HStack(spacing: 12) {
                        if viewModel.isLessonInProgress {
                            Text("Continue Practicing")
                        } else if lesson.isCompleted {
                            Text("Practice Again")
                        } else {
                            Text("Start Lesson")
                        }
                        Image(systemName: "play.circle.fill")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: .green.opacity(0.5), radius: 10)
                }
                .buttonStyle(.plain)

                // Navigation buttons
                HStack(spacing: 16) {
                    if viewModel.canGoPrevious {
                        Button(action: {
                            viewModel.previousLesson()
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Previous Lesson")
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(20)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    if viewModel.canGoNext {
                        Button(action: {
                            viewModel.nextLesson()
                        }) {
                            HStack {
                                Text("Next Lesson")
                                Image(systemName: "chevron.right")
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(20)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top)
            }
            .padding()
        }
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("🎉")
                .font(.system(size: 100))

            VStack(spacing: 12) {
                Text("All Lessons Complete!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Amazing work! You've completed all lessons in this session.")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }

            // Stats
            VStack(spacing: 12) {
                StatRow(icon: "🎓", label: "Lessons Completed", value: "\(viewModel.session.lessons.count)")
                StatRow(icon: "📚", label: "Vocabulary Words", value: "\(viewModel.session.vocabulary.count)")
                StatRow(icon: "🔥", label: "Current Streak", value: "\(viewModel.session.progress.currentStreak) days")
                StatRow(icon: "⏱️", label: "Study Time", value: "\(viewModel.session.progress.studyTimeMinutes) min")
            }
            .padding(24)
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)

            Button(action: { dismiss() }) {
                Text("Back to Sessions")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding()
    }

    private var progressPercentage: Double {
        guard !viewModel.session.lessons.isEmpty else { return 0 }
        return Double(viewModel.currentLessonIndex + 1) / Double(viewModel.session.lessons.count)
    }
}

// MARK: - Stat Row

struct StatRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(icon)
                .font(.title2)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))

            Spacer()

            Text(value)
                .font(.headline)
                .foregroundColor(.white)
        }
    }
}

// MARK: - View Model

@MainActor
class LessonPlayerViewModel: ObservableObject {
    @Published var session: LanguageLearningSession
    @Published var currentLessonIndex = 0
    @Published var isLessonInProgress = false

    init(session: LanguageLearningSession) {
        self.session = session
        // Find first incomplete lesson
        if let firstIncomplete = session.lessons.firstIndex(where: { !$0.isCompleted }) {
            currentLessonIndex = firstIncomplete
        }
    }

    var currentLesson: LanguageLesson? {
        guard currentLessonIndex < session.lessons.count else { return nil }
        return session.lessons[currentLessonIndex]
    }

    var canGoPrevious: Bool {
        currentLessonIndex > 0
    }

    var canGoNext: Bool {
        currentLessonIndex < session.lessons.count - 1
    }

    func getMoxieGreeting(for lesson: LanguageLesson) -> String {
        if lesson.isCompleted {
            return "Welcome back! You've already completed this lesson, but practice makes perfect! Want to review '\(lesson.title)'? 📚"
        } else {
            return "Hi! I'm so excited to teach you about '\(lesson.title)'! This is a \(lesson.category.rawValue) lesson. Let's learn together! 🎓"
        }
    }

    func startLesson() {
        isLessonInProgress = true
        // TODO: Implement interactive lesson practice
        // This will open the actual exercise interface
        print("Starting lesson: \(currentLesson?.title ?? "")")
    }

    func nextLesson() {
        if canGoNext {
            currentLessonIndex += 1
            isLessonInProgress = false
        }
    }

    func previousLesson() {
        if canGoPrevious {
            currentLessonIndex -= 1
            isLessonInProgress = false
        }
    }

    func markLessonComplete() {
        // Update lesson completion
        session.lessons[currentLessonIndex].isCompleted = true
        session.progress.totalLessonsCompleted += 1

        // Update progress in database
        Task {
            await saveProgress()
        }
    }

    private func saveProgress() async {
        let dockerService = DIContainer.shared.resolve(DockerServiceProtocol.self)

        guard let jsonData = try? JSONEncoder().encode(session),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }

        let pythonScript = """
        import json
        from hive.models import MoxieDevice, PersistentData

        device = MoxieDevice.objects.filter(device_id='moxie_001').first()
        if device:
            persist = PersistentData.objects.filter(device=device).first()
            if persist and persist.data:
                data = persist.data
                language_sessions = data.get('language_sessions', [])

                # Find and update the session
                session_data = json.loads('''\(jsonString)''')
                for i, session in enumerate(language_sessions):
                    if session.get('id') == '\(session.id)':
                        language_sessions[i] = session_data
                        break

                data['language_sessions'] = language_sessions
                persist.data = data
                persist.save()
                print('Progress saved!')
        """

        do {
            _ = try await dockerService.executePythonScript(pythonScript)
            print("Progress saved successfully")
        } catch {
            print("Failed to save progress: \(error)")
        }
    }
}
