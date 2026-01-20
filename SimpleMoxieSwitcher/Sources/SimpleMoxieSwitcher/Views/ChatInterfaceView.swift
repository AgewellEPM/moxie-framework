import SwiftUI

// MARK: - Chat Interface View (ChatGPT Style)
struct ChatInterfaceView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: ChatViewModel
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool
    @State private var selectedConversationFile: ConversationFile?

    init(personality: Personality) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(personality: personality))
    }

    var body: some View {
        HSplitView {
            // Left Sidebar - Conversation History
            conversationSidebar
                .frame(minWidth: 250, idealWidth: 280, maxWidth: 320)

            // Main Chat Area
            mainChatView
                .frame(minWidth: 600)
        }
        .frame(minWidth: 900, minHeight: 600)
        .onAppear {
            Task {
                await viewModel.loadConversationHistory()
                await viewModel.loadCurrentConversation()
            }
        }
    }

    // MARK: - Conversation Sidebar
    private var conversationSidebar: some View {
        VStack(spacing: 0) {
            // Sidebar Header
            HStack {
                Text("\(viewModel.personality.emoji) Conversations")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    Task { await viewModel.startNewConversation() }
                }) {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.black.opacity(0.3))

            Divider()

            // Conversation List
            if viewModel.conversationHistory.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "message")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No conversations yet")
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(viewModel.conversationHistory) { conversation in
                            ConversationSidebarRow(
                                conversation: conversation,
                                isSelected: viewModel.currentConversationFile?.id == conversation.id,
                                onSelect: {
                                    Task {
                                        await viewModel.loadConversation(conversation)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
            }

            Divider()

            // Bottom Actions
            HStack {
                Button(action: {
                    Task { await viewModel.loadConversationHistory() }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)

                Spacer()

                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.black.opacity(0.2))
        }
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Main Chat View
    private var mainChatView: some View {
        VStack(spacing: 0) {
            // Chat Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let current = viewModel.currentConversationFile {
                        Text(current.filename.replacingOccurrences(of: ".jsonl", with: ""))
                            .font(.headline)
                        Text("\(current.messageCount) messages • \(timeAgo(from: current.lastModified))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("New Conversation")
                            .font(.headline)
                    }
                }
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.1))

            Divider()

            // Messages Area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.messages) { message in
                            ChatMessageBubble(message: message)
                                .id(message.id)
                        }

                        if viewModel.isLoading {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Moxie is thinking...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)
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

            Divider()

            // Input Area (ChatGPT style)
            VStack(spacing: 8) {
                if let error = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Dismiss") {
                            viewModel.errorMessage = nil
                        }
                        .font(.caption)
                    }
                    .padding(.horizontal)
                }

                HStack(alignment: .bottom, spacing: 12) {
                    // Text input area
                    ZStack(alignment: .topLeading) {
                        if messageText.isEmpty {
                            Text("Message \(viewModel.personality.name)...")
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 14)
                        }

                        TextEditor(text: $messageText)
                            .font(.body)
                            .frame(minHeight: 44, maxHeight: 120)
                            .focused($isInputFocused)
                            .scrollContentBackground(.hidden)
                            .padding(8)
                    }
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)

                    // Send button
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(canSend ? .blue : .gray)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSend)
                }
                .padding()
            }
            .background(Color(NSColor.windowBackgroundColor))
        }
    }

    private var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isLoading
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messageText = ""
        Task {
            await viewModel.sendMessage(text)
        }
    }

    private func timeAgo(from date: Date) -> String {
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: Date())

        if let days = components.day, days > 0 {
            return "\(days)d ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "Just now"
        }
    }
}

// MARK: - Conversation Sidebar Row
struct ConversationSidebarRow: View {
    let conversation: ConversationFile
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 6) {
                Text(displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .lineLimit(1)

                Text(conversation.preview)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                Text("\(conversation.messageCount) messages")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }

    private var displayName: String {
        conversation.filename
            .replacingOccurrences(of: "moxie_", with: "")
            .replacingOccurrences(of: "_current", with: "")
            .replacingOccurrences(of: ".jsonl", with: "")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}

// MARK: - Chat Message Bubble
struct ChatMessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.isUser {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(18)
                        .textSelection(.enabled)
                        .frame(maxWidth: 500, alignment: .trailing)

                    Text(message.formattedTime)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(18)
                        .textSelection(.enabled)
                        .frame(maxWidth: 500, alignment: .leading)

                    Text(message.formattedTime)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
    }
}

// MARK: - Conversation File Model
struct ConversationFile: Identifiable {
    let id: String
    let filename: String
    let path: URL?  // Optional - not needed for database conversations
    let messages: [[String: Any]]?  // For database conversations
    let messageCount: Int
    let lastModified: Date
    let preview: String
    let personalityEmoji: String?
    let personalityName: String?

    // Init for file-based conversations
    init(id: String, filename: String, path: URL, messageCount: Int, lastModified: Date, preview: String, personalityEmoji: String? = nil, personalityName: String? = nil) {
        self.id = id
        self.filename = filename
        self.path = path
        self.messages = nil
        self.messageCount = messageCount
        self.lastModified = lastModified
        self.preview = preview
        self.personalityEmoji = personalityEmoji
        self.personalityName = personalityName
    }

    // Init for database conversations
    init(id: String, filename: String, messages: [[String: Any]], messageCount: Int, lastModified: Date, preview: String, personalityEmoji: String? = nil, personalityName: String? = nil) {
        self.id = id
        self.filename = filename
        self.path = nil
        self.messages = messages
        self.messageCount = messageCount
        self.lastModified = lastModified
        self.preview = preview
        self.personalityEmoji = personalityEmoji
        self.personalityName = personalityName
    }
}
