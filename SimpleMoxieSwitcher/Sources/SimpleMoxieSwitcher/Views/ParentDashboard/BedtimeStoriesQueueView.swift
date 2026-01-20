import SwiftUI

// MARK: - Models

enum BedtimeStoryGenre: String, Codable, CaseIterable {
    case adventure = "adventure"
    case fantasy = "fantasy"
    case animals = "animals"
    case friendship = "friendship"
    case bedtime = "bedtime"
    case educational = "educational"
    case fairytale = "fairytale"
    case nature = "nature"

    var displayName: String {
        switch self {
        case .adventure: return "Adventure"
        case .fantasy: return "Fantasy"
        case .animals: return "Animals"
        case .friendship: return "Friendship"
        case .bedtime: return "Bedtime"
        case .educational: return "Educational"
        case .fairytale: return "Fairytale"
        case .nature: return "Nature"
        }
    }

    var icon: String {
        switch self {
        case .adventure: return "map.fill"
        case .fantasy: return "wand.and.stars"
        case .animals: return "pawprint.fill"
        case .friendship: return "heart.fill"
        case .bedtime: return "moon.stars.fill"
        case .educational: return "book.fill"
        case .fairytale: return "crown.fill"
        case .nature: return "leaf.fill"
        }
    }

    var color: String {
        switch self {
        case .adventure: return "#FF5722"
        case .fantasy: return "#9C27B0"
        case .animals: return "#795548"
        case .friendship: return "#E91E63"
        case .bedtime: return "#3F51B5"
        case .educational: return "#2196F3"
        case .fairytale: return "#FFD700"
        case .nature: return "#4CAF50"
        }
    }
}

enum StoryLength: String, Codable, CaseIterable {
    case short = "short"       // ~5 min
    case medium = "medium"     // ~10 min
    case long = "long"         // ~15 min
    case extended = "extended" // ~20+ min

    var displayName: String {
        switch self {
        case .short: return "Short (~5 min)"
        case .medium: return "Medium (~10 min)"
        case .long: return "Long (~15 min)"
        case .extended: return "Extended (~20+ min)"
        }
    }

    var shortName: String {
        switch self {
        case .short: return "5 min"
        case .medium: return "10 min"
        case .long: return "15 min"
        case .extended: return "20+ min"
        }
    }
}

struct BedtimeStory: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var genre: BedtimeStoryGenre
    var length: StoryLength
    var themes: [String]
    var ageMin: Int
    var ageMax: Int
    var isFavorite: Bool
    var timesRead: Int
    var lastReadAt: Date?
    var rating: Int?
    var isCustom: Bool
    var customContent: String?

    init(id: UUID = UUID(), title: String, description: String, genre: BedtimeStoryGenre, length: StoryLength, themes: [String] = [], ageMin: Int = 3, ageMax: Int = 10, isFavorite: Bool = false, timesRead: Int = 0, lastReadAt: Date? = nil, rating: Int? = nil, isCustom: Bool = false, customContent: String? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.genre = genre
        self.length = length
        self.themes = themes
        self.ageMin = ageMin
        self.ageMax = ageMax
        self.isFavorite = isFavorite
        self.timesRead = timesRead
        self.lastReadAt = lastReadAt
        self.rating = rating
        self.isCustom = isCustom
        self.customContent = customContent
    }
}

struct StoryQueueItem: Identifiable, Codable {
    let id: UUID
    let storyId: UUID
    var scheduledDate: Date?
    var isCompleted: Bool
    var completedAt: Date?
    let addedAt: Date

    init(id: UUID = UUID(), storyId: UUID, scheduledDate: Date? = nil, isCompleted: Bool = false, completedAt: Date? = nil, addedAt: Date = Date()) {
        self.id = id
        self.storyId = storyId
        self.scheduledDate = scheduledDate
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.addedAt = addedAt
    }
}

struct BedtimeStoriesSettings: Codable {
    var stories: [BedtimeStory] = []
    var queue: [StoryQueueItem] = []
    var preferredGenres: [BedtimeStoryGenre] = []
    var preferredLength: StoryLength = .medium
    var bedtimeHour: Int = 20
    var bedtimeMinute: Int = 0
    var autoSuggestEnabled: Bool = true
    var childAge: Int = 5
}

