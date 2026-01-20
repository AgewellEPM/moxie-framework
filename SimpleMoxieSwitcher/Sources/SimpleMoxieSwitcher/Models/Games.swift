import Foundation

// MARK: - Game Models

/// Represents a game session with scoring and progress
struct GameSession: Identifiable, Codable {
    let id: String
    let gameType: GameType
    let createdAt: Date
    var score: Int
    var questionsAnswered: Int
    var correctAnswers: Int
    var isCompleted: Bool

    enum GameType: String, Codable, CaseIterable {
        case knowledgeQuest = "Knowledge Quest RPG"
        case trivia = "Trivia Challenge"
        case spellingBee = "Spelling Bee"
        case movieLines = "Name That Movie Line"
        case videoGames = "Name That Video Game"

        var icon: String {
            switch self {
            case .knowledgeQuest: return "⚔️"
            case .trivia: return "🧠"
            case .spellingBee: return "✏️"
            case .movieLines: return "🎬"
            case .videoGames: return "🎮"
            }
        }

        var description: String {
            switch self {
            case .knowledgeQuest: return "Embark on an epic adventure where Moxie is your Game Master! Apply your knowledge to overcome challenges."
            case .trivia: return "Answer questions and score points! Moxie will quiz you on various topics."
            case .spellingBee: return "Spell words correctly to earn points!"
            case .movieLines: return "Can you identify the movie from a famous quote?"
            case .videoGames: return "Test your video game knowledge!"
            }
        }
    }

    init(gameType: GameType) {
        self.id = UUID().uuidString
        self.gameType = gameType
        self.createdAt = Date()
        self.score = 0
        self.questionsAnswered = 0
        self.correctAnswers = 0
        self.isCompleted = false
    }

    var accuracy: Double {
        guard questionsAnswered > 0 else { return 0 }
        return Double(correctAnswers) / Double(questionsAnswered)
    }
}

// MARK: - Trivia Question

struct TriviaQuestion: Identifiable, Codable {
    let id: String
    let category: String
    let question: String
    let options: [String]
    let correctAnswer: Int
    let difficulty: Difficulty
    let points: Int
    var userAnswer: Int?

    enum Difficulty: String, Codable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"

        var pointValue: Int {
            switch self {
            case .easy: return 10
            case .medium: return 20
            case .hard: return 30
            }
        }
    }

    init(category: String, question: String, options: [String], correctAnswer: Int, difficulty: Difficulty) {
        self.id = UUID().uuidString
        self.category = category
        self.question = question
        self.options = options
        self.correctAnswer = correctAnswer
        self.difficulty = difficulty
        self.points = difficulty.pointValue
    }

    var isCorrect: Bool? {
        guard let answer = userAnswer else { return nil }
        return answer == correctAnswer
    }
}

// MARK: - Spelling Bee Word

struct SpellingWord: Identifiable, Codable {
    let id: String
    let word: String
    let definition: String
    let difficulty: TriviaQuestion.Difficulty
    let audioHint: String // Phonetic pronunciation
    var userSpelling: String?
    var attempts: Int

    init(word: String, definition: String, difficulty: TriviaQuestion.Difficulty, audioHint: String) {
        self.id = UUID().uuidString
        self.word = word
        self.definition = definition
        self.difficulty = difficulty
        self.audioHint = audioHint
        self.attempts = 0
    }

    var isCorrect: Bool? {
        guard let spelling = userSpelling else { return nil }
        return spelling.lowercased() == word.lowercased()
    }

    var points: Int {
        guard isCorrect == true else { return 0 }
        let basePoints = difficulty.pointValue
        // Bonus for first-try success
        return attempts == 1 ? basePoints + 10 : basePoints
    }
}

// MARK: - Movie Line Challenge

struct MovieLineChallenge: Identifiable, Codable {
    let id: String
    let movieLine: String
    let correctMovie: String
    let options: [String] // Multiple choice
    let year: String
    let difficulty: TriviaQuestion.Difficulty
    var userAnswer: Int?

    init(movieLine: String, correctMovie: String, options: [String], year: String, difficulty: TriviaQuestion.Difficulty) {
        self.id = UUID().uuidString
        self.movieLine = movieLine
        self.correctMovie = correctMovie
        self.options = options
        self.year = year
        self.difficulty = difficulty
    }

    var isCorrect: Bool? {
        guard let answer = userAnswer else { return nil }
        return options[answer] == correctMovie
    }

    var points: Int {
        guard isCorrect == true else { return 0 }
        return difficulty.pointValue
    }
}

// MARK: - Video Game Challenge

struct VideoGameChallenge: Identifiable, Codable {
    let id: String
    let clue: String
    let correctGame: String
    let options: [String]
    let franchise: String?
    let difficulty: TriviaQuestion.Difficulty
    var userAnswer: Int?

    init(clue: String, correctGame: String, options: [String], franchise: String? = nil, difficulty: TriviaQuestion.Difficulty) {
        self.id = UUID().uuidString
        self.clue = clue
        self.correctGame = correctGame
        self.options = options
        self.franchise = franchise
        self.difficulty = difficulty
    }

    var isCorrect: Bool? {
        guard let answer = userAnswer else { return nil }
        return options[answer] == correctGame
    }

    var points: Int {
        guard isCorrect == true else { return 0 }
        return difficulty.pointValue
    }
}

// MARK: - Game Stats

struct GameStats: Codable {
    var totalGamesPlayed: Int
    var totalPoints: Int
    var bestScore: Int
    var averageAccuracy: Double
    var gamesByType: [String: Int] // GameType.rawValue: count
    var achievements: [GameAchievement]

    init() {
        self.totalGamesPlayed = 0
        self.totalPoints = 0
        self.bestScore = 0
        self.averageAccuracy = 0.0
        self.gamesByType = [:]
        self.achievements = []
    }

    mutating func recordGame(_ session: GameSession) {
        totalGamesPlayed += 1
        totalPoints += session.score
        bestScore = max(bestScore, session.score)

        let typeKey = session.gameType.rawValue
        gamesByType[typeKey, default: 0] += 1

        // Update average accuracy
        let totalAccuracy = averageAccuracy * Double(totalGamesPlayed - 1) + session.accuracy
        averageAccuracy = totalAccuracy / Double(totalGamesPlayed)

        // Check for achievements
        checkAchievements()
    }

    mutating func checkAchievements() {
        // First game achievement
        if totalGamesPlayed == 1 && !hasAchievement("first_game") {
            achievements.append(GameAchievement(
                id: "first_game",
                title: "Game On!",
                description: "Played your first game with Moxie",
                icon: "🎮"
            ))
        }

        // Perfect score achievement
        if averageAccuracy >= 1.0 && totalGamesPlayed >= 5 && !hasAchievement("perfect") {
            achievements.append(GameAchievement(
                id: "perfect",
                title: "Perfect Player",
                description: "Maintained 100% accuracy across 5 games",
                icon: "🌟"
            ))
        }

        // High scorer
        if bestScore >= 200 && !hasAchievement("high_scorer") {
            achievements.append(GameAchievement(
                id: "high_scorer",
                title: "High Scorer",
                description: "Reached 200 points in a single game",
                icon: "🏆"
            ))
        }
    }

    private func hasAchievement(_ id: String) -> Bool {
        achievements.contains(where: { $0.id == id })
    }
}

struct GameAchievement: Identifiable, Codable {
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

// MARK: - Verbal Escape Room

/// A verbal escape room puzzle where players interact with objects using only audio descriptions
struct EscapeRoomScenario: Identifiable, Codable {
    let id: String
    let title: String
    let theme: EscapeTheme
    let roomDescription: String
    var objects: [RoomObject]
    var currentObjectIndex: Int
    var hintsUsed: Int
    var isCompleted: Bool
    var timeElapsed: TimeInterval

    enum EscapeTheme: String, Codable, CaseIterable {
        case pirateStudy = "Pirate's Study"
        case spaceStation = "Space Station"
        case ancientTemple = "Ancient Temple"
        case wizardTower = "Wizard's Tower"
        case mysteryMansion = "Mystery Mansion"

        var icon: String {
            switch self {
            case .pirateStudy: return "🏴‍☠️"
            case .spaceStation: return "🚀"
            case .ancientTemple: return "🏛️"
            case .wizardTower: return "🧙"
            case .mysteryMansion: return "🏚️"
            }
        }
    }

