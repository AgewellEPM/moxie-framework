//
//  CustomPersonalityView.swift
//  SimpleMoxieSwitcherApp
//
//  Created on 2026-01-06.
//

import SwiftUI
import AppKit

struct CustomPersonalityView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var controller: PersonalityController

    @State private var name = ""
    @State private var emoji = "🎨"
    @State private var showEmojiPicker = false
    @State private var prompt = ""
    @State private var opener = ""
    @State private var goal = ""
    @State private var learningObjective = ""
    @State private var aiModel = "gpt-4"
    @State private var temperature = 0.7
    @State private var maxTokens = 70
    @State private var topP = 1.0
    @State private var frequencyPenalty = 0.0
    @State private var presencePenalty = 0.0

    let emojiOptions = ["🎨", "🤖", "🧠", "📚", "🎓", "🔬", "🧪", "🎭", "🎪", "🎨", "🌟", "⭐", "✨", "💫", "🌈", "🔥", "💡", "🎯", "🏆", "👑", "🦁", "🐯", "🦊", "🐺", "🦉", "🦅", "🐉", "🦄", "🎮", "🎲", "🎪", "🎭", "🎬", "🎨", "🎹", "🎸", "🎺", "🎷", "🎻", "🥁", "📱", "💻", "🖥️", "⌨️", "🖱️", "🕹️", "🎧", "🎤", "📷", "📹"]

    let aiModels = [
        "gpt-4",
        "gpt-4-turbo",
        "gpt-3.5-turbo",
        "claude-3-opus",
        "claude-3-sonnet",
        "claude-3-haiku",
        "llama-3-70b",
        "llama-3-8b",
        "mixtral-8x7b",
        "gemini-pro",
        "palm-2"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("✨ Create Custom Personality")
                    .font(.title2)
                    .bold()
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))

            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    // Basic Info
                    VStack(alignment: .leading, spacing: 10) {
                        Text("NAME & EMOJI")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: 15) {
                            TextField("Personality Name", text: $name)
                                .textFieldStyle(.roundedBorder)
                                .font(.body)

                            // Emoji Button with Picker
                            Button(action: {
                                showEmojiPicker.toggle()
                            }) {
                                Text(emoji)
                                    .font(.system(size: 40))
                                    .frame(width: 80, height: 50)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            .popover(isPresented: $showEmojiPicker) {
                                VStack {
                                    Text("Select Emoji")
                                        .font(.headline)
                                        .padding()

                                    ScrollView {
                                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 10) {
                                            ForEach(emojiOptions, id: \.self) { emojiOption in
                                                Button(action: {
                                                    emoji = emojiOption
                                                    showEmojiPicker = false
                                                }) {
                                                    Text(emojiOption)
                                                        .font(.system(size: 35))
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .padding()
                                    }
                                }
                                .frame(width: 400, height: 300)
                            }
                        }
                    }

                    Divider()

                    // AI Model Selection
                    VStack(alignment: .leading, spacing: 10) {
                        Text("AI MODEL")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Choose which AI model Moxie should use")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Picker("AI Model", selection: $aiModel) {
                            ForEach(aiModels, id: \.self) { model in
                                Text(model).tag(model)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color.purple.opacity(0.05))
                        .cornerRadius(8)
                    }

                    Divider()

                    // Goal & Learning Objective
                    VStack(alignment: .leading, spacing: 10) {
                        Text("GOAL & LEARNING OBJECTIVE")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("What should Moxie help you achieve or learn?")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        VStack(spacing: 10) {
                            TextField("Goal (e.g., Learn Math, Practice Spanish, Build Confidence)", text: $goal)
                                .textFieldStyle(.roundedBorder)
                                .font(.body)

                            TextEditor(text: $learningObjective)
                                .frame(height: 80)
                                .font(.system(.body))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            Text("Detailed objective (e.g., 'Make sure I understand algebra and can solve quadratic equations')")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color.orange.opacity(0.05))
                        .cornerRadius(8)
                    }

                    Divider()

                    // Personality Prompt
                    VStack(alignment: .leading, spacing: 10) {
                        Text("PERSONALITY PROMPT")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Describe how Moxie should act and talk")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        TextEditor(text: $prompt)
                            .frame(height: 180)
                            .font(.system(.body))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }

                    Divider()

                    // Opening Line
                    VStack(alignment: .leading, spacing: 10) {
                        Text("OPENING LINE")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("What Moxie says when he wakes up")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        TextEditor(text: $opener)
                            .frame(height: 80)
                            .font(.system(.body))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }

                    Divider()

                    // AI Settings
                    VStack(alignment: .leading, spacing: 20) {
                        Text("ADVANCED AI SETTINGS")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        // Temperature
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Temperature")
                                    .font(.subheadline)
                                    .bold()
                                Spacer()
                                Text(String(format: "%.2f", temperature))
                                    .font(.title3)
                                    .bold()
                                    .foregroundColor(.blue)
                            }

                            Slider(value: $temperature, in: 0...2, step: 0.01)
                                .tint(.blue)

                            Text("0 = Focused & Consistent  •  1 = Balanced  •  2 = Wild & Creative")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(8)

                        // Max Tokens
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Max Tokens (Response Length)")
                                    .font(.subheadline)
                                    .bold()
                                Spacer()
                                Text("\(maxTokens)")
                                    .font(.title3)
                                    .bold()
                                    .foregroundColor(.green)
                            }

                            Slider(value: Binding(
                                get: { Double(maxTokens) },
                                set: { maxTokens = Int($0) }
                            ), in: 30...4000, step: 10)
                                .tint(.green)

                            Text("30 = Short  •  70 = Normal  •  200 = Long  •  4000 = Maximum")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.green.opacity(0.05))
                        .cornerRadius(8)

                        // Top P
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Top P (Nucleus Sampling)")
                                    .font(.subheadline)
                                    .bold()
                                Spacer()
                                Text(String(format: "%.2f", topP))
                                    .font(.title3)
                                    .bold()
                                    .foregroundColor(.purple)
                            }

                            Slider(value: $topP, in: 0...1, step: 0.01)
                                .tint(.purple)

                            Text("Controls diversity via nucleus sampling. 1.0 = All possibilities  •  0.5 = Top 50%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.purple.opacity(0.05))
                        .cornerRadius(8)

                        // Frequency Penalty
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Frequency Penalty")
                                    .font(.subheadline)
                                    .bold()
                                Spacer()
                                Text(String(format: "%.2f", frequencyPenalty))
                                    .font(.title3)
                                    .bold()
                                    .foregroundColor(.orange)
                            }

                            Slider(value: $frequencyPenalty, in: -2...2, step: 0.01)
                                .tint(.orange)

                            Text("Reduces repetition. 0 = No penalty  •  Positive = Less repetition  •  Negative = More repetition")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.05))
                        .cornerRadius(8)

                        // Presence Penalty
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Presence Penalty")
                                    .font(.subheadline)
                                    .bold()
                                Spacer()
                                Text(String(format: "%.2f", presencePenalty))
                                    .font(.title3)
                                    .bold()
                                    .foregroundColor(.pink)
                            }

                            Slider(value: $presencePenalty, in: -2...2, step: 0.01)
                                .tint(.pink)

                            Text("Encourages new topics. 0 = Neutral  •  Positive = More topics  •  Negative = Stay on topic")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.pink.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
                .padding(20)
            }

            // Bottom Button
            Button(action: {
                let custom = Personality(
                    name: name.isEmpty ? "Custom" : name,
                    prompt: prompt,
                    opener: opener.isEmpty ? "Hello!" : opener,
                    temperature: temperature,
                    maxTokens: maxTokens,
                    emoji: emoji.isEmpty ? "🎨" : emoji
                )

                Task {
                    await controller.switchPersonality(custom)
                    dismiss()
                }
            }) {
                Text("Apply Custom Personality")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(prompt.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(10)
            }
            .disabled(prompt.isEmpty)
            .padding()
        }
        .frame(minWidth: 700, minHeight: 800)
    }
}
