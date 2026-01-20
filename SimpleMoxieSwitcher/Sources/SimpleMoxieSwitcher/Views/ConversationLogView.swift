import SwiftUI
import UniformTypeIdentifiers

// MARK: - Conversation Log View (Parent Dashboard)
struct ConversationLogView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var modeContext = ModeContext.shared
    @State private var conversations: [ConversationLog] = []
    @State private var filteredConversations: [ConversationLog] = []
    @State private var searchText = ""
    @State private var selectedDateRange = DateRange.today
    @State private var selectedSentiment: Sentiment? = nil
    @State private var showOnlyFlagged = false
    @State private var selectedConversation: ConversationLog? = nil
    @State private var isExporting = false
    @State private var exportFormat = ExportFormat.pdf
    @State private var showExportSuccess = false

    enum DateRange: String, CaseIterable {
        case today = "Today"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case all = "All Time"

        var dateInterval: DateInterval {
            let calendar = Calendar.current
            let now = Date()
            switch self {
            case .today:
                let start = calendar.startOfDay(for: now)
                return DateInterval(start: start, end: now)
            case .thisWeek:
                let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
                return DateInterval(start: start, end: now)
            case .thisMonth:
                let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
                return DateInterval(start: start, end: now)
            case .all:
                return DateInterval(start: Date.distantPast, end: now)
            }
        }
    }

    enum ExportFormat: String, CaseIterable {
        case pdf = "PDF"
        case csv = "CSV"
        case json = "JSON"
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(hex: "#9D4EDD").opacity(0.05),
                    Color(hex: "#7B2CBF").opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView
                    .padding()
                    .background(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)

                // Filters
                filterBar
                    .padding()
                    .background(Color.gray.opacity(0.05))

                // Content
                if filteredConversations.isEmpty {
                    emptyStateView
                } else {
                    conversationList
                }
            }
        }
        .frame(minWidth: 900, minHeight: 700)
        .sheet(item: $selectedConversation) { conversation in
            ConversationDetailView(conversation: conversation)
        }
        .onAppear {
            loadConversations()
            applyFilters()
        }
        .onChange(of: searchText) { _ in applyFilters() }
        .onChange(of: selectedDateRange) { _ in applyFilters() }
        .onChange(of: selectedSentiment) { _ in applyFilters() }
        .onChange(of: showOnlyFlagged) { _ in applyFilters() }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Conversation Logs")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(hex: "#9D4EDD"))

                Text("Monitor and review all child conversations")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Export button
            Menu {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    Button(action: { exportConversations(format: format) }) {
                        Label(
                            "Export as \(format.rawValue)",
                            systemImage: format == .pdf ? "doc.fill" :
                                       format == .csv ? "tablecells.fill" : "curlybraces"
                        )
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(hex: "#9D4EDD"))
                .cornerRadius(8)
            }
            .menuStyle(.borderlessButton)
            .disabled(isExporting)

            // Close button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: 16) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search conversations...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color.white)
            .cornerRadius(8)
            .frame(maxWidth: 300)

            // Date range
            Picker("Date", selection: $selectedDateRange) {
                ForEach(DateRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 300)

            // Sentiment filter
            Menu {
                Button("All Sentiments") {
                    selectedSentiment = nil
                }
                Divider()
                ForEach([Sentiment.veryPositive, .positive, .neutral, .negative, .concerning], id: \.self) { sentiment in
                    Button(action: { selectedSentiment = sentiment }) {
                        Label(sentiment.displayName, systemImage: "")
                            .badge(Text(sentiment.emoji))
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(selectedSentiment?.emoji ?? "😊")
                    Text(selectedSentiment?.displayName ?? "All Sentiments")
                        .font(.system(size: 14))
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white)
                .cornerRadius(8)
            }
            .menuStyle(.borderlessButton)

            // Flagged filter
            Toggle(isOn: $showOnlyFlagged) {
                HStack(spacing: 4) {
                    Image(systemName: "flag.fill")
                        .foregroundColor(.orange)
                    Text("Flagged Only")
                }
            }
            .toggleStyle(.button)

            Spacer()

            // Stats
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(filteredConversations.count) conversations")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if showOnlyFlagged {
                    Text("\(flaggedCount) flagged")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
    }

    // MARK: - Conversation List

    private var conversationList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredConversations) { conversation in
                    ConversationRowView(
                        conversation: conversation,
                        onTap: {
                            selectedConversation = conversation
                        }
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 80))
                .foregroundColor(.secondary.opacity(0.3))

            Text("No conversations found")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("Adjust your filters or check back later")
                .font(.body)
                .foregroundColor(.secondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helper Methods

    private func loadConversations() {
        // Load from repository - get all conversations
        Task {
            let repository = ConversationRepository()
            do {
                let allConversations = try await repository.loadConversations()

                // Convert to ConversationLog with safety features
                await MainActor.run {
                    conversations = allConversations.map { conversation in
                        ConversationLog(
                            mode: .child,
                            personality: conversation.personality,
                            messages: conversation.messages,
                            summary: generateSummary(for: conversation),
                            sentiment: analyzeSentiment(for: conversation),
                            flags: detectFlags(in: conversation)
                        )
                    }
                }
            } catch {
                print("Failed to load conversations: \(error)")
            }
        }
    }

    private func applyFilters() {
        filteredConversations = conversations.filter { conversation in
            // Date filter
            let dateInterval = selectedDateRange.dateInterval
            guard conversation.createdAt >= dateInterval.start &&
                  conversation.createdAt <= dateInterval.end else {
                return false
            }

            // Search filter
            if !searchText.isEmpty {
                let searchLower = searchText.lowercased()
                let matchesSearch = conversation.messages.contains { message in
                    message.content.lowercased().contains(searchLower)
                } || conversation.personality.lowercased().contains(searchLower)
                guard matchesSearch else { return false }
            }

            // Sentiment filter
            if let sentiment = selectedSentiment {
                guard conversation.sentiment == sentiment else { return false }
            }

            // Flagged filter
            if showOnlyFlagged {
                guard conversation.hasFlaggedContent else { return false }
            }

            return true
        }
    }

    private var flaggedCount: Int {
        conversations.filter { $0.hasFlaggedContent }.count
    }

    private func generateSummary(for conversation: Conversation) -> String {
        // Simple summary generation
        let topics = conversation.messages.compactMap { message -> String? in
            if message.role == "user" {
                return String(message.content.prefix(50))
            }
            return nil
        }
        return topics.joined(separator: ", ")
    }

    private func analyzeSentiment(for conversation: Conversation) -> Sentiment {
        // Simple sentiment analysis based on keywords
        let content = conversation.messages.map { $0.content }.joined(separator: " ").lowercased()

        if content.contains("sad") || content.contains("upset") || content.contains("angry") {
            return .negative
        } else if content.contains("happy") || content.contains("fun") || content.contains("great") {
            return .positive
        } else {
            return .neutral
        }
    }

    private func detectFlags(in conversation: Conversation) -> [ContentFlag] {
        // Simple flag detection
        var flags: [ContentFlag] = []

        for message in conversation.messages {
            let content = message.content.lowercased()

            // Check for concerning keywords
            if content.contains("bully") || content.contains("mean") {
                flags.append(ContentFlag(
                    severity: .medium,
                    category: .bullyingMention,
                    messageContent: message.content,
                    aiExplanation: "Detected mention of bullying"
                ))
            }

            if content.contains("sad") && content.contains("always") {
                flags.append(ContentFlag(
                    severity: .medium,
                    category: .sadnessRepeated,
                    messageContent: message.content,
                    aiExplanation: "Detected repeated sadness"
                ))
            }
        }

        return flags
    }

    private func exportConversations(format: ExportFormat) {
        isExporting = true

        // Simulated export
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isExporting = false
            showExportSuccess = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showExportSuccess = false
            }
        }
    }
}

