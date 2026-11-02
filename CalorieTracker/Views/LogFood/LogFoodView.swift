import SwiftUI

/// The "Log Food" tab. After adding a food the coach immediately replies with feedback for the day.
struct LogFoodView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: AppRouter

    @State private var path = NavigationPath()
    @State private var feedback: LoggedFeedback?

    var body: some View {
        NavigationStack(path: $path) {
            FoodBrowser()
                .navigationTitle("Log Food")
                .navigationDestination(for: FoodItem.self) { food in
                    FoodDetailView(food: food) { servings, meal in
                        let entry = store.log(food, servings: servings, meal: meal, on: router.selectedDay)
                        path = NavigationPath()
                        feedback = LoggedFeedback(entry: entry, day: router.selectedDay)
                    }
                }
        }
        .sheet(item: $feedback) { item in
            CoachFeedbackSheet(entry: item.entry, day: item.day)
        }
    }
}

struct LoggedFeedback: Identifiable {
    let entry: MealEntry
    let day: Date
    var id: UUID { entry.id }
}

/// The coach's reply right after logging: "You had X… you should add Y…"
struct CoachFeedbackSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let entry: MealEntry
    let day: Date

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        FoodEmoji(emoji: entry.food.emoji, size: 52)
                        VStack(alignment: .leading) {
                            Text("Logged \(entry.label)")
                                .font(.headline)
                            Text("\(Int(entry.nutrients.calories.rounded())) kcal · \(Int(entry.nutrients.protein.rounded())) g protein")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.bottom, 4)

                    if let analysis = store.analysis(on: day) {
                        CoachAnalysisContent(analysis: analysis, day: day)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Coach says")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Undo", role: .destructive) {
                        store.delete(entry)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
