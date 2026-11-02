import Foundation

enum Sex: String, Codable, CaseIterable, Identifiable {
    case male, female
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    case sedentary, light, moderate, active, veryActive

    var id: String { rawValue }

    /// Multiplier applied to BMR to estimate total daily energy expenditure.
    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .active: return 1.725
        case .veryActive: return 1.9
        }
    }

    var title: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .light: return "Lightly active"
        case .moderate: return "Moderately active"
        case .active: return "Very active"
        case .veryActive: return "Athlete"
        }
    }

    var detail: String {
        switch self {
        case .sedentary: return "Desk job, little or no exercise"
        case .light: return "Light exercise 1–3 days/week"
        case .moderate: return "Training 3–5 days/week"
        case .active: return "Hard training 6–7 days/week"
        case .veryActive: return "Twice-a-day training or physical job"
        }
    }
}

enum FitnessGoal: String, Codable, CaseIterable, Identifiable {
    case maintain, leanBulk, bulk, aggressiveBulk

    var id: String { rawValue }

    /// Daily calorie surplus over maintenance.
    var calorieSurplus: Double {
        switch self {
        case .maintain: return 0
        case .leanBulk: return 250
        case .bulk: return 450
        case .aggressiveBulk: return 700
        }
    }

    /// Grams of protein per kg of body weight.
    var proteinPerKg: Double {
        switch self {
        case .maintain: return 1.6
        case .leanBulk: return 1.8
        case .bulk: return 2.0
        case .aggressiveBulk: return 2.2
        }
    }

    var title: String {
        switch self {
        case .maintain: return "Maintain"
        case .leanBulk: return "Lean bulk"
        case .bulk: return "Mass gain"
        case .aggressiveBulk: return "Aggressive mass gain"
        }
    }

    var detail: String {
        switch self {
        case .maintain: return "Keep your current weight"
        case .leanBulk: return "+250 kcal/day · slow gain, minimal fat"
        case .bulk: return "+450 kcal/day · steady muscle gain"
        case .aggressiveBulk: return "+700 kcal/day · fastest gain, for hard gainers"
        }
    }
}

/// What the user is willing to eat. Used to filter food suggestions.
enum DietPreference: String, Codable, CaseIterable, Identifiable {
    case nonVegetarian, eggetarian, vegetarian, vegan

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nonVegetarian: return "Non-vegetarian"
        case .eggetarian: return "Eggetarian"
        case .vegetarian: return "Vegetarian"
        case .vegan: return "Vegan"
        }
    }

    func allows(_ type: FoodDietType) -> Bool {
        switch self {
        case .nonVegetarian: return true
        case .eggetarian: return type != .nonVeg
        case .vegetarian: return type == .vegetarian || type == .vegan
        case .vegan: return type == .vegan
        }
    }
}

enum UnitSystem: String, Codable, CaseIterable, Identifiable {
    case metric, imperial
    var id: String { rawValue }
    var title: String { self == .metric ? "Metric (kg, cm)" : "Imperial (lb, ft)" }
}

struct UserProfile: Codable, Hashable {
    var name: String
    var age: Int
    var sex: Sex
    var heightCm: Double
    var weightKg: Double
    var targetWeightKg: Double?
    var activityLevel: ActivityLevel
    var goal: FitnessGoal
    var diet: DietPreference
    var unitSystem: UnitSystem
    /// When set, these override the calculated targets.
    var customTargets: Nutrients?
    var createdAt: Date

    init(
        name: String = "",
        age: Int = 25,
        sex: Sex = .male,
        heightCm: Double = 175,
        weightKg: Double = 65,
        targetWeightKg: Double? = nil,
        activityLevel: ActivityLevel = .moderate,
        goal: FitnessGoal = .bulk,
        diet: DietPreference = .nonVegetarian,
        unitSystem: UnitSystem = .metric,
        customTargets: Nutrients? = nil,
        createdAt: Date = .now
    ) {
        self.name = name
        self.age = age
        self.sex = sex
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.targetWeightKg = targetWeightKg
        self.activityLevel = activityLevel
        self.goal = goal
        self.diet = diet
        self.unitSystem = unitSystem
        self.customTargets = customTargets
        self.createdAt = createdAt
    }

    var bmi: Double {
        let meters = heightCm / 100
        guard meters > 0 else { return 0 }
        return weightKg / (meters * meters)
    }

    var displayName: String {
        name.trimmingCharacters(in: .whitespaces).isEmpty ? "there" : name
    }
}

enum UnitConversion {
    static let lbPerKg = 2.2046226218
    static let cmPerInch = 2.54

    static func kgToLb(_ kg: Double) -> Double { kg * lbPerKg }
    static func lbToKg(_ lb: Double) -> Double { lb / lbPerKg }

    static func cmToFeetInches(_ cm: Double) -> (feet: Int, inches: Int) {
        let totalInches = Int((cm / cmPerInch).rounded())
        return (totalInches / 12, totalInches % 12)
    }

    static func feetInchesToCm(feet: Int, inches: Int) -> Double {
        Double(feet * 12 + inches) * cmPerInch
    }

    static func formatWeight(_ kg: Double, system: UnitSystem) -> String {
        switch system {
        case .metric: return "\(kg.formatted(.number.precision(.fractionLength(0...1)))) kg"
        case .imperial: return "\(kgToLb(kg).formatted(.number.precision(.fractionLength(0)))) lb"
        }
    }

    static func formatHeight(_ cm: Double, system: UnitSystem) -> String {
        switch system {
        case .metric: return "\(Int(cm.rounded())) cm"
        case .imperial:
            let value = cmToFeetInches(cm)
            return "\(value.feet)′ \(value.inches)″"
        }
    }
}
