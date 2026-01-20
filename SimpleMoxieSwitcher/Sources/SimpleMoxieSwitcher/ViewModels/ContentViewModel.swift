import Foundation
import SwiftUI

@MainActor
final class ContentViewModel: ObservableObject {
    @Published var isUpdating = false
    @Published var statusMessage: String?
    @Published var allPersonalities: [Personality] = []
    @Published var showCustomCreator = false
    @Published var showAppearance = false
    @Published var showConversations = false
    @Published var showSettings = false
    @Published var editingPersonality: Personality?
    @Published var showPersonalityEditor = false
    @Published var showChat = false
    @Published var showStoryTime = false
    @Published var showLearning = false
    @Published var showLanguage = false
    @Published var showMusic = false
    @Published var showSmartHome = false
    @Published var showPuppetMode = false
    @Published var showLyricMode = false
    @Published var showChildProfile = false
    @Published var showGames = false
    @Published var showDocumentation = false
    @Published var showModelSelector = false
    @Published var selectedPersonalityForChat: Personality?
    @Published var showSetupWizard = false
    @Published var isStartingDocker = false
    @Published var isOnline: Bool = false
    @Published var onlineTime: Date?
    @Published var learningTiles: [LearningTile] = []
    @Published var storyTiles: [StoryTile] = []

    private let personalityService: PersonalityServiceProtocol
    private let personalityRepository: PersonalityRepositoryProtocol
    private let tileRepository: TileRepositoryProtocol
    private var statusCheckTimer: Timer?

    init(personalityService: PersonalityServiceProtocol, personalityRepository: PersonalityRepositoryProtocol, tileRepository: TileRepositoryProtocol) {
        self.personalityService = personalityService
        self.personalityRepository = personalityRepository
        self.tileRepository = tileRepository
        loadPersonalities()
        loadTiles()
        checkFirstLaunch()
        startStatusMonitoring()
    }

    func checkFirstLaunch() {
        let hasCompletedSetup = UserDefaults.standard.bool(forKey: "hasCompletedSetup")
        if !hasCompletedSetup {
            showSetupWizard = true
        }
    }

    func startStatusMonitoring() {
        // Check status immediately
        Task {
            await checkMoxieStatus()
        }

        // Then check every 5 seconds
        statusCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkMoxieStatus()
            }
        }
    }

    func checkMoxieStatus() async {
        let endpoint = UserDefaults.standard.string(forKey: "moxieEndpoint") ?? AppConfig.statusEndpoint

        guard let url = URL(string: endpoint) else {
            isOnline = false
            onlineTime = nil
            return
        }

        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if !isOnline {
                    // Just came online
                    onlineTime = Date()
                }
                isOnline = true
            } else {
                isOnline = false
                onlineTime = nil
            }
        } catch {
            isOnline = false
            onlineTime = nil
        }
    }

    deinit {
        statusCheckTimer?.invalidate()
    }

    func loadPersonalities() {
        let savedPersonalities = personalityRepository.loadPersonalities()
        allPersonalities = Personality.allPersonalities + savedPersonalities
        print("[ContentViewModel] Loaded \(allPersonalities.count) personalities: \(allPersonalities.map { $0.name })")
    }

    func loadTiles() {
        learningTiles = tileRepository.loadLearningTiles()
        storyTiles = tileRepository.loadStoryTiles()
    }

    func switchPersonality(_ personality: Personality) async {
        print("[ContentViewModel] switchPersonality called for: \(personality.name)")
        isUpdating = true
        statusMessage = "Switching to \(personality.name)..."

        do {
            print("[ContentViewModel] Calling personalityService...")
            try await personalityService.switchPersonality(personality)
            print("[ContentViewModel] Service call completed")
            statusMessage = "✅ SUCCESS! Moxie is now \(personality.emoji) \(personality.name)!"

            // Clear status after delay
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            statusMessage = nil
        } catch {
            statusMessage = "❌ Error: \(error.localizedDescription)"
        }

        isUpdating = false
    }

    func editPersonality(_ personality: Personality) {
        editingPersonality = personality
        showPersonalityEditor = true
    }

    func openChat(for personality: Personality) {
        selectedPersonalityForChat = personality
        showChat = true
    }

    /// Find Docker executable path
    private var dockerPath: String {
        let paths = [
            "/usr/local/bin/docker",
            "/opt/homebrew/bin/docker",
            "/usr/bin/docker",
            "/Applications/Docker.app/Contents/Resources/bin/docker"
        ]
        return paths.first { FileManager.default.fileExists(atPath: $0) } ?? "docker"
    }

    /// Find docker-compose executable path
    private var dockerComposePath: String {
        let paths = [
            "/usr/local/bin/docker-compose",
            "/opt/homebrew/bin/docker-compose",
            "/usr/bin/docker-compose",
            "/Applications/Docker.app/Contents/Resources/bin/docker-compose"
        ]
        if let found = paths.first(where: { FileManager.default.fileExists(atPath: $0) }) {
            return found
        }
        // Fallback to docker compose (v2 syntax)
        return "\(dockerPath) compose"
    }

    func startDockerContainer() async {
        isStartingDocker = true
        statusMessage = "Starting OpenMoxie containers..."

        let openMoxieDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("OpenMoxie").path
        let docker = dockerPath
        let compose = dockerComposePath

        // Try to start existing containers first, otherwise use docker-compose
        let script = """
        # Try starting existing containers first
        if \(docker) start openmoxie-server openmoxie-mqtt 2>/dev/null; then
            echo "Started existing containers"
            exit 0
        fi

        # If that fails, try docker-compose in OpenMoxie directory
        if [ -d "\(openMoxieDir)" ] && [ -f "\(openMoxieDir)/docker-compose.yml" ]; then
            cd "\(openMoxieDir)" && \(compose) up -d
            exit $?
        fi

        # Last resort: pull and run the images directly
        \(docker) network create openmoxie-net 2>/dev/null || true

        \(docker) run -d --name openmoxie-mqtt \
          --network openmoxie-net \
          -p 1883:1883 \
          -p 8883:8883 \
          openmoxie/openmoxie-mqtt:latest

        \(docker) run -d --name openmoxie-server \
          --network openmoxie-net \
          -p 8001:8000 \
          openmoxie/openmoxie-server:latest
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", script]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            if process.terminationStatus == 0 {
                statusMessage = "✅ OpenMoxie containers started!"
                // Check status immediately
                await checkMoxieStatus()
            } else {
                statusMessage = "❌ Failed to start Docker: \(output)"
            }
        } catch {
            statusMessage = "❌ Error starting Docker: \(error.localizedDescription)"
        }

        // Clear status after delay
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        statusMessage = nil
        isStartingDocker = false
    }
}