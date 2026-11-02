import Foundation
import SwiftUI

/// The single source of truth for the app. Views read from it and call its methods to change data.
@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var data: AppData {
        didSet { persistence.save(data) }
    }

    private let persistence: Persistence
    private let calendar: Calendar

    init(persistence: Persistence = Persistence(), calendar: Calendar = .current) {
        self.persistence = persistence
        self.calendar = calendar
        self.data = persistence.load()
    }

    // MARK: Profile

    var profile: UserProfile? { data.profile }
    var hasProfile: Bool { data.profile != nil }

    var targets: Nutrients {
        guard let profile = data.profile else { return .zero }
        return NutritionCalculator.targets(for: profile)
    }

    var recommendation: NutritionRecommendation? {
        data.profile.map(NutritionCalculator.recommendation(for:))
    }

    func saveProfile(_ profile: UserProfile) {
        let previousWeight = data.profile?.weightKg
        data.profile = profile
        if previousWeight != profile.weightKg {
            logWeight(profile.weightKg, updateProfile: false)
        }
    }

    func resetAllData() {
        data = AppData()
    }

    // MARK: Foods

    var allFoods: [FoodItem] { data.customFoods + FoodDatabase.all }

    func addCustomFood(_ food: FoodItem) {
        data.customFoods.removeAll { $0.id == food.id }
        data.customFoods.insert(food, at: 0)
    }

    func deleteCustomFood(_ food: FoodItem) {
        data.customFoods.removeAll { $0.id == food.id }
        data.favoriteFoodIDs.removeAll { $0 == food.id }
    }

    func isFavorite(_ food: FoodItem) -> Bool {
        data.favoriteFoodIDs.contains(food.id)
    }

    func toggleFavorite(_ food: FoodItem) {
        if let index = data.favoriteFoodIDs.firstIndex(of: food.id) {
            data.favoriteFoodIDs.remove(at: index)
        } else {
            data.favoriteFoodIDs.append(food.id)
        }
    }

    var favoriteFoods: [FoodItem] {
        let foods = allFoods
        return data.favoriteFoodIDs.compactMap { id in foods.first { $0.id == id } }
    }

    /// Most recently logged distinct foods.
    func recentFoods(limit: Int = 8) -> [FoodItem] {
        var seen = Set<String>()
        var result: [FoodItem] = []
        for entry in data.entries.sorted(by: { $0.date > $1.date }) where !seen.contains(entry.food.id) {
            seen.insert(entry.food.id)
            result.append(entry.food)
            if result.count == limit { break }
        }
        return result
    }

    // MARK: Entries

    func entries(on day: Date) -> [MealEntry] {
        data.entries
            .filter { calendar.isDate($0.date, inSameDayAs: day) }
            .sorted { $0.date < $1.date }
    }

    func entries(on day: Date, meal: MealType) -> [MealEntry] {
        entries(on: day).filter { $0.mealType == meal }
    }

    func totals(on day: Date) -> Nutrients {
        entries(on: day).map(\.nutrients).total
    }

    @discardableResult
    func log(_ food: FoodItem, servings: Double, meal: MealType, on day: Date = .now) -> MealEntry {
        let entry = MealEntry(date: timestamp(for: day), mealType: meal, food: food, servings: servings)
        data.entries.append(entry)
        return entry
    }

    func update(_ entry: MealEntry) {
        guard let index = data.entries.firstIndex(where: { $0.id == entry.id }) else { return }
        data.entries[index] = entry
    }

    func delete(_ entry: MealEntry) {
        data.entries.removeAll { $0.id == entry.id }
    }

    /// Copies all entries from one day to another (e.g. "repeat yesterday").
    func copyEntries(from source: Date, to destination: Date) {
        let copies = entries(on: source).map {
            MealEntry(date: timestamp(for: destination), mealType: $0.mealType, food: $0.food, servings: $0.servings)
        }
        data.entries.append(contentsOf: copies)
    }

    func analysis(on day: Date) -> DailyAnalysis? {
        guard let profile = data.profile else { return nil }
        return NutritionCoach.analyze(
            entries: entries(on: day),
            targets: targets,
            profile: profile,
            foods: allFoods
        )
    }

    /// Daily totals for the last `days` days, oldest first.
    func history(days: Int, endingOn end: Date = .now) -> [DayTotals] {
        let endDay = calendar.startOfDay(for: end)
        return (0..<days).reversed().compactMap { (offset: Int) -> DayTotals? in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: endDay) else { return nil }
            return DayTotals(day: day, totals: totals(on: day), entryCount: entries(on: day).count)
        }
    }

    /// Number of consecutive days (ending today or yesterday) with at least one entry.
    var loggingStreak: Int {
        var streak = 0
        var day = calendar.startOfDay(for: .now)
        if entries(on: day).isEmpty, let yesterday = calendar.date(byAdding: .day, value: -1, to: day) {
            day = yesterday
        }
        while !entries(on: day).isEmpty {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }

    // MARK: Weight

    var weights: [WeightEntry] { data.weights.sorted { $0.date < $1.date } }

    func logWeight(_ kg: Double, on date: Date = .now, updateProfile: Bool = true) {
        data.weights.removeAll { calendar.isDate($0.date, inSameDayAs: date) }
        data.weights.append(WeightEntry(date: date, weightKg: kg))
        if updateProfile, var profile = data.profile, calendar.isDateInToday(date) {
            profile.weightKg = kg
            data.profile = profile
        }
    }

    func deleteWeight(_ entry: WeightEntry) {
        data.weights.removeAll { $0.id == entry.id }
    }

    // MARK: Helpers

    /// Keeps the current time of day when logging to another date.
    private func timestamp(for day: Date) -> Date {
        if calendar.isDateInToday(day) { return .now }
        let time = calendar.dateComponents([.hour, .minute, .second], from: .now)
        return calendar.date(
            bySettingHour: time.hour ?? 12, minute: time.minute ?? 0, second: time.second ?? 0, of: day
        ) ?? day
    }
}

struct DayTotals: Identifiable, Hashable {
    let day: Date
    let totals: Nutrients
    let entryCount: Int
    var id: Date { day }
}

extension AppStore {
    /// A store pre-filled with a profile and sample entries, for SwiftUI previews.
    static var preview: AppStore {
        let store = AppStore(persistence: .temporary)
        store.saveProfile(UserProfile(name: "Alex", age: 24, sex: .male, heightCm: 178, weightKg: 64, targetWeightKg: 72))
        if let egg = FoodDatabase.food(id: "egg") {
            store.log(egg, servings: 4, meal: .breakfast)
        }
        return store
    }
}
