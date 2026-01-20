//
//  SetupWizardView.swift
//  SimpleMoxieSwitcherApp
//
//  Parent-friendly setup wizard for OpenMoxie
//

import SwiftUI

struct SetupWizardView: View {
    @ObservedObject var setupManager: SetupManager
    @Binding var isComplete: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            SetupHeaderView(currentStep: setupManager.currentStep)

            // Progress bar
            SetupProgressBar(currentStep: setupManager.currentStep)
                .padding(.horizontal, 40)
                .padding(.vertical, 20)

            // Main content area
            ScrollView {
                VStack(spacing: 30) {
                    switch setupManager.currentStep {
                    case .welcome:
                        WelcomeStepView(setupManager: setupManager)
                    case .dockerInstall:
                        DockerInstallStepView(setupManager: setupManager)
                    case .dockerRunning:
                        DockerRunningStepView(setupManager: setupManager)
                    case .openMoxieSetup:
                        OpenMoxieSetupStepView(setupManager: setupManager)
                    case .apiConfiguration:
                        APIConfigurationStepView(setupManager: setupManager)
                    case .moxieConnection:
                        MoxieConnectionStepView(setupManager: setupManager)
                    case .complete:
                        SetupCompleteView(isComplete: $isComplete)
                    }
                }
                .padding(40)
            }

            // Error message if any
            if let error = setupManager.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .foregroundColor(.red)
                        .font(.callout)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }

            // Loading indicator
            if setupManager.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(setupManager.statusMessage)
                        .foregroundColor(.secondary)
                        .font(.callout)
                }
                .padding()
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            Task {
                await setupManager.performFullCheck()
            }
        }
    }
}

// MARK: - Header

struct SetupHeaderView: View {
    let currentStep: SetupStep

    var body: some View {
        VStack(spacing: 10) {
            Text("Moxie 2.0 Controller")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text(currentStep.description)
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 30)
        .padding(.horizontal)
    }
}

// MARK: - Progress Bar

struct SetupProgressBar: View {
    let currentStep: SetupStep

    var body: some View {
        HStack(spacing: 4) {
            ForEach(SetupStep.allCases.filter { $0 != .welcome && $0 != .complete }, id: \.rawValue) { step in
                VStack(spacing: 6) {
                    Circle()
                        .fill(stepColor(for: step))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Group {
                                if step.rawValue < currentStep.rawValue || currentStep == .complete {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                        .font(.caption.bold())
                                } else {
                                    Image(systemName: step.icon)
                                        .foregroundColor(step == currentStep ? .white : .gray)
                                        .font(.caption)
                                }
                            }
                        )

                    Text(step.title)
                        .font(.caption2)
                        .foregroundColor(step == currentStep ? .primary : .secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)

                if step.rawValue < SetupStep.moxieConnection.rawValue {
                    Rectangle()
                        .fill(step.rawValue < currentStep.rawValue ? Color.green : Color.gray.opacity(0.3))
                        .frame(height: 2)
                        .frame(maxWidth: 40)
                }
            }
        }
    }

    private func stepColor(for step: SetupStep) -> Color {
        if step.rawValue < currentStep.rawValue || currentStep == .complete {
            return .green
        } else if step == currentStep {
            return .blue
        } else {
            return Color.gray.opacity(0.3)
        }
    }
}

// MARK: - Welcome Step

