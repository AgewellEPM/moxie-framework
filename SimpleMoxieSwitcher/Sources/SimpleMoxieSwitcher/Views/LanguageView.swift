import SwiftUI
import AVFoundation
import Speech

struct LanguageView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = LanguageViewModel()
    @State private var userInput = ""
    @State private var showSettings = false
    @State private var showLibrary = false
    @State private var showWizard = false
    @State private var showSessions = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            // Beautiful gradient background with language theme
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.05, blue: 0.25),
                    Color(red: 0.25, green: 0.15, blue: 0.35),
                    Color(red: 0.20, green: 0.10, blue: 0.30)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("🌍 Language Lab")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    // Language indicator
                    HStack(spacing: 8) {
                        Text(viewModel.moxieLanguage.flag)
                            .font(.title2)
                        Text("→")
                            .foregroundColor(.white.opacity(0.6))
                        Text(viewModel.userLanguage.flag)
                            .font(.title2)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .padding(.trailing, 12)

                    // Wizard button
                    Button(action: { showWizard.toggle() }) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 12)

                    // My Sessions button
                    Button(action: { showSessions.toggle() }) {
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 12)

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
                    LanguageSettingsPanel(viewModel: viewModel)
                }

                // Conversation Area
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            // Welcome message if no conversation
                            if viewModel.messages.isEmpty {
                                WelcomeCard(viewModel: viewModel)
                                    .id("welcome")
                            }

                            // Messages
                            ForEach(viewModel.messages) { message in
                                LanguageMessageBubble(message: message)
                                    .id(message.id)
                            }

                            // Loading indicator
                            if viewModel.isLoading {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Moxie is translating...")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        scrollToBottom(proxy)
                    }
                }

                // Success message
                if let success = viewModel.successMessage {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(success)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                    }
                    .padding()
                    .background(Color.green.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal)
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

                // Input area
                VStack(spacing: 8) {
                    HStack(alignment: .bottom, spacing: 12) {
                        // Microphone button
                        Button(action: {
                            viewModel.toggleListening()
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: viewModel.isListening ? "mic.fill" : "mic")
                                    .font(.system(size: 24))
                                    .foregroundColor(viewModel.isListening ? .red : .purple)
                                if viewModel.isListening {
                                    Text(viewModel.userLanguage.code.uppercased())
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.1), in: Circle())
                        }
                        .buttonStyle(.plain)

                        // Text input
                        ZStack(alignment: .topLeading) {
                            if userInput.isEmpty && !viewModel.isListening {
                                Text("Type in \(viewModel.userLanguage.name)...")
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
                                .foregroundColor(canSend ? .purple : .gray)
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
                            Text("Listening in \(viewModel.userLanguage.name)...")
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
                    if !viewModel.messages.isEmpty {
                        Button(action: {
                            Task {
                                await viewModel.saveConversation()
                            }
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Save")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            viewModel.clearConversation()
                        }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Clear")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            viewModel.swapLanguages()
                        }) {
                            HStack {
                                Image(systemName: "arrow.left.arrow.right")
                                Text("Swap")
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

                    Text("\(viewModel.messages.count) messages")
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
            LanguageLearningWizardView()
        }
        .sheet(isPresented: $showSessions) {
            LanguageSessionsView()
        }
        .sheet(isPresented: $showLibrary) {
            LanguagePairsLibraryView(languageViewModel: viewModel)
        }
        .onAppear {
            viewModel.initializeSpeechRecognition()
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
            await viewModel.sendMessage(text)
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        if let lastMessage = viewModel.messages.last {
            withAnimation {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

// MARK: - Welcome Card
struct WelcomeCard: View {
    @ObservedObject var viewModel: LanguageViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("🌍")
                .font(.system(size: 60))

            Text("Welcome to Language Lab!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("Moxie speaks: \(viewModel.moxieLanguage.name) \(viewModel.moxieLanguage.flag)")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))

            Text("You speak: \(viewModel.userLanguage.name) \(viewModel.userLanguage.flag)")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))

            Divider()
                .background(Color.white.opacity(0.3))
                .padding(.horizontal, 40)

            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "globe", text: "Moxie responds in \(viewModel.moxieLanguage.name)")
                FeatureRow(icon: "person.fill", text: "You can reply in ANY language")
                FeatureRow(icon: "arrow.left.arrow.right", text: "Swap languages anytime")
                FeatureRow(icon: "mic.fill", text: "Use voice or text input")
            }
            .padding()

            Text("Start by saying hello in \(viewModel.userLanguage.name)!")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .italic()
        }
        .padding(30)
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.purple.opacity(0.8))
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

// MARK: - Language Settings Panel
struct LanguageSettingsPanel: View {
    @ObservedObject var viewModel: LanguageViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Language Settings")
                .font(.headline)
                .foregroundColor(.white)

            HStack(spacing: 30) {
                // Moxie's Language
                VStack(alignment: .leading, spacing: 8) {
                    Text("Moxie speaks:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))

                    Menu {
                        ForEach(Language.allLanguages, id: \.code) { language in
                            Button(action: {
                                viewModel.moxieLanguage = language
                            }) {
                                HStack {
                                    Text(language.flag)
                                    Text(language.name)
                                    if language.code == viewModel.moxieLanguage.code {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.moxieLanguage.flag)
                                .font(.title2)
                            Text(viewModel.moxieLanguage.name)
                                .foregroundColor(.white)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.purple.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
                    }
                }

                Image(systemName: "arrow.left.arrow.right")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.5))

                // User's Language
                VStack(alignment: .leading, spacing: 8) {
                    Text("You speak:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))

                    Menu {
                        ForEach(Language.allLanguages, id: \.code) { language in
                            Button(action: {
                                viewModel.userLanguage = language
                            }) {
                                HStack {
                                    Text(language.flag)
                                    Text(language.name)
                                    if language.code == viewModel.userLanguage.code {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.userLanguage.flag)
                                .font(.title2)
                            Text(viewModel.userLanguage.name)
                                .foregroundColor(.white)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }

            // Mode selector
            HStack {
                Text("Mode:")
                    .foregroundColor(.white.opacity(0.8))
                Picker("", selection: $viewModel.conversationMode) {
                    ForEach(ConversationMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Save Language Pair button
            Button(action: {
                Task {
                    await viewModel.saveLanguagePair()
                }
            }) {
                HStack {
                    Image(systemName: "bookmark.fill")
                    Text("Save Language Pair")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.green.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

// MARK: - Language Message Bubble
struct LanguageMessageBubble: View {
    let message: LanguageMessage

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if message.sender == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.sender == .moxie ? .leading : .trailing, spacing: 8) {
                // Header with language
                HStack(spacing: 6) {
                    if message.sender == .moxie {
                        Text("🤖")
                            .font(.caption)
                        Text("Moxie")
                            .font(.caption)
                            .fontWeight(.semibold)
                    } else {
                        Text("You")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("👤")
                            .font(.caption)
                    }
                    Text(message.language.flag)
                        .font(.caption)
                    Text(message.language.code.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                }
                .foregroundColor(.white.opacity(0.8))

                // Message text
                Text(message.text)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        message.sender == .moxie ?
                        LinearGradient(
                            colors: [Color.purple.opacity(0.4), Color.purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ).opacity(1) :
                        LinearGradient(
                            colors: [Color.blue.opacity(0.4), Color.blue.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ).opacity(1),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )

                // Translation if available
                if let translation = message.translation {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10))
                        Text(translation)
                            .font(.caption)
                            .italic()
                    }
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 16)
                }
            }

            if message.sender == .moxie {
                Spacer(minLength: 60)
            }
        }
    }
}

// MARK: - Models
struct LanguageMessage: Identifiable {
    let id = UUID()
    let sender: MessageSender
    let text: String
    let language: Language
    let translation: String?
    let timestamp: Date
}

enum MessageSender {
    case moxie
    case user
}

struct Language: Codable {
    let code: String
    let name: String
    let flag: String
    let nativeName: String?

    init(code: String, name: String, flag: String, nativeName: String? = nil) {
        self.code = code
        self.name = name
        self.flag = flag
        self.nativeName = nativeName
    }

    static let allLanguages: [Language] = [
        Language(code: "en", name: "English", flag: "🇺🇸"),
        Language(code: "es", name: "Spanish", flag: "🇪🇸", nativeName: "Español"),
        Language(code: "fr", name: "French", flag: "🇫🇷", nativeName: "Français"),
        Language(code: "de", name: "German", flag: "🇩🇪", nativeName: "Deutsch"),
        Language(code: "it", name: "Italian", flag: "🇮🇹", nativeName: "Italiano"),
        Language(code: "pt", name: "Portuguese", flag: "🇧🇷", nativeName: "Português"),
        Language(code: "ru", name: "Russian", flag: "🇷🇺", nativeName: "Русский"),
        Language(code: "zh", name: "Chinese", flag: "🇨🇳", nativeName: "中文"),
        Language(code: "ja", name: "Japanese", flag: "🇯🇵", nativeName: "日本語"),
        Language(code: "ko", name: "Korean", flag: "🇰🇷", nativeName: "한국어"),
        Language(code: "ar", name: "Arabic", flag: "🇸🇦", nativeName: "العربية"),
        Language(code: "hi", name: "Hindi", flag: "🇮🇳", nativeName: "हिन्दी"),
        Language(code: "nl", name: "Dutch", flag: "🇳🇱", nativeName: "Nederlands"),
        Language(code: "sv", name: "Swedish", flag: "🇸🇪", nativeName: "Svenska"),
        Language(code: "pl", name: "Polish", flag: "🇵🇱", nativeName: "Polski"),
        Language(code: "tr", name: "Turkish", flag: "🇹🇷", nativeName: "Türkçe"),
        Language(code: "vi", name: "Vietnamese", flag: "🇻🇳", nativeName: "Tiếng Việt"),
        Language(code: "th", name: "Thai", flag: "🇹🇭", nativeName: "ไทย"),
        Language(code: "id", name: "Indonesian", flag: "🇮🇩", nativeName: "Bahasa Indonesia"),
        Language(code: "he", name: "Hebrew", flag: "🇮🇱", nativeName: "עברית")
    ]
}

enum ConversationMode: String, CaseIterable {
    case casual = "Casual Chat"
    case learning = "Language Learning"
    case translation = "Translation Help"
}

// MARK: - Language ViewModel
@MainActor
class LanguageViewModel: ObservableObject {
    @Published var messages: [LanguageMessage] = []
    @Published var isLoading = false
    @Published var isListening = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    @Published var moxieLanguage: Language = Language.allLanguages[0] {
        didSet {
            // Update global language preference for all personalities
            LanguagePreferenceManager.shared.setLanguage(code: moxieLanguage.code, name: moxieLanguage.name)
        }
    }
    @Published var userLanguage: Language = Language.allLanguages[1] // Spanish
    @Published var conversationMode: ConversationMode = .casual

    private let conversationsDir = AppPaths.languages
    private let dockerService: DockerServiceProtocol = DIContainer.shared.resolve(DockerServiceProtocol.self)
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    func initializeSpeechRecognition() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: userLanguage.code))

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
        // Update recognizer for current user language
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: userLanguage.code))
        isListening = true
    }

    private func stopListening() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        isListening = false
    }

    func sendMessage(_ text: String) async {
        guard !text.isEmpty else { return }

        // Add user message
        let userMessage = LanguageMessage(
            sender: .user,
            text: text,
            language: userLanguage,
            translation: nil,
            timestamp: Date()
        )
        messages.append(userMessage)

        isLoading = true
        errorMessage = nil

        do {
            let modePrompt = getModePrompt()
            let prompt = """
            You are Moxie, a friendly multilingual robot assistant.

            Conversation mode: \(conversationMode.rawValue)
            \(modePrompt)

            The user just said in \(userLanguage.name): "\(text)"

            You must respond ONLY in \(moxieLanguage.name).

            Important:
            - Write your entire response in \(moxieLanguage.name)
            - Be friendly and encouraging
            - Keep responses conversational and natural
            - If helping with language learning, be supportive

            Format your response as JSON:
            {
                "response": "Your response in \(moxieLanguage.name)",
                "translation": "Optional English translation for learning purposes"
            }
            """

            let response = try await callLLM(prompt: prompt)

            if let data = response.data(using: .utf8),
               let json = try? JSONDecoder().decode(MoxieResponse.self, from: data) {

                let moxieMessage = LanguageMessage(
                    sender: .moxie,
                    text: json.response,
                    language: moxieLanguage,
                    translation: conversationMode == .learning ? json.translation : nil,
                    timestamp: Date()
                )
                messages.append(moxieMessage)
            }
        } catch {
            errorMessage = "Failed to get response: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func saveConversation() async {
        // Create directory if needed
        try? FileManager.default.createDirectory(at: conversationsDir, withIntermediateDirectories: true)

        let timestamp = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let dateString = formatter.string(from: timestamp)

        let filename = "conversation_\(moxieLanguage.code)_\(userLanguage.code)_\(dateString).json"
        let fileURL = conversationsDir.appendingPathComponent(filename)

        let conversationData: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: timestamp),
            "moxie_language": ["code": moxieLanguage.code, "name": moxieLanguage.name],
            "user_language": ["code": userLanguage.code, "name": userLanguage.name],
            "mode": conversationMode.rawValue,
            "messages": messages.map { [
                "sender": $0.sender == .moxie ? "moxie" : "user",
                "text": $0.text,
                "language_code": $0.language.code,
                "language_name": $0.language.name,
                "translation": $0.translation ?? "",
                "timestamp": ISO8601DateFormatter().string(from: $0.timestamp)
            ]}
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: conversationData, options: .prettyPrinted)
            try jsonData.write(to: fileURL)
            print("Conversation saved to: \(fileURL.path)")
        } catch {
            errorMessage = "Failed to save conversation: \(error.localizedDescription)"
        }
    }

    func clearConversation() {
        messages = []
        errorMessage = nil
    }

    func swapLanguages() {
        let temp = moxieLanguage
        moxieLanguage = userLanguage
        userLanguage = temp

        // Update speech recognizer
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: userLanguage.code))
    }

    func saveLanguagePair() async {
        // Create directory if needed
        try? FileManager.default.createDirectory(at: conversationsDir, withIntermediateDirectories: true)

        let timestamp = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let dateString = formatter.string(from: timestamp)

        let filename = "language_pair_\(moxieLanguage.code)_\(userLanguage.code)_\(dateString).json"
        let fileURL = conversationsDir.appendingPathComponent(filename)

        let languagePairData: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: timestamp),
            "moxie_language": ["code": moxieLanguage.code, "name": moxieLanguage.name],
            "user_language": ["code": userLanguage.code, "name": userLanguage.name],
            "mode": conversationMode.rawValue,
            "messages": [] // Empty messages array for language pairs
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: languagePairData, options: .prettyPrinted)
            try jsonData.write(to: fileURL)
            print("Language pair saved to: \(fileURL.path)")

            // Show success message
            successMessage = "Language pair saved!"
            // Auto-dismiss after 2 seconds
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                successMessage = nil
            }
        } catch {
            errorMessage = "Failed to save language pair: \(error.localizedDescription)"
        }
    }

    private func getModePrompt() -> String {
        switch conversationMode {
        case .casual:
            return "Have a natural, friendly conversation. Be engaging and fun."
        case .learning:
            return "Help the user learn \(moxieLanguage.name). Use simple phrases, repeat key words, and be encouraging. Provide translations when helpful."
        case .translation:
            return "Help translate between languages. Be clear and educational about grammar and usage."
        }
    }

    private func callLLM(prompt: String) async throws -> String {
        // Use local OpenMoxie server's LLM through Docker
        // Escape the prompt for Python
        let escapedPrompt = prompt
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")

        let pythonScript = """
        import json
        from hive.utils.llm_client import get_llm_client

        client = get_llm_client()

        system_msg = "You are Moxie, a friendly multilingual robot. Always respond in valid JSON format with keys: response (your response text) and translation (optional English translation)."
        user_msg = '''\(escapedPrompt)'''

        result = client.chat_completion(
            messages=[
                {"role": "system", "content": system_msg},
                {"role": "user", "content": user_msg}
            ],
            temperature=0.8,
            max_tokens=500
        )

        # Extract the response content
        if hasattr(result, 'choices') and result.choices:
            content = result.choices[0].message.content
        elif isinstance(result, dict) and 'choices' in result:
            content = result['choices'][0]['message']['content']
        else:
            content = str(result)

        # Try to parse as JSON, if not wrap it
        try:
            parsed = json.loads(content)
            print(json.dumps(parsed))
        except:
            print(json.dumps({"response": content, "translation": None}))
        """

        let result = try await dockerService.executePythonScript(pythonScript)

        // Clean the result - remove any Django shell output before the JSON
        let lines = result.components(separatedBy: "\n")
        for line in lines.reversed() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("{") && trimmed.hasSuffix("}") {
                return trimmed
            }
        }

        // If no JSON found, return a default response
        return "{\"response\": \"I'm having trouble responding right now. Please try again.\", \"translation\": null}"
    }
}

