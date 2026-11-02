import Foundation
import SwiftUI

/// A bundle of macro-nutrient values. Used for food servings, daily totals and targets.
struct Nutrients: Codable, Hashable {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double

    init(calories: Double = 0, protein: Double = 0, carbs: Double = 0, fat: Double = 0, fiber: Double = 0) {
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
    }

    static let zero = Nutrients()

    func scaled(by factor: Double) -> Nutrients {
        Nutrients(
            calories: calories * factor,
            protein: protein * factor,
            carbs: carbs * factor,
            fat: fat * factor,
            fiber: fiber * factor
        )
    }

    func value(for nutrient: Nutrient) -> Double {
        switch nutrient {
        case .calories: return calories
        case .protein: return protein
        case .carbs: return carbs
        case .fat: return fat
        case .fiber: return fiber
        }
    }

    mutating func set(_ value: Double, for nutrient: Nutrient) {
        switch nutrient {
        case .calories: calories = value
        case .protein: protein = value
        case .carbs: carbs = value
        case .fat: fat = value
        case .fiber: fiber = value
        }
    }

    /// Per-nutrient difference, never negative (what is still missing to reach `self`).
    func remaining(after consumed: Nutrients) -> Nutrients {
        var result = Nutrients.zero
        for nutrient in Nutrient.allCases {
            result.set(max(0, value(for: nutrient) - consumed.value(for: nutrient)), for: nutrient)
        }
        return result
    }

    static func + (lhs: Nutrients, rhs: Nutrients) -> Nutrients {
        Nutrients(
            calories: lhs.calories + rhs.calories,
            protein: lhs.protein + rhs.protein,
            carbs: lhs.carbs + rhs.carbs,
            fat: lhs.fat + rhs.fat,
            fiber: lhs.fiber + rhs.fiber
        )
    }

    static func += (lhs: inout Nutrients, rhs: Nutrients) {
        lhs = lhs + rhs
    }
}

extension Sequence where Element == Nutrients {
    var total: Nutrients { reduce(.zero, +) }
}

/// The nutrients the app tracks.
enum Nutrient: String, CaseIterable, Identifiable, Codable {
    case calories, protein, carbs, fat, fiber

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calories: return "Calories"
        case .protein: return "Protein"
        case .carbs: return "Carbs"
        case .fat: return "Fat"
        case .fiber: return "Fiber"
        }
    }

    var unit: String { self == .calories ? "kcal" : "g" }

    var color: Color {
        switch self {
        case .calories: return .orange
        case .protein: return .red
        case .carbs: return .blue
        case .fat: return .yellow
        case .fiber: return .green
        }
    }

    var symbol: String {
        switch self {
        case .calories: return "flame.fill"
        case .protein: return "bolt.heart.fill"
        case .carbs: return "leaf.circle.fill"
        case .fat: return "drop.fill"
        case .fiber: return "carrot.fill"
        }
    }

    func format(_ value: Double, withUnit: Bool = true) -> String {
        let number = value.formatted(.number.precision(.fractionLength(0)))
        return withUnit ? "\(number) \(unit)" : number
    }
}
