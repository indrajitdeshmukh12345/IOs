import Foundation

enum NutrientStatus: String {
    case low, onTrack, high

    var label: String {
        switch self {
        case .low: return "Low"
        case .onTrack: return "On track"
        case .high: return "Over"
        }
    }
}

struct NutrientProgress: Identifiable, Hashable {
    let nutrient: Nutrient
    let consumed: Double
    let target: Double

    var id: Nutrient { nutrient }
    var fraction: Double { target > 0 ? consumed / target : 0 }
    var percent: Int { Int((fraction * 100).rounded()) }
    var remaining: Double { max(0, target - consumed) }
    var excess: Double { max(0, consumed - target) }

    var status: NutrientStatus {
        if fraction < 0.9 { return .low }
        // Extra protein and fiber are not a problem for a bulk.
        let upper: Double
        switch nutrient {
        case .protein: upper = 1.5
        case .fiber: upper = 2.0
        default: upper = 1.15
        }
        return fraction > upper ? .high : .onTrack
    }
}

struct FoodSuggestion: Identifiable, Hashable {
    let food: FoodItem
    let servings: Double
    let reason: String

    var id: String { food.id }
    var added: Nutrients { food.nutrients(servings: servings) }
    var label: String { food.quantityLabel(servings: servings) }
}

struct CoachMessage: Identifiable, Hashable {
    enum Kind: String {
        case summary, success, warning, tip, plan
    }

    let id = UUID()
    let kind: Kind
    let title: String
    let text: String
}

struct DailyAnalysis {
    let totals: Nutrients
    let targets: Nutrients
    let progress: [NutrientProgress]
    let headline: String
    let messages: [CoachMessage]
    let suggestions: [FoodSuggestion]
    /// Score from 0–100 for how close the day is to target.
    let score: Int
    let entryCount: Int

    var isEmpty: Bool { entryCount == 0 }

    var projectedTotals: Nutrients {
        totals + suggestions.map(\.added).total
    }

    func progress(for nutrient: Nutrient) -> NutrientProgress {
        progress.first { $0.nutrient == nutrient }
            ?? NutrientProgress(nutrient: nutrient, consumed: 0, target: 0)
    }
}

/// Turns what the user ate into plain-language feedback and concrete food suggestions.
enum NutritionCoach {
    private static let weights: [Nutrient: Double] = [
        .calories: 1.0, .protein: 1.6, .carbs: 0.8, .fat: 0.6, .fiber: 0.4,
    ]

    static func analyze(
        entries: [MealEntry],
        targets: Nutrients,
        profile: UserProfile,
        foods: [FoodItem] = FoodDatabase.all,
        maxSuggestions: Int = 5
    ) -> DailyAnalysis {
        let totals = entries.map(\.nutrients).total
        let progress = Nutrient.allCases.map {
            NutrientProgress(nutrient: $0, consumed: totals.value(for: $0), target: targets.value(for: $0))
        }

        let eatenIDs = Set(entries.map(\.food.id))
        let suggestions = suggestFoods(
            remaining: targets.remaining(after: totals),
            targets: targets,
            diet: profile.diet,
            foods: foods,
            excluding: eatenIDs,
            limit: maxSuggestions
        )

        let score = dayScore(progress)
        let messages = buildMessages(
            entries: entries,
            totals: totals,
            progress: progress,
            suggestions: suggestions,
            profile: profile
        )

        return DailyAnalysis(
            totals: totals,
            targets: targets,
            progress: progress,
            headline: headline(entries: entries, progress: progress, profile: profile),
            messages: messages,
            suggestions: suggestions,
            score: entries.isEmpty ? 0 : score,
            entryCount: entries.count
        )
    }

    // MARK: - Suggestions

