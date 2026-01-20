import SwiftUI

// MARK: - Models

enum NoteCategory: String, Codable, CaseIterable {
    case milestone = "milestone"
    case behavior = "behavior"
    case health = "health"
    case learning = "learning"
    case social = "social"
    case memory = "memory"
    case concern = "concern"
    case gratitude = "gratitude"

    var displayName: String {
        switch self {
        case .milestone: return "Milestone"
        case .behavior: return "Behavior"
        case .health: return "Health"
        case .learning: return "Learning"
        case .social: return "Social"
        case .memory: return "Memory"
        case .concern: return "Concern"
        case .gratitude: return "Gratitude"
        }
    }

    var icon: String {
        switch self {
        case .milestone: return "star.fill"
        case .behavior: return "face.smiling.fill"
        case .health: return "heart.fill"
        case .learning: return "book.fill"
        case .social: return "person.2.fill"
        case .memory: return "camera.fill"
        case .concern: return "exclamationmark.circle.fill"
        case .gratitude: return "hands.clap.fill"
        }
    }

    var color: String {
        switch self {
        case .milestone: return "#FFD700"
        case .behavior: return "#FF9800"
        case .health: return "#F44336"
        case .learning: return "#2196F3"
        case .social: return "#4CAF50"
        case .memory: return "#9C27B0"
        case .concern: return "#795548"
        case .gratitude: return "#E91E63"
        }
    }
}

enum NoteMood: String, Codable, CaseIterable {
    case veryHappy = "veryHappy"
    case happy = "happy"
    case neutral = "neutral"
    case sad = "sad"
    case worried = "worried"

    var displayName: String {
        switch self {
        case .veryHappy: return "Very Happy"
        case .happy: return "Happy"
        case .neutral: return "Neutral"
        case .sad: return "Sad"
        case .worried: return "Worried"
        }
    }

    var emoji: String {
        switch self {
        case .veryHappy: return "😄"
        case .happy: return "🙂"
        case .neutral: return "😐"
        case .sad: return "😢"
        case .worried: return "😟"
        }
    }
}

struct ParentalNote: Identifiable, Codable {
    let id: UUID
    var title: String
    var content: String
    var category: NoteCategory
    var mood: NoteMood?
    var tags: [String]
    var isPinned: Bool
    var isPrivate: Bool
    let createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), title: String, content: String, category: NoteCategory, mood: NoteMood? = nil, tags: [String] = [], isPinned: Bool = false, isPrivate: Bool = false, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.content = content
        self.category = category
        self.mood = mood
        self.tags = tags
        self.isPinned = isPinned
        self.isPrivate = isPrivate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct JournalPrompt: Identifiable {
    let id = UUID()
    let prompt: String
    let category: NoteCategory
}

struct ParentalNotesSettings: Codable {
    var notes: [ParentalNote] = []
    var customTags: [String] = []
    var showPrivateNotes: Bool = true
    var sortNewestFirst: Bool = true
}

// MARK: - Main View

struct ParentalNotesView: View {
    @State private var settings = ParentalNotesSettings()
    @State private var searchText = ""
    @State private var selectedCategory: NoteCategory?
    @State private var selectedTag: String?
    @State private var showingAddNote = false
    @State private var showingNoteDetail: ParentalNote?
    @State private var showingPrompts = false

    private let journalPrompts: [JournalPrompt] = [
        JournalPrompt(prompt: "What made me proud of my child today?", category: .milestone),
        JournalPrompt(prompt: "A new word or phrase my child learned...", category: .learning),
        JournalPrompt(prompt: "How did my child handle a difficult emotion today?", category: .behavior),
        JournalPrompt(prompt: "A funny thing my child said or did...", category: .memory),
        JournalPrompt(prompt: "Something new my child tried today...", category: .milestone),
        JournalPrompt(prompt: "How my child showed kindness to others...", category: .social),
        JournalPrompt(prompt: "A worry I have about my child...", category: .concern),
        JournalPrompt(prompt: "What I'm grateful for about my child today...", category: .gratitude),
        JournalPrompt(prompt: "How my child's health has been lately...", category: .health),
        JournalPrompt(prompt: "A special moment we shared together...", category: .memory)
    ]