// MARK: - Main View

struct BedtimeStoriesQueueView: View {
    @State private var settings = BedtimeStoriesSettings()
    @State private var selectedGenre: BedtimeStoryGenre?
    @State private var searchText = ""
    @State private var showingAddStory = false
    @State private var showingStoryDetail: BedtimeStory?
    @State private var showFavoritesOnly = false

    private let defaultStories: [BedtimeStory] = [
        // Adventure Stories
        BedtimeStory(title: "The Brave Little Explorer", description: "A young explorer discovers a hidden cave full of glowing crystals", genre: .adventure, length: .medium, themes: ["courage", "discovery", "nature"], ageMin: 4, ageMax: 8),
        BedtimeStory(title: "Captain Teddy's Voyage", description: "A teddy bear captain sails across the bathtub ocean", genre: .adventure, length: .short, themes: ["imagination", "bravery"], ageMin: 3, ageMax: 6),
        BedtimeStory(title: "The Secret Treehouse", description: "Three friends discover a magical treehouse in the forest", genre: .adventure, length: .long, themes: ["friendship", "mystery", "nature"], ageMin: 5, ageMax: 10),

        // Fantasy Stories
        BedtimeStory(title: "The Dragon Who Couldn't Fly", description: "A young dragon learns that being different is okay", genre: .fantasy, length: .medium, themes: ["acceptance", "perseverance"], ageMin: 4, ageMax: 8),
        BedtimeStory(title: "Princess of the Stars", description: "A princess travels through the night sky on her unicorn", genre: .fantasy, length: .medium, themes: ["dreams", "magic"], ageMin: 3, ageMax: 7),
        BedtimeStory(title: "The Wizard's Apprentice", description: "A young apprentice accidentally turns everything purple", genre: .fantasy, length: .short, themes: ["mistakes", "learning", "humor"], ageMin: 4, ageMax: 9),

        // Animal Stories
        BedtimeStory(title: "Ollie the Owl's First Flight", description: "A baby owl learns to fly with help from his family", genre: .animals, length: .short, themes: ["family", "growth", "courage"], ageMin: 3, ageMax: 6),
        BedtimeStory(title: "The Bunny Who Loved Carrots", description: "A bunny shares her garden with forest friends", genre: .animals, length: .short, themes: ["sharing", "kindness"], ageMin: 2, ageMax: 5),
        BedtimeStory(title: "Deep Sea Friends", description: "Ocean creatures work together to help a lost baby whale", genre: .animals, length: .medium, themes: ["cooperation", "friendship"], ageMin: 4, ageMax: 8),

        // Friendship Stories
        BedtimeStory(title: "The New Kid", description: "Making friends with someone who seems different", genre: .friendship, length: .medium, themes: ["inclusion", "kindness", "diversity"], ageMin: 4, ageMax: 9),
        BedtimeStory(title: "Best Friends Forever", description: "Two friends learn to share and compromise", genre: .friendship, length: .short, themes: ["sharing", "forgiveness"], ageMin: 3, ageMax: 7),
        BedtimeStory(title: "The Shy Superhero", description: "A shy child finds confidence through a new friendship", genre: .friendship, length: .medium, themes: ["confidence", "friendship"], ageMin: 5, ageMax: 10),

        // Bedtime Stories
        BedtimeStory(title: "Goodnight Moon Garden", description: "A peaceful journey through a moonlit garden", genre: .bedtime, length: .short, themes: ["peace", "nature", "sleep"], ageMin: 2, ageMax: 5),
        BedtimeStory(title: "The Sleepy Cloud", description: "A little cloud floats across the sky collecting dreams", genre: .bedtime, length: .short, themes: ["dreams", "imagination"], ageMin: 2, ageMax: 6),
        BedtimeStory(title: "Where Stars Come From", description: "A gentle tale about stars watching over sleeping children", genre: .bedtime, length: .medium, themes: ["comfort", "wonder"], ageMin: 3, ageMax: 7),

        // Educational Stories
        BedtimeStory(title: "Counting Sheep on the Farm", description: "Learn to count with friendly farm animals", genre: .educational, length: .short, themes: ["counting", "animals"], ageMin: 2, ageMax: 5),
        BedtimeStory(title: "The Color Rainbow", description: "Discover how rainbows get their beautiful colors", genre: .educational, length: .medium, themes: ["colors", "nature", "science"], ageMin: 3, ageMax: 7),
        BedtimeStory(title: "A Trip Around the World", description: "Visit different countries and learn about cultures", genre: .educational, length: .long, themes: ["geography", "culture", "diversity"], ageMin: 5, ageMax: 10),

        // Fairytale Stories
        BedtimeStory(title: "The Kind Cobbler", description: "A shoemaker's kindness is magically rewarded", genre: .fairytale, length: .medium, themes: ["kindness", "magic", "reward"], ageMin: 4, ageMax: 9),
        BedtimeStory(title: "The Talking Mirror", description: "A magical mirror teaches a princess about inner beauty", genre: .fairytale, length: .medium, themes: ["self-esteem", "inner beauty"], ageMin: 5, ageMax: 10),
        BedtimeStory(title: "Three Wishes", description: "A child learns to make wishes wisely", genre: .fairytale, length: .short, themes: ["wisdom", "choices"], ageMin: 4, ageMax: 8),

        // Nature Stories
        BedtimeStory(title: "The Little Seed's Journey", description: "A seed grows into a beautiful flower", genre: .nature, length: .short, themes: ["growth", "patience", "nature"], ageMin: 3, ageMax: 6),
        BedtimeStory(title: "Rainy Day Wonders", description: "Discovering the magic in a rainy day", genre: .nature, length: .medium, themes: ["weather", "appreciation"], ageMin: 3, ageMax: 7),
        BedtimeStory(title: "The Forest at Night", description: "Explore the peaceful sounds of the nighttime forest", genre: .nature, length: .medium, themes: ["nature", "calm", "night"], ageMin: 4, ageMax: 9)
    ]

