import Foundation

// MARK: - Conversation Repository Protocol
protocol ConversationRepositoryProtocol {
    func loadConversations() async throws -> [Conversation]
    func saveConversation(_ conversation: Conversation) async throws
    func deleteConversation(_ conversation: Conversation) async throws
    func clearAllConversations() async throws
}

// MARK: - Conversation Repository Implementation
class ConversationRepository: ConversationRepositoryProtocol {
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory,
                                                              in: .userDomainMask).first!
    private var conversationsFile: URL {
        documentsDirectory.appendingPathComponent("MoxieConversations.json")
    }

    func loadConversations() async throws -> [Conversation] {
        guard FileManager.default.fileExists(atPath: conversationsFile.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: conversationsFile)
            let conversations = try JSONDecoder().decode([Conversation].self, from: data)
            return conversations.sorted { first, second in
                first.date > second.date
            }
        } catch {
            print("Error loading conversations: \(error)")
            return []
        }
    }

    func saveConversation(_ conversation: Conversation) async throws {
        var conversations = try await loadConversations()

        // Remove existing conversation if it exists
        conversations.removeAll { $0.id == conversation.id }

        // Add the updated conversation
        conversations.append(conversation)

        // Save back to file
        let data = try JSONEncoder().encode(conversations)
        try data.write(to: conversationsFile)
    }

    func deleteConversation(_ conversation: Conversation) async throws {
        var conversations = try await loadConversations()
        conversations.removeAll { $0.id == conversation.id }

        let data = try JSONEncoder().encode(conversations)
        try data.write(to: conversationsFile)
    }

    func clearAllConversations() async throws {
        try FileManager.default.removeItem(at: conversationsFile)
    }
}