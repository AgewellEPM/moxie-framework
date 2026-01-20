import Foundation
import AppKit

/// Service for automatically installing and configuring dependencies
@MainActor
class DependencyInstallationService: ObservableObject {
    @Published var mosquittoInstalled = false
    @Published var mosquittoRunning = false
    @Published var dockerInstalled = false
    @Published var openMoxieConfigured = false

    @Published var installationProgress: String = ""
    @Published var isInstalling = false
    @Published var installationError: String?
    @Published var detectedIPAddress: String = ""
    @Published var installationLogs: [String] = []

    private let openMoxieDir: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("OpenMoxie")
    private let maxRetries = 3
    private let retryDelay: UInt64 = 3_000_000_000 // 3 seconds

    /// Add a log entry
    func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logEntry = "[\(timestamp)] \(message)"
        installationLogs.append(logEntry)
        installationProgress = message
        print(logEntry)
    }

    /// Clear logs
    func clearLogs() {
        installationLogs.removeAll()
    }

    // MARK: - IP Address Auto-Detection

    /// Auto-detect the local LAN IP address (e.g., 192.168.x.x)
    /// This is the IP that Moxie needs to connect to your computer
    func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0 else { return nil }
        defer { freeifaddrs(ifaddr) }

        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }

            guard let interface = ptr?.pointee else { continue }
            let addrFamily = interface.ifa_addr.pointee.sa_family

            // Check for IPv4
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)

                // Skip loopback and check for en0/en1 (WiFi/Ethernet)
                if name == "en0" || name == "en1" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(
                        interface.ifa_addr,
                        socklen_t(interface.ifa_addr.pointee.sa_len),
                        &hostname,
                        socklen_t(hostname.count),
                        nil,
                        socklen_t(0),
                        NI_NUMERICHOST
                    )
                    let ip = String(cString: hostname)

                    // Prefer private network addresses (192.168.x.x, 10.x.x.x, 172.x.x.x)
                    if ip.hasPrefix("192.168.") || ip.hasPrefix("10.") || ip.hasPrefix("172.") {
                        address = ip
                        break
                    }
                }
            }
        }

        if let detectedIP = address {
            detectedIPAddress = detectedIP
            print("✅ Auto-detected local IP: \(detectedIP)")
        }

        return address
    }

    /// Get the moxieEndpoint URL with auto-detected IP
    func getMoxieEndpoint() -> String {
        if let ip = getLocalIPAddress() {
            return "http://\(ip):8001/hive/endpoint/"
        }
        // Fallback to configured endpoint if IP detection fails
        return AppConfig.statusEndpoint
    }

    /// Configure OpenMoxie with the auto-detected IP address
    func configureOpenMoxieWithIP() async throws {
        guard let ip = getLocalIPAddress() else {
            print("⚠️ Could not detect local IP, using localhost")
            return
        }

        let endpoint = "http://\(ip):8001/hive/endpoint/"

        // Save to UserDefaults for the app
        UserDefaults.standard.set(endpoint, forKey: "moxieEndpoint")
        UserDefaults.standard.set(ip, forKey: "detectedIPAddress")

        // Update OpenMoxie container configuration if running
        let containerRunning = await checkDockerRunning()
        if containerRunning {
            let configScript = """
            cd ~/OpenMoxie && \(dockerComposePath) exec -T web python manage.py shell -c "
            import os
            os.environ['MOXIE_HOST'] = '\(ip)'
            os.environ['MOXIE_PORT'] = '8001'
            try:
                from hive.models import MoxieDevice, PersistentData
                device = MoxieDevice.objects.filter(device_id='moxie_001').first()
                if device:
                    persist, _ = PersistentData.objects.get_or_create(device=device, defaults={'data': {}})
                    data = persist.data or {}
                    data['endpoint_config'] = {'host': '\(ip)', 'port': 8001, 'url': '\(endpoint)'}
                    persist.data = data
                    persist.save()
                    print('Endpoint configured to: \(endpoint)')
            except Exception as e:
                print(f'Note: {e}')
            "
            """
            _ = await runShellCommand(configScript)
        }

        print("✅ Configured OpenMoxie endpoint: \(endpoint)")
    }

    // MARK: - Docker Path Detection

    /// Find Docker executable path by checking common locations
    var dockerPath: String {
        let possiblePaths = [
            "/usr/local/bin/docker",
            "/opt/homebrew/bin/docker",
            "/usr/bin/docker",
            "/Applications/Docker.app/Contents/Resources/bin/docker"
        ]

        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }

        return "docker" // Fallback
    }

    /// Find docker-compose executable path by checking common locations
    var dockerComposePath: String {
        let possiblePaths = [
            "/usr/local/bin/docker-compose",
            "/opt/homebrew/bin/docker-compose",
            "/usr/bin/docker-compose",
            "/Applications/Docker.app/Contents/Resources/bin/docker-compose"
        ]

        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }

        // Try docker compose (v2 syntax) as fallback
        return "\(dockerPath) compose"
    }

    // MARK: - Check Installation Status

    func checkMosquitto() async -> Bool {
        // Check if mosquitto is installed via Homebrew
        let result = await runShellCommand("/opt/homebrew/bin/brew list mosquitto")
        return result.success
    }

    func checkMosquittoRunning() async -> Bool {
        // Check if mosquitto service is running
        let result = await runShellCommand("/opt/homebrew/bin/brew services list")
        return result.output.contains("mosquitto") && result.output.contains("started")
    }

    func checkDocker() async -> Bool {
        // Check if Docker.app is installed
        let workspace = NSWorkspace.shared
        let hasDockerApp = workspace.urlForApplication(withBundleIdentifier: "com.docker.docker") != nil
            || FileManager.default.fileExists(atPath: "/Applications/Docker.app")

        if hasDockerApp {
            // Check specific known paths for Docker CLI (more reliable than 'which')
            let dockerPaths = [
                "/usr/local/bin/docker",
                "/opt/homebrew/bin/docker",
                "/usr/bin/docker",
                "/Applications/Docker.app/Contents/Resources/bin/docker"
            ]
            let hasDockerCLI = dockerPaths.contains { FileManager.default.fileExists(atPath: $0) }
            return hasDockerCLI
        }
        return false
    }

    func checkOpenMoxieContainer() async -> Bool {
        // Check if OpenMoxie container exists
        let result = await runShellCommand("\(dockerPath) ps -a --filter name=openmoxie --format '{{.Names}}'")
        return result.output.contains("openmoxie")
    }

    // MARK: - Install Mosquitto

    func installMosquitto() async throws {
        isInstalling = true
        installationError = nil
        installationProgress = "Checking for Homebrew..."

        // Check if Homebrew is installed
        let brewCheck = await runShellCommand("which brew")
        if !brewCheck.success {
            installationProgress = "Installing Homebrew..."
            try await installHomebrew()
        }

        installationProgress = "Installing Mosquitto via Homebrew..."
        let installResult = await runShellCommand("/opt/homebrew/bin/brew install mosquitto")

        guard installResult.success else {
            throw InstallationError.mosquittoInstallFailed(installResult.error)
        }

        mosquittoInstalled = true

        // Start Mosquitto service
        installationProgress = "Starting Mosquitto service..."
        let startResult = await runShellCommand("/opt/homebrew/bin/brew services start mosquitto")

        guard startResult.success else {
            throw InstallationError.mosquittoStartFailed(startResult.error)
        }

        mosquittoRunning = true
        installationProgress = "Mosquitto installed and running!"
        isInstalling = false
    }

    private func installHomebrew() async throws {
        // Download and install Homebrew
        let installScript = """
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        """

        let result = await runShellCommand(installScript)
        guard result.success else {
            throw InstallationError.homebrewInstallFailed(result.error)
        }
    }

    // MARK: - Setup OpenMoxie Container

    func setupOpenMoxieContainer(dbPassword: String = "moxiepass") async throws {
        isInstalling = true
        installationError = nil

        // Check Docker is running
        installationProgress = "Checking Docker status..."
        let dockerRunning = await checkDockerRunning()
        guard dockerRunning else {
            throw InstallationError.dockerNotRunning
        }

        // Check if container already exists
        let containerExists = await checkOpenMoxieContainer()
        if containerExists {
            installationProgress = "OpenMoxie container already exists. Starting it..."
            let startResult = await runShellCommand("\(dockerPath) start openmoxie")
            if startResult.success {
                openMoxieConfigured = true
                installationProgress = "OpenMoxie container started!"
                isInstalling = false
                return
            }
        }

        // Clone OpenMoxie repository and build from source
        installationProgress = "Setting up OpenMoxie from GitHub repository..."
        try await setupOpenMoxieFromGitHub(dbPassword: dbPassword)

        openMoxieConfigured = true
        installationProgress = "OpenMoxie container created and running!"
        isInstalling = false
    }

    private func setupOpenMoxieFromGitHub(dbPassword: String) async throws {
        log("Starting OpenMoxie setup...")

        // Check if OpenMoxie directory exists
        if !FileManager.default.fileExists(atPath: openMoxieDir.path) {
            log("Creating OpenMoxie directory...")
            try FileManager.default.createDirectory(at: openMoxieDir, withIntermediateDirectories: true)

            // Create docker-compose.yml
            log("Creating docker-compose configuration...")
            let dockerCompose = """
            services:
              openmoxie-server:
                image: openmoxie/openmoxie-server:latest
                container_name: openmoxie-server
                ports:
                  - "8001:8000"
                volumes:
                  - ./local:/app/local
                restart: unless-stopped
                depends_on:
                  - mqtt
                networks:
                  - openmoxie

              mqtt:
                image: openmoxie/openmoxie-mqtt:latest
                container_name: openmoxie-mqtt
                ports:
                  - "1883:1883"
                  - "8883:8883"
                restart: unless-stopped
                networks:
                  - openmoxie

            networks:
              openmoxie:
                driver: bridge
            """
            let composeFile = openMoxieDir.appendingPathComponent("docker-compose.yml")
            try dockerCompose.write(to: composeFile, atomically: true, encoding: .utf8)
        }

        // Pull images with retry
        log("Pulling OpenMoxie Docker images (this may take a few minutes)...")
        let pullResult = await runShellCommandWithRetry(
            "cd \(openMoxieDir.path) && \(dockerComposePath) pull",
            description: "Pull Docker images"
        )
        if !pullResult.success {
            log("Warning: Could not pull images - will try to use cached versions")
        } else {
            log("Images pulled successfully!")
        }

        // Start containers with retry
        log("Starting OpenMoxie containers...")
        let upResult = await runShellCommandWithRetry(
            "cd \(openMoxieDir.path) && \(dockerComposePath) up -d",
            description: "Start containers"
        )
        if !upResult.success {
            log("Error starting containers: \(upResult.error)")
            throw InstallationError.containerSetupFailed(upResult.error)
        }
        log("Containers started successfully!")

        // Wait for server to be ready
        log("Waiting for OpenMoxie server to start...")
        for i in 1...15 {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            let checkResult = await runShellCommand("curl -s \(AppConfig.setupEndpoint)")
            if checkResult.success && !checkResult.output.isEmpty {
                log("Server is ready!")
                break
            }
            log("Waiting... (\(i * 2)s)")
        }

        // Auto-configure with detected IP
        log("Auto-configuring OpenMoxie with your IP address...")
        try await configureHiveSetup()

        openMoxieConfigured = true
        log("OpenMoxie setup complete!")
    }

    /// Configure the hive setup page with auto-detected IP and API key
    func configureHiveSetup(apiKey: String = "") async throws {
        guard let ip = getLocalIPAddress() else {
            log("Warning: Could not detect IP address")
            return
        }

        log("Detected IP: \(ip)")

        // Get CSRF token first
        log("Getting CSRF token...")
        let csrfResult = await runShellCommand("curl -s -c /tmp/moxie_cookies.txt \(AppConfig.setupEndpoint)")

        // Extract CSRF token from the page
        var csrfToken = ""
        if let range = csrfResult.output.range(of: "csrfmiddlewaretoken\" value=\"") {
            let start = csrfResult.output[range.upperBound...]
            if let endRange = start.range(of: "\"") {
                csrfToken = String(start[..<endRange.lowerBound])
            }
        }

        if csrfToken.isEmpty {
            log("Warning: Could not get CSRF token, trying direct configuration...")
        }

        // Submit the configuration form
        log("Configuring hostname to: \(ip)")
        let configCommand = """
        curl -s -X POST \(AppConfig.setupEndpoint) \
            -b /tmp/moxie_cookies.txt \
            -d "csrfmiddlewaretoken=\(csrfToken)" \
            -d "openai_api_key=\(apiKey)" \
            -d "hostname=\(ip)"
        """
        let configResult = await runShellCommand(configCommand)

        if configResult.success {
            log("Configuration submitted successfully!")
        } else {
            log("Warning: Configuration may not have applied: \(configResult.error)")
        }

        // Save to UserDefaults
        let endpoint = "http://\(ip):8001/hive/endpoint/"
        UserDefaults.standard.set(endpoint, forKey: "moxieEndpoint")
        UserDefaults.standard.set(ip, forKey: "detectedIPAddress")
        log("Saved endpoint: \(endpoint)")
    }

    private func checkDockerRunning() async -> Bool {
        let result = await runShellCommand("\(dockerPath) info")
        return result.success
    }

    // MARK: - Retry Logic

    /// Run a shell command with automatic retry on failure
    private func runShellCommandWithRetry(_ command: String, description: String, maxAttempts: Int? = nil) async -> ShellResult {
        let attempts = maxAttempts ?? maxRetries

        for attempt in 1...attempts {
            let result = await runShellCommand(command)

            if result.success {
                return result
            }

            if attempt < attempts {
                log("Attempt \(attempt)/\(attempts) failed for: \(description)")
                log("Retrying in 3 seconds...")
                try? await Task.sleep(nanoseconds: retryDelay)
            } else {
                log("All \(attempts) attempts failed for: \(description)")
            }
        }

        return await runShellCommand(command) // Return last attempt result
    }

    /// Check if a container is healthy (running and responding)
    func isContainerHealthy(_ containerName: String) async -> Bool {
        let statusResult = await runShellCommand("\(dockerPath) inspect --format='{{.State.Status}}' \(containerName)")
        guard statusResult.success && statusResult.output.trimmingCharacters(in: .whitespacesAndNewlines) == "running" else {
            return false
        }

        // Additional health check for server
        if containerName == "openmoxie-server" {
            let healthResult = await runShellCommand("curl -s --max-time 5 \(AppConfig.healthEndpoint) || echo 'fail'")
            return !healthResult.output.contains("fail")
        }

        return true
    }

    /// Restart a container if it's unhealthy
    func ensureContainerHealthy(_ containerName: String) async -> Bool {
        if await isContainerHealthy(containerName) {
            return true
        }

        log("Container \(containerName) is unhealthy, attempting restart...")

        // Try to start the container
        let startResult = await runShellCommand("\(dockerPath) start \(containerName)")
        if !startResult.success {
            log("Failed to start \(containerName): \(startResult.error)")
            return false
        }

        // Wait and check health
        for _ in 1...5 {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if await isContainerHealthy(containerName) {
                log("Container \(containerName) is now healthy!")
                return true
            }
        }

        return false
    }

    // MARK: - Shell Command Execution

    private func runShellCommand(_ command: String) async -> ShellResult {
        await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = ["-c", command]

            let outputPipe = Pipe()
            let errorPipe = Pipe()

            process.standardOutput = outputPipe
            process.standardError = errorPipe

            do {
                try process.run()
                process.waitUntilExit()

                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

                let output = String(data: outputData, encoding: .utf8) ?? ""
                let error = String(data: errorData, encoding: .utf8) ?? ""

                let result = ShellResult(
                    success: process.terminationStatus == 0,
                    output: output,
                    error: error
                )

                continuation.resume(returning: result)
            } catch {
                continuation.resume(returning: ShellResult(
                    success: false,
                    output: "",
                    error: error.localizedDescription
                ))
            }
        }
    }

    // MARK: - Complete Setup

    func runCompleteSetup() async {
        do {
            // Step 1: Check and install Mosquitto
            installationProgress = "Checking Mosquitto..."
            let hasMosquitto = await checkMosquitto()

            if !hasMosquitto {
                installationProgress = "Installing Mosquitto..."
                try await installMosquitto()
            } else {
                mosquittoInstalled = true

                // Check if running, start if not
                let isRunning = await checkMosquittoRunning()
                if !isRunning {
                    installationProgress = "Starting Mosquitto..."
                    _ = await runShellCommand("/opt/homebrew/bin/brew services start mosquitto")
                }
                mosquittoRunning = true
            }

            // Step 2: Check Docker
            installationProgress = "Checking Docker..."
            let hasDocker = await checkDocker()

            if !hasDocker {
                installationError = "Docker is not installed. Please install Docker Desktop first."
                isInstalling = false
                return
            }
            dockerInstalled = true

            // Step 3: Setup OpenMoxie
            installationProgress = "Setting up OpenMoxie..."
            try await setupOpenMoxieContainer()

            // Step 4: Auto-configure IP address
            installationProgress = "Configuring network settings..."
            try await configureOpenMoxieWithIP()

            installationProgress = "Setup complete! All dependencies installed."

        } catch {
            installationError = error.localizedDescription
            installationProgress = "Setup failed: \(error.localizedDescription)"
        }

        isInstalling = false
    }

    /// Start Docker Desktop if not running
    func startDockerDesktop() async {
        log("Starting Docker Desktop...")
        installationProgress = "Starting Docker Desktop..."

        // Use shell command - much more reliable than NSWorkspace API
        let openResult = await runShellCommand("open -a Docker")
        if !openResult.success {
            log("Failed to launch Docker: \(openResult.error)")
            installationError = "Failed to launch Docker Desktop. Please start it manually."
            return
        }

        log("Docker launch command sent, waiting for Docker to start...")

        // Wait for Docker to start (up to 60 seconds)
        for i in 1...30 {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            let isRunning = await checkDockerRunning()
            if isRunning {
                log("Docker is now running!")
                installationProgress = "Docker is running!"
                return
            }
            installationProgress = "Waiting for Docker to start... (\(i * 2)s)"
            log("Waiting for Docker... (\(i * 2)s)")
        }

        log("Docker failed to start after 60 seconds")
        installationError = "Docker failed to start. Please start Docker Desktop manually."
    }

    /// Open Docker Desktop download page
    func downloadDocker() {
        if let url = URL(string: "https://www.docker.com/products/docker-desktop/") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Supporting Types

struct ShellResult {
    let success: Bool
    let output: String
    let error: String
}

enum InstallationError: LocalizedError {
    case homebrewInstallFailed(String)
    case mosquittoInstallFailed(String)
    case mosquittoStartFailed(String)
    case dockerNotRunning
    case containerSetupFailed(String)
    case imageBuildFailed(String)
    case gitCloneFailed(String)
    case bundledOpenMoxieNotFound

    var errorDescription: String? {
        switch self {
        case .homebrewInstallFailed(let details):
            return "Failed to install Homebrew: \(details)"
        case .mosquittoInstallFailed(let details):
            return "Failed to install Mosquitto: \(details)"
        case .mosquittoStartFailed(let details):
            return "Failed to start Mosquitto service: \(details)"
        case .dockerNotRunning:
            return "Docker is not running. Please start Docker Desktop and try again."
        case .containerSetupFailed(let details):
            return "Failed to setup OpenMoxie container: \(details)"
        case .imageBuildFailed(let details):
            return "Failed to build Docker image: \(details)"
        case .gitCloneFailed(let details):
            return "Failed to clone OpenMoxie repository: \(details)"
        case .bundledOpenMoxieNotFound:
            return "OpenMoxie backend not found. Please ensure the OpenMoxie folder is in the same directory as SimpleMoxieSwitcher.app"
        }
    }
}
