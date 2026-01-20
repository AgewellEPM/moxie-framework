import SwiftUI
import AVFoundation

struct MusicView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = MusicViewModel()
    @State private var searchText = ""
    @State private var showSearch = true
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        ZStack {
            // Beautiful music-themed gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.0, blue: 0.2),
                    Color(red: 0.2, green: 0.05, blue: 0.3),
                    Color(red: 0.15, green: 0.0, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("🎤 Moxie Karaoke")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    // Search toggle
                    Button(action: { showSearch.toggle() }) {
                        Image(systemName: showSearch ? "music.note.list" : "magnifyingglass")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 12)

                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
                .background(.ultraThinMaterial)

                // Search Bar
                if showSearch {
                    SearchBar(searchText: $searchText, isSearchFocused: $isSearchFocused) {
                        Task {
                            await viewModel.searchSong(query: searchText)
                        }
                    }
                }

                // Main Content
                if let song = viewModel.currentSong {
                    // Song playing view
                    KaraokeView(viewModel: viewModel, song: song)
                } else if viewModel.isSearching {
                    // Loading state
                    VStack(spacing: 20) {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.pink)
                        Text("Searching for lyrics...")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                    }
                } else if !viewModel.recentSongs.isEmpty {
                    // Recent songs list
                    RecentSongsView(viewModel: viewModel)
                } else {
                    // Welcome screen
                    WelcomeMusicView()
                }

                // Error message
                if let error = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Button("Dismiss") {
                            viewModel.errorMessage = nil
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color.red.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal)
                }

                // Control bar at bottom
                if viewModel.currentSong != nil {
                    ControlBar(viewModel: viewModel)
                }
            }
        }
        .frame(minWidth: 900, minHeight: 700)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var searchText: String
    var isSearchFocused: FocusState<Bool>.Binding
    let onSearch: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.6))

            TextField("Search by song name, artist, or title...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.body)
                .foregroundColor(.white)
                .focused(isSearchFocused)
                .onSubmit {
                    onSearch()
                }

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }

            Button(action: onSearch) {
                Text("Search")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.pink.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(searchText.isEmpty)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

// MARK: - Welcome Music View
struct WelcomeMusicView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Text("🎤")
                .font(.system(size: 80))

            Text("Moxie Karaoke")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)

            Text("Search for any song and Moxie will sing it for you!")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            VStack(alignment: .leading, spacing: 12) {
                MusicFeatureRow(icon: "music.note", text: "Search by song name, artist, or lyrics")
                MusicFeatureRow(icon: "text.bubble", text: "Lyrics displayed karaoke-style")
                MusicFeatureRow(icon: "mic.fill", text: "Moxie sings line by line")
                MusicFeatureRow(icon: "star.fill", text: "Save your favorite songs")
            }
            .padding()

            Spacer()
        }
    }
}

// MARK: - Music Feature Row
struct MusicFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.pink.opacity(0.8))
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

// MARK: - Karaoke View
struct KaraokeView: View {
    @ObservedObject var viewModel: MusicViewModel
    let song: Song

    var body: some View {
        VStack(spacing: 0) {
            // Song info header
            VStack(spacing: 8) {
                Text(song.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Text(song.artist)
                    .font(.headline)
                    .foregroundColor(.pink.opacity(0.9))
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)

            // Lyrics display
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(Array(song.lyrics.enumerated()), id: \.offset) { index, line in
                            LyricLine(
                                text: line,
                                isCurrent: index == viewModel.currentLineIndex,
                                isPast: index < viewModel.currentLineIndex,
                                lineNumber: index
                            )
                            .id(index)
                        }
                    }
                    .padding(.vertical, 40)
                    .padding(.horizontal, 30)
                }
                .onChange(of: viewModel.currentLineIndex) { newIndex in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
        }
    }
}

// MARK: - Lyric Line
struct LyricLine: View {
    let text: String
    let isCurrent: Bool
    let isPast: Bool
    let lineNumber: Int

    var body: some View {
        HStack(spacing: 12) {
            // Line number
            Text("\(lineNumber + 1)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(isCurrent ? .pink : .white.opacity(0.3))
                .frame(width: 30)

            // Lyric text
            Text(text.isEmpty ? "♪" : text)
                .font(.system(size: isCurrent ? 28 : 20, weight: isCurrent ? .bold : .regular))
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, isCurrent ? 12 : 8)
                .padding(.horizontal, 16)
                .background(
                    backgroundColor
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                )
                .overlay(borderOverlay)
                .scaleEffect(isCurrent ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCurrent)
        }
    }

