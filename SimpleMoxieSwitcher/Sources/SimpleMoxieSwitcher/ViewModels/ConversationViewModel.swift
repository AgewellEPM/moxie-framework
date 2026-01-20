import SwiftUI
import Combine

@MainActor
class ConversationViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentSessionState: SessionState = SessionState()
    @Published var redirectionSuggestion: String?

    private let conversationService: ConversationServiceProtocol
    private let conversationRepository: ConversationRepositoryProtocol
    private let intentDetectionService: IntentDetectionServiceProtocol

    init(
        conversationService: ConversationServiceProtocol,
        conversationRepository: ConversationRepositoryProtocol,
        intentDetectionService: IntentDetectionServiceProtocol
    ) {
        self.conversationService = conversationService
        self.conversationRepository = conversationRepository
        self.intentDetectionService = intentDetectionService
    }

    func loadConversations() async {
        isLoading = true
        errorMessage = nil

        do {
            conversations = try await conversationRepository.loadConversations()
        } catch {
            errorMessage = "Failed to load conversations: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func deleteConversation(_ conversation: Conversation) async {
        do {
            try await conversationRepository.deleteConversation(conversation)
            await loadConversations()
        } catch {
            errorMessage = "Failed to delete conversation: \(error.localizedDescription)"
        }
    }

    func exportConversation(_ conversation: Conversation) {
        let exported = conversationService.exportConversation(conversation)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(exported, forType: .string)
    }

    func startNewConversation() {
        // Open browser chat to start new conversation
        if let url = URL(string: AppConfig.browserChatURL) {
            NSWorkspace.shared.open(url)
        }
    }

    func filterConversations(searchText: String) -> [Conversation] {
        if searchText.isEmpty {
            return conversations
        } else {
            return conversations.filter { conversation in
                conversation.title.localizedCaseInsensitiveContains(searchText) ||
                conversation.personality.localizedCaseInsensitiveContains(searchText) ||
                conversation.messages.contains { $0.content.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }

    // MARK: - Session Intent Detection

    func checkSessionIntent(for conversation: Conversation) {
        currentSessionState.incrementMessages()

        // Only check if it's time
        guard currentSessionState.shouldRecheckIntent else { return }

        let (detectedIntent, confidence) = intentDetectionService.detectIntent(from: conversation.messages)

        // Check for drift
        if currentSessionState.currentIntent != .unknown {
            let drift = intentDetectionService.detectDrift(
                currentIntent: currentSessionState.currentIntent,
                recentMessages: Array(conversation.messages.suffix(5))
            )

            currentSessionState.driftDetected = drift

            if drift {
                // Generate redirection suggestion
                redirectionSuggestion = intentDetectionService.generateRedirectionSuggestion(
                    from: currentSessionState.currentIntent,
                    to: detectedIntent
                )
            }
        }

        // Update intent
        currentSessionState.updateIntent(detectedIntent, confidence: confidence)
    }

    func acceptRedirection() {
        redirectionSuggestion = nil
        currentSessionState.driftDetected = false
    }

    func dismissRedirection() {
        redirectionSuggestion = nil
    }

    func startNewSession() {
        currentSessionState = SessionState()
        redirectionSuggestion = nil
    }
}