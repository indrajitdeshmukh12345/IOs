import SwiftUI

struct CoachView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case myDay = "My day"
        case whatIf = "Quick check"
        var id: String { rawValue }
    }

    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: AppRouter
    @State private var mode: Mode = .myDay

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Picker("Mode", selection: $mode) {
                        ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    switch mode {
                    case .myDay:
                        DaySwitcher(day: $router.selectedDay)
                            .padding(.horizontal, 4)
                        if let analysis = store.analysis(on: router.selectedDay) {
                            CoachAnalysisContent(analysis: analysis, day: router.selectedDay)
                        }
                    case .whatIf:
                        QuickCheckView()
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Coach")
        }
    }
}

/// Headline, score, coach messages and suggested foods for an analysis.
struct CoachAnalysisContent: View {
    @EnvironmentObject private var store: AppStore

    let analysis: DailyAnalysis
    /// When set, suggestions can be logged straight to this day.
    var day: Date?

    @State private var addedIDs: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                if !analysis.isEmpty {
                    ScoreBadge(score: analysis.score)
                }
                Text(analysis.headline)
                    .font(.title3.bold())
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !analysis.isEmpty {
                MacroSnapshot(analysis: analysis)
            }

            ForEach(analysis.messages) { message in
                CoachMessageView(message: message)
            }

            if !analysis.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Suggested additions")
                            .font(.headline)
                        Spacer()
                        if day != nil && addedIDs.count < analysis.suggestions.count {
                            Button("Add all") {
                                analysis.suggestions.forEach(add)
                            }
                            .font(.subheadline.bold())
                        }
                    }
                    ForEach(analysis.suggestions) { suggestion in
                        SuggestionRow(suggestion: suggestion, onAdd: addAction(for: suggestion))
                        if suggestion.id != analysis.suggestions.last?.id { Divider() }
                    }
                    ProjectedTotalsView(projected: analysis.projectedTotals, targets: analysis.targets)
                        .padding(.top, 6)
                }
                .padding()
                .cardStyle()
            }
        }
        .onChange(of: analysis.entryCount) { _, _ in
            // Suggestions are recalculated after logging, so reset "added" markers.
            addedIDs.removeAll()
        }
    }

    private func addAction(for suggestion: FoodSuggestion) -> (() -> Void)? {
        guard day != nil, !addedIDs.contains(suggestion.id) else { return nil }
        return { add(suggestion) }
    }

    private func add(_ suggestion: FoodSuggestion) {
        guard let day, !addedIDs.contains(suggestion.id) else { return }
        addedIDs.insert(suggestion.id)
        withAnimation {
            store.log(suggestion.food, servings: suggestion.servings, meal: .suggested(), on: day)
        }
    }
}

/// Compact consumed / target overview.
private struct MacroSnapshot: View {
    let analysis: DailyAnalysis

    var body: some View {
        HStack(spacing: 0) {
            ForEach([Nutrient.calories, .protein, .carbs, .fat]) { nutrient in
                let item = analysis.progress(for: nutrient)
                VStack(spacing: 6) {
                    ZStack {
                        ProgressRing(fraction: item.fraction, color: nutrient.color, lineWidth: 6)
                        Text("\(item.percent)%")
                            .font(.caption2.bold().monospacedDigit())
                    }
                    .frame(width: 54, height: 54)
                    Text(nutrient.title).font(.caption.bold())
                    Text("\(nutrient.format(item.consumed, withUnit: false))/\(nutrient.format(item.target, withUnit: false))")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical)
        .cardStyle()
    }
}

/// "If you add these, you'll reach…"
struct ProjectedTotalsView: View {
    let projected: Nutrients
    let targets: Nutrients

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("With these additions you'd reach")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            HStack {
                ForEach([Nutrient.calories, .protein, .carbs, .fat]) { nutrient in
                    let target = targets.value(for: nutrient)
                    let percent = target > 0 ? Int((projected.value(for: nutrient) / target * 100).rounded()) : 0
                    VStack(alignment: .leading) {
                        Text(nutrient.format(projected.value(for: nutrient)))
                            .font(.caption.bold().monospacedDigit())
                        Text("\(percent)% \(nutrient.title.lowercased())")
                            .font(.caption2)
                            .foregroundStyle(nutrient.color)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

/// Try out a day's food without logging it: "If I only eat 4 eggs today, what am I missing?"
struct QuickCheckView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: AppRouter
    @State private var items: [MealEntry] = []
    @State private var showingPicker = false
    @State private var loggedMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("What will you eat today?")
                    .font(.title3.bold())
                Text("Pick foods and amounts — e.g. 4 eggs — and the coach will tell you what you're getting and what to add. Nothing is logged unless you choose to.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                ForEach(items) { item in
                    HStack {
                        EntryRow(entry: item)
                        Button {
                            withAnimation { items.removeAll { $0.id == item.id } }
                        } label: {
                            Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Remove \(item.food.name)")
                    }
                    Divider()
                }
                Button {
                    showingPicker = true
                } label: {
                    Label(items.isEmpty ? "Add a food" : "Add another food", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding()
            .cardStyle()

            if !items.isEmpty, let profile = store.profile {
                let analysis = NutritionCoach.analyze(
                    entries: items,
                    targets: store.targets,
                    profile: profile,
                    foods: store.allFoods
                )
                CoachAnalysisContent(analysis: analysis, day: nil)

                Button {
                    for item in items {
                        store.log(item.food, servings: item.servings, meal: item.mealType, on: router.selectedDay)
                    }
                    loggedMessage = "Logged \(items.count) item\(items.count == 1 ? "" : "s") to your diary."
                    withAnimation { items.removeAll() }
                } label: {
                    Label("Log these foods", systemImage: "square.and.arrow.down.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            if let loggedMessage {
                Label(loggedMessage, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.subheadline.bold())
            }
        }
        .sheet(isPresented: $showingPicker) {
            AddFoodSheet(initialMeal: .suggested(), confirmTitle: "Check") { food, servings, meal in
                loggedMessage = nil
                withAnimation {
                    items.append(MealEntry(mealType: meal, food: food, servings: servings))
                }
            }
        }
    }
}
