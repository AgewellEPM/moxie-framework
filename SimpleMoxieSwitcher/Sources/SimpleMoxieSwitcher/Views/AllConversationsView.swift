import SwiftUI

// MARK: - All Conversations View (ChatGPT Style)
struct AllConversationsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.diContainer) var diContainer
    @StateObject private var viewModel = OldAllConversationsViewModel()
    @StateObject private var memoryViewModel = MemoryViewModel()
    @State private var messageText = ""
    @State private var showMemoryExtraction = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        Group {
            if viewModel.selectedConversation == nil {
                // Show conversation list full screen
                conversationListView
            } else {
                // Show chat interface with back button
                chatWithBackButton
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .onAppear {
            Task {
                await viewModel.loadAllConversations()
                await memoryViewModel.loadExistingMemories()
            }
        }
        .sheet(isPresented: $showMemoryExtraction) {
            MemoryExtractionSheet(
                viewModel: memoryViewModel,
                conversations: viewModel.allConversations
            )
        }
    }

    // MARK: - Full Screen Conversation List

    private var conversationListView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("💬 All Conversations")
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

            Divider()

            // Content
            if viewModel.allConversations.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "message")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No conversations yet")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Talk to Moxie to see conversations here")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Start Conversation Button
                    Button(action: { viewModel.startNewConversation() }) {
                        HStack(spacing: 16) {
                            Text("💬")
                                .font(.system(size: 40))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Start Conversation")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text("Create a new chat with Moxie")
                                    .font(.caption)
                                    .opacity(0.8)
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 20)
                        .padding(.horizontal, 24)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.2, green: 0.8, blue: 0.4),
                                    Color(red: 0.1, green: 0.7, blue: 0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.6), radius: 15, x: 0, y: 8)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2, pinnedViews: [.sectionHeaders]) {
                        ForEach(viewModel.conversationsByPersonality.keys.sorted(), id: \.self) { personality in
                            Section {
                                if viewModel.expandedPersonalities.contains(personality) {
                                    ForEach(viewModel.conversationsByPersonality[personality] ?? []) { conversation in
                                        ConversationSidebarRow(
                                            conversation: conversation,
                                            isSelected: false,
                                            onSelect: {
                                                Task {
                                                    await viewModel.selectConversation(conversation)
                                                }
                                            }
                                        )
                                    }
                                }
                            } header: {
                                PersonalityFolderHeader(
                                    personality: personality,
                                    emoji: viewModel.conversationsByPersonality[personality]?.first?.personalityEmoji ?? "💬",
                                    count: viewModel.conversationsByPersonality[personality]?.count ?? 0,
                                    isExpanded: viewModel.expandedPersonalities.contains(personality),
                                    onToggle: {
                                        if viewModel.expandedPersonalities.contains(personality) {
                                            viewModel.expandedPersonalities.remove(personality)
                                        } else {
                                            viewModel.expandedPersonalities.insert(personality)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Divider()

                // Bottom Actions
                HStack {
                    Button(action: { viewModel.startNewConversation() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("New Conversation")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Memory Extraction Button
                    Button(action: { showMemoryExtraction = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "brain.head.profile")
                            Text("Extract Memories")
                            if memoryViewModel.totalMemoriesExtracted > 0 {
                                Text("(\(memoryViewModel.totalMemoriesExtracted))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.purple.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        Task { await viewModel.loadAllConversations() }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(Color.black.opacity(0.2))
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Chat with Back Button

    private var chatWithBackButton: some View {
        VStack(spacing: 0) {
            // Chat Header with Back Button
            HStack {
                Button(action: {
                    viewModel.selectedConversation = nil
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.cyan)
                }
                .buttonStyle(.plain)

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    if let current = viewModel.selectedConversation {
                        HStack {
                            Text(current.personalityEmoji ?? "💬")
                            Text(current.filename.replacingOccurrences(of: ".jsonl", with: ""))
                                .font(.headline)
                        }
                        Text("\(current.messageCount) messages • \(timeAgo(from: current.lastModified))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(.ultraThinMaterial)

            Divider()

            // Messages Area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.messages) { message in
                            ChatMessageBubble(message: message)
                                .id(message.id)
                        }

                        if viewModel.isSendingMessage {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Thinking...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Input Area
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    TextField("Type your message here...", text: $messageText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .focused($isInputFocused)
                        .onSubmit {
                            sendMessage()
                        }

                    Button(action: sendMessage) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: messageText.isEmpty ?
                                            [Color.gray.opacity(0.3), Color.gray.opacity(0.2)] :
                                            [Color.cyan, Color.blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                                .shadow(color: messageText.isEmpty ? .clear : .cyan.opacity(0.5), radius: 8)

                            Image(systemName: "arrow.up")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(messageText.isEmpty || viewModel.isSendingMessage)
                }

                HStack {
                    if viewModel.isSendingMessage {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Sending to Moxie...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if !messageText.isEmpty {
                        Text("Press Return or click the button to send")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Continue your conversation with Moxie")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.3), Color.black.opacity(0.2)],
                    startPoint: .top,
                    endPoint: .bottom)
            )
        }
        .sheet(isPresented: $viewModel.showKnowledgeGraph) {
            KnowledgeGraphView()
                .environmentObject(viewModel.knowledgeGraphService)
        }
    }

    private func sendMessage() {
        guard !messageText.isEmpty else { return }

        Task {
            await viewModel.sendMessage(messageText)
            messageText = ""
            isInputFocused = true
        }
    }

    private func timeAgo(from date: Date) -> String {
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: Date())

        if let days = components.day, days > 0 {
            return "\(days)d ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "Just now"
        }
    }
}

// MARK: - Old ViewModel (Moved to separate file)
// The ViewModel has been moved to ViewModels/AllConversationsViewModel.swift
@MainActor
class OldAllConversationsViewModel: ObservableObject {
    @Published var allConversations: [ConversationFile] = []
    @Published var conversationsByPersonality: [String: [ConversationFile]] = [:]
    @Published var expandedPersonalities: Set<String> = []
    @Published var selectedConversation: ConversationFile?
    @Published var messages: [ChatMessage] = []
    @Published var isSendingMessage: Bool = false
    @Published var showKnowledgeGraph: Bool = false

    let knowledgeGraphService = KnowledgeGraphService()
    private let conversationsDir = AppPaths.conversations

    func startNewConversation() {
        // Create a new conversation file with timestamp
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let filename = "moxie_coach_\(timestamp.replacingOccurrences(of: ":", with: ""))"
        let fileURL = conversationsDir.appendingPathComponent("\(filename).jsonl")

        // Create empty file
        try? "".write(to: fileURL, atomically: true, encoding: .utf8)

        // Reload conversations and select the new one
        Task {
            await loadAllConversations()
            // The new conversation should be first (most recent)
            if let newConversation = allConversations.first {
                await selectConversation(newConversation)
            }
        }
    }

    func loadAllConversations() async {
        // Fetch conversations from OpenMoxie database
        do {
            let dockerService = DIContainer.shared.resolve(DockerServiceProtocol.self)

            let pythonScript = """
            import json
            import sys
            from hive.models import MoxieDevice, PersistentData

            # Suppress Django import messages
            sys.stderr = open('/dev/null', 'w')

            # STEP 1: Find all devices and their data
            all_devices = MoxieDevice.objects.all()
            sys.stdout.write('TOTAL_DEVICES:' + str(all_devices.count()) + '\\n')

            for device in all_devices:
                sys.stdout.write('DEVICE:' + str(device.device_id) + '\\n')

            # STEP 2: Use the FIRST device (the real Moxie device, not moxie_001)
            device = MoxieDevice.objects.first()
            if device:
                persist = PersistentData.objects.filter(device=device).first()
                if persist and persist.data:
                    # Print all top-level keys
                    sys.stdout.write('PERSIST_DATA_KEYS:' + json.dumps(list(persist.data.keys())) + '\\n')

                    # Look for any key containing 'conversation' or 'memory'
                    for key in persist.data.keys():
                        if 'conversation' in key.lower() or 'memory' in key.lower():
                            val = persist.data[key]
                            sys.stdout.write('KEY_' + key + '_TYPE:' + str(type(val).__name__) + '\\n')

                            if isinstance(val, dict):
                                # Check if this dict has numbered keys
                                dict_keys = list(val.keys())[:10]
                                sys.stdout.write('KEY_' + key + '_DICT_KEYS:' + json.dumps(dict_keys) + '\\n')

                                # Check if keys are numbers (like "0", "1", "2")
                                numeric_keys = [k for k in dict_keys if k.isdigit()]
                                if numeric_keys:
                                    sys.stdout.write('FOUND_NUMBERED_CONVERSATIONS_IN:' + key + '\\n')
                                    # Output this data
                                    sys.stdout.write(json.dumps(val))
                                    sys.stdout.flush()
                                    exit()
                            elif isinstance(val, list):
                                sys.stdout.write('KEY_' + key + '_LIST_LENGTH:' + str(len(val)) + '\\n')

                                # Check the first item in the list
                                if len(val) > 0 and isinstance(val[0], dict):
                                    first_item_keys = list(val[0].keys())
                                    sys.stdout.write('KEY_' + key + '_FIRST_ITEM_KEYS:' + json.dumps(first_item_keys) + '\\n')

                                # Output the list
                                sys.stdout.write(json.dumps(val))
                                sys.stdout.flush()
                                exit()

                    sys.stdout.write('{}')
                    sys.stdout.flush()
                else:
                    sys.stdout.write('{}')
                    sys.stdout.flush()
            else:
                sys.stdout.write('{}')
                sys.stdout.flush()
            """

            let result = try await dockerService.executePythonScript(pythonScript)

            print("📊 Raw database output:")
            print(result)
            print("---")

            // Parse debug information and extract JSON
            let lines = result.components(separatedBy: "\n")
            var jsonStartLineIndex = 0

            for (index, line) in lines.enumerated() {
                if line.hasPrefix("TOTAL_DEVICES:") {
                    let count = String(line.dropFirst("TOTAL_DEVICES:".count))
                    print("🤖 Total devices in database: \(count)")
                } else if line.hasPrefix("DEVICE:") {
                    let deviceId = String(line.dropFirst("DEVICE:".count))
                    print("📱 Device found: \(deviceId)")
                } else if line.hasPrefix("PERSIST_DATA_KEYS:") {
                    let keysJSON = String(line.dropFirst("PERSIST_DATA_KEYS:".count))
                    print("🔑 All persist.data keys: \(keysJSON)")
                } else if line.hasPrefix("KEY_") && line.contains("_TYPE:") {
                    print("📦 \(line)")
                } else if line.hasPrefix("KEY_") && line.contains("_DICT_KEYS:") {
                    print("🗂️ \(line)")
                } else if line.hasPrefix("KEY_") && line.contains("_LIST_LENGTH:") {
                    print("📏 \(line)")
                } else if line.hasPrefix("KEY_") && line.contains("_FIRST_ITEM_KEYS:") {
                    print("🔍 \(line)")
                    jsonStartLineIndex = index + 1
                } else if line.hasPrefix("FOUND_NUMBERED_CONVERSATIONS_IN:") {
                    let keyName = String(line.dropFirst("FOUND_NUMBERED_CONVERSATIONS_IN:".count))
                    print("✅ FOUND IT! Conversations are in: \(keyName)")
                    jsonStartLineIndex = index + 1
                }
            }

            // Extract JSON from the lines after debug output
            let jsonLines = Array(lines[jsonStartLineIndex...])
            let jsonString = jsonLines.joined(separator: "\n")

            print("📊 Extracted JSON (first 200 chars): \(String(jsonString.prefix(200)))")

            guard let jsonData = jsonString.data(using: .utf8) else {
                print("❌ Failed to convert result to UTF8 data")
                allConversations = []
                return
            }

            // Try to parse as array (real Moxie data format)
            if let conversationsArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] {
                print("✅ Successfully parsed conversations array with \(conversationsArray.count) items")

                var loadedConversations: [ConversationFile] = []

                // Process each conversation from the array
                for (index, convDict) in conversationsArray.enumerated() {
                    // Each item in the array is a single conversation exchange
                    // Structure: {"timestamp": "...", "user": "...", "moxie": "..."}
                    let conversationId = String(index)
                    let messageCount = 1 // Each entry is one exchange

                    var personalityName: String?
                    var personalityEmoji: String?
                    var preview = "Empty conversation"
                    var lastModified = Date()

                    // Extract data from the single message
                    if let userMessage = convDict["user"] as? String {
                        preview = String(userMessage.prefix(60)) + (userMessage.count > 60 ? "..." : "")
                    }

                    if let timestampString = convDict["timestamp"] as? String,
                       let isoDate = ISO8601DateFormatter().date(from: timestampString) {
                        lastModified = isoDate
                    }

                    // Try to get personality from metadata if available
                    if let metadata = convDict["metadata"] as? [String: Any] {
                        personalityName = metadata["personality"] as? String
                    }

                    // Default personality
                    if personalityName == nil {
                        personalityName = "Moxie"
                    }

                    // Set emoji based on personality
                    personalityEmoji = "🤖"

                    // Wrap the single message in an array for compatibility
                    let messages = [convDict]

                    let conversation = ConversationFile(
                        id: conversationId,
                        filename: "Conversation \(conversationId)",
                        messages: messages,  // Store as single-item array
                        messageCount: messageCount,
                        lastModified: lastModified,
                        preview: preview,
                        personalityEmoji: personalityEmoji,
                        personalityName: personalityName
                    )

                    loadedConversations.append(conversation)
                }

                // Sort by last modified (newest first)
                loadedConversations.sort { $0.lastModified > $1.lastModified }

                allConversations = loadedConversations

                // Group by personality
                var grouped: [String: [ConversationFile]] = [:]
                for conversation in loadedConversations {
                    let personality = conversation.personalityName ?? "Unknown"
                    grouped[personality, default: []].append(conversation)
                }
                conversationsByPersonality = grouped

                // Expand all personalities by default
                expandedPersonalities = Set(grouped.keys)

                // Auto-select most recent if none selected
                if selectedConversation == nil, let first = loadedConversations.first {
                    await selectConversation(first)
                }
            } else {
                print("❌ Failed to parse conversations - unknown format")
                allConversations = []
            }
        } catch {
            print("Error loading conversations from database: \(error)")
            allConversations = []
        }
    }

    private func loadConversationFile(from url: URL) -> ConversationFile? {
        guard let data = try? String(contentsOf: url),
              let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let modifiedDate = attributes[.modificationDate] as? Date else {
            return nil
        }

        let lines = data.components(separatedBy: .newlines).filter { !$0.isEmpty }
        let messageCount = lines.count

        // Get preview and personality from first message
        var preview = "Empty conversation"
        var personalityEmoji: String?
        var personalityName: String?

        if let firstLine = lines.first,
           let json = try? JSONSerialization.jsonObject(with: firstLine.data(using: .utf8)!) as? [String: Any] {
            if let userMessage = json["user"] as? String {
                preview = String(userMessage.prefix(60)) + (userMessage.count > 60 ? "..." : "")
            }
            personalityEmoji = json["personality_emoji"] as? String
            personalityName = json["personality"] as? String
        }

        return ConversationFile(
            id: url.lastPathComponent,
            filename: url.lastPathComponent,
            path: url,
            messageCount: messageCount,
            lastModified: modifiedDate,
            preview: preview,
            personalityEmoji: personalityEmoji,
            personalityName: personalityName
        )
    }

    func selectConversation(_ conversation: ConversationFile) async {
        selectedConversation = conversation

        var loadedMessages: [ChatMessage] = []

        // Check if conversation has messages from database or needs to load from file
        if let conversationMessages = conversation.messages {
            // Load from database messages
            for messageDict in conversationMessages {
                guard let user = messageDict["user"] as? String,
                      let timestampString = messageDict["timestamp"] as? String else {
                    continue
                }

                // Try both "moxie" and "alex" field names for backward compatibility
                let moxieResponse = messageDict["moxie"] as? String ?? messageDict["alex"] as? String
                guard let moxieMessage = moxieResponse else {
                    continue
                }

                // Parse timestamp
                let timestamp: Date
                if let isoDate = ISO8601DateFormatter().date(from: timestampString) {
                    timestamp = isoDate
                } else {
                    timestamp = Date()
                }

                // Add user message
                let userMessage = ChatMessage(
                    role: "user",
                    content: user,
                    timestamp: timestamp
                )
                loadedMessages.append(userMessage)

                // Add assistant message
                let assistantMessage = ChatMessage(
                    role: "assistant",
                    content: moxieMessage,
                    timestamp: timestamp.addingTimeInterval(1)
                )
                loadedMessages.append(assistantMessage)
            }
        } else if let path = conversation.path {
            // Load from file (legacy support)
            guard let data = try? String(contentsOf: path),
                  !data.isEmpty else {
                messages = []
                return
            }

            let lines = data.components(separatedBy: .newlines).filter { !$0.isEmpty }

            for line in lines {
                guard let jsonData = line.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                      let user = json["user"] as? String,
                      let alex = json["alex"] as? String,
                      let timestampString = json["timestamp"] as? String else {
                    continue
                }

                // Parse timestamp
                let timestamp: Date
                if let isoDate = ISO8601DateFormatter().date(from: timestampString) {
                    timestamp = isoDate
                } else {
                    timestamp = Date()
                }

                // Add user message
                let userMessage = ChatMessage(
                    role: "user",
                    content: user,
                    timestamp: timestamp
                )
                loadedMessages.append(userMessage)

                // Add assistant message
                let assistantMessage = ChatMessage(
                    role: "assistant",
                    content: alex,
                    timestamp: timestamp.addingTimeInterval(1)
                )
                loadedMessages.append(assistantMessage)
            }
        }

        messages = loadedMessages
    }

    // MARK: - Send Message
    func sendMessage(_ text: String) async {
        guard let conversation = selectedConversation else { return }

        isSendingMessage = true

        // Add user message immediately
        let userMessage = ChatMessage(role: "user", content: text, timestamp: Date())
        messages.append(userMessage)

        do {
            // Get response from AI
            let response = try await sendToMoxie(message: text, conversation: conversation)

            // Add assistant message
            let assistantMessage = ChatMessage(role: "assistant", content: response, timestamp: Date())
            messages.append(assistantMessage)

            // Save to conversation file
            await saveMessageToFile(userMessage: text, assistantMessage: response, conversation: conversation)

            // Extract knowledge from conversation
            knowledgeGraphService.extractKnowledge(from: text, assistantMessage: response, conversationId: conversation.id)

            // Reload conversation to update message count
            await loadAllConversations()
        } catch {
            print("Error sending message: \(error)")
        }

        isSendingMessage = false
    }

    private func saveMessageToFile(userMessage: String, assistantMessage: String, conversation: ConversationFile) async {
        let timestamp = ISO8601DateFormatter().string(from: Date())

        let entry: [String: Any] = [
            "user": userMessage,
            "alex": assistantMessage,
            "timestamp": timestamp,
            "personality": conversation.personalityName ?? "Unknown",
            "personality_emoji": conversation.personalityEmoji ?? "💬"
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: entry),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }

        // Append to file (legacy support for file-based conversations)
        if let path = conversation.path, let fileHandle = try? FileHandle(forWritingTo: path) {
            defer { fileHandle.closeFile() }
            fileHandle.seekToEndOfFile()
            if let data = (jsonString + "\n").data(using: .utf8) {
                fileHandle.write(data)
            }
        }

        // TODO: Also save to database for database-based conversations
    }

    private func sendToMoxie(message: String, conversation: ConversationFile) async throws -> String {
        // Get knowledge context
        let knowledgeContext = knowledgeGraphService.getContext(for: conversation.id, limit: 5)
        let personalContext = knowledgeGraphService.getPersonalContext()

        // Build enhanced prompt with context
        var enhancedPrompt = message
        if !personalContext.isEmpty {
            enhancedPrompt = personalContext + "\n\nUser: " + message
        }

        // Make API call to Moxie brain
        guard let url = URL(string: "\(AppConfig.moxieAPIBaseURL)/generate_text") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "prompt": enhancedPrompt,
            "personality": conversation.personalityName ?? "Default",
            "max_tokens": 500,
            "context": knowledgeContext
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let text = json["generated_text"] as? String else {
            throw URLError(.cannotParseResponse)
        }

        return text
    }
}

// MARK: - Personality Folder Header
struct PersonalityFolderHeader: View {
    let personality: String
    let emoji: String
    let count: Int
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 8) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(emoji)
                    .font(.body)

                Text(personality)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Memory Extraction Sheet

struct MemoryExtractionSheet: View {
    @ObservedObject var viewModel: MemoryViewModel
    let conversations: [ConversationFile]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.purple)

                    Text("Memory Extraction")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Extract structured memories from \(conversations.count) conversations")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)

                Divider()

                // Status Section
                VStack(spacing: 16) {
                    if viewModel.isExtracting {
                        // Progress indicator
                        VStack(spacing: 12) {
                            ProgressView(value: viewModel.extractionProgress)
                                .progressViewStyle(.linear)

                            Text(viewModel.extractionStatus)
                                .font(.body)
                                .foregroundColor(.secondary)

                            Text("\(viewModel.totalMemoriesExtracted) memories extracted")
                                .font(.caption)
                                .foregroundColor(.purple)
                        }
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(12)
                    } else if viewModel.totalMemoriesExtracted > 0 {
                        // Completed state
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title2)
                                Text("Extraction Complete")
                                    .font(.headline)
                            }

                            Text("\(viewModel.totalMemoriesExtracted) total memories")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            if let cortex = viewModel.frontalCortex {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Frontal Cortex Summary:")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)

                                    HStack {
                                        Label("\(cortex.interests.count) interests", systemImage: "star.fill")
                                        Spacer()
                                        Label("\(cortex.goals.count) goals", systemImage: "target")
                                    }
                                    .font(.caption)

                                    HStack {
                                        Label("\(cortex.skills.count) skills", systemImage: "hand.raised.fill")
                                        Spacer()
                                        Label("\(cortex.relationships.count) relationships", systemImage: "person.2.fill")
                                    }
                                    .font(.caption)
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    } else {
                        // Ready state
                        VStack(spacing: 12) {
                            Image(systemName: "brain")
                                .font(.system(size: 40))
                                .foregroundColor(.purple)

                            Text("Ready to extract memories")
                                .font(.headline)

                            Text("This will analyze all conversations and extract:\n• Facts and preferences\n• Emotions and goals\n• Relationships and skills\n• Topics and entities")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(12)
                    }

                    // Error message
                    if let error = viewModel.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                // Action Buttons
                VStack(spacing: 12) {
                    if !viewModel.isExtracting {
                        Button(action: {
                            Task {
                                await viewModel.extractMemoriesFromConversations(conversations)
                            }
                        }) {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                Text(viewModel.totalMemoriesExtracted > 0 ? "Re-Extract Memories" : "Start Extraction")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .disabled(conversations.isEmpty)
                    }

                    Button(action: { dismiss() }) {
                        Text("Close")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Memory Extraction")
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}
