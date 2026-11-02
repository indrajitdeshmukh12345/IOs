import Foundation

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast, lunch, snack, dinner

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    var symbol: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .snack: return "takeoutbag.and.cup.and.straw.fill"
        case .dinner: return "moon.stars.fill"
        }
    }

    /// Best guess for the meal based on the time of day.
    static func suggested(for date: Date = .now, calendar: Calendar = .current) -> MealType {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 4..<11: return .breakfast
        case 11..<16: return .lunch
        case 16..<19: return .snack
        default: return .dinner
        }
    }
}

/// One logged food. Stores a snapshot of the food so history stays correct if the food changes.
struct MealEntry: Codable, Hashable, Identifiable {
    var id: UUID
    var date: Date
    var mealType: MealType
    var food: FoodItem
    var servings: Double

    init(id: UUID = UUID(), date: Date = .now, mealType: MealType, food: FoodItem, servings: Double) {
        self.id = id
        self.date = date
        self.mealType = mealType
        self.food = food
        self.servings = servings
    }

    var nutrients: Nutrients { food.nutrients(servings: servings) }
    var grams: Double { food.servingGrams * servings }
    var label: String { food.quantityLabel(servings: servings) }
}

struct WeightEntry: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var date: Date
    var weightKg: Double
}
