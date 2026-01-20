import SwiftUI

struct ConversationsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: ConversationViewModel
    @State private var searchText = ""
    @State private var selectedConversation: Conversation?
    @State private var showChatViewer = false

    var filteredConversations: [Conversation] {
        viewModel.filterConversations(searchText: searchText)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("💬 Conversation History")
                    .font(.title2)
                    .bold()
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search conversations...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top, 10)

            if viewModel.isLoading {
                ProgressView("Loading conversations...")
                    .padding()
            } else if filteredConversations.isEmpty {
                VStack(spacing: 20) {
                    Text("📭")
                        .font(.system(size: 80))
                    Text(searchText.isEmpty ? "No conversations yet" : "No matching conversations")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? "Start chatting with Moxie to see your conversation history here!" : "Try a different search term")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(40)
            } else {
                List {
                    ForEach(filteredConversations) { conversation in
                        Button(action: {
                            selectedConversation = conversation
                            showChatViewer = true
                        }) {
                            ConversationRow(conversation: conversation)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deleteConversation(conversation)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                viewModel.exportConversation(conversation)
                            } label: {
                                Label("Export", systemImage: "square.and.arrow.up")
                            }
                            .tint(.blue)
                        }
                    }
                }
                .listStyle(.inset)
            }

            // Action buttons
            HStack(spacing: 12) {
                // New Conversation button
                Button(action: {
                    viewModel.startNewConversation()
                }) {
                    HStack {
                        Image(systemName: "plus.message")
                        Text("New Conversation")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }

                // Refresh button
                Button(action: {
                    Task {
                        await viewModel.loadConversations()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding()
        }
        .frame(minWidth: 700, minHeight: 600)
        .task {
            await viewModel.loadConversations()
        }
        .sheet(isPresented: $showChatViewer) {
            if let conversation = selectedConversation {
                ChatViewerView(conversation: conversation)
                    .environmentObject(viewModel)
            }
        }
    }
}

// MARK: - Conversation Row
struct ConversationRow: View {
    let conversation: Conversation
    @EnvironmentObject var viewModel: ConversationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(conversation.title)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text(conversation.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Label(conversation.personality, systemImage: "brain")
                    .font(.caption)
                    .foregroundColor(.blue)

                // Show session intent badge if detected
                if viewModel.currentSessionState.currentIntent != .unknown {
                    SessionIntentBadge(intent: viewModel.currentSessionState.currentIntent)
                }

                Spacer()
                Text("\(conversation.messages.count) messages")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let lastMessage = conversation.messages.last {
                Text(lastMessage.content)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Chat Viewer View
struct ChatViewerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: ConversationViewModel
    let conversation: Conversation

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(conversation.title)
                        .font(.title2)
                        .bold()
                    Text("Personality: \(conversation.personality)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Close") {
                    dismiss()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))

            // Session Intent Indicator
            if viewModel.currentSessionState.currentIntent != .unknown {
                VStack(spacing: 8) {
                    SessionIntentIndicator(sessionState: viewModel.currentSessionState)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Redirection suggestion banner
                    if let suggestion = viewModel.redirectionSuggestion {
                        RedirectionSuggestionBanner(
                            suggestion: suggestion,
                            onAccept: {
                                viewModel.acceptRedirection()
                            },
                            onDismiss: {
                                viewModel.dismissRedirection()
                            }
                        )
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.bottom, 8)
            }

            // Messages
            ScrollViewReader { scrollView in
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        ForEach(conversation.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onAppear {
                    if let lastMessage = conversation.messages.last {
                        scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                    // Check session intent when viewing conversation
                    viewModel.checkSessionIntent(for: conversation)
                }
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                    Text(message.formattedTime)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: 300)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(15)
                    Text(message.formattedTime)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: 300)
                Spacer()
            }
        }
    }
}