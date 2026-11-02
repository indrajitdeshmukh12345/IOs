import SwiftUI

/// Pick an amount and meal for a food, see its nutrition and how it moves today's totals.
struct FoodDetailView: View {
    @EnvironmentObject private var store: AppStore

    let food: FoodItem
    let confirmTitle: String
    let onConfirm: (Double, MealType) -> Void

    @State private var servings: Double = 1
    @State private var meal: MealType

    init(food: FoodItem, initialMeal: MealType = .suggested(), confirmTitle: String = "Add to log", onConfirm: @escaping (Double, MealType) -> Void) {
        self.food = food
        self.confirmTitle = confirmTitle
        self.onConfirm = onConfirm
        _meal = State(initialValue: initialMeal)
    }

    var body: some View {
        Form {
            Section {
                HStack(spacing: 14) {
                    FoodEmoji(emoji: food.emoji, size: 60)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(food.name).font(.title3.bold())
                        Text("1 serving = \(food.servingName)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(food.dietType.title)
                            .font(.caption.bold())
                            .foregroundStyle(food.dietType == .nonVeg ? Color.red : Color.green)
                    }
                }
            }

            Section("How much?") {
                ServingsInput(servings: $servings, food: food)
            }

            Section("Meal") {
                Picker("Meal", selection: $meal) {
                    ForEach(MealType.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            Section("Nutrition for \(food.quantityLabel(servings: servings))") {
                NutritionTable(nutrients: food.nutrients(servings: servings))
            }

            Section {
                ForEach(Nutrient.allCases) { nutrient in
                    impactRow(nutrient)
                }
            } header: {
                Text("Share of your daily target")
            } footer: {
                Text("Protein density: \(food.proteinDensity.formatted(.number.precision(.fractionLength(1)))) g protein per 100 kcal.")
            }
        }
        .navigationTitle(food.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.toggleFavorite(food)
                } label: {
                    Image(systemName: store.isFavorite(food) ? "heart.fill" : "heart")
                        .foregroundStyle(.pink)
                }
                .accessibilityLabel(store.isFavorite(food) ? "Remove from favorites" : "Add to favorites")
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                onConfirm(servings, meal)
            } label: {
                Text("\(confirmTitle) · \(Int(food.nutrients(servings: servings).calories.rounded())) kcal")
                    .bold()
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(servings <= 0)
            .padding()
            .background(.bar)
        }
    }

    private func impactRow(_ nutrient: Nutrient) -> some View {
        let target = store.targets.value(for: nutrient)
        let amount = food.nutrients(servings: servings).value(for: nutrient)
        let share = target > 0 ? amount / target : 0
        return HStack {
            Text(nutrient.title)
                .foregroundStyle(nutrient.color)
                .frame(width: 70, alignment: .leading)
            ProgressView(value: min(share, 1))
                .tint(nutrient.color)
            Text("\(Int((share * 100).rounded()))%")
                .font(.subheadline.monospacedDigit())
                .frame(width: 48, alignment: .trailing)
        }
    }
}

/// Servings stepper with quick picks and an optional grams field.
struct ServingsInput: View {
    @Binding var servings: Double
    let food: FoodItem

    private let quickPicks: [Double] = [0.5, 1, 2, 3, 4]

    var body: some View {
        Stepper(value: $servings, in: 0.25...50, step: 0.5) {
            HStack {
                Text(ServingFormatter.string(servings))
                    .font(.title3.bold().monospacedDigit())
                Text(servings == 1 ? "serving" : "servings")
                    .foregroundStyle(.secondary)
            }
        }

        HStack {
            ForEach(quickPicks, id: \.self) { value in
                Button(ServingFormatter.string(value) + "×") {
                    servings = value
                }
                .buttonStyle(.bordered)
                .tint(servings == value ? Color.accentColor : Color.secondary)
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.borderless)

        HStack {
            Text("Or enter grams")
            Spacer()
            TextField("grams", value: grams, format: .number.precision(.fractionLength(0)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
            Text("g").foregroundStyle(.secondary)
        }
    }

    private var grams: Binding<Double> {
        Binding(
            get: { (servings * food.servingGrams).rounded() },
            set: { newValue in
                guard food.servingGrams > 0, newValue > 0 else { return }
                servings = newValue / food.servingGrams
            }
        )
    }
}

struct NutritionTable: View {
    let nutrients: Nutrients

    var body: some View {
        ForEach(Nutrient.allCases) { nutrient in
            HStack {
                Label(nutrient.title, systemImage: nutrient.symbol)
                    .foregroundStyle(nutrient.color)
                Spacer()
                Text(nutrients.value(for: nutrient).formatted(.number.precision(.fractionLength(0...1))) + " " + nutrient.unit)
                    .monospacedDigit()
            }
        }
    }
}
