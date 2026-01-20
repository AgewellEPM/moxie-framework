//
//  ConversationRow.swift
//  SimpleMoxieSwitcherApp
//
//  Created on 2026-01-06.
//

import SwiftUI
import AppKit

struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            // Personality emoji
            Text(conversation.personalityEmoji)
                .font(.system(size: 40))
                .frame(width: 60, height: 60)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 5) {
                Text(conversation.title)
                    .font(.headline)
                    .lineLimit(1)

                Text(conversation.personality)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let lastMessage = conversation.messages.last {
                    Text(lastMessage.content)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                Text(formatDate(conversation.updatedAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text("\\(conversation.messages.count) messages")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(5)
            }
        }
        .padding(.vertical, 8)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
