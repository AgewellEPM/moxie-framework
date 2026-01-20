import SwiftUI

/// Memory visualization matching Windows version
struct MemoryView: View {
    @StateObject private var viewModel = MemoryVisualizationViewModel()

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left Panel - Categories & Timeline
                leftPanel
                    .frame(width: 300)

                Divider()

                // Center Panel - Memory Grid
                centerPanel
                    .frame(maxWidth: .infinity)

                Divider()

                // Right Panel - Memory Details
                rightPanel
                    .frame(width: 350)
            }
        }
        .background(
            RadialGradient(
                colors: [Color(hex: "2A1A5A"), Color(hex: "0A0A0A")],
                center: .center,
                startRadius: 100,
                endRadius: 600
            )
            .ignoresSafeArea()
        )
        .preferredColorScheme(.dark)
        .onAppear {
            Task {
                await viewModel.loadMemories()
            }
        }
    }

    // MARK: - Left Panel

    private var leftPanel: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 5) {
                Text("🧠 Memory Visualization")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                Text("Explore what Moxie remembers")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "AAAAAA"))
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black.opacity(0.2))

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Total memories badge
                    HStack {
                        Text("💾")
                        Text("\(viewModel.totalMemories)")
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "00CED1"))
                        Text("memories")
                            .foregroundColor(Color(hex: "AAAAAA"))
                    }
                    .padding(15)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(15)

                    // Categories
                    Text("Memory Categories")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    ForEach(viewModel.categories) { category in
                        categoryButton(category)
                    }

                    Divider()
                        .background(Color(hex: "333333"))
                        .padding(.vertical, 10)

                    // Timeline
                    Text("Timeline")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)

                    ForEach(viewModel.timelinePeriods) { period in
                        Toggle(isOn: Binding(
                            get: { period.isVisible },
                            set: { viewModel.toggleTimeline(period.id, isVisible: $0) }
                        )) {
                            HStack {
                                Text(period.name)
                                Text("(\(period.count))")
                                    .foregroundColor(Color(hex: "666666"))
                            }
                            .foregroundColor(.white)
                        }
                        .toggleStyle(.checkbox)
                    }
                }
                .padding(20)
            }
        }
        .background(Color.black.opacity(0.1))
    }

    private func categoryButton(_ category: MemoryCategory) -> some View {
        Button(action: {
            viewModel.selectCategory(category.id)
        }) {
            HStack {
                Text(category.icon)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Text(category.description)
                        .font(.caption2)
                        .foregroundColor(Color(hex: "AAAAAA"))
                }

                Spacer()

                Text("\(category.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(category.isSelected ? Color(hex: "00CED1") : .white)
            }
            .padding(15)
            .background(
                category.isSelected ?
                    Color(hex: "00CED1").opacity(0.2) :
                    Color.white.opacity(0.05)
            )
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Center Panel

    private var centerPanel: some View {
        ScrollView {
            if viewModel.filteredMemories.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.filteredMemories) { memory in
                        memoryCard(memory)
                    }
                }
                .padding(30)
            }
        }
    }

    private func memoryCard(_ memory: MemoryItem) -> some View {
        Button(action: {
            viewModel.selectMemory(memory.id)
        }) {
            HStack(spacing: 20) {
                // Icon
                Circle()
                    .fill(memory.categoryColor)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(memory.icon)
                            .font(.title)
                    )

                // Details
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(memory.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)

                        if memory.isImportant {
                            Text("Important")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .cornerRadius(10)
                        }
                    }

                    Text(memory.description)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "AAAAAA"))
                        .lineLimit(2)

                    HStack(spacing: 15) {
                        Label(memory.date, systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(Color(hex: "666666"))

                        Label("\(memory.connectionCount) connections", systemImage: "link")
                            .font(.caption)
                            .foregroundColor(Color(hex: "666666"))
                    }
                }

                Spacer()

                // Strength indicator
                VStack {
                    Text("Strength")
                        .font(.caption2)
                        .foregroundColor(Color(hex: "AAAAAA"))

                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(hex: "333333"))
                            .frame(width: 80, height: 6)
                            .cornerRadius(3)

                        Rectangle()
                            .fill(memory.strengthColor)
                            .frame(width: 80 * (Double(memory.strength) / 100), height: 6)
                            .cornerRadius(3)
                    }

                    Text("\(memory.strength)%")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.15))
            .cornerRadius(15)
        }
        .buttonStyle(.plain)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Text("🧠")
                .font(.system(size: 64))

            Text("No Memories Yet")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("Moxie will start creating memories as you interact")
                .foregroundColor(Color(hex: "AAAAAA"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(60)
    }

    // MARK: - Right Panel

    private var rightPanel: some View {
        ScrollView {
            if let selected = viewModel.selectedMemory {
                VStack(alignment: .leading, spacing: 20) {
                    // Memory header
                    VStack(spacing: 15) {
                        Circle()
                            .fill(selected.categoryColor)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(selected.icon)
                                    .font(.system(size: 36))
                            )

                        Text(selected.title)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text(selected.date)
                            .font(.caption)
                            .foregroundColor(Color(hex: "AAAAAA"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(15)

                    // Memory content
                    Text(selected.content)
                        .foregroundColor(.white)
                        .padding(15)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(10)

                    // Details
                    Text("Details")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)

                    VStack(spacing: 8) {
                        detailRow(label: "Category:", value: selected.category)
                        detailRow(label: "Created:", value: selected.created)
                        detailRow(label: "Last Access:", value: selected.lastAccess)
                        detailRow(label: "Access Count:", value: "\(selected.accessCount)")
                    }
                    .padding(15)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(10)

                    // Related memories
                    if !selected.relatedMemories.isEmpty {
                        Text("Related Memories")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)

                        ForEach(selected.relatedMemories) { related in
                            relatedMemoryRow(related)
                        }
                    }

                    // Actions
                    VStack(spacing: 10) {
                        actionButton(icon: "📌", label: "Pin Memory") {
                            viewModel.pinMemory(selected.id)
                        }

                        actionButton(icon: "🔗", label: "View Connections") {
                            viewModel.viewConnections(selected.id)
                        }

                        actionButton(icon: "🗑️", label: "Delete Memory", isDestructive: true) {
                            viewModel.deleteMemory(selected.id)
                        }
                    }
                }
                .padding(20)
            } else {
                Text("Select a memory to view details")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "666666"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            }
        }
        .background(Color.black.opacity(0.1))
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(Color(hex: "666666"))
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundColor(.white)
        }
    }

    private func relatedMemoryRow(_ related: RelatedMemory) -> some View {
        Button(action: {
            viewModel.selectMemory(related.id)
        }) {
            HStack {
                Circle()
                    .fill(related.color)
                    .frame(width: 30, height: 30)
                    .overlay(
                        Text(related.icon)
                            .font(.caption)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(related.title)
                        .font(.caption)
                        .foregroundColor(.white)
                    Text(related.date)
                        .font(.caption2)
                        .foregroundColor(Color(hex: "666666"))
                }

                Spacer()
            }
            .padding(10)
            .background(Color.black.opacity(0.2))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private func actionButton(icon: String, label: String, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(icon)
                Text(label)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(isDestructive ? Color.red.opacity(0.6) : Color.white.opacity(0.2))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Supporting ViewModels and Models

@MainActor
class MemoryVisualizationViewModel: ObservableObject {
    @Published var categories: [MemoryCategory] = []
    @Published var timelinePeriods: [TimelinePeriod] = []
    @Published var memories: [MemoryItem] = []
    @Published var selectedMemory: MemoryItem?
    @Published var selectedCategoryId: String?

    var totalMemories: Int {
        memories.count
    }

    var filteredMemories: [MemoryItem] {
        guard let categoryId = selectedCategoryId else {
            return memories
        }
        return memories.filter { $0.categoryId == categoryId }
    }

    func loadMemories() async {
        // Load sample data - replace with actual memory loading from MemoryViewModel
        categories = [
            MemoryCategory(id: "facts", name: "Facts", description: "Things Moxie knows", icon: "📚", count: 24),
            MemoryCategory(id: "preferences", name: "Preferences", description: "Likes and dislikes", icon: "❤️", count: 12),
            MemoryCategory(id: "emotions", name: "Emotions", description: "Emotional moments", icon: "😊", count: 31),
            MemoryCategory(id: "skills", name: "Skills", description: "Things you can do", icon: "🎯", count: 8),
            MemoryCategory(id: "goals", name: "Goals", description: "Things you want to achieve", icon: "🏆", count: 5)
        ]

        timelinePeriods = [
            TimelinePeriod(id: "today", name: "Today", count: 5, isVisible: true),
            TimelinePeriod(id: "week", name: "This Week", count: 18, isVisible: true),
            TimelinePeriod(id: "month", name: "This Month", count: 42, isVisible: true),
            TimelinePeriod(id: "older", name: "Older", count: 15, isVisible: false)
        ]

        // Sample memories
        memories = [
            MemoryItem(
                id: "1",
                categoryId: "facts",
                icon: "🦕",
                title: "Loves Dinosaurs",
                description: "Has a deep fascination with dinosaurs, especially T-Rex",
                date: "Today, 2:30 PM",
                content: "During our conversation, I learned that you absolutely love dinosaurs! Your favorite is the T-Rex because of how powerful and fierce it was.",
                category: "Facts",
                created: "Jan 10, 2026",
                lastAccess: "Just now",
                accessCount: 3,
                strength: 85,
                connectionCount: 4,
                isImportant: true,
                categoryColor: Color.purple,
                strengthColor: Color.green,
                relatedMemories: [
                    RelatedMemory(id: "2", title: "Favorite Movie: Jurassic Park", date: "Yesterday", icon: "🎬", color: Color.red)
                ]
            )
        ]
    }

    func selectCategory(_ categoryId: String) {
        selectedCategoryId = categoryId
        for i in categories.indices {
            categories[i].isSelected = (categories[i].id == categoryId)
        }
    }

    func selectMemory(_ memoryId: String) {
        selectedMemory = memories.first { $0.id == memoryId }
    }

    func toggleTimeline(_ periodId: String, isVisible: Bool) {
        if let index = timelinePeriods.firstIndex(where: { $0.id == periodId }) {
            timelinePeriods[index].isVisible = isVisible
        }
    }

    func pinMemory(_ memoryId: String) {
        print("Pinning memory: \(memoryId)")
    }

    func viewConnections(_ memoryId: String) {
        print("Viewing connections for: \(memoryId)")
    }

    func deleteMemory(_ memoryId: String) {
        memories.removeAll { $0.id == memoryId }
        if selectedMemory?.id == memoryId {
            selectedMemory = nil
        }
    }
}

struct MemoryCategory: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let count: Int
    var isSelected: Bool = false
}

struct TimelinePeriod: Identifiable {
    let id: String
    let name: String
    let count: Int
    var isVisible: Bool
}

struct MemoryItem: Identifiable {
    let id: String
    let categoryId: String
    let icon: String
    let title: String
    let description: String
    let date: String
    let content: String
    let category: String
    let created: String
    let lastAccess: String
    let accessCount: Int
    let strength: Int
    let connectionCount: Int
    let isImportant: Bool
    let categoryColor: Color
    let strengthColor: Color
    let relatedMemories: [RelatedMemory]
}

struct RelatedMemory: Identifiable {
    let id: String
    let title: String
    let date: String
    let icon: String
    let color: Color
}

// Color extension is defined in ModeColors.swift
