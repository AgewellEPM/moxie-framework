import SwiftUI
import AVFoundation
import Speech

struct LearningView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = LearningViewModel()
    @State private var userInput = ""
    @State private var showSettings = false
    @State private var showWizard = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.08, blue: 0.05),
                    Color(red: 0.08, green: 0.12, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("🎓 Learning Lab")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

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
                    LearningSettingsPanel(viewModel: viewModel)
                }

                // Learning Content
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            // Welcome banner when no curriculum - SIMILAR TO STORY TIME
                            if viewModel.curriculum == nil && viewModel.learningSegments.isEmpty && !viewModel.isLoading {
                                VStack(spacing: 32) {
                                    Spacer()

                                    Image(systemName: "graduationcap.fill")
                                        .font(.system(size: 80))
                                        .foregroundColor(.green.opacity(0.7))

                                    VStack(spacing: 12) {
                                        Text("Start Learning")
                                            .font(.system(size: 32, weight: .bold))
                                            .foregroundColor(.white)

                                        Text("Tell me what you want to learn about")
                                            .font(.system(size: 18))
                                            .foregroundColor(.white.opacity(0.8))
                                    }

                                    Button(action: { showWizard = true }) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "wand.and.stars")
                                            Text("Use Learning Wizard")
                                        }
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 32)
                                        .padding(.vertical, 16)
                                        .background(
                                            LinearGradient(
                                                colors: [Color.green, Color.blue],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                            in: RoundedRectangle(cornerRadius: 14)
                                        )
                                        .shadow(color: Color.green.opacity(0.3), radius: 10, y: 5)
                                    }
                                    .buttonStyle(.plain)

                                    Spacer()
                                }
                                .frame(maxWidth: .infinity)
                            }

                            // Show curriculum if generated
                            if let curriculum = viewModel.curriculum {
                                CurriculumView(curriculum: curriculum)
                                    .id("curriculum")
                            }

                            // Learning segments (like chat messages)
                            ForEach(viewModel.learningSegments) { segment in
                                LearningSegmentView(segment: segment)
                                    .id(segment.id)
                            }

                            // Loading indicator
                            if viewModel.isLoading {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Moxie is preparing your lesson...")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding()
                            }

                            // Quiz questions if available
                            if let quiz = viewModel.currentQuiz, !viewModel.isLoading {
                                QuizView(
                                    quiz: quiz,
                                    onAnswer: { answer in
                                        Task {
                                            await viewModel.submitAnswer(answer)
                                        }
                                    }
                                )
                                .id("quiz")
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.learningSegments.count) { _ in
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
                                .foregroundColor(viewModel.isListening ? .red : .green)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.1), in: Circle())
                        }
                        .buttonStyle(.plain)

                        // Text input
                        ZStack(alignment: .topLeading) {
                            if userInput.isEmpty && !viewModel.isListening {
                                Text(viewModel.curriculum == nil ? "What do you want to learn today?" : "Ask a question or type 'next' for the next lesson...")
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 14)
                            }

                            TextEditor(text: $userInput)
                                .font(.body)
                                .foregroundColor(.white)
                                .frame(minHeight: 44, maxHeight: 100)
                                .focused($isInputFocused)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                        }
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                        // Send button
                        Button(action: {
                            sendMessage()
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(canSend ? .green : .gray)
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
                    if viewModel.curriculum != nil {
                        Button(action: {
                            Task {
                                await viewModel.saveLearningSession()
                            }
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Save Session")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            viewModel.resetLearning()
                        }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("New Topic")
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
                                await viewModel.resumeLearning()
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

                    if let curriculum = viewModel.curriculum {
                        Text("Lesson \(viewModel.currentLessonIndex + 1)/\(curriculum.lessons.count)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding()
                .background(Color.black.opacity(0.2))
            }
        }
        .frame(minWidth: 900, minHeight: 700)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showWizard) {
            LearningWizardView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.initializeSpeechRecognition()
            Task {
                await viewModel.loadPreviousSessions()
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
            if viewModel.curriculum == nil {
                await viewModel.generateCurriculum(topic: text)
            } else {
                await viewModel.processUserInput(text)
            }
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        if viewModel.currentQuiz != nil {
            withAnimation {
                proxy.scrollTo("quiz", anchor: .bottom)
            }
        } else if let lastSegment = viewModel.learningSegments.last {
            withAnimation {
                proxy.scrollTo(lastSegment.id, anchor: .bottom)
            }
        }
    }
}

// MARK: - Learning Settings Panel
struct LearningSettingsPanel: View {
    @ObservedObject var viewModel: LearningViewModel
    @State private var specificTopic: String = ""

    var body: some View {
        VStack(spacing: 12) {
            Text("🎓 Customize Your Learning")
                .font(.headline)
                .foregroundColor(.white)

            // Specific Topic Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Specific Topic:")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))

                HStack {
                    TextField("e.g., 'Quadratic Equations', 'Python Lists', 'Photosynthesis'", text: $specificTopic)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

                    if !specificTopic.isEmpty {
                        Button(action: {
                            Task {
                                await viewModel.generateCurriculum(topic: specificTopic)
                                specificTopic = ""
                            }
                        }) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.green)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("Type exactly what you want to learn and press the arrow to build your lesson plan")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.bottom, 8)

            Divider()
                .background(Color.white.opacity(0.3))

            // Subject
            HStack {
                Text("Subject:")
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 120, alignment: .leading)
                Picker("", selection: $viewModel.subject) {
                    ForEach(Subject.allCases, id: \.self) { subject in
                        Text(subject.rawValue).tag(subject)
                    }
                }
                .pickerStyle(.menu)
            }

            // Grade Level
            HStack {
                Text("Grade Level:")
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 120, alignment: .leading)
                Picker("", selection: $viewModel.gradeLevel) {
                    ForEach(GradeLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(.menu)
            }

            // Difficulty Level
            HStack {
                Text("Difficulty:")
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 120, alignment: .leading)
                Picker("", selection: $viewModel.difficulty) {
                    ForEach(DifficultyLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(.menu)
            }

            // Learning Style
            HStack {
                Text("Learning Style:")
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 120, alignment: .leading)
                Picker("", selection: $viewModel.learningStyle) {
                    ForEach(LearningStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(.menu)
            }

            // Lesson Length
            HStack {
                Text("Lesson Length:")
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 120, alignment: .leading)
                Picker("", selection: $viewModel.lessonLength) {
                    ForEach(LessonLength.allCases, id: \.self) { length in
                        Text(length.rawValue).tag(length)
                    }
                }
                .pickerStyle(.menu)
            }

            Divider()
                .background(Color.white.opacity(0.3))

            // Quick start buttons for popular topics
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Start:")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))

                HStack(spacing: 8) {
                    QuickTopicButton(emoji: "🤖", title: "AI & ML", subject: .coding, gradeLevel: .college, difficulty: .advanced, viewModel: viewModel)
                    QuickTopicButton(emoji: "💻", title: "Python", subject: .coding, gradeLevel: .highSchool, difficulty: .beginner, viewModel: viewModel)
                }

                HStack(spacing: 8) {
                    QuickTopicButton(emoji: "📊", title: "Data Science", subject: .math, gradeLevel: .college, difficulty: .intermediate, viewModel: viewModel)
                    QuickTopicButton(emoji: "🧮", title: "Calculus", subject: .math, gradeLevel: .highSchool, difficulty: .advanced, viewModel: viewModel)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

// MARK: - Quick Topic Button
struct QuickTopicButton: View {
    let emoji: String
    let title: String
    let subject: Subject
    let gradeLevel: GradeLevel
    let difficulty: DifficultyLevel
    @ObservedObject var viewModel: LearningViewModel

    var body: some View {
        Button(action: {
            viewModel.subject = subject
            viewModel.gradeLevel = gradeLevel
            viewModel.difficulty = difficulty
        }) {
            HStack(spacing: 4) {
                Text(emoji)
                    .font(.caption)
                Text(title)
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.green.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Curriculum View
struct CurriculumView: View {
    let curriculum: Curriculum

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📚")
                    .font(.title)
                Text(curriculum.topic)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            Text(curriculum.description)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .padding(.bottom, 8)

            Text("Curriculum Outline:")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(Array(curriculum.lessons.enumerated()), id: \.offset) { index, lesson in
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.3))
                            .frame(width: 32, height: 32)
                        Text("\(index + 1)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(lesson.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Text(lesson.objective)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.green.opacity(0.2), Color.blue.opacity(0.2)],
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

// MARK: - Learning Segment View
struct LearningSegmentView: View {
    let segment: LearningSegment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let question = segment.userQuestion {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.green)
                    Text("You: \(question)")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .italic()
                }
            }

            HStack(alignment: .top, spacing: 8) {
                Text("🎓")
                    .font(.title2)
                VStack(alignment: .leading, spacing: 8) {
                    if let title = segment.lessonTitle {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    Text(segment.content)
                        .font(.body)
                        .foregroundColor(.white)

                    // Show examples if available
                    if !segment.examples.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Examples:")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            ForEach(segment.examples, id: \.self) { example in
                                Text("• \(example)")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [Color.green.opacity(0.2), Color.blue.opacity(0.2)],
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

// MARK: - Quiz View
struct QuizView: View {
    let quiz: Quiz
    let onAnswer: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("❓")
                    .font(.title2)
                Text("Check Your Understanding")
                    .font(.headline)
                    .foregroundColor(.white)
            }

            Text(quiz.question)
                .font(.body)
                .foregroundColor(.white)
                .padding(.vertical, 8)

            ForEach(Array(quiz.options.enumerated()), id: \.offset) { index, option in
                Button(action: {
                    onAnswer(option)
                }) {
                    HStack {
                        Text("\(index + 1).")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Text(option)
                            .font(.body)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                    .background(Color.green.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Models
struct LearningSegment: Identifiable {
    let id = UUID()
    let lessonTitle: String?
    let content: String
    let examples: [String]
    let userQuestion: String?
}

struct Curriculum: Codable {
    let topic: String
    let description: String
    let lessons: [Lesson]
}

struct Lesson: Codable {
    let title: String
    let objective: String
}

struct Quiz: Identifiable {
    let id = UUID()
    let question: String
    let options: [String]
    let correctAnswer: String
}

enum DifficultyLevel: String, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
}

enum LearningStyle: String, CaseIterable {
    case visual = "Visual (with examples)"
    case handson = "Hands-on (interactive)"
    case reading = "Reading & Writing"
    case conversational = "Conversational"
}

enum LessonLength: String, CaseIterable {
    case short = "Short (5 min)"
    case medium = "Medium (10 min)"
    case long = "Long (15 min)"
}

enum Subject: String, CaseIterable {
    case math = "Math"
    case science = "Science"
    case english = "English & Reading"
    case history = "History & Social Studies"
    case coding = "Coding & Computer Science"
    case art = "Art & Music"
    case language = "Foreign Languages"
    case general = "General Knowledge"
}

enum GradeLevel: String, CaseIterable {
    case preschool = "Preschool (Ages 3-5)"
    case kindergarten = "Kindergarten (Ages 5-6)"
    case elementary = "Elementary (Grades 1-5)"
    case middleSchool = "Middle School (Grades 6-8)"
    case highSchool = "High School (Grades 9-12)"
    case college = "College/Adult"
}

// MARK: - Learning ViewModel
@MainActor
class LearningViewModel: ObservableObject {
    @Published var learningSegments: [LearningSegment] = []
    @Published var curriculum: Curriculum?
    @Published var currentQuiz: Quiz?
    @Published var isLoading = false
    @Published var isListening = false
    @Published var errorMessage: String?
    @Published var currentLessonIndex = 0

    @Published var subject: Subject = .general
    @Published var gradeLevel: GradeLevel = .elementary
    @Published var difficulty: DifficultyLevel = .beginner
    @Published var learningStyle: LearningStyle = .conversational
    @Published var lessonLength: LessonLength = .medium

    private let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    private let learningDir = AppPaths.learning
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var learningContext: [String] = []
    private let tileRepository: TileRepository = TileRepository()

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

    func generateCurriculum(topic: String, fromWizard: Bool = false) async {
        guard !topic.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            let stylePrompt = getLearningStylePrompt()
            let gradeLevelPrompt = getGradeLevelPrompt()

            // Add emotion tag if coming from wizard
            let emotionTag = fromWizard ? "[emotion:excited] " : ""

            let prompt = """
            You are an expert educator. Create a comprehensive curriculum for teaching: \(topic)

            Subject Area: \(subject.rawValue)
            Grade Level: \(gradeLevel.rawValue)
            Difficulty Level: \(difficulty.rawValue)
            Learning Style: \(learningStyle.rawValue)
            Lesson Length: \(lessonLength.rawValue)

            \(stylePrompt)
            \(gradeLevelPrompt)

            Create a curriculum with 5-7 progressive lessons. Each lesson should build on the previous one.
            Make this appropriate for \(gradeLevel.rawValue) students learning \(subject.rawValue).

            Format your response as JSON:
            {
                "topic": "The topic name",
                "description": "A brief description of what the student will learn",
                "lessons": [
                    {
                        "title": "Lesson title",
                        "objective": "What the student will learn in this lesson"
                    }
                ]
            }
            """

            let response = try await callOpenAI(prompt: prompt)

            if let data = response.data(using: .utf8),
               let curriculum = try? JSONDecoder().decode(Curriculum.self, from: data) {
                self.curriculum = curriculum
                currentLessonIndex = 0

                // Add an introductory message if from wizard
                if fromWizard {
                    learningSegments.append(LearningSegment(
                        lessonTitle: nil,
                        content: "\(emotionTag)Great choices! I've created a personalized curriculum for \(topic). Let's start your learning adventure!",
                        examples: [],
                        userQuestion: nil
                    ))
                }

                // Automatically start the first lesson
                await teachLesson(index: 0)
            }
        } catch {
            errorMessage = "Failed to generate curriculum: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func teachLesson(index: Int) async {
        guard let curriculum = curriculum, index < curriculum.lessons.count else { return }

        isLoading = true
        errorMessage = nil
        currentLessonIndex = index

        do {
            let lesson = curriculum.lessons[index]
            let stylePrompt = getLearningStylePrompt()

            let prompt = """
            You are teaching a lesson about: \(curriculum.topic)
            Current lesson: \(lesson.title)
            Objective: \(lesson.objective)

            Difficulty Level: \(difficulty.rawValue)
            Learning Style: \(learningStyle.rawValue)

            \(stylePrompt)

            Teach this lesson in a clear, engaging way. Make it longer and more detailed than a story.
            Include 2-3 concrete examples to help understanding.

            Format your response as JSON:
            {
                "content": "The lesson content (3-5 paragraphs)",
                "examples": ["Example 1", "Example 2", "Example 3"]
            }
            """

            let response = try await callOpenAI(prompt: prompt)

            if let data = response.data(using: .utf8),
               let json = try? JSONDecoder().decode(LessonContent.self, from: data) {

                learningSegments.append(LearningSegment(
                    lessonTitle: lesson.title,
                    content: json.content,
                    examples: json.examples,
                    userQuestion: nil
                ))

                learningContext.append(json.content)

                // Generate a quiz question
                await generateQuiz(lesson: lesson, content: json.content)
            }
        } catch {
            errorMessage = "Failed to teach lesson: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func generateQuiz(lesson: Lesson, content: String) async {
        do {
            let prompt = """
            Based on this lesson content:
            \(content)

            Create a quiz question to check understanding. Make it appropriate for \(difficulty.rawValue) level.

            Format your response as JSON:
            {
                "question": "The question",
                "options": ["Option 1", "Option 2", "Option 3", "Option 4"],
                "correct_answer": "The correct option"
            }
            """

            let response = try await callOpenAI(prompt: prompt)

            if let data = response.data(using: .utf8),
               let json = try? JSONDecoder().decode(QuizResponse.self, from: data) {

                currentQuiz = Quiz(
                    question: json.question,
                    options: json.options,
                    correctAnswer: json.correct_answer
                )
            }
        } catch {
            // Quiz is optional, don't show error
        }
    }

    func submitAnswer(_ answer: String) async {
        guard let quiz = currentQuiz else { return }

        let isCorrect = answer == quiz.correctAnswer

        learningSegments.append(LearningSegment(
            lessonTitle: nil,
            content: isCorrect ? "✅ Correct! \(answer)" : "❌ Not quite. The correct answer is: \(quiz.correctAnswer)",
            examples: [],
            userQuestion: nil
        ))

        currentQuiz = nil

        // Move to next lesson if available
        if let curriculum = curriculum, currentLessonIndex < curriculum.lessons.count - 1 {
            await teachLesson(index: currentLessonIndex + 1)
        } else {
            learningSegments.append(LearningSegment(
                lessonTitle: nil,
                content: "🎉 Congratulations! You've completed the curriculum for \(curriculum?.topic ?? "this topic")!",
                examples: [],
                userQuestion: nil
            ))
        }
    }

    func processUserInput(_ input: String) async {
        if input.lowercased() == "next" {
            if let curriculum = curriculum, currentLessonIndex < curriculum.lessons.count - 1 {
                await teachLesson(index: currentLessonIndex + 1)
            }
        } else {
            // Answer user's question
            isLoading = true

            do {
                let contextText = learningContext.joined(separator: "\n\n")
                let prompt = """
                You are teaching about: \(curriculum?.topic ?? "this topic")

                Previous lessons:
                \(contextText)

                Student question: \(input)

                Answer the question clearly and helpfully, relating it to what they've already learned.

                Format your response as JSON:
                {
                    "content": "Your answer",
                    "examples": ["Example if needed"]
                }
                """

                let response = try await callOpenAI(prompt: prompt)

                if let data = response.data(using: .utf8),
                   let json = try? JSONDecoder().decode(LessonContent.self, from: data) {

                    learningSegments.append(LearningSegment(
                        lessonTitle: nil,
                        content: json.content,
                        examples: json.examples,
                        userQuestion: input
                    ))
                }
            } catch {
                errorMessage = "Failed to answer question: \(error.localizedDescription)"
            }

            isLoading = false
        }
    }

    func saveLearningSession() async {
        guard let curriculum = curriculum else { return }

        // Create directory if needed
        try? FileManager.default.createDirectory(at: learningDir, withIntermediateDirectories: true)

        let timestamp = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let dateString = formatter.string(from: timestamp)

        let filename = "learning_\(curriculum.topic.replacingOccurrences(of: " ", with: "_"))_\(dateString).json"
        let fileURL = learningDir.appendingPathComponent(filename)

        let sessionData: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: timestamp),
            "topic": curriculum.topic,
            "difficulty": difficulty.rawValue,
            "learning_style": learningStyle.rawValue,
            "lesson_length": lessonLength.rawValue,
            "curriculum": [
                "topic": curriculum.topic,
                "description": curriculum.description,
                "lessons": curriculum.lessons.map { ["title": $0.title, "objective": $0.objective] }
            ],
            "segments": learningSegments.map { [
                "lesson_title": $0.lessonTitle ?? "",
                "content": $0.content,
                "examples": $0.examples,
                "user_question": $0.userQuestion ?? ""
            ]},
            "current_lesson": currentLessonIndex
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: sessionData, options: .prettyPrinted)
            try jsonData.write(to: fileURL)
            print("Learning session saved to: \(fileURL.path)")

            // Create and save a LearningTile
            let bookTitle = curriculum.description.isEmpty ? (curriculum.lessons.first?.title ?? "Learning Session") : curriculum.description
            let learningTile = LearningTile(
                title: curriculum.topic,
                bookTitle: bookTitle,
                subject: subject.rawValue,
                gradeLevel: gradeLevel.rawValue,
                difficulty: difficulty.rawValue,
                sessionFilePath: fileURL.path,
                emoji: "🎓"
            )
            tileRepository.saveLearningTile(learningTile)
            print("Learning tile saved for: \(curriculum.topic)")
        } catch {
            errorMessage = "Failed to save session: \(error.localizedDescription)"
        }
    }

    func loadPreviousSessions() async {
        // Implementation to load and resume previous sessions
    }

    func resumeLearning() async {
        // Continue from where we left off
        if let curriculum = curriculum, currentLessonIndex < curriculum.lessons.count - 1 {
            await teachLesson(index: currentLessonIndex + 1)
        }
    }

    func resetLearning() {
        learningSegments = []
        curriculum = nil
        currentQuiz = nil
        currentLessonIndex = 0
        learningContext = []
        errorMessage = nil
    }

    private func getLearningStylePrompt() -> String {
        switch learningStyle {
        case .visual:
            return "Use vivid descriptions and provide concrete visual examples."
        case .handson:
            return "Include interactive activities and practical exercises."
        case .reading:
            return "Use clear, structured text with key points highlighted."
        case .conversational:
            return "Use a friendly, conversational tone like talking to a friend."
        }
    }

    private func getGradeLevelPrompt() -> String {
        switch gradeLevel {
        case .preschool:
            return "Use very simple language and focus on basic concepts. Make it playful and engaging for young children."
        case .kindergarten:
            return "Use simple vocabulary and short sentences. Include basic counting, colors, and shapes when relevant."
        case .elementary:
            return "Use age-appropriate vocabulary for grades 1-5. Break down complex concepts into simple steps."
        case .middleSchool:
            return "Use pre-teen appropriate language. Introduce more abstract thinking and problem-solving."
        case .highSchool:
            return "Use mature vocabulary and introduce advanced concepts. Prepare for college-level thinking."
        case .college:
            return "Use sophisticated academic language. Include theoretical frameworks, research, and professional applications."
        }
    }

    private func callOpenAI(prompt: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw NSError(domain: "Learning", code: 1, userInfo: [NSLocalizedDescriptionKey: "OpenAI API key not set in environment"])
        }

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": "You are an expert educator who creates engaging lessons. Always respond in valid JSON format."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 1500,
            "response_format": ["type": "json_object"]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "Learning", code: 2, userInfo: [NSLocalizedDescriptionKey: "API request failed"])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw NSError(domain: "Learning", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }

        return content
    }
}

// MARK: - Response Models
struct LessonContent: Codable {
    let content: String
    let examples: [String]
}

struct QuizResponse: Codable {
    let question: String
    let options: [String]
    let correct_answer: String
}
