import Foundation

/// Service for storing and retrieving memories
@MainActor
class MemoryStorageService {
    private let dockerService: DockerServiceProtocol
    private let deviceId = "moxie_001"

    init(dockerService: DockerServiceProtocol? = nil) {
        self.dockerService = dockerService ?? DIContainer.shared.resolve(DockerServiceProtocol.self)
    }

    // MARK: - Save Memories

    /// Save extracted memories to the database
    func saveMemories(_ memories: [ConversationMemory]) async throws {
        // Convert memories to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let memoriesData = try encoder.encode(memories)
        let memoriesJSON = String(data: memoriesData, encoding: .utf8)!

        let script = """
        import json
        from hive.models import MoxieDevice, PersistentData

        device = MoxieDevice.objects.filter(device_id='\(deviceId)').first()
        if device:
            persist, created = PersistentData.objects.get_or_create(
                device=device,
                defaults={'data': {}}
            )
            data = persist.data or {}

            # Get existing memories or initialize
            memories = data.get('extracted_memories', [])

            # Add new memories
            new_memories = \(memoriesJSON)
            memories.extend(new_memories)

            # Store back
            data['extracted_memories'] = memories
            persist.data = data
            persist.save()

            print(json.dumps({'success': True, 'total_memories': len(memories)}))
        else:
            print(json.dumps({'success': False, 'error': 'Device not found'}))
        """

        let result = try await dockerService.executePythonScript(script)
        print("💾 Saved memories: \(result)")
    }

    /// Load all memories from the database
    func loadMemories() async throws -> [ConversationMemory] {
        let script = """
        import json
        from hive.models import MoxieDevice, PersistentData

        device = MoxieDevice.objects.filter(device_id='\(deviceId)').first()
        if device:
            persist = PersistentData.objects.filter(device=device).first()
            if persist and persist.data:
                memories = persist.data.get('extracted_memories', [])
                print(json.dumps(memories))
            else:
                print('[]')
        else:
            print('[]')
        """

        let result = try await dockerService.executePythonScript(script)

        // Parse JSON
        guard let jsonData = result.data(using: .utf8) else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let memories = try decoder.decode([ConversationMemory].self, from: jsonData)

        return memories
    }

    // MARK: - Save Frontal Cortex

    /// Save the frontal cortex (core knowledge base)
    func saveFrontalCortex(_ cortex: FrontalCortex) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let cortexData = try encoder.encode(cortex)
        let cortexJSON = String(data: cortexData, encoding: .utf8)!

        let script = """
        import json
        from hive.models import MoxieDevice, PersistentData

        device = MoxieDevice.objects.filter(device_id='\(deviceId)').first()
        if device:
            persist, created = PersistentData.objects.get_or_create(
                device=device,
                defaults={'data': {}}
            )
            data = persist.data or {}
            data['frontal_cortex'] = \(cortexJSON)
            persist.data = data
            persist.save()
            print(json.dumps({'success': True}))
        else:
            print(json.dumps({'success': False, 'error': 'Device not found'}))
        """

        let result = try await dockerService.executePythonScript(script)
        print("🧠 Saved frontal cortex: \(result)")
    }

    /// Load the frontal cortex
    func loadFrontalCortex() async throws -> FrontalCortex? {
        let script = """
        import json
        from hive.models import MoxieDevice, PersistentData

        device = MoxieDevice.objects.filter(device_id='\(deviceId)').first()
        if device:
            persist = PersistentData.objects.filter(device=device).first()
            if persist and persist.data:
                cortex = persist.data.get('frontal_cortex')
                if cortex:
                    print(json.dumps(cortex))
                else:
                    print('null')
            else:
                print('null')
        else:
            print('null')
        """

        let result = try await dockerService.executePythonScript(script)

        // Check for null
        let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed == "null" || trimmed.isEmpty {
            return nil
        }

        guard let jsonData = result.data(using: .utf8) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let cortex = try decoder.decode(FrontalCortex.self, from: jsonData)

        return cortex
    }

    // MARK: - Query Memories

    /// Search memories based on query parameters
    func queryMemories(_ query: MemoryQuery) async throws -> [MemorySearchResult] {
        // Load all memories
        let allMemories = try await loadMemories()

        // Filter by time range
        var filtered = allMemories
        if let timeRange = query.timeRange {
            filtered = filtered.filter { memory in
                timeRange.contains(memory.timestamp)
            }
        }

        // Filter by memory types
        if !query.memoryTypes.isEmpty {
            filtered = filtered.filter { memory in
                query.memoryTypes.contains(memory.memoryType)
            }
        }

        // Filter by importance
        filtered = filtered.filter { $0.importance >= query.minImportance }

        // Calculate relevance and recency scores
        let now = Date()
        var results: [MemorySearchResult] = []

        for memory in filtered {
            // Calculate relevance score based on keywords
            let relevanceScore = calculateRelevanceScore(
                memory: memory,
                keywords: query.keywords
            )

            // Calculate recency score (exponential decay)
            let daysSince = now.timeIntervalSince(memory.timestamp) / 86400
            let recencyScore = exp(-daysSince / 30.0) // Decay over 30 days

            let result = MemorySearchResult(
                memory: memory,
                relevanceScore: relevanceScore,
                recencyScore: recencyScore
            )
            results.append(result)
        }

        // Sort by combined score
        results.sort { $0.combinedScore > $1.combinedScore }

        // Limit results
        return Array(results.prefix(query.limit))
    }

    private func calculateRelevanceScore(memory: ConversationMemory, keywords: [String]) -> Double {
        guard !keywords.isEmpty else { return 1.0 }

        let lowerContent = memory.content.lowercased()
        let lowerTopics = memory.topics.map { $0.lowercased() }
        let lowerEntities = memory.entities.map { $0.lowercased() }

        var matches = 0
        for keyword in keywords {
            let lowerKeyword = keyword.lowercased()

            if lowerContent.contains(lowerKeyword) {
                matches += 3 // Content match is most important
            }
            if lowerTopics.contains(lowerKeyword) {
                matches += 2 // Topic match
            }
            if lowerEntities.contains(lowerKeyword) {
                matches += 1 // Entity match
            }
        }

        // Normalize score
        let maxPossibleMatches = keywords.count * 3
        return Double(matches) / Double(maxPossibleMatches)
    }

    // MARK: - Context Generation

    /// Generate AI context from relevant memories
    func generateContextForAI(
        keywords: [String],
        limit: Int = 5
    ) async throws -> String {
        // Query relevant memories
        let query = MemoryQuery(
            keywords: keywords,
            timeRange: nil,
            memoryTypes: [],
            minImportance: 0.5,
            limit: limit
        )

        let results = try await queryMemories(query)

        guard !results.isEmpty else {
            return ""
        }

        var context = "## Relevant Past Conversations\n\n"

        for (index, result) in results.enumerated() {
            let memory = result.memory
            context += "\(index + 1). [\(memory.memoryType.rawValue)] \(memory.content)\n"

            if !memory.topics.isEmpty {
                context += "   Topics: \(memory.topics.joined(separator: ", "))\n"
            }

            // Add timestamp for context
            let formatter = RelativeDateTimeFormatter()
            let timeAgo = formatter.localizedString(for: memory.timestamp, relativeTo: Date())
            context += "   (\(timeAgo))\n\n"
        }

        return context
    }
}