// MARK: - Response Model
struct MoxieResponse: Codable {
    let response: String
    let translation: String?
}

// MARK: - Language Pair Model
struct LanguagePair: Identifiable {
    let id = UUID()
    let moxieLanguage: Language
    let userLanguage: Language
    let mode: ConversationMode
    let messageCount: Int
    let timestamp: Date
    let filePath: String
}

// MARK: - Language Pairs Library View
struct LanguagePairsLibraryView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var languageViewModel: LanguageViewModel
    @StateObject private var viewModel = LanguagePairsLibraryViewModel()

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.05, blue: 0.25),
                    Color(red: 0.25, green: 0.15, blue: 0.35)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("🌍 Language Pairs")
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
                if viewModel.pairs.isEmpty && !viewModel.isLoading {
                    // Empty state
                    VStack(spacing: 24) {
                        Image(systemName: "globe.americas")
                            .font(.system(size: 80))
                            .foregroundColor(.white.opacity(0.3))
                            .padding(.top, 60)

                        Text("No Saved Language Pairs")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)

                        Text("Your saved language conversations will appear here")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.pairs) { pair in
                                LanguagePairCard(
                                    pair: pair,
                                    onLoad: {
                                        // Update language settings from the selected pair
                                        languageViewModel.moxieLanguage = pair.moxieLanguage
                                        languageViewModel.userLanguage = pair.userLanguage
                                        languageViewModel.conversationMode = pair.mode
                                        languageViewModel.clearConversation()
                                        dismiss()
                                    },
                                    onDelete: {
                                        viewModel.deletePair(pair)
                                    }
                                )
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
        .onAppear {
            Task {
                await viewModel.loadPairs()
            }
        }
    }
}

