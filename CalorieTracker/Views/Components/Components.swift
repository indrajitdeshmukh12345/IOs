import SwiftUI

/// A circular progress ring.
struct ProgressRing: View {
    var fraction: Double
    var color: Color
    var lineWidth: CGFloat = 12

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(fraction, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.6), value: fraction)
            if fraction > 1 {
                // Second lap shows the overshoot.
                Circle()
                    .trim(from: 0, to: min(fraction - 1, 1))
                    .stroke(color.opacity(0.55), style: StrokeStyle(lineWidth: lineWidth / 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
        }
    }
}

/// Big calorie ring with remaining calories in the middle.
struct CalorieRingCard: View {
    let progress: NutrientProgress

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                ProgressRing(fraction: progress.fraction, color: .orange, lineWidth: 16)
                VStack(spacing: 2) {
                    Text(progress.consumed > progress.target ? "+\(Int(progress.excess))" : "\(Int(progress.remaining))")
                        .font(.system(.title, design: .rounded).bold())
                        .contentTransition(.numericText())
                    Text(progress.consumed > progress.target ? "kcal over" : "kcal left")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 140, height: 140)

            VStack(alignment: .leading, spacing: 10) {
                statRow(title: "Eaten", value: progress.consumed, symbol: "fork.knife")
                statRow(title: "Target", value: progress.target, symbol: "target")
                HStack(spacing: 6) {
                    StatusBadge(status: progress.status)
                    Text("\(progress.percent)%")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding()
        .cardStyle()
    }

    private func statRow(title: String, value: Double, symbol: String) -> some View {
        HStack {
            Image(systemName: symbol)
                .foregroundStyle(.orange)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 0) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Text("\(Int(value.rounded())) kcal").font(.headline)
            }
        }
    }
}

/// Horizontal bar for one macro.
struct NutrientBar: View {
    let progress: NutrientProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(progress.nutrient.title, systemImage: progress.nutrient.symbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(progress.nutrient.color)
                Spacer()
                Text("\(progress.nutrient.format(progress.consumed, withUnit: false)) / \(progress.nutrient.format(progress.target))")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(progress.nutrient.color.opacity(0.15))
                    Capsule()
                        .fill(progress.nutrient.color.gradient)
                        .frame(width: geo.size.width * min(progress.fraction, 1))
                        .animation(.spring(duration: 0.6), value: progress.fraction)
                }
            }
            .frame(height: 10)
            HStack {
                Text(remainingText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                StatusBadge(status: progress.status)
            }
        }
    }

    private var remainingText: String {
        if progress.remaining > 0 {
            return "\(progress.nutrient.format(progress.remaining)) to go"
        }
        if progress.excess > 0 {
            return "\(progress.nutrient.format(progress.excess)) over"
        }
        return "Target hit"
    }
}

struct StatusBadge: View {
    let status: NutrientStatus

    var body: some View {
        Text(status.label)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.18), in: Capsule())
            .foregroundStyle(color)
    }

    private var color: Color {
        switch status {
        case .low: return .orange
        case .onTrack: return .green
        case .high: return .red
        }
    }
}

/// Small pill showing a nutrient value.
struct MacroPill: View {
    let nutrient: Nutrient
    let value: Double

    var body: some View {
        HStack(spacing: 3) {
            Circle().fill(nutrient.color).frame(width: 6, height: 6)
            Text(shortTitle + " " + nutrient.format(value, withUnit: false) + (nutrient == .calories ? "" : "g"))
        }
        .font(.caption2.monospacedDigit())
        .foregroundStyle(.secondary)
    }

    private var shortTitle: String {
        switch nutrient {
        case .calories: return "kcal"
        case .protein: return "P"
        case .carbs: return "C"
        case .fat: return "F"
        case .fiber: return "Fib"
        }
    }
}

/// Row showing P / C / F for a nutrients value.
struct MacroSummaryRow: View {
    let nutrients: Nutrients
    var includeCalories = false

    var body: some View {
        HStack(spacing: 10) {
            if includeCalories {
                MacroPill(nutrient: .calories, value: nutrients.calories)
            }
            MacroPill(nutrient: .protein, value: nutrients.protein)
            MacroPill(nutrient: .carbs, value: nutrients.carbs)
            MacroPill(nutrient: .fat, value: nutrients.fat)
        }
    }
}

struct FoodEmoji: View {
    let emoji: String
    var size: CGFloat = 40

    var body: some View {
        Text(emoji)
            .font(.system(size: size * 0.55))
            .frame(width: size, height: size)
            .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: size * 0.3))
    }
}

/// A chat-bubble style coach message.
struct CoachMessageView: View {
    let message: CoachMessage

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(message.title)
                    .font(.subheadline.bold())
                Text(message.text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    private var symbol: String {
        switch message.kind {
        case .summary: return "fork.knife.circle.fill"
        case .success: return "checkmark.seal.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .tip: return "lightbulb.fill"
        case .plan: return "list.bullet.clipboard.fill"
        }
    }

    private var color: Color {
        switch message.kind {
        case .summary: return .blue
        case .success: return .green
        case .warning: return .orange
        case .tip: return .purple
        case .plan: return .accentColor
        }
    }
}

struct SuggestionRow: View {
    let suggestion: FoodSuggestion
    var onAdd: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            FoodEmoji(emoji: suggestion.food.emoji)
            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.label)
                    .font(.subheadline.bold())
                Text("\(ServingFormatter.string(suggestion.servings)) × \(suggestion.food.servingName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(suggestion.reason)
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
            }
            Spacer(minLength: 0)
            if let onAdd {
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Add \(suggestion.label) to log")
            }
        }
        .padding(.vertical, 4)
    }
}

struct ScoreBadge: View {
    let score: Int

    var body: some View {
        ZStack {
            ProgressRing(fraction: Double(score) / 100, color: color, lineWidth: 6)
            Text("\(score)")
                .font(.system(.headline, design: .rounded).bold())
        }
        .frame(width: 52, height: 52)
        .accessibilityLabel("Day score \(score) out of 100")
    }

    private var color: Color {
        switch score {
        case 85...: return .green
        case 60..<85: return .yellow
        default: return .orange
        }
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
}

/// Day switcher with previous / next buttons.
struct DaySwitcher: View {
    @Binding var day: Date
    private let calendar = Calendar.current

    var body: some View {
        HStack {
            Button {
                shift(-1)
            } label: {
                Image(systemName: "chevron.left.circle.fill").font(.title2)
            }
            Spacer()
            VStack(spacing: 0) {
                Text(title).font(.headline)
                Text(day, format: .dateTime.weekday(.wide).day().month())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                shift(1)
            } label: {
                Image(systemName: "chevron.right.circle.fill").font(.title2)
            }
            .disabled(calendar.isDateInToday(day))
        }
        .buttonStyle(.borderless)
    }

    private var title: String {
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(.dateTime.day().month(.abbreviated))
    }

    private func shift(_ value: Int) {
        if let newDay = calendar.date(byAdding: .day, value: value, to: day) {
            withAnimation { day = calendar.startOfDay(for: newDay) }
        }
    }
}
