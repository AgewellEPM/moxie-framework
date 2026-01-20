import SwiftUI

// MARK: - Models

enum ActivityCategory: String, Codable, CaseIterable {
    case outdoor = "outdoor"
    case indoor = "indoor"
    case creative = "creative"
    case educational = "educational"
    case cooking = "cooking"
    case exercise = "exercise"
    case mindfulness = "mindfulness"
    case social = "social"

    var displayName: String {
        switch self {
        case .outdoor: return "Outdoor Adventures"
        case .indoor: return "Indoor Fun"
        case .creative: return "Creative Arts"
        case .educational: return "Learning Together"
        case .cooking: return "Kitchen Adventures"
        case .exercise: return "Move & Play"
        case .mindfulness: return "Calm & Connect"
        case .social: return "Social Skills"
        }
    }

    var icon: String {
        switch self {
        case .outdoor: return "leaf.fill"
        case .indoor: return "house.fill"
        case .creative: return "paintbrush.fill"
        case .educational: return "book.fill"
        case .cooking: return "fork.knife"
        case .exercise: return "figure.run"
        case .mindfulness: return "heart.fill"
        case .social: return "person.2.fill"
        }
    }

    var color: String {
        switch self {
        case .outdoor: return "#4CAF50"
        case .indoor: return "#FF9800"
        case .creative: return "#E91E63"
        case .educational: return "#2196F3"
        case .cooking: return "#795548"
        case .exercise: return "#F44336"
        case .mindfulness: return "#9C27B0"
        case .social: return "#00BCD4"
        }
    }
}

enum ActivityDuration: String, Codable, CaseIterable {
    case quick = "quick"        // 5-15 min
    case medium = "medium"      // 15-30 min
    case long = "long"          // 30-60 min
    case extended = "extended"  // 1+ hour

    var displayName: String {
        switch self {
        case .quick: return "Quick (5-15 min)"
        case .medium: return "Medium (15-30 min)"
        case .long: return "Long (30-60 min)"
        case .extended: return "Extended (1+ hour)"
        }
    }

    var shortName: String {
        switch self {
        case .quick: return "5-15 min"
        case .medium: return "15-30 min"
        case .long: return "30-60 min"
        case .extended: return "1+ hour"
        }
    }
}

enum AgeGroup: String, Codable, CaseIterable {
    case toddler = "toddler"      // 2-4
    case preschool = "preschool"  // 4-6
    case earlySchool = "early"    // 6-8
    case middleChild = "middle"   // 8-10
    case preteen = "preteen"      // 10-12

    var displayName: String {
        switch self {
        case .toddler: return "Toddler (2-4)"
        case .preschool: return "Preschool (4-6)"
        case .earlySchool: return "Early School (6-8)"
        case .middleChild: return "Middle (8-10)"
        case .preteen: return "Preteen (10-12)"
        }
    }
}

struct Activity: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let category: ActivityCategory
    let duration: ActivityDuration
    let ageGroups: [AgeGroup]
    let materials: [String]
    let steps: [String]
    let tips: [String]
    let moxieIntegration: String?
    var isFavorite: Bool
    var timesCompleted: Int
    var lastCompletedAt: Date?
    var isCustom: Bool

    init(id: UUID = UUID(), title: String, description: String, category: ActivityCategory, duration: ActivityDuration, ageGroups: [AgeGroup], materials: [String] = [], steps: [String] = [], tips: [String] = [], moxieIntegration: String? = nil, isFavorite: Bool = false, timesCompleted: Int = 0, lastCompletedAt: Date? = nil, isCustom: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.duration = duration
        self.ageGroups = ageGroups
        self.materials = materials
        self.steps = steps
        self.tips = tips
        self.moxieIntegration = moxieIntegration
        self.isFavorite = isFavorite
        self.timesCompleted = timesCompleted
        self.lastCompletedAt = lastCompletedAt
        self.isCustom = isCustom
    }
}

