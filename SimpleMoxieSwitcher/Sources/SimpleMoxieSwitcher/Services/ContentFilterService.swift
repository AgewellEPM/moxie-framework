import Foundation

// MARK: - Content Category
enum ContentCategory {
    case safe
    case requiresParent
    case blocked
}

// MARK: - Content Filter Service
class ContentFilterService {

    // MARK: - Child Mode Filtering

    static func evaluateChildModeRequest(_ message: String) -> ContentCategory {
        let lowercased = message.lowercased()

        // BLOCKED TOPICS (auto-deny)
        let blockedKeywords = [
            // Violence & Safety
            "gun", "weapon", "kill", "hurt", "violence", "fight",
            "murder", "suicide", "bomb", "attack", "stab",

            // Adult Financial
            "credit card", "bank account", "password", "pin code", "money",
            "social security", "credit score", "loan", "mortgage", "debt",

            // Mature Relationships
            "dating", "sex", "romance", "kissing", "pregnant",
            "divorce", "affair", "marriage problems",

            // Politics (controversial)
            "election", "president", "vote", "political party",
            "democrat", "republican", "congress", "senate",

            // Inappropriate Content
            "alcohol", "drugs", "cigarette", "beer", "wine",
            "vodka", "marijuana", "weed", "smoke", "vape",

            // Scary/Disturbing Content
            "horror", "blood", "gore", "nightmare", "scary movie",
            "demon", "devil", "hell", "curse"
        ]

        for keyword in blockedKeywords {
            if lowercased.contains(keyword) {
                return .blocked
            }
        }

        // REQUIRES PARENT (redirect to parent)
        let parentRequiredKeywords = [
            "how much cost", "price", "buy", "purchase",
            "school grades", "report card", "teacher said",
            "parent password", "adult mode", "unlock parent",
            "configure", "settings", "change settings",
            "subscription", "payment", "billing",
            "privacy settings", "parental controls",
            "screen time", "time limit"
        ]

        for keyword in parentRequiredKeywords {
            if lowercased.contains(keyword) {
                return .requiresParent
            }
        }

        // Default: safe for child mode
        return .safe
    }

    // MARK: - Response Generation for Filtered Content

    static func childModeBlockedResponse(originalMessage: String) -> String {
        let responses = [
            "[emotion:neutral] That's a great question for a grown-up! Let's talk about something fun instead. What's your favorite thing to do outside? 🌟",
            "[emotion:neutral] Hmm, that's something to ask your parent about! How about we play a game or tell a story instead? 🎮",
            "[emotion:neutral] That's a grown-up topic! Let's explore something else. What's your favorite animal? 🐻",
            "[emotion:neutral] I think a grown-up could help with that better than me! Want to hear a fun fact about space? 🚀"
        ]
        return responses.randomElement() ?? responses[0]
    }

    static func childModeParentRequiredResponse(originalMessage: String) -> String {
        let responses = [
            "[emotion:neutral] That's something your parent can help you with! I'll let them know you asked. In the meantime, what else would you like to talk about? 😊",
            "[emotion:neutral] Your parent would be the best person to help with that! Let's talk about something fun while you wait to ask them. What's your favorite game? 🎯",
            "[emotion:neutral] I think your parent needs to help with that one! They'll know exactly what to do. Want to tell me about your day instead? ☀️"
        ]
        return responses.randomElement() ?? responses[0]
    }

    // MARK: - Response Sanitization

    static func sanitizeResponse(_ response: String, mode: OperationalMode) -> String {
        guard mode == .child else { return response }

        // Detect inappropriate patterns in AI responses
        let inappropriatePatterns = [
            "kill", "die", "death", "dead",
            "hate", "stupid", "dumb", "idiot",
            "damn", "hell", "crap", "sucks",
            "scary", "terrifying", "nightmare",
            "blood", "violence", "fight"
        ]

        let sanitized = response
        let lowercased = response.lowercased()

        for pattern in inappropriatePatterns {
            if lowercased.contains(pattern) {
                // Log the incident
                logSafetyFilterTrigger(pattern: pattern, originalResponse: response)

                // Return safe fallback
                return "[emotion:happy] Let me think of a better way to say that! How about we talk about something fun? What's your favorite animal? 🐻"
            }
        }

        return sanitized
    }

    // MARK: - Adult Mode Access

    static func evaluateAdultModeRequest(_ message: String) -> ContentCategory {
        // Adults have unrestricted access
        return .safe
    }

