import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var viewModel: ContentViewModel
    @Environment(\.diContainer) var diContainer
    @ObservedObject private var localization = LocalizationService.shared
    @StateObject private var modeContext = ModeContext.shared

    // Chat state
    @State private var chatInput = ""
    @State private var chatMessages: [QuickChatMessage] = []
    @State private var isChatExpanded = false
    @State private var isSendingChat = false
    @FocusState private var isChatFocused: Bool

    var body: some View {
        ZStack {
            // Background with opacity
            Color.black.opacity(0.80)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    headerView

                    if viewModel.isUpdating {
                        loadingView
                    }

                    if let status = viewModel.statusMessage {
                        statusView(status)
                    }

                    personalityGrid
                }
                .padding()

                // Chat Panel
                chatPanel
            }
            .frame(minWidth: 500, minHeight: 400)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [Color.green, Color.cyan, Color.blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .shadow(color: .cyan, radius: 1, x: 0, y: 0)
                .shadow(color: .green, radius: 1, x: 0, y: 0)
                .shadow(color: .cyan, radius: 1, x: 0, y: 0)
        )
        .sheet(isPresented: $viewModel.showCustomCreator) {
            CustomPersonalityView()
                .environmentObject(diContainer.resolve(PersonalityViewModel.self))
        }
        .sheet(isPresented: $viewModel.showAppearance) {
            AppearanceCustomizationView()
                .environmentObject(diContainer.resolve(AppearanceViewModel.self))
        }
        .sheet(isPresented: $viewModel.showSettings) {
            SettingsView()
                .environmentObject(diContainer.resolve(SettingsViewModel.self))
        }
        .sheet(isPresented: $viewModel.showPersonalityEditor) {
            if let personality = viewModel.editingPersonality {
                PersonalityEditorView(personality: personality)
                    .environmentObject(diContainer.resolve(PersonalityViewModel.self))
            }
        }
        .sheet(isPresented: $viewModel.showChat) {
            AllConversationsView()
        }
        .sheet(isPresented: $viewModel.showStoryTime) {
            StoryTimeView()
        }
        .sheet(isPresented: $viewModel.showLearning) {
            LearningView()
        }
        .sheet(isPresented: $viewModel.showLanguage) {
            LanguageView()
        }
        .sheet(isPresented: $viewModel.showMusic) {
            MusicView()
        }
        .sheet(isPresented: $viewModel.showSetupWizard) {
            SetupWizardView()
        }
        .sheet(isPresented: $viewModel.showSmartHome) {
            SmartHomeView()
                .environmentObject(diContainer.resolve(SmartHomeViewModel.self))
        }
        .sheet(isPresented: $viewModel.showPuppetMode) {
            PuppetModeView()
        }
        .sheet(isPresented: $viewModel.showLyricMode) {
            LyricModeView()
        }
        .sheet(isPresented: $viewModel.showChildProfile) {
            ChildProfileView()
        }
        .sheet(isPresented: $viewModel.showGames) {
            GamesMenuView()
        }
        .sheet(isPresented: $viewModel.showDocumentation) {
            DocumentationView()
        }
        .sheet(isPresented: $viewModel.showModelSelector) {
            ModelSelectorView()
        }
    }

    // MARK: - View Components
    private var headerView: some View {
        VStack(spacing: 8) {
            Text(localization.localize("moxie_controller"))
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 10)

            // Status indicator with language selector
            HStack(spacing: 12) {
                // Online status - CLICKABLE to switch models
                Button(action: {
                    if viewModel.isOnline {
                        viewModel.showModelSelector = true
                    }
                }) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(viewModel.isOnline ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                            .shadow(color: viewModel.isOnline ? .green : .red, radius: 5)

                        if viewModel.isOnline {
                            if let onlineTime = viewModel.onlineTime {
                                Text("Online - \(formatUptime(onlineTime))")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            } else {
                                Text(localization.localize("online"))
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        } else {
                            Text(localization.localize("offline"))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }

                        if viewModel.isOnline {
                            Image(systemName: "chevron.down.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        viewModel.isOnline ?
                            Color.white.opacity(0.15) :
                            Color.white.opacity(0.1),
                        in: RoundedRectangle(cornerRadius: 20)
                    )
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.isOnline)

                // Language selector
                LanguageDropdownMenu()
            }
        }
    }

    private func formatUptime(_ startTime: Date) -> String {
        let interval = Date().timeIntervalSince(startTime)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60

        if hours > 0 {
            return String(format: "%dh %dm %ds", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }

    private var loadingView: some View {
        ProgressView("Switching personality...")
            .tint(.white)
            .foregroundColor(.white)
            .padding()
    }

    private func statusView(_ status: String) -> some View {
        Text(status)
            .foregroundColor(status.contains("SUCCESS") ? .green : .red)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(10)
    }

    private var personalityGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 15) {
                // Feature buttons
                // Start Docker button (shown when offline)
                if !viewModel.isOnline {
                    PlasticButton.startDocker {
                        Task {
                            await viewModel.startDockerContainer()
                        }
                    }
                }

                PlasticButton.childProfile {
                    viewModel.showChildProfile = true
                }

                PlasticButton.customCreator {
                    viewModel.showCustomCreator = true
                }

                PlasticButton.appearance {
                    viewModel.showAppearance = true
                }

                PlasticButton.chat {
                    viewModel.showChat = true
                }

                PlasticButton.storyTime {
                    viewModel.showStoryTime = true
                }

                PlasticButton.learning {
                    viewModel.showLearning = true
                }

                PlasticButton.language {
                    viewModel.showLanguage = true
                }

                PlasticButton.music {
                    viewModel.showMusic = true
                }

                PlasticButton.smartHome {
                    viewModel.showSmartHome = true
                }

                PlasticButton.puppetMode {
                    viewModel.showPuppetMode = true
                }

                PlasticButton.lyricMode {
                    viewModel.showLyricMode = true
                }

                PlasticButton.games {
                    viewModel.showGames = true
                }

                PlasticButton.settings {
                    viewModel.showSettings = true
                }

                PlasticButton.documentation {
                    viewModel.showDocumentation = true
                }

                // Learning tiles
                ForEach(viewModel.learningTiles) { tile in
                    PlasticButton.learningTile(tile: tile) {
                        // TODO: Open LearningView and load this session
                        viewModel.showLearning = true
                    }
                }

                // Story tiles
                ForEach(viewModel.storyTiles) { tile in
                    PlasticButton.storyTile(tile: tile) {
                        // TODO: Open StoryTimeView and load this session
                        viewModel.showStoryTime = true
                    }
                }

                // Personality buttons
                ForEach(viewModel.allPersonalities) { personality in
                    PersonalityButton(
                        personality: personality,
                        isUpdating: viewModel.isUpdating,
                        onTap: {
                            print("[ContentView] onTap called for: \(personality.name)")
                            Task {
                                await viewModel.switchPersonality(personality)
                            }
                        },
                        onDoubleTap: {
                            viewModel.editPersonality(personality)
                        }
                    )
                }
            }
            .padding()
        }
    }

    // MARK: - Chat Panel
    private var chatPanel: some View {
        VStack(spacing: 0) {
            // Chat header - tap to expand/collapse
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isChatExpanded.toggle()
                    if isChatExpanded {
                        isChatFocused = true
                    }
                }
            }) {
                HStack {
                    Image(systemName: isChatExpanded ? "chevron.down" : "chevron.up")
                        .font(.caption)
                    Text("Chat with Moxie")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    if !chatMessages.isEmpty {
                        Text("\(chatMessages.count) messages")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    if isSendingChat {
                        ProgressView()
                            .scaleEffect(0.6)
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.purple.opacity(0.4))
            }
            .buttonStyle(.plain)

            if isChatExpanded {
                // Messages area
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(chatMessages) { message in
                                QuickChatBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .frame(height: 200)
                    .background(Color.black.opacity(0.3))
                    .onChange(of: chatMessages.count) { _ in
                        if let lastMessage = chatMessages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // Input area
                HStack(spacing: 12) {
                    ChatTextField(text: $chatInput, placeholder: "Type a message...", onSubmit: {
                        logChat("[Chat] onSubmit triggered from ChatTextField")
                        sendChatMessage()
                    })

                    Button(action: sendChatMessage) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18))
                            .foregroundColor(chatInput.isEmpty || isSendingChat ? .gray : .cyan)
                    }
                    .buttonStyle(.plain)
                    .disabled(chatInput.isEmpty || isSendingChat)

                    Button(action: { saveChat() }) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 16))
                            .foregroundColor(.green.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .disabled(chatMessages.isEmpty)

                    Button(action: { chatMessages.removeAll() }) {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundColor(.red.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .disabled(chatMessages.isEmpty)
                }
                .padding()
                .background(Color.black.opacity(0.4))
            }
        }
    }

    private func logChat(_ message: String) {
        let logFile = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("moxie_chat_debug.log")
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logLine = "[\(timestamp)] \(message)\n"
        if let data = logLine.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFile.path) {
                if let handle = try? FileHandle(forWritingTo: logFile) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    handle.closeFile()
                }
            } else {
                try? data.write(to: logFile)
            }
        }
        print(message)
    }

    private func sendChatMessage() {
        logChat("[Chat] sendChatMessage called, input: '\(chatInput)'")
        let text = chatInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSendingChat else {
            logChat("[Chat] Guard failed: text.isEmpty=\(text.isEmpty), isSendingChat=\(isSendingChat)")
            return
        }

        logChat("[Chat] Sending message: \(text)")

        // Add user message
        let userMessage = QuickChatMessage(text: text, isUser: true)
        chatMessages.append(userMessage)
        chatInput = ""
        isSendingChat = true

        Task { @MainActor in
            do {
                logChat("[Chat] Calling sendToMoxie...")
                let response = try await sendToMoxie(text)
                logChat("[Chat] Got response: \(response)")
                let moxieMessage = QuickChatMessage(text: response, isUser: false)
                chatMessages.append(moxieMessage)
                // Auto-save after each response
                autoSaveChat()
            } catch {
                logChat("[Chat] Error: \(error)")
                let errorMessage = QuickChatMessage(text: "Error: \(error.localizedDescription)", isUser: false)
                chatMessages.append(errorMessage)
            }
            isSendingChat = false
        }
    }

    private func sendToMoxie(_ text: String) async throws -> String {
        // Use OpenMoxie's interact_update API to get response
        let endpoint = AppConfig.interactEndpoint
        logChat("[Chat] Using endpoint: \(endpoint)")

        guard let url = URL(string: endpoint) else {
            logChat("[Chat] ERROR: Invalid URL from endpoint: \(endpoint)")
            throw NSError(domain: "Chat", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL: \(endpoint)"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        // Form data format
        let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text
        let formData = "speech=\(encodedText)&token=166007a1ff3940b58b901111c9767265&module_id=OPENMOXIE_CHAT&content_id=default"
        request.httpBody = formData.data(using: .utf8)

        logChat("[Chat] Sending POST to: \(url.absoluteString)")
        logChat("[Chat] Form data: \(formData)")

        let (data, response) = try await URLSession.shared.data(for: request)

        let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode"
        logChat("[Chat] Raw response: \(responseString)")

        guard let httpResponse = response as? HTTPURLResponse else {
            logChat("[Chat] ERROR: Response is not HTTPURLResponse")
            throw NSError(domain: "Chat", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
        }

        logChat("[Chat] HTTP Status: \(httpResponse.statusCode)")

        if httpResponse.statusCode == 200 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                logChat("[Chat] Parsed JSON keys: \(json.keys.joined(separator: ", "))")
                if let message = json["message"] as? String {
                    // Strip emotion tags for display
                    let cleanMessage = message.replacingOccurrences(of: "\\[emotion:\\w+\\]", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
                    logChat("[Chat] Clean message: \(cleanMessage)")

                    // Also make Moxie speak via puppet API
                    logChat("[Chat] Calling puppet API...")
                    await speakViaPuppet(cleanMessage)

                    return cleanMessage
                } else {
                    logChat("[Chat] WARNING: JSON has no 'message' key")
                }
            } else {
                logChat("[Chat] WARNING: Failed to parse JSON")
            }
            // Fallback: return raw response
            return responseString
        }

        throw NSError(domain: "Chat", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error: \(httpResponse.statusCode) - \(responseString)"])
    }

    private func speakViaPuppet(_ text: String) async {
        // Send speech to Moxie via puppet API
        let puppetURL = AppConfig.puppetEndpoint(speech: text, mood: "happy")
        logChat("[Puppet] URL: \(puppetURL)")

        guard let url = URL(string: puppetURL) else {
            logChat("[Puppet] ERROR: Invalid URL")
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                logChat("[Puppet] HTTP Status: \(httpResponse.statusCode)")
            }
            if let responseStr = String(data: data, encoding: .utf8) {
                logChat("[Puppet] Response: \(responseStr)")
            }
        } catch {
            logChat("[Puppet] ERROR: \(error)")
        }
    }

    private func saveChat(showInFinder: Bool = true) {
        logChat("[Save] saveChat called, message count: \(chatMessages.count)")
        guard !chatMessages.isEmpty else {
            logChat("[Save] No messages to save")
            return
        }

        // Save to Documents/MoxieChats
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let chatsDir = documentsPath.appendingPathComponent("MoxieChats")
        logChat("[Save] Chats directory: \(chatsDir.path)")

        // Create directory if needed
        do {
            try FileManager.default.createDirectory(at: chatsDir, withIntermediateDirectories: true, attributes: nil)
            logChat("[Save] Directory created/exists")
        } catch {
            logChat("[Save] ERROR creating directory: \(error)")
            return
        }

        // Create filename with timestamp
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let filename = "chat_\(formatter.string(from: Date())).json"
        let fileURL = chatsDir.appendingPathComponent(filename)
        logChat("[Save] Saving to: \(fileURL.path)")

        // Convert messages to saveable format
        let saveData: [[String: Any]] = chatMessages.map { msg in
            [
                "text": msg.text,
                "isUser": msg.isUser,
                "timestamp": ISO8601DateFormatter().string(from: msg.timestamp)
            ]
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: saveData, options: .prettyPrinted)
            try jsonData.write(to: fileURL)
            logChat("[Save] Chat saved successfully to: \(fileURL.path)")

            // Show in Finder
            if showInFinder {
                NSWorkspace.shared.selectFile(fileURL.path, inFileViewerRootedAtPath: chatsDir.path)
            }
        } catch {
            logChat("[Save] ERROR: Failed to save chat: \(error)")
        }
    }

    // Auto-save after each response
    private func autoSaveChat() {
        saveChat(showInFinder: false)
    }
}

