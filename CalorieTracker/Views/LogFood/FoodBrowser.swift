import SwiftUI

/// Searchable list of all foods with category filters, favourites and recents.
/// Each row is a `NavigationLink(value: FoodItem)` — the parent stack decides the destination.
struct FoodBrowser: View {
    @EnvironmentObject private var store: AppStore
    @State private var query = ""
    @State private var category: FoodCategory?
    @State private var showingCustomFood = false

    var body: some View {
        List {
            if query.isEmpty && category == nil {
                let favorites = store.favoriteFoods
                if !favorites.isEmpty {
                    Section("Favorites") {
                        ForEach(favorites) { FoodLinkRow(food: $0) }
                    }
                }
                let recents = store.recentFoods()
                if !recents.isEmpty {
                    Section("Recent") {
                        ForEach(recents) { FoodLinkRow(food: $0) }
                    }
                }
            }

            Section {
                ForEach(filteredFoods) { food in
                    FoodLinkRow(food: food)
                        .swipeActions {
                            if food.isCustom {
                                Button(role: .destructive) {
                                    store.deleteCustomFood(food)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                }
                if filteredFoods.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No foods match “\(query)”.")
                            .foregroundStyle(.secondary)
                        Button("Create “\(query)” as a custom food") { showingCustomFood = true }
                    }
                }
            } header: {
                Text(category?.title ?? (query.isEmpty ? "All foods" : "Results"))
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search eggs, rice, paneer…")
        .safeAreaInset(edge: .top, spacing: 0) {
            CategoryChips(selection: $category)
                .background(.bar)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCustomFood = true
                } label: {
                    Label("Custom food", systemImage: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showingCustomFood) {
            CustomFoodEditor(initialName: query)
        }
    }

    private var filteredFoods: [FoodItem] {
        var foods = store.allFoods
        if let category {
            foods = foods.filter { category == .custom ? $0.isCustom : $0.category == category }
        }
        return FoodDatabase.search(query, in: foods)
    }
}

private struct CategoryChips: View {
    @Binding var selection: FoodCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: "All", emoji: "🍽️", isSelected: selection == nil) { selection = nil }
                ForEach(FoodCategory.allCases) { category in
                    chip(title: category.title, emoji: category.emoji, isSelected: selection == category) {
                        selection = selection == category ? nil : category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func chip(title: String, emoji: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("\(emoji) \(title)")
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.secondarySystemFill), in: Capsule())
                .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }
}

struct FoodLinkRow: View {
    let food: FoodItem

    var body: some View {
        NavigationLink(value: food) {
            FoodRow(food: food)
        }
    }
}

struct FoodRow: View {
    let food: FoodItem

    var body: some View {
        HStack(spacing: 12) {
            FoodEmoji(emoji: food.emoji)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(food.name).font(.subheadline.bold())
                    if food.isCustom {
                        Image(systemName: "star.fill").font(.caption2).foregroundStyle(.yellow)
                    }
                }
                Text(food.servingName).font(.caption).foregroundStyle(.secondary)
                MacroSummaryRow(nutrients: food.nutrients)
            }
            Spacer()
            Text("\(Int(food.nutrients.calories.rounded()))")
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(.orange)
        }
    }
}

/// Sheet wrapper: pick a food, choose an amount, then hand the result back.
struct AddFoodSheet: View {
    @Environment(\.dismiss) private var dismiss
    let initialMeal: MealType
    let confirmTitle: String
    let onConfirm: (FoodItem, Double, MealType) -> Void

    var body: some View {
        NavigationStack {
            FoodBrowser()
                .navigationTitle("Add food")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
                .navigationDestination(for: FoodItem.self) { food in
                    FoodDetailView(food: food, initialMeal: initialMeal, confirmTitle: confirmTitle) { servings, meal in
                        onConfirm(food, servings, meal)
                        dismiss()
                    }
                }
        }
    }
}
