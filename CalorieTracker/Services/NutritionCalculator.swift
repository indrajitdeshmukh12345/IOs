import Foundation

/// The output of the target calculation, with the intermediate numbers so the UI can explain them.
struct NutritionRecommendation: Hashable {
    var bmr: Double
    var tdee: Double
    var surplus: Double
    var targets: Nutrients
    var waterLiters: Double
    /// Expected weight change per week at this intake (kg).
    var projectedWeeklyGainKg: Double

    var proteinPerKg: Double
    var weightKg: Double

    /// Plain-language reasons for each number.
    var explanations: [String] {
        [
            "Your body burns about \(Int(bmr.rounded())) kcal/day at rest (BMR, Mifflin-St Jeor).",
            "With your activity level that's about \(Int(tdee.rounded())) kcal/day to maintain weight.",
            surplus > 0
                ? "A +\(Int(surplus)) kcal surplus gives \(Int(targets.calories)) kcal/day — roughly \(projectedWeeklyGainKg.formatted(.number.precision(.fractionLength(2)))) kg of gain per week."
                : "Eating \(Int(targets.calories)) kcal/day keeps your weight stable.",
            "Protein: \(proteinPerKg.formatted(.number.precision(.fractionLength(1)))) g per kg of body weight = \(Int(targets.protein)) g to build muscle.",
            "Fat: \(Int(targets.fat)) g (≈\(Int((targets.fat * 9 / max(targets.calories, 1) * 100).rounded()))% of calories) for hormones and joint health.",
            "Carbs fill the rest: \(Int(targets.carbs)) g to fuel training and recovery.",
            "Fiber: \(Int(targets.fiber)) g for digestion — important when eating big.",
        ]
    }
}

enum NutritionCalculator {
    /// Energy stored in 1 kg of body mass, used for gain projections.
    static let kcalPerKg: Double = 7700

    /// Mifflin-St Jeor basal metabolic rate.
    static func bmr(weightKg: Double, heightCm: Double, age: Int, sex: Sex) -> Double {
        let base = 10 * weightKg + 6.25 * heightCm - 5 * Double(age)
        return base + (sex == .male ? 5 : -161)
    }

    static func recommendation(for profile: UserProfile) -> NutritionRecommendation {
        let bmr = bmr(weightKg: profile.weightKg, heightCm: profile.heightCm, age: profile.age, sex: profile.sex)
        let tdee = bmr * profile.activityLevel.multiplier
        let surplus = profile.goal.calorieSurplus
        let calories = roundTo(tdee + surplus, step: 10)

        let protein = (profile.weightKg * profile.goal.proteinPerKg).rounded()
        // At least 25% of calories from fat, and never under 0.8 g/kg.
        let fat = max(profile.weightKg * 0.8, calories * 0.25 / 9).rounded()
        let carbs = max(0, (calories - protein * 4 - fat * 9) / 4).rounded()
        let fiber = (calories / 1000 * 14).rounded()

        let calculated = Nutrients(calories: calories, protein: protein, carbs: carbs, fat: fat, fiber: fiber)

        return NutritionRecommendation(
            bmr: bmr,
            tdee: tdee,
            surplus: surplus,
            targets: calculated,
            waterLiters: (profile.weightKg * 0.035 * 10).rounded() / 10,
            projectedWeeklyGainKg: surplus * 7 / kcalPerKg,
            proteinPerKg: profile.goal.proteinPerKg,
            weightKg: profile.weightKg
        )
    }

    /// The targets actually used by the app: custom overrides win over calculated values.
    static func targets(for profile: UserProfile) -> Nutrients {
        profile.customTargets ?? recommendation(for: profile).targets
    }

    /// Weeks until the target weight at the current surplus, if it makes sense.
    static func weeksToTarget(for profile: UserProfile) -> Double? {
        guard let target = profile.targetWeightKg, target > profile.weightKg else { return nil }
        let weekly = recommendation(for: profile).projectedWeeklyGainKg
        guard weekly > 0 else { return nil }
        return (target - profile.weightKg) / weekly
    }

    private static func roundTo(_ value: Double, step: Double) -> Double {
        (value / step).rounded() * step
    }
}