    var filteredNotes: [ParentalNote] {
        var notes = settings.notes

        if !settings.showPrivateNotes {
            notes = notes.filter { !$0.isPrivate }
        }

        if let category = selectedCategory {
            notes = notes.filter { $0.category == category }
        }

        if let tag = selectedTag {
            notes = notes.filter { $0.tags.contains(tag) }
        }

        if !searchText.isEmpty {
            notes = notes.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Sort: pinned first, then by date
        notes = notes.sorted { note1, note2 in
            if note1.isPinned != note2.isPinned {
                return note1.isPinned
            }
            return settings.sortNewestFirst ? note1.createdAt > note2.createdAt : note1.createdAt < note2.createdAt
        }

        return notes
    }

    var allTags: [String] {
        var tags = Set<String>()
        for note in settings.notes {
            tags.formUnion(note.tags)
        }
        tags.formUnion(settings.customTags)
        return Array(tags).sorted()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                statsSection
                promptsSection
                notesListSection
            }
            .padding(24)
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "#667eea"), Color(hex: "#764ba2")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onAppear(perform: loadSettings)
        .sheet(isPresented: $showingAddNote) {
            AddNoteSheet(existingTags: allTags, onSave: { note in
                settings.notes.append(note)
                saveSettings()
            })
        }
        .sheet(item: $showingNoteDetail) { note in
            NoteDetailSheet(note: note, existingTags: allTags, onUpdate: { updated in
                if let index = settings.notes.firstIndex(where: { $0.id == updated.id }) {
                    settings.notes[index] = updated
                    saveSettings()
                }
            }, onDelete: { noteId in
                settings.notes.removeAll { $0.id == noteId }
                saveSettings()
            })
        }
        .sheet(isPresented: $showingPrompts) {
            PromptsSheet(prompts: journalPrompts, onSelect: { prompt in
                showingPrompts = false
                // Create new note with prompt
                let note = ParentalNote(
                    title: "",
                    content: prompt.prompt,
                    category: prompt.category
                )
                showingNoteDetail = note
            })
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Parental Notes")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Journal your child's journey")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: { showingPrompts = true }) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                        Text("Prompts")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
                    .foregroundColor(.white)
                }

                Button(action: { showingAddNote = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("New Note")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
                    .foregroundColor(.white)
                }
            }
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Journal Stats")
                    .font(.headline)

                Spacer()

                Toggle("Show Private", isOn: $settings.showPrivateNotes)
                    .toggleStyle(.switch)
                    .onChange(of: settings.showPrivateNotes) { _ in saveSettings() }
            }

            HStack(spacing: 20) {
                NoteStatBox(title: "Total Notes", value: "\(settings.notes.count)", icon: "doc.text.fill", color: "#2196F3")

                NoteStatBox(title: "This Week", value: "\(notesThisWeek)", icon: "calendar", color: "#4CAF50")

                NoteStatBox(title: "Pinned", value: "\(settings.notes.filter { $0.isPinned }.count)", icon: "pin.fill", color: "#FF9800")

                NoteStatBox(title: "Categories", value: "\(Set(settings.notes.map { $0.category }).count)", icon: "folder.fill", color: "#9C27B0")
            }

            // Category breakdown
            if !settings.notes.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(NoteCategory.allCases, id: \.self) { category in
                            let count = settings.notes.filter { $0.category == category }.count
                            if count > 0 {
                                CategoryBadge(category: category, count: count, isSelected: selectedCategory == category, onTap: {
                                    selectedCategory = selectedCategory == category ? nil : category
                                })
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    private var notesThisWeek: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return settings.notes.filter { $0.createdAt >= weekAgo }.count
    }

    private var promptsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Prompt")
                .font(.headline)
                .foregroundColor(.white)

            let todayPrompt = journalPrompts[Calendar.current.component(.day, from: Date()) % journalPrompts.count]

            Button(action: {
                let note = ParentalNote(
                    title: "",
                    content: todayPrompt.prompt,
                    category: todayPrompt.category
                )
                showingNoteDetail = note
            }) {
                HStack {
                    Image(systemName: todayPrompt.category.icon)
                        .foregroundColor(Color(hex: todayPrompt.category.color))
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(todayPrompt.prompt)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)

                        Text("Tap to start writing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
    }

    private var notesListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Notes")
                    .font(.headline)

                Spacer()

                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search notes...", text: $searchText)
                        .frame(width: 150)
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

                // Sort toggle
                Button(action: {
                    settings.sortNewestFirst.toggle()
                    saveSettings()
                }) {
                    HStack {
                        Image(systemName: "arrow.up.arrow.down")
                        Text(settings.sortNewestFirst ? "Newest" : "Oldest")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }

            // Filters
            HStack(spacing: 12) {
                // Category filter
                Menu {
                    Button("All Categories") {
                        selectedCategory = nil
                    }
                    Divider()
                    ForEach(NoteCategory.allCases, id: \.self) { category in
                        Button(action: { selectedCategory = category }) {
                            Label(category.displayName, systemImage: category.icon)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: selectedCategory?.icon ?? "folder")
                        Text(selectedCategory?.displayName ?? "Category")
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }

                // Tag filter
                if !allTags.isEmpty {
                    Menu {
                        Button("All Tags") {
                            selectedTag = nil
                        }
                        Divider()
                        ForEach(allTags, id: \.self) { tag in
                            Button(action: { selectedTag = tag }) {
                                Label(tag, systemImage: "tag")
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "tag")
                            Text(selectedTag ?? "Tag")
                            Image(systemName: "chevron.down")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }

                if selectedCategory != nil || selectedTag != nil {
                    Button("Clear Filters") {
                        selectedCategory = nil
                        selectedTag = nil
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                Text("\(filteredNotes.count) notes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Notes grid
            if filteredNotes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "note.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No notes yet")
                        .font(.headline)
                    Text("Start journaling your child's special moments")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button(action: { showingAddNote = true }) {
                        Text("Write First Note")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color(hex: "#667eea"))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 280))], spacing: 12) {
                    ForEach(filteredNotes) { note in
                        NoteCard(note: note, onTap: { showingNoteDetail = note }, onTogglePin: { togglePin(note) })
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    private func togglePin(_ note: ParentalNote) {
        if let index = settings.notes.firstIndex(where: { $0.id == note.id }) {
            settings.notes[index].isPinned.toggle()
            saveSettings()
        }
    }

    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "parentalNotesSettings"),
           let decoded = try? JSONDecoder().decode(ParentalNotesSettings.self, from: data) {
            settings = decoded
        }
    }

    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: "parentalNotesSettings")
        }
    }
}

// MARK: - Supporting Views

struct NoteStatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color(hex: color))

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(hex: color).opacity(0.1))
        .cornerRadius(12)
    }
}