    var allStories: [BedtimeStory] {
        settings.stories.isEmpty ? defaultStories : settings.stories
    }

    var filteredStories: [BedtimeStory] {
        var stories = allStories

        if showFavoritesOnly {
            stories = stories.filter { $0.isFavorite }
        }

        if let genre = selectedGenre {
            stories = stories.filter { $0.genre == genre }
        }

        // Filter by age
        stories = stories.filter { $0.ageMin <= settings.childAge && $0.ageMax >= settings.childAge }

        if !searchText.isEmpty {
            stories = stories.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        return stories
    }

    var queuedStories: [(StoryQueueItem, BedtimeStory)] {
        settings.queue
            .filter { !$0.isCompleted }
            .sorted { ($0.scheduledDate ?? $0.addedAt) < ($1.scheduledDate ?? $1.addedAt) }
            .compactMap { item in
                if let story = allStories.first(where: { $0.id == item.storyId }) {
                    return (item, story)
                }
                return nil
            }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                queueSection
                settingsSection
                librarySection
            }
            .padding(24)
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "#1a237e"), Color(hex: "#4a148c")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onAppear(perform: loadSettings)
        .sheet(isPresented: $showingAddStory) {
            AddStorySheet(onSave: { story in
                if settings.stories.isEmpty {
                    settings.stories = defaultStories
                }
                settings.stories.append(story)
                saveSettings()
            })
        }
        .sheet(item: $showingStoryDetail) { story in
            StoryDetailSheet(story: story, isInQueue: settings.queue.contains { $0.storyId == story.id && !$0.isCompleted }, onAddToQueue: { addToQueue(story) }, onRemoveFromQueue: { removeFromQueue(story) }, onToggleFavorite: { toggleFavorite(story) }, onRate: { rating in rateStory(story, rating: rating) })
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bedtime Stories")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Queue stories for peaceful bedtimes")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            // Tonight's bedtime
            VStack(alignment: .trailing) {
                Text("Bedtime")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Text(bedtimeString)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)

