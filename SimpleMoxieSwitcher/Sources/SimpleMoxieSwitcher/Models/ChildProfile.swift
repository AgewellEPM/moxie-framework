import Foundation

struct ChildProfile: Codable, Identifiable {
    let id: UUID
    var name: String
    var birthday: Date?
    var interests: [String]
    var personalGoals: [String]
    var thingsToRemember: String
    var photoData: Data? // Optional profile photo
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        birthday: Date? = nil,
        interests: [String] = [],
        personalGoals: [String] = [],
        thingsToRemember: String = "",
        photoData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.birthday = birthday
        self.interests = interests
        self.personalGoals = personalGoals
        self.thingsToRemember = thingsToRemember
        self.photoData = photoData
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var age: Int? {
        guard let birthday = birthday else { return nil }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthday, to: Date())
        return ageComponents.year
    }

    var birthdayString: String {
        guard let birthday = birthday else { return "Not set" }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: birthday)
    }

    // Get profile context for AI conversations
    var contextForAI: String {
        var context = "Child's Profile:\n"
        context += "- Name: \(name)\n"

        if let age = age {
            context += "- Age: \(age) years old\n"
        }

        if !interests.isEmpty {
            context += "- Interests: \(interests.joined(separator: ", "))\n"
        }

        if !personalGoals.isEmpty {
            context += "- Goals: \(personalGoals.joined(separator: ", "))\n"
        }

        if !thingsToRemember.isEmpty {
            context += "- Important to remember: \(thingsToRemember)\n"
        }

        return context
    }
}