// MARK: - Conversation Row View
struct ConversationRowView: View {
    let conversation: ConversationLog
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Sentiment indicator
                Text(conversation.sentiment?.emoji ?? "😐")
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(conversation.personality)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if conversation.hasFlaggedContent {
                            HStack(spacing: 4) {
                                Image(systemName: "flag.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Text("\(conversation.unreviewedFlags.count)")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                        }

                        Spacer()

                        Text(conversation.createdAt, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let summary = conversation.summary {
                        Text(summary)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    HStack {
                        Label("\(conversation.messageCount) messages", systemImage: "bubble.left.and.bubble.right")
                        Label(conversation.formattedDuration, systemImage: "clock")

                        if !conversation.flags.isEmpty {
                            ForEach(Array(Set(conversation.flags.map { $0.severity })), id: \.self) { severity in
                                Text(severity.emoji)
                                    .font(.caption)
                            }
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Conversation Detail View
struct ConversationDetailView: View {
    let conversation: ConversationLog
    @Environment(\.dismiss) var dismiss
    @State private var selectedFlag: ContentFlag? = nil

    var body: some View {
        ZStack {
            Color.gray.opacity(0.05)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(conversation.personality)
                            .font(.title2.bold())

                        HStack(spacing: 12) {
                            Label(conversation.createdAt.formatted(), systemImage: "calendar")
                            Label(conversation.formattedDuration, systemImage: "clock")
                            if let sentiment = conversation.sentiment {
                                HStack(spacing: 4) {
                                    Text(sentiment.emoji)
                                    Text(sentiment.displayName)
                                }
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)

                // Flags section
                if !conversation.flags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(conversation.flags) { flag in
                                FlagCardView(flag: flag) {
                                    selectedFlag = flag
                                }
                            }
                        }
                        .padding()
                    }
                    .background(Color.orange.opacity(0.05))
                }

                // Messages
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(conversation.messages) { message in
                            MessageBubbleView(message: message)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .sheet(item: $selectedFlag) { flag in
            FlagDetailView(flag: flag)
        }
    }
}

// MARK: - Message Bubble View
struct MessageBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == "assistant" {
                Image(systemName: "brain.head.profile")
                    .font(.title3)
                    .foregroundColor(.purple)
                    .frame(width: 32, height: 32)
                    .background(Color.purple.opacity(0.1))
                    .clipShape(Circle())
            } else {
                Spacer()
            }

            Text(message.content)
                .padding(12)
                .background(
                    message.role == "user" ?
                        Color.blue.opacity(0.1) :
                        Color.purple.opacity(0.1)
                )
                .cornerRadius(12)
                .foregroundColor(.primary)
                .frame(maxWidth: 500, alignment: message.role == "user" ? .trailing : .leading)

            if message.role == "user" {
                Image(systemName: "person.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
            } else {
                Spacer()
            }
        }
    }
}

// MARK: - Flag Card View
struct FlagCardView: View {
    let flag: ContentFlag
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(flag.severity.emoji)
                    Text(flag.category.displayName)
                        .font(.caption.bold())
                    Spacer()
                    if !flag.reviewed {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                    }
                }

                Text(flag.messageContent)
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(width: 250)
            .background(Color.white)
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flag Detail View
struct FlagDetailView: View {
    let flag: ContentFlag
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text(flag.severity.emoji)
                    .font(.largeTitle)
                VStack(alignment: .leading) {
                    Text(flag.category.displayName)
                        .font(.title2.bold())
                    Text("Severity: \(flag.severity.displayName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // Content
            VStack(alignment: .leading, spacing: 16) {
                Text("Flagged Message")
                    .font(.headline)
                Text(flag.messageContent)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)

                Text("AI Explanation")
                    .font(.headline)
                Text(flag.aiExplanation)
                    .foregroundColor(.secondary)

                Text("Recommended Action")
                    .font(.headline)
                Text(flag.category.recommendedAction)
                    .foregroundColor(.blue)
            }

            Spacer()

            // Actions
            HStack(spacing: 12) {
                Button(action: { dismiss() }) {
                    Text("Mark as Reviewed")
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Button(action: { dismiss() }) {
                    Text("Dismiss")
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .frame(width: 500, height: 500)
    }
}

// MARK: - Preview
struct ConversationLogView_Previews: PreviewProvider {
    static var previews: some View {
        ConversationLogView()
    }
}