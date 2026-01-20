import Foundation

// MARK: - Knowledge Quest RPG Models

/// Represents a knowledge-based RPG adventure with Moxie as Game Master
struct KnowledgeQuest: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let theme: QuestTheme
    let difficulty: Difficulty
    var chapters: [Chapter]
    var currentChapterIndex: Int
    var playerStats: PlayerStats
    var inventory: [String]
    var isCompleted: Bool
    let createdAt: Date

    enum QuestTheme: String, Codable, CaseIterable {
        case science = "Science Adventure"
        case history = "Historical Journey"
        case math = "Mathematical Mystery"
        case geography = "World Explorer"
        case literature = "Story Realm"
        case nature = "Nature Quest"
        case space = "Space Odyssey"
        case ocean = "Ocean Depths"

        var icon: String {
            switch self {
            case .science: return "🔬"
            case .history: return "🏛️"
            case .math: return "🔢"
            case .geography: return "🗺️"
            case .literature: return "📖"
            case .nature: return "🌳"
            case .space: return "🚀"
            case .ocean: return "🌊"
            }
        }

        var backgroundDescription: String {
            switch self {
            case .science:
                return "Dr. Moxie needs your help in the Science Lab to solve mysterious experiments!"
            case .history:
                return "Travel through time with Moxie to uncover historical secrets!"
            case .math:
                return "Help Detective Moxie solve mathematical puzzles to crack the case!"
            case .geography:
                return "Explore the world with Explorer Moxie and discover new lands!"
            case .literature:
                return "Journey through magical story worlds with Librarian Moxie!"
            case .nature:
                return "Join Ranger Moxie on an adventure through the wilderness!"
            case .space:
                return "Blast off with Astronaut Moxie to explore the cosmos!"
            case .ocean:
                return "Dive deep with Captain Moxie to discover ocean mysteries!"
            }
        }
    }

    enum Difficulty: String, Codable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
        case expert = "Expert"

        var skillCheckDifficulty: Int {
            switch self {
            case .easy: return 5
            case .medium: return 10
            case .hard: return 15
            case .expert: return 20
            }
        }
    }

    init(title: String, theme: QuestTheme, difficulty: Difficulty) {
        self.id = UUID().uuidString
        self.title = title
        self.description = theme.backgroundDescription
        self.theme = theme
        self.difficulty = difficulty
        self.chapters = []
        self.currentChapterIndex = 0
        self.playerStats = PlayerStats()
        self.inventory = []
        self.isCompleted = false
        self.createdAt = Date()
    }

    var currentChapter: Chapter? {
        guard currentChapterIndex < chapters.count else { return nil }
        return chapters[currentChapterIndex]
    }

    var progress: Double {
        guard !chapters.isEmpty else { return 0 }
        return Double(currentChapterIndex) / Double(chapters.count)
    }
}

// MARK: - Chapter

struct Chapter: Identifiable, Codable {
    let id: String
    let title: String
    let storyText: String
    let location: String
    var encounters: [Encounter]
    var currentEncounterIndex: Int
    var isCompleted: Bool

    init(title: String, storyText: String, location: String) {
        self.id = UUID().uuidString
        self.title = title
        self.storyText = storyText
        self.location = location
        self.encounters = []
        self.currentEncounterIndex = 0
        self.isCompleted = false
    }

    var currentEncounter: Encounter? {
        guard currentEncounterIndex < encounters.count else { return nil }
        return encounters[currentEncounterIndex]
    }
}

// MARK: - Encounter

struct Encounter: Identifiable, Codable {
    let id: String
    let type: EncounterType
    let description: String
    var challenge: Challenge
    var isCompleted: Bool
    var wasSuccessful: Bool?

    enum EncounterType: String, Codable {
        case obstacle = "Obstacle"
        case puzzle = "Puzzle"
        case riddle = "Riddle"
        case discovery = "Discovery"
        case conversation = "Conversation"

        var icon: String {
            switch self {
            case .obstacle: return "⚡"
            case .puzzle: return "🧩"
            case .riddle: return "❓"
            case .discovery: return "💎"
            case .conversation: return "💬"
            }
        }
    }

    init(type: EncounterType, description: String, challenge: Challenge) {
        self.id = UUID().uuidString
        self.type = type
        self.description = description
        self.challenge = challenge
        self.isCompleted = false
    }
}

// MARK: - Challenge

struct Challenge: Codable {
    let question: String
    let knowledgeArea: String  // e.g., "Science", "Math", "History"
    let skillRequired: String   // e.g., "Memory", "Logic", "Calculation"
    let options: [String]
    let correctAnswer: Int
    let successOutcome: String
    let failureOutcome: String
    let hint: String?
    var userAnswer: Int?

    var isCorrect: Bool? {
        guard let answer = userAnswer else { return nil }
        return answer == correctAnswer
    }

    var experienceReward: Int {
        return isCorrect == true ? 50 : 10  // More XP for success
    }
}

// MARK: - Player Stats

struct PlayerStats: Codable {
    var level: Int
    var experience: Int
    var health: Int
    var maxHealth: Int
    var knowledge: Int  // Intelligence stat
    var wisdom: Int     // Problem-solving stat
    var creativity: Int // Creative thinking stat

    init() {
        self.level = 1
        self.experience = 0
        self.health = 100
        self.maxHealth = 100
        self.knowledge = 10
        self.wisdom = 10
        self.creativity = 10
    }

    var experienceToNextLevel: Int {
        return level * 100
    }

    mutating func gainExperience(_ amount: Int) {
        experience += amount
        checkLevelUp()
    }

