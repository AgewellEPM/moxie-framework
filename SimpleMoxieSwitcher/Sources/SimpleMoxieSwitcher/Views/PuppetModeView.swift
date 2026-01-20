import SwiftUI

/// Puppet Mode - Control Moxie's responses remotely
/// Parents can hide in another room and control what Moxie says
struct PuppetModeView: View {
    @StateObject private var viewModel = PuppetModeViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var messageText = ""
    @State private var selectedMood: Mood = .neutral
    @State private var intensity: Double = 50
    @FocusState private var isTextFieldFocused: Bool

    enum Mood: String, CaseIterable {
        case happy = "Happy"
        case excited = "Excited"
        case calm = "Calm"
        case neutral = "Neutral"
        case curious = "Curious"
        case empathetic = "Empathetic"
        case playful = "Playful"

        var emoji: String {
            switch self {
            case .happy: return "😊"
            case .excited: return "🤩"
            case .calm: return "😌"
            case .neutral: return "😐"
            case .curious: return "🤔"
            case .empathetic: return "🥰"
            case .playful: return "😄"
            }
        }
    }

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                Divider()
                    .background(Color.white.opacity(0.2))

                // Conversation view (what child and Moxie are saying)
                conversationView

                Divider()
                    .background(Color.white.opacity(0.2))

                // Control panel (type responses, set mood/intensity)
                controlPanel
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .onAppear {
            viewModel.startListening()
        }
        .onDisappear {
            viewModel.stopListening()
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("🎭 Puppet Mode")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Control Moxie's responses remotely")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            // Status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(viewModel.isActive ? Color.green : Color.orange)
                    .frame(width: 12, height: 12)
                    .shadow(color: viewModel.isActive ? .green : .orange, radius: 5)

                Text(viewModel.isActive ? "Active" : "Pending")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding()
    }

    private var conversationView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if viewModel.messages.isEmpty {
                        VStack(spacing: 12) {
                            Text("👂")
                                .font(.system(size: 60))
                            Text("Listening for conversation...")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.6))
                            Text("Messages from your child will appear here")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 100)
                    } else {
                        ForEach(viewModel.messages) { message in
                            PuppetMessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _ in
                if let lastMessage = viewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var controlPanel: some View {
        VStack(spacing: 16) {
            // Mood selector
            VStack(alignment: .leading, spacing: 8) {
                Text("Mood")
                    .font(.headline)
                    .foregroundColor(.white)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Mood.allCases, id: \.self) { mood in
                            MoodButton(
                                mood: mood,
                                isSelected: selectedMood == mood,
                                action: { selectedMood = mood }
                            )
                        }
                    }
                }
            }

            // Intensity slider
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Intensity")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Text("\(Int(intensity))%")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }

                Slider(value: $intensity, in: 0...100)
                    .tint(.orange)
            }

            // Message input
            VStack(alignment: .leading, spacing: 8) {
                Text("Moxie's Response")
                    .font(.headline)
                    .foregroundColor(.white)

                HStack(spacing: 12) {
                    TextField("Type what Moxie should say...", text: $messageText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .foregroundColor(.white)
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            sendMessage()
                        }

                    // Send button
                    Button(action: sendMessage) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: messageText.isEmpty ?
                                            [Color.gray.opacity(0.3), Color.gray.opacity(0.2)] :
                                            [Color.orange, Color.red],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)
                                .shadow(color: messageText.isEmpty ? .clear : .orange.opacity(0.5), radius: 8)

                            Image(systemName: "arrow.up")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(messageText.isEmpty)
                }
            }

            // Helper text
            if viewModel.isSending {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Sending to Moxie...")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            } else if !messageText.isEmpty {
                Text("Press Return or click the button to make Moxie say this")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            } else {
                Text("Type a message to control what Moxie says")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }

    private func sendMessage() {
        guard !messageText.isEmpty else { return }

        viewModel.sendPuppetMessage(
            text: messageText,
            mood: selectedMood.rawValue.lowercased(),
            intensity: Int(intensity)
        )

        messageText = ""
        isTextFieldFocused = true
    }
}

// MARK: - Puppet Message Bubble
struct PuppetMessageBubble: View {
    let message: PuppetMessage

