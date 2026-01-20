import Foundation

protocol IntentDetectionServiceProtocol {
    func detectIntent(from messages: [ChatMessage]) -> (intent: SessionIntent, confidence: Double)
    func detectDrift(currentIntent: SessionIntent, recentMessages: [ChatMessage]) -> Bool
    func generateRedirectionSuggestion(from current: SessionIntent, to detected: SessionIntent) -> String?
}

final class IntentDetectionService: IntentDetectionServiceProtocol {

    // MARK: - Intent Keywords

    private let playKeywords = [
        "play", "game", "fun", "silly", "joke", "laugh", "pretend", "imagine",
        "let's play", "wanna play", "can we play"
    ]

    private let learnKeywords = [
        "learn", "teach", "show me", "how to", "what is", "why", "explain",
        "help me understand", "I want to know", "can you teach", "homework",
        "study", "practice", "lesson"
    ]

    private let comfortKeywords = [
        "sad", "scared", "worried", "upset", "lonely", "miss", "hurt", "cry",
        "afraid", "nervous", "anxious", "feel bad", "not good", "help me feel",
        "I need", "comfort me"
    ]

    private let exploreKeywords = [
        "what if", "curious", "wonder", "explore", "discover", "find out",
        "show me around", "let's look", "I wonder", "tell me about"
    ]

    private let socializingKeywords = [
        "hi", "hello", "how are you", "what's up", "tell me about you",
        "let's talk", "chat", "friend", "buddy", "wanna hang out"
    ]

    private let storytellingKeywords = [
        "story", "tell me a story", "once upon", "adventure", "tale",
        "read me", "storytime", "bedtime story", "make up a story"
    ]

    // MARK: - Subject Detection for Learning

    private let subjects = [
        "math": ["math", "addition", "subtraction", "numbers", "counting", "multiply", "divide"],
        "science": ["science", "experiment", "animals", "plants", "space", "earth", "nature"],
        "reading": ["reading", "letters", "words", "alphabet", "spelling", "book"],
        "art": ["art", "drawing", "painting", "colors", "creative", "craft"],
        "social": ["feelings", "emotions", "friends", "sharing", "kindness", "manners"]
    ]

    // MARK: - Intent Detection

    func detectIntent(from messages: [ChatMessage]) -> (intent: SessionIntent, confidence: Double) {
        // Analyze recent messages (last 5 or all if less)
        let recentMessages = messages.suffix(5)
        let text = recentMessages
            .filter { $0.isUser }
            .map { $0.content.lowercased() }
            .joined(separator: " ")

        var scores: [SessionIntent: Double] = [
            .play: 0.0,
            .learn(subject: nil): 0.0,
            .comfort: 0.0,
            .explore: 0.0,
            .socializing: 0.0,
            .storytelling: 0.0
        ]

        // Score each intent
        scores[.play] = score(text: text, keywords: playKeywords)
        scores[.comfort] = score(text: text, keywords: comfortKeywords) * 1.2  // Weight comfort higher
        scores[.explore] = score(text: text, keywords: exploreKeywords)
        scores[.socializing] = score(text: text, keywords: socializingKeywords)
        scores[.storytelling] = score(text: text, keywords: storytellingKeywords)

        // Check for learning with subject detection
        let learnScore = score(text: text, keywords: learnKeywords)
        let subject = detectSubject(from: text)
        scores[.learn(subject: subject)] = learnScore

        // Detect questions (often learning or exploring)
        if text.contains("?") {
            if learnScore > 0 {
                scores[.learn(subject: subject)]? += 0.3
            } else {
                scores[.explore]? += 0.2
            }
        }

        // Find highest score
        let sorted = scores.sorted { $0.value > $1.value }
        guard let top = sorted.first else {
            return (.unknown, 0.0)
        }

        // If score is too low, return unknown
        if top.value < 0.3 {
            return (.unknown, top.value)
        }

        // Check if it's socializing by default (greetings at start)
        if messages.count <= 2 && scores[.socializing] ?? 0.0 > 0 {
            return (.socializing, scores[.socializing] ?? 0.0)
        }

        return (top.key, min(top.value, 1.0))
    }

    // MARK: - Drift Detection

    func detectDrift(currentIntent: SessionIntent, recentMessages: [ChatMessage]) -> Bool {
        let (detected, confidence) = detectIntent(from: recentMessages)

        // High confidence in a different intent suggests drift
        if detected != currentIntent && confidence > 0.6 {
            return true
        }

        return false
    }

    // MARK: - Redirection Suggestions

    func generateRedirectionSuggestion(from current: SessionIntent, to detected: SessionIntent) -> String? {
        switch (current, detected) {
        case (.socializing, .learn):
            return "I notice you're curious about learning something new! Want to start a lesson together?"

        case (.play, .learn):
            return "Sounds like you want to learn! Should we switch to learning mode?"

        case (.learn, .play):
            return "Ready for a break from learning? Let's have some fun!"

        case (.learn, .comfort):
            return "I can tell you might need a little break. Want to just talk for a bit?"

        case (.play, .comfort):
            return "Is everything okay? I'm here if you need to talk."

        case (_, .storytelling):
            return "Would you like me to tell you a story?"

        case (.socializing, .explore):
            return "You seem really curious! Want to explore and discover some new things together?"

        default:
            return nil
        }
    }

    // MARK: - Helper Methods

    private func score(text: String, keywords: [String]) -> Double {
        var score = 0.0
        let words = text.split(separator: " ").map { String($0) }

        for keyword in keywords {
            let keywordWords = keyword.split(separator: " ").map { String($0) }

            if keywordWords.count == 1 {
                // Single word keyword
                if words.contains(keyword) {
                    score += 0.3
                }
            } else {
                // Multi-word phrase
                if text.contains(keyword) {
                    score += 0.5  // Higher weight for exact phrases
                }
            }
        }

        return score
    }

    private func detectSubject(from text: String) -> String? {
        for (subject, keywords) in subjects {
            let subjectScore = score(text: text, keywords: keywords)
            if subjectScore > 0.3 {
                return subject
            }
        }
        return nil
    }
}
