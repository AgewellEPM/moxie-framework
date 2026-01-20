import SwiftUI
import AVFoundation
import Speech

struct StoryTimeView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = StoryTimeViewModel()
    @State private var userInput = ""
    @State private var showSettings = false
    @State private var showWizard = false
    @State private var showLibrary = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            // Dark gradient background
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
                    Text("📚 Story Time")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    // Library button
                    Button(action: { showLibrary.toggle() }) {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 12)

                    // Settings button
                    Button(action: { showSettings.toggle() }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 12)

                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
                .background(.ultraThinMaterial)

                // Settings Panel
                if showSettings {
                    StorySettingsPanel(viewModel: viewModel)
                }

                // Story Content
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            // Welcome banner when story is empty - SIMPLE AND CLEAN
                            if viewModel.storySegments.isEmpty && !viewModel.isLoading {
                                VStack(spacing: 32) {
                                    Spacer()

                                    Image(systemName: "book.pages")
                                        .font(.system(size: 80))
                                        .foregroundColor(.white.opacity(0.7))

                                    VStack(spacing: 12) {
                                        Text("Create a Story")
                                            .font(.system(size: 32, weight: .bold))
                                            .foregroundColor(.white)

                                        Text("Tell me what story you'd like to create")
                                            .font(.system(size: 18))
                                            .foregroundColor(.white.opacity(0.8))
                                    }

                                    Button(action: { showWizard = true }) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "wand.and.stars")
                                            Text("Use Story Wizard")
                                        }
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 32)
                                        .padding(.vertical, 16)
                                        .background(
                                            LinearGradient(
                                                colors: [Color.blue, Color.purple],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                            in: RoundedRectangle(cornerRadius: 14)
                                        )
                                        .shadow(color: Color.blue.opacity(0.3), radius: 10, y: 5)
                                    }
                                    .buttonStyle(.plain)

                                    Spacer()
                                }
                                .frame(maxWidth: .infinity)
                            }

                            // Story messages (like chat)
                            ForEach(viewModel.storySegments) { segment in
                                StorySegmentView(segment: segment)
                                    .id(segment.id)
                            }

                            // Show ALL choices (including the ones not chosen)
                            if !viewModel.allChoicesHistory.isEmpty {
                                ForEach(viewModel.allChoicesHistory) { choiceSet in
                                    ChoiceHistoryView(choiceSet: choiceSet)
                                        .id(choiceSet.id)
                                }
                            }

                            // Loading indicator
                            if viewModel.isLoading {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Moxie is thinking...")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding()
                            }

                            // Current choice buttons (show only if we have choices and not loading)
                            if !viewModel.currentChoices.isEmpty && !viewModel.isLoading {
                                VStack(spacing: 12) {
                                    Text("What happens next?")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.top)

                                    ForEach(Array(viewModel.currentChoices.enumerated()), id: \.offset) { index, choice in
                                        ChoiceButton(
                                            number: index + 1,
                                            text: choice,
                                            action: {
                                                Task {
                                                    await viewModel.makeChoice(choice)
                                                }
                                            }
                                        )
                                    }
                                }
                                .padding()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.storySegments.count) { _ in
                        scrollToBottom(proxy)
                    }
                    .onChange(of: viewModel.allChoicesHistory.count) { _ in
                        scrollToBottom(proxy)
                    }
                }

                // Error message
                if let error = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Button("Dismiss") {
                            viewModel.errorMessage = nil
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color.red.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal)
                }

                // Input area (like chat - always visible)
                VStack(spacing: 8) {
                    HStack(alignment: .bottom, spacing: 12) {
                        // Microphone button for voice input
                        Button(action: {
                            viewModel.toggleListening()
                        }) {
                            Image(systemName: viewModel.isListening ? "mic.fill" : "mic")
                                .font(.system(size: 24))
                                .foregroundColor(viewModel.isListening ? .red : .blue)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.1), in: Circle())
                        }
                        .buttonStyle(.plain)

                        // Text input
                        ZStack(alignment: .topLeading) {
                            if userInput.isEmpty && !viewModel.isListening {
                                Text(viewModel.storySegments.isEmpty ? "Tell me what story you want..." : "Continue the story or ask a question...")
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 14)
                                    .allowsHitTesting(false)
                            }

                            TextEditor(text: $userInput)
                                .font(.body)
                                .foregroundColor(.white)
                                .frame(minHeight: 44, maxHeight: 100)
                                .focused($isInputFocused)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                        }
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )

                        // Send button
                        Button(action: {
                            sendMessage()
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(canSend ? .blue : .gray)
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSend)
                    }
                    .padding()

                    // Listening indicator
                    if viewModel.isListening {
                        HStack {
                            Image(systemName: "waveform")
                                .foregroundColor(.red)
                            Text("Listening...")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                }
                .background(Color.black.opacity(0.3))

                // Control buttons at bottom
                HStack(spacing: 16) {
                    if !viewModel.storySegments.isEmpty {
                        Button(action: {
                            Task {
                                await viewModel.saveStory()
                            }
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Save Story")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            viewModel.resetStory()
                        }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("New Story")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            Task {
                                await viewModel.resumeStory()
                            }
                        }) {
                            HStack {
                                Image(systemName: "play.circle")
                                Text("Resume")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    Text("\(viewModel.storySegments.count) segments")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding()
                .background(Color.black.opacity(0.2))
            }
        }
        .frame(minWidth: 900, minHeight: 700)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showWizard) {
            StoryWizardView(viewModel: viewModel)
        }
        .sheet(isPresented: $showLibrary) {
            StoryLibraryView()
        }
        .onAppear {
            viewModel.initializeSpeechRecognition()
            Task {
                await viewModel.loadPreviousStories()
            }
        }
    }

    private var canSend: Bool {
        !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isLoading
    }

    private func sendMessage() {
        let text = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        userInput = ""
        Task {
            if viewModel.storySegments.isEmpty {
                await viewModel.startStory(topic: text)
            } else {
                await viewModel.continueWithCustomInput(text)
            }
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        if let lastChoice = viewModel.allChoicesHistory.last {
            withAnimation {
                proxy.scrollTo(lastChoice.id, anchor: .bottom)
            }
        } else if let lastSegment = viewModel.storySegments.last {
            withAnimation {
                proxy.scrollTo(lastSegment.id, anchor: .bottom)
            }
        }
    }
}

