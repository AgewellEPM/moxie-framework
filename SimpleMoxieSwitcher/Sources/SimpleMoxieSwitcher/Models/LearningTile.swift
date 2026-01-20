import Foundation

struct LearningTile: Codable, Identifiable, Equatable {
    var id: String { title }
    let title: String  // Subject/Matter (e.g., "Math", "Python Programming")
    let bookTitle: String  // Reading book title
    let subject: String
    let gradeLevel: String
    let difficulty: String
    let sessionFilePath: String  // Path to the saved session JSON
    let emoji: String
    let createdAt: Date

    init(title: String, bookTitle: String, subject: String, gradeLevel: String, difficulty: String, sessionFilePath: String, emoji: String = "🎓", createdAt: Date = Date()) {
        self.title = title
        self.bookTitle = bookTitle
        self.subject = subject
        self.gradeLevel = gradeLevel
        self.difficulty = difficulty
        self.sessionFilePath = sessionFilePath
        self.emoji = emoji
        self.createdAt = createdAt
    }
}
