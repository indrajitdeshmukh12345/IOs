import Foundation

/// Built-in food library. Values are approximate per serving (USDA / IFCT averages).
enum FoodDatabase {
    // swiftlint:disable function_parameter_count
    private static func food(
        _ id: String, _ name: String, _ emoji: String, _ category: FoodCategory, _ diet: FoodDietType,
        serving: String, grams: Double,
        kcal: Double, p: Double, c: Double, f: Double, fiber: Double,
        max: Int = 2
    ) -> FoodItem {
        FoodItem(
            id: id, name: name, emoji: emoji, category: category, dietType: diet,
            servingName: serving, servingGrams: grams,
            nutrients: Nutrients(calories: kcal, protein: p, carbs: c, fat: f, fiber: fiber),
            maxSuggestedServings: max
        )
    }
    // swiftlint:enable function_parameter_count

    static let all: [FoodItem] = [
        // MARK: Eggs & dairy
        food("egg", "Whole egg", "🥚", .eggsDairy, .egg, serving: "1 large egg", grams: 50, kcal: 72, p: 6.3, c: 0.4, f: 4.8, fiber: 0, max: 4),
        food("egg-white", "Egg white", "🥚", .eggsDairy, .egg, serving: "1 large egg white", grams: 33, kcal: 17, p: 3.6, c: 0.2, f: 0.1, fiber: 0, max: 6),
        food("omelette", "Omelette (2 eggs)", "🍳", .eggsDairy, .egg, serving: "1 omelette", grams: 120, kcal: 190, p: 13, c: 1.5, f: 15, fiber: 0.2, max: 1),
        food("milk-whole", "Whole milk", "🥛", .eggsDairy, .vegetarian, serving: "1 glass (250 ml)", grams: 250, kcal: 153, p: 8, c: 12, f: 8, fiber: 0, max: 2),
        food("milk-toned", "Toned milk", "🥛", .eggsDairy, .vegetarian, serving: "1 glass (250 ml)", grams: 250, kcal: 120, p: 8, c: 12, f: 4.5, fiber: 0, max: 2),
        food("greek-yogurt", "Greek yogurt (plain)", "🥣", .eggsDairy, .vegetarian, serving: "1 cup (170 g)", grams: 170, kcal: 100, p: 17, c: 6, f: 0.7, fiber: 0, max: 2),
        food("curd", "Curd / Dahi", "🥣", .eggsDairy, .vegetarian, serving: "1 bowl (150 g)", grams: 150, kcal: 92, p: 5.3, c: 7, f: 5, fiber: 0, max: 2),
        food("paneer", "Paneer", "🧀", .eggsDairy, .vegetarian, serving: "100 g", grams: 100, kcal: 265, p: 18.3, c: 1.2, f: 20.8, fiber: 0, max: 2),
        food("cottage-cheese", "Cottage cheese (low fat)", "🧀", .eggsDairy, .vegetarian, serving: "½ cup (113 g)", grams: 113, kcal: 92, p: 12, c: 5, f: 2.6, fiber: 0, max: 2),
        food("cheese-slice", "Cheese slice", "🧀", .eggsDairy, .vegetarian, serving: "1 slice (28 g)", grams: 28, kcal: 113, p: 7, c: 0.4, f: 9.3, fiber: 0, max: 2),

        // MARK: Meat & fish
        food("chicken-breast", "Chicken breast (cooked)", "🍗", .meatFish, .nonVeg, serving: "100 g", grams: 100, kcal: 165, p: 31, c: 0, f: 3.6, fiber: 0, max: 3),
        food("chicken-thigh", "Chicken thigh (cooked)", "🍗", .meatFish, .nonVeg, serving: "100 g", grams: 100, kcal: 209, p: 26, c: 0, f: 10.9, fiber: 0, max: 2),
        food("chicken-curry", "Chicken curry", "🍛", .meatFish, .nonVeg, serving: "1 bowl (240 g)", grams: 240, kcal: 290, p: 25, c: 8, f: 17, fiber: 1.5, max: 2),
        food("mutton-curry", "Mutton curry", "🍛", .meatFish, .nonVeg, serving: "1 bowl (240 g)", grams: 240, kcal: 350, p: 26, c: 8, f: 24, fiber: 1.5, max: 1),
        food("ground-beef", "Lean ground beef (cooked)", "🥩", .meatFish, .nonVeg, serving: "100 g", grams: 100, kcal: 217, p: 26, c: 0, f: 12, fiber: 0, max: 2),
        food("salmon", "Salmon (cooked)", "🐟", .meatFish, .nonVeg, serving: "100 g", grams: 100, kcal: 206, p: 22, c: 0, f: 12, fiber: 0, max: 2),
        food("tuna", "Tuna (canned in water)", "🐟", .meatFish, .nonVeg, serving: "1 can (100 g)", grams: 100, kcal: 116, p: 26, c: 0, f: 0.8, fiber: 0, max: 2),
        food("fish-curry", "Fish curry", "🐠", .meatFish, .nonVeg, serving: "1 bowl (240 g)", grams: 240, kcal: 250, p: 24, c: 6, f: 14, fiber: 1, max: 2),
        food("prawns", "Prawns (cooked)", "🦐", .meatFish, .nonVeg, serving: "100 g", grams: 100, kcal: 99, p: 24, c: 0.2, f: 0.3, fiber: 0, max: 2),

        // MARK: Grains & carbs
        food("rice-white", "White rice (cooked)", "🍚", .grains, .vegan, serving: "1 cup (158 g)", grams: 158, kcal: 205, p: 4.3, c: 44.5, f: 0.4, fiber: 0.6, max: 3),
        food("rice-brown", "Brown rice (cooked)", "🍚", .grains, .vegan, serving: "1 cup (195 g)", grams: 195, kcal: 216, p: 5, c: 45, f: 1.8, fiber: 3.5, max: 3),
        food("roti", "Roti / Chapati", "🫓", .grains, .vegan, serving: "1 medium (40 g)", grams: 40, kcal: 110, p: 3, c: 18, f: 3, fiber: 2.5, max: 4),
        food("paratha", "Plain paratha", "🫓", .grains, .vegetarian, serving: "1 piece (80 g)", grams: 80, kcal: 260, p: 5, c: 36, f: 10, fiber: 3, max: 2),
        food("oats", "Oats (dry)", "🥣", .grains, .vegan, serving: "½ cup (40 g)", grams: 40, kcal: 150, p: 5, c: 27, f: 2.5, fiber: 4, max: 2),
        food("bread-ww", "Whole wheat bread", "🍞", .grains, .vegan, serving: "1 slice (32 g)", grams: 32, kcal: 80, p: 4, c: 14, f: 1, fiber: 2, max: 4),
        food("bread-white", "White bread", "🍞", .grains, .vegan, serving: "1 slice (25 g)", grams: 25, kcal: 67, p: 2, c: 13, f: 0.8, fiber: 0.6, max: 4),
        food("pasta", "Pasta (cooked)", "🍝", .grains, .vegan, serving: "1 cup (140 g)", grams: 140, kcal: 220, p: 8, c: 43, f: 1.3, fiber: 2.5, max: 2),
        food("quinoa", "Quinoa (cooked)", "🍚", .grains, .vegan, serving: "1 cup (185 g)", grams: 185, kcal: 222, p: 8, c: 39, f: 3.6, fiber: 5, max: 2),
        food("potato", "Potato (boiled)", "🥔", .grains, .vegan, serving: "1 medium (173 g)", grams: 173, kcal: 161, p: 4.3, c: 37, f: 0.2, fiber: 3.8, max: 2),
        food("sweet-potato", "Sweet potato (baked)", "🍠", .grains, .vegan, serving: "1 medium (114 g)", grams: 114, kcal: 103, p: 2.3, c: 24, f: 0.2, fiber: 3.8, max: 2),
        food("granola", "Granola", "🥣", .grains, .vegan, serving: "½ cup (60 g)", grams: 60, kcal: 270, p: 6, c: 36, f: 11, fiber: 4, max: 1),

        // MARK: Legumes & soy
        food("lentils", "Lentils (boiled)", "🫘", .legumes, .vegan, serving: "1 cup (198 g)", grams: 198, kcal: 230, p: 18, c: 40, f: 0.8, fiber: 15.6, max: 2),
        food("chickpeas", "Chickpeas (boiled)", "🫘", .legumes, .vegan, serving: "1 cup (164 g)", grams: 164, kcal: 269, p: 14.5, c: 45, f: 4.2, fiber: 12.5, max: 2),
        food("tofu", "Tofu (firm)", "🧊", .legumes, .vegan, serving: "100 g", grams: 100, kcal: 144, p: 17, c: 3, f: 9, fiber: 2, max: 2),
        food("soya-chunks", "Soya chunks (dry)", "🟤", .legumes, .vegan, serving: "50 g", grams: 50, kcal: 173, p: 26, c: 17, f: 0.3, fiber: 6.5, max: 2),
        food("moong-sprouts", "Moong sprouts", "🌱", .legumes, .vegan, serving: "1 cup (104 g)", grams: 104, kcal: 31, p: 3, c: 6, f: 0.2, fiber: 1.9, max: 2),
        food("peanut-butter", "Peanut butter", "🥜", .legumes, .vegan, serving: "2 tbsp (32 g)", grams: 32, kcal: 190, p: 7, c: 7, f: 16, fiber: 2, max: 2),

        // MARK: Indian meals
        food("dal-tadka", "Dal tadka", "🍲", .indianMeals, .vegetarian, serving: "1 bowl (200 g)", grams: 200, kcal: 230, p: 12, c: 30, f: 7, fiber: 7, max: 2),
        food("rajma", "Rajma curry", "🍲", .indianMeals, .vegan, serving: "1 bowl (240 g)", grams: 240, kcal: 240, p: 13, c: 38, f: 5, fiber: 11, max: 2),
        food("chole", "Chole (chickpea curry)", "🍲", .indianMeals, .vegan, serving: "1 bowl (240 g)", grams: 240, kcal: 280, p: 12, c: 40, f: 9, fiber: 10, max: 2),
        food("palak-paneer", "Palak paneer", "🥬", .indianMeals, .vegetarian, serving: "1 bowl (240 g)", grams: 240, kcal: 280, p: 14, c: 10, f: 20, fiber: 3, max: 1),
        food("paneer-bhurji", "Paneer bhurji", "🧀", .indianMeals, .vegetarian, serving: "1 bowl (150 g)", grams: 150, kcal: 320, p: 20, c: 8, f: 23, fiber: 1.5, max: 1),
        food("egg-curry", "Egg curry (2 eggs)", "🍛", .indianMeals, .egg, serving: "1 bowl (220 g)", grams: 220, kcal: 260, p: 14, c: 8, f: 19, fiber: 1.5, max: 1),
        food("chicken-biryani", "Chicken biryani", "🍛", .indianMeals, .nonVeg, serving: "1 plate (300 g)", grams: 300, kcal: 500, p: 25, c: 60, f: 18, fiber: 2, max: 1),
        food("veg-biryani", "Veg biryani", "🍛", .indianMeals, .vegetarian, serving: "1 plate (300 g)", grams: 300, kcal: 430, p: 9, c: 66, f: 14, fiber: 4, max: 1),
        food("poha", "Poha", "🍚", .indianMeals, .vegan, serving: "1 plate (150 g)", grams: 150, kcal: 250, p: 5, c: 45, f: 6, fiber: 2, max: 1),
        food("upma", "Upma", "🍚", .indianMeals, .vegetarian, serving: "1 bowl (200 g)", grams: 200, kcal: 250, p: 6, c: 38, f: 8, fiber: 3, max: 1),
        food("idli", "Idli", "⚪️", .indianMeals, .vegan, serving: "1 piece (40 g)", grams: 40, kcal: 58, p: 2, c: 12, f: 0.4, fiber: 0.8, max: 4),
        food("dosa", "Plain dosa", "🫓", .indianMeals, .vegan, serving: "1 dosa (80 g)", grams: 80, kcal: 168, p: 4, c: 29, f: 3.7, fiber: 1, max: 2),
        food("sabzi", "Mixed veg sabzi", "🥘", .indianMeals, .vegan, serving: "1 bowl (150 g)", grams: 150, kcal: 120, p: 3, c: 12, f: 7, fiber: 4, max: 2),

        // MARK: Nuts & seeds
        food("almonds", "Almonds", "🌰", .nutsSeeds, .vegan, serving: "1 handful (28 g)", grams: 28, kcal: 164, p: 6, c: 6, f: 14, fiber: 3.5, max: 2),
        food("peanuts", "Peanuts (roasted)", "🥜", .nutsSeeds, .vegan, serving: "1 handful (28 g)", grams: 28, kcal: 166, p: 7, c: 6, f: 14, fiber: 2.4, max: 2),
        food("walnuts", "Walnuts", "🌰", .nutsSeeds, .vegan, serving: "1 handful (28 g)", grams: 28, kcal: 185, p: 4.3, c: 3.9, f: 18.5, fiber: 1.9, max: 1),
        food("cashews", "Cashews", "🥜", .nutsSeeds, .vegan, serving: "1 handful (28 g)", grams: 28, kcal: 157, p: 5.2, c: 8.6, f: 12.4, fiber: 0.9, max: 1),
        food("chia", "Chia seeds", "⚫️", .nutsSeeds, .vegan, serving: "1 tbsp (12 g)", grams: 12, kcal: 58, p: 2, c: 5, f: 3.7, fiber: 4.1, max: 2),
        food("flax", "Flax seeds", "🟤", .nutsSeeds, .vegan, serving: "1 tbsp (10 g)", grams: 10, kcal: 55, p: 1.9, c: 3, f: 4.3, fiber: 2.8, max: 2),

        // MARK: Fruits
        food("banana", "Banana", "🍌", .fruits, .vegan, serving: "1 medium (118 g)", grams: 118, kcal: 105, p: 1.3, c: 27, f: 0.4, fiber: 3.1, max: 3),
        food("apple", "Apple", "🍎", .fruits, .vegan, serving: "1 medium (182 g)", grams: 182, kcal: 95, p: 0.5, c: 25, f: 0.3, fiber: 4.4, max: 2),
        food("mango", "Mango", "🥭", .fruits, .vegan, serving: "1 cup (165 g)", grams: 165, kcal: 99, p: 1.4, c: 25, f: 0.6, fiber: 2.6, max: 2),
        food("orange", "Orange", "🍊", .fruits, .vegan, serving: "1 medium (131 g)", grams: 131, kcal: 62, p: 1.2, c: 15.4, f: 0.2, fiber: 3.1, max: 2),
        food("dates", "Dates", "🌴", .fruits, .vegan, serving: "2 pieces (48 g)", grams: 48, kcal: 133, p: 0.9, c: 36, f: 0.1, fiber: 3.2, max: 2),
        food("avocado", "Avocado", "🥑", .fruits, .vegan, serving: "½ fruit (100 g)", grams: 100, kcal: 160, p: 2, c: 8.5, f: 14.7, fiber: 6.7, max: 1),
        food("raisins", "Raisins", "🍇", .fruits, .vegan, serving: "¼ cup (40 g)", grams: 40, kcal: 120, p: 1.2, c: 32, f: 0.2, fiber: 1.5, max: 1),

        // MARK: Vegetables
        food("broccoli", "Broccoli", "🥦", .vegetables, .vegan, serving: "1 cup (91 g)", grams: 91, kcal: 31, p: 2.5, c: 6, f: 0.3, fiber: 2.4, max: 2),
        food("spinach", "Spinach (cooked)", "🥬", .vegetables, .vegan, serving: "1 cup (180 g)", grams: 180, kcal: 41, p: 5.3, c: 6.8, f: 0.5, fiber: 4.3, max: 2),
        food("salad", "Green salad", "🥗", .vegetables, .vegan, serving: "1 bowl (100 g)", grams: 100, kcal: 20, p: 1.2, c: 3.5, f: 0.2, fiber: 1.8, max: 2),
        food("carrot", "Carrot", "🥕", .vegetables, .vegan, serving: "1 medium (61 g)", grams: 61, kcal: 25, p: 0.6, c: 6, f: 0.1, fiber: 1.7, max: 2),

        // MARK: Snacks & fast food
        food("samosa", "Samosa", "🥟", .snacks, .vegan, serving: "1 piece (100 g)", grams: 100, kcal: 260, p: 4, c: 30, f: 14, fiber: 2.5, max: 1),
        food("pizza", "Pizza slice", "🍕", .snacks, .vegetarian, serving: "1 slice (107 g)", grams: 107, kcal: 285, p: 12, c: 36, f: 10, fiber: 2.5, max: 2),
        food("burger", "Cheeseburger", "🍔", .snacks, .nonVeg, serving: "1 burger (113 g)", grams: 113, kcal: 303, p: 15, c: 33, f: 12, fiber: 1.5, max: 1),
        food("fries", "French fries", "🍟", .snacks, .vegan, serving: "1 medium (117 g)", grams: 117, kcal: 365, p: 4, c: 48, f: 17, fiber: 4.4, max: 1),
        food("dark-chocolate", "Dark chocolate", "🍫", .snacks, .vegan, serving: "28 g", grams: 28, kcal: 170, p: 2.2, c: 13, f: 12, fiber: 3.1, max: 1),

        // MARK: Drinks & shakes
        food("mass-shake", "Mass gainer shake (homemade)", "🥤", .drinks, .vegetarian, serving: "1 glass (milk, banana, oats, PB)", grams: 450, kcal: 600, p: 25, c: 70, f: 24, fiber: 7, max: 1),
        food("banana-shake", "Banana milkshake", "🍌", .drinks, .vegetarian, serving: "1 glass (300 ml)", grams: 300, kcal: 280, p: 9, c: 45, f: 8, fiber: 3, max: 2),
        food("lassi", "Sweet lassi", "🥛", .drinks, .vegetarian, serving: "1 glass (250 ml)", grams: 250, kcal: 230, p: 8, c: 33, f: 7, fiber: 0, max: 1),
        food("chai", "Masala chai", "☕️", .drinks, .vegetarian, serving: "1 cup (150 ml)", grams: 150, kcal: 90, p: 2.5, c: 13, f: 3, fiber: 0, max: 1),
        food("orange-juice", "Orange juice", "🧃", .drinks, .vegan, serving: "1 glass (250 ml)", grams: 250, kcal: 112, p: 1.7, c: 26, f: 0.5, fiber: 0.5, max: 1),
        food("coconut-water", "Coconut water", "🥥", .drinks, .vegan, serving: "1 glass (240 ml)", grams: 240, kcal: 46, p: 1.7, c: 9, f: 0.5, fiber: 2.6, max: 1),

        // MARK: Supplements
        food("whey", "Whey protein", "💪", .supplements, .vegetarian, serving: "1 scoop (30 g)", grams: 30, kcal: 120, p: 24, c: 3, f: 1.5, fiber: 0, max: 2),
        food("plant-protein", "Plant protein", "🌿", .supplements, .vegan, serving: "1 scoop (33 g)", grams: 33, kcal: 130, p: 22, c: 5, f: 2.5, fiber: 2, max: 2),
        food("protein-bar", "Protein bar", "🍫", .supplements, .vegetarian, serving: "1 bar (60 g)", grams: 60, kcal: 210, p: 20, c: 22, f: 7, fiber: 5, max: 1),

        // MARK: Oils & fats
        food("ghee", "Ghee", "🧈", .fats, .vegetarian, serving: "1 tbsp (13 g)", grams: 13, kcal: 117, p: 0, c: 0, f: 13, fiber: 0, max: 1),
        food("butter", "Butter", "🧈", .fats, .vegetarian, serving: "1 tbsp (14 g)", grams: 14, kcal: 102, p: 0.1, c: 0, f: 11.5, fiber: 0, max: 1),
        food("olive-oil", "Olive oil", "🫒", .fats, .vegan, serving: "1 tbsp (14 g)", grams: 14, kcal: 119, p: 0, c: 0, f: 13.5, fiber: 0, max: 1),
    ]

    static func food(id: String) -> FoodItem? {
        all.first { $0.id == id }
    }

    static func search(_ query: String, in foods: [FoodItem]) -> [FoodItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return foods }
        let terms = trimmed.lowercased().split(separator: " ").map(String.init)
        return foods
            .filter { food in
                let haystack = "\(food.name) \(food.category.title) \(food.id)".lowercased()
                return terms.allSatisfy { haystack.contains($0) }
            }
            .sorted { lhs, rhs in
                // Names that start with the query come first.
                let l = lhs.name.lowercased().hasPrefix(trimmed.lowercased())
                let r = rhs.name.lowercased().hasPrefix(trimmed.lowercased())
                if l != r { return l }
                return lhs.name < rhs.name
            }
    }
}
