import Foundation

// MARK: - Enhanced Conversation Log with Safety Features
struct ConversationLog: Codable, Identifiable {
    let id: UUID
    let mode: OperationalMode
    let sessionID: UUID
    let childProfileID: UUID?
    let personality: String
    let messages: [ChatMessage]
    let summary: String?
    let sentiment: Sentiment?
    let flags: [ContentFlag]
    let createdAt: Date
    let updatedAt: Date

    init(
        id: UUID = UUID(),
        mode: OperationalMode,
        sessionID: UUID = UUID(),
        childProfileID: UUID? = nil,
        personality: String,
        messages: [ChatMessage] = [],
        summary: String? = nil,
        sentiment: Sentiment? = nil,
        flags: [ContentFlag] = []
    ) {
        self.id = id
        self.mode = mode
        self.sessionID = sessionID
        self.childProfileID = childProfileID
        self.personality = personality
        self.messages = messages
        self.summary = summary
        self.sentiment = sentiment
        self.flags = flags
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // Computed properties
    var duration: TimeInterval {
        guard let first = messages.first, let last = messages.last else { return 0 }
        return last.timestamp.timeIntervalSince(first.timestamp)
    }

    var messageCount: Int {
        messages.count
    }

    var hasFlaggedContent: Bool {
        !flags.isEmpty
    }

    var unreviewedFlags: [ContentFlag] {
        flags.filter { !$0.reviewed }
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes)m \(seconds)s"
    }
}

// MARK: - Sentiment Analysis
enum Sentiment: String, Codable {
    case veryPositive = "very_positive"
    case positive = "positive"
    case neutral = "neutral"
    case negative = "negative"
    case concerning = "concerning"

    var displayName: String {
        switch self {
        case .veryPositive:
            return "Very Positive"
        case .positive:
            return "Positive"
        case .neutral:
            return "Neutral"
        case .negative:
            return "Negative"
        case .concerning:
            return "Concerning"
        }
    }

    var emoji: String {
        switch self {
        case .veryPositive:
            return "😄"
        case .positive:
            return "🙂"
        case .neutral:
            return "😐"
        case .negative:
            return "😕"
        case .concerning:
            return "😟"
        }
    }

    var color: String {
        switch self {
        case .veryPositive:
            return "#00FF00"  // Green
        case .positive:
            return "#7FFF00"  // Yellow-green
        case .neutral:
            return "#808080"  // Gray
        case .negative:
            return "#FFA500"  // Orange
        case .concerning:
            return "#FF0000"  // Red
        }
    }

    var shouldNotifyParent: Bool {
        self == .concerning
    }
}

// MARK: - Content Flag
struct ContentFlag: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let severity: FlagSeverity
    let category: FlagCategory
    let messageContent: String
    let contextMessages: [ChatMessage]
    let aiExplanation: String
    var reviewed: Bool

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        severity: FlagSeverity,
        category: FlagCategory,
        messageContent: String,
        contextMessages: [ChatMessage] = [],
        aiExplanation: String,
        reviewed: Bool = false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.severity = severity
        self.category = category
        self.messageContent = messageContent
        self.contextMessages = contextMessages
        self.aiExplanation = aiExplanation
        self.reviewed = reviewed
    }

    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    mutating func markAsReviewed() {
        reviewed = true
    }
}

// MARK: - Flag Severity
enum FlagSeverity: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"

    var displayName: String {
        rawValue.capitalized
    }

    var emoji: String {
        switch self {
        case .low:
            return "ℹ️"
        case .medium:
            return "⚠️"
        case .high:
            return "🚨"
        case .critical:
            return "🆘"
        }
    }

    var color: String {
        switch self {
        case .low:
            return "#0099FF"  // Blue
        case .medium:
            return "#FFA500"  // Orange
        case .high:
            return "#FF4500"  // Red-orange
        case .critical:
            return "#FF0000"  // Red
        }
    }

    var shouldEmailParent: Bool {
        self == .high || self == .critical
    }

    var shouldAlertImmediately: Bool {
        self == .critical
    }
}

