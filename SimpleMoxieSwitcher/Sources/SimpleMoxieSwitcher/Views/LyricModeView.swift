import SwiftUI

/// Lyric Mode - Paste lyrics and Moxie performs them, then stays in character for AI chat
struct LyricModeView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = LyricModeViewModel()
    @State private var lyricsText = ""
    @State private var selectedPersonality: Personality = .freestyleRapper
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                Divider()
                    .background(Color.white.opacity(0.2))

                // Main content
                if viewModel.isPerforming {
                    performanceView
                } else if viewModel.isInCharacterMode {
                    characterChatView
                } else {
                    lyricsInputView
                }
            }
        }
        .frame(minWidth: 800, minHeight: 650)
    }

    // MARK: - Header View
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(viewModel.isInCharacterMode ? "AI Chat" : "Lyric Mode")")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(viewModel.isInCharacterMode ?
                     "Moxie is staying in character as \(selectedPersonality.name)" :
                     "Paste lyrics for Moxie to perform, then chat in character")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            // Status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                    .shadow(color: statusColor, radius: 5)

                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))

            if viewModel.isInCharacterMode {
                Button("New Performance") {
                    viewModel.resetToLyrics()
                }
                .buttonStyle(.bordered)
                .tint(.purple)
            }

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)
        }
        .padding()
    }

    private var statusColor: Color {
        if viewModel.isPerforming { return .green }
        if viewModel.isInCharacterMode { return .purple }
        return .orange
    }

    private var statusText: String {
        if viewModel.isPerforming { return "Performing..." }
        if viewModel.isInCharacterMode { return "In Character" }
        return "Ready"
    }

    // MARK: - Lyrics Input View
    private var lyricsInputView: some View {
        VStack(spacing: 20) {
            // Personality selector
            VStack(alignment: .leading, spacing: 12) {
                Text("Character Style")
                    .font(.headline)
                    .foregroundColor(.white)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(availablePersonalities, id: \.name) { personality in
                            PersonalityChip(
                                personality: personality,
                                isSelected: selectedPersonality.name == personality.name,
                                action: { selectedPersonality = personality }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal)

            // Lyrics input area
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Paste Your Lyrics")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    if !lyricsText.isEmpty {
                        Text("\(lyricsText.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count) lines")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                ZStack(alignment: .topLeading) {
                    if lyricsText.isEmpty {
                        Text("Paste song lyrics here...\n\nEach line will be spoken by Moxie.\nAfter the performance, you can chat with Moxie who will stay in character!")
                            .foregroundColor(.white.opacity(0.4))
                            .padding(12)
                    }

                    TextEditor(text: $lyricsText)
                        .font(.system(.body, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .focused($isTextFieldFocused)
                }
                .frame(height: 300)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                        )
                )
                .foregroundColor(.white)
            }
            .padding(.horizontal)

            // Performance settings
            VStack(alignment: .leading, spacing: 12) {
                Text("Performance Settings")
                    .font(.headline)
                    .foregroundColor(.white)

                HStack(spacing: 20) {
                    // Delay between lines
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Delay between lines")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))

                        Picker("", selection: $viewModel.lineDelay) {
                            Text("0.5s").tag(0.5)
                            Text("1s").tag(1.0)
                            Text("1.5s").tag(1.5)
                            Text("2s").tag(2.0)
                            Text("3s").tag(3.0)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 250)
                    }

                    Spacer()

                    Toggle("Auto-chat after performance", isOn: $viewModel.autoChatAfter)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal)

            Spacer()

            // Start button
            Button(action: startPerformance) {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.title2)
                    Text("Start Performance")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: lyricsText.isEmpty ?
                            [Color.gray.opacity(0.3), Color.gray.opacity(0.2)] :
                            [Color.pink, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: lyricsText.isEmpty ? .clear : .pink.opacity(0.5), radius: 10)
            }
            .buttonStyle(.plain)
            .disabled(lyricsText.isEmpty)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding(.top)
    }

    // MARK: - Performance View
    private var performanceView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Current line being spoken
            VStack(spacing: 16) {
                Text(selectedPersonality.emoji)
                    .font(.system(size: 80))
                    .scaleEffect(viewModel.isSpeaking ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true), value: viewModel.isSpeaking)

                Text("Line \(viewModel.currentLineIndex + 1) of \(viewModel.totalLines)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))

                Text(viewModel.currentLine)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.pink.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.pink.opacity(0.5), lineWidth: 2)
                            )
                    )
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentLine)
            }

            // Progress bar
            VStack(spacing: 8) {
                ProgressView(value: Double(viewModel.currentLineIndex + 1), total: Double(viewModel.totalLines))
                    .progressViewStyle(.linear)
                    .tint(.pink)
                    .frame(width: 300)

                Text("\(Int((Double(viewModel.currentLineIndex + 1) / Double(viewModel.totalLines)) * 100))% complete")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            // Control buttons
            HStack(spacing: 20) {
                Button(action: { viewModel.stopPerformance() }) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("Stop")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.6))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)

                Button(action: { viewModel.skipToChat(personality: selectedPersonality) }) {
                    HStack {
                        Image(systemName: "forward.fill")
                        Text("Skip to Chat")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.purple.opacity(0.6))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Character Chat View
    private var characterChatView: some View {
        VStack(spacing: 0) {
            // Character badge
            HStack {
                Text(selectedPersonality.emoji)
                    .font(.title)
                Text("Chatting as \(selectedPersonality.name)")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Text("Moxie will stay in character!")
                    .font(.caption)
                    .foregroundColor(.purple.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
            }
            .padding()
            .background(Color.purple.opacity(0.15))

            Divider()
                .background(Color.white.opacity(0.2))

            // Chat messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.chatMessages) { message in
                            LyricChatBubble(message: message)
                                .id(message.id)
                        }

                        if viewModel.isWaitingForResponse {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Moxie is thinking in character...")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.chatMessages.count) { _ in
                    if let lastMessage = viewModel.chatMessages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()
                .background(Color.white.opacity(0.2))

            // Chat input
            HStack(spacing: 12) {
                TextField("Chat with \(selectedPersonality.name)...", text: $viewModel.chatInput)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .foregroundColor(.white)
                    .onSubmit {
                        viewModel.sendChatMessage(personality: selectedPersonality)
                    }

                Button(action: { viewModel.sendChatMessage(personality: selectedPersonality) }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: viewModel.chatInput.isEmpty ?
                                        [Color.gray.opacity(0.3), Color.gray.opacity(0.2)] :
                                        [Color.purple, Color.pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                            .shadow(color: viewModel.chatInput.isEmpty ? .clear : .purple.opacity(0.5), radius: 8)

                        Image(systemName: "arrow.up")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                .disabled(viewModel.chatInput.isEmpty || viewModel.isWaitingForResponse)
            }
            .padding()
            .background(Color.black.opacity(0.3))
        }
    }

    // MARK: - Helpers
    private var availablePersonalities: [Personality] {
        [
            .freestyleRapper,
            .twoPac,
            .roastMode,
            .shakespeare,
            .pirateMode,
            .yodaMode,
            .valleyGirl,
            .motivationalCoach,
            .defaultMoxie
        ]
    }

    private func startPerformance() {
        let lines = lyricsText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        viewModel.startPerformance(lines: lines, personality: selectedPersonality)
    }
}

// MARK: - Personality Chip
struct PersonalityChip: View {
    let personality: Personality
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(personality.emoji)
                    .font(.title3)
                Text(personality.name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.pink.opacity(0.4) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? Color.pink : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Lyric Chat Bubble
struct LyricChatBubble: View {
    let message: LyricChatMessage

    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.isUser ? "You" : message.characterName)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))

                Text(message.text)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(message.isUser ?
                                  Color.blue.opacity(0.3) :
                                  Color.purple.opacity(0.3))
                    )
            }
            .frame(maxWidth: 400, alignment: message.isUser ? .trailing : .leading)

            if !message.isUser {
                Spacer(minLength: 60)
            }
        }
    }
}

