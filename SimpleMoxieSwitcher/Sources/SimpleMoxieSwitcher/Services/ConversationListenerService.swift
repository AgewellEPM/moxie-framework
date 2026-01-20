import Foundation
import Combine

// MARK: - MQTT Conversation Listener Service
// Listens to Moxie robot's conversation MQTT topics and persists them to JSONL files

@MainActor
class ConversationListenerService: ObservableObject {
    @Published var isListening = false
    @Published var lastMessageReceived: Date?
    @Published var messageCount: Int = 0

    private var listenerProcess: Process?
    private let conversationsDir = AppPaths.conversations
    private var currentConversationFile: URL?
    private var currentPersonality: String = "Default"
    private var currentPersonalityEmoji: String = "🤖"

    // MQTT Configuration
    private var mqttHost: String { AppConfig.mqttHost }
    private var mqttPort: String { String(AppConfig.mqttPort) }
    private let conversationTopic = "moxie/conversation/#"

    init() {
        // Create conversations directory if it doesn't exist
        try? FileManager.default.createDirectory(at: conversationsDir, withIntermediateDirectories: true)
    }

    // MARK: - Start Listening
    func startListening() {
        guard !isListening else { return }

        print("📡 Starting MQTT conversation listener...")

        // Create mosquitto_sub process to listen to conversation topics
        let process = Process()

        let exe = AppConfig.mosquittoSubPath
        var args: [String] = []
        if exe.contains("/") {
            process.executableURL = URL(fileURLWithPath: exe)
        } else {
            // Use env lookup if only command name is provided
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            args.append(exe)
        }

        // Base arguments
        args.append(contentsOf: [
            "-h", mqttHost,
            "-p", mqttPort,
            "-t", conversationTopic,
            "-v"
        ])

        // If TLS is enabled for MQTT, allow insecure for self-signed brokers
        if AppConfig.mqttUseTLS {
            args.append("--insecure")
        }

        process.arguments = args

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        // Handle incoming MQTT messages
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            guard let self = self else { return }

            let data = handle.availableData
            guard !data.isEmpty,
                  let output = String(data: data, encoding: .utf8) else {
                return
            }

            Task { @MainActor in
                await self.handleMQTTMessage(output)
            }
        }

        do {
            try process.run()
            listenerProcess = process
            isListening = true
            print("✅ MQTT listener started successfully")
        } catch {
            print("❌ Failed to start MQTT listener: \(error)")
        }
    }

    // MARK: - Stop Listening
    func stopListening() {
        guard isListening else { return }

        print("🛑 Stopping MQTT conversation listener...")
        listenerProcess?.terminate()
        listenerProcess = nil
        isListening = false
        print("✅ MQTT listener stopped")
    }

    // MARK: - Handle MQTT Messages
    private func handleMQTTMessage(_ message: String) async {
        let lines = message.components(separatedBy: .newlines).filter { !$0.isEmpty }

        for line in lines {
            // Format: "topic payload"
            let components = line.split(separator: " ", maxSplits: 1)
            guard components.count == 2 else { continue }

            let topic = String(components[0])
            let payload = String(components[1])

            // Parse different conversation message types
            if topic.contains("moxie/conversation/user") {
                await handleUserMessage(payload)
            } else if topic.contains("moxie/conversation/assistant") {
                await handleAssistantMessage(payload)
            } else if topic.contains("moxie/conversation/start") {
                await handleConversationStart(payload)
            } else if topic.contains("moxie/conversation/metadata") {
                await handleConversationMetadata(payload)
            }
        }
    }

    // MARK: - Handle User Message
    private func handleUserMessage(_ payload: String) async {
        guard let data = payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let text = json["text"] as? String else {
            return
        }

        print("👤 User: \(text)")

        // Store for pairing with assistant response
        UserDefaults.standard.set(text, forKey: "pending_user_message")
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "pending_user_timestamp")
    }

    // MARK: - Handle Assistant Message
    private func handleAssistantMessage(_ payload: String) async {
        guard let data = payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let text = json["text"] as? String else {
            return
        }

        print("🤖 Moxie: \(text)")

        // Get pending user message
        guard let userMessage = UserDefaults.standard.string(forKey: "pending_user_message"),
              let userTimestamp = UserDefaults.standard.object(forKey: "pending_user_timestamp") as? TimeInterval else {
            print("⚠️ No pending user message to pair with assistant response")
            return
        }

        // Save conversation exchange
        await saveConversationExchange(
            user: userMessage,
            assistant: text,
            timestamp: Date(timeIntervalSince1970: userTimestamp)
        )

        // Clear pending message
        UserDefaults.standard.removeObject(forKey: "pending_user_message")
        UserDefaults.standard.removeObject(forKey: "pending_user_timestamp")

        lastMessageReceived = Date()
        messageCount += 1
    }

    // MARK: - Handle Conversation Start
    private func handleConversationStart(_ payload: String) async {
        print("🆕 New conversation started")

        // Create new conversation file
        let timestamp = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let dateString = formatter.string(from: timestamp)

        let filename = "moxie_\(currentPersonality.lowercased().replacingOccurrences(of: " ", with: "_"))_\(dateString).jsonl"
        currentConversationFile = conversationsDir.appendingPathComponent(filename)

        // Create empty file
        try? "".write(to: currentConversationFile!, atomically: true, encoding: .utf8)

        print("📝 Created conversation file: \(filename)")
    }

    // MARK: - Handle Conversation Metadata
    private func handleConversationMetadata(_ payload: String) async {
        guard let data = payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        if let personality = json["personality"] as? String {
            currentPersonality = personality
            print("🎭 Personality: \(personality)")
        }

        if let emoji = json["personality_emoji"] as? String {
            currentPersonalityEmoji = emoji
            print("😀 Emoji: \(emoji)")
        }
    }

    // MARK: - Save Conversation Exchange
    private func saveConversationExchange(user: String, assistant: String, timestamp: Date) async {
        // Use current conversation file or create a default one
        if currentConversationFile == nil {
            await handleConversationStart("{}")
        }

        guard let fileURL = currentConversationFile else { return }

        let entry: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: timestamp),
            "user": user,
            "alex": assistant,
            "personality": currentPersonality,
            "personality_emoji": currentPersonalityEmoji
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: entry)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""

            // Append to file
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let fileHandle = try FileHandle(forWritingTo: fileURL)
                fileHandle.seekToEndOfFile()
                fileHandle.write((jsonString + "\n").data(using: .utf8) ?? Data())
                fileHandle.closeFile()
            } else {
                try (jsonString + "\n").write(to: fileURL, atomically: true, encoding: .utf8)
            }

            print("💾 Saved conversation exchange to \(fileURL.lastPathComponent)")
        } catch {
            print("❌ Failed to save conversation: \(error)")
        }
    }

    deinit {
        // Clean up - terminate process directly since we can't call async methods in deinit
        listenerProcess?.terminate()
    }
}