    private var textColor: Color {
        if isCurrent {
            return .white
        } else if isPast {
            return .white.opacity(0.5)
        } else {
            return .white.opacity(0.7)
        }
    }

    @ViewBuilder
    private var backgroundColor: some View {
        if isCurrent {
            LinearGradient(
                colors: [Color.pink.opacity(0.4), Color.purple.opacity(0.4)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            Color.clear
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        if isCurrent {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.pink.opacity(0.6), lineWidth: 2)
        }
    }
}

// MARK: - Recent Songs View
struct RecentSongsView: View {
    @ObservedObject var viewModel: MusicViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Songs")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal)
                .padding(.top)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(viewModel.recentSongs) { song in
                        SongCard(song: song) {
                            viewModel.playSong(song)
                        }
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Song Card
struct SongCard: View {
    let song: Song
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Music icon
                ZStack {
                    Circle()
                        .fill(Color.pink.opacity(0.3))
                        .frame(width: 50, height: 50)
                    Image(systemName: "music.note")
                        .font(.system(size: 24))
                        .foregroundColor(.pink)
                }

                // Song info
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(song.artist)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    Text("\(song.lyrics.count) lines")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.pink)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Control Bar
struct ControlBar: View {
    @ObservedObject var viewModel: MusicViewModel

    var body: some View {
        HStack(spacing: 20) {
            // Previous line
            Button(action: {
                viewModel.previousLine()
            }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.currentLineIndex <= 0)
            .opacity(viewModel.currentLineIndex <= 0 ? 0.3 : 1.0)

            // Play/Pause
            Button(action: {
                viewModel.togglePlayPause()
            }) {
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.pink)
            }
            .buttonStyle(.plain)

            // Next line
            Button(action: {
                viewModel.nextLine()
            }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.currentLineIndex >= (viewModel.currentSong?.lyrics.count ?? 0) - 1)
            .opacity(viewModel.currentLineIndex >= (viewModel.currentSong?.lyrics.count ?? 0) - 1 ? 0.3 : 1.0)

            Spacer()

            // Progress indicator
            if let song = viewModel.currentSong {
                Text("\(viewModel.currentLineIndex + 1) / \(song.lyrics.count)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
            }

            // Speed control
            Menu {
                Button("0.5x") { viewModel.playbackSpeed = 0.5 }
                Button("0.75x") { viewModel.playbackSpeed = 0.75 }
                Button("1x (Normal)") { viewModel.playbackSpeed = 1.0 }
                Button("1.25x") { viewModel.playbackSpeed = 1.25 }
                Button("1.5x") { viewModel.playbackSpeed = 1.5 }
            } label: {
                HStack {
                    Image(systemName: "gauge.medium")
                    Text("\(String(format: "%.2f", viewModel.playbackSpeed))x")
                }
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
            }

            // Save/Unsave
            Button(action: {
                viewModel.toggleSaveSong()
            }) {
                Image(systemName: viewModel.isCurrentSongSaved ? "heart.fill" : "heart")
                    .font(.system(size: 20))
                    .foregroundColor(viewModel.isCurrentSongSaved ? .pink : .white)
            }
            .buttonStyle(.plain)

            // Back to search
            Button(action: {
                viewModel.stopSong()
            }) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("New Search")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.purple.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.black.opacity(0.5))
    }
}

// MARK: - Models
struct Song: Identifiable, Codable {
    let id = UUID()
    let title: String
    let artist: String
    let lyrics: [String]
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case title, artist, lyrics, timestamp
    }
}

// MARK: - Music ViewModel
@MainActor
class MusicViewModel: ObservableObject {
    @Published var currentSong: Song?
    @Published var recentSongs: [Song] = []
    @Published var currentLineIndex = 0
    @Published var isPlaying = false
    @Published var isSearching = false
    @Published var errorMessage: String?
    @Published var playbackSpeed: Double = 1.0
    @Published var isCurrentSongSaved = false

    private let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    private let songsDir = AppPaths.music
    private var playbackTimer: Timer?
    private let baseLineDelay: TimeInterval = 3.0 // Base delay between lines in seconds

    init() {
        loadRecentSongs()
    }

    func searchSong(query: String) async {
        guard !query.isEmpty else { return }

        isSearching = true
        errorMessage = nil

        do {
            let prompt = """
            Find the lyrics for the song matching this search query: "\(query)"

            The query might be:
            - Just the song title
            - Artist name and song title
            - Part of the lyrics
            - Any combination

            Return the complete song lyrics, split into individual lines.

            Format your response as JSON:
            {
                "title": "Exact song title",
                "artist": "Artist name",
                "lyrics": ["Line 1", "Line 2", "Line 3", ...]
            }

            Important:
            - Each line should be a separate string in the lyrics array
            - Include blank lines as empty strings for musical pauses
            - Keep the original line breaks from the song
            - If it's a song with verses and chorus, include them all
            """

            let response = try await callOpenAI(prompt: prompt)

            if let data = response.data(using: .utf8),
               let songData = try? JSONDecoder().decode(SongData.self, from: data) {

                let song = Song(
                    title: songData.title,
                    artist: songData.artist,
                    lyrics: songData.lyrics,
                    timestamp: Date()
                )

                currentSong = song
                currentLineIndex = 0
                isPlaying = false
                checkIfSongIsSaved()

                // Add to recent songs if not already there
                if !recentSongs.contains(where: { $0.title == song.title && $0.artist == song.artist }) {
                    recentSongs.insert(song, at: 0)
                    if recentSongs.count > 20 {
                        recentSongs = Array(recentSongs.prefix(20))
                    }
                    saveRecentSongs()
                }
            }
        } catch {
            errorMessage = "Failed to find song: \(error.localizedDescription)"
        }

        isSearching = false
    }

    func playSong(_ song: Song) {
        currentSong = song
        currentLineIndex = 0
        isPlaying = false
        checkIfSongIsSaved()
    }

    func togglePlayPause() {
        isPlaying.toggle()

        if isPlaying {
            startPlayback()
        } else {
            stopPlayback()
        }
    }

    private func startPlayback() {
        playbackTimer?.invalidate()

        let adjustedDelay = baseLineDelay / playbackSpeed

        playbackTimer = Timer.scheduledTimer(withTimeInterval: adjustedDelay, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.nextLine()
            }
        }
    }

    private func stopPlayback() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    func nextLine() {
        guard let song = currentSong else { return }

        if currentLineIndex < song.lyrics.count - 1 {
            currentLineIndex += 1
        } else {
            // Song finished
            isPlaying = false
            stopPlayback()
        }
    }

    func previousLine() {
        if currentLineIndex > 0 {
            currentLineIndex -= 1
        }
    }

    func stopSong() {
        stopPlayback()
        currentSong = nil
        currentLineIndex = 0
        isPlaying = false
    }

    func toggleSaveSong() {
        guard let song = currentSong else { return }

        // Create directory if needed
        try? FileManager.default.createDirectory(at: songsDir, withIntermediateDirectories: true)

        let filename = "\(song.title)_\(song.artist).json".replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "/", with: "-")
        let fileURL = songsDir.appendingPathComponent(filename)

        if isCurrentSongSaved {
            // Unsave - delete file
            try? FileManager.default.removeItem(at: fileURL)
            isCurrentSongSaved = false
        } else {
            // Save
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(song)
                try data.write(to: fileURL)
                isCurrentSongSaved = true
            } catch {
                errorMessage = "Failed to save song: \(error.localizedDescription)"
            }
        }
    }