    init(title: String, theme: EscapeTheme, roomDescription: String) {
        self.id = UUID().uuidString
        self.title = title
        self.theme = theme
        self.roomDescription = roomDescription
        self.objects = []
        self.currentObjectIndex = 0
        self.hintsUsed = 0
        self.isCompleted = false
        self.timeElapsed = 0
    }

    var currentObject: RoomObject? {
        guard currentObjectIndex < objects.count else { return nil }
        return objects[currentObjectIndex]
    }
}

/// An object in the escape room that can be interacted with
struct RoomObject: Identifiable, Codable {
    let id: String
    let name: String
    let initialDescription: String
    let location: String // e.g., "on the wall", "on the floor", "on the desk"
    var state: ObjectState
    var interactions: [ObjectInteraction]
    var currentInteractionIndex: Int

    enum ObjectState: String, Codable {
        case locked
        case unlocked
        case examined
        case solved
    }

    init(name: String, initialDescription: String, location: String) {
        self.id = UUID().uuidString
        self.name = name
        self.initialDescription = initialDescription
        self.location = location
        self.state = .locked
        self.interactions = []
        self.currentInteractionIndex = 0
    }

    var currentInteraction: ObjectInteraction? {
        guard currentInteractionIndex < interactions.count else { return nil }
        return interactions[currentInteractionIndex]
    }
}

/// An interaction with a room object (verbal command and response)
struct ObjectInteraction: Identifiable, Codable {
    let id: String
    let actionPrompt: String // What Moxie asks the player to do
    let correctActions: [String] // Acceptable verbal commands
    let successResponse: String // What Moxie says on success
    let failureResponse: String // What Moxie says on failure
    let hint: String?
    var userAction: String?
    var wasSuccessful: Bool?

    init(actionPrompt: String, correctActions: [String], successResponse: String, failureResponse: String, hint: String? = nil) {
        self.id = UUID().uuidString
        self.actionPrompt = actionPrompt
        self.correctActions = correctActions
        self.successResponse = successResponse
        self.failureResponse = failureResponse
        self.hint = hint
    }

    func isActionCorrect(_ action: String) -> Bool {
        let normalizedAction = action.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return correctActions.contains { correctAction in
            normalizedAction.contains(correctAction.lowercased())
        }
    }
}

// MARK: - Would You Rather Debate

/// A moral/ethical debate scenario
struct DebateScenario: Identifiable, Codable {
    let id: String
    let category: DebateCategory
    let scenario: String
    let optionA: String
    let optionB: String
    let contextInfo: String? // Additional background information
    var userChoice: Int? // 0 for A, 1 for B
    var userReasoning: String?
    var moxieResponse: String? // Moxie's philosophical response
    var challengeRound: ChallengeRound?
    var difficulty: TriviaQuestion.Difficulty

    enum DebateCategory: String, Codable, CaseIterable {
        case ethics = "Ethics"
        case environment = "Environment"
        case friendship = "Friendship"
        case fairness = "Fairness"
        case responsibility = "Responsibility"
        case honesty = "Honesty"

        var icon: String {
            switch self {
            case .ethics: return "⚖️"
            case .environment: return "🌍"
            case .friendship: return "👫"
            case .fairness: return "🤝"
            case .responsibility: return "📋"
            case .honesty: return "💬"
            }
        }
    }

    struct ChallengeRound: Codable {
        let devilsAdvocateArgument: String // Moxie challenges their reasoning
        var userCounterArgument: String?
        var finalThought: String? // Moxie's final philosophical insight
    }

    init(category: DebateCategory, scenario: String, optionA: String, optionB: String, contextInfo: String? = nil, difficulty: TriviaQuestion.Difficulty) {
        self.id = UUID().uuidString
        self.category = category
        self.scenario = scenario
        self.optionA = optionA
        self.optionB = optionB
        self.contextInfo = contextInfo
        self.difficulty = difficulty
    }

    var chosenOption: String? {
        guard let choice = userChoice else { return nil }
        return choice == 0 ? optionA : optionB
    }

    var points: Int {
        // Points awarded for thoughtful reasoning, not "correct" answers
        guard userReasoning != nil else { return 0 }

        let basePoints = difficulty.pointValue
        // Bonus for engaging with devil's advocate challenge
        let challengeBonus = challengeRound?.userCounterArgument != nil ? 20 : 0

        return basePoints + challengeBonus
    }
}
