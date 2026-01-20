import Foundation

protocol TileRepositoryProtocol {
    func loadLearningTiles() -> [LearningTile]
    func saveLearningTile(_ tile: LearningTile)
    func deleteLearningTile(_ tile: LearningTile)

    func loadStoryTiles() -> [StoryTile]
    func saveStoryTile(_ tile: StoryTile)
    func deleteStoryTile(_ tile: StoryTile)
}

class TileRepository: TileRepositoryProtocol {
    private let learningTilesKey = "saved_learning_tiles"
    private let storyTilesKey = "saved_story_tiles"

    // MARK: - Learning Tiles
    func loadLearningTiles() -> [LearningTile] {
        guard let data = UserDefaults.standard.data(forKey: learningTilesKey),
              let tiles = try? JSONDecoder().decode([LearningTile].self, from: data) else {
            return []
        }
        return tiles.sorted { $0.createdAt > $1.createdAt }
    }

    func saveLearningTile(_ tile: LearningTile) {
        var tiles = loadLearningTiles()

        // Remove existing tile with same title if it exists
        tiles.removeAll { $0.title == tile.title }

        // Add new tile
        tiles.append(tile)

        // Save to UserDefaults
        if let data = try? JSONEncoder().encode(tiles) {
            UserDefaults.standard.set(data, forKey: learningTilesKey)
        }
    }

    func deleteLearningTile(_ tile: LearningTile) {
        var tiles = loadLearningTiles()
        tiles.removeAll { $0.id == tile.id }

        if let data = try? JSONEncoder().encode(tiles) {
            UserDefaults.standard.set(data, forKey: learningTilesKey)
        }

        // Also delete the session file
        let fileURL = URL(fileURLWithPath: tile.sessionFilePath)
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Story Tiles
    func loadStoryTiles() -> [StoryTile] {
        guard let data = UserDefaults.standard.data(forKey: storyTilesKey),
              let tiles = try? JSONDecoder().decode([StoryTile].self, from: data) else {
            return []
        }
        return tiles.sorted { $0.createdAt > $1.createdAt }
    }

    func saveStoryTile(_ tile: StoryTile) {
        var tiles = loadStoryTiles()

        // Remove existing tile with same title if it exists
        tiles.removeAll { $0.title == tile.title }

        // Add new tile
        tiles.append(tile)

        // Save to UserDefaults
        if let data = try? JSONEncoder().encode(tiles) {
            UserDefaults.standard.set(data, forKey: storyTilesKey)
        }
    }

    func deleteStoryTile(_ tile: StoryTile) {
        var tiles = loadStoryTiles()
        tiles.removeAll { $0.id == tile.id }

        if let data = try? JSONEncoder().encode(tiles) {
            UserDefaults.standard.set(data, forKey: storyTilesKey)
        }

        // Also delete the session file
        let fileURL = URL(fileURLWithPath: tile.sessionFilePath)
        try? FileManager.default.removeItem(at: fileURL)
    }
}