    private func checkIfSongIsSaved() {
        guard let song = currentSong else {
            isCurrentSongSaved = false
            return
        }

        let filename = "\(song.title)_\(song.artist).json".replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "/", with: "-")
        let fileURL = songsDir.appendingPathComponent(filename)
        isCurrentSongSaved = FileManager.default.fileExists(atPath: fileURL.path)
    }

    private func loadRecentSongs() {
        // Load from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "recentSongs"),
           let songs = try? JSONDecoder().decode([Song].self, from: data) {
            recentSongs = songs
        }
    }

    private func saveRecentSongs() {
        if let data = try? JSONEncoder().encode(recentSongs) {
            UserDefaults.standard.set(data, forKey: "recentSongs")
        }
    }

    private func callOpenAI(prompt: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw NSError(domain: "Music", code: 1, userInfo: [NSLocalizedDescriptionKey: "OpenAI API key not set in environment"])
        }

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": "You are a music expert with knowledge of song lyrics. Always respond in valid JSON format."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.3,
            "max_tokens": 2000,
            "response_format": ["type": "json_object"]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "Music", code: 2, userInfo: [NSLocalizedDescriptionKey: "API request failed"])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw NSError(domain: "Music", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }

        return content
    }

    deinit {
        playbackTimer?.invalidate()
    }
}

// MARK: - Response Model
struct SongData: Codable {
    let title: String
    let artist: String
    let lyrics: [String]
}
