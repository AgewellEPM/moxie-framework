//
//  ConversationsView.swift
//  SimpleMoxieSwitcherApp
//
//  Created on 2026-01-06.
//

import SwiftUI
import AppKit

struct ConversationsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var controller: PersonalityController
    @StateObject private var conversationManager = ConversationManager()
    @State private var searchText = ""
    @State private var selectedConversation: Conversation?
    @State private var showChatViewer = false

    var filteredConversations: [Conversation] {
        if searchText.isEmpty {
            return conversationManager.conversations
        } else {
            return conversationManager.conversations.filter { conversation in
                conversation.title.localizedCaseInsensitiveContains(searchText) ||
                conversation.personality.localizedCaseInsensitiveContains(searchText) ||
                conversation.messages.contains { $0.content.localizedCaseInsensitiveContains(searchText) }
            }
        }
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

            if conversationManager.isLoading {
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
                                    await conversationManager.deleteConversation(conversation)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                let exported = conversationManager.exportConversation(conversation)
                                let pasteboard = NSPasteboard.general
                                pasteboard.clearContents()
                                pasteboard.setString(exported, forType: .string)
                            } label: {
                                Label("Export", systemImage: "square.and.arrow.up")
                            }
                            .tint(.blue)
                        }
                    }
                }
                .listStyle(.inset)
            }

            // Refresh button
            Button(action: {
                Task {
                    await conversationManager.loadConversations()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh Conversations")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
        }
        .frame(minWidth: 700, minHeight: 600)
        .task {
            await conversationManager.loadConversations()
        }
        .sheet(isPresented: $showChatViewer) {
            if let conversation = selectedConversation {
                ChatViewerView(conversation: conversation, conversationManager: conversationManager, controller: controller)
            }
        }
    }
}