    mutating func checkLevelUp() {
        while experience >= experienceToNextLevel {
            levelUp()
        }
    }

    mutating func levelUp() {
        level += 1
        maxHealth += 20
        health = maxHealth
        knowledge += 2
        wisdom += 2
        creativity += 2
    }

    mutating func takeDamage(_ amount: Int) {
        health = max(0, health - amount)
    }

    mutating func heal(_ amount: Int) {
        health = min(maxHealth, health + amount)
    }
}

// MARK: - Quest Progress

struct QuestProgress: Codable {
    var totalQuestsCompleted: Int
    var totalChallengesCompleted: Int
    var totalExperienceEarned: Int
    var highestLevel: Int
    var knowledgeAreasExplored: Set<String>
    var achievements: [QuestAchievement]

    init() {
        self.totalQuestsCompleted = 0
        self.totalChallengesCompleted = 0
        self.totalExperienceEarned = 0
        self.highestLevel = 1
        self.knowledgeAreasExplored = []
        self.achievements = []
    }

    mutating func recordQuestCompletion(quest: KnowledgeQuest) {
        totalQuestsCompleted += 1
        highestLevel = max(highestLevel, quest.playerStats.level)
        totalExperienceEarned += quest.playerStats.experience

        // Track knowledge areas
        for chapter in quest.chapters {
            for encounter in chapter.encounters {
                knowledgeAreasExplored.insert(encounter.challenge.knowledgeArea)
            }
        }

        checkAchievements()
    }

    mutating func checkAchievements() {
        if totalQuestsCompleted == 1 && !hasAchievement("first_quest") {
            achievements.append(QuestAchievement(
                id: "first_quest",
                title: "Adventurer",
                description: "Completed your first Knowledge Quest!",
                icon: "🗡️"
            ))
        }

        if totalQuestsCompleted >= 5 && !hasAchievement("veteran") {
            achievements.append(QuestAchievement(
                id: "veteran",
                title: "Veteran Quester",
                description: "Completed 5 Knowledge Quests!",
                icon: "🏆"
            ))
        }

        if knowledgeAreasExplored.count >= 5 && !hasAchievement("scholar") {
            achievements.append(QuestAchievement(
                id: "scholar",
                title: "Scholar",
                description: "Explored 5 different knowledge areas!",
                icon: "📚"
            ))
        }

        if highestLevel >= 5 && !hasAchievement("master") {
            achievements.append(QuestAchievement(
                id: "master",
                title: "Knowledge Master",
                description: "Reached level 5!",
                icon: "🌟"
            ))
        }
    }

    private func hasAchievement(_ id: String) -> Bool {
        achievements.contains(where: { $0.id == id })
    }
}

struct QuestAchievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let unlockedAt: Date

    init(id: String, title: String, description: String, icon: String) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.unlockedAt = Date()
    }
}

// MARK: - Quest Generator Helper

struct QuestTemplate {
    let theme: KnowledgeQuest.QuestTheme
    let chapterTitles: [String]
    let locations: [String]
    let encounterTypes: [Encounter.EncounterType]

    static func template(for theme: KnowledgeQuest.QuestTheme) -> QuestTemplate {
        switch theme {
        case .science:
            return QuestTemplate(
                theme: .science,
                chapterTitles: ["The Mysterious Lab", "Chemical Reactions", "The Final Experiment"],
                locations: ["Science Laboratory", "Testing Chamber", "Research Library"],
                encounterTypes: [.puzzle, .discovery, .obstacle]
            )
        case .history:
            return QuestTemplate(
                theme: .history,
                chapterTitles: ["Ancient Civilizations", "Medieval Times", "Modern Era"],
                locations: ["Ancient Temple", "Castle Keep", "Modern Museum"],
                encounterTypes: [.conversation, .riddle, .discovery]
            )
        case .math:
            return QuestTemplate(
                theme: .math,
                chapterTitles: ["Number Mystery", "Geometric Patterns", "The Final Equation"],
                locations: ["Number Kingdom", "Shape Valley", "Equation Tower"],
                encounterTypes: [.puzzle, .obstacle, .riddle]
            )
        case .geography:
            return QuestTemplate(
                theme: .geography,
                chapterTitles: ["Continental Journey", "Island Discovery", "Mountain Peak"],
                locations: ["World Map Room", "Tropical Island", "Summit Vista"],
                encounterTypes: [.discovery, .conversation, .puzzle]
            )
        case .literature:
            return QuestTemplate(
                theme: .literature,
                chapterTitles: ["Story Beginning", "Plot Twist", "Grand Finale"],
                locations: ["Enchanted Library", "Story Forest", "Chapter Castle"],
                encounterTypes: [.riddle, .conversation, .discovery]
            )
        case .nature:
            return QuestTemplate(
                theme: .nature,
                chapterTitles: ["Forest Entrance", "Wildlife Wonder", "Nature's Balance"],
                locations: ["Dense Forest", "Animal Haven", "Ecosystem Peak"],
                encounterTypes: [.discovery, .puzzle, .conversation]
            )
        case .space:
            return QuestTemplate(
                theme: .space,
                chapterTitles: ["Launch Sequence", "Orbit Adventure", "Stellar Discovery"],
                locations: ["Space Station", "Asteroid Field", "Distant Planet"],
                encounterTypes: [.puzzle, .discovery, .obstacle]
            )
        case .ocean:
            return QuestTemplate(
                theme: .ocean,
                chapterTitles: ["Shallow Waters", "Deep Dive", "Ocean Floor"],
                locations: ["Coral Reef", "Kelp Forest", "Trench Depths"],
                encounterTypes: [.discovery, .conversation, .puzzle]
            )
        }
    }
}
