import SwiftUI

/// Multi-step profile setup. Ends with the recommended daily targets.
struct OnboardingView: View {
    @EnvironmentObject private var store: AppStore

    enum Step: Int, CaseIterable {
        case welcome, basics, body, activity, goal, results
    }

    @State private var step: Step = .welcome
    @State private var profile = UserProfile()

    var body: some View {
        VStack(spacing: 0) {
            if step != .welcome {
                ProgressView(value: Double(step.rawValue), total: Double(Step.allCases.count - 1))
                    .padding(.horizontal)
                    .padding(.top, 8)
            }

            Group {
                switch step {
                case .welcome: WelcomeStep()
                case .basics: BasicsStep(profile: $profile)
                case .body: BodyStep(profile: $profile)
                case .activity: ActivityStep(profile: $profile)
                case .goal: GoalStep(profile: $profile)
                case .results: ResultsStep(profile: profile)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)).combined(with: .opacity))
            .id(step)

            HStack {
                if step != .welcome {
                    Button("Back") { go(-1) }
                        .buttonStyle(.bordered)
                }
                Spacer()
                Button(action: next) {
                    Text(primaryTitle)
                        .frame(minWidth: 120)
                        .bold()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canContinue)
            }
            .controlSize(.large)
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private var primaryTitle: String {
        switch step {
        case .welcome: return "Get started"
        case .results: return "Start tracking"
        default: return "Continue"
        }
    }

    private var canContinue: Bool {
        switch step {
        case .basics: return profile.age >= 13 && profile.age <= 100
        case .body: return profile.heightCm > 100 && profile.weightKg > 25
        default: return true
        }
    }

    private func next() {
        if step == .results {
            store.saveProfile(profile)
        } else {
            go(1)
        }
    }

    private func go(_ delta: Int) {
        guard let newStep = Step(rawValue: step.rawValue + delta) else { return }
        withAnimation(.easeInOut) { step = newStep }
    }
}

// MARK: - Steps

private struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("🍳💪")
                .font(.system(size: 80))
            Text("MassTrack")
                .font(.largeTitle.bold())
            Text("Track your calories, protein, carbs and fat — and get a personal coach that tells you exactly what to eat next to gain mass.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            VStack(alignment: .leading, spacing: 14) {
                feature("person.text.rectangle", "Personal targets from your body & goal")
                feature("fork.knife", "Log 80+ foods incl. Indian meals in seconds")
                feature("bubble.left.and.text.bubble.right", "Coach feedback: what you had & what to add")
                feature("chart.xyaxis.line", "Weekly trends and weight progress")
            }
            .padding(.top)
            Spacer()
        }
        .padding()
    }

    private func feature(_ symbol: String, _ text: String) -> some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: symbol).foregroundStyle(Color.accentColor)
        }
        .font(.subheadline)
    }
}

private struct StepHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.title.bold())
            Text(subtitle).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 24)
    }
}

private struct BasicsStep: View {
    @Binding var profile: UserProfile