// MARK: - Story Settings Panel
struct StorySettingsPanel: View {
    @ObservedObject var viewModel: StoryTimeViewModel

    var body: some View {
        VStack(spacing: 12) {
            // Instructions Section
            VStack(alignment: .leading, spacing: 8) {
                Text("📖 How Story Time Works")
                    .font(.headline)
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 6) {
                    InstructionRow(number: "1", text: "Type what story you want (e.g., \"a brave knight\")")
                    InstructionRow(number: "2", text: "Moxie creates the opening and gives 3 choices")
                    InstructionRow(number: "3", text: "Tap a choice OR type your own adventure idea")
                    InstructionRow(number: "4", text: "The story continues based on your choices!")
                    InstructionRow(number: "5", text: "Save creates a tile you can resume anytime")
                }
                .padding(.leading, 8)
            }
            .padding()
            .background(Color.blue.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))

            Divider()
                .background(Color.white.opacity(0.3))

            Text("🎨 Customize Your Story")
                .font(.headline)
                .foregroundColor(.white)

            // Reading Level
            HStack {
                Text("Reading Level:")
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 120, alignment: .leading)
                Picker("", selection: $viewModel.readingLevel) {
                    ForEach(ReadingLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(.menu)
            }

            // Genre
            HStack {
                Text("Genre:")
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 120, alignment: .leading)
                Picker("", selection: $viewModel.genre) {
                    ForEach(StoryGenre.allCases, id: \.self) { genre in
                        Text(genre.rawValue).tag(genre)
                    }
                }
                .pickerStyle(.menu)
            }

            // Fiction Type
            HStack {
                Text("Type:")
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 120, alignment: .leading)
                Picker("", selection: $viewModel.fictionType) {
                    ForEach(FictionType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)
            }