    /// Greedy gap-filling: repeatedly picks the food + serving count that closes the
    /// biggest weighted gaps without overshooting, preferring variety across categories.
    static func suggestFoods(
        remaining initialRemaining: Nutrients,
        targets: Nutrients,
        diet: DietPreference,
        foods: [FoodItem],
        excluding: Set<String> = [],
        limit: Int = 5
    ) -> [FoodSuggestion] {
        var remaining = initialRemaining
        var picked: [FoodSuggestion] = []
        var usedCategories: [FoodCategory: Int] = [:]

        let candidates = foods.filter { food in
            diet.allows(food.dietType)
                && food.category != .snacks
                && food.category != .fats
                && food.nutrients.calories > 0
        }

        for _ in 0..<limit {
            let caloriesDone = remaining.calories <= targets.calories * 0.05
            let proteinDone = remaining.protein <= targets.protein * 0.05
            if caloriesDone && proteinDone { break }

            var best: (food: FoodItem, servings: Double, score: Double)?
            for food in candidates where !picked.contains(where: { $0.food.id == food.id }) {
                // Foods already eaten today are allowed but slightly de-prioritised for variety.
                var varietyFactor = excluding.contains(food.id) ? 0.75 : 1.0
                if let uses = usedCategories[food.category] {
                    varietyFactor *= pow(0.55, Double(uses))
                }
                for servings in 1...max(1, food.maxSuggestedServings) {
                    let added = food.nutrients(servings: Double(servings))
                    let score = gapScore(added: added, remaining: remaining, targets: targets) * varietyFactor
                    if score > (best?.score ?? 0.02) {
                        best = (food, Double(servings), score)
                    }
                }
            }

            guard let choice = best else { break }
            let added = choice.food.nutrients(servings: choice.servings)
            picked.append(FoodSuggestion(
                food: choice.food,
                servings: choice.servings,
                reason: reason(for: choice.food, added: added, remaining: remaining)
            ))
            usedCategories[choice.food.category, default: 0] += 1
            remaining = remaining.remaining(after: added)
        }
        return picked
    }

    static func gapScore(added: Nutrients, remaining: Nutrients, targets: Nutrients) -> Double {
        var score = 0.0
        for nutrient in Nutrient.allCases {
            let target = max(targets.value(for: nutrient), 1)
            let gap = remaining.value(for: nutrient)
            let amount = added.value(for: nutrient)
            let weight = weights[nutrient] ?? 1
            let gapRatio = min(1, gap / target)
            let filled = min(amount, gap) / target
            let over = max(0, amount - gap) / target
            score += weight * filled * (0.5 + gapRatio)
            score -= weight * over * 1.2
        }
        return score
    }

    private static func reason(for food: FoodItem, added: Nutrients, remaining: Nutrients) -> String {
        let protein = Int(added.protein.rounded())
        let kcal = Int(added.calories.rounded())
        var descriptor: String
        if food.proteinDensity >= 9 {
            descriptor = "lean, high-protein"
        } else if added.carbs * 4 >= added.calories * 0.6 {
            descriptor = "clean carbs for training energy"
        } else if added.fat * 9 >= added.calories * 0.5 {
            descriptor = "calorie-dense healthy fats"
        } else if added.calories >= 400 {
            descriptor = "big calorie boost"
        } else {
            descriptor = "balanced macros"
        }
        if added.fiber >= 4 && remaining.fiber > 0 {
            descriptor += ", rich in fiber"
        }
        return "+\(protein) g protein · +\(kcal) kcal — \(descriptor)"
    }

    // MARK: - Messages

    private static func headline(entries: [MealEntry], progress: [NutrientProgress], profile: UserProfile) -> String {
        guard !entries.isEmpty else {
            return "Log what you ate and I'll tell you what's missing."
        }
        let low = progress.filter { $0.status == .low && $0.nutrient != .fiber }.map(\.nutrient)
        let high = progress.filter { $0.status == .high }.map(\.nutrient)

        if low.isEmpty && high.isEmpty {
            return "Great job, \(profile.displayName)! You hit your targets today. 💪"
        }
        if low.contains(.calories) && low.contains(.protein) {
            return "You're short on calories and protein for \(profile.goal.title.lowercased())."
        }
        if let first = low.first {
            return "You still need more \(first.title.lowercased()) today."
        }
        if let first = high.first {
            return "You're over on \(first.title.lowercased()) — balance it out tomorrow."
        }
        return "Here's how your day looks."
    }