    var body: some View {
        HStack {
            if message.sender == .moxie {
                Spacer()
            }

            VStack(alignment: message.sender == .child ? .leading : .trailing, spacing: 4) {
                // Sender label
                Text(message.sender == .child ? "Child" : "Moxie (You)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))

                // Message bubble
                Text(message.text)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(message.sender == .child ?
                                  Color.blue.opacity(0.3) :
                                  Color.orange.opacity(0.3))
                    )

                // Timestamp
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
            }
            .frame(maxWidth: 400, alignment: message.sender == .child ? .leading : .trailing)

            if message.sender == .child {
                Spacer()
            }
        }
    }
}

// MARK: - Mood Button
struct MoodButton: View {
    let mood: PuppetModeView.Mood
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(mood.emoji)
                    .font(.title2)
                Text(mood.rawValue)
                    .font(.caption2)
            }
            .foregroundColor(.white)
            .frame(width: 80, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.orange.opacity(0.4) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Puppet Message Model
struct PuppetMessage: Identifiable {
    let id = UUID()
    let sender: Sender
    let text: String
    let timestamp: Date

    enum Sender {
        case child
        case moxie
    }
}

// MARK: - Puppet Mode ViewModel
@MainActor
class PuppetModeViewModel: ObservableObject {
    @Published var messages: [PuppetMessage] = []
    @Published var isActive = false
    @Published var isSending = false

    private var mqttService: MQTTServiceProtocol
    private var pollingTimer: Timer?

    init() {
        self.mqttService = DIContainer.shared.resolve(MQTTServiceProtocol.self)
    }

    func startListening() {
        // Start puppet mode on OpenMoxie
        Task {
            await activatePuppetMode()
        }

        // Poll for new messages from child
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkForNewMessages()
            }
        }
    }

    func stopListening() {
        pollingTimer?.invalidate()
        pollingTimer = nil

        // Deactivate puppet mode
        Task {
            await deactivatePuppetMode()
        }
    }

    func sendPuppetMessage(text: String, mood: String, intensity: Int) {
        isSending = true

        // Add to local messages immediately
        messages.append(PuppetMessage(
            sender: .moxie,
            text: text,
            timestamp: Date()
        ))

        // Send via MQTT with mood and intensity
        let payload: [String: Any] = [
            "event_id": UUID().uuidString,
            "command": "puppet_speak",
            "speech": text,
            "mood": mood,
            "intensity": intensity,
            "backend": "router",
            "module_id": "OPENMOXIE_PUPPET",
            "content_id": "default"
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: payload),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            let topic = "/devices/d_openmoxie_ios/events/puppet"
            mqttService.publish(topic: topic, message: jsonString)
            print("📤 Sent puppet message: \(text) [mood: \(mood), intensity: \(intensity)]")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isSending = false
        }
    }

    private func activatePuppetMode() async {
        let dockerService = DIContainer.shared.resolve(DockerServiceProtocol.self)

        let script = """
        # Activate puppet mode
        import os
        os.system('curl -X POST \(AppConfig.puppetStartEndpoint)')
        print('Puppet mode activated')
        """

        do {
            _ = try await dockerService.executePythonScript(script)
            isActive = true
        } catch {
            print("Failed to activate puppet mode: \(error)")
        }
    }

    private func deactivatePuppetMode() async {
        let dockerService = DIContainer.shared.resolve(DockerServiceProtocol.self)

        let script = """
        import os
        os.system('curl -X POST \(AppConfig.puppetStopEndpoint)')
        print('Puppet mode deactivated')
        """

        do {
            _ = try await dockerService.executePythonScript(script)
            isActive = false
        } catch {
            print("Failed to deactivate puppet mode: \(error)")
        }
    }

    private func checkForNewMessages() async {
        // Poll OpenMoxie for new messages from the child
        let dockerService = DIContainer.shared.resolve(DockerServiceProtocol.self)

        let script = """
        import json
        from hive.models import MoxieDevice, PersistentData

        device = MoxieDevice.objects.filter(device_id='moxie_001').first()
        if device:
            persist = PersistentData.objects.filter(device=device).first()
            if persist and persist.data:
                messages = persist.data.get('puppet_messages', [])
                print(json.dumps(messages))
        """

        do {
            let result = try await dockerService.executePythonScript(script)
            if let data = result.data(using: .utf8),
               let messageArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {

                for msgData in messageArray {
                    if let text = msgData["text"] as? String,
                       let isNew = msgData["is_new"] as? Bool,
                       isNew {
                        // Add child message
                        messages.append(PuppetMessage(
                            sender: .child,
                            text: text,
                            timestamp: Date()
                        ))
                    }
                }
            }
        } catch {
            print("Failed to check for messages: \(error)")
        }
    }
}
