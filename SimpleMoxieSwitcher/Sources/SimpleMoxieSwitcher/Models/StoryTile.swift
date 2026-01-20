import Foundation

struct StoryTile: Codable, Identifiable, Equatable {
    var id: String { title }
    let title: String  // Story title (e.g., "The Dragon's Quest", "Space Adventure")
    let genre: String
    let authorStyle: String
    let readingLevel: String
    let sessionFilePath: String  // Path to the saved story JSON
    let emoji: String
    let createdAt: Date

    init(title: String, genre: String, authorStyle: String, readingLevel: String, sessionFilePath: String, emoji: String = "📚", createdAt: Date = Date()) {
        self.title = title
        self.genre = genre
        self.authorStyle = authorStyle
        self.readingLevel = readingLevel
        self.sessionFilePath = sessionFilePath
        self.emoji = emoji
        self.createdAt = createdAt
    }
}
