import SwiftUI

struct StoryLibraryView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = StoryLibraryViewModel()

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.08),
                    Color(red: 0.08, green: 0.08, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("📚 Story Library")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
                .background(.ultraThinMaterial)

                // Content
                if viewModel.stories.isEmpty && !viewModel.isLoading {
                    // Empty state
                    VStack(spacing: 24) {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 80))
                            .foregroundColor(.white.opacity(0.3))
                            .padding(.top, 60)

                        Text("No Stories Yet")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)

                        Text("Create your first story and it will appear here")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.stories) { story in
                                StoryCard(story: story, onResume: {
                                    viewModel.selectedStory = story
                                    viewModel.showResumeView = true
                                }, onDelete: {
                                    viewModel.deleteStory(story)
                                })
                            }
                        }
                        .padding()
                    }
                }

                // Loading indicator
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                }
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $viewModel.showResumeView) {
            if let story = viewModel.selectedStory {
                StoryResumeView(story: story)
            }
        }
        .onAppear {
            Task {
                await viewModel.loadStories()
            }
        }
    }
}

// MARK: - Story Card
struct StoryCard: View {
    let story: StoryTile
    let onResume: () -> Void
    let onDelete: () -> Void
    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(genreColor.opacity(0.3))
                    .frame(width: 60, height: 60)
                Text(story.emoji)
                    .font(.system(size: 32))
            }

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(story.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)

                HStack(spacing: 12) {
                    Label(story.genre, systemImage: "tag")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))

                    Label(story.readingLevel, systemImage: "book")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }

                Text(formattedDate)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            // Actions
            HStack(spacing: 12) {
                Button(action: onResume) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Resume")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                Button(action: { showDeleteConfirmation = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                        .frame(width: 40, height: 40)
                        .background(Color.red.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(genreColor.opacity(0.3), lineWidth: 1)
        )
        .alert("Delete Story?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive, action: onDelete)
        } message: {
            Text("Are you sure you want to delete \"\(story.title)\"? This cannot be undone.")
        }
    }

    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: story.createdAt, relativeTo: Date())
    }

    private var genreColor: Color {
        switch story.genre {
        case "Adventure": return .green
        case "Fantasy": return .purple
        case "Science Fiction": return .blue
        case "Mystery": return .orange
        case "Historical": return .brown
        case "Educational": return .cyan
        default: return .gray
        }
    }
}

// MARK: - Story Resume View
struct StoryResumeView: View {
    @Environment(\.dismiss) var dismiss
    let story: StoryTile
    @StateObject private var storyViewModel = StoryTimeViewModel()

    var body: some View {
        StoryTimeView()
            .onAppear {
                Task {
                    await loadStoryIntoViewModel()
                }
            }
    }

    private func loadStoryIntoViewModel() async {
        // Load the story data from file
        guard let url = URL(string: "file://\(story.sessionFilePath)"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        // Restore story state
        if let genreStr = json["genre"] as? String,
           let genre = StoryGenre.allCases.first(where: { $0.rawValue == genreStr }) {
            storyViewModel.genre = genre
        }

        if let fictionTypeStr = json["fiction_type"] as? String,
           let fictionType = FictionType.allCases.first(where: { $0.rawValue == fictionTypeStr }) {
            storyViewModel.fictionType = fictionType
        }

        if let authorStyleStr = json["author_style"] as? String,
           let authorStyle = AuthorStyle.allCases.first(where: { $0.rawValue == authorStyleStr }) {
            storyViewModel.authorStyle = authorStyle
        }

        // Load segments and continue
        await storyViewModel.resumeStory()
    }
}

// MARK: - Story Library ViewModel
@MainActor
class StoryLibraryViewModel: ObservableObject {
    @Published var stories: [StoryTile] = []
    @Published var isLoading = false
    @Published var selectedStory: StoryTile?
    @Published var showResumeView = false

    private let tileRepository = TileRepository()

    func loadStories() async {
        isLoading = true
        stories = tileRepository.loadStoryTiles()
        isLoading = false
    }

    func deleteStory(_ story: StoryTile) {
        // Delete the story file
        let fileURL = URL(fileURLWithPath: story.sessionFilePath)
        try? FileManager.default.removeItem(at: fileURL)

        // Remove from repository
        tileRepository.deleteStoryTile(story)

        // Reload stories
        Task {
            await loadStories()
        }
    }
}