struct ActivitySuggestionsSettings: Codable {
    var activities: [Activity] = []
    var favoriteCategories: [ActivityCategory] = []
    var childAgeGroup: AgeGroup = .preschool
    var preferredDurations: [ActivityDuration] = [.quick, .medium]
    var completedActivityIds: [UUID] = []
    var weeklyGoal: Int = 5
    var activitiesThisWeek: Int = 0
    var weekStartDate: Date = Date()
}

// MARK: - Main View

struct ActivitySuggestionsView: View {
    @State private var settings = ActivitySuggestionsSettings()
    @State private var searchText = ""
    @State private var selectedCategory: ActivityCategory?
    @State private var selectedDuration: ActivityDuration?
    @State private var showingActivityDetail: Activity?
    @State private var showingAddActivity = false
    @State private var showFavoritesOnly = false

    private let defaultActivities: [Activity] = [
        // Outdoor Activities
        Activity(title: "Nature Scavenger Hunt", description: "Explore the outdoors and find items from a checklist", category: .outdoor, duration: .medium, ageGroups: [.preschool, .earlySchool, .middleChild], materials: ["Checklist", "Bag for treasures"], steps: ["Create a list of items to find", "Head outside together", "Check off items as you find them", "Discuss what you discovered"], tips: ["Adjust difficulty for age", "Take photos instead of collecting living things"], moxieIntegration: "Ask Moxie to help create a themed scavenger hunt list"),

        Activity(title: "Puddle Jumping", description: "Put on boots and splash in puddles after rain", category: .outdoor, duration: .quick, ageGroups: [.toddler, .preschool, .earlySchool], materials: ["Rain boots", "Rain jacket"], steps: ["Wait for a rainy day", "Put on waterproof gear", "Find the best puddles", "Jump and splash together"], tips: ["Bring a change of clothes", "Make it educational by measuring puddle depths"]),

        Activity(title: "Backyard Camping", description: "Set up a tent and enjoy an outdoor adventure", category: .outdoor, duration: .extended, ageGroups: [.earlySchool, .middleChild, .preteen], materials: ["Tent", "Sleeping bags", "Flashlights", "Snacks"], steps: ["Set up tent together", "Plan activities", "Tell stories", "Stargaze before bed"], moxieIntegration: "Ask Moxie for camping stories or constellation facts"),

        Activity(title: "Bug Safari", description: "Discover insects in your backyard or park", category: .outdoor, duration: .medium, ageGroups: [.preschool, .earlySchool, .middleChild], materials: ["Magnifying glass", "Bug container", "Field guide"], steps: ["Choose a search area", "Look under leaves and rocks", "Observe insects carefully", "Release bugs after observing"], moxieIntegration: "Ask Moxie to teach about the bugs you find"),

        // Indoor Activities
        Activity(title: "Fort Building", description: "Create an epic blanket fort for imaginative play", category: .indoor, duration: .medium, ageGroups: [.toddler, .preschool, .earlySchool, .middleChild], materials: ["Blankets", "Pillows", "Chairs", "Clips or clothespins"], steps: ["Gather building materials", "Design your fort layout", "Construct walls and roof", "Decorate and add cozy touches"], tips: ["String lights add magic", "Include a reading nook"]),

        Activity(title: "Indoor Treasure Hunt", description: "Follow clues to find hidden treasure", category: .indoor, duration: .medium, ageGroups: [.preschool, .earlySchool, .middleChild], materials: ["Paper for clues", "Small treasure or treats"], steps: ["Write age-appropriate clues", "Hide clues around the house", "Place treasure at final spot", "Let the hunt begin!"], moxieIntegration: "Ask Moxie to help create rhyming clues"),

        Activity(title: "Dance Party", description: "Turn up the music and dance together", category: .indoor, duration: .quick, ageGroups: [.toddler, .preschool, .earlySchool, .middleChild, .preteen], materials: ["Music player", "Optional: disco ball or lights"], steps: ["Choose favorite songs", "Clear a dance space", "Take turns choosing moves", "Try freeze dance variations"]),

        Activity(title: "Puzzle Challenge", description: "Work together on a jigsaw puzzle", category: .indoor, duration: .long, ageGroups: [.earlySchool, .middleChild, .preteen], materials: ["Age-appropriate puzzle"], steps: ["Choose a puzzle together", "Sort pieces by color/edge", "Work on sections", "Celebrate completion"], tips: ["Start with corners and edges", "Keep puzzle on a board to move if needed"]),

        // Creative Activities
        Activity(title: "Collaborative Art", description: "Create artwork together on a large canvas", category: .creative, duration: .medium, ageGroups: [.toddler, .preschool, .earlySchool, .middleChild], materials: ["Large paper", "Paints", "Brushes", "Smocks"], steps: ["Set up art station", "Choose a theme or go abstract", "Take turns adding elements", "Display your masterpiece"]),

        Activity(title: "Homemade Playdough", description: "Make and play with custom playdough", category: .creative, duration: .medium, ageGroups: [.toddler, .preschool, .earlySchool], materials: ["Flour", "Salt", "Water", "Food coloring", "Cream of tartar"], steps: ["Mix dry ingredients", "Add water and coloring", "Knead until smooth", "Create together"], tips: ["Add glitter or scents", "Store in airtight container"]),

        Activity(title: "Story Illustration", description: "Draw pictures for a story you create together", category: .creative, duration: .medium, ageGroups: [.preschool, .earlySchool, .middleChild], materials: ["Paper", "Art supplies", "Stapler for book"], steps: ["Create a story together", "Divide into scenes", "Illustrate each scene", "Bind into a book"], moxieIntegration: "Ask Moxie to start a story for you to continue"),

        Activity(title: "Music Making", description: "Create music with household items or instruments", category: .creative, duration: .quick, ageGroups: [.toddler, .preschool, .earlySchool, .middleChild], materials: ["Pots", "Spoons", "Rice containers", "Any instruments"], steps: ["Gather sound-making items", "Experiment with sounds", "Create a rhythm together", "Perform a family concert"]),

        // Educational Activities
        Activity(title: "Kitchen Science", description: "Simple science experiments with kitchen items", category: .educational, duration: .medium, ageGroups: [.preschool, .earlySchool, .middleChild, .preteen], materials: ["Baking soda", "Vinegar", "Food coloring", "Containers"], steps: ["Choose an experiment", "Gather materials", "Make predictions", "Observe and discuss results"], moxieIntegration: "Ask Moxie to explain the science behind what happened"),

        Activity(title: "Map Making", description: "Create maps of your home or neighborhood", category: .educational, duration: .medium, ageGroups: [.earlySchool, .middleChild, .preteen], materials: ["Paper", "Pencils", "Ruler", "Colored pencils"], steps: ["Choose what to map", "Walk through the space", "Draw to scale if possible", "Add details and legend"]),

        Activity(title: "Plant Growing", description: "Start seeds and watch them grow together", category: .educational, duration: .extended, ageGroups: [.preschool, .earlySchool, .middleChild], materials: ["Seeds", "Soil", "Pots", "Water"], steps: ["Choose fast-growing seeds", "Plant together", "Create a watering schedule", "Track growth in a journal"], moxieIntegration: "Ask Moxie about plant facts and growth stages"),

        Activity(title: "Letter/Number Hunt", description: "Find letters or numbers around the house", category: .educational, duration: .quick, ageGroups: [.toddler, .preschool], materials: ["Paper and pencil for tracking"], steps: ["Choose a letter or number", "Search around the house", "Mark each find", "Practice saying and writing it"]),

        // Cooking Activities
        Activity(title: "Cookie Decorating", description: "Decorate cookies together with frosting and toppings", category: .cooking, duration: .medium, ageGroups: [.toddler, .preschool, .earlySchool, .middleChild], materials: ["Plain cookies", "Frosting", "Sprinkles", "Decorations"], steps: ["Set up decorating station", "Show techniques", "Let creativity flow", "Share and enjoy"]),

        Activity(title: "Pizza Making", description: "Make personal pizzas from scratch or premade dough", category: .cooking, duration: .medium, ageGroups: [.preschool, .earlySchool, .middleChild, .preteen], materials: ["Dough", "Sauce", "Cheese", "Toppings"], steps: ["Prepare toppings", "Shape the dough", "Add toppings", "Bake and enjoy together"]),

        Activity(title: "Smoothie Creation", description: "Blend healthy smoothies with fun ingredients", category: .cooking, duration: .quick, ageGroups: [.preschool, .earlySchool, .middleChild, .preteen], materials: ["Blender", "Fruits", "Yogurt", "Milk"], steps: ["Choose ingredients", "Measure together", "Blend until smooth", "Taste test and adjust"]),

        Activity(title: "Snack Art", description: "Create edible art with healthy snacks", category: .cooking, duration: .quick, ageGroups: [.toddler, .preschool, .earlySchool], materials: ["Fruits", "Vegetables", "Crackers", "Cheese"], steps: ["Wash and prep ingredients", "Plan your design", "Assemble art on plate", "Take a photo then eat!"]),

        // Exercise Activities
        Activity(title: "Obstacle Course", description: "Create and complete a fun obstacle course", category: .exercise, duration: .medium, ageGroups: [.toddler, .preschool, .earlySchool, .middleChild], materials: ["Pillows", "Chairs", "Tape", "Timer"], steps: ["Design the course together", "Set up obstacles", "Practice the route", "Time each other"]),

        Activity(title: "Yoga Together", description: "Practice kid-friendly yoga poses", category: .exercise, duration: .quick, ageGroups: [.preschool, .earlySchool, .middleChild, .preteen], materials: ["Yoga mats or towels", "Comfortable clothes"], steps: ["Find a calm space", "Try animal poses", "Practice breathing", "End with relaxation"], moxieIntegration: "Ask Moxie to guide a yoga session"),

        Activity(title: "Balloon Keep-Up", description: "Keep balloons in the air without touching the ground", category: .exercise, duration: .quick, ageGroups: [.toddler, .preschool, .earlySchool], materials: ["Balloons"], steps: ["Blow up balloons", "Start with one balloon", "Add more for challenge", "Try different body parts"]),

        Activity(title: "Family Walk", description: "Take a walk and explore your neighborhood", category: .exercise, duration: .medium, ageGroups: [.toddler, .preschool, .earlySchool, .middleChild, .preteen], materials: ["Comfortable shoes", "Water bottles"], steps: ["Choose a route", "Set a walking goal", "Notice interesting things", "Talk about what you see"]),

        // Mindfulness Activities
        Activity(title: "Gratitude Sharing", description: "Share things you're grateful for", category: .mindfulness, duration: .quick, ageGroups: [.preschool, .earlySchool, .middleChild, .preteen], materials: ["Optional: gratitude journal"], steps: ["Sit together comfortably", "Take turns sharing gratitude", "Listen without interrupting", "Discuss why these things matter"], moxieIntegration: "Ask Moxie about gratitude and its benefits"),

        Activity(title: "Breathing Exercises", description: "Practice calming breathing techniques", category: .mindfulness, duration: .quick, ageGroups: [.toddler, .preschool, .earlySchool, .middleChild], materials: ["None needed"], steps: ["Try balloon breathing", "Practice 4-7-8 breathing", "Use finger breathing", "Discuss how it feels"]),

        Activity(title: "Mindful Coloring", description: "Color together while practicing mindfulness", category: .mindfulness, duration: .medium, ageGroups: [.preschool, .earlySchool, .middleChild, .preteen], materials: ["Coloring pages", "Crayons or markers"], steps: ["Choose calming pages", "Color in silence", "Focus on the present", "Share your experience"]),

        Activity(title: "Feelings Check-In", description: "Discuss emotions and how to handle them", category: .mindfulness, duration: .quick, ageGroups: [.preschool, .earlySchool, .middleChild, .preteen], materials: ["Optional: feelings chart"], steps: ["Name your current feeling", "Discuss what caused it", "Share coping strategies", "Practice one together"], moxieIntegration: "Ask Moxie about emotions and coping strategies"),

        // Social Activities
        Activity(title: "Role Playing", description: "Act out social scenarios together", category: .social, duration: .medium, ageGroups: [.preschool, .earlySchool, .middleChild], materials: ["Props optional", "Costume pieces"], steps: ["Choose a scenario", "Assign roles", "Act it out", "Discuss what worked well"]),

        Activity(title: "Board Game Time", description: "Play age-appropriate board games together", category: .social, duration: .long, ageGroups: [.preschool, .earlySchool, .middleChild, .preteen], materials: ["Board games"], steps: ["Choose a game together", "Review rules", "Play fairly", "Discuss good sportsmanship"]),

        Activity(title: "Compliment Circle", description: "Practice giving and receiving compliments", category: .social, duration: .quick, ageGroups: [.preschool, .earlySchool, .middleChild], materials: ["None needed"], steps: ["Sit in a circle", "Give sincere compliments", "Accept with thanks", "Discuss how it felt"]),

        Activity(title: "Helping Project", description: "Do something kind for someone together", category: .social, duration: .medium, ageGroups: [.earlySchool, .middleChild, .preteen], materials: ["Varies by project"], steps: ["Choose who to help", "Plan your project", "Work together", "Reflect on the experience"], moxieIntegration: "Ask Moxie for ideas on helping others")
    ]

