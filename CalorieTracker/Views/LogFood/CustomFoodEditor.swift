import SwiftUI

/// Create a custom food with your own nutrition values (e.g. from a package label).
struct CustomFoodEditor: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var emoji = "🍽️"
    @State private var servingName = "1 serving"
    @State private var servingGrams: Double = 100
    @State private var nutrients = Nutrients()
    @State private var dietType: FoodDietType = .vegetarian

    private let emojiChoices = ["🍽️", "🥚", "🍗", "🐟", "🥩", "🍚", "🫓", "🍞", "🍝", "🍲", "🍛", "🥗", "🥦", "🍌", "🍎", "🥜", "🥛", "🧀", "🥤", "🍫", "💪"]

    init(initialName: String = "") {
        _name = State(initialValue: initialName)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Food") {
                    TextField("Name (e.g. Mom's chicken curry)", text: $name)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(emojiChoices, id: \.self) { choice in
                                Text(choice)
                                    .font(.title2)
                                    .padding(6)
                                    .background(
                                        Circle().fill(choice == emoji ? Color.accentColor.opacity(0.25) : .clear)
                                    )
                                    .onTapGesture { emoji = choice }
                            }
                        }
                    }
                    Picker("Type", selection: $dietType) {
                        ForEach(FoodDietType.allCases) { Text($0.title).tag($0) }
                    }
                }

                Section("Serving") {
                    TextField("Serving description (e.g. 1 bowl)", text: $servingName)
                    numberField("Weight", unit: "g", value: $servingGrams)
                }

                Section {
                    numberField("Calories", unit: "kcal", value: $nutrients.calories)
                    numberField("Protein", unit: "g", value: $nutrients.protein)
                    numberField("Carbs", unit: "g", value: $nutrients.carbs)
                    numberField("Fat", unit: "g", value: $nutrients.fat)
                    numberField("Fiber", unit: "g", value: $nutrients.fiber)
                } header: {
                    Text("Nutrition per serving")
                } footer: {
                    if abs(estimatedCalories - nutrients.calories) > max(40, nutrients.calories * 0.2) && nutrients.calories > 0 {
                        Text("Heads up: the macros add up to about \(Int(estimatedCalories)) kcal (4·P + 4·C + 9·F).")
                            .foregroundStyle(.orange)
                    } else {
                        Text("Tip: copy the numbers from the package label.")
                    }
                }

                if nutrients.calories == 0 && estimatedCalories > 0 {
                    Button("Fill calories from macros (\(Int(estimatedCalories)) kcal)") {
                        nutrients.calories = estimatedCalories.rounded()
                    }
                }
            }
            .navigationTitle("Custom food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!isValid)
                }
            }
        }
    }

    private var estimatedCalories: Double {
        nutrients.protein * 4 + nutrients.carbs * 4 + nutrients.fat * 9
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && nutrients.calories > 0 && servingGrams > 0
    }

    private func numberField(_ title: String, unit: String, value: Binding<Double>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0", value: value, format: .number.precision(.fractionLength(0...1)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .leading)
        }
    }

    private func save() {
        let food = FoodItem(
            id: "custom-\(UUID().uuidString)",
            name: name.trimmingCharacters(in: .whitespaces),
            emoji: emoji,
            category: .custom,
            dietType: dietType,
            servingName: servingName.isEmpty ? "1 serving" : servingName,
            servingGrams: servingGrams,
            nutrients: nutrients,
            maxSuggestedServings: 2,
            isCustom: true
        )
        store.addCustomFood(food)
        dismiss()
    }
}