    var body: some View {
        VStack(spacing: 0) {
            StepHeader(title: "About you", subtitle: "Used to estimate how many calories your body burns.")
            Form {
                Section("Name") {
                    TextField("Your name", text: $profile.name)
                        .textContentType(.givenName)
                }
                Section("Sex") {
                    Picker("Sex", selection: $profile.sex) {
                        ForEach(Sex.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Age") {
                    Stepper(value: $profile.age, in: 13...100) {
                        Text("\(profile.age) years")
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
    }
}

private struct BodyStep: View {
    @Binding var profile: UserProfile

    var body: some View {
        VStack(spacing: 0) {
            StepHeader(title: "Your body", subtitle: "Height and weight drive your calorie and protein targets.")
            Form {
                Section {
                    Picker("Units", selection: $profile.unitSystem) {
                        ForEach(UnitSystem.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                BodyMeasurementsSection(profile: $profile)
            }
            .scrollContentBackground(.hidden)
        }
    }
}

/// Height / weight / target weight inputs that respect the selected unit system. Reused in the profile editor.
struct BodyMeasurementsSection: View {
    @Binding var profile: UserProfile

    var body: some View {
        Section("Height") {
            if profile.unitSystem == .metric {
                Stepper(value: $profile.heightCm, in: 120...230, step: 1) {
                    Text("\(Int(profile.heightCm)) cm")
                }
            } else {
                Stepper(value: feet, in: 4...7) { Text("\(feet.wrappedValue) ft") }
                Stepper(value: inches, in: 0...11) { Text("\(inches.wrappedValue) in") }
            }
        }
        Section("Current weight") {
            weightStepper(value: weight, title: UnitConversion.formatWeight(profile.weightKg, system: profile.unitSystem))
        }
        Section {
            Toggle("Set a target weight", isOn: hasTarget)
            if profile.targetWeightKg != nil {
                weightStepper(
                    value: targetWeight,
                    title: UnitConversion.formatWeight(profile.targetWeightKg ?? profile.weightKg, system: profile.unitSystem)
                )
            }
        } header: {
            Text("Goal weight")
        } footer: {
            if let weeks = NutritionCalculator.weeksToTarget(for: profile) {
                Text("At your plan's pace that's about \(Int(weeks.rounded(.up))) weeks.")
            }
        }
    }

    private func weightStepper(value: Binding<Double>, title: String) -> some View {
        let isMetric = profile.unitSystem == .metric
        let range: ClosedRange<Double> = isMetric ? 30...200 : 66...440
        let step: Double = isMetric ? 0.5 : 1
        return Stepper(value: value, in: range, step: step) {
            Text(title).monospacedDigit()
        }
    }

    // Bindings that convert between display units and the stored metric values.

    private var weight: Binding<Double> {
        Binding(
            get: { profile.unitSystem == .metric ? profile.weightKg : UnitConversion.kgToLb(profile.weightKg).rounded() },
            set: { profile.weightKg = profile.unitSystem == .metric ? $0 : UnitConversion.lbToKg($0) }
        )
    }

    private var targetWeight: Binding<Double> {
        Binding(
            get: {
                let kg = profile.targetWeightKg ?? profile.weightKg
                return profile.unitSystem == .metric ? kg : UnitConversion.kgToLb(kg).rounded()
            },
            set: { profile.targetWeightKg = profile.unitSystem == .metric ? $0 : UnitConversion.lbToKg($0) }
        )
    }

    private var hasTarget: Binding<Bool> {
        Binding(
            get: { profile.targetWeightKg != nil },
            set: { profile.targetWeightKg = $0 ? (profile.weightKg + 5).rounded() : nil }
        )
    }

    private var feet: Binding<Int> {
        Binding(
            get: { UnitConversion.cmToFeetInches(profile.heightCm).feet },
            set: { profile.heightCm = UnitConversion.feetInchesToCm(feet: $0, inches: UnitConversion.cmToFeetInches(profile.heightCm).inches) }
        )
    }

    private var inches: Binding<Int> {
        Binding(
            get: { UnitConversion.cmToFeetInches(profile.heightCm).inches },
            set: { profile.heightCm = UnitConversion.feetInchesToCm(feet: UnitConversion.cmToFeetInches(profile.heightCm).feet, inches: $0) }
        )
    }
}

private struct ActivityStep: View {
    @Binding var profile: UserProfile

    var body: some View {
        VStack(spacing: 0) {
            StepHeader(title: "Activity level", subtitle: "How active are you on a typical week?")
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(ActivityLevel.allCases) { level in
                        SelectableCard(
                            title: level.title,
                            subtitle: level.detail,
                            isSelected: profile.activityLevel == level
                        ) { profile.activityLevel = level }
                    }
                }
                .padding()
            }
        }
    }
}

private struct GoalStep: View {
    @Binding var profile: UserProfile

    var body: some View {
        VStack(spacing: 0) {
            StepHeader(title: "Goal & diet", subtitle: "Pick how fast you want to gain, and what you eat.")
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(FitnessGoal.allCases) { goal in
                        SelectableCard(
                            title: goal.title,
                            subtitle: goal.detail,
                            isSelected: profile.goal == goal
                        ) { profile.goal = goal }
                    }

                    Text("Diet preference")
                        .font(.headline)
                        .padding(.top, 8)
                    Text("Coach suggestions will only include foods you eat.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("Diet", selection: $profile.diet) {
                        ForEach(DietPreference.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
            }
        }
    }
}

struct SelectableCard: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ResultsStep: View {
    let profile: UserProfile

    var body: some View {
        let rec = NutritionCalculator.recommendation(for: profile)
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                StepHeader(
                    title: "Your daily plan",
                    subtitle: "Recommended intake for \(profile.goal.title.lowercased()), \(profile.displayName)."
                )
                .padding(.horizontal, -16)

                TargetsGrid(targets: rec.targets)

                VStack(alignment: .leading, spacing: 10) {
                    Text("How we calculated this").font(.headline)
                    ForEach(rec.explanations, id: \.self) { line in
                        Label {
                            Text(line).font(.subheadline)
                        } icon: {
                            Image(systemName: "checkmark.circle").foregroundStyle(.green)
                        }
                    }
                    Label("Drink about \(rec.waterLiters.formatted()) L of water per day.", systemImage: "drop")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
                .padding()
                .cardStyle()

                Text("You can fine-tune these targets anytime in Profile.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

/// Grid of the five daily targets.
struct TargetsGrid: View {
    let targets: Nutrients

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(Nutrient.allCases) { nutrient in
                VStack(alignment: .leading, spacing: 4) {
                    Label(nutrient.title, systemImage: nutrient.symbol)
                        .font(.caption.bold())
                        .foregroundStyle(nutrient.color)
                    Text(nutrient.format(targets.value(for: nutrient)))
                        .font(.title2.bold().monospacedDigit())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .cardStyle()
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppStore(persistence: .temporary))
}