    private static func buildMessages(
        entries: [MealEntry],
        totals: Nutrients,
        progress: [NutrientProgress],
        suggestions: [FoodSuggestion],
        profile: UserProfile
    ) -> [CoachMessage] {
        guard !entries.isEmpty else {
            return [CoachMessage(
                kind: .tip,
                title: "Ready when you are",
                text: "Add foods from the Log tab — even \"4 eggs\" for the whole day — and I'll break down your protein, carbs, fat and calories against your \(profile.goal.title.lowercased()) targets."
            )]
        }

        var messages: [CoachMessage] = []
        let p = Dictionary(uniqueKeysWithValues: progress.map { ($0.nutrient, $0) })

        // 1. What you ate.
        let grouped = groupedByFood(entries)
        let eatenList: String
        if grouped.count <= 4 {
            eatenList = grouped.map { $0.food.quantityLabel(servings: $0.servings) }.formattedList
        } else {
            eatenList = "\(grouped.count) different foods"
        }
        messages.append(CoachMessage(
            kind: .summary,
            title: "What you ate",
            text: "You had \(eatenList). That's \(fmt(totals.calories)) kcal, \(fmt(totals.protein)) g protein, \(fmt(totals.carbs)) g carbs, \(fmt(totals.fat)) g fat and \(fmt(totals.fiber)) g fiber."
        ))

        // 2. Protein.
        if let protein = p[.protein] {
            let source = topSource(for: .protein, in: grouped, total: totals.protein)
            switch protein.status {
            case .low:
                messages.append(CoachMessage(
                    kind: .warning,
                    title: "Protein: \(fmt(protein.consumed)) g of \(fmt(protein.target)) g (\(protein.percent)%)",
                    text: "You need \(fmt(protein.remaining)) g more protein to support muscle growth.\(source)"
                ))
            case .onTrack, .high:
                messages.append(CoachMessage(
                    kind: .success,
                    title: "Protein: \(fmt(protein.consumed)) g of \(fmt(protein.target)) g",
                    text: "Protein target reached — your muscles have the building blocks they need.\(source)"
                ))
            }
        }

        // 3. Calories.
        if let cal = p[.calories] {
            switch cal.status {
            case .low:
                let gainNote = profile.goal == .maintain
                    ? "Under-eating will make you lose weight."
                    : "Without a calorie surplus your body can't build new mass."
                messages.append(CoachMessage(
                    kind: .warning,
                    title: "Calories: \(fmt(cal.consumed)) of \(fmt(cal.target)) kcal (\(cal.percent)%)",
                    text: "You're \(fmt(cal.remaining)) kcal short. \(gainNote)"
                ))
            case .onTrack:
                messages.append(CoachMessage(
                    kind: .success,
                    title: "Calories: \(fmt(cal.consumed)) of \(fmt(cal.target)) kcal",
                    text: "Your energy intake is right where it should be."
                ))
            case .high:
                messages.append(CoachMessage(
                    kind: .warning,
                    title: "Calories: \(fmt(cal.excess)) kcal over",
                    text: "A small overshoot is fine on a bulk, but staying >15% over adds extra fat rather than muscle."
                ))
            }
        }

        // 4. Carbs.
        if let carbs = p[.carbs], carbs.status == .low {
            messages.append(CoachMessage(
                kind: .warning,
                title: "Carbs: \(fmt(carbs.consumed)) g of \(fmt(carbs.target)) g (\(carbs.percent)%)",
                text: "Carbs fuel your workouts and make it much easier to hit your calories. Add \(fmt(carbs.remaining)) g — rice, roti, oats, potatoes or bananas work well."
            ))
        }

        // 5. Fat.
        if let fat = p[.fat] {
            if fat.status == .high {
                messages.append(CoachMessage(
                    kind: .warning,
                    title: "Fat: \(fmt(fat.consumed)) g (\(fat.percent)% of target)",
                    text: "That's more fat than you need. Use less oil/ghee and lean on proteins like chicken breast, egg whites, Greek yogurt or soya chunks."
                ))
            } else if fat.status == .low && totals.calories > 0 {
                messages.append(CoachMessage(
                    kind: .tip,
                    title: "Fat: \(fmt(fat.consumed)) g of \(fmt(fat.target)) g",
                    text: "Add \(fmt(fat.remaining)) g of healthy fats — nuts, peanut butter or whole eggs are an easy calorie boost."
                ))
            }
        }

        // 6. Fiber.
        if let fiber = p[.fiber], fiber.fraction < 0.6 {
            messages.append(CoachMessage(
                kind: .tip,
                title: "Fiber: \(fmt(fiber.consumed)) g of \(fmt(fiber.target)) g",
                text: "Low fiber makes big meals harder to digest. Add vegetables, fruit, dal or oats."
            ))
        }

        // 7. Variety.
        if grouped.count <= 2 {
            let names = grouped.map(\.food.name).formattedList
            messages.append(CoachMessage(
                kind: .tip,
                title: "Mix it up",
                text: "Your day relies on just \(names). Combine a protein, a carb source and veggies at each meal for the vitamins and minerals one food can't give you."
            ))
        }

        // 8. Meal timing.
        let mealCount = Set(entries.map(\.mealType)).count
        if mealCount == 1 && totals.protein > 0 && profile.goal != .maintain {
            messages.append(CoachMessage(
                kind: .tip,
                title: "Spread your meals",
                text: "Splitting food across 4–5 meals (20–40 g protein each) makes a calorie surplus easier and improves muscle protein synthesis."
            ))
        }

        // 9. The plan.
        if !suggestions.isEmpty {
            let projected = totals + suggestions.map(\.added).total
            let list = suggestions.map(\.label).formattedList
            messages.append(CoachMessage(
                kind: .plan,
                title: "You should add",
                text: "\(list). That brings you to about \(fmt(projected.calories)) kcal and \(fmt(projected.protein)) g protein."
            ))
        }

        return messages
    }

