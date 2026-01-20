import Foundation

/// Service for managing child profile persistence and retrieval
@MainActor
final class ChildProfileService: ObservableObject {
    @Published var currentProfile: ChildProfile?

    private let dockerService: DockerServiceProtocol
    private let deviceId = "moxie_001"

    init(dockerService: DockerServiceProtocol? = nil) {
        self.dockerService = dockerService ?? DIContainer.shared.resolve(DockerServiceProtocol.self)
    }

    // MARK: - Load Active Profile (Synchronous)

    /// Load the currently active profile from UserDefaults or in-memory cache
    func loadActiveProfile() -> ChildProfile? {
        // First check in-memory cache
        if let profile = currentProfile {
            return profile
        }

        // Then check UserDefaults
        guard let data = UserDefaults.standard.data(forKey: "childProfile") else {
            return nil
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let profile = try decoder.decode(ChildProfile.self, from: data)
            currentProfile = profile
            return profile
        } catch {
            print("Failed to load child profile from UserDefaults: \(error)")
            return nil
        }
    }

    // MARK: - Load Profile

    /// Load the child profile from the database
    func loadProfile() async throws -> ChildProfile? {
        let script = """
        import json
        from hive.models import MoxieDevice, PersistentData

        device = MoxieDevice.objects.filter(device_id='\(deviceId)').first()
        if device:
            persist = PersistentData.objects.filter(device=device).first()
            if persist and persist.data:
                profile_data = persist.data.get('child_profile')
                if profile_data:
                    print(json.dumps(profile_data))
                else:
                    print('null')
            else:
                print('null')
        else:
            print('null')
        """

        let result = try await dockerService.executePythonScript(script)

        // Parse JSON response
        guard let jsonData = result.data(using: .utf8) else {
            return nil
        }

        // Check for null result
        let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed == "null" || trimmed.isEmpty {
            return nil
        }

        let profile = try JSONDecoder().decode(ChildProfile.self, from: jsonData)
        currentProfile = profile
        return profile
    }

    // MARK: - Save Profile

    /// Save or update the child profile in the database
    func saveProfile(_ profile: ChildProfile) async throws {
        // Update timestamp
        var updatedProfile = profile
        updatedProfile.updatedAt = Date()

        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let profileData = try encoder.encode(updatedProfile)
        let profileJSON = String(data: profileData, encoding: .utf8)!

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
            data['child_profile'] = \(profileJSON)
            persist.data = data
            persist.save()
            print(json.dumps({'success': True}))
        else:
            print(json.dumps({'success': False, 'error': 'Device not found'}))
        """

        let result = try await dockerService.executePythonScript(script)

        // Verify success
        guard let jsonData = result.data(using: .utf8),
              let response = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let success = response["success"] as? Bool,
              success else {
            throw NSError(domain: "ChildProfileService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to save profile"
            ])
        }

        currentProfile = updatedProfile

        // Also save to UserDefaults for synchronous access
        if let localData = try? encoder.encode(updatedProfile) {
            UserDefaults.standard.set(localData, forKey: "childProfile")
        }
    }

    // MARK: - Update Interests

    /// Extract and add interests from conversation content
    func extractAndAddInterests(from conversationText: String) async throws {
        guard var profile = currentProfile else { return }

        // Simple keyword extraction (can be enhanced with NLP)
        let keywords = extractKeywords(from: conversationText)

        // Add new interests (avoid duplicates)
        for keyword in keywords {
            if !profile.interests.contains(keyword) {
                profile.interests.append(keyword)
            }
        }

        // Save updated profile
        try await saveProfile(profile)
    }

    // MARK: - Private Helpers

    private func extractKeywords(from text: String) -> [String] {
        // Define interest categories
        let interestPatterns: [String: [String]] = [
            "animals": ["dog", "cat", "bird", "fish", "dinosaur", "animals", "pets"],
            "sports": ["soccer", "basketball", "football", "swimming", "tennis", "sports"],
            "art": ["drawing", "painting", "coloring", "art", "crafts"],
            "music": ["music", "singing", "piano", "guitar", "drums"],
            "science": ["space", "planets", "stars", "robots", "experiments", "science"],
            "reading": ["books", "reading", "stories"],
            "games": ["games", "puzzles", "lego", "blocks"],
            "nature": ["trees", "flowers", "plants", "garden", "nature"],
            "technology": ["computer", "iPad", "tablet", "coding", "programming"]
        ]

        var foundInterests: Set<String> = []
        let lowercasedText = text.lowercased()

        for (category, patterns) in interestPatterns {
            for pattern in patterns {
                if lowercasedText.contains(pattern) {
                    foundInterests.insert(category)
                    break
                }
            }
        }

        return Array(foundInterests)
    }

    // MARK: - Get Context for AI

    /// Get child profile context formatted for AI prompts
    func getContextForAI() -> String {
        guard let profile = currentProfile else {
            return ""
        }
        return profile.contextForAI
    }
}
