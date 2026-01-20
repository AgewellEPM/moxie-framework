import Foundation

enum SessionIntent: Codable, Equatable, Hashable {
    case play
    case learn(subject: String?)
    case comfort
    case explore
    case socializing
    case storytelling
    case unknown

    var displayName: String {
        switch self {
        case .play:
            return "Playing"
        case .learn(let subject):
            if let subject = subject {
                return "Learning: \(subject)"
            }
            return "Learning"
        case .comfort:
            return "Comfort & Support"
        case .explore:
            return "Exploring"
        case .socializing:
            return "Chatting"
        case .storytelling:
            return "Story Time"
        case .unknown:
            return "Unknown"
        }
    }

    var icon: String {
        switch self {
        case .play:
            return "🎮"
        case .learn:
            return "📚"
        case .comfort:
            return "💙"
        case .explore:
            return "🔍"
        case .socializing:
            return "💬"
        case .storytelling:
            return "📖"
        case .unknown:
            return "❓"
        }
    }

    var color: (red: Double, green: Double, blue: Double) {
        switch self {
        case .play:
            return (0.9, 0.5, 0.9)  // Purple
        case .learn:
            return (0.3, 0.6, 0.9)  // Blue
        case .comfort:
            return (0.5, 0.8, 0.9)  // Light blue
        case .explore:
            return (0.9, 0.7, 0.3)  // Orange
        case .socializing:
            return (0.5, 0.9, 0.5)  // Green
        case .storytelling:
            return (0.9, 0.6, 0.4)  // Warm orange
        case .unknown:
            return (0.5, 0.5, 0.5)  // Gray
        }
    }
}

struct SessionState: Codable {
    var currentIntent: SessionIntent
    var startTime: Date
    var lastIntentCheck: Date
    var messagesSinceLastCheck: Int
    var driftDetected: Bool
    var confidence: Double  // 0-1

    init(intent: SessionIntent = .unknown) {
        self.currentIntent = intent
        self.startTime = Date()
        self.lastIntentCheck = Date()
        self.messagesSinceLastCheck = 0
        self.driftDetected = false
        self.confidence = 0.0
    }

    mutating func updateIntent(_ newIntent: SessionIntent, confidence: Double) {
        self.currentIntent = newIntent
        self.confidence = confidence
        self.lastIntentCheck = Date()
        self.messagesSinceLastCheck = 0
    }

    mutating func incrementMessages() {
        self.messagesSinceLastCheck += 1
    }

    var sessionDuration: TimeInterval {
        Date().timeIntervalSince(startTime)
    }

    var timeSinceLastCheck: TimeInterval {
        Date().timeIntervalSince(lastIntentCheck)
    }

    var shouldRecheckIntent: Bool {
        // Recheck if:
        // - 5+ messages since last check
        // - 3+ minutes since last check
        // - Drift was detected
        messagesSinceLastCheck >= 5 ||
        timeSinceLastCheck > 180 ||
        driftDetected
    }
}
