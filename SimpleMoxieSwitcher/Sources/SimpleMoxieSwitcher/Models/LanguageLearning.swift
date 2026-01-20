import Foundation

// MARK: - Language Learning Models

/// Represents a complete language learning session
struct LanguageLearningSession: Identifiable, Codable {
    let id: String
    let language: String
    let languageCode: String
    let languageFlag: String
    let proficiencyLevel: ProficiencyLevel
    let createdAt: Date
    var lastAccessedAt: Date
    var lessons: [LanguageLesson]
    var vocabulary: [VocabularyWord]
    var progress: LearningProgress

    enum ProficiencyLevel: String, Codable, CaseIterable {
        case beginner = "Beginner"
        case elementary = "Elementary"
        case intermediate = "Intermediate"
        case upperIntermediate = "Upper Intermediate"
        case advanced = "Advanced"

        var emoji: String {
            switch self {
            case .beginner: return "🌱"
            case .elementary: return "📚"
            case .intermediate: return "🎯"
            case .upperIntermediate: return "🏆"
            case .advanced: return "🌟"
            }
        }
    }

    init(language: String, languageCode: String, languageFlag: String, proficiencyLevel: ProficiencyLevel) {
        self.id = UUID().uuidString
        self.language = language
        self.languageCode = languageCode
        self.languageFlag = languageFlag
        self.proficiencyLevel = proficiencyLevel
        self.createdAt = Date()
        self.lastAccessedAt = Date()
        self.lessons = []
        self.vocabulary = []
        self.progress = LearningProgress()
    }
}

// MARK: - Lesson Structure

struct LanguageLesson: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let category: LessonCategory
    let difficultyLevel: Int // 1-5
    var isCompleted: Bool
    var lastAttemptDate: Date?
    var exercises: [Exercise]
    var grammarPoints: [GrammarPoint]

    enum LessonCategory: String, Codable {
        case vocabulary = "Vocabulary"
        case grammar = "Grammar"
        case conversation = "Conversation"
        case pronunciation = "Pronunciation"
        case listening = "Listening"
        case reading = "Reading"
        case writing = "Writing"
        case culture = "Culture"

        var icon: String {
            switch self {
            case .vocabulary: return "📖"
            case .grammar: return "📝"
            case .conversation: return "💬"
            case .pronunciation: return "🗣️"
            case .listening: return "👂"
            case .reading: return "📰"
            case .writing: return "✍️"
            case .culture: return "🌍"
            }
        }
    }

    init(title: String, description: String, category: LessonCategory, difficultyLevel: Int) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.category = category
        self.difficultyLevel = difficultyLevel
        self.isCompleted = false
        self.exercises = []
        self.grammarPoints = []
    }
}

// MARK: - Exercise Types

enum Exercise: Identifiable, Codable {
    case multipleChoice(MultipleChoiceExercise)
    case fillInTheBlank(FillInTheBlankExercise)
    case translation(TranslationExercise)
    case conversation(ConversationExercise)
    case listening(ListeningExercise)
    case matching(MatchingExercise)

    var id: String {
        switch self {
        case .multipleChoice(let ex): return ex.id
        case .fillInTheBlank(let ex): return ex.id
        case .translation(let ex): return ex.id
        case .conversation(let ex): return ex.id
        case .listening(let ex): return ex.id
        case .matching(let ex): return ex.id
        }
    }
}

struct MultipleChoiceExercise: Identifiable, Codable {
    let id: String
    let question: String
    let options: [String]
    let correctAnswer: Int
    let explanation: String
    var userAnswer: Int?
    var isCorrect: Bool?

    init(question: String, options: [String], correctAnswer: Int, explanation: String) {
        self.id = UUID().uuidString
        self.question = question
        self.options = options
        self.correctAnswer = correctAnswer
        self.explanation = explanation
    }
}

struct FillInTheBlankExercise: Identifiable, Codable {
    let id: String
    let sentence: String // Contains "_____" for blanks
    let correctAnswer: String
    let hints: [String]
    var userAnswer: String?
    var isCorrect: Bool?

    init(sentence: String, correctAnswer: String, hints: [String] = []) {
        self.id = UUID().uuidString
        self.sentence = sentence
        self.correctAnswer = correctAnswer
        self.hints = hints
    }
}

struct TranslationExercise: Identifiable, Codable {
    let id: String
    let sourceText: String
    let sourceLanguage: String
    let targetLanguage: String
    let correctTranslation: String
    let acceptableAlternatives: [String]
    var userTranslation: String?
    var isCorrect: Bool?

    init(sourceText: String, sourceLanguage: String, targetLanguage: String, correctTranslation: String, alternatives: [String] = []) {
        self.id = UUID().uuidString
        self.sourceText = sourceText
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.correctTranslation = correctTranslation
        self.acceptableAlternatives = alternatives
    }
}

struct ConversationExercise: Identifiable, Codable {
    let id: String
    let scenario: String
    let moxiePrompts: [String]
    let suggestedResponses: [String]
    var userResponses: [String]
    var completedAt: Date?

    init(scenario: String, moxiePrompts: [String], suggestedResponses: [String]) {
        self.id = UUID().uuidString
        self.scenario = scenario
        self.moxiePrompts = moxiePrompts
        self.suggestedResponses = suggestedResponses
        self.userResponses = []
    }
}

