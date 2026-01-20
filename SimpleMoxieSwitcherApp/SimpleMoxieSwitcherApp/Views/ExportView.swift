//
//  ExportView.swift
//  SimpleMoxieSwitcherApp
//
//  Created on 2026-01-06.
//

import SwiftUI
import AppKit

struct ExportView: View {
    @Environment(\.dismiss) var dismiss
    let text: String
    let title: String
    @State private var saved = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Export: \\(title)")
                    .font(.title3)
                    .bold()
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))

            TextEditor(text: .constant(text))
                .font(.system(.body, design: .monospaced))
                .padding()

            HStack(spacing: 15) {
                Button(action: {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(text, forType: .string)
                    saved = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        saved = false
                    }
                }) {
                    Label(saved ? "Copied!" : "Copy to Clipboard", systemImage: saved ? "checkmark" : "doc.on.clipboard")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(saved ? Color.green : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button(action: {
                    let savePanel = NSSavePanel()
                    savePanel.allowedContentTypes = [.plainText]
                    savePanel.nameFieldStringValue = "\\(title).txt"

                    if savePanel.runModal() == .OK, let url = savePanel.url {
                        try? text.write(to: url, atomically: true, encoding: .utf8)
                    }
                }) {
                    Label("Save to File", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}
