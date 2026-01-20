import Foundation

struct ChatMessage: Codable, Identifiable {
    var id = UUID()
    let role: String  // "user" or "assistant"
    let content: String
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case role, content, timestamp
    }

    var isUser: Bool {
        role == "user"
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

struct Conversation: Codable, Identifiable {
    var id = UUID()
    let title: String
    let personality: String
    let personalityEmoji: String
    let messages: [ChatMessage]
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case title, personality, personalityEmoji, messages, createdAt, updatedAt
    }

    var date: Date {
        updatedAt
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: updatedAt)
    }
}