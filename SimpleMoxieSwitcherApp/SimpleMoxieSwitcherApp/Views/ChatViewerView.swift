//
//  ChatViewerView.swift
//  SimpleMoxieSwitcherApp
//
//  Created on 2026-01-06.
//

import SwiftUI
import AppKit

struct ChatViewerView: View {
    @Environment(\.dismiss) var dismiss
    let conversation: Conversation
    @ObservedObject var conversationManager: ConversationManager
    @ObservedObject var controller: PersonalityController
    @State private var showingExport = false
    @State private var exportedText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 5) {
                HStack {
                    Button("Back") {
                        dismiss()
                    }
                    Spacer()
                    Menu {
                        Button(action: {
                            exportedText = conversationManager.exportConversation(conversation)
                            showingExport = true
                        }) {
                            Label("Export as Text", systemImage: "square.and.arrow.up")
                        }

                        Button(action: {
                            let pasteboard = NSPasteboard.general
                            pasteboard.clearContents()
                            pasteboard.setString(conversationManager.exportConversation(conversation), forType: .string)
                        }) {
                            Label("Copy to Clipboard", systemImage: "doc.on.clipboard")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                }
                .padding()

                VStack(spacing: 5) {
                    Text(conversation.personalityEmoji)
                        .font(.system(size: 50))
                    Text(conversation.title)
                        .font(.title2)
                        .bold()
                    Text(conversation.personality)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\\(conversation.messages.count) messages • \\(formatDate(conversation.createdAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom)
            }
            .background(Color.gray.opacity(0.05))

            Divider()

            // Messages
            ScrollView {
                ScrollViewReader { proxy in
                    LazyVStack(spacing: 15) {
                        ForEach(conversation.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                    .onAppear {
                        if let lastMessage = conversation.messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .sheet(isPresented: $showingExport) {
            ExportView(text: exportedText, title: conversation.title)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
