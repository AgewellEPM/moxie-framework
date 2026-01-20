import Foundation

/// Configuration constants for Games persistence
struct GamesPersistenceConfig {
    /// Device ID for persistence queries
    static let deviceID = "moxie_001"

    /// Database keys
    static let statsKey = "game_stats"
    static let questProgressKey = "quest_progress"
    static let currentQuestKey = "current_quest"
    static let escapeRoomProgressKey = "escape_room_progress"
    static let debateHistoryKey = "debate_history"

    /// Error messages
    static let loadErrorMessage = "Unable to load game data. Please try again."
    static let saveErrorMessage = "Unable to save game progress. Please try again."

    /// Input validation
    static let maxInputLength = 500
    static let maxReasoningLength = 1000
}