// MARK: - Quick Chat Message Model
struct QuickChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp = Date()
}

// MARK: - Quick Chat Bubble
struct QuickChatBubble: View {
    let message: QuickChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 60) }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.isUser ? "You" : "Moxie")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))

                Text(message.text)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        message.isUser ?
                            Color.blue.opacity(0.6) :
                            Color.purple.opacity(0.6),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
            }

            if !message.isUser { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Chat TextField (NSViewRepresentable for better macOS compatibility)
struct ChatTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var onSubmit: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.placeholderString = placeholder
        textField.delegate = context.coordinator
        textField.isBordered = false
        textField.backgroundColor = NSColor.white.withAlphaComponent(0.1)
        textField.textColor = .white
        textField.focusRingType = .none
        textField.font = NSFont.systemFont(ofSize: 14)
        textField.wantsLayer = true
        textField.layer?.cornerRadius = 8
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.stringValue = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: ChatTextField

        init(_ parent: ChatTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text = textField.stringValue
            }
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onSubmit()
                return true
            }
            return false
        }
    }
}

// MARK: - Personality Button
struct PersonalityButton: View {
    let personality: Personality
    let isUpdating: Bool
    let onTap: () -> Void
    let onDoubleTap: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false
    @State private var breatheScale: CGFloat = 1.0
    @ObservedObject private var localization = LocalizationService.shared