            Button(action: { showingAddStory = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Story")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.2))
                .cornerRadius(20)
                .foregroundColor(.white)
            }
        }
    }

    private var bedtimeString: String {
        let hour = settings.bedtimeHour
        let minute = settings.bedtimeMinute
        let ampm = hour >= 12 ? "PM" : "AM"
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        return String(format: "%d:%02d %@", displayHour, minute, ampm)
    }

    private var queueSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(Color(hex: "#FFD700"))
                Text("Tonight's Queue")
                    .font(.headline)

                Spacer()

                Text("\(queuedStories.count) stories")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if queuedStories.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No stories queued")
                        .font(.headline)
                    Text("Add stories from the library below")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            } else {
                ForEach(Array(queuedStories.enumerated()), id: \.1.0.id) { index, item in
                    let (queueItem, story) = item
                    QueueItemRow(index: index + 1, story: story, queueItem: queueItem, onPlay: { playStory(story, queueItem: queueItem) }, onRemove: { removeFromQueue(story) }, onMoveUp: index > 0 ? { moveInQueue(queueItem, direction: -1) } : nil, onMoveDown: index < queuedStories.count - 1 ? { moveInQueue(queueItem, direction: 1) } : nil)
                }
            }

            // Quick add suggestions
            if !queuedStories.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggested Next")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    let suggestions = getSuggestedStories()
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(suggestions.prefix(5)) { story in
                                SuggestionChip(story: story, onAdd: { addToQueue(story) })
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

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)

            HStack(spacing: 20) {
                // Bedtime picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bedtime")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        Picker("Hour", selection: $settings.bedtimeHour) {
                            ForEach(17..<23) { hour in
                                Text("\(hour > 12 ? hour - 12 : hour) \(hour >= 12 ? "PM" : "AM")").tag(hour)
                            }
                        }
                        .frame(width: 100)

                        Picker("Minute", selection: $settings.bedtimeMinute) {
                            ForEach([0, 15, 30, 45], id: \.self) { minute in
                                Text(String(format: ":%02d", minute)).tag(minute)
                            }
                        }
                        .frame(width: 60)
                    }
                    .onChange(of: settings.bedtimeHour) { _ in saveSettings() }
                    .onChange(of: settings.bedtimeMinute) { _ in saveSettings() }
                }

                Divider()
                    .frame(height: 50)

                // Child age
                VStack(alignment: .leading, spacing: 4) {
                    Text("Child's Age")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Stepper("\(settings.childAge) years old", value: $settings.childAge, in: 2...12)
                        .onChange(of: settings.childAge) { _ in saveSettings() }
                }

                Divider()
                    .frame(height: 50)

                // Preferred length
                VStack(alignment: .leading, spacing: 4) {
                    Text("Preferred Length")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Picker("Length", selection: $settings.preferredLength) {
                        ForEach(StoryLength.allCases, id: \.self) { length in
                            Text(length.shortName).tag(length)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 250)
                    .onChange(of: settings.preferredLength) { _ in saveSettings() }
                }
            }

            // Preferred genres
            VStack(alignment: .leading, spacing: 8) {
                Text("Preferred Genres")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(BedtimeStoryGenre.allCases, id: \.self) { genre in
                            GenreChip(genre: genre, isSelected: settings.preferredGenres.contains(genre), onToggle: {
                                if settings.preferredGenres.contains(genre) {
                                    settings.preferredGenres.removeAll { $0 == genre }
                                } else {
                                    settings.preferredGenres.append(genre)
                                }
                                saveSettings()
                            })
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

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Story Library")
                    .font(.headline)

                Spacer()

                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search stories...", text: $searchText)
                        .frame(width: 150)
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

                // Favorites toggle
                Button(action: { showFavoritesOnly.toggle() }) {
                    HStack {
                        Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                        Text("Favorites")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(showFavoritesOnly ? Color(hex: "#E91E63") : Color.gray.opacity(0.1))
                    .foregroundColor(showFavoritesOnly ? .white : .primary)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }

            // Genre filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button(action: { selectedGenre = nil }) {
                        Text("All")
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedGenre == nil ? Color(hex: "#667eea") : Color.gray.opacity(0.1))
                            .foregroundColor(selectedGenre == nil ? .white : .primary)
                            .cornerRadius(20)
                    }
                    .buttonStyle(.plain)

                    ForEach(BedtimeStoryGenre.allCases, id: \.self) { genre in
                        Button(action: { selectedGenre = genre }) {
                            HStack {
                                Image(systemName: genre.icon)
                                Text(genre.displayName)
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedGenre == genre ? Color(hex: genre.color) : Color.gray.opacity(0.1))
                            .foregroundColor(selectedGenre == genre ? .white : .primary)
                            .cornerRadius(20)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Stories grid
            if filteredStories.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No stories found")
                        .font(.headline)
                    Text("Try adjusting your filters or search")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 250))], spacing: 12) {
                    ForEach(filteredStories) { story in
                        BedtimeStoryCard(story: story, isInQueue: settings.queue.contains { $0.storyId == story.id && !$0.isCompleted }, onTap: { showingStoryDetail = story }, onQuickAdd: { addToQueue(story) })
                    }
                }
            }

            // Stats
            HStack(spacing: 30) {
                VStack {
                    Text("\(allStories.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Total Stories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack {
                    Text("\(allStories.filter { $0.isFavorite }.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Favorites")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack {
                    Text("\(allStories.reduce(0) { $0 + $1.timesRead })")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Times Read")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack {
                    Text("\(allStories.filter { $0.isCustom }.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Custom Stories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    // MARK: - Actions

    private func addToQueue(_ story: BedtimeStory) {
        let item = StoryQueueItem(storyId: story.id)
        settings.queue.append(item)
        saveSettings()
    }

    private func removeFromQueue(_ story: BedtimeStory) {
        settings.queue.removeAll { $0.storyId == story.id && !$0.isCompleted }
        saveSettings()
    }

    private func playStory(_ story: BedtimeStory, queueItem: StoryQueueItem) {
        // Mark as completed
        if let index = settings.queue.firstIndex(where: { $0.id == queueItem.id }) {
            settings.queue[index].isCompleted = true
            settings.queue[index].completedAt = Date()
        }

        // Update story stats
        if settings.stories.isEmpty {
            settings.stories = defaultStories
        }
        if let storyIndex = settings.stories.firstIndex(where: { $0.id == story.id }) {
            settings.stories[storyIndex].timesRead += 1
            settings.stories[storyIndex].lastReadAt = Date()
        }

        saveSettings()
    }

    private func moveInQueue(_ item: StoryQueueItem, direction: Int) {
        let pendingItems = settings.queue.filter { !$0.isCompleted }
        guard let currentIndex = pendingItems.firstIndex(where: { $0.id == item.id }) else { return }

        let newIndex = currentIndex + direction
        guard newIndex >= 0 && newIndex < pendingItems.count else { return }

        // Find actual indices in full queue
        if let fullIndex = settings.queue.firstIndex(where: { $0.id == item.id }),
           let targetId = pendingItems[safe: newIndex]?.id,
           let targetFullIndex = settings.queue.firstIndex(where: { $0.id == targetId }) {
            settings.queue.swapAt(fullIndex, targetFullIndex)
            saveSettings()
        }
    }

    private func toggleFavorite(_ story: BedtimeStory) {
        if settings.stories.isEmpty {
            settings.stories = defaultStories
        }
        if let index = settings.stories.firstIndex(where: { $0.id == story.id }) {
            settings.stories[index].isFavorite.toggle()
            saveSettings()
        }
    }

    private func rateStory(_ story: BedtimeStory, rating: Int) {
        if settings.stories.isEmpty {
            settings.stories = defaultStories
        }
        if let index = settings.stories.firstIndex(where: { $0.id == story.id }) {
            settings.stories[index].rating = rating
            saveSettings()
        }
    }

    private func getSuggestedStories() -> [BedtimeStory] {
        let queuedIds = Set(settings.queue.filter { !$0.isCompleted }.map { $0.storyId })

        return allStories
            .filter { !queuedIds.contains($0.id) }
            .filter { $0.ageMin <= settings.childAge && $0.ageMax >= settings.childAge }
            .filter { settings.preferredGenres.isEmpty || settings.preferredGenres.contains($0.genre) }
            .sorted { ($0.isFavorite ? 1 : 0) > ($1.isFavorite ? 1 : 0) }
    }

    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "bedtimeStoriesSettings"),
           let decoded = try? JSONDecoder().decode(BedtimeStoriesSettings.self, from: data) {
            settings = decoded
        }
    }

    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: "bedtimeStoriesSettings")
        }
    }
}