struct CategoryBadge: View {
    let category: NoteCategory
    let count: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.displayName)
                    .font(.caption)
                Text("\(count)")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.3))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color(hex: category.color) : Color(hex: category.color).opacity(0.2))
            .foregroundColor(isSelected ? .white : Color(hex: category.color))
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

struct NoteCard: View {
    let note: ParentalNote
    let onTap: () -> Void
    let onTogglePin: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: note.category.icon)
                        .foregroundColor(Color(hex: note.category.color))

                    if !note.title.isEmpty {
                        Text(note.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    } else {
                        Text(note.category.displayName)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if note.isPrivate {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Button(action: { onTogglePin() }) {
                        Image(systemName: note.isPinned ? "pin.fill" : "pin")
                            .foregroundColor(note.isPinned ? Color(hex: "#FF9800") : .secondary)
                    }
                    .buttonStyle(.plain)
                }

                Text(note.content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                HStack {
                    if let mood = note.mood {
                        Text(mood.emoji)
                            .font(.caption)
                    }

                    if !note.tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(note.tags.prefix(2), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption2)
                                    .foregroundColor(Color(hex: note.category.color))
                            }
                            if note.tags.count > 2 {
                                Text("+\(note.tags.count - 2)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Spacer()

                    Text(note.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(note.isPinned ? Color(hex: "#FFF3E0") : Color.gray.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: note.category.color).opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Note Sheet

struct AddNoteSheet: View {
    let existingTags: [String]
    let onSave: (ParentalNote) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var content = ""
    @State private var category: NoteCategory = .memory
    @State private var mood: NoteMood?
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var isPrivate = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("New Note")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Cancel") { dismiss() }
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title (Optional)")
                            .font(.headline)
                        TextField("Give your note a title", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Category
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.headline)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: 8) {
                            ForEach(NoteCategory.allCases, id: \.self) { cat in
                                Button(action: { category = cat }) {
                                    HStack {
                                        Image(systemName: cat.icon)
                                        Text(cat.displayName)
                                            .font(.caption)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(category == cat ? Color(hex: cat.color) : Color.gray.opacity(0.1))
                                    .foregroundColor(category == cat ? .white : .primary)
                                    .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note")
                            .font(.headline)

                        TextEditor(text: $content)
                            .frame(minHeight: 150)
                            .padding(8)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(8)
                    }

                    // Mood
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mood (Optional)")
                            .font(.headline)

                        HStack(spacing: 12) {
                            ForEach(NoteMood.allCases, id: \.self) { m in
                                Button(action: { mood = mood == m ? nil : m }) {
                                    VStack {
                                        Text(m.emoji)
                                            .font(.title)
                                        Text(m.displayName)
                                            .font(.caption2)
                                    }
                                    .padding(8)
                                    .background(mood == m ? Color(hex: "#667eea").opacity(0.2) : Color.gray.opacity(0.05))
                                    .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Tags
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.headline)

                        HStack {
                            TextField("Add tag", text: $newTag)
                                .textFieldStyle(.roundedBorder)
                            Button(action: {
                                if !newTag.isEmpty && !tags.contains(newTag.lowercased()) {
                                    tags.append(newTag.lowercased())
                                    newTag = ""
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                            }
                            .disabled(newTag.isEmpty)
                        }

                        // Selected tags
                        if !tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(tags, id: \.self) { tag in
                                        HStack {
                                            Text("#\(tag)")
                                            Button(action: { tags.removeAll { $0 == tag } }) {
                                                Image(systemName: "xmark.circle")
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color(hex: category.color).opacity(0.2))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }

                        // Existing tags suggestions
                        if !existingTags.isEmpty {
                            Text("Suggested tags:")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(existingTags.filter { !tags.contains($0) }.prefix(10), id: \.self) { tag in
                                        Button(action: { tags.append(tag) }) {
                                            Text("#\(tag)")
                                                .font(.caption)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(Color.gray.opacity(0.1))
                                                .cornerRadius(12)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }

                    // Privacy toggle
                    Toggle("Private Note", isOn: $isPrivate)
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                }
                .padding()
            }

            Divider()

            HStack {
                Spacer()
                Button("Save Note") {
                    let note = ParentalNote(
                        title: title,
                        content: content,
                        category: category,
                        mood: mood,
                        tags: tags,
                        isPrivate: isPrivate
                    )
                    onSave(note)
                    dismiss()
                }
                .disabled(content.isEmpty)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 600)
    }
}

// MARK: - Note Detail Sheet

struct NoteDetailSheet: View {
    let note: ParentalNote
    let existingTags: [String]
    let onUpdate: (ParentalNote) -> Void
    let onDelete: (UUID) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var currentNote: ParentalNote
    @State private var isEditing = false
    @State private var newTag = ""

    init(note: ParentalNote, existingTags: [String], onUpdate: @escaping (ParentalNote) -> Void, onDelete: @escaping (UUID) -> Void) {
        self.note = note
        self.existingTags = existingTags
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        _currentNote = State(initialValue: note)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: currentNote.category.icon)
                            .foregroundColor(Color(hex: currentNote.category.color))
                        Text(currentNote.category.displayName)
                            .font(.subheadline)
                            .foregroundColor(Color(hex: currentNote.category.color))
                    }

                    if !currentNote.title.isEmpty {
                        Text(currentNote.title)
                            .font(.title)
                            .fontWeight(.bold)
                    }
                }

                Spacer()

                HStack(spacing: 12) {
                    if currentNote.isPrivate {
                        Label("Private", systemImage: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Button(action: { isEditing.toggle() }) {
                        Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle")
                            .font(.title2)
                            .foregroundColor(Color(hex: "#667eea"))
                    }
                    .buttonStyle(.plain)

                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Content
                    if isEditing {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.headline)
                            TextField("Title", text: $currentNote.title)
                                .textFieldStyle(.roundedBorder)

                            Text("Content")
                                .font(.headline)
                            TextEditor(text: $currentNote.content)
                                .frame(minHeight: 200)
                                .padding(8)
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(8)
                        }
                    } else {
                        Text(currentNote.content)
                            .font(.body)
                    }

                    // Mood
                    if let mood = currentNote.mood {
                        HStack {
                            Text("Mood:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(mood.emoji)
                            Text(mood.displayName)
                                .font(.subheadline)
                        }
                    }

                    // Tags
                    if !currentNote.tags.isEmpty || isEditing {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .font(.headline)

                            if isEditing {
                                HStack {
                                    TextField("Add tag", text: $newTag)
                                        .textFieldStyle(.roundedBorder)
                                    Button(action: {
                                        if !newTag.isEmpty && !currentNote.tags.contains(newTag.lowercased()) {
                                            currentNote.tags.append(newTag.lowercased())
                                            newTag = ""
                                        }
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                    }
                                    .disabled(newTag.isEmpty)
                                }
                            }

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(currentNote.tags, id: \.self) { tag in
                                        HStack {
                                            Text("#\(tag)")
                                            if isEditing {
                                                Button(action: { currentNote.tags.removeAll { $0 == tag } }) {
                                                    Image(systemName: "xmark.circle")
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color(hex: currentNote.category.color).opacity(0.2))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                    }

                    // Metadata
                    HStack(spacing: 30) {
                        VStack(alignment: .leading) {
                            Text("Created")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(currentNote.createdAt, style: .date)
                                .font(.subheadline)
                            Text(currentNote.createdAt, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if currentNote.updatedAt != currentNote.createdAt {
                            VStack(alignment: .leading) {
                                Text("Last Updated")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(currentNote.updatedAt, style: .relative)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)

                    // Category change (editing mode)
                    if isEditing {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.headline)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))], spacing: 8) {
                                ForEach(NoteCategory.allCases, id: \.self) { cat in
                                    Button(action: { currentNote.category = cat }) {
                                        HStack {
                                            Image(systemName: cat.icon)
                                            Text(cat.displayName)
                                                .font(.caption)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(currentNote.category == cat ? Color(hex: cat.color) : Color.gray.opacity(0.1))
                                        .foregroundColor(currentNote.category == cat ? .white : .primary)
                                        .cornerRadius(10)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        Toggle("Private Note", isOn: $currentNote.isPrivate)
                    }
                }
                .padding()
            }

            Divider()

            // Footer
            HStack {
                Button(role: .destructive, action: {
                    onDelete(note.id)
                    dismiss()
                }) {
                    Label("Delete", systemImage: "trash")
                }

                Spacer()

                if isEditing {
                    Button("Save Changes") {
                        currentNote.updatedAt = Date()
                        onUpdate(currentNote)
                        isEditing = false
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Done") { dismiss() }
                }
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 500)
    }
}

// MARK: - Prompts Sheet

struct PromptsSheet: View {
    let prompts: [JournalPrompt]
    let onSelect: (JournalPrompt) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Journal Prompts")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Cancel") { dismiss() }
            }
            .padding()

            Divider()

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(prompts) { prompt in
                        Button(action: { onSelect(prompt) }) {
                            HStack {
                                Image(systemName: prompt.category.icon)
                                    .foregroundColor(Color(hex: prompt.category.color))
                                    .frame(width: 30)

                                Text(prompt.prompt)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(hex: prompt.category.color).opacity(0.1))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

#Preview {
    ParentalNotesView()
        .frame(width: 900, height: 700)
}
