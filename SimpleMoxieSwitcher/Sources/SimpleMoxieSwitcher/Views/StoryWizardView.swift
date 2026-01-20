import SwiftUI

struct StoryWizardView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: StoryTimeViewModel
    @State private var currentStep = 0
    @State private var storyTopic = ""
    @FocusState private var isTextFieldFocused: Bool

    let totalSteps = 5

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
                // Header with progress
                VStack(spacing: 12) {
                    HStack {
                        Text("📚 Story Time Wizard")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)

                        Spacer()

                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }

                    // Progress bar
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Step \(currentStep + 1) of \(totalSteps)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue)
                                    .frame(width: geometry.size.width * CGFloat(currentStep + 1) / CGFloat(totalSteps), height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)

                // Step content
                ScrollView {
                    VStack(spacing: 24) {
                        stepContent
                    }
                    .padding(32)
                }

                // Navigation buttons
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button(action: { withAnimation { currentStep -= 1 } }) {
                            HStack {
                                Image(systemName: "arrow.left")
                                Text("Back")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    Button(action: nextStep) {
                        HStack {
                            Text(currentStep == totalSteps - 1 ? "Start Story!" : "Next")
                            if currentStep < totalSteps - 1 {
                                Image(systemName: "arrow.right")
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(canProceed ? Color.blue : Color.gray.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canProceed)
                }
                .padding()
                .background(Color.black.opacity(0.3))
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            welcomeStep
        case 1:
            readingLevelStep
        case 2:
            genreStep
        case 3:
            authorStyleStep
        case 4:
            storyTopicStep
        default:
            EmptyView()
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "book.pages.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .padding(.top, 20)

            Text("Welcome to Story Time!")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)

            Text("Let's create magical stories together with Moxie")
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 16) {
                StoryFeatureRow(icon: "wand.and.stars", text: "Choose your own adventure")
                StoryFeatureRow(icon: "book.closed.fill", text: "Pick any genre and reading level")
                StoryFeatureRow(icon: "person.fill.questionmark", text: "Write like famous authors")
                StoryFeatureRow(icon: "bookmark.fill", text: "Save and resume stories anytime")
            }
            .padding()
            .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private var readingLevelStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Choose Reading Level")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text("Select the right difficulty for your child")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))

            VStack(spacing: 12) {
                ForEach(ReadingLevel.allCases, id: \.self) { level in
                    ReadingLevelOption(
                        level: level,
                        isSelected: viewModel.readingLevel == level,
                        action: { viewModel.readingLevel = level }
                    )
                }
            }
        }
    }

    private var genreStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.purple)

            Text("Pick a Genre")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text("What kind of story do you want to create?")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(StoryGenre.allCases, id: \.self) { genre in
                    GenreOption(
                        genre: genre,
                        isSelected: viewModel.genre == genre,
                        action: { viewModel.genre = genre }
                    )
                }
            }

            VStack(spacing: 12) {
                Text("Fiction Type")
                    .font(.headline)
                    .foregroundColor(.white)

                HStack(spacing: 12) {
                    ForEach(FictionType.allCases, id: \.self) { type in
                        FictionTypeButton(
                            type: type,
                            isSelected: viewModel.fictionType == type,
                            action: { viewModel.fictionType = type }
                        )
                    }
                }
            }
        }
    }

    private var authorStyleStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "pencil.and.outline")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Writing Style")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text("Choose a writing style or enter your favorite author")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))

            // Toggle between preset and custom
            HStack {
                Button(action: { viewModel.useCustomAuthor = false }) {
                    Text("Preset Styles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(viewModel.useCustomAuthor ? .white.opacity(0.6) : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(viewModel.useCustomAuthor ? Color.clear : Color.blue, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                Button(action: {
                    viewModel.useCustomAuthor = true
                    isTextFieldFocused = true
                }) {
                    Text("Custom Author")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(viewModel.useCustomAuthor ? .white : .white.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(viewModel.useCustomAuthor ? Color.blue : Color.clear, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            .padding(4)
            .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))

            if viewModel.useCustomAuthor {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Enter Author Name")
                        .font(.headline)
                        .foregroundColor(.white)

                    TextField("e.g., Stephen King, R.L. Stine, J.K. Rowling", text: $viewModel.customAuthor)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .focused($isTextFieldFocused)

                    Text("💡 Examples: Ernest Hemingway, Dr. Seuss, Roald Dahl, Agatha Christie, J.R.R. Tolkien")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding()
                .background(Color.blue.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 12) {
                    ForEach(AuthorStyle.allCases, id: \.self) { style in
                        AuthorStyleOption(
                            style: style,
                            isSelected: viewModel.authorStyle == style,
                            action: { viewModel.authorStyle = style }
                        )
                    }
                }
            }
        }
    }

    private var storyTopicStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)

            Text("What's Your Story About?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text("Tell Moxie what you want the story to be about")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))

            VStack(alignment: .leading, spacing: 12) {
                Text("Story Topic or Idea")
                    .font(.headline)
                    .foregroundColor(.white)

                TextEditor(text: $storyTopic)
                    .font(.body)
                    .foregroundColor(.white)
                    .frame(height: 120)
                    .scrollContentBackground(.hidden)
                    .padding()
                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .overlay(
                        Group {
                            if storyTopic.isEmpty {
                                Text("e.g., a brave knight who lost his sword, a princess who can talk to animals, a robot learning to feel emotions...")
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding()
                                    .allowsHitTesting(false)
                            }
                        },
                        alignment: .topLeading
                    )
            }

            // Summary card
            VStack(alignment: .leading, spacing: 12) {
                Text("📋 Your Story Settings")
                    .font(.headline)
                    .foregroundColor(.white)

                SummaryRow(label: "Reading Level", value: viewModel.readingLevel.rawValue)
                SummaryRow(label: "Genre", value: viewModel.genre.rawValue)
                SummaryRow(label: "Type", value: viewModel.fictionType.rawValue)
                SummaryRow(label: "Writing Style", value: viewModel.useCustomAuthor ? viewModel.customAuthor : viewModel.authorStyle.rawValue)
            }
            .padding()
            .background(Color.green.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var canProceed: Bool {
        switch currentStep {
        case 3:
            return viewModel.useCustomAuthor ? !viewModel.customAuthor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty : true
        case 4:
            return !storyTopic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default:
            return true
        }
    }

    private func nextStep() {
        if currentStep < totalSteps - 1 {
            withAnimation {
                currentStep += 1
            }
        } else {
            // Start the story!
            Task {
                await viewModel.startStory(topic: storyTopic)
                dismiss()
            }
        }
    }
}

// MARK: - Supporting Views

struct StoryFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 32)
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.white)
            Spacer()
        }
    }
}

struct ReadingLevelOption: View {
    let level: ReadingLevel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(level.rawValue)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(
                isSelected ? Color.green.opacity(0.3) : Color.white.opacity(0.1),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.green : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct GenreOption: View {
    let genre: StoryGenre
    let isSelected: Bool
    let action: () -> Void

    private var icon: String {
        switch genre {
        case .adventure: return "🗺️"
        case .fantasy: return "🧙‍♂️"
        case .sciFi: return "🚀"
        case .mystery: return "🔍"
        case .historical: return "🏛️"
        case .educational: return "🎓"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(icon)
                    .font(.system(size: 32))
                Text(genre.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSelected ? Color.purple.opacity(0.3) : Color.white.opacity(0.1),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.purple : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct FictionTypeButton: View {
    let type: FictionType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(type.rawValue)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    isSelected ? Color.purple : Color.white.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 8)
                )
        }
        .buttonStyle(.plain)
    }
}

struct AuthorStyleOption: View {
    let style: AuthorStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(style.rawValue)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.orange)
                }
            }
            .padding()
            .background(
                isSelected ? Color.orange.opacity(0.3) : Color.white.opacity(0.1),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.orange : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label + ":")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}
