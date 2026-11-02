import Charts
import SwiftUI

struct ProgressTabView: View {
    enum ChartRange: Int, CaseIterable, Identifiable {
        case week = 7, twoWeeks = 14, month = 30
        var id: Int { rawValue }
        var title: String {
            switch self {
            case .week: return "7 days"
            case .twoWeeks: return "14 days"
            case .month: return "30 days"
            }
        }
    }

    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var router: AppRouter
    @State private var range: ChartRange = .week
    @State private var chartNutrient: Nutrient = .calories
    @State private var showingWeightEntry = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Range", selection: $range) {
                        ForEach(ChartRange.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    let history = store.history(days: range.rawValue)
                    AveragesCard(history: history, targets: store.targets)
                    intakeChart(history)
                    weightCard
                    daysList(history)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Progress")
            .sheet(isPresented: $showingWeightEntry) {
                WeightEntrySheet()
            }
        }
    }

    // MARK: Intake chart

    private func intakeChart(_ history: [DayTotals]) -> some View {
        let target = store.targets.value(for: chartNutrient)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Daily intake").font(.headline)
                Spacer()
                Picker("Nutrient", selection: $chartNutrient) {
                    ForEach(Nutrient.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.menu)
            }

            Chart {
                ForEach(history) { day in
                    BarMark(
                        x: .value("Day", day.day, unit: .day),
                        y: .value(chartNutrient.title, day.totals.value(for: chartNutrient))
                    )
                    .foregroundStyle(chartNutrient.color.gradient)
                    .cornerRadius(4)
                }
                if target > 0 {
                    RuleMark(y: .value("Target", target))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 4]))
                        .foregroundStyle(.secondary)
                        .annotation(position: .top, alignment: .leading) {
                            Text("Target \(chartNutrient.format(target))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: axisStride)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day())
                }
            }
            .frame(height: 220)
        }
        .padding()
        .cardStyle()
    }

    // MARK: Weight

    private var weightCard: some View {
        let unit = store.profile?.unitSystem ?? .metric
        let weights = store.weights
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Body weight").font(.headline)
                Spacer()
                Button {
                    showingWeightEntry = true
                } label: {
                    Label("Log weight", systemImage: "plus.circle.fill")
                        .font(.subheadline.bold())
                }
            }

            if weights.count >= 2 {
                Chart {
                    ForEach(weights) { entry in
                        LineMark(
                            x: .value("Date", entry.date, unit: .day),
                            y: .value("Weight", displayWeight(entry.weightKg, unit))
                        )
                        .interpolationMethod(.catmullRom)
                        PointMark(
                            x: .value("Date", entry.date, unit: .day),
                            y: .value("Weight", displayWeight(entry.weightKg, unit))
                        )
                    }
                    if let target = store.profile?.targetWeightKg {
                        RuleMark(y: .value("Goal", displayWeight(target, unit)))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                            .foregroundStyle(.green)
                    }
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .frame(height: 180)
            }

            if let first = weights.first, let last = weights.last {
                let change = last.weightKg - first.weightKg
                HStack {
                    VStack(alignment: .leading) {
                        Text("Current").font(.caption).foregroundStyle(.secondary)
                        Text(UnitConversion.formatWeight(last.weightKg, system: unit)).font(.title3.bold())
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Change").font(.caption).foregroundStyle(.secondary)
                        Text((change >= 0 ? "+" : "−") + UnitConversion.formatWeight(abs(change), system: unit))
                            .font(.title3.bold())
                            .foregroundStyle(change >= 0 ? Color.green : Color.orange)
                    }
                }
            } else {
                Text("Log your weight weekly to see if your surplus is working. Aim for about 0.25–0.5 kg gain per week.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .cardStyle()
    }

    private var axisStride: Int {
        switch range {
        case .week: return 1
        case .twoWeeks: return 2
        case .month: return 5
        }
    }

    private func displayWeight(_ kg: Double, _ unit: UnitSystem) -> Double {
        unit == .metric ? kg : UnitConversion.kgToLb(kg)
    }

    // MARK: Days

    private func daysList(_ history: [DayTotals]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Daily log").font(.headline)
            ForEach(Array(history.reversed())) { day in
                Button {
                    router.selectedDay = day.day
                    router.selectedTab = .today
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(day.day, format: .dateTime.weekday(.abbreviated).day().month())
                                .font(.subheadline.bold())
                            if day.entryCount == 0 {
                                Text("Not logged").font(.caption).foregroundStyle(.tertiary)
                            } else {
                                MacroSummaryRow(nutrients: day.totals)
                            }
                        }
                        Spacer()
                        if day.entryCount > 0 {
                            let percent = store.targets.calories > 0 ? day.totals.calories / store.targets.calories : 0
                            Text("\(Int(day.totals.calories)) kcal")
                                .font(.subheadline.monospacedDigit())
                            Image(systemName: percent >= 0.9 ? "checkmark.circle.fill" : "circle.dashed")
                                .foregroundStyle(percent >= 0.9 ? Color.green : Color.orange)
                        }
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Divider()
            }
        }
        .padding()
        .cardStyle()
    }
}

private struct AveragesCard: View {
    let history: [DayTotals]
    let targets: Nutrients

    var body: some View {
        let logged = history.filter { $0.entryCount > 0 }
        let average = logged.isEmpty ? Nutrients.zero : logged.map(\.totals).total.scaled(by: 1 / Double(logged.count))
        let daysOnTarget = logged.filter { targets.calories > 0 && $0.totals.calories >= targets.calories * 0.9 }.count

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Daily average").font(.headline)
                Spacer()
                Text("\(logged.count)/\(history.count) days logged")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack {
                ForEach([Nutrient.calories, .protein, .carbs, .fat]) { nutrient in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(nutrient.title).font(.caption).foregroundStyle(nutrient.color)
                        Text(nutrient.format(average.value(for: nutrient), withUnit: false))
                            .font(.title3.bold().monospacedDigit())
                        let target = targets.value(for: nutrient)
                        Text(target > 0 ? "\(Int((average.value(for: nutrient) / target * 100).rounded()))%" : "–")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            if !logged.isEmpty {
                Label("Hit your calorie target on \(daysOnTarget) of \(logged.count) logged days.", systemImage: "target")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .cardStyle()
    }
}

private struct WeightEntrySheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date.now
    @State private var value: Double = 0

    private var unit: UnitSystem { store.profile?.unitSystem ?? .metric }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date)
                HStack {
                    Text("Weight")
                    Spacer()
                    TextField("Weight", value: $value, format: .number.precision(.fractionLength(0...1)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                    Text(unit == .metric ? "kg" : "lb").foregroundStyle(.secondary)
                }
                if Calendar.current.isDateInToday(date) {
                    Text("Today's weight also updates your profile and recalculates your targets.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Log weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let kg = unit == .metric ? value : UnitConversion.lbToKg(value)
                        store.logWeight(kg, on: date)
                        dismiss()
                    }
                    .disabled(value <= 0)
                }
            }
            .onAppear {
                let kg = store.profile?.weightKg ?? 70
                value = unit == .metric ? kg : UnitConversion.kgToLb(kg).rounded()
            }
        }
        .presentationDetents([.medium])
    }
}
