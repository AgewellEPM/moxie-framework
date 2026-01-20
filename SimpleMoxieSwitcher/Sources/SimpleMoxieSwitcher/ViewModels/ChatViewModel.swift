import SwiftUI
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var conversationHistory: [ConversationFile] = []
    @Published var currentConversationFile: ConversationFile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentConversationId = UUID()

    let personality: Personality
    private let conversationsDir = AppPaths.conversations
    private var pollingTimer: Timer?
    private let aiService: AIServiceProtocol
    private let usageRepository: UsageRepositoryProtocol
    private let childProfileService: ChildProfileService
    private let memoryStorageService: MemoryStorageService
    private let memoryWindowSize = 20 // Last 20 messages for context

    init(personality: Personality,
         aiService: AIServiceProtocol? = nil,
         usageRepository: UsageRepositoryProtocol? = nil,
         childProfileService: ChildProfileService? = nil,
         memoryStorageService: MemoryStorageService? = nil) {
        self.personality = personality
        self.aiService = aiService ?? AIService()
        self.usageRepository = usageRepository ?? UsageRepository()
        self.childProfileService = childProfileService ?? DIContainer.shared.resolve(ChildProfileService.self)
        self.memoryStorageService = memoryStorageService ?? DIContainer.shared.resolve(MemoryStorageService.self)

        // Load child profile on init
        Task {
            try? await self.childProfileService.loadProfile()
        }
    }

    // MARK: - Load Conversation History
    func loadConversationHistory() async {
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: conversationsDir, withIntermediateDirectories: true)

        guard FileManager.default.fileExists(atPath: conversationsDir.path) else {
            conversationHistory = []
            return
        }

        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: conversationsDir,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )

            var loadedConversations: [ConversationFile] = []

            for file in files where file.pathExtension == "jsonl" {
                if let conversation = loadConversationFile(from: file) {
                    loadedConversations.append(conversation)
                }
            }

            // Sort by last modified (newest first)
            loadedConversations.sort { $0.lastModified > $1.lastModified }

            conversationHistory = loadedConversations
        } catch {
            print("Error loading conversations: \(error)")
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

        // Get preview from first user message
        var preview = "Empty conversation"
        if let firstLine = lines.first,
           let json = try? JSONSerialization.jsonObject(with: firstLine.data(using: .utf8)!) as? [String: Any],
           let userMessage = json["user"] as? String {
            preview = String(userMessage.prefix(60)) + (userMessage.count > 60 ? "..." : "")
        }

        return ConversationFile(
            id: url.lastPathComponent,
            filename: url.lastPathComponent,
            path: url,
            messageCount: messageCount,
            lastModified: modifiedDate,
            preview: preview
        )
    }

    // MARK: - Load Current Conversation
    func loadCurrentConversation() async {
        let filename = "moxie_\(personality.name.lowercased().replacingOccurrences(of: " ", with: "_"))_current.jsonl"
        let fileURL = conversationsDir.appendingPathComponent(filename)

        // Create file if it doesn't exist
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            try? "".write(to: fileURL, atomically: true, encoding: .utf8)
        }

        // Load the conversation
        if let conversationFile = loadConversationFile(from: fileURL) {
            await loadConversation(conversationFile)
        }

        // Start polling for updates (for voice conversations)
        startPolling()
    }

    // MARK: - Load Specific Conversation
    func loadConversation(_ conversation: ConversationFile) async {
        currentConversationFile = conversation

        guard let path = conversation.path,
              let data = try? String(contentsOf: path),
              !data.isEmpty else {
            messages = []
            return
        }

        let lines = data.components(separatedBy: .newlines).filter { !$0.isEmpty }
        var loadedMessages: [ChatMessage] = []

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

        messages = loadedMessages
    }

    // MARK: - Start New Conversation
    func startNewConversation() async {
        let timestamp = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let dateString = formatter.string(from: timestamp)

        let filename = "moxie_\(personality.name.lowercased().replacingOccurrences(of: " ", with: "_"))_\(dateString).jsonl"
        let fileURL = conversationsDir.appendingPathComponent(filename)

        // Create empty file
        try? "".write(to: fileURL, atomically: true, encoding: .utf8)

        // Generate new conversation ID for tracking
        currentConversationId = UUID()

        // Load it
        if let conversationFile = loadConversationFile(from: fileURL) {
            await loadConversation(conversationFile)
        }

        await loadConversationHistory()
    }

    // MARK: - Send Message
    func sendMessage(_ text: String, featureType: FeatureType = .conversation) async {
        guard let currentFile = currentConversationFile else { return }

        // Get current mode
        let currentMode = ModeContext.shared.currentMode

        // Filter content in child mode
        if currentMode == .child {
            let category = ContentFilterService.evaluateChildModeRequest(text)

            switch category {
            case .blocked:
                // Add user message
                let userMessage = ChatMessage(role: "user", content: text, timestamp: Date())
                messages.append(userMessage)

                // Add blocked response
                let blockedResponse = ContentFilterService.childModeBlockedResponse(originalMessage: text)
                let assistantMessage = ChatMessage(role: "assistant", content: blockedResponse, timestamp: Date())
                messages.append(assistantMessage)

                // Save to file
                if let filePath = currentFile.path {
                    await saveMessageToFile(user: text, assistant: blockedResponse, file: filePath)
                }

                // Log the blocked content for parent review
                logBlockedContent(message: text, category: "blocked")
                return

            case .requiresParent:
                // Add user message
                let userMessage = ChatMessage(role: "user", content: text, timestamp: Date())
                messages.append(userMessage)

                // Add redirect response
                let redirectResponse = ContentFilterService.childModeParentRequiredResponse(originalMessage: text)
                let assistantMessage = ChatMessage(role: "assistant", content: redirectResponse, timestamp: Date())
                messages.append(assistantMessage)

                // Save to file and notify parent
                if let filePath = currentFile.path {
                    await saveMessageToFile(user: text, assistant: redirectResponse, file: filePath)
                }

                // Create parent notification
                createParentNotification(message: text, category: "parent_required")
                return

            case .safe:
                // Continue with normal flow
                break
            }

            // Check for concerning content
            let concernCheck = ContentFilterService.detectConcerningContent(text)
            if concernCheck.isConcerning, let concernCategory = concernCheck.category {
                // Flag for parent review but continue conversation
                createConcernFlag(message: text, category: concernCategory)
            }
        }

        // Add user message to UI
        let userMessage = ChatMessage(
            role: "user",
            content: text,
            timestamp: Date()
        )
        messages.append(userMessage)

        isLoading = true
        errorMessage = nil

        do {
            // Get conversation history window (last N messages for context)
            let recentMessages = Array(getConversationMemoryWindow())

            // Generate memory context from past conversations
            let memoryContext = await generateMemoryContext(for: text)

            // Prepend memory context to the message if available
            var enhancedMessage = text
            if !memoryContext.isEmpty {
                enhancedMessage = memoryContext + "\n\n---\n\nUser: " + text
                print("🧠 Memory context added to AI prompt (\(memoryContext.count) chars)")
            }

            // Send to AI provider with usage tracking
            // Note: Child profile context is automatically included via PersonalityShiftService
            let response = try await aiService.sendMessage(
                enhancedMessage,
                personality: personality,
                featureType: featureType,
                conversationHistory: recentMessages
            )

            // Sanitize response for child mode
            let sanitizedContent = ContentFilterService.sanitizeResponse(
                response.content,
                mode: currentMode
            )

            // Add assistant response
            let assistantMessage = ChatMessage(
                role: "assistant",
                content: sanitizedContent,
                timestamp: Date()
            )
            messages.append(assistantMessage)

            // Save to JSONL file
            if let filePath = currentFile.path {
                await saveMessageToFile(user: text, assistant: sanitizedContent, file: filePath)
            }

            // Extract interests from conversation
            try? await childProfileService.extractAndAddInterests(from: "\(text) \(sanitizedContent)")

            // Log additional usage info if needed
            print("API Response - Model: \(response.model), Tokens: \(response.totalTokens), Time: \(response.responseTime)s")

        } catch {
            errorMessage = "Failed to send message: \(error.localizedDescription)"
            // Remove the user message if sending failed
            if let index = messages.firstIndex(where: { $0.id == userMessage.id }) {
                messages.remove(at: index)
            }
        }

        isLoading = false
    }

    // MARK: - Safety Logging Methods

    private func logBlockedContent(message: String, category: String) {
        // Log blocked content for parent review
        print("⚠️ Content blocked in child mode: \(category)")
        // In production, this would save to a parent-accessible log
    }

    private func createParentNotification(message: String, category: String) {
        // Create notification for parent review
        let notification = ParentNotification(
            timestamp: Date(),
            childMessage: message,
            category: category,
            moxieResponse: ContentFilterService.childModeParentRequiredResponse(originalMessage: message),
            severity: .low
        )

        // In production, this would save to a notification queue
        print("📢 Parent notification created: \(notification.category)")
    }

    private func createConcernFlag(message: String, category: ConcernCategory) {
        // Flag concerning content for parent review
        let severity: ParentNotification.SeverityLevel = {
            switch category {
            case .safetyRisk: return .high
            case .emotionalDistress: return .medium
            case .bullyingIndicator: return .medium
            case .socialIsolation: return .low
            }
        }()

        let notification = ParentNotification(
            timestamp: Date(),
            childMessage: message,
            category: category.rawValue,
            moxieResponse: ContentFilterService.generateConcernResponse(category: category),
            severity: severity
        )

        // In production, this would save to a priority notification queue
        print("🚨 Concern flagged: \(category.rawValue) - Severity: \(severity.rawValue)")
        // Log the notification ID for tracking
        print("   Notification ID: \(notification.id)")
    }

    private func saveMessageToFile(user: String, assistant: String, file: URL) async {
        let entry: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "user": user,
            "alex": assistant,
            "personality": personality.name,
            "personality_emoji": personality.emoji
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: entry)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""

            // Append to file
            if FileManager.default.fileExists(atPath: file.path) {
                let fileHandle = try FileHandle(forWritingTo: file)
                fileHandle.seekToEndOfFile()
                fileHandle.write((jsonString + "\n").data(using: .utf8) ?? Data())
                fileHandle.closeFile()
            } else {
                try (jsonString + "\n").write(to: file, atomically: true, encoding: .utf8)
            }

            // Reload conversation history
            await loadConversationHistory()
        } catch {
            print("Failed to save message: \(error)")
        }
    }


    // MARK: - Auto-reload for Voice Conversations
    private func startPolling() {
        // Poll every 2 seconds to check for new messages from voice conversations
        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, let currentFile = self.currentConversationFile else { return }
                // Reload the current conversation to pick up voice messages
                await self.loadConversation(currentFile)
            }
        }
    }

    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    // MARK: - Conversation Memory Window

    /// Get the most recent N messages for AI context
    private func getConversationMemoryWindow() -> ArraySlice<ChatMessage> {
        // Don't include the last message (the one we just added)
        let messagesToConsider = messages.dropLast()

        // Return last N messages
        if messagesToConsider.count > memoryWindowSize {
            return messagesToConsider.suffix(memoryWindowSize)
        } else {
            return messagesToConsider[messagesToConsider.startIndex...]
        }
    }

    // MARK: - Memory Context Generation

    /// Generate memory context from past conversations
    private func generateMemoryContext(for message: String) async -> String {
        // Extract keywords from user message for memory retrieval
        let keywords = extractKeywords(from: message)

        do {
            // Load frontal cortex (consolidated knowledge)
            if let cortex = try await memoryStorageService.loadFrontalCortex() {
                let cortexContext = cortex.generateContextForAI()

                // Load relevant memories based on keywords
                let memoryContext = try await memoryStorageService.generateContextForAI(
                    keywords: keywords,
                    limit: 5
                )

                // Combine contexts
                if !cortexContext.isEmpty && !memoryContext.isEmpty {
                    return cortexContext + "\n\n" + memoryContext
                } else if !cortexContext.isEmpty {
                    return cortexContext
                } else {
                    return memoryContext
                }
            }

            return ""
        } catch {
            print("⚠️ Failed to generate memory context: \(error)")
            return ""
        }
    }

    /// Extract keywords from user message for memory retrieval
    private func extractKeywords(from text: String) -> [String] {
        // Simple keyword extraction (in production, use NLP)
        let stopWords = Set(["the", "a", "an", "is", "are", "was", "were", "to", "of", "and", "or", "but", "in", "on", "at", "by", "for", "with", "about", "as", "from", "i", "you", "me", "my", "your"])

        let words = text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !stopWords.contains($0) && $0.count > 2 }

        // Return top 5 most significant words
        return Array(words.prefix(5))
    }

    deinit {
        pollingTimer?.invalidate()
    }
}