// MARK: - Lyric Chat Message Model
struct LyricChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let characterName: String
    let timestamp = Date()
}

// MARK: - Lyric Mode ViewModel
@MainActor
class LyricModeViewModel: ObservableObject {
    @Published var isPerforming = false
    @Published var isInCharacterMode = false
    @Published var isSpeaking = false
    @Published var currentLine = ""
    @Published var currentLineIndex = 0
    @Published var totalLines = 0
    @Published var lineDelay: Double = 1.5
    @Published var autoChatAfter = true

    @Published var chatMessages: [LyricChatMessage] = []
    @Published var chatInput = ""
    @Published var isWaitingForResponse = false

    private var lines: [String] = []
    private var currentPersonality: Personality?
    private var performanceTask: Task<Void, Never>?

    func startPerformance(lines: [String], personality: Personality) {
        self.lines = lines
        self.currentPersonality = personality
        self.totalLines = lines.count
        self.currentLineIndex = 0
        self.isPerforming = true

        performanceTask = Task {
            for (index, line) in lines.enumerated() {
                guard isPerforming else { break }

                currentLineIndex = index
                currentLine = line
                isSpeaking = true

                // Send line to Moxie
                await speakLine(line)

                isSpeaking = false

                // Wait between lines
                if index < lines.count - 1 {
                    try? await Task.sleep(nanoseconds: UInt64(lineDelay * 1_000_000_000))
                }
            }

            // Performance complete
            isPerforming = false

            if autoChatAfter {
                // Transition to character chat mode
                transitionToCharacterChat(personality: personality)
            }
        }
    }

