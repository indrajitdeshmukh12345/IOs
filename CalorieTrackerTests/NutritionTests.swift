import XCTest
@testable import CalorieTracker

final class NutritionCalculatorTests: XCTestCase {
    private let profile = UserProfile(
        name: "Test", age: 25, sex: .male, heightCm: 175, weightKg: 65,
        activityLevel: .moderate, goal: .bulk, diet: .nonVegetarian
    )

    func testBMRUsesMifflinStJeor() {
        // 10*65 + 6.25*175 - 5*25 + 5 = 1623.75
        XCTAssertEqual(NutritionCalculator.bmr(weightKg: 65, heightCm: 175, age: 25, sex: .male), 1623.75, accuracy: 0.01)
        // Female: same minus 166
        XCTAssertEqual(NutritionCalculator.bmr(weightKg: 65, heightCm: 175, age: 25, sex: .female), 1457.75, accuracy: 0.01)
    }

    func testMassGainTargets() {
        let rec = NutritionCalculator.recommendation(for: profile)
        // TDEE = 1623.75 * 1.55 = 2516.8 -> +450 surplus -> 2970 (rounded to 10)
        XCTAssertEqual(rec.targets.calories, 2970)
        XCTAssertEqual(rec.targets.protein, 130) // 2.0 g/kg
        XCTAssertGreaterThanOrEqual(rec.targets.fat, 65 * 0.8)
        // Macros should add up to roughly the calorie target.
        let macroCalories = rec.targets.protein * 4 + rec.targets.carbs * 4 + rec.targets.fat * 9
        XCTAssertEqual(macroCalories, rec.targets.calories, accuracy: 15)
        XCTAssertGreaterThan(rec.projectedWeeklyGainKg, 0.3)
    }

    func testCustomTargetsOverrideCalculation() {
        var custom = profile
        custom.customTargets = Nutrients(calories: 3500, protein: 180, carbs: 450, fat: 90, fiber: 40)
        XCTAssertEqual(NutritionCalculator.targets(for: custom).calories, 3500)
    }

    func testWeeksToTarget() {
        var withTarget = profile
        withTarget.targetWeightKg = 70
        let weeks = NutritionCalculator.weeksToTarget(for: withTarget)
        XCTAssertNotNil(weeks)
        XCTAssertEqual(weeks ?? 0, 5 / (450.0 * 7 / 7700), accuracy: 0.01)
    }
}

final class NutritionCoachTests: XCTestCase {
    private let profile = UserProfile(
        name: "Test", age: 25, sex: .male, heightCm: 175, weightKg: 65,
        activityLevel: .moderate, goal: .bulk, diet: .nonVegetarian
    )

    private var targets: Nutrients { NutritionCalculator.targets(for: profile) }

    private func eggs(_ count: Double) -> MealEntry {
        MealEntry(mealType: .breakfast, food: FoodDatabase.food(id: "egg")!, servings: count)
    }

    func testFourEggsReportsProteinGapAndSuggestsFoods() {
        let analysis = NutritionCoach.analyze(entries: [eggs(4)], targets: targets, profile: profile)

        XCTAssertEqual(analysis.totals.protein, 25.2, accuracy: 0.01)
        XCTAssertEqual(analysis.totals.calories, 288, accuracy: 0.01)
        XCTAssertEqual(analysis.progress(for: .protein).status, .low)
        XCTAssertEqual(analysis.progress(for: .calories).status, .low)

        let summary = analysis.messages.first { $0.kind == .summary }
        XCTAssertNotNil(summary)
        XCTAssertTrue(summary?.text.contains("4 × Whole egg") ?? false)

        XCTAssertTrue(analysis.messages.contains { $0.kind == .plan })
        XCTAssertFalse(analysis.suggestions.isEmpty)
        XCTAssertLessThanOrEqual(analysis.suggestions.count, 5)
        // Suggestions should meaningfully close the protein and calorie gaps.
        XCTAssertGreaterThan(analysis.projectedTotals.protein, analysis.totals.protein + 40)
        XCTAssertGreaterThan(analysis.projectedTotals.calories, analysis.totals.calories + 800)
        // No duplicate foods.
        XCTAssertEqual(Set(analysis.suggestions.map(\.food.id)).count, analysis.suggestions.count)
    }

