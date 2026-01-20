//
//  SetupManager.swift
//  SimpleMoxieSwitcherApp
//
//  Manages the setup state for Docker and OpenMoxie
//

import SwiftUI
import AppKit
import Network

enum SetupStep: Int, CaseIterable {
    case welcome = 0
    case dockerInstall = 1
    case dockerRunning = 2
    case openMoxieSetup = 3
    case apiConfiguration = 4
    case moxieConnection = 5
    case complete = 6

    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .dockerInstall: return "Install Docker"
        case .dockerRunning: return "Start Docker"
        case .openMoxieSetup: return "Setup OpenMoxie"
        case .apiConfiguration: return "API Keys"
        case .moxieConnection: return "Connect Moxie"
        case .complete: return "All Done!"
        }
    }

    var description: String {
        switch self {
        case .welcome: return "Let's get your Moxie robot set up with OpenMoxie!"
        case .dockerInstall: return "Docker helps run the OpenMoxie server on your computer."
        case .dockerRunning: return "Docker needs to be running before we can continue."
        case .openMoxieSetup: return "Now we'll download and set up the OpenMoxie server."
        case .apiConfiguration: return "OpenMoxie needs an API key to power conversations."
        case .moxieConnection: return "Connect your Moxie robot to OpenMoxie."
        case .complete: return "Your Moxie is ready to go!"
        }
    }

    var icon: String {
        switch self {
        case .welcome: return "hand.wave.fill"
        case .dockerInstall: return "shippingbox.fill"
        case .dockerRunning: return "play.circle.fill"
        case .openMoxieSetup: return "server.rack"
        case .apiConfiguration: return "key.fill"
        case .moxieConnection: return "antenna.radiowaves.left.and.right"
        case .complete: return "checkmark.circle.fill"
        }
    }
}

@MainActor
class SetupManager: ObservableObject {
    @Published var currentStep: SetupStep = .welcome
    @Published var isLoading = false
    @Published var statusMessage = ""
    @Published var errorMessage: String?

    // Setup state
    @Published var isDockerInstalled = false
    @Published var isDockerRunning = false
    @Published var isOpenMoxieInstalled = false
    @Published var isOpenMoxieRunning = false
    @Published var isConfigured = false

    // Configuration values
    @Published var openAIApiKey = ""
    @Published var googleServiceKey = ""
    @Published var localIPAddress = ""

    // Docker path - detected once and reused
    private var dockerPath: String?

    // Timer for polling Docker status
    private var dockerCheckTimer: Timer?

    // Computed property
    var setupComplete: Bool {
        isDockerInstalled && isDockerRunning && isOpenMoxieRunning && isConfigured
    }

    init() {
        // Auto-detect the local IP address
        localIPAddress = getLocalIPAddress() ?? "localhost"
    }

    deinit {
        dockerCheckTimer?.invalidate()
    }

    // MARK: - IP Address Detection

    func getLocalIPAddress() -> String? {
        var addresses: [String] = []

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }

        defer { freeifaddrs(ifaddr) }

        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family

            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                // Skip loopback interface
                if name == "lo0" { continue }

                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                           &hostname, socklen_t(hostname.count),
                           nil, socklen_t(0), NI_NUMERICHOST)
                let address = String(cString: hostname)

                // Prefer en0 (WiFi) or en1 (Ethernet)
                if name == "en0" || name == "en1" {
                    return address
                }
                addresses.append(address)
            }
        }

        // Return first non-loopback address if en0/en1 not found
        return addresses.first
    }

    // MARK: - Docker Detection

    func checkDockerInstalled() async -> Bool {
        let paths = [
            "/usr/local/bin/docker",
            "/opt/homebrew/bin/docker",
            "/Applications/Docker.app/Contents/Resources/bin/docker"
        ]

        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                isDockerInstalled = true
                return true
            }
        }

        // Also try which command
        let result = await runCommand("/usr/bin/which", arguments: ["docker"])
        isDockerInstalled = result.success && !result.output.isEmpty
        return isDockerInstalled
    }

    func checkDockerRunning() async -> Bool {
        // Quick check: Is Docker.app running as a process?
        let runningApps = NSWorkspace.shared.runningApplications
        let dockerAppRunning = runningApps.contains { $0.bundleIdentifier == "com.docker.docker" }

        if !dockerAppRunning {
            isDockerRunning = false
            return false
        }

        // Docker app is running - now verify the daemon is responding
        // Try to connect to Docker's API via HTTP to check if it's ready
        // This works even in sandboxed apps

        // First try shell command approach
        let paths = [
            "/usr/local/bin/docker",
            "/opt/homebrew/bin/docker",
            "/Applications/Docker.app/Contents/Resources/bin/docker"
        ]

        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                let result = await runCommand(path, arguments: ["version"])
                if result.success {
                    isDockerRunning = true
                    return true
                }
            }
        }

        // If shell commands don't work (sandboxed), check if Docker socket exists
        // and assume Docker is ready if the app is running for more than a few seconds
        let socketPaths = [
            "/var/run/docker.sock",
            "\(NSHomeDirectory())/Library/Containers/com.docker.docker/Data/docker.raw.sock"
        ]

        for socketPath in socketPaths {
            if FileManager.default.fileExists(atPath: socketPath) {
                // Socket exists and Docker app is running - assume it's ready
                isDockerRunning = true
                return true
            }
        }

        // Docker app is running but daemon might still be starting
        // Be optimistic - if the app has been running, it's probably ready
        isDockerRunning = true
        return true
    }

    func checkOpenMoxieStatus() async -> (installed: Bool, running: Bool) {
        // Check if container exists
        let existsResult = await runDockerCommand(["ps", "-a", "--filter", "name=openmoxie-server", "--format", "{{.Names}}"])
        isOpenMoxieInstalled = existsResult.output.contains("openmoxie-server")

        // Check if running
        let runningResult = await runDockerCommand(["ps", "--filter", "name=openmoxie-server", "--filter", "status=running", "--format", "{{.Names}}"])
        isOpenMoxieRunning = runningResult.output.contains("openmoxie-server")

        return (isOpenMoxieInstalled, isOpenMoxieRunning)
    }

    // MARK: - Docker Status Polling

    func startDockerPolling() {
        dockerCheckTimer?.invalidate()
        dockerCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let wasRunning = self.isDockerRunning
                _ = await self.checkDockerRunning()

                // Auto-advance if Docker just started running
                if !wasRunning && self.isDockerRunning && self.currentStep == .dockerRunning {
                    self.stopDockerPolling()
                    self.currentStep = .openMoxieSetup
                }
            }
        }
    }

    func stopDockerPolling() {
        dockerCheckTimer?.invalidate()
        dockerCheckTimer = nil
    }

    // MARK: - Setup Actions

    func openDockerDownload() {
        if let url = URL(string: "https://www.docker.com/products/docker-desktop/") {
            NSWorkspace.shared.open(url)
        }
    }

    func openDockerApp() {
        if let dockerURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.docker.docker") {
            NSWorkspace.shared.openApplication(at: dockerURL, configuration: NSWorkspace.OpenConfiguration())
        }
        // Start polling for Docker to come up
        startDockerPolling()
    }

    func startOpenMoxie() async {
        isLoading = true
        statusMessage = "Starting OpenMoxie server..."
        errorMessage = nil

        // Check if already running
        let (installed, running) = await checkOpenMoxieStatus()

        if running {
            statusMessage = "OpenMoxie is already running!"
            isLoading = false
            // Auto-advance
            currentStep = .apiConfiguration
            return
        }

        if installed {
            // Just start existing container
            statusMessage = "Starting OpenMoxie container..."
            let result = await runDockerCommand(["start", "openmoxie-server"])
            if result.success {
                // Wait for container to be ready
                statusMessage = "Waiting for OpenMoxie to start..."
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                isOpenMoxieRunning = true
                statusMessage = "OpenMoxie started successfully!"

                // Check if already configured
                await checkIfConfigured()

                // Auto-advance
                if isConfigured {
                    currentStep = .moxieConnection
                } else {
                    currentStep = .apiConfiguration
                }
            } else {
                errorMessage = "Failed to start OpenMoxie: \(result.output)"
            }
        } else {
            // Need to pull and run
            statusMessage = "Downloading OpenMoxie (this may take a few minutes)..."

            // Pull the image
            let pullResult = await runDockerCommand(["pull", "ghcr.io/openmoxie/openmoxie:latest"])
            if !pullResult.success {
                errorMessage = "Failed to download OpenMoxie: \(pullResult.output)"
                isLoading = false
                return
            }

            statusMessage = "Creating OpenMoxie container..."

            // Run the container with our auto-detected IP
            let runArgs = [
                "run", "-d",
                "--name", "openmoxie-server",
                "-p", "8001:8001",
                "-p", "8883:8883",
                "-v", "openmoxie-data:/app/data",
                "-e", "MOXIE_HOSTNAME=\(localIPAddress)",
                "ghcr.io/openmoxie/openmoxie:latest"
            ]

            let runResult = await runDockerCommand(runArgs)
            if runResult.success {
                statusMessage = "OpenMoxie installed! Waiting for it to start..."
                isOpenMoxieInstalled = true

                // Wait for container to be ready
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                isOpenMoxieRunning = true

                statusMessage = "OpenMoxie is ready!"
                currentStep = .apiConfiguration
            } else {
                errorMessage = "Failed to start OpenMoxie: \(runResult.output)"
            }
        }

        isLoading = false
    }

    func stopOpenMoxie() async {
        isLoading = true
        statusMessage = "Stopping OpenMoxie..."

        let result = await runDockerCommand(["stop", "openmoxie-server"])
        if result.success {
            isOpenMoxieRunning = false
            statusMessage = "OpenMoxie stopped"
        } else {
            errorMessage = "Failed to stop: \(result.output)"
        }

        isLoading = false
    }

    func restartOpenMoxie() async {
        isLoading = true
        statusMessage = "Restarting OpenMoxie..."

        let result = await runDockerCommand(["restart", "openmoxie-server"])
        if result.success {
            statusMessage = "OpenMoxie restarted!"
            // Wait a bit for it to come up
            try? await Task.sleep(nanoseconds: 3_000_000_000)
        } else {
            errorMessage = "Failed to restart: \(result.output)"
        }

        isLoading = false
    }

    // MARK: - Configuration

    func checkIfConfigured() async {
        do {
            let (_, response) = try await URLSession.shared.data(from: URL(string: "http://localhost:8001/hive/")!)
            if let httpResponse = response as? HTTPURLResponse {
                // If we get redirected to setup, not configured
                isConfigured = httpResponse.url?.path != "/hive/setup"
            }
        } catch {
            isConfigured = false
        }
    }

    func submitConfiguration() async -> Bool {
        isLoading = true
        statusMessage = "Saving configuration..."
        errorMessage = nil

        guard let setupURL = URL(string: "http://localhost:8001/hive/setup") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return false
        }

        do {
            // First, get the setup page to get CSRF token
            let (data, _) = try await URLSession.shared.data(from: setupURL)
            guard let html = String(data: data, encoding: .utf8) else {
                throw NSError(domain: "Setup", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load setup page"])
            }

            // Extract CSRF token
            var csrfToken = ""
            if let range = html.range(of: "name=\"csrfmiddlewaretoken\" value=\"") {
                let startIndex = range.upperBound
                if let endRange = html[startIndex...].range(of: "\"") {
                    csrfToken = String(html[startIndex..<endRange.lowerBound])
                }
            }

            // Now submit the form with the LOCAL IP ADDRESS (not hostname!)
            var request = URLRequest(url: setupURL)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.setValue("http://localhost:8001/hive/setup", forHTTPHeaderField: "Referer")

            var formData = [
                "csrfmiddlewaretoken": csrfToken,
                "openai_api_key": openAIApiKey,
                "hostname": localIPAddress  // USE THE IP ADDRESS!
            ]

            if !googleServiceKey.isEmpty {
                formData["google_service_key"] = googleServiceKey
            }

            let bodyString = formData.map { key, value in
                let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
                let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
                return "\(encodedKey)=\(encodedValue)"
            }.joined(separator: "&")

            request.httpBody = bodyString.data(using: .utf8)

            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               (200...399).contains(httpResponse.statusCode) {
                isConfigured = true
                statusMessage = "Configuration saved!"
                isLoading = false

                // Restart OpenMoxie to apply config
                statusMessage = "Restarting OpenMoxie to apply settings..."
                await restartOpenMoxie()

                return true
            } else {
                throw NSError(domain: "Setup", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to save configuration"])
            }
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func openSetupInBrowser() {
        if let url = URL(string: "http://localhost:8001/hive/setup") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Full Status Check

    func performFullCheck() async {
        isLoading = true
        statusMessage = "Checking system status..."

        // Refresh IP address
        localIPAddress = getLocalIPAddress() ?? "localhost"

        // Check Docker installed
        _ = await checkDockerInstalled()

        if isDockerInstalled {
            // Check Docker running
            _ = await checkDockerRunning()

            if isDockerRunning {
                // Check OpenMoxie
                _ = await checkOpenMoxieStatus()

                if isOpenMoxieRunning {
                    await checkIfConfigured()
                }
            }
        }

        // Determine current step based on state
        updateCurrentStep()

        isLoading = false
        statusMessage = ""
    }

    func updateCurrentStep() {
        if !isDockerInstalled {
            currentStep = .dockerInstall
        } else if !isDockerRunning {
            currentStep = .dockerRunning
            // Start polling for Docker
            startDockerPolling()
        } else if !isOpenMoxieRunning {
            stopDockerPolling()
            currentStep = .openMoxieSetup
        } else if !isConfigured {
            stopDockerPolling()
            currentStep = .apiConfiguration
        } else {
            stopDockerPolling()
            currentStep = .complete
        }
    }

    // MARK: - Helpers

    private func runCommand(_ path: String, arguments: [String]) async -> (success: Bool, output: String) {
        await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: path)
            process.arguments = arguments

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            do {
                try process.run()
                process.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""

                continuation.resume(returning: (process.terminationStatus == 0, output.trimmingCharacters(in: .whitespacesAndNewlines)))
            } catch {
                continuation.resume(returning: (false, error.localizedDescription))
            }
        }
    }

    private func runDockerCommand(_ arguments: [String]) async -> (success: Bool, output: String) {
        // Try multiple docker paths
        let paths = [
            "/usr/local/bin/docker",
            "/opt/homebrew/bin/docker",
            "/Applications/Docker.app/Contents/Resources/bin/docker"
        ]

        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return await runCommand(path, arguments: arguments)
            }
        }

        // Fall back to /usr/bin/env docker
        return await runCommand("/usr/bin/env", arguments: ["docker"] + arguments)
    }
}
