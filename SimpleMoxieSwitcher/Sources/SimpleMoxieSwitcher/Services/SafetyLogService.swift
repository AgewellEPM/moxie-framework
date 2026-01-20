import Foundation

/// Service for persisting and managing safety-related logs
@MainActor
class SafetyLogService {
    static let shared = SafetyLogService()

    private let logPath: URL
    private let maxLogEntries = 10000 // Keep last 10,000 entries
    private let dockerService: DockerServiceProtocol

    private init() {
        self.logPath = AppPaths.applicationSupport.appendingPathComponent("safety_logs.json")
        self.dockerService = DIContainer.shared.resolve(DockerServiceProtocol.self)
    }

    // MARK: - Log Safety Entry

    func logEntry(_ entry: SafetyLogEntry) async {
        // Save locally
        await saveLocalLog(entry)

        // Save to OpenMoxie database for parent review
        await saveToDatabaseLog(entry)
    }

    // MARK: - Log Content Flag

    func logContentFlag(_ flag: ContentFlag, conversationLog: ConversationLog) async {
        // Create safety log entry
        let entry = SafetyLogEntry(
            timestamp: flag.timestamp,
            triggerPattern: flag.category.rawValue,
            originalContent: flag.messageContent,
            action: .flagged
        )

        await logEntry(entry)

        // Send parent notification if severe
        if flag.severity.shouldEmailParent {
            await ParentNotificationService.shared.notifyContentFlag(
                severity: flag.severity,
                category: flag.category
            )
        }
    }

    // MARK: - Retrieve Logs

    func getRecentLogs(limit: Int = 100) async -> [SafetyLogEntry] {
        do {
            guard FileManager.default.fileExists(atPath: logPath.path) else {
                return []
            }

            let data = try Data(contentsOf: logPath)
            let logs = try JSONDecoder().decode([SafetyLogEntry].self, from: data)
            return Array(logs.suffix(limit).reversed())
        } catch {
            print("Error loading safety logs: \(error)")
            return []
        }
    }

    func getLogsByPattern(_ pattern: String) async -> [SafetyLogEntry] {
        let allLogs = await getRecentLogs(limit: maxLogEntries)
        return allLogs.filter { $0.triggerPattern.lowercased().contains(pattern.lowercased()) }
    }

    func getLogsByDateRange(from startDate: Date, to endDate: Date) async -> [SafetyLogEntry] {
        let allLogs = await getRecentLogs(limit: maxLogEntries)
        return allLogs.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
    }

    // MARK: - Statistics

    func getSafetyStatistics() async -> SafetyStatistics {
        let logs = await getRecentLogs(limit: maxLogEntries)

        let totalEntries = logs.count
        let filteredCount = logs.filter { $0.action == .filtered }.count
        let flaggedCount = logs.filter { $0.action == .flagged }.count
        let notifiedCount = logs.filter { $0.action == .notified }.count

        // Get most common patterns
        let patternCounts = Dictionary(grouping: logs, by: { $0.triggerPattern })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }

        let topPatterns = patternCounts.prefix(10).map {
            SafetyPattern(pattern: $0.key, count: $0.value)
        }

        // Get recent trend (last 7 days)
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentLogs = logs.filter { $0.timestamp >= sevenDaysAgo }

        return SafetyStatistics(
            totalEntries: totalEntries,
            filteredCount: filteredCount,
            flaggedCount: flaggedCount,
            notifiedCount: notifiedCount,
            topPatterns: topPatterns,
            recentTrend: recentLogs.count,
            lastUpdated: Date()
        )
    }

    // MARK: - Private Helpers

    private func saveLocalLog(_ entry: SafetyLogEntry) async {
        do {
            var logs: [SafetyLogEntry] = []

            // Load existing logs
            if FileManager.default.fileExists(atPath: logPath.path) {
                let data = try Data(contentsOf: logPath)
                logs = try JSONDecoder().decode([SafetyLogEntry].self, from: data)
            }

            // Add new entry
            logs.append(entry)

            // Trim to max entries
            if logs.count > maxLogEntries {
                logs = Array(logs.suffix(maxLogEntries))
            }

            // Save back
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(logs)
            try data.write(to: logPath)

            print("📝 Safety log saved: \(entry.action.rawValue) - \(entry.triggerPattern)")
        } catch {
            print("Error saving safety log: \(error)")
        }
    }

    private func saveToDatabaseLog(_ entry: SafetyLogEntry) async {
        // Convert log entry to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        guard let jsonData = try? encoder.encode(entry),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }

        let pythonScript = """
        import json
        from django.utils import timezone
        from hive.models import MoxieDevice, PersistentData

        device = MoxieDevice.objects.filter(device_id='moxie_001').first()
        if device:
            persist, created = PersistentData.objects.get_or_create(device=device, defaults={'data': {}})
            data = persist.data or {}

            # Initialize safety_logs if it doesn't exist
            if 'safety_logs' not in data:
                data['safety_logs'] = []

            # Add the new safety log entry
            log_entry = json.loads('''\(jsonString)''')
            data['safety_logs'].append(log_entry)

            # Keep only last 1000 entries to prevent database bloat
            if len(data['safety_logs']) > 1000:
                data['safety_logs'] = data['safety_logs'][-1000:]

            persist.data = data
            persist.save()
            print(f'Safety log saved to database: {log_entry["action"]}')
        """

        do {
            _ = try await dockerService.executePythonScript(pythonScript)
        } catch {
            print("Failed to save safety log to database: \(error)")
        }
    }

    // MARK: - Cleanup

    func cleanupOldLogs(olderThan days: Int) async {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        do {
            guard FileManager.default.fileExists(atPath: logPath.path) else { return }

            let data = try Data(contentsOf: logPath)
            var logs = try JSONDecoder().decode([SafetyLogEntry].self, from: data)

            // Remove old logs
            let beforeCount = logs.count
            logs.removeAll { $0.timestamp < cutoffDate }
            let afterCount = logs.count

            // Save back
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let newData = try encoder.encode(logs)
            try newData.write(to: logPath)

            print("🧹 Cleaned up \(beforeCount - afterCount) safety logs older than \(days) days")
        } catch {
            print("Error cleaning up safety logs: \(error)")
        }
    }
}

// MARK: - Supporting Models

struct SafetyStatistics: Codable {
    let totalEntries: Int
    let filteredCount: Int
    let flaggedCount: Int
    let notifiedCount: Int
    let topPatterns: [SafetyPattern]
    let recentTrend: Int
    let lastUpdated: Date
}

struct SafetyPattern: Codable {
    let pattern: String
    let count: Int
}
