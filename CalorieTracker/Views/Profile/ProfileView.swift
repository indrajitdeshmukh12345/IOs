import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showingEditor = false
    @State private var showingTargets = false
    @State private var confirmingReset = false

    var body: some View {
        NavigationStack {
            List {
                if let profile = store.profile, let rec = store.recommendation {
                    Section {
                        HStack(spacing: 14) {
                            Text(String(profile.name.prefix(1)).uppercased().ifEmpty("🙂"))
                                .font(.title.bold())
                                .frame(width: 60, height: 60)
                                .background(Color.accentColor.opacity(0.2), in: Circle())
                            VStack(alignment: .leading, spacing: 3) {
                                Text(profile.name.isEmpty ? "Your profile" : profile.name).font(.title3.bold())
                                Text("\(profile.age) y · \(profile.sex.title) · \(UnitConversion.formatHeight(profile.heightCm, system: profile.unitSystem)) · \(UnitConversion.formatWeight(profile.weightKg, system: profile.unitSystem))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text("\(profile.goal.title) · \(profile.diet.title)")
                                    .font(.caption.bold())
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        Button("Edit profile") { showingEditor = true }
                    }

                    Section {
                        TargetsGrid(targets: store.targets)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    } header: {
                        HStack {
                            Text("Daily targets")
                            Spacer()
                            if profile.customTargets != nil {
                                Text("Custom").foregroundStyle(.orange)
                            }
                        }
                    }

                    Section {
                        Button("Adjust targets manually") { showingTargets = true }
                        if profile.customTargets != nil {
                            Button("Use recommended targets") {
                                var updated = profile
                                updated.customTargets = nil
                                store.saveProfile(updated)
                            }
                        }
                    }

                    Section("Your numbers") {
                        LabeledContent("BMR", value: "\(Int(rec.bmr.rounded())) kcal")
                        LabeledContent("Maintenance (TDEE)", value: "\(Int(rec.tdee.rounded())) kcal")
                        LabeledContent("Surplus", value: "+\(Int(rec.surplus)) kcal")
                        LabeledContent("BMI", value: profile.bmi.formatted(.number.precision(.fractionLength(1))))
                        LabeledContent("Water", value: "\(rec.waterLiters.formatted()) L / day")
                        LabeledContent(
                            "Expected gain",
                            value: "\(UnitConversion.formatWeight(rec.projectedWeeklyGainKg, system: profile.unitSystem)) / week"
                        )
                        if let weeks = NutritionCalculator.weeksToTarget(for: profile), let target = profile.targetWeightKg {
                            LabeledContent(
                                "Reach \(UnitConversion.formatWeight(target, system: profile.unitSystem))",
                                value: "~\(Int(weeks.rounded(.up))) weeks"
                            )
                        }
                    }

                    Section("How your targets are set") {
                        ForEach(rec.explanations, id: \.self) { line in
                            Text(line).font(.subheadline)
                        }
                    }
                }

                Section {
                    Button("Reset all data", role: .destructive) { confirmingReset = true }
                } footer: {
                    Text("Nutrition values are estimates for guidance only and are not medical advice.")
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingEditor) {
                if let profile = store.profile {
                    ProfileEditorSheet(profile: profile)
                }
            }
            .sheet(isPresented: $showingTargets) {
                if let profile = store.profile {
                    TargetsEditorSheet(profile: profile)
                }
            }
            .confirmationDialog("Delete your profile, food log and custom foods?", isPresented: $confirmingReset, titleVisibility: .visible) {
                Button("Reset everything", role: .destructive) { store.resetAllData() }
            }
        }
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String { isEmpty ? fallback : self }
}

private struct ProfileEditorSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var profile: UserProfile

    init(profile: UserProfile) {
        _profile = State(initialValue: profile)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("About you") {
                    TextField("Name", text: $profile.name)
                    Picker("Sex", selection: $profile.sex) {
                        ForEach(Sex.allCases) { Text($0.title).tag($0) }
                    }
                    Stepper("Age: \(profile.age)", value: $profile.age, in: 13...100)
                }
                Section("Units") {
                    Picker("Units", selection: $profile.unitSystem) {
                        ForEach(UnitSystem.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                BodyMeasurementsSection(profile: $profile)
                Section("Activity") {
                    Picker("Activity level", selection: $profile.activityLevel) {
                        ForEach(ActivityLevel.allCases) { level in
                            VStack(alignment: .leading) {
                                Text(level.title)
                                Text(level.detail).font(.caption).foregroundStyle(.secondary)
                            }
                            .tag(level)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                Section("Goal") {
                    Picker("Goal", selection: $profile.goal) {
                        ForEach(FitnessGoal.allCases) { Text($0.title).tag($0) }
                    }
                    Picker("Diet", selection: $profile.diet) {
                        ForEach(DietPreference.allCases) { Text($0.title).tag($0) }
                    }
                }
                Section("New recommended targets") {
                    let targets = NutritionCalculator.recommendation(for: profile).targets
                    ForEach(Nutrient.allCases) { nutrient in
                        LabeledContent(nutrient.title, value: nutrient.format(targets.value(for: nutrient)))
                    }
                    if profile.customTargets != nil {
                        Text("You're using custom targets — reset them in Profile to apply these.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle("Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.saveProfile(profile)
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct TargetsEditorSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let profile: UserProfile
    @State private var targets: Nutrients

    init(profile: UserProfile) {
        self.profile = profile
        _targets = State(initialValue: NutritionCalculator.targets(for: profile))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper(value: $targets.calories, in: 1200...6000, step: 50) {
                        LabeledContent("Calories", value: "\(Int(targets.calories)) kcal")
                    }
                    Stepper(value: $targets.protein, in: 40...350, step: 5) {
                        LabeledContent("Protein", value: "\(Int(targets.protein)) g")
                    }
                    Stepper(value: $targets.carbs, in: 50...900, step: 10) {
                        LabeledContent("Carbs", value: "\(Int(targets.carbs)) g")
                    }
                    Stepper(value: $targets.fat, in: 20...250, step: 5) {
                        LabeledContent("Fat", value: "\(Int(targets.fat)) g")
                    }
                    Stepper(value: $targets.fiber, in: 10...80, step: 1) {
                        LabeledContent("Fiber", value: "\(Int(targets.fiber)) g")
                    }
                } footer: {
                    let macroCalories = targets.protein * 4 + targets.carbs * 4 + targets.fat * 9
                    Text("Your macros add up to \(Int(macroCalories)) kcal.")
                }

                Section {
                    Button("Balance carbs to match calories") {
                        targets.carbs = max(0, ((targets.calories - targets.protein * 4 - targets.fat * 9) / 4).rounded())
                    }
                }
            }
            .navigationTitle("Custom targets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var updated = profile
                        updated.customTargets = targets
                        store.saveProfile(updated)
                        dismiss()
                    }
                }
            }
        }
    }
}
