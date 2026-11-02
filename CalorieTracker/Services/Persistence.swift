import Foundation

/// Everything the app saves, in one Codable document.
struct AppData: Codable {
    var profile: UserProfile?
    var entries: [MealEntry] = []
    var customFoods: [FoodItem] = []
    var favoriteFoodIDs: [String] = []
    var weights: [WeightEntry] = []
}

/// Saves `AppData` as JSON in the app's Documents folder.
struct Persistence {
    let fileURL: URL

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
            self.fileURL = directory.appendingPathComponent("calorie-tracker.json")
        }
    }

    /// An in-memory-only store used for previews and tests.
    static var temporary: Persistence {
        Persistence(fileURL: FileManager.default.temporaryDirectory
            .appendingPathComponent("calorie-tracker-\(UUID().uuidString).json"))
    }

    func load() -> AppData {
        guard let data = try? Data(contentsOf: fileURL) else { return AppData() }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode(AppData.self, from: data)) ?? AppData()
    }

    func save(_ appData: AppData) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            let data = try encoder.encode(appData)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("⚠️ Failed to save data: \(error)")
        }
    }

    func delete() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
