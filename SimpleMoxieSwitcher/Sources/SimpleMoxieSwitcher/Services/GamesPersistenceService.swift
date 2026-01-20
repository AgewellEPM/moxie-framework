import Foundation

/// Result type for persistence operations
enum PersistenceResult<T> {
    case success(T)
    case failure(PersistenceError)
}

/// Errors that can occur during persistence operations
enum PersistenceError: Error, LocalizedError {
    case dockerServiceUnavailable
    case encodingFailed
    case decodingFailed
    case deviceNotFound
    case saveFailed
    case loadFailed

    var errorDescription: String? {
        switch self {
        case .dockerServiceUnavailable:
            return "Database service is unavailable"
        case .encodingFailed:
            return "Failed to encode data"
        case .decodingFailed:
            return "Failed to decode data"
        case .deviceNotFound:
            return "Device not found in database"
        case .saveFailed:
            return GamesPersistenceConfig.saveErrorMessage
        case .loadFailed:
            return GamesPersistenceConfig.loadErrorMessage
        }
    }
}

/// Centralized service for all Games database operations
/// Eliminates duplicate queries and provides consistent error handling
@MainActor
class GamesPersistenceService {
    private let dockerService: DockerServiceProtocol

    init(dockerService: DockerServiceProtocol) {
        self.dockerService = dockerService
    }

    // MARK: - Game Stats

    func loadGameStats() async -> PersistenceResult<GameStats> {
        do {
            let script = GamesDatabaseScripts.loadData(key: GamesPersistenceConfig.statsKey)
            let result = try await dockerService.executePythonScript(script)

            if let jsonData = result.data(using: .utf8),
               let stats = try? JSONDecoder().decode(GameStats.self, from: jsonData) {
                return .success(stats)
            } else {
                // No stats exist yet, return empty
                return .success(GameStats())
            }
        } catch {
            print("Error loading game stats: \(error)")
            return .failure(.loadFailed)
        }
    }

    func saveGameStats(_ stats: GameStats) async -> PersistenceResult<Void> {
        do {
            guard let jsonData = try? JSONEncoder().encode(stats),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                return .failure(.encodingFailed)
            }

            let script = GamesDatabaseScripts.saveData(
                key: GamesPersistenceConfig.statsKey,
                jsonString: jsonString
            )

            _ = try await dockerService.executePythonScript(script)
            return .success(())
        } catch {
            print("Error saving game stats: \(error)")
            return .failure(.saveFailed)
        }
    }

    /// Record a completed game session and update stats atomically
    func recordGameSession(_ session: GameSession) async -> PersistenceResult<Void> {
        do {
            guard let sessionData = try? JSONEncoder().encode(session),
                  let sessionString = String(data: sessionData, encoding: .utf8) else {
                return .failure(.encodingFailed)
            }

            let script = GamesDatabaseScripts.updateGameStats(sessionJSON: sessionString)
            _ = try await dockerService.executePythonScript(script)
            return .success(())
        } catch {
            print("Error recording game session: \(error)")
            return .failure(.saveFailed)
        }
    }

    // MARK: - Quest Progress

    func loadQuestProgress() async -> PersistenceResult<QuestProgress> {
        do {
            let script = GamesDatabaseScripts.loadData(key: GamesPersistenceConfig.questProgressKey)
            let result = try await dockerService.executePythonScript(script)

            if let jsonData = result.data(using: .utf8),
               let progress = try? JSONDecoder().decode(QuestProgress.self, from: jsonData) {
                return .success(progress)
            } else {
                return .success(QuestProgress())
            }
        } catch {
            print("Error loading quest progress: \(error)")
            return .failure(.loadFailed)
        }
    }

    func saveQuestProgress(_ progress: QuestProgress) async -> PersistenceResult<Void> {
        do {
            guard let jsonData = try? JSONEncoder().encode(progress),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                return .failure(.encodingFailed)
            }

            let script = GamesDatabaseScripts.saveData(
                key: GamesPersistenceConfig.questProgressKey,
                jsonString: jsonString
            )

            _ = try await dockerService.executePythonScript(script)
            return .success(())
        } catch {
            print("Error saving quest progress: \(error)")
            return .failure(.saveFailed)
        }
    }

    // MARK: - Current Quest

    func loadCurrentQuest() async -> PersistenceResult<KnowledgeQuest?> {
        do {
            let script = GamesDatabaseScripts.loadData(key: GamesPersistenceConfig.currentQuestKey)
            let result = try await dockerService.executePythonScript(script)

            if let jsonData = result.data(using: .utf8),
               let quest = try? JSONDecoder().decode(KnowledgeQuest.self, from: jsonData) {
                return .success(quest)
            } else {
                return .success(nil)
            }
        } catch {
            print("Error loading current quest: \(error)")
            return .failure(.loadFailed)
        }
    }

    func saveCurrentQuest(_ quest: KnowledgeQuest) async -> PersistenceResult<Void> {
        do {
            guard let jsonData = try? JSONEncoder().encode(quest),
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
                return .failure(.encodingFailed)
            }

            let script = GamesDatabaseScripts.saveData(
                key: GamesPersistenceConfig.currentQuestKey,
                jsonString: jsonString
            )

            _ = try await dockerService.executePythonScript(script)
            return .success(())
        } catch {
            print("Error saving current quest: \(error)")
            return .failure(.saveFailed)
        }
    }

    // MARK: - Helper: Input Sanitization

    static func sanitizeUserInput(_ input: String) -> String {
        input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .prefix(GamesPersistenceConfig.maxInputLength)
            .description
    }

    static func sanitizeReasoning(_ input: String) -> String {
        input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .prefix(GamesPersistenceConfig.maxReasoningLength)
            .description
    }
}
