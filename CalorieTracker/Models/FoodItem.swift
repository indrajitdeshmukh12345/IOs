import Foundation

enum FoodDietType: String, Codable, CaseIterable, Identifiable {
    case vegan, vegetarian, egg, nonVeg

    var id: String { rawValue }

    var title: String {
        switch self {
        case .vegan: return "Vegan"
        case .vegetarian: return "Vegetarian"
        case .egg: return "Contains egg"
        case .nonVeg: return "Non-veg"
        }
    }
}

enum FoodCategory: String, Codable, CaseIterable, Identifiable {
    case eggsDairy, meatFish, grains, legumes, indianMeals, nutsSeeds, fruits, vegetables, snacks, drinks, supplements, fats, custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .eggsDairy: return "Eggs & Dairy"
        case .meatFish: return "Meat & Fish"
        case .grains: return "Grains & Carbs"
        case .legumes: return "Legumes & Soy"
        case .indianMeals: return "Indian Meals"
        case .nutsSeeds: return "Nuts & Seeds"
        case .fruits: return "Fruits"
        case .vegetables: return "Vegetables"
        case .snacks: return "Snacks & Fast Food"
        case .drinks: return "Drinks & Shakes"
        case .supplements: return "Supplements"
        case .fats: return "Oils & Fats"
        case .custom: return "My Foods"
        }
    }

    var emoji: String {
        switch self {
        case .eggsDairy: return "🥚"
        case .meatFish: return "🍗"
        case .grains: return "🍚"
        case .legumes: return "🫘"
        case .indianMeals: return "🍛"
        case .nutsSeeds: return "🥜"
        case .fruits: return "🍌"
        case .vegetables: return "🥦"
        case .snacks: return "🍕"
        case .drinks: return "🥤"
        case .supplements: return "💪"
        case .fats: return "🫒"
        case .custom: return "⭐️"
        }
    }
}

/// A food with nutrition values for one serving.
struct FoodItem: Codable, Hashable, Identifiable {
    var id: String
    var name: String
    var emoji: String
    var category: FoodCategory
    var dietType: FoodDietType
    /// Human readable serving, e.g. "1 large egg" or "1 cup cooked".
    var servingName: String
    var servingGrams: Double
    /// Nutrients for ONE serving.
    var nutrients: Nutrients
    /// Upper bound of servings the coach will suggest in one go.
    var maxSuggestedServings: Int
    var isCustom: Bool

    init(
        id: String,
        name: String,
        emoji: String,
        category: FoodCategory,
        dietType: FoodDietType,
        servingName: String,
        servingGrams: Double,
        nutrients: Nutrients,
        maxSuggestedServings: Int = 2,
        isCustom: Bool = false
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.category = category
        self.dietType = dietType
        self.servingName = servingName
        self.servingGrams = servingGrams
        self.nutrients = nutrients
        self.maxSuggestedServings = maxSuggestedServings
        self.isCustom = isCustom
    }

    func nutrients(servings: Double) -> Nutrients {
        nutrients.scaled(by: servings)
    }

    /// Protein grams per 100 kcal — a "protein density" score.
    var proteinDensity: Double {
        guard nutrients.calories > 0 else { return 0 }
        return nutrients.protein / nutrients.calories * 100
    }

    /// "4 × Whole egg" / "1.5 × Rice"
    func quantityLabel(servings: Double) -> String {
        "\(ServingFormatter.string(servings)) × \(name)"
    }
}

enum ServingFormatter {
    static func string(_ servings: Double) -> String {
        servings.formatted(.number.precision(.fractionLength(0...2)))
    }
}
