import Foundation

// MARK: - Service Protocols

protocol MQTTServiceProtocol {
    func connect()
    func disconnect()
    func sendCommand(_ command: String, speech: String)
    func publish(topic: String, message: String)
}

protocol DockerServiceProtocol {
    func executePythonScript(_ script: String) async throws -> String
    func restartServer() async throws
}

protocol PersonalityServiceProtocol {
    func updatePersonality(_ personality: Personality) async throws
    func switchPersonality(_ personality: Personality) async throws
}

// ConversationServiceProtocol is defined in ConversationService.swift
// AppearanceServiceProtocol is defined in AppearanceService.swift

// MARK: - Repository Protocols

protocol PersonalityRepositoryProtocol {
    func savePersonality(_ personality: Personality)
    func deletePersonality(_ personality: Personality)
    func loadPersonalities() -> [Personality]
    func resetToDefaults()
}

// ConversationRepositoryProtocol is defined in ConversationRepository.swift

