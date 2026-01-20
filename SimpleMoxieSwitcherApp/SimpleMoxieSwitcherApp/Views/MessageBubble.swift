//
//  MessageBubble.swift
//  SimpleMoxieSwitcherApp
//
//  Created on 2026-01-06.
//

import SwiftUI
import AppKit

struct MessageBubble: View {
    let message: ChatMessage

    var isUser: Bool {
        message.role == "user"
    }

    var body: some View {
        HStack {
            if isUser {
                Spacer()
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 5) {
                Text(message.content)
                    .padding(12)
                    .background(isUser ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(isUser ? .white : .primary)
                    .cornerRadius(15)
                    .frame(maxWidth: 500, alignment: isUser ? .trailing : .leading)

                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if !isUser {
                Spacer()
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