struct ListeningExercise: Identifiable, Codable {
    let id: String
    let audioText: String // Text that Moxie will speak
    let question: String
    let correctAnswer: String
    var userAnswer: String?
    var isCorrect: Bool?
    var playCount: Int

    init(audioText: String, question: String, correctAnswer: String) {
        self.id = UUID().uuidString
        self.audioText = audioText
        self.question = question
        self.correctAnswer = correctAnswer
        self.playCount = 0
    }
}

struct MatchingExercise: Identifiable, Codable {
    struct Pair: Codable {
        let word: String
        let translation: String
    }

    let id: String
    let pairs: [Pair]
    var shuffledLeft: [String]
    var shuffledRight: [String]
    var userMatches: [Int: Int] // left index: right index
    var isCompleted: Bool

    init(pairs: [(String, String)]) {
        self.id = UUID().uuidString
        self.pairs = pairs.map { Pair(word: $0.0, translation: $0.1) }
        self.shuffledLeft = pairs.map { $0.0 }.shuffled()
        self.shuffledRight = pairs.map { $0.1 }.shuffled()
        self.userMatches = [:]
        self.isCompleted = false
    }
}

// MARK: - Vocabulary

struct VocabularyWord: Identifiable, Codable {
    let id: String
    let word: String
    let translation: String
    let pronunciation: String
    let partOfSpeech: PartOfSpeech
    let exampleSentence: String
    let exampleTranslation: String
    var masteryLevel: Int // 0-5
    var lastPracticed: Date?
    var timesCorrect: Int
    var timesIncorrect: Int

    enum PartOfSpeech: String, Codable {
        case noun = "Noun"
        case verb = "Verb"
        case adjective = "Adjective"
        case adverb = "Adverb"
        case preposition = "Preposition"
        case conjunction = "Conjunction"
        case pronoun = "Pronoun"
        case interjection = "Interjection"

        var abbreviation: String {
            switch self {
            case .noun: return "n."
            case .verb: return "v."
            case .adjective: return "adj."
            case .adverb: return "adv."
            case .preposition: return "prep."
            case .conjunction: return "conj."
            case .pronoun: return "pron."
            case .interjection: return "interj."
            }
        }
    }

    init(word: String, translation: String, pronunciation: String, partOfSpeech: PartOfSpeech, exampleSentence: String, exampleTranslation: String) {
        self.id = UUID().uuidString
        self.word = word
        self.translation = translation
        self.pronunciation = pronunciation
        self.partOfSpeech = partOfSpeech
        self.exampleSentence = exampleSentence
        self.exampleTranslation = exampleTranslation
        self.masteryLevel = 0
        self.timesCorrect = 0
        self.timesIncorrect = 0
    }
}

// MARK: - Grammar

struct GrammarPoint: Identifiable, Codable {
    let id: String
    let title: String
    let explanation: String
    let examples: [GrammarExample]
    let commonMistakes: [String]
    var isUnderstood: Bool

    struct GrammarExample: Codable {
        let correct: String
        let incorrect: String?
        let translation: String
    }

    init(title: String, explanation: String, examples: [GrammarExample], commonMistakes: [String] = []) {
        self.id = UUID().uuidString
        self.title = title
        self.explanation = explanation
        self.examples = examples
        self.commonMistakes = commonMistakes
        self.isUnderstood = false
    }
}

// MARK: - Progress Tracking

struct LearningProgress: Codable {
    var totalLessonsCompleted: Int
    var totalExercisesCompleted: Int
    var vocabularyMastered: Int
    var currentStreak: Int
    var longestStreak: Int
    var lastStudyDate: Date?
    var studyTimeMinutes: Int
    var achievements: [Achievement]

    init() {
        self.totalLessonsCompleted = 0
        self.totalExercisesCompleted = 0
        self.vocabularyMastered = 0
        self.currentStreak = 0
        self.longestStreak = 0
        self.studyTimeMinutes = 0
        self.achievements = []
    }

    mutating func recordStudySession(durationMinutes: Int) {
        studyTimeMinutes += durationMinutes

        // Update streak
        if let lastDate = lastStudyDate {
            let calendar = Calendar.current
            if calendar.isDateInToday(lastDate) {
                // Same day, no change to streak
            } else if calendar.isDateInYesterday(lastDate) {
                // Consecutive day
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                // Streak broken
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }

        lastStudyDate = Date()
    }
}

struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let unlockedAt: Date

    init(title: String, description: String, icon: String) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.icon = icon
        self.unlockedAt = Date()
    }
}

// MARK: - Learning Goals

struct LearningGoal: Identifiable, Codable {
    let id: String
    let type: GoalType
    let target: Int
    var current: Int
    let startDate: Date
    let deadline: Date?
    var isCompleted: Bool

    enum GoalType: String, Codable {
        case dailyPractice = "Practice Daily"
        case completeLessons = "Complete Lessons"
        case masterVocabulary = "Master Vocabulary"
        case studyTime = "Study Time (minutes)"
        case maintainStreak = "Maintain Streak"
    }

    init(type: GoalType, target: Int, deadline: Date? = nil) {
        self.id = UUID().uuidString
        self.type = type
        self.target = target
        self.current = 0
        self.startDate = Date()
        self.deadline = deadline
        self.isCompleted = false
    }

    var progressPercentage: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }
}