    var filteredActivities: [Activity] {
        var activities = settings.activities.isEmpty ? defaultActivities : settings.activities

        if showFavoritesOnly {
            activities = activities.filter { $0.isFavorite }
        }

        if let category = selectedCategory {
            activities = activities.filter { $0.category == category }
        }

        if let duration = selectedDuration {
            activities = activities.filter { $0.duration == duration }
        }

        // Filter by child's age group
        activities = activities.filter { $0.ageGroups.contains(settings.childAgeGroup) }

        if !searchText.isEmpty {
            activities = activities.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        return activities
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                weeklyProgressSection
                filtersSection
                activitiesListSection
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
        .sheet(item: $showingActivityDetail) { activity in
            ActivityDetailSheet(activity: activity, onComplete: { markActivityCompleted($0) }, onToggleFavorite: { toggleFavorite($0) })
        }
        .sheet(isPresented: $showingAddActivity) {
            AddActivitySheet(onSave: { newActivity in
                var activity = newActivity
                activity = Activity(id: activity.id, title: activity.title, description: activity.description, category: activity.category, duration: activity.duration, ageGroups: activity.ageGroups, materials: activity.materials, steps: activity.steps, tips: activity.tips, moxieIntegration: activity.moxieIntegration, isFavorite: activity.isFavorite, timesCompleted: activity.timesCompleted, lastCompletedAt: activity.lastCompletedAt, isCustom: true)
                if settings.activities.isEmpty {
                    settings.activities = defaultActivities
                }
                settings.activities.append(activity)
                saveSettings()
            })
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Activity Suggestions")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Fun things to do together")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                Button(action: { showingAddActivity = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Activity")
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

    private var weeklyProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Progress")
                .font(.headline)
                .foregroundColor(.primary)

            HStack(spacing: 20) {
                // Progress circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: min(Double(settings.activitiesThisWeek) / Double(max(settings.weeklyGoal, 1)), 1.0))
                        .stroke(Color(hex: "#4CAF50"), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(settings.activitiesThisWeek)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("of \(settings.weeklyGoal)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Activities completed this week")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("Weekly Goal:")
                            .font(.subheadline)

                        Stepper("\(settings.weeklyGoal) activities", value: $settings.weeklyGoal, in: 1...14)
                            .onChange(of: settings.weeklyGoal) { _ in saveSettings() }
                    }

                    // Age group selector
                    HStack {
                        Text("Child's Age:")
                            .font(.subheadline)

                        Picker("Age Group", selection: $settings.childAgeGroup) {
                            ForEach(AgeGroup.allCases, id: \.self) { group in
                                Text(group.displayName).tag(group)
                            }
                        }
                        .onChange(of: settings.childAgeGroup) { _ in saveSettings() }
                    }
                }

                Spacer()
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    private var filtersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search activities...", text: $searchText)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(10)

            HStack(spacing: 12) {
                // Category filter
                Menu {
                    Button("All Categories") {
                        selectedCategory = nil
                    }
                    Divider()
                    ForEach(ActivityCategory.allCases, id: \.self) { category in
                        Button(action: { selectedCategory = category }) {
                            Label(category.displayName, systemImage: category.icon)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: selectedCategory?.icon ?? "square.grid.2x2")
                        Text(selectedCategory?.displayName ?? "Category")
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(8)
                }

                // Duration filter
                Menu {
                    Button("Any Duration") {
                        selectedDuration = nil
                    }
                    Divider()
                    ForEach(ActivityDuration.allCases, id: \.self) { duration in
                        Button(duration.displayName) {
                            selectedDuration = duration
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "clock")
                        Text(selectedDuration?.shortName ?? "Duration")
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(8)
                }

                // Favorites toggle
                Button(action: { showFavoritesOnly.toggle() }) {
                    HStack {
                        Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                        Text("Favorites")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(showFavoritesOnly ? Color(hex: "#E91E63") : Color.white)
                    .foregroundColor(showFavoritesOnly ? .white : .primary)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("\(filteredActivities.count) activities")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }

    private var activitiesListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Category sections
            ForEach(ActivityCategory.allCases, id: \.self) { category in
                let categoryActivities = filteredActivities.filter { $0.category == category }

                if !categoryActivities.isEmpty && (selectedCategory == nil || selectedCategory == category) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(Color(hex: category.color))
                            Text(category.displayName)
                                .font(.headline)

                            Spacer()

                            Text("\(categoryActivities.count)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: category.color).opacity(0.2))
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 280))], spacing: 12) {
                            ForEach(categoryActivities) { activity in
                                ActivityCard(activity: activity, onTap: { showingActivityDetail = activity }, onToggleFavorite: { toggleFavorite(activity) })
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                }
            }

            if filteredActivities.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No activities found")
                        .font(.headline)
                    Text("Try adjusting your filters or search terms")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(Color.white)
                .cornerRadius(16)
            }
        }
    }

    private func toggleFavorite(_ activity: Activity) {
        if settings.activities.isEmpty {
            settings.activities = defaultActivities
        }

        if let index = settings.activities.firstIndex(where: { $0.id == activity.id }) {
            settings.activities[index].isFavorite.toggle()
        } else if let index = defaultActivities.firstIndex(where: { $0.id == activity.id }) {
            var updatedActivity = defaultActivities[index]
            updatedActivity.isFavorite.toggle()
            settings.activities = defaultActivities
            settings.activities[index] = updatedActivity
        }
        saveSettings()
    }

    private func markActivityCompleted(_ activity: Activity) {
        if settings.activities.isEmpty {
            settings.activities = defaultActivities
        }

        if let index = settings.activities.firstIndex(where: { $0.id == activity.id }) {
            settings.activities[index].timesCompleted += 1
            settings.activities[index].lastCompletedAt = Date()
        }

        settings.activitiesThisWeek += 1
        settings.completedActivityIds.append(activity.id)
        saveSettings()
    }

    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "activitySuggestionsSettings"),
           let decoded = try? JSONDecoder().decode(ActivitySuggestionsSettings.self, from: data) {
            settings = decoded

            // Reset weekly count if it's a new week
            let calendar = Calendar.current
            if !calendar.isDate(settings.weekStartDate, equalTo: Date(), toGranularity: .weekOfYear) {
                settings.activitiesThisWeek = 0
                settings.weekStartDate = Date()
                saveSettings()
            }
        }
    }

    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: "activitySuggestionsSettings")
        }
    }
}