// MARK: - Supporting Views

struct QueueItemRow: View {
    let index: Int
    let story: BedtimeStory
    let queueItem: StoryQueueItem
    let onPlay: () -> Void
    let onRemove: () -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(.headline)
                .frame(width: 30)
                .foregroundColor(Color(hex: story.genre.color))

            Image(systemName: story.genre.icon)
                .foregroundColor(Color(hex: story.genre.color))

            VStack(alignment: .leading) {
                Text(story.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(story.length.shortName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Reorder buttons
            VStack(spacing: 2) {
                if let moveUp = onMoveUp {
                    Button(action: moveUp) {
                        Image(systemName: "chevron.up")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
                if let moveDown = onMoveDown {
                    Button(action: moveDown) {
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
            .foregroundColor(.secondary)

            Button(action: onPlay) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: "#4CAF50"))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(hex: story.genre.color).opacity(0.05))
        .cornerRadius(12)
    }
}

struct GenreChip: View {
    let genre: BedtimeStoryGenre
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 4) {
                Image(systemName: genre.icon)
                    .font(.caption)
                Text(genre.displayName)
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color(hex: genre.color) : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct SuggestionChip: View {
    let story: BedtimeStory
    let onAdd: () -> Void

    var body: some View {
        Button(action: onAdd) {
            HStack {
                Image(systemName: story.genre.icon)
                    .foregroundColor(Color(hex: story.genre.color))
                Text(story.title)
                    .font(.caption)
                    .lineLimit(1)
                Image(systemName: "plus.circle")
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

struct BedtimeStoryCard: View {
    let story: BedtimeStory
    let isInQueue: Bool
    let onTap: () -> Void
    let onQuickAdd: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: story.genre.icon)
                        .foregroundColor(Color(hex: story.genre.color))

                    Text(story.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer()

                    if story.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(Color(hex: "#E91E63"))
                    }
                }

                Text(story.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack {
                    // Length badge
                    Text(story.length.shortName)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)

                    // Age badge
                    Text("\(story.ageMin)-\(story.ageMax) yrs")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)

                    // Rating
                    if let rating = story.rating {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.caption2)
                                    .foregroundColor(Color(hex: "#FFD700"))
                            }
                        }
                    }

                    Spacer()

                    // Quick add button
                    if !isInQueue {
                        Button(action: { onQuickAdd() }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Color(hex: "#667eea"))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Label("Queued", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(Color(hex: "#4CAF50"))
                    }
                }
            }
            .padding(12)
            .background(isInQueue ? Color(hex: "#4CAF50").opacity(0.05) : Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Story Detail Sheet

struct StoryDetailSheet: View {
    let story: BedtimeStory
    let isInQueue: Bool
    let onAddToQueue: () -> Void
    let onRemoveFromQueue: () -> Void
    let onToggleFavorite: () -> Void
    let onRate: (Int) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var selectedRating: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: story.genre.icon)
                            .foregroundColor(Color(hex: story.genre.color))
                        Text(story.genre.displayName)
                            .font(.subheadline)
                            .foregroundColor(Color(hex: story.genre.color))
                    }
                    Text(story.title)
                        .font(.title)
                        .fontWeight(.bold)
                }

                Spacer()

                Button(action: onToggleFavorite) {
                    Image(systemName: story.isFavorite ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundColor(story.isFavorite ? Color(hex: "#E91E63") : .secondary)
                }
                .buttonStyle(.plain)

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(story.description)
                        .font(.body)

                    // Story info
                    HStack(spacing: 20) {
                        VStack(alignment: .leading) {
                            Text("Length")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(story.length.displayName)
                                .font(.subheadline)
                        }

                        VStack(alignment: .leading) {
                            Text("Age Range")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(story.ageMin)-\(story.ageMax) years")
                                .font(.subheadline)
                        }

                        VStack(alignment: .leading) {
                            Text("Times Read")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(story.timesRead)")
                                .font(.subheadline)
                        }

                        if let lastRead = story.lastReadAt {
                            VStack(alignment: .leading) {
                                Text("Last Read")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(lastRead, style: .relative)
                                    .font(.subheadline)
                            }
                        }
                    }

                    // Themes
                    if !story.themes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Themes")
                                .font(.headline)

                            HStack {
                                ForEach(story.themes, id: \.self) { theme in
                                    Text(theme.capitalized)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color(hex: story.genre.color).opacity(0.1))
                                        .foregroundColor(Color(hex: story.genre.color))
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }

                    // Rating
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Rating")
                            .font(.headline)

                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { star in
                                Button(action: {
                                    selectedRating = star
                                    onRate(star)
                                }) {
                                    Image(systemName: star <= (story.rating ?? selectedRating) ? "star.fill" : "star")
                                        .font(.title2)
                                        .foregroundColor(Color(hex: "#FFD700"))
                                }
                                .buttonStyle(.plain)
                            }

                            if story.rating != nil || selectedRating > 0 {
                                Button(action: {
                                    selectedRating = 0
                                    onRate(0)
                                }) {
                                    Text("Clear")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    // Custom content preview
                    if story.isCustom, let content = story.customContent {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Story Content")
                                .font(.headline)

                            Text(content)
                                .font(.body)
                                .padding()
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }

            Divider()

            // Actions
            HStack {
                if isInQueue {
                    Button(action: {
                        onRemoveFromQueue()
                        dismiss()
                    }) {
                        Label("Remove from Queue", systemImage: "minus.circle")
                    }
                    .foregroundColor(.red)
                } else {
                    Button(action: {
                        onAddToQueue()
                        dismiss()
                    }) {
                        Label("Add to Queue", systemImage: "plus.circle.fill")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color(hex: "#667eea"))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Button("Close") { dismiss() }
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 500)
        .onAppear {
            selectedRating = story.rating ?? 0
        }
    }
}

// MARK: - Add Story Sheet

struct AddStorySheet: View {
    let onSave: (BedtimeStory) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var genre: BedtimeStoryGenre = .bedtime
    @State private var length: StoryLength = .medium
    @State private var ageMin = 3
    @State private var ageMax = 8
    @State private var themes: [String] = []
    @State private var newTheme = ""
    @State private var customContent = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Add Custom Story")
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
                        Text("Story Title")
                            .font(.headline)
                        TextField("Enter story title", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        TextField("Brief description of the story", text: $description)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Genre and Length
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Genre")
                                .font(.headline)
                            Picker("Genre", selection: $genre) {
                                ForEach(BedtimeStoryGenre.allCases, id: \.self) { g in
                                    Label(g.displayName, systemImage: g.icon).tag(g)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Length")
                                .font(.headline)
                            Picker("Length", selection: $length) {
                                ForEach(StoryLength.allCases, id: \.self) { l in
                                    Text(l.displayName).tag(l)
                                }
                            }
                        }
                    }

                    // Age range
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Age Range")
                            .font(.headline)

                        HStack {
                            Stepper("Min: \(ageMin)", value: $ageMin, in: 2...ageMax)
                            Stepper("Max: \(ageMax)", value: $ageMax, in: ageMin...12)
                        }
                    }

                    // Themes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Themes")
                            .font(.headline)

                        HStack {
                            TextField("Add theme", text: $newTheme)
                                .textFieldStyle(.roundedBorder)
                            Button(action: {
                                if !newTheme.isEmpty {
                                    themes.append(newTheme.lowercased())
                                    newTheme = ""
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                            }
                            .disabled(newTheme.isEmpty)
                        }

                        if !themes.isEmpty {
                            HStack {
                                ForEach(themes, id: \.self) { theme in
                                    HStack {
                                        Text(theme)
                                        Button(action: { themes.removeAll { $0 == theme } }) {
                                            Image(systemName: "xmark.circle")
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }

                    // Story content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Story Content (Optional)")
                            .font(.headline)
                        Text("Write the full story text here")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextEditor(text: $customContent)
                            .frame(minHeight: 150)
                            .padding(8)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(8)
                    }
                }
                .padding()
            }

            Divider()

            HStack {
                Spacer()
                Button("Save Story") {
                    let story = BedtimeStory(
                        title: title,
                        description: description,
                        genre: genre,
                        length: length,
                        themes: themes,
                        ageMin: ageMin,
                        ageMax: ageMax,
                        isCustom: true,
                        customContent: customContent.isEmpty ? nil : customContent
                    )
                    onSave(story)
                    dismiss()
                }
                .disabled(title.isEmpty || description.isEmpty)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 600)
    }
}

// Helper extension
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    BedtimeStoriesQueueView()
        .frame(width: 900, height: 700)
}
