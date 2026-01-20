import SwiftUI

/// View to display and manage all saved language learning sessions
struct LanguageSessionsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = LanguageSessionsViewModel()
    @State private var showLessonPlayer = false
    @State private var selectedSession: LanguageLearningSession?

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("🎓 My Language Learning")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
                .background(.ultraThinMaterial)

                // Content
                if viewModel.isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading your language sessions...")
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.sessions.isEmpty {
                    emptyState
                } else {
                    sessionsListView
                }
            }
        }
        .frame(minWidth: 900, minHeight: 700)
        .preferredColorScheme(.dark)
        .onAppear {
            Task {
                await viewModel.loadSessions()
            }
        }
        .sheet(isPresented: $showLessonPlayer) {
            if let session = selectedSession {
                LessonPlayerView(session: session)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("🌍")
                .font(.system(size: 100))

            VStack(spacing: 12) {
                Text("No Language Sessions Yet")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Start your language learning journey with the wizard!")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Sessions List

    private var sessionsListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.sessions) { session in
                    SessionCard(session: session) {
                        selectedSession = session
                        showLessonPlayer = true
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Session Card

struct SessionCard: View {
    let session: LanguageLearningSession
    let onResume: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onResume) {
            HStack(spacing: 20) {
                // Language flag
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.4), Color.blue.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)

                    Text(session.languageFlag)
                        .font(.system(size: 40))
                }

                // Session info
                VStack(alignment: .leading, spacing: 8) {
                    Text(session.language)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    HStack(spacing: 8) {
                        Text(session.proficiencyLevel.emoji)
                        Text(session.proficiencyLevel.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }

                    // Progress bar
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Progress")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text("\(completedLessons)/\(session.lessons.count) lessons")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [.green, .blue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * progressPercentage, height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                }

                Spacer()

                // Stats
                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 4) {
                        Text("🔥")
                        Text("\(session.progress.currentStreak)")
                            .font(.headline)
                            .foregroundColor(.orange)
                        Text("day streak")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    HStack(spacing: 4) {
                        Text("📚")
                        Text("\(session.vocabulary.count)")
                            .font(.headline)
                            .foregroundColor(.blue)
                        Text("words")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Text(relativeDateString)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }

                // Resume button
                VStack {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                }
            }
            .padding(20)
            .background(
                isHovered ?
                    Color.white.opacity(0.15) :
                    Color.white.opacity(0.1)
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isHovered ?
                            Color.green.opacity(0.6) :
                            Color.white.opacity(0.2),
                        lineWidth: isHovered ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var completedLessons: Int {
        session.lessons.filter { $0.isCompleted }.count
    }

    private var progressPercentage: Double {
        guard !session.lessons.isEmpty else { return 0 }
        return Double(completedLessons) / Double(session.lessons.count)
    }

    private var relativeDateString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Last studied " + formatter.localizedString(for: session.lastAccessedAt, relativeTo: Date())
    }
}

// MARK: - View Model

@MainActor
class LanguageSessionsViewModel: ObservableObject {
    @Published var sessions: [LanguageLearningSession] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadSessions() async {
        isLoading = true
        errorMessage = nil

        do {
            let dockerService = DIContainer.shared.resolve(DockerServiceProtocol.self)

            let pythonScript = """
            import json
            from hive.models import MoxieDevice, PersistentData

            device = MoxieDevice.objects.filter(device_id='moxie_001').first()
            if device:
                persist = PersistentData.objects.filter(device=device).first()
                if persist and persist.data:
                    language_sessions = persist.data.get('language_sessions', [])
                    print(json.dumps(language_sessions))
                else:
                    print('[]')
            else:
                print('[]')
            """

            let result = try await dockerService.executePythonScript(pythonScript)

            guard let jsonData = result.data(using: .utf8),
                  let sessionsArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
                print("Failed to parse language sessions from database")
                sessions = []
                isLoading = false
                return
            }

            // Decode sessions
            var loadedSessions: [LanguageLearningSession] = []

            for sessionDict in sessionsArray {
                guard let sessionData = try? JSONSerialization.data(withJSONObject: sessionDict),
                      let session = try? JSONDecoder().decode(LanguageLearningSession.self, from: sessionData) else {
                    continue
                }
                loadedSessions.append(session)
            }

            // Sort by last accessed (most recent first)
            sessions = loadedSessions.sorted { $0.lastAccessedAt > $1.lastAccessedAt }

        } catch {
            print("Error loading language sessions: \(error)")
            errorMessage = "Failed to load sessions: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