// MARK: - Flag Category
enum FlagCategory: String, Codable, CaseIterable {
    case inappropriateLanguage = "inappropriate_language"
    case bullyingMention = "bullying_mention"
    case sadnessRepeated = "sadness_repeated"
    case angerRepeated = "anger_repeated"
    case selfHarmLanguage = "self_harm_language"
    case abuseIndicators = "abuse_indicators"
    case privacyRisk = "privacy_risk"

    var displayName: String {
        switch self {
        case .inappropriateLanguage:
            return "Inappropriate Language"
        case .bullyingMention:
            return "Bullying Mention"
        case .sadnessRepeated:
            return "Repeated Sadness"
        case .angerRepeated:
            return "Repeated Anger"
        case .selfHarmLanguage:
            return "Self-Harm Language"
        case .abuseIndicators:
            return "Abuse Indicators"
        case .privacyRisk:
            return "Privacy Risk"
        }
    }

    var description: String {
        switch self {
        case .inappropriateLanguage:
            return "Child used language that may be inappropriate for their age"
        case .bullyingMention:
            return "Child mentioned being bullied or bullying others"
        case .sadnessRepeated:
            return "Child expressed sadness multiple times in conversation"
        case .angerRepeated:
            return "Child expressed anger or frustration multiple times"
        case .selfHarmLanguage:
            return "Child used language suggesting self-harm thoughts"
        case .abuseIndicators:
            return "Child mentioned situations that may indicate abuse"
        case .privacyRisk:
            return "Child shared personal information (address, phone, etc.)"
        }
    }

    var recommendedAction: String {
        switch self {
        case .inappropriateLanguage:
            return "Talk with your child about appropriate language use"
        case .bullyingMention:
            return "Discuss the situation with your child and consider contacting school"
        case .sadnessRepeated:
            return "Check in with your child about how they're feeling"
        case .angerRepeated:
            return "Help your child develop healthy ways to express frustration"
        case .selfHarmLanguage:
            return "Seek immediate professional help - contact a therapist or call 988"
        case .abuseIndicators:
            return "Document the conversation and contact appropriate authorities"
        case .privacyRisk:
            return "Remind your child about online safety and private information"
        }
    }

    var defaultSeverity: FlagSeverity {
        switch self {
        case .inappropriateLanguage:
            return .low
        case .bullyingMention:
            return .medium
        case .sadnessRepeated:
            return .medium
        case .angerRepeated:
            return .medium
        case .selfHarmLanguage:
            return .critical
        case .abuseIndicators:
            return .critical
        case .privacyRisk:
            return .high
        }
    }
}

// MARK: - Activity Event
struct ActivityEvent: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let mode: OperationalMode
    let type: EventType
    let details: [String: String]

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        mode: OperationalMode,
        type: EventType,
        details: [String: String] = [:]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.mode = mode
        self.type = type
        self.details = details
    }

    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    var displayDescription: String {
        switch type {
        case .modeSwitchToAdult:
            return "Switched to Parent Console"
        case .modeSwitchToChild:
            return "Switched to Child Mode"
        case .pinEntrySuccess:
            return "PIN entered successfully"
        case .pinEntryFailure:
            return "Failed PIN attempt"
        case .pinLockoutTriggered:
            return "PIN entry locked (too many attempts)"
        case .sessionTimeout:
            return "Session timed out (inactivity)"
        case .conversationStarted:
            return "Conversation started (\(details["personality"] ?? "Unknown"))"
        case .conversationEnded:
            return "Conversation ended"
        case .contentFlagged:
            return "Content flagged: \(details["category"] ?? "Unknown")"
        case .autoLockTriggered:
            return "Auto-lock activated (time restriction)"
        case .timeExtensionRequested:
            return "Child requested more time"
        case .timeExtensionGranted:
            return "Time extension granted (\(details["duration"] ?? "Unknown"))"
        case .timeExtensionDenied:
            return "Time extension denied"
        case .storyAccessed:
            return "Story accessed: \(details["title"] ?? "Unknown")"
        case .learningActivityCompleted:
            return "Learning activity completed: \(details["title"] ?? "Unknown")"
        case .smartHomeCommandIssued:
            return "Smart home command: \(details["command"] ?? "Unknown")"
        case .cameraAccessed:
            return "Camera accessed"
        case .conversationExported:
            return "Conversation exported (\(details["format"] ?? "Unknown"))"
        case .dataDeleted:
            return "Data deleted: \(details["type"] ?? "Unknown")"
        case .settingsChanged:
            return "Settings changed: \(details["setting"] ?? "Unknown")"
        case .emergencyOverride:
            return "Emergency override activated: \(details["reason"] ?? "Unknown")"
        }
    }
}

