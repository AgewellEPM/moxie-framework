import Foundation

// MARK: - Conversation Service Protocol
protocol ConversationServiceProtocol {
    func loadConversations() async throws -> [Conversation]
    func saveConversation(_ conversation: Conversation) async throws
    func deleteConversation(_ conversation: Conversation) async throws
    func exportConversation(_ conversation: Conversation) -> String
}

// MARK: - Conversation Service Implementation
class ConversationService: ConversationServiceProtocol {
    func loadConversations() async throws -> [Conversation] {
        // In a real implementation, this would load from a database or API
        // For now, returning empty array
        return []
    }

    func saveConversation(_ conversation: Conversation) async throws {
        // In a real implementation, this would save to a database or API
    }

    func deleteConversation(_ conversation: Conversation) async throws {
        // In a real implementation, this would delete from a database or API
    }

    func exportConversation(_ conversation: Conversation) -> String {
        var export = "Conversation: \(conversation.title)\n"
        export += "Date: \(conversation.formattedDate)\n"
        export += "Personality: \(conversation.personality)\n"
        export += "Messages: \(conversation.messages.count)\n"
        export += "---\n\n"

        for message in conversation.messages {
            let sender = message.isUser ? "User" : "Moxie"
            export += "[\(message.formattedTime)] \(sender): \(message.content)\n\n"
        }

        return export
    }
}