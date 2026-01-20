import SwiftUI

struct KnowledgeGraphView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var knowledgeGraphService: KnowledgeGraphService
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("🧠 Knowledge Graph")
                    .font(.title)
                    .fontWeight(.bold)

                Spacer()

                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            // Tab Selector
            Picker("", selection: $selectedTab) {
                Text("Facts").tag(0)
                Text("Topics").tag(1)
                Text("Preferences").tag(2)
                Text("Memories").tag(3)
            }
            .pickerStyle(.segmented)
            .padding()

            Divider()

            // Content
            ScrollView {
                Group {
                    switch selectedTab {
                    case 0: factsView
                    case 1: topicsView
                    case 2: preferencesView
                    case 3: memoriesView
                    default: EmptyView()
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }

    private var factsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(knowledgeGraphService.knowledgeGraph.facts.count) Facts")
                .font(.headline)

            if knowledgeGraphService.knowledgeGraph.facts.isEmpty {
                emptyState(icon: "doc.text", message: "No facts learned yet")
            } else {
                ForEach(knowledgeGraphService.knowledgeGraph.facts) { fact in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(fact.key.capitalized)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text(fact.category)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)
                        }

                        Text(fact.value)
                            .font(.body)

                        Text(fact.timestamp.formatted())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
            }
        }
    }

    private var topicsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(knowledgeGraphService.knowledgeGraph.topics.count) Topics Discussed")
                .font(.headline)

            if knowledgeGraphService.knowledgeGraph.topics.isEmpty {
                emptyState(icon: "bubble.left.and.bubble.right", message: "No topics discussed yet")
            } else {
                let sortedTopics = knowledgeGraphService.knowledgeGraph.topics.sorted { $0.mentions > $1.mentions }

                ForEach(sortedTopics) { topic in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(topic.name.capitalized)
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Text("Mentioned \(topic.mentions) time\(topic.mentions == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text(topic.lastMentioned.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
            }
        }
    }

    private var preferencesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(knowledgeGraphService.knowledgeGraph.preferences.count) Preferences")
                .font(.headline)

            if knowledgeGraphService.knowledgeGraph.preferences.isEmpty {
                emptyState(icon: "heart", message: "No preferences learned yet")
            } else {
                ForEach(knowledgeGraphService.knowledgeGraph.preferences) { pref in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(pref.category.capitalized)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                // Strength indicator
                                ForEach(0..<5) { index in
                                    Image(systemName: Double(index) < pref.strength * 5 ? "star.fill" : "star")
                                        .font(.caption2)
                                        .foregroundColor(.yellow)
                                }
                            }

                            Text(pref.value)
                                .font(.body)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
            }
        }
    }

    private var memoriesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(knowledgeGraphService.knowledgeGraph.memories.count) Memories")
                .font(.headline)

            if knowledgeGraphService.knowledgeGraph.memories.isEmpty {
                emptyState(icon: "brain", message: "No memories stored yet")
            } else {
                let recentMemories = knowledgeGraphService.knowledgeGraph.getRecentMemories(limit: 20)

                ForEach(recentMemories) { memory in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: emotionalIcon(for: memory.emotional_tone))
                                .foregroundColor(emotionalColor(for: memory.emotional_tone))

                            Text(memory.timestamp.formatted())
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            // Importance indicator
                            HStack(spacing: 2) {
                                ForEach(0..<5) { index in
                                    Circle()
                                        .fill(Double(index) < memory.importance * 5 ? Color.blue : Color.gray.opacity(0.3))
                                        .frame(width: 6, height: 6)
                                }
                            }
                        }

                        Text(memory.content)
                            .font(.body)
                            .lineLimit(4)

                        if !memory.tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(memory.tags, id: \.self) { tag in
                                        Text(tag)
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(Color.blue.opacity(0.2))
                                            .cornerRadius(6)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
            }
        }
    }

    private func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(message)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    private func emotionalIcon(for tone: String) -> String {
        switch tone {
        case "positive": return "face.smiling"
        case "negative": return "face.frowning"
        default: return "face.dashed"
        }
    }

    private func emotionalColor(for tone: String) -> Color {
        switch tone {
        case "positive": return .green
        case "negative": return .red
        default: return .gray
        }
    }
}