// MARK: - Activity Card

struct ActivityCard: View {
    let activity: Activity
    let onTap: () -> Void
    let onToggleFavorite: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(activity.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer()

                    Button(action: onToggleFavorite) {
                        Image(systemName: activity.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(activity.isFavorite ? Color(hex: "#E91E63") : .secondary)
                    }
                    .buttonStyle(.plain)
                }

                Text(activity.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    // Duration badge
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(activity.duration.shortName)
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                    // Moxie integration badge
                    if activity.moxieIntegration != nil {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.caption2)
                            Text("Moxie")
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#667eea").opacity(0.1))
                        .foregroundColor(Color(hex: "#667eea"))
                        .cornerRadius(8)
                    }

                    Spacer()

                    if activity.timesCompleted > 0 {
                        Text("Done \(activity.timesCompleted)x")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Activity Detail Sheet

struct ActivityDetailSheet: View {
    let activity: Activity
    let onComplete: (Activity) -> Void
    let onToggleFavorite: (Activity) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(activity.title)
                            .font(.title)
                            .fontWeight(.bold)

                        HStack(spacing: 8) {
                            Label(activity.category.displayName, systemImage: activity.category.icon)
                                .font(.subheadline)
                                .foregroundColor(Color(hex: activity.category.color))

                            Text("•")

                            Label(activity.duration.displayName, systemImage: "clock")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Button(action: { onToggleFavorite(activity) }) {
                        Image(systemName: activity.isFavorite ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundColor(activity.isFavorite ? Color(hex: "#E91E63") : .secondary)
                    }
                    .buttonStyle(.plain)
                }

                Text(activity.description)
                    .font(.body)
                    .foregroundColor(.secondary)

                // Age groups
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suitable Ages")
                        .font(.headline)

                    HStack {
                        ForEach(activity.ageGroups, id: \.self) { age in
                            Text(age.displayName)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(hex: "#4CAF50").opacity(0.1))
                                .foregroundColor(Color(hex: "#4CAF50"))
                                .cornerRadius(8)
                        }
                    }
                }

                // Materials
                if !activity.materials.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Materials Needed")
                            .font(.headline)

                        ForEach(activity.materials, id: \.self) { material in
                            HStack {
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(Color(hex: "#4CAF50"))
                                Text(material)
                            }
                        }
                    }
                }