    // MARK: - Concern Detection

    static func detectConcerningContent(_ message: String) -> (isConcerning: Bool, category: ConcernCategory?) {
        let lowercased = message.lowercased()

        // Check for emotional distress
        let emotionalDistressPatterns = [
            "nobody likes me", "i hate myself", "i'm stupid",
            "want to die", "nobody cares", "i'm worthless",
            "everyone hates me", "i'm ugly", "i'm a failure"
        ]

        for pattern in emotionalDistressPatterns {
            if lowercased.contains(pattern) {
                return (true, .emotionalDistress)
            }
        }

        // Check for safety risks
        let safetyRiskPatterns = [
            "hitting me", "hurts me", "touches me",
            "scared at home", "don't tell anyone", "keep it secret",
            "yelling at me", "locks me"
        ]

        for pattern in safetyRiskPatterns {
            if lowercased.contains(pattern) {
                return (true, .safetyRisk)
            }
        }

        // Check for bullying indicators
        let bullyingPatterns = [
            "kids are mean", "being bullied", "they tease me",
            "makes fun of me", "calls me names", "won't play with me",
            "pushed me", "took my"
        ]

        for pattern in bullyingPatterns {
            if lowercased.contains(pattern) {
                return (true, .bullyingIndicator)
            }
        }

        return (false, nil)
    }

    // MARK: - Generate Concern Response

    static func generateConcernResponse(category: ConcernCategory) -> String {
        switch category {
        case .emotionalDistress:
            return "[emotion:neutral] Thank you for sharing that with me. That sounds really hard. 💙 It's important to talk to a grown-up you trust about big feelings like this - like your parent, teacher, or school counselor.\n\nI'm here to listen, and I care about you. Do you want to tell me more, or would you like to talk about something else?"

        case .safetyRisk:
            return "[emotion:neutral] I'm glad you told me about this. You're being very brave. 💙 It's really important to talk to a grown-up you trust about this - like your parent, teacher, or another family member.\n\nYou deserve to feel safe and happy. Is there anything else you want to share with me?"

        case .bullyingIndicator:
            return "[emotion:neutral] I'm sorry that's happening to you. That doesn't feel good at all. 💙 Being treated that way isn't okay, and it's not your fault.\n\nHave you talked to a grown-up about this? Teachers and parents can really help make things better. You're awesome just the way you are!"

        case .socialIsolation:
            return "[emotion:neutral] That sounds lonely, and I understand how that feels. 💙 Sometimes making friends can be tricky, but you have so many wonderful things about you!\n\nMaybe we can think of some fun ways to meet new friends or things you enjoy doing. What makes you happy?"
        }
    }

    // MARK: - Logging

    private static func logSafetyFilterTrigger(pattern: String, originalResponse: String) {
        print("⚠️ Safety filter triggered: '\(pattern)' detected in response")

        // Create safety log entry
        let logEntry = SafetyLogEntry(
            timestamp: Date(),
            triggerPattern: pattern,
            originalContent: originalResponse,
            action: .filtered
        )

        // Save to safety log
        Task {
            await SafetyLogService.shared.logEntry(logEntry)
        }
    }
}

// MARK: - Supporting Types

enum ConcernCategory: String, Codable {
    case emotionalDistress = "emotional_distress"
    case safetyRisk = "safety_risk"
    case bullyingIndicator = "bullying_indicator"
    case socialIsolation = "social_isolation"
}

struct SafetyLogEntry: Codable {
    let timestamp: Date
    let triggerPattern: String
    let originalContent: String
    let action: SafetyAction

    enum SafetyAction: String, Codable {
        case filtered = "filtered"
        case flagged = "flagged"
        case notified = "notified"
    }
}

// MARK: - Parent Notification

struct ParentNotification: Codable {
    let id: UUID
    let timestamp: Date
    let childMessage: String
    let category: String
    let moxieResponse: String
    let severity: SeverityLevel

    init(timestamp: Date, childMessage: String, category: String, moxieResponse: String, severity: SeverityLevel) {
        self.id = UUID()
        self.timestamp = timestamp
        self.childMessage = childMessage
        self.category = category
        self.moxieResponse = moxieResponse
        self.severity = severity
    }

    enum SeverityLevel: String, Codable {
        case low = "low"           // General questions about restricted topics
        case medium = "medium"     // Persistent concerns or emotional issues
        case high = "high"         // Safety concerns or urgent matters
    }
}