import Foundation
import SwiftUI

@MainActor
class AllConversationsViewModel: ObservableObject {
    @Published var conversations: [ConversationSession] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let dockerService: DockerServiceProtocol
    private var refreshTimer: Timer?

    init(dockerService: DockerServiceProtocol) {
        self.dockerService = dockerService
    }

    func loadConversations() async {
        isLoading = true
        errorMessage = nil

        do {
            let pythonScript = """
            from hive.models import MoxieDevice, PersistentData
            import json
            from datetime import datetime

            # Get the device
            device = MoxieDevice.objects.filter(device_id='moxie_001').first()
            if device:
                persist = PersistentData.objects.filter(device=device).first()
                if persist and persist.data:
                    # Get real conversations
                    real_convs = persist.data.get('real_conversations', [])

                    # Group by date/session
                    sessions = {}
                    for conv in real_convs:
                        # Extract date from timestamp
                        timestamp = conv.get('timestamp', '')
                        if timestamp:
                            try:
                                dt = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
                                session_key = f"{dt.strftime('%Y-%m-%d_%H')}"

                                if session_key not in sessions:
                                    sessions[session_key] = {
                                        'id': session_key,
                                        'personality': conv.get('personality', 'Default'),
                                        'timestamp': timestamp,
                                        'messages': []
                                    }

                                # Add both user and moxie messages
                                if conv.get('user'):
                                    sessions[session_key]['messages'].append({
                                        'role': 'user',
                                        'content': conv['user'],
                                        'timestamp': timestamp
                                    })
                                if conv.get('moxie'):
                                    sessions[session_key]['messages'].append({
                                        'role': 'moxie',
                                        'content': conv['moxie'],
                                        'timestamp': timestamp
                                    })
                            except:
                                pass

                    # Convert to list and sort by timestamp
                    session_list = list(sessions.values())
                    session_list.sort(key=lambda x: x['timestamp'], reverse=True)

                    # Output as JSON
                    print(json.dumps(session_list))
                else:
                    print(json.dumps([]))
            else:
                print(json.dumps([]))
            """

            let output = try await dockerService.executePythonScript(pythonScript)

            // Parse the JSON output
            if let jsonData = output.data(using: .utf8),
               let sessionsArray = try? JSONDecoder().decode([ConversationSessionData].self, from: jsonData) {

                // Convert to our model
                conversations = sessionsArray.map { sessionData in
                    let messages = sessionData.messages.map { msg in
                        ChatMessage(
                            role: msg.role,
                            content: msg.content,
                            timestamp: ISO8601DateFormatter().date(from: msg.timestamp) ?? Date()
                        )
                    }

                    return ConversationSession(
                        id: sessionData.id,
                        personality: sessionData.personality,
                        timestamp: ISO8601DateFormatter().date(from: sessionData.timestamp) ?? Date(),
                        messages: messages,
                        messageCount: messages.count
                    )
                }
            } else {
                // No real conversations yet - clear fake data
                conversations = []
            }

        } catch {
            errorMessage = "Failed to load conversations: \(error.localizedDescription)"
            conversations = []
        }

        isLoading = false
    }

    func startAutoRefresh() {
        // Refresh every 5 seconds to show new conversations
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.loadConversations()
            }
        }
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    deinit {
        refreshTimer?.invalidate()
    }
}

// Data structures for JSON parsing
struct ConversationSessionData: Codable {
    let id: String
    let personality: String
    let timestamp: String
    let messages: [MessageData]
}

struct MessageData: Codable {
    let role: String
    let content: String
    let timestamp: String
}

// Model for conversation sessions
struct ConversationSession: Identifiable {
    let id: String
    let personality: String
    let timestamp: Date
    let messages: [ChatMessage]
    let messageCount: Int

    var preview: String {
        if let firstUserMessage = messages.first(where: { $0.role == "user" }) {
            let preview = firstUserMessage.content
            return String(preview.prefix(100)) + (preview.count > 100 ? "..." : "")
        }
        return "No messages"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}