// MARK: - Language Pair Card
struct LanguagePairCard: View {
    let pair: LanguagePair
    let onLoad: () -> Void
    let onDelete: () -> Void
    @State private var showDeleteConfirmation = false
    @State private var isHovered = false

    var body: some View {
        Button(action: onLoad) {
            HStack(spacing: 16) {
                // Language Icons
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.purple.opacity(0.3))
                        .frame(width: 80, height: 60)
                    HStack(spacing: 6) {
                        Text(pair.moxieLanguage.flag)
                            .font(.system(size: 24))
                        Text("→")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.6))
                        Text(pair.userLanguage.flag)
                            .font(.system(size: 24))
                    }
                }

                // Info
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(pair.moxieLanguage.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                        Text(pair.userLanguage.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    HStack(spacing: 12) {
                        Label(pair.mode.rawValue, systemImage: "star")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))

                        Label("\(pair.messageCount) messages", systemImage: "bubble.left.and.bubble.right")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Text(formattedDate)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                // Delete button
                Button(action: { showDeleteConfirmation = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                        .frame(width: 40, height: 40)
                        .background(Color.red.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(
                isHovered ?
                    Color.white.opacity(0.15) :
                    Color.white.opacity(0.1),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isHovered ?
                            Color.purple.opacity(0.6) :
                            Color.purple.opacity(0.3),
                        lineWidth: isHovered ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .alert("Delete Language Pair?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive, action: onDelete)
        } message: {
            Text("Are you sure you want to delete this saved conversation? This cannot be undone.")
        }
    }

    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: pair.timestamp, relativeTo: Date())
    }
}

// MARK: - Language Pairs Library ViewModel
@MainActor
class LanguagePairsLibraryViewModel: ObservableObject {
    @Published var pairs: [LanguagePair] = []
    @Published var isLoading = false
    @Published var selectedPair: LanguagePair?
    @Published var showLoadView = false

    private let conversationsDir = AppPaths.languages

    func loadPairs() async {
        isLoading = true

        guard FileManager.default.fileExists(atPath: conversationsDir.path) else {
            isLoading = false
            return
        }

        do {
            let files = try FileManager.default.contentsOfDirectory(at: conversationsDir, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles)

            var loadedPairs: [LanguagePair] = []

            for file in files where file.pathExtension == "json" {
                if let data = try? Data(contentsOf: file),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let timestampStr = json["timestamp"] as? String,
                   let timestamp = ISO8601DateFormatter().date(from: timestampStr),
                   let moxieLangDict = json["moxie_language"] as? [String: String],
                   let userLangDict = json["user_language"] as? [String: String],
                   let moxieCode = moxieLangDict["code"],
                   let _ = moxieLangDict["name"],
                   let userCode = userLangDict["code"],
                   let _ = userLangDict["name"],
                   let modeStr = json["mode"] as? String,
                   let messages = json["messages"] as? [[String: Any]] {

                    // Find matching languages
                    if let moxieLang = Language.allLanguages.first(where: { $0.code == moxieCode }),
                       let userLang = Language.allLanguages.first(where: { $0.code == userCode }),
                       let mode = ConversationMode.allCases.first(where: { $0.rawValue == modeStr }) {

                        let pair = LanguagePair(
                            moxieLanguage: moxieLang,
                            userLanguage: userLang,
                            mode: mode,
                            messageCount: messages.count,
                            timestamp: timestamp,
                            filePath: file.path
                        )
                        loadedPairs.append(pair)
                    }
                }
            }

            // Sort by timestamp (newest first)
            pairs = loadedPairs.sorted { $0.timestamp > $1.timestamp }
        } catch {
            print("Error loading language pairs: \(error)")
        }

        isLoading = false
    }

    func deletePair(_ pair: LanguagePair) {
        let fileURL = URL(fileURLWithPath: pair.filePath)
        try? FileManager.default.removeItem(at: fileURL)

        Task {
            await loadPairs()
        }
    }
}