            // Author Style
            HStack {
                Text("Author Style:")
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 120, alignment: .leading)
                Picker("", selection: $viewModel.authorStyle) {
                    ForEach(AuthorStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

// MARK: - Help Row (for welcome banner)
struct HelpRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
            Spacer()
        }
    }
}

// MARK: - Instruction Row (for settings panel)
struct InstructionRow: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 24, height: 24)
                Text(number)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }
}

// MARK: - Story Segment View
struct StorySegmentView: View {
    let segment: StorySegment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let choice = segment.choiceMade {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                    Text("You: \(choice)")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .italic()
                }
            }

            HStack(alignment: .top, spacing: 8) {
                Text("📚")
                    .font(.title2)
                Text(segment.text)
                    .font(.body)
                    .foregroundColor(.white)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [Color.purple.opacity(0.2), Color.blue.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

// MARK: - Choice History View
struct ChoiceHistoryView: View {
    let choiceSet: ChoiceSet

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Available choices:")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))

            ForEach(Array(choiceSet.choices.enumerated()), id: \.offset) { index, choice in
                HStack {
                    Text("\(index + 1).")
                        .font(.caption)
                        .foregroundColor(choice == choiceSet.selected ? .green : .white.opacity(0.4))
                    Text(choice)
                        .font(.caption)
                        .foregroundColor(choice == choiceSet.selected ? .green : .white.opacity(0.4))
                    if choice == choiceSet.selected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Choice Button
struct ChoiceButton: View {
    let number: Int
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 32, height: 32)
                    Text("\(number)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }

                Text(text)
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)

                Spacer()

                Image(systemName: "arrow.right")
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Models
struct StorySegment: Identifiable {
    let id = UUID()
    let text: String
    let choiceMade: String?
}

struct ChoiceSet: Identifiable {
    let id = UUID()
    let choices: [String]
    let selected: String?
}

enum StoryGenre: String, CaseIterable {
    case adventure = "Adventure"
    case fantasy = "Fantasy"
    case sciFi = "Science Fiction"
    case mystery = "Mystery"
    case historical = "Historical"
    case educational = "Educational"
}

enum FictionType: String, CaseIterable {
    case fiction = "Fiction"
    case nonFiction = "Non-Fiction"
    case realistic = "Realistic Fiction"
    case fairytale = "Fairy Tale"
}

enum AuthorStyle: String, CaseIterable {
    case simple = "Simple (Dr. Seuss)"
    case descriptive = "Descriptive (Roald Dahl)"
    case adventurous = "Adventurous (Jules Verne)"
    case concise = "Concise (Hemingway)"
    case poetic = "Poetic (Lewis Carroll)"
    case suspenseful = "Suspenseful (Edgar Allan Poe)"
}

enum ReadingLevel: String, CaseIterable {
    case preschool = "Preschool (Ages 3-5)"
    case earlyReader = "Early Reader (Ages 5-7)"
    case elementary = "Elementary (Ages 8-10)"
    case middleGrade = "Middle Grade (Ages 10-12)"
    case youngAdult = "Young Adult (Ages 13+)"
    case adult = "Adult"
}

// MARK: - Story Time ViewModel
@MainActor
class StoryTimeViewModel: ObservableObject {
    @Published var storySegments: [StorySegment] = []
    @Published var allChoicesHistory: [ChoiceSet] = []
    @Published var currentChoices: [String] = []
    @Published var isLoading = false
    @Published var isListening = false
    @Published var errorMessage: String?

    @Published var genre: StoryGenre = .adventure
    @Published var fictionType: FictionType = .fiction
    @Published var authorStyle: AuthorStyle = .simple
    @Published var customAuthor: String = "" // e.g., "Stephen King", "R.L. Stine"
    @Published var useCustomAuthor: Bool = false
    @Published var readingLevel: ReadingLevel = .elementary

    private var storyContext: [String] = []
    private let storiesDir = AppPaths.stories
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let tileRepository: TileRepository = TileRepository()
    private let aiService: AIServiceProtocol = AIService() // Use cached AI service

    func initializeSpeechRecognition() {
        speechRecognizer = SFSpeechRecognizer()

        SFSpeechRecognizer.requestAuthorization { status in
            // Handle authorization
        }
    }

    func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }

    private func startListening() {
        // Implementation for speech recognition would go here
        isListening = true
    }

    private func stopListening() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        isListening = false
    }

    func startStory(topic: String) async {
        guard !topic.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            let stylePrompt = getStylePrompt()
            let levelPrompt = getReadingLevelPrompt()
            let authorName = useCustomAuthor ? customAuthor : authorStyle.rawValue
            let prompt = """
            You are a creative storyteller. Create a \(genre.rawValue) story in the style of \(authorName) about: \(topic)

            Type: \(fictionType.rawValue)
            Reading Level: \(readingLevel.rawValue)

            \(stylePrompt)
            \(levelPrompt)

            Write an engaging opening paragraph (3-5 sentences) that sets the scene.
            Then provide exactly 3 different choices for what happens next. Make this a "Choose Your Own Adventure" style story.

            Format your response as JSON:
            {
                "story": "The story text here...",
                "choices": ["Choice 1", "Choice 2", "Choice 3"]
            }
            """

            let response = try await callAI(prompt: prompt)

            if let data = response.data(using: .utf8),
               let json = try? JSONDecoder().decode(StoryResponse.self, from: data) {

                storySegments.append(StorySegment(text: json.story, choiceMade: nil))
                currentChoices = json.choices
                allChoicesHistory.append(ChoiceSet(choices: json.choices, selected: nil))
                storyContext.append(json.story)

                // Trigger prefetch for all choices
                await triggerPrefetch(choices: json.choices)
            }
        } catch {
            errorMessage = "Failed to generate story: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func makeChoice(_ choice: String) async {
        guard !choice.isEmpty else { return }

        // Record the choice
        if let lastIndex = allChoicesHistory.indices.last {
            allChoicesHistory[lastIndex] = ChoiceSet(
                choices: allChoicesHistory[lastIndex].choices,
                selected: choice
            )
        }

        isLoading = true
        errorMessage = nil
        currentChoices = []

        // Check for prefetched content first
        if let prefetched = await StoryPrefetchService.shared.getContinuation(
            storyContext: storyContext,
            choice: choice
        ) {
            // Use prefetched content - instant response!
            print("📖 Using prefetched story continuation")
            await CacheAnalyticsService.shared.recordCacheHit(category: .story, tokensSaved: 600)

            storySegments.append(StorySegment(text: prefetched.storyText, choiceMade: choice))
            currentChoices = prefetched.nextChoices
            allChoicesHistory.append(ChoiceSet(choices: prefetched.nextChoices, selected: nil))
            storyContext.append(prefetched.storyText)

            // Prefetch next choices
            await triggerPrefetch(choices: prefetched.nextChoices)

            isLoading = false
            return
        }

        // No prefetch available - generate normally
        do {
            let contextText = storyContext.joined(separator: "\n\n")
            let stylePrompt = getStylePrompt()
            let levelPrompt = getReadingLevelPrompt()
            let authorName = useCustomAuthor ? customAuthor : authorStyle.rawValue

            let prompt = """
            Continue this \(genre.rawValue) story in the style of \(authorName) based on the choice: "\(choice)"

            Reading Level: \(readingLevel.rawValue)

            Previous story:
            \(contextText)

            \(stylePrompt)
            \(levelPrompt)

            Write the next paragraph (3-5 sentences) that follows from this choice.
            Then provide exactly 3 new choices for what happens next.

            Format your response as JSON:
            {
                "story": "The continuation text here...",
                "choices": ["Choice 1", "Choice 2", "Choice 3"]
            }
            """

            let response = try await callAI(prompt: prompt)

            if let data = response.data(using: .utf8),
               let json = try? JSONDecoder().decode(StoryResponse.self, from: data) {

                storySegments.append(StorySegment(text: json.story, choiceMade: choice))
                currentChoices = json.choices
                allChoicesHistory.append(ChoiceSet(choices: json.choices, selected: nil))
                storyContext.append(json.story)

                // Prefetch next choices
                await triggerPrefetch(choices: json.choices)
            }
        } catch {
            errorMessage = "Failed to continue story: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Trigger background prefetch for story choices
    private func triggerPrefetch(choices: [String]) async {
        await StoryPrefetchService.shared.prefetchContinuations(
            storyContext: storyContext,
            choices: choices,
            genre: genre.rawValue,
            authorStyle: authorStyle.rawValue,
            readingLevel: readingLevel.rawValue
        )
    }

    func continueWithCustomInput(_ input: String) async {
        // Allow custom input instead of choosing from options
        await makeChoice(input)
    }

    func saveStory() async {
        // Create directory if needed
        try? FileManager.default.createDirectory(at: storiesDir, withIntermediateDirectories: true)

        let timestamp = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let dateString = formatter.string(from: timestamp)

        let filename = "story_\(genre.rawValue.lowercased())_\(dateString).json"
        let fileURL = storiesDir.appendingPathComponent(filename)

        let storyData: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: timestamp),
            "genre": genre.rawValue,
            "fiction_type": fictionType.rawValue,
            "author_style": authorStyle.rawValue,
            "reading_level": readingLevel.rawValue,
            "segments": storySegments.map { [
                "text": $0.text,
                "choice_made": $0.choiceMade ?? ""
            ]},
            "choice_history": allChoicesHistory.map { [
                "choices": $0.choices,
                "selected": $0.selected ?? ""
            ]}
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: storyData, options: .prettyPrinted)
            try jsonData.write(to: fileURL)
            print("Story saved to: \(fileURL.path)")

            // Create and save a StoryTile
            // Generate title from first story segment
            let storyTitle: String
            if let firstSegment = storySegments.first {
                let text = firstSegment.text
                if text.count <= 50 {
                    storyTitle = text
                } else {
                    // Take first 50 characters and try to find a natural break
                    let prefix = String(text.prefix(50))
                    if let lastSpace = prefix.lastIndex(of: " ") {
                        storyTitle = String(text.prefix(upTo: lastSpace)) + "..."
                    } else {
                        storyTitle = prefix + "..."
                    }
                }
            } else {
                storyTitle = "\(genre.rawValue) Story"
            }

            let storyTile = StoryTile(
                title: storyTitle,
                genre: genre.rawValue,
                authorStyle: authorStyle.rawValue,
                readingLevel: readingLevel.rawValue,
                sessionFilePath: fileURL.path,
                emoji: "📚"
            )
            tileRepository.saveStoryTile(storyTile)
            print("Story tile saved: \(storyTitle)")
        } catch {
            errorMessage = "Failed to save story: \(error.localizedDescription)"
        }
    }

    func resetStory() {
        storySegments = []
        allChoicesHistory = []
        currentChoices = []
        storyContext = []
        errorMessage = nil
    }

    func loadPreviousStories() async {
        // Implementation to load previous story sessions
        // This could show a list of saved stories to resume
    }

    func resumeStory() async {
        // Continue from where we left off
        if !storySegments.isEmpty && !currentChoices.isEmpty {
            // Story already in progress, just continue
            return
        }

        // Try to load the most recent story
        do {
            try? FileManager.default.createDirectory(at: storiesDir, withIntermediateDirectories: true)

            let files = try FileManager.default.contentsOfDirectory(at: storiesDir, includingPropertiesForKeys: [.creationDateKey], options: [.skipsHiddenFiles])

            guard let mostRecent = files.sorted(by: { file1, file2 in
                let date1 = (try? file1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                let date2 = (try? file2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                return date1 > date2
            }).first else {
                errorMessage = "No saved stories found"
                return
            }

            let data = try Data(contentsOf: mostRecent)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                errorMessage = "Failed to load story"
                return
            }

            // Restore story state
            if let genreStr = json["genre"] as? String,
               let genre = StoryGenre.allCases.first(where: { $0.rawValue == genreStr }) {
                self.genre = genre
            }

            if let fictionTypeStr = json["fiction_type"] as? String,
               let fictionType = FictionType.allCases.first(where: { $0.rawValue == fictionTypeStr }) {
                self.fictionType = fictionType
            }

            if let authorStyleStr = json["author_style"] as? String,
               let authorStyle = AuthorStyle.allCases.first(where: { $0.rawValue == authorStyleStr }) {
                self.authorStyle = authorStyle
            }

            if let segments = json["segments"] as? [[String: String]] {
                storySegments = segments.map { seg in
                    StorySegment(text: seg["text"] ?? "", choiceMade: seg["choice_made"])
                }
                storyContext = storySegments.map { $0.text }
            }

            if let choiceHistory = json["choice_history"] as? [[String: Any]] {
                allChoicesHistory = choiceHistory.map { ch in
                    ChoiceSet(
                        choices: ch["choices"] as? [String] ?? [],
                        selected: ch["selected"] as? String
                    )
                }
            }

            // Generate new choices to continue
            if !storySegments.isEmpty {
                let contextText = storyContext.joined(separator: "\n\n")
                let stylePrompt = getStylePrompt()

                let prompt = """
                Continue this \(genre.rawValue) story in the style of \(authorStyle.rawValue).

                Previous story:
                \(contextText)

                \(stylePrompt)

                Provide exactly 3 new choices for what happens next to continue the adventure.

                Format your response as JSON:
                {
                    "choices": ["Choice 1", "Choice 2", "Choice 3"]
                }
                """

                let response = try await callAI(prompt: prompt)

                if let data = response.data(using: .utf8),
                   let json = try? JSONDecoder().decode(ResumeResponse.self, from: data) {
                    currentChoices = json.choices
                    allChoicesHistory.append(ChoiceSet(choices: json.choices, selected: nil))
                }
            }
        } catch {
            errorMessage = "Failed to resume story: \(error.localizedDescription)"
        }
    }

    private func getStylePrompt() -> String {
        if useCustomAuthor && !customAuthor.isEmpty {
            return "Write in the distinctive style of \(customAuthor). Capture their unique voice, tone, and storytelling techniques."
        }

        switch authorStyle {
        case .simple:
            return "Use simple, rhythmic language like Dr. Seuss. Keep sentences short and fun."
        case .descriptive:
            return "Use rich, vivid descriptions like Roald Dahl. Paint detailed pictures with words."
        case .adventurous:
            return "Use exciting, action-packed language like Jules Verne. Build suspense and wonder."
        case .concise:
            return "Use short, powerful sentences like Hemingway. Be direct and impactful."
        case .poetic:
            return "Use playful, imaginative language like Lewis Carroll. Include wordplay and whimsy."
        case .suspenseful:
            return "Use dark, atmospheric language like Edgar Allan Poe. Build tension and mystery."
        }
    }

    private func getReadingLevelPrompt() -> String {
        switch readingLevel {
        case .preschool:
            return "Use very simple words and short sentences (3-5 words). Focus on basic concepts and repetition. Like 'See Spot run.'"
        case .earlyReader:
            return "Use simple vocabulary and short sentences (5-8 words). Include some sight words and basic punctuation."
        case .elementary:
            return "Use age-appropriate vocabulary with moderate sentence length (8-12 words). Include descriptive words and varied sentence structure."
        case .middleGrade:
            return "Use engaging vocabulary with complex sentences. Include figurative language and more advanced concepts."
        case .youngAdult:
            return "Use sophisticated vocabulary and varied sentence structure. Include mature themes and complex character development."
        case .adult:
            return "Use advanced vocabulary and literary techniques. Include nuanced themes and sophisticated narrative structure."
        }
    }

    private func callAI(prompt: String) async throws -> String {
        // Use the centralized AIService which includes caching, analytics, and usage tracking
        let systemPrompt = "You are a creative storyteller for children. Always respond in valid JSON format."
        let fullPrompt = "\(systemPrompt)\n\n\(prompt)"

        let response = try await aiService.sendMessage(
            fullPrompt,
            personality: nil,
            featureType: .story,
            conversationHistory: []
        )

        // Track story generation in cache analytics
        await CacheAnalyticsService.shared.recordCacheMiss(category: .story)

        return response.content
    }
}

// MARK: - Story Response Model
struct StoryResponse: Codable {
    let story: String
    let choices: [String]
}

struct ResumeResponse: Codable {
    let choices: [String]
}
