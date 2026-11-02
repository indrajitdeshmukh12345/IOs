import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: AppRouter

    @State private var addingToMeal: MealType?
    @State private var editingEntry: MealEntry?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    DaySwitcher(day: $router.selectedDay)
                        .padding(.horizontal, 4)

                    if let analysis = store.analysis(on: router.selectedDay) {
                        CalorieRingCard(progress: analysis.progress(for: .calories))

                        VStack(spacing: 16) {
                            ForEach([Nutrient.protein, .carbs, .fat, .fiber]) { nutrient in
                                NutrientBar(progress: analysis.progress(for: nutrient))
                            }
                        }
                        .padding()
                        .cardStyle()

                        CoachPreviewCard(analysis: analysis) {
                            router.selectedTab = .coach
                        }
                    }

                    ForEach(MealType.allCases) { meal in
                        MealSection(
                            meal: meal,
                            entries: store.entries(on: router.selectedDay, meal: meal),
                            onAdd: { addingToMeal = meal },
                            onEdit: { editingEntry = $0 },
                            onDelete: { entry in withAnimation { store.delete(entry) } }
                        )
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(greeting)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: router.selectedDay) {
                                withAnimation { store.copyEntries(from: yesterday, to: router.selectedDay) }
                            }
                        } label: {
                            Label("Repeat previous day's meals", systemImage: "arrow.uturn.backward.circle")
                        }
                        Button {
                            withAnimation { router.selectedDay = Calendar.current.startOfDay(for: .now) }
                        } label: {
                            Label("Jump to today", systemImage: "calendar")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if store.loggingStreak > 0 {
                        Label("\(store.loggingStreak)", systemImage: "flame.fill")
                            .labelStyle(.titleAndIcon)
                            .font(.subheadline.bold())
                            .foregroundStyle(.orange)
                            .accessibilityLabel("\(store.loggingStreak) day logging streak")
                    }
                }
            }
            .sheet(item: $addingToMeal) { meal in
                AddFoodSheet(initialMeal: meal, confirmTitle: "Add to \(meal.title)") { food, servings, chosenMeal in
                    store.log(food, servings: servings, meal: chosenMeal, on: router.selectedDay)
                }
            }
            .sheet(item: $editingEntry) { entry in
                EntryEditorSheet(entry: entry)
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let part: String
        switch hour {
        case 5..<12: part = "Good morning"
        case 12..<17: part = "Good afternoon"
        default: part = "Good evening"
        }
        if let name = store.profile?.name, !name.isEmpty {
            return "\(part), \(name)"
        }
        return part
    }
}

private struct CoachPreviewCard: View {
    let analysis: DailyAnalysis
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                if analysis.isEmpty {
                    Image(systemName: "bubble.left.and.text.bubble.right.fill")
                        .font(.title)
                        .foregroundStyle(Color.accentColor)
                } else {
                    ScoreBadge(score: analysis.score)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Coach").font(.caption.bold()).foregroundStyle(.secondary)
                    Text(analysis.headline).font(.headline)
                }
            }

            if let firstSuggestion = analysis.suggestions.first, !analysis.isEmpty {
                Text("Try adding **\(firstSuggestion.label)** next — \(firstSuggestion.reason).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button(action: onOpen) {
                Label("See full analysis", systemImage: "arrow.right.circle.fill")
                    .font(.subheadline.bold())
            }
            .buttonStyle(.borderless)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardStyle()
    }
}

private struct MealSection: View {
    let meal: MealType
    let entries: [MealEntry]
    let onAdd: () -> Void
    let onEdit: (MealEntry) -> Void
    let onDelete: (MealEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(meal.title, systemImage: meal.symbol)
                    .font(.headline)
                Spacer()
                if !entries.isEmpty {
                    Text("\(Int(entries.map(\.nutrients).total.calories)) kcal")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill").font(.title2)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Add food to \(meal.title)")
            }

            if entries.isEmpty {
                Text("Nothing logged yet")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(entries) { entry in
                    EntryRow(entry: entry)
                        .contentShape(Rectangle())
                        .onTapGesture { onEdit(entry) }
                        .contextMenu {
                            Button { onEdit(entry) } label: { Label("Edit", systemImage: "pencil") }
                            Button(role: .destructive) { onDelete(entry) } label: { Label("Delete", systemImage: "trash") }
                        }
                    if entry.id != entries.last?.id { Divider() }
                }
            }
        }
        .padding()
        .cardStyle()
    }
}

struct EntryRow: View {
    let entry: MealEntry

    var body: some View {
        HStack(spacing: 12) {
            FoodEmoji(emoji: entry.food.emoji)
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.food.name).font(.subheadline.bold())
                Text("\(ServingFormatter.string(entry.servings)) × \(entry.food.servingName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                MacroSummaryRow(nutrients: entry.nutrients)
            }
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(Int(entry.nutrients.calories.rounded()))")
                    .font(.headline.monospacedDigit())
                Text("kcal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// Edit servings / meal of a logged entry, or delete it.
struct EntryEditorSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var entry: MealEntry

    init(entry: MealEntry) {
        _entry = State(initialValue: entry)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        FoodEmoji(emoji: entry.food.emoji, size: 52)
                        VStack(alignment: .leading) {
                            Text(entry.food.name).font(.headline)
                            Text(entry.food.servingName).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Amount") {
                    ServingsInput(servings: $entry.servings, food: entry.food)
                }
                Section("Meal") {
                    Picker("Meal", selection: $entry.mealType) {
                        ForEach(MealType.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Nutrition") {
                    NutritionTable(nutrients: entry.nutrients)
                }
                Section {
                    Button("Delete entry", role: .destructive) {
                        store.delete(entry)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.update(entry)
                        dismiss()
                    }
                    .disabled(entry.servings <= 0)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppStore.preview)
}