    func testSuggestionsRespectDiet() {
        var vegetarian = profile
        vegetarian.diet = .vegetarian
        let analysis = NutritionCoach.analyze(entries: [], targets: targets, profile: vegetarian)
        XCTAssertFalse(analysis.suggestions.isEmpty)
        for suggestion in analysis.suggestions {
            XCTAssertTrue(
                [FoodDietType.vegetarian, .vegan].contains(suggestion.food.dietType),
                "\(suggestion.food.name) is not vegetarian"
            )
        }

        var vegan = profile
        vegan.diet = .vegan
        let veganAnalysis = NutritionCoach.analyze(entries: [], targets: targets, profile: vegan)
        XCTAssertTrue(veganAnalysis.suggestions.allSatisfy { $0.food.dietType == .vegan })
    }

    func testNoSuggestionsWhenTargetsMet() {
        let suggestions = NutritionCoach.suggestFoods(
            remaining: .zero, targets: targets, diet: .nonVegetarian, foods: FoodDatabase.all
        )
        XCTAssertTrue(suggestions.isEmpty)
    }

    func testEmptyDayHasHelpfulMessage() {
        let analysis = NutritionCoach.analyze(entries: [], targets: targets, profile: profile)
        XCTAssertTrue(analysis.isEmpty)
        XCTAssertEqual(analysis.score, 0)
        XCTAssertEqual(analysis.messages.count, 1)
    }

    func testHighFatIsFlagged() {
        let ghee = FoodDatabase.food(id: "ghee")!
        let entry = MealEntry(mealType: .lunch, food: ghee, servings: 12) // 156 g fat
        let analysis = NutritionCoach.analyze(entries: [entry], targets: targets, profile: profile)
        XCTAssertEqual(analysis.progress(for: .fat).status, .high)
        XCTAssertTrue(analysis.messages.contains { $0.title.hasPrefix("Fat") && $0.kind == .warning })
    }
}

final class FoodDatabaseTests: XCTestCase {
    func testIDsAreUnique() {
        let ids = FoodDatabase.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testCaloriesRoughlyMatchMacros() {
        for food in FoodDatabase.all {
            let n = food.nutrients
            let estimate = n.protein * 4 + n.carbs * 4 + n.fat * 9
            XCTAssertEqual(estimate, n.calories, accuracy: max(40, n.calories * 0.2), "\(food.name) macros look off")
        }
    }

    func testSearch() {
        let results = FoodDatabase.search("egg", in: FoodDatabase.all)
        XCTAssertTrue(results.first?.name.lowercased().hasPrefix("egg") ?? false)
        XCTAssertTrue(results.contains { $0.id == "egg" })
        XCTAssertTrue(FoodDatabase.search("chicken breast", in: FoodDatabase.all).contains { $0.id == "chicken-breast" })
    }
}

@MainActor
final class AppStoreTests: XCTestCase {
    func testLoggingPersistsAndTotals() {
        let persistence = Persistence.temporary
        defer { persistence.delete() }

        let store = AppStore(persistence: persistence)
        store.saveProfile(UserProfile(name: "A"))
        store.log(FoodDatabase.food(id: "egg")!, servings: 4, meal: .breakfast)
        XCTAssertEqual(store.totals(on: .now).protein, 25.2, accuracy: 0.01)

        // A new store reading the same file sees the same data.
        let reloaded = AppStore(persistence: persistence)
        XCTAssertEqual(reloaded.entries(on: .now).count, 1)
        XCTAssertEqual(reloaded.profile?.name, "A")
    }

    func testDeleteAndCopyEntries() {
        let persistence = Persistence.temporary
        defer { persistence.delete() }
        let store = AppStore(persistence: persistence)
        let entry = store.log(FoodDatabase.food(id: "banana")!, servings: 2, meal: .snack)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        store.copyEntries(from: .now, to: yesterday)
        XCTAssertEqual(store.entries(on: yesterday).count, 1)
        store.delete(entry)
        XCTAssertTrue(store.entries(on: .now).isEmpty)
    }
}
