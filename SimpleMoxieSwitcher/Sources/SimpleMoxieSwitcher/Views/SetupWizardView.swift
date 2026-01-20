import SwiftUI
import AppKit
import CoreImage.CIFilterBuiltins
import CoreWLAN

struct SetupWizardView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentStep = 0
    @State private var dockerInstalled = false
    @State private var isChecking = false
    @State private var checkStatus = ""
    @State private var canContinue = false
    @State private var wifiSSID: String = UserDefaults.standard.string(forKey: "wifiSSID") ?? ""
    @State private var wifiPassword: String = UserDefaults.standard.string(forKey: "wifiPassword") ?? ""
    @State private var wifiEncryption: String = UserDefaults.standard.string(forKey: "wifiEncryption") ?? "WPA"
    @State private var moxieEndpoint: String = ""
    @State private var openAIKey: String = ""
    @State private var showingApiKey = false
    @StateObject private var providerManager = AIProviderManager()
    @StateObject private var installService = DependencyInstallationService()
    @State private var pinCreateStep = 0
    @State private var createPIN = ""
    @State private var confirmPIN = ""
    @State private var securityQuestion = ""
    @State private var securityAnswer = ""
    @State private var parentEmail = ""
    @State private var isStartingDocker = false
    private let pinService = PINService()

    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.08),
                    Color(red: 0.08, green: 0.08, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.1), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                }

                // Header
                VStack(spacing: 16) {
                    Text("Welcome to OpenMoxie")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    Text("Let's set up everything you need")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 0)

                // Progress indicator (4 steps now)
                HStack(spacing: 12) {
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(index <= currentStep ? Color.blue : Color.white.opacity(0.3))
                            .frame(width: 12, height: 12)
                    }
                }
                .padding(.vertical, 20)

                // Content based on current step (streamlined to 4 steps)
                Group {
                    if currentStep == 0 {
                        welcomeAndDockerStep  // Combined welcome + Docker auto-setup
                    } else if currentStep == 1 {
                        pinSetupStep  // Security setup
                    } else if currentStep == 2 {
                        robotPairingStep  // Combined WiFi + Network QR
                    } else {
                        completionStep  // Done
                    }
                }
                .frame(maxWidth: 600)
                .padding(.horizontal, 40)

                Spacer()

                // Navigation buttons
                HStack(spacing: 20) {
                    if currentStep > 0 {
                        Button(action: {
                            withAnimation {
                                currentStep -= 1
                            }
                        }) {
                            Text("Back")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    // Skip button (show on steps 1 and 2 only - PIN and pairing can be skipped)
                    if currentStep == 1 || currentStep == 2 {
                        Button(action: {
                            withAnimation {
                                currentStep += 1
                            }
                        }) {
                            Text("Skip")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                    }

                    Button(action: {
                        if currentStep == 3 {
                            // Mark setup as complete
                            UserDefaults.standard.set(true, forKey: "hasCompletedSetup")
                            dismiss()
                        } else {
                            // Save PIN when moving from PIN setup step (only if filled)
                            if currentStep == 1 && canContinuePIN() {
                                savePINSettings()
                            }
                            withAnimation {
                                currentStep += 1
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text(currentStep == 3 ? "Get Started" : "Continue")
                                .font(.headline)
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(
                            (currentStep == 1 && !canContinuePIN()) ?
                                LinearGradient(colors: [.gray, .gray.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(currentStep == 1 && !canContinuePIN())
                }
                .padding(.bottom, 30)
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .preferredColorScheme(.dark)
    }

    // MARK: - Welcome + Docker Step (Combined)
    private var welcomeAndDockerStep: some View {
        VStack(spacing: 20) {
            // Welcome header
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Welcome to OpenMoxie!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            // Auto-setup status
            if installService.isInstalling || !installService.installationLogs.isEmpty {
                // Show installation progress
                VStack(spacing: 12) {
                    if installService.isInstalling {
                        HStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.0)
                                .tint(.blue)
                            Text(installService.installationProgress)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                    } else if installService.openMoxieConfigured {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                            Text("OpenMoxie is ready!")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.green)
                        }
                    }

                    // Log output
                    if !installService.installationLogs.isEmpty {
                        ScrollViewReader { proxy in
                            ScrollView {
                                VStack(alignment: .leading, spacing: 3) {
                                    ForEach(Array(installService.installationLogs.enumerated()), id: \.offset) { index, logEntry in
                                        Text(logEntry)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(logEntry.contains("Error") || logEntry.contains("Warning") ? .orange : .green)
                                            .id(index)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .onChange(of: installService.installationLogs.count) { _ in
                                if let lastIndex = installService.installationLogs.indices.last {
                                    withAnimation { proxy.scrollTo(lastIndex, anchor: .bottom) }
                                }
                            }
                        }
                        .frame(height: 120)
                        .padding(10)
                        .background(Color.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
            } else if !dockerInstalled {
                // Docker not installed - show download button
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.red)
                        Text("Docker Desktop Required")
                            .font(.headline)
                            .foregroundColor(.white)
                    }

                    Text("OpenMoxie needs Docker to run. Please install it first.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)

                    Button(action: { downloadDocker() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("Download Docker Desktop")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)

                    Button(action: { checkDockerAndAutoSetup() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                            Text("I've installed Docker - Check Again")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            } else {
                // Show features while setup runs
                VStack(alignment: .leading, spacing: 12) {
                    WizardFeatureRow(icon: "brain.head.profile", title: "AI Personalities", description: "Create custom personalities for your robot")
                    WizardFeatureRow(icon: "eye.fill", title: "Parent Control", description: "Full visibility into your child's interactions")
                    WizardFeatureRow(icon: "message.fill", title: "Multi-Language", description: "Conversations in any language")
                }
                .padding()
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
            }

            // Show error OR "starting docker" state
            if let error = installService.installationError {
                VStack(spacing: 12) {
                    if isStartingDocker {
                        HStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Starting Docker Desktop...")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    } else {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)

                        // Show Start Docker button if Docker isn't running
                        if error.contains("not running") {
                            HStack(spacing: 12) {
                                // Use onTapGesture - more reliable than Button on macOS
                                HStack(spacing: 8) {
                                    Image(systemName: "play.circle.fill")
                                    Text("Start Docker")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 8))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    print("Start Docker tapped!")
                                    // Open Docker directly using NSWorkspace
                                    let dockerPath = URL(fileURLWithPath: "/Applications/Docker.app")
                                    NSWorkspace.shared.open(dockerPath)

                                    isStartingDocker = true
                                    installService.log("Opening Docker Desktop...")

                                    Task {
                                        await installService.startDockerDesktop()
                                        isStartingDocker = false
                                        if installService.installationError == nil {
                                            await autoSetupOpenMoxie()
                                        }
                                    }
                                }

                                // Retry button
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Retry")
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    print("Retry tapped!")
                                    installService.installationError = nil
                                    installService.clearLogs()
                                    checkDockerAndAutoSetup()
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            } else if isStartingDocker {
                // Show starting state even if error is cleared
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Starting Docker Desktop...")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .onAppear {
            // Auto-start setup when this step appears
            if checkStatus.isEmpty {
                checkDockerAndAutoSetup()
            }
        }
    }

    // MARK: - Legacy Welcome Step (kept for reference)
    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Welcome!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 16) {
                WizardFeatureRow(icon: "brain.head.profile", title: "AI-Powered Personalities", description: "Build your own personalities for your OpenMoxie robot")
                WizardFeatureRow(icon: "eye.fill", title: "Parents Stay In Control", description: "Track and see everything your child is doing with complete visibility")
                WizardFeatureRow(icon: "message.fill", title: "Languages & Chat", description: "Natural conversations in any language with your robot")
                WizardFeatureRow(icon: "book.fill", title: "Story Time & Learning", description: "Educational content and storytelling features")
                WizardFeatureRow(icon: "music.note", title: "Music & Karaoke", description: "Sing along with AI-generated lyrics")
            }
            .padding()
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Docker Check Step (legacy)
    private var dockerCheckStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Docker Setup")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text("OpenMoxie requires Docker to run the backend services. Let's check if Docker is installed on your system.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            // Check button
            if !isChecking && checkStatus.isEmpty {
                Button(action: {
                    checkDocker()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                        Text("Check for Docker")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                }
                .buttonStyle(.plain)
            }

            // Status display
            if isChecking {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.blue)
                    Text("Checking for Docker...")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding()
            }

            if !checkStatus.isEmpty {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: dockerInstalled ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(dockerInstalled ? .green : .red)

                        Text(checkStatus)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .background(
                        dockerInstalled ?
                            Color.green.opacity(0.1) :
                            Color.red.opacity(0.1),
                        in: RoundedRectangle(cornerRadius: 12)
                    )

                    if !dockerInstalled {
                        VStack(spacing: 12) {
                            Button(action: {
                                downloadDocker()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "arrow.down.circle.fill")
                                    Text("Download Docker Desktop")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    in: RoundedRectangle(cornerRadius: 10)
                                )
                            }
                            .buttonStyle(.plain)

                            Text("After installing Docker, we'll set up the rest automatically")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)

                            Button(action: {
                                checkDocker()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Recheck Docker")
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        // Docker is installed, show auto-setup button
                        VStack(spacing: 12) {
                            if !installService.isInstalling {
                                Button(action: {
                                    installService.clearLogs()
                                    Task {
                                        await installService.runCompleteSetup()
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "wand.and.stars")
                                        Text("Auto-Install OpenMoxie")
                                            .font(.headline)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 14)
                                    .background(
                                        LinearGradient(
                                            colors: [.purple, .blue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        in: RoundedRectangle(cornerRadius: 10)
                                    )
                                }
                                .buttonStyle(.plain)

                                Text("This will install and configure OpenMoxie automatically")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                    .multilineTextAlignment(.center)
                            } else {
                                VStack(spacing: 8) {
                                    ProgressView()
                                        .scaleEffect(1.2)
                                        .tint(.blue)
                                    Text(installService.installationProgress)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                            }

                            // Log output box
                            if !installService.installationLogs.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Installation Log")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.6))
                                        Spacer()
                                        if !installService.isInstalling {
                                            Button("Clear") {
                                                installService.clearLogs()
                                            }
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                            .buttonStyle(.plain)
                                        }
                                    }

                                    ScrollViewReader { proxy in
                                        ScrollView {
                                            VStack(alignment: .leading, spacing: 4) {
                                                ForEach(Array(installService.installationLogs.enumerated()), id: \.offset) { index, logEntry in
                                                    Text(logEntry)
                                                        .font(.system(size: 11, design: .monospaced))
                                                        .foregroundColor(logEntry.contains("Error") || logEntry.contains("Warning") ? .orange : .green)
                                                        .id(index)
                                                }
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .onChange(of: installService.installationLogs.count) { _ in
                                            if let lastIndex = installService.installationLogs.indices.last {
                                                withAnimation {
                                                    proxy.scrollTo(lastIndex, anchor: .bottom)
                                                }
                                            }
                                        }
                                    }
                                    .frame(height: 150)
                                    .padding(10)
                                    .background(Color.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                                }
                                .padding(.horizontal, 20)
                            }

                            if let error = installService.installationError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding()
                                    .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            // Auto-check and auto-install on appear
            if checkStatus.isEmpty {
                checkDockerAndAutoSetup()
            }
        }
    }

    /// Check Docker and automatically setup OpenMoxie if needed
    private func checkDockerAndAutoSetup() {
        isChecking = true
        checkStatus = ""

        Task {
            await MainActor.run {
                let workspace = NSWorkspace.shared

                // Check if Docker Desktop app is installed
                let hasDockerApp = workspace.urlForApplication(withBundleIdentifier: "com.docker.docker") != nil
                    || FileManager.default.fileExists(atPath: "/Applications/Docker.app")

                if hasDockerApp {
                    let dockerPaths = [
                        "/usr/local/bin/docker",
                        "/opt/homebrew/bin/docker",
                        "/usr/bin/docker",
                        "/Applications/Docker.app/Contents/Resources/bin/docker"
                    ]
                    let hasDockerCLI = dockerPaths.contains { FileManager.default.fileExists(atPath: $0) }

                    if hasDockerCLI {
                        dockerInstalled = true
                        checkStatus = "Docker is installed!"
                        isChecking = false

                        // Auto-start OpenMoxie setup
                        installService.clearLogs()
                        installService.log("Docker detected! Starting automatic setup...")

                        Task {
                            await autoSetupOpenMoxie()
                        }
                    } else {
                        dockerInstalled = false
                        checkStatus = "Docker Desktop is installed but CLI not found. Try restarting Docker."
                        isChecking = false
                    }
                } else {
                    dockerInstalled = false
                    checkStatus = "Docker Desktop is not installed"
                    isChecking = false
                }
            }
        }
    }

    /// Automatically setup or bind to OpenMoxie
    private func autoSetupOpenMoxie() async {
        // Use dockerPath from installService for reliable Docker detection
        let dockerPath = installService.dockerPath

        // Check if OpenMoxie container already exists and is running
        let checkResult = await runShellCommand("\(dockerPath) ps --filter name=openmoxie-server --format '{{.Names}}'")

        if checkResult.output.contains("openmoxie-server") {
            // Already running - just bind to it
            installService.log("OpenMoxie is already running!")
            installService.log("Binding to existing installation...")

            // Auto-detect IP and configure
            _ = installService.getLocalIPAddress()
            if !installService.detectedIPAddress.isEmpty {
                installService.log("Detected IP: \(installService.detectedIPAddress)")

                // Configure the hive setup with the IP
                do {
                    try await installService.configureHiveSetup()
                    installService.log("Configuration complete!")
                    installService.openMoxieConfigured = true
                } catch {
                    installService.log("Warning: Could not auto-configure: \(error.localizedDescription)")
                }
            }

            installService.log("Ready to use!")
            canContinue = true
        } else {
            // Check if container exists but is stopped
            let stoppedCheck = await runShellCommand("\(dockerPath) ps -a --filter name=openmoxie-server --format '{{.Names}}'")

            if stoppedCheck.output.contains("openmoxie-server") {
                // Container exists but stopped - start it
                installService.log("OpenMoxie container found but stopped. Starting...")
                let startResult = await runShellCommand("\(dockerPath) start openmoxie-server openmoxie-mqtt")
                if startResult.success {
                    installService.log("Containers started!")

                    // Wait for server to be ready
                    installService.log("Waiting for server to start...")
                    for i in 1...10 {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        let ready = await runShellCommand("curl -s \(AppConfig.setupEndpoint)")
                        if ready.success && !ready.output.isEmpty {
                            installService.log("Server is ready!")
                            break
                        }
                        installService.log("Waiting... (\(i * 2)s)")
                    }

                    // Configure
                    _ = installService.getLocalIPAddress()
                    if !installService.detectedIPAddress.isEmpty {
                        try? await installService.configureHiveSetup()
                    }

                    installService.log("Ready to use!")
                    installService.openMoxieConfigured = true
                    canContinue = true
                } else {
                    // Starting failed - containers might not exist properly
                    // Fall through to fresh install
                    installService.log("Could not start existing containers, will do fresh install...")
                    installService.log("Starting automatic installation...")
                    await installService.runCompleteSetup()
                    canContinue = installService.openMoxieConfigured
                }
            } else {
                // Not installed at all - run full setup
                installService.log("OpenMoxie not installed. Starting automatic installation...")
                await installService.runCompleteSetup()
                canContinue = installService.openMoxieConfigured
            }
        }
    }

    /// Run shell command helper
    private func runShellCommand(_ command: String) async -> (success: Bool, output: String, error: String) {
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

                continuation.resume(returning: (process.terminationStatus == 0, output, error))
            } catch {
                continuation.resume(returning: (false, "", error.localizedDescription))
            }
        }
    }

    // MARK: - PIN Setup Step
    private var pinSetupStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .indigo],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Parent PIN Setup")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text("Protect your Parent Console with a 6-digit PIN")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            VStack(spacing: 16) {
                // Create PIN
                VStack(alignment: .leading, spacing: 8) {
                    Text("Create PIN")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    SecureField("6-digit PIN", text: $createPIN)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16, design: .monospaced))
                        .padding()
                        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                        .foregroundColor(.white)
                        .onChange(of: createPIN) { newValue in
                            if newValue.count > 6 {
                                createPIN = String(newValue.prefix(6))
                            }
                        }
                }

                // Confirm PIN
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm PIN")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    SecureField("Re-enter PIN", text: $confirmPIN)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16, design: .monospaced))
                        .padding()
                        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                        .foregroundColor(.white)
                        .onChange(of: confirmPIN) { newValue in
                            if newValue.count > 6 {
                                confirmPIN = String(newValue.prefix(6))
                            }
                        }
                }

                // Parent Email
                VStack(alignment: .leading, spacing: 8) {
                    Text("Parent Email")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    TextField("parent@example.com", text: $parentEmail)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)

            // PIN requirements
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: createPIN.count == 6 ? "checkmark.circle.fill" : "circle")
                        .font(.caption)
                        .foregroundColor(createPIN.count == 6 ? .green : .white.opacity(0.5))
                    Text("Exactly 6 digits")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                HStack(spacing: 8) {
                    Image(systemName: (createPIN == confirmPIN && !createPIN.isEmpty) ? "checkmark.circle.fill" : "circle")
                        .font(.caption)
                        .foregroundColor((createPIN == confirmPIN && !createPIN.isEmpty) ? .green : .white.opacity(0.5))
                    Text("PINs match")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                HStack(spacing: 8) {
                    Image(systemName: isValidEmail(parentEmail) ? "checkmark.circle.fill" : "circle")
                        .font(.caption)
                        .foregroundColor(isValidEmail(parentEmail) ? .green : .white.opacity(0.3))
                    Text("Email (optional)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding()
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - WiFi QR Step
    private var wifiQRStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "wifi")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("WiFi Setup")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text("Configure your WiFi credentials to connect your OpenMoxie robot to your network")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            // Show auto-detected network
            if !wifiSSID.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Network (Auto-Detected)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Text(wifiSSID)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.green)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)
            }

            VStack(spacing: 12) {
                HStack {
                    TextField("WiFi Network Name (SSID)", text: $wifiSSID)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .foregroundColor(.white)

                    Button(action: { detectCurrentWiFi() }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("Detect current WiFi network")
                }
                .padding()
                .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

                SecureField("WiFi Password", text: $wifiPassword)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

                Picker("Encryption", selection: $wifiEncryption) {
                    Text("WPA/WPA2").tag("WPA")
                    Text("WEP").tag("WEP")
                    Text("None").tag("nopass")
                }
                .pickerStyle(.segmented)
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)

            if !wifiSSID.isEmpty {
                VStack(spacing: 16) {
                    Text("Scan this QR code with your OpenMoxie robot")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))

                    if let qrImage = generateWiFiQRCode() {
                        Image(nsImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .green.opacity(0.3), radius: 10)
                    }
                }
                .padding(.top, 12)
            }
        }
        .onAppear {
            // Auto-detect WiFi on appear if not already set
            if wifiSSID.isEmpty {
                detectCurrentWiFi()
            }
        }
        .onChange(of: wifiSSID) { _ in saveWiFiCredentials() }
        .onChange(of: wifiPassword) { _ in saveWiFiCredentials() }
        .onChange(of: wifiEncryption) { _ in saveWiFiCredentials() }
    }

    /// Detect the current WiFi network using system command
    private func detectCurrentWiFi() {
        // Try multiple methods to get WiFi SSID
        Task {
            // Method 1: networksetup command (most reliable)
            let result = await runShellCommand("/usr/sbin/networksetup -getairportnetwork en0")
            if result.success {
                // Output is like "Current Wi-Fi Network: NetworkName"
                let output = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
                if let range = output.range(of: "Current Wi-Fi Network: ") {
                    let ssid = String(output[range.upperBound...])
                    if !ssid.isEmpty && ssid != "You are not associated with an AirPort network." {
                        await MainActor.run {
                            wifiSSID = ssid
                            print("✅ Auto-detected WiFi network: \(ssid)")
                        }
                        return
                    }
                }
            }

            // Method 2: Try airport command
            let airportResult = await runShellCommand("/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | grep ' SSID' | cut -d ':' -f 2 | tr -d ' '")
            if airportResult.success {
                let ssid = airportResult.output.trimmingCharacters(in: .whitespacesAndNewlines)
                if !ssid.isEmpty {
                    await MainActor.run {
                        wifiSSID = ssid
                        print("✅ Auto-detected WiFi network (airport): \(ssid)")
                    }
                    return
                }
            }

            // Method 3: Try CoreWLAN as fallback
            await MainActor.run {
                if let interface = CWWiFiClient.shared().interface() {
                    if let ssid = interface.ssid() {
                        wifiSSID = ssid
                        print("✅ Auto-detected WiFi network (CoreWLAN): \(ssid)")
                    }
                }
            }
        }
    }

    // MARK: - Network QR Step
    private var networkQRStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "qrcode")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Connect to OpenMoxie")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text("Scan this QR code to connect your OpenMoxie robot to the backend")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            // Show auto-detected IP prominently
            if !installService.detectedIPAddress.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your IP Address (Auto-Detected)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Text(installService.detectedIPAddress)
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }

            VStack(spacing: 16) {
                if let qrImage = generateNetworkQRCode() {
                    Image(nsImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .blue.opacity(0.3), radius: 10)
                }

                Text(moxieEndpoint)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
                    .padding()
                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .onAppear {
            // Auto-detect IP and set endpoint when this step appears
            moxieEndpoint = installService.getMoxieEndpoint()
            UserDefaults.standard.set(moxieEndpoint, forKey: "moxieEndpoint")
        }
    }

    // MARK: - Robot Pairing Step (Combined WiFi + Network)
    private var robotPairingStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Pair Your Robot")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text("Scan these QR codes with your Moxie robot to connect")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                // Two QR codes side by side
                HStack(spacing: 30) {
                    // WiFi QR Code
                    VStack(spacing: 12) {
                        Text("1. WiFi Network")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)

                        if let qrImage = generateWiFiQRCode() {
                            Image(nsImage: qrImage)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                                .background(Color.white)
                                .cornerRadius(8)
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 150, height: 150)
                                .overlay(
                                    Text("Enter WiFi\ndetails below")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.5))
                                        .multilineTextAlignment(.center)
                                )
                        }

                        Text(wifiSSID.isEmpty ? "No network" : wifiSSID)
                            .font(.caption)
                            .foregroundColor(.green)
                    }

                    // Network QR Code
                    VStack(spacing: 12) {
                        Text("2. OpenMoxie Server")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)

                        if let qrImage = generateNetworkQRCode() {
                            Image(nsImage: qrImage)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                                .background(Color.white)
                                .cornerRadius(8)
                        }

                        Text(installService.detectedIPAddress.isEmpty ? "Detecting..." : installService.detectedIPAddress)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))

                // WiFi Configuration (collapsed by default if auto-detected)
                VStack(spacing: 12) {
                    HStack {
                        Text("WiFi Settings")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                        Spacer()
                        if !wifiSSID.isEmpty {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }

                    HStack {
                        TextField("Network Name (SSID)", text: $wifiSSID)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .foregroundColor(.white)

                        Button(action: { detectCurrentWiFi() }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

                    SecureField("WiFi Password", text: $wifiPassword)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

                    Picker("Encryption", selection: $wifiEncryption) {
                        Text("WPA/WPA2").tag("WPA")
                        Text("WEP").tag("WEP")
                        Text("None").tag("nopass")
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            // Auto-detect network info
            if wifiSSID.isEmpty {
                detectCurrentWiFi()
            }
            if moxieEndpoint.isEmpty {
                moxieEndpoint = installService.getMoxieEndpoint()
                UserDefaults.standard.set(moxieEndpoint, forKey: "moxieEndpoint")
            }
        }
        .onChange(of: wifiSSID) { _ in saveWiFiCredentials() }
        .onChange(of: wifiPassword) { _ in saveWiFiCredentials() }
        .onChange(of: wifiEncryption) { _ in saveWiFiCredentials() }
    }

    // MARK: - API Key Step (Optional - accessible from Settings)
    private var apiKeyStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("AI Setup")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text("Connect your OpenAI account to power OpenMoxie's conversations with GPT-3.5")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 16) {
                // OpenAI Header
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .blur(radius: 8)
                            .frame(width: 40, height: 40)
                        Image(systemName: "sparkles")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.green)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("OpenAI")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)

                        Text("GPT-3.5 Turbo recommended")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    Link(destination: URL(string: "https://platform.openai.com/api-keys")!) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right.square")
                            Text("Get API Key")
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.blue)
                    }
                }

                // API Key Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Key")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))

                    HStack {
                        if showingApiKey {
                            TextField("Enter your OpenAI API key", text: $openAIKey)
                                .textFieldStyle(.plain)
                                .foregroundColor(.white)
                                .font(.system(size: 13, design: .monospaced))
                        } else {
                            SecureField("sk-...", text: $openAIKey)
                                .textFieldStyle(.plain)
                                .foregroundColor(.white)
                                .font(.system(size: 13, design: .monospaced))
                        }

                        Button(action: { showingApiKey.toggle() }) {
                            Image(systemName: showingApiKey ? "eye.slash.fill" : "eye.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                }

                // Info
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text("Your API key is stored securely and never shared")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.top, 8)
            }
            .padding(20)
            .background(.ultraThinMaterial.opacity(0.3), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
        .onAppear {
            // Auto-detect OpenAI API key from environment or existing configuration
            autoDetectOpenAIKey()
        }
        .onChange(of: openAIKey) { newValue in
            saveOpenAIKey(newValue)
        }
    }

    // MARK: - Completion Step
    private var completionStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("You're All Set!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text("OpenMoxie is ready to use. You can now:")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 12) {
                SetupCompletionRow(icon: "shippingbox.fill", text: "Launch Docker and OpenMoxie backend with one click")
                SetupCompletionRow(icon: "qrcode", text: "Generate QR codes for easy setup")
                SetupCompletionRow(icon: "wifi", text: "Configure WiFi for your OpenMoxie robot")
                SetupCompletionRow(icon: "person.2.fill", text: "Switch between AI personalities")
                SetupCompletionRow(icon: "sparkles", text: "Explore all the amazing features")
            }
            .padding()
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Helper Functions
    func checkDocker() {
        isChecking = true
        checkStatus = ""
        canContinue = false

        Task {
            // Small delay for better UX
            try? await Task.sleep(nanoseconds: 1_000_000_000)

            await MainActor.run {
                let workspace = NSWorkspace.shared

                // Check if Docker Desktop app is installed
                let hasDockerApp = workspace.urlForApplication(withBundleIdentifier: "com.docker.docker") != nil
                    || FileManager.default.fileExists(atPath: "/Applications/Docker.app")

                if hasDockerApp {
                    // Check if docker CLI is available in multiple locations
                    let dockerPaths = [
                        "/usr/local/bin/docker",
                        "/opt/homebrew/bin/docker",
                        "/usr/bin/docker",
                        "/Applications/Docker.app/Contents/Resources/bin/docker"
                    ]

                    let hasDockerCLI = dockerPaths.contains { FileManager.default.fileExists(atPath: $0) }

                    if hasDockerCLI {
                        dockerInstalled = true
                        checkStatus = "Docker is installed and ready!"
                        canContinue = true

                        // Auto-detect IP address early
                        _ = installService.getLocalIPAddress()
                    } else {
                        dockerInstalled = false
                        checkStatus = "Docker Desktop is installed but CLI not found. Try restarting Docker."
                        canContinue = false
                    }
                } else {
                    dockerInstalled = false
                    checkStatus = "Docker Desktop is not installed"
                    canContinue = false
                }

                isChecking = false
            }
        }
    }

    func downloadDocker() {
        // Open Docker Desktop download page
        if let url = URL(string: "https://www.docker.com/products/docker-desktop/") {
            NSWorkspace.shared.open(url)
        }
    }

    func saveWiFiCredentials() {
        UserDefaults.standard.set(wifiSSID, forKey: "wifiSSID")
        UserDefaults.standard.set(wifiPassword, forKey: "wifiPassword")
        UserDefaults.standard.set(wifiEncryption, forKey: "wifiEncryption")
    }

    func saveOpenAIKey(_ key: String) {
        // Save to AIProviderManager
        if var config = providerManager.providers.first(where: { $0.provider == .openai }) {
            config.apiKey = key
            config.selectedModel = "gpt-3.5-turbo"
            providerManager.updateProvider(config)
            providerManager.setActiveProvider(.openai)
        }
    }

    func autoDetectOpenAIKey() {
        // Check if key already exists in provider manager
        if let existingConfig = providerManager.providers.first(where: { $0.provider == .openai }),
           !existingConfig.apiKey.isEmpty {
            openAIKey = existingConfig.apiKey
            print("✅ Found existing OpenAI API key in configuration")
            return
        }

        // Check environment variable OPENAI_API_KEY
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"],
           !envKey.isEmpty {
            openAIKey = envKey
            print("✅ Auto-detected OpenAI API key from environment variable")
            return
        }

        print("ℹ️ No OpenAI API key found - user will need to enter it")
    }

    func generateWiFiQRCode() -> NSImage? {
        guard !wifiSSID.isEmpty else { return nil }

        // WiFi QR code format: WIFI:T:WPA;S:MyNetwork;P:MyPassword;;
        let wifiString = "WIFI:T:\(wifiEncryption);S:\(wifiSSID);P:\(wifiPassword);;"

        return generateQRCode(from: wifiString)
    }

    func generateNetworkQRCode() -> NSImage? {
        return generateQRCode(from: moxieEndpoint)
    }

    func canContinuePIN() -> Bool {
        // PIN is required, email is optional
        return createPIN.count == 6 &&
               createPIN == confirmPIN &&
               createPIN.allSatisfy { $0.isNumber }
    }

    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    func savePINSettings() {
        do {
            // Create PIN
            try pinService.createPIN(createPIN)

            // Save parent email
            UserDefaults.standard.set(parentEmail, forKey: "parentEmail")

            // Create parent account (simplified version)
            let parentAccount = ParentAccount(
                email: parentEmail,
                securityQuestion: "Default question",
                securityAnswerHash: ""
            )

            if let encoded = try? JSONEncoder().encode(parentAccount) {
                UserDefaults.standard.set(encoded, forKey: "parentAccount")
            }
        } catch {
            print("Failed to save PIN: \(error)")
        }
    }

    func generateQRCode(from string: String) -> NSImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)

            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return NSImage(cgImage: cgImage, size: NSSize(width: scaledImage.extent.width, height: scaledImage.extent.height))
            }
        }

        return nil
    }
}

// MARK: - Supporting Views
struct WizardFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

struct SetupCompletionRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.green)
                .frame(width: 24, height: 24)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
        }
    }
}