                // Steps
                if !activity.steps.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Steps")
                            .font(.headline)

                        ForEach(Array(activity.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top) {
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .frame(width: 24, height: 24)
                                    .background(Color(hex: "#667eea"))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)

                                Text(step)
                                    .font(.body)
                            }
                        }
                    }
                }

                // Tips
                if !activity.tips.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tips")
                            .font(.headline)

                        ForEach(activity.tips, id: \.self) { tip in
                            HStack(alignment: .top) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(Color(hex: "#FF9800"))
                                Text(tip)
                            }
                        }
                    }
                }

                // Moxie integration
                if let moxieIntegration = activity.moxieIntegration {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Moxie Integration")
                                .font(.headline)
                        }
                        .foregroundColor(Color(hex: "#667eea"))

                        Text(moxieIntegration)
                            .padding()
                            .background(Color(hex: "#667eea").opacity(0.1))
                            .cornerRadius(12)
                    }
                }

                // Stats
                if activity.timesCompleted > 0 {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Times Completed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(activity.timesCompleted)")
                                .font(.title2)
                                .fontWeight(.bold)
                        }

                        Spacer()

                        if let lastCompleted = activity.lastCompletedAt {
                            VStack(alignment: .trailing) {
                                Text("Last Done")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(lastCompleted, style: .relative)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }

                // Action buttons
                HStack(spacing: 16) {
                    Button(action: { dismiss() }) {
                        Text("Close")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        onComplete(activity)
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Mark Complete")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#4CAF50"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
        }
        .frame(minWidth: 500, minHeight: 600)
    }
}