// MARK: - Event Type
enum EventType: String, Codable {
    // Mode events
    case modeSwitchToAdult = "mode_switch_to_adult"
    case modeSwitchToChild = "mode_switch_to_child"
    case pinEntrySuccess = "pin_entry_success"
    case pinEntryFailure = "pin_entry_failure"
    case pinLockoutTriggered = "pin_lockout_triggered"
    case sessionTimeout = "session_timeout"

    // Conversation events
    case conversationStarted = "conversation_started"
    case conversationEnded = "conversation_ended"
    case contentFlagged = "content_flagged"

    // Time restriction events
    case autoLockTriggered = "auto_lock_triggered"
    case timeExtensionRequested = "time_extension_requested"
    case timeExtensionGranted = "time_extension_granted"
    case timeExtensionDenied = "time_extension_denied"

    // Feature usage
    case storyAccessed = "story_accessed"
    case learningActivityCompleted = "learning_activity_completed"
    case smartHomeCommandIssued = "smart_home_command_issued"
    case cameraAccessed = "camera_accessed"

    // Data management
    case conversationExported = "conversation_exported"
    case dataDeleted = "data_deleted"
    case settingsChanged = "settings_changed"

    // Emergency
    case emergencyOverride = "emergency_override"

    var category: EventCategory {
        switch self {
        case .modeSwitchToAdult, .modeSwitchToChild, .pinEntrySuccess, .pinEntryFailure, .pinLockoutTriggered, .sessionTimeout:
            return .security
        case .conversationStarted, .conversationEnded, .contentFlagged:
            return .conversation
        case .autoLockTriggered, .timeExtensionRequested, .timeExtensionGranted, .timeExtensionDenied:
            return .timeRestriction
        case .storyAccessed, .learningActivityCompleted, .smartHomeCommandIssued, .cameraAccessed:
            return .featureUsage
        case .conversationExported, .dataDeleted, .settingsChanged:
            return .dataManagement
        case .emergencyOverride:
            return .emergency
        }
    }
}

enum EventCategory {
    case security
    case conversation
    case timeRestriction
    case featureUsage
    case dataManagement
    case emergency
}

// MARK: - Activity Log
struct ActivityLog: Codable {
    var events: [ActivityEvent]

    init(events: [ActivityEvent] = []) {
        self.events = events
    }

    mutating func addEvent(_ event: ActivityEvent) {
        events.append(event)
    }

    func getEvents(
        from startDate: Date,
        to endDate: Date,
        mode: OperationalMode? = nil,
        eventType: EventType? = nil,
        category: EventCategory? = nil
    ) -> [ActivityEvent] {
        events.filter { event in
            var matches = event.timestamp >= startDate && event.timestamp <= endDate

            if let mode = mode {
                matches = matches && event.mode == mode
            }

            if let eventType = eventType {
                matches = matches && event.type == eventType
            }

            if let category = category {
                matches = matches && event.type.category == category
            }

            return matches
        }
    }

    func getRecentEvents(limit: Int = 10) -> [ActivityEvent] {
        Array(events.suffix(limit).reversed())
    }

    mutating func pruneOldEvents(olderThan days: Int) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        events.removeAll { $0.timestamp < cutoffDate }
    }
}