    private struct GroupedFood {
        let food: FoodItem
        let servings: Double
        var nutrients: Nutrients { food.nutrients(servings: servings) }
    }

    private static func groupedByFood(_ entries: [MealEntry]) -> [GroupedFood] {
        var order: [String] = []
        var map: [String: GroupedFood] = [:]
        for entry in entries {
            if let existing = map[entry.food.id] {
                map[entry.food.id] = GroupedFood(food: existing.food, servings: existing.servings + entry.servings)
            } else {
                order.append(entry.food.id)
                map[entry.food.id] = GroupedFood(food: entry.food, servings: entry.servings)
            }
        }
        return order.compactMap { map[$0] }
    }

    private static func topSource(for nutrient: Nutrient, in foods: [GroupedFood], total: Double) -> String {
        guard total > 0,
              let top = foods.max(by: { $0.nutrients.value(for: nutrient) < $1.nutrients.value(for: nutrient) })
        else { return "" }
        let share = Int((top.nutrients.value(for: nutrient) / total * 100).rounded())
        return " \(top.food.name) supplied \(share)% of it."
    }

    private static func dayScore(_ progress: [NutrientProgress]) -> Int {
        var total = 0.0
        var weightSum = 0.0
        for item in progress {
            let weight = weights[item.nutrient] ?? 1
            let closeness: Double
            if item.status == .onTrack {
                closeness = 1
            } else if item.fraction < 1 {
                closeness = item.fraction
            } else {
                closeness = max(0, 1 - (item.fraction - 1))
            }
            total += closeness * weight
            weightSum += weight
        }
        guard weightSum > 0 else { return 0 }
        return Int((total / weightSum * 100).rounded())
    }

    private static func fmt(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0)))
    }
}

extension Array where Element == String {
    /// ["a", "b", "c"] -> "a, b and c"
    var formattedList: String {
        switch count {
        case 0: return ""
        case 1: return self[0]
        default: return dropLast().joined(separator: ", ") + " and " + last!
        }
    }
}
