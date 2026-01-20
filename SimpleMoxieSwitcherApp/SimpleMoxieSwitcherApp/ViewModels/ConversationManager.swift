//
//  ConversationManager.swift
//  SimpleMoxieSwitcherApp
//
//  Created on 2026-01-06.
//

import SwiftUI
import AppKit

class ConversationManager: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    @Published var statusMessage: String?

    func loadConversations() async {
        isLoading = true
        statusMessage = "Loading conversations from Moxie..."

        do {
            let pythonScript = """
            from hive.models import MoxieDevice, PersistentData
            import json

            # Get the first device
            device = MoxieDevice.objects.first()
            if device:
                persist = PersistentData.objects.filter(device=device).first()
                if persist and persist.data:
                    print(json.dumps(persist.data.get('conversations', [])))
                else:
                    print('[]')
            else:
                print('[]')
            """

            let output = try await runPythonInDocker(pythonScript)

            if let data = output.data(using: .utf8) {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                conversations = try decoder.decode([Conversation].self, from: data)
                statusMessage = "Loaded \\(conversations.count) conversations"
            }
        } catch {
            statusMessage = "Error: \\(error.localizedDescription)"
            conversations = []
        }

        isLoading = false
    }

    func saveConversation(_ conversation: Conversation) async {
        isLoading = true
        statusMessage = "Saving conversation..."

        do {
            var updatedConversations = conversations
            if let index = updatedConversations.firstIndex(where: { $0.id == conversation.id }) {
                updatedConversations[index] = conversation
            } else {
                updatedConversations.append(conversation)
            }

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(updatedConversations)
            let jsonString = String(data: jsonData, encoding: .utf8)!

            let pythonScript = """
            from hive.models import MoxieDevice, PersistentData
            import json

            device = MoxieDevice.objects.first()
            if device:
                persist, created = PersistentData.objects.get_or_create(device=device, defaults={'data': {}})
                persist.data['conversations'] = json.loads('''\\(jsonString)''')
                persist.save()
                print('Saved!')
            """

            _ = try await runPythonInDocker(pythonScript)
            conversations = updatedConversations
            statusMessage = "Conversation saved!"
        } catch {
            statusMessage = "Error saving: \\(error.localizedDescription)"
        }

        isLoading = false
    }

    func deleteConversation(_ conversation: Conversation) async {
        conversations.removeAll { $0.id == conversation.id }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(conversations)
            let jsonString = String(data: jsonData, encoding: .utf8)!

            let pythonScript = """
            from hive.models import MoxieDevice, PersistentData
            import json

            device = MoxieDevice.objects.first()
            if device:
                persist = PersistentData.objects.filter(device=device).first()
                if persist:
                    persist.data['conversations'] = json.loads('''\\(jsonString)''')
                    persist.save()
            """

            _ = try await runPythonInDocker(pythonScript)
        } catch {
            statusMessage = "Error deleting: \\(error.localizedDescription)"
        }
    }

    func exportConversation(_ conversation: Conversation) -> String {
        var export = "# \\(conversation.title)\\n"
        export += "Personality: \\(conversation.personalityEmoji) \\(conversation.personality)\\n"
        export += "Created: \\(formatDate(conversation.createdAt))\\n\\n"
        export += "---\\n\\n"

        for message in conversation.messages {
            let sender = message.role == "user" ? "You" : "Moxie"
            export += "**\\(sender)** (\\(formatDate(message.timestamp))):  \\n"
            export += "\\(message.content)\\n\\n"
        }

        return export
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func runPythonInDocker(_ script: String) async throws -> String {
        let escapedScript = script.replacingOccurrences(of: "\"", with: "\\\"")
        let dockerCommand = "/usr/local/bin/docker exec -w /app/site openmoxie-server python3 manage.py shell -c \"\(escapedScript)\""

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", dockerCommand]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