    var body: some View {
        Button(action: {
            print("[PersonalityButton] Button pressed for: \(personality.name)")
            // Call action immediately
            onTap()

            // Animation only
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
        }) {
            VStack(spacing: 10) {
                Text(personality.emoji)
                    .font(.system(size: isPressed ? 45 : (isHovered ? 60 : 50)))
                    .scaleEffect(isHovered ? breatheScale : 1.0)
                    .rotationEffect(.degrees(isHovered ? sin(Double(breatheScale) * Double.pi * 2.0) * 5.0 : 0))
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: breatheScale)
                Text(localization.localize(personality.name))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .foregroundColor(.white)
            .frame(width: 150, height: 100)
            .background(plasticBackground)
            .cornerRadius(18)
            .overlay(glossyOverlay)
            // Enhanced shadow with press effect
            .shadow(color: isPressed ? .purple : .cyan.opacity(isHovered ? 0.9 : 0.6),
                    radius: isPressed ? 30 : (isHovered ? 20 : 15),
                    x: 0,
                    y: isPressed ? 5 : (isHovered ? 12 : 8))
            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
            // Glow effect when pressed
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isPressed ? Color.cyan.opacity(0.8) : Color.clear, lineWidth: 3)
                    .blur(radius: isPressed ? 5 : 0)
                    .animation(.easeInOut(duration: 0.1), value: isPressed)
            )
        }
        .buttonStyle(.plain)
        .disabled(isUpdating)
        .scaleEffect(isUpdating ? 0.95 : (isPressed ? 0.92 : (isHovered ? 1.15 : 1.0)))
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isUpdating)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                // Start breathing animation
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    breatheScale = 1.15
                }
            } else {
                // Stop breathing animation
                withAnimation(.easeOut(duration: 0.3)) {
                    breatheScale = 1.0
                }
            }
        }
        .onTapGesture(count: 2) {
            onDoubleTap()
        }
    }

    private var plasticBackground: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.cyan.opacity(0.8),
                    Color.cyan.opacity(0.6)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )

            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.6),
                    Color.white.opacity(0.0)
                ]),
                startPoint: .top,
                endPoint: .center
            )
        }
    }

    private var glossyOverlay: some View {
        RoundedRectangle(cornerRadius: 18)
            .stroke(Color.white.opacity(0.6), lineWidth: 2)
            .blur(radius: 1)
    }
}

// MARK: - Language Dropdown Menu
struct LanguageDropdownMenu: View {
    @State private var selectedLanguage: Language
    @State private var isUpdating = false

    init() {
        let current = LanguagePreferenceManager.shared.currentLanguage
        if let language = Language.allLanguages.first(where: { $0.code == current.code }) {
            _selectedLanguage = State(initialValue: language)
        } else {
            _selectedLanguage = State(initialValue: Language.allLanguages[0])
        }
    }

    var body: some View {
        Menu {
            ForEach(Language.allLanguages, id: \.code) { language in
                Button(action: {
                    selectedLanguage = language
                    LanguagePreferenceManager.shared.setLanguage(code: language.code, name: language.name)

                    // Force LocalizationService to update
                    LocalizationService.shared.forceLanguageUpdate(language)

                    // Update OpenMoxie with the new language immediately
                    Task {
                        await updateOpenMoxieLanguage(language)
                    }
                }) {
                    HStack {
                        Text(language.flag)
                            .font(.title3)
                        Text(language.name)
                            .font(.body)
                        if language.code == selectedLanguage.code {
                            Image(systemName: "checkmark")
                                .foregroundColor(.purple)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "globe")
                    .font(.title3)
                Text(selectedLanguage.flag)
                    .font(.title3)
                Text(selectedLanguage.name)
                    .font(.body)
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.purple.opacity(0.3), in: RoundedRectangle(cornerRadius: 20))
        }
        .menuStyle(.borderlessButton)
        .disabled(isUpdating)
    }

    private func updateOpenMoxieLanguage(_ language: Language) async {
        isUpdating = true
        defer { isUpdating = false }

        let dockerService = DIContainer.shared.resolve(DockerServiceProtocol.self)

        // Get the language instruction
        let languageInstruction = getLanguageInstruction(for: language.code)

        let languageScript = """
        import os
        import re
        # Set the language environment variable
        os.environ['MOXIE_LANGUAGE'] = '\(language.name)'
        os.environ['MOXIE_LANGUAGE_CODE'] = '\(language.code)'

        # Update in database
        from hive.models import MoxieDevice, PersistentData, SinglePromptChat
        device = MoxieDevice.objects.filter(device_id='moxie_001').first()
        if device:
            persist, created = PersistentData.objects.get_or_create(device=device, defaults={'data': {}})
            data = persist.data or {}
            data['language_preference'] = {
                'code': '\(language.code)',
                'name': '\(language.name)'
            }
            persist.data = data
            persist.save()

        # Update ALL SinglePromptChat entries with the new language instruction
        language_instruction = '''\(languageInstruction)'''

        for chat in SinglePromptChat.objects.all():
            # Remove any existing language instruction
            prompt = chat.prompt
            prompt = re.sub(r'\\n*LANGUAGE INSTRUCTION:.*$', '', prompt, flags=re.DOTALL)

            # Add new language instruction
            chat.prompt = prompt.strip() + '\\n\\nLANGUAGE INSTRUCTION: ' + language_instruction
            chat.save()

        print(f'Language updated to: \(language.name) for all personalities')
        """

        do {
            _ = try await dockerService.executePythonScript(languageScript)
            try await dockerService.restartServer()
        } catch {
            print("Failed to update language: \(error)")
        }
    }

    private func getLanguageInstruction(for languageCode: String) -> String {
        switch languageCode {
        case "es":
            return "Siempre responde COMPLETAMENTE en español. Toda tu respuesta debe estar en español, incluyendo las emociones."
        case "sv":
            return "Svara ALLTID HELT på svenska. Hela ditt svar måste vara på svenska, inklusive känslor."
        case "zh":
            return "始终完全用中文回答。你的整个回复必须是中文，包括情绪。"
        case "fr":
            return "Réponds TOUJOURS COMPLÈTEMENT en français. Toute ta réponse doit être en français, y compris les émotions."
        case "de":
            return "Antworte IMMER VOLLSTÄNDIG auf Deutsch. Deine gesamte Antwort muss auf Deutsch sein, einschließlich Emotionen."
        case "it":
            return "Rispondi SEMPRE COMPLETAMENTE in italiano. Tutta la tua risposta deve essere in italiano, comprese le emozioni."
        case "ru":
            return "Всегда отвечай ПОЛНОСТЬЮ на русском языке. Весь твой ответ должен быть на русском, включая эмоции."
        case "ja":
            return "常に完全に日本語で答えてください。感情を含め、すべての返答は日本語でなければなりません。"
        case "ko":
            return "항상 완전히 한국어로 대답하세요. 감정을 포함한 모든 응답은 한국어여야 합니다."
        default:
            return "Always respond in English."
        }
    }
}