struct WelcomeStepView: View {
    @ObservedObject var setupManager: SetupManager

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "face.smiling")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                )

            Text("Welcome to Moxie 2.0!")
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Text("This app will help you set up OpenMoxie on your computer so you can customize your Moxie robot's personality, appearance, and more.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 500)

            VStack(alignment: .leading, spacing: 15) {
                FeatureRow(icon: "sparkles", color: .purple, title: "Custom Personalities", description: "Give Moxie any personality you can imagine")
                FeatureRow(icon: "paintbrush.fill", color: .orange, title: "Appearance Editor", description: "Change Moxie's face, eyes, hair, and more")
                FeatureRow(icon: "bubble.left.and.bubble.right.fill", color: .blue, title: "Conversation History", description: "See what Moxie and your child talked about")
                FeatureRow(icon: "gamecontroller.fill", color: .green, title: "Remote Control", description: "Control Moxie's movements and expressions")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(15)

            Button(action: {
                Task {
                    await setupManager.performFullCheck()
                }
            }) {
                HStack {
                    Text("Let's Get Started")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Docker Install Step

struct DockerInstallStepView: View {
    @ObservedObject var setupManager: SetupManager

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 70))
                .foregroundColor(.blue)

            Text("Install Docker Desktop")
                .font(.system(size: 24, weight: .bold, design: .rounded))

            Text("Docker is a free app that lets your computer run OpenMoxie. It's safe and used by millions of developers.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 450)

            VStack(spacing: 20) {
                InstructionStep(number: 1, text: "Click the button below to open the Docker download page")
                InstructionStep(number: 2, text: "Download Docker Desktop for Mac")
                InstructionStep(number: 3, text: "Open the downloaded file and drag Docker to Applications")
                InstructionStep(number: 4, text: "Open Docker from your Applications folder")
                InstructionStep(number: 5, text: "Come back here and click \"Check Again\"")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(15)

            HStack(spacing: 20) {
                Button(action: {
                    setupManager.openDockerDownload()
                }) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("Download Docker")
                    }
                    .padding(.horizontal, 25)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)

                Button(action: {
                    Task {
                        await setupManager.performFullCheck()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Check Again")
                    }
                    .padding(.horizontal, 25)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct InstructionStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Text("\(number)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Color.blue)
                .clipShape(Circle())

            Text(text)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Docker Running Step

struct DockerRunningStepView: View {
    @ObservedObject var setupManager: SetupManager

    var body: some View {
        VStack(spacing: 30) {
            // Animated waiting indicator
            ZStack {
                Circle()
                    .stroke(Color.green.opacity(0.3), lineWidth: 8)
                    .frame(width: 100, height: 100)

                if setupManager.isDockerRunning {
                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.green)
                } else {
                    ProgressView()
                        .scaleEffect(2)
                }
            }

            Text(setupManager.isDockerRunning ? "Docker is Running!" : "Waiting for Docker...")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(setupManager.isDockerRunning ? .green : .primary)

            HStack(spacing: 15) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                Text("Docker is installed!")
                    .foregroundColor(.green)
                    .fontWeight(.medium)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(10)

            if !setupManager.isDockerRunning {
                Text("Docker needs to be running before we can set up OpenMoxie. Click the button below to start it - we'll automatically continue when it's ready.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 450)

                Text("Note: The first time Docker starts, it may take a minute or two. You'll see the Docker whale icon in your menu bar when it's ready.")
                    .font(.callout)
                    .foregroundColor(.orange)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(10)
                    .frame(maxWidth: 450)

                HStack(spacing: 20) {
                    Button(action: {
                        setupManager.openDockerApp()
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Docker")
                        }
                        .padding(.horizontal, 25)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        Task {
                            await setupManager.performFullCheck()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Check Again")
                        }
                        .padding(.horizontal, 25)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                // Auto-advance in 2 seconds
                Text("Continuing to next step...")
                    .foregroundColor(.secondary)
                    .onAppear {
                        Task {
                            try? await Task.sleep(nanoseconds: 1_500_000_000)
                            setupManager.currentStep = .openMoxieSetup
                        }
                    }
            }
        }
        .onAppear {
            // Start polling when this view appears
            setupManager.startDockerPolling()
        }
    }
}

// MARK: - OpenMoxie Setup Step

struct OpenMoxieSetupStepView: View {
    @ObservedObject var setupManager: SetupManager

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "server.rack")
                .font(.system(size: 70))
                .foregroundColor(.purple)

            Text("Set Up OpenMoxie Server")
                .font(.system(size: 24, weight: .bold, design: .rounded))

            VStack(spacing: 10) {
                StatusCheckRow(title: "Docker Installed", isComplete: setupManager.isDockerInstalled)
                StatusCheckRow(title: "Docker Running", isComplete: setupManager.isDockerRunning)
                StatusCheckRow(title: "OpenMoxie Server", isComplete: setupManager.isOpenMoxieRunning)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(15)

            // Show detected IP address
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "network")
                        .foregroundColor(.blue)
                    Text("Your IP Address:")
                        .fontWeight(.medium)
                    Text(setupManager.localIPAddress)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.blue)
                }
                Text("This will be automatically configured for Moxie to connect")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)

            if !setupManager.isOpenMoxieInstalled {
                Text("Click the button below to download and set up the OpenMoxie server. This is a one-time setup that may take a few minutes.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 450)
            } else {
                Text("OpenMoxie is installed but not running. Click below to start it.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 450)
            }

            Button(action: {
                Task {
                    await setupManager.startOpenMoxie()
                }
            }) {
                HStack {
                    if setupManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: setupManager.isOpenMoxieInstalled ? "play.fill" : "arrow.down.circle.fill")
                    }
                    Text(setupManager.isOpenMoxieInstalled ? "Start OpenMoxie" : "Install OpenMoxie")
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(setupManager.isLoading ? Color.gray : Color.purple)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .disabled(setupManager.isLoading)
        }
    }
}

struct StatusCheckRow: View {
    let title: String
    let isComplete: Bool

    var body: some View {
        HStack {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isComplete ? .green : .gray)
            Text(title)
            Spacer()
            if isComplete {
                Text("Ready")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Text("Waiting...")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - API Configuration Step

struct APIConfigurationStepView: View {
    @ObservedObject var setupManager: SetupManager

    var body: some View {
        VStack(spacing: 25) {
            Image(systemName: "key.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Just One More Thing!")
                .font(.system(size: 24, weight: .bold, design: .rounded))

            Text("OpenMoxie needs an OpenAI API key to power Moxie's conversations. This is the only thing you need to provide - everything else is set up automatically!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 500)

            // Show that IP is auto-configured
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Network address auto-detected:")
                    .foregroundColor(.secondary)
                Text(setupManager.localIPAddress)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(10)

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("OpenAI API Key")
                            .fontWeight(.semibold)
                        Text("(Required)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    SecureField("sk-...", text: $setupManager.openAIApiKey)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 400)

                    HStack {
                        Button("Get OpenAI API Key") {
                            if let url = URL(string: "https://platform.openai.com/api-keys") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .font(.caption)

                        Text("- Create account, add $10 credit, generate key")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Google Service Key (Optional)")
                        .fontWeight(.semibold)
                    SecureField("Paste Google key here...", text: $setupManager.googleServiceKey)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 400)
                    Text("For better speech-to-text quality (optional, OpenAI Whisper is used by default)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(15)

            HStack(spacing: 20) {
                Button(action: {
                    setupManager.openSetupInBrowser()
                }) {
                    HStack {
                        Image(systemName: "safari")
                        Text("Open in Browser")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)

                Button(action: {
                    Task {
                        let success = await setupManager.submitConfiguration()
                        if success {
                            setupManager.currentStep = .moxieConnection
                        }
                    }
                }) {
                    HStack {
                        if setupManager.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.right")
                        }
                        Text("Save & Continue")
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(setupManager.openAIApiKey.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .disabled(setupManager.openAIApiKey.isEmpty || setupManager.isLoading)
            }
        }
    }
}

// MARK: - Moxie Connection Step

struct MoxieConnectionStepView: View {
    @ObservedObject var setupManager: SetupManager
    @State private var copied = false

    var body: some View {
        VStack(spacing: 25) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Connect Your Moxie")
                .font(.system(size: 24, weight: .bold, design: .rounded))

            Text("Final step! Point your Moxie robot to this computer.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Big prominent server address box
            VStack(spacing: 15) {
                Text("Enter this address in Moxie's settings:")
                    .font(.headline)

                HStack(spacing: 15) {
                    Text("\(setupManager.localIPAddress):8883")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)

                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString("\(setupManager.localIPAddress):8883", forType: .string)
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            copied = false
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                .font(.title2)
                            Text(copied ? "Copied!" : "Copy")
                                .font(.caption)
                        }
                        .foregroundColor(copied ? .green : .blue)
                        .frame(width: 60)
                    }
                    .buttonStyle(.plain)
                }

                Text("This is your computer's IP address - NOT your computer name!")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .fontWeight(.medium)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(15)

            VStack(alignment: .leading, spacing: 15) {
                Text("How to connect:")
                    .fontWeight(.semibold)

                InstructionStep(number: 1, text: "Make sure Moxie is on and connected to the same WiFi network")
                InstructionStep(number: 2, text: "Open the Embodied Moxie app on your phone/tablet")
                InstructionStep(number: 3, text: "Go to Settings > Advanced > Server Settings")
                InstructionStep(number: 4, text: "Enter the address above (copy it!) and save")
                InstructionStep(number: 5, text: "Restart Moxie - it should now connect!")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(15)

            Button(action: {
                setupManager.currentStep = .complete
            }) {
                HStack {
                    Text("I've Connected Moxie")
                    Image(systemName: "checkmark")
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Complete Step

struct SetupCompleteView: View {
    @Binding var isComplete: Bool

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("You're All Set!")
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Text("Your Moxie is now connected to OpenMoxie. You can customize personalities, change appearances, view conversations, and much more!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 450)

            VStack(alignment: .leading, spacing: 12) {
                Text("What you can do now:")
                    .fontWeight(.semibold)

                FeatureRow(icon: "sparkles", color: .purple, title: "Switch Personalities", description: "Try different personalities like Pirate Mode or Shakespeare")
                FeatureRow(icon: "paintbrush.fill", color: .orange, title: "Customize Appearance", description: "Change Moxie's eyes, hair, and face designs")
                FeatureRow(icon: "bubble.left.fill", color: .blue, title: "View Conversations", description: "See what Moxie and your child talked about")
                FeatureRow(icon: "gearshape.fill", color: .gray, title: "Settings", description: "Configure advanced options anytime")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(15)

            Button(action: {
                isComplete = true
            }) {
                HStack {
                    Text("Start Using Moxie Controller")
                    Image(systemName: "arrow.right")
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
    }
}