// MARK: - Add Activity Sheet

struct AddActivitySheet: View {
    let onSave: (Activity) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var category: ActivityCategory = .indoor
    @State private var duration: ActivityDuration = .medium
    @State private var selectedAgeGroups: Set<AgeGroup> = [.preschool, .earlySchool]
    @State private var materials: [String] = []
    @State private var steps: [String] = []
    @State private var newMaterial = ""
    @State private var newStep = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add Custom Activity")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Cancel") { dismiss() }
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Basic info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Activity Name")
                            .font(.headline)
                        TextField("Enter activity name", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        TextField("Brief description", text: $description)
                            .textFieldStyle(.roundedBorder)
                    }

                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.headline)
                            Picker("Category", selection: $category) {
                                ForEach(ActivityCategory.allCases, id: \.self) { cat in
                                    Label(cat.displayName, systemImage: cat.icon).tag(cat)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Duration")
                                .font(.headline)
                            Picker("Duration", selection: $duration) {
                                ForEach(ActivityDuration.allCases, id: \.self) { dur in
                                    Text(dur.displayName).tag(dur)
                                }
                            }
                        }
                    }

                    // Age groups
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Suitable Age Groups")
                            .font(.headline)

                        HStack {
                            ForEach(AgeGroup.allCases, id: \.self) { age in
                                Button(action: {
                                    if selectedAgeGroups.contains(age) {
                                        selectedAgeGroups.remove(age)
                                    } else {
                                        selectedAgeGroups.insert(age)
                                    }
                                }) {
                                    Text(age.displayName)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(selectedAgeGroups.contains(age) ? Color(hex: "#4CAF50") : Color.gray.opacity(0.1))
                                        .foregroundColor(selectedAgeGroups.contains(age) ? .white : .primary)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Materials
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Materials Needed")
                            .font(.headline)

                        HStack {
                            TextField("Add material", text: $newMaterial)
                                .textFieldStyle(.roundedBorder)
                            Button(action: {
                                if !newMaterial.isEmpty {
                                    materials.append(newMaterial)
                                    newMaterial = ""
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                            }
                            .disabled(newMaterial.isEmpty)
                        }

                        ForEach(materials, id: \.self) { material in
                            HStack {
                                Text("• \(material)")
                                Spacer()
                                Button(action: { materials.removeAll { $0 == material } }) {
                                    Image(systemName: "xmark.circle")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Steps
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Steps")
                            .font(.headline)

                        HStack {
                            TextField("Add step", text: $newStep)
                                .textFieldStyle(.roundedBorder)
                            Button(action: {
                                if !newStep.isEmpty {
                                    steps.append(newStep)
                                    newStep = ""
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                            }
                            .disabled(newStep.isEmpty)
                        }

                        ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                            HStack {
                                Text("\(index + 1). \(step)")
                                Spacer()
                                Button(action: { steps.remove(at: index) }) {
                                    Image(systemName: "xmark.circle")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
            }

            Divider()

            // Footer
            HStack {
                Spacer()
                Button("Save Activity") {
                    let activity = Activity(
                        title: title,
                        description: description,
                        category: category,
                        duration: duration,
                        ageGroups: Array(selectedAgeGroups),
                        materials: materials,
                        steps: steps,
                        isCustom: true
                    )
                    onSave(activity)
                    dismiss()
                }
                .disabled(title.isEmpty || description.isEmpty)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 500)
    }
}

#Preview {
    ActivitySuggestionsView()
        .frame(width: 900, height: 700)
}