    func stopPerformance() {
        performanceTask?.cancel()
        isPerforming = false
        isSpeaking = false
    }

    func skipToChat(personality: Personality) {
        stopPerformance()
        transitionToCharacterChat(personality: personality)
    }

    func resetToLyrics() {
        isInCharacterMode = false
        chatMessages = []
        chatInput = ""
        currentLine = ""
        currentLineIndex = 0
    }

    private func transitionToCharacterChat(personality: Personality) {
        currentPersonality = personality
        isInCharacterMode = true

        // Add opening message from character
        let opener = personality.opener
            .replacingOccurrences(of: #"\[emotion:\w+\]"#, with: "", options: .regularExpression)
            .components(separatedBy: "|")
            .first ?? "That was fun! What do you want to talk about?"

        chatMessages.append(LyricChatMessage(
            text: opener.trimmingCharacters(in: .whitespacesAndNewlines),
            isUser: false,
            characterName: personality.name
        ))
    }

    func sendChatMessage(personality: Personality) {
        let text = chatInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Add user message
        chatMessages.append(LyricChatMessage(
            text: text,
            isUser: true,
            characterName: ""
        ))

        chatInput = ""
        isWaitingForResponse = true

        Task {
            do {
                let response = try await getAIResponse(userMessage: text, personality: personality)
                chatMessages.append(LyricChatMessage(
                    text: response,
                    isUser: false,
                    characterName: personality.name
                ))

                // Also make Moxie speak the response
                await speakLine(response)
            } catch {
                chatMessages.append(LyricChatMessage(
                    text: "Oops, something went wrong. Let's try again!",
                    isUser: false,
                    characterName: personality.name
                ))
            }
            isWaitingForResponse = false
        }
    }

    private func speakLine(_ text: String) async {
        // Use the puppet API to make Moxie speak
        guard let url = URL(string: AppConfig.puppetEndpoint(speech: text, mood: "happy")) else { return }

        do {
            let (_, _) = try await URLSession.shared.data(from: url)
        } catch {
            print("Puppet API error: \(error)")
        }
    }

    private func getAIResponse(userMessage: String, personality: Personality) async throws -> String {
        // Use OpenMoxie's interact_update API
        guard let url = URL(string: AppConfig.interactEndpoint) else {
            throw NSError(domain: "LyricMode", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // Build conversation context with personality instructions
        let contextPrompt = """
        You are Moxie, staying in character as \(personality.name).
        \(personality.prompt)

        The user just watched you perform some lyrics and now wants to chat.
        Stay completely in character for your response.
        Keep responses concise (2-3 sentences max).
        """

        let formData = "speech=\(userMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? userMessage)&token=166007a1ff3940b58b901111c9767265&module_id=OPENMOXIE_CHAT&content_id=default&context=\(contextPrompt.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        request.httpBody = formData.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "LyricMode", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        if httpResponse.statusCode == 200 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["message"] as? String {
                // Strip emotion tags
                return message
                    .replacingOccurrences(of: #"\[emotion:\w+\]"#, with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        throw NSError(domain: "LyricMode", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error"])
    }
}
