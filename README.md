# MassTrack: calorie & macro tracker for iOS

MassTrack is a native SwiftUI iPhone app that tracks your calories, protein, carbs, fat and fiber. It works out the intake you need to gain mass and tells you what to eat to close the gaps.

> **Example:** log **4 × Whole egg** as your whole day, and the coach replies:
>
> *"You had 4 × Whole egg. That's 288 kcal, 25 g protein, 2 g carbs, 19 g fat and 0 g fiber."*
> *"Protein: 25 g of 130 g (19%). You need 105 g more protein to support muscle growth. Whole egg supplied 100% of it."*
> *"Calories: 288 of 2,970 kcal (10%). You're 2,682 kcal short. Without a calorie surplus your body can't build new mass."*
> *"**You should add** 3 × Chicken breast, 3 × Brown rice, 2 × Chole, 3 × Banana and 1 × Walnuts. That brings you to about 2,491 kcal and 165 g protein."*

## Features

| Area | What it does |
| --- | --- |
| **Onboarding & profile** | Name, age, sex, height, weight, target weight, activity level, goal and diet (non-veg, eggetarian, vegetarian or vegan). Metric or imperial units. |
| **Recommended intake** | BMR from Mifflin-St Jeor, multiplied by your activity level to get maintenance (TDEE), plus a surplus for your goal: lean bulk +250, mass gain +450, aggressive +700 kcal. Protein is 1.6–2.2 g/kg, fat is at least 25% of calories (and at least 0.8 g/kg), carbs fill the rest, and fiber is 14 g per 1000 kcal. Also shows water intake, expected weekly gain and weeks to your target weight. Every number comes with a plain-language explanation. |
| **Custom targets** | Override any target by hand, or switch back to the recommended ones. |
| **Food logging** | 84 built-in foods, including Indian meals (dal, roti, paneer, biryani, idli, dosa…), plus your own custom foods. Search, category filters, favorites and recents. Enter amounts in servings or grams, and pick breakfast, lunch, snack or dinner. |
| **Today dashboard** | A calorie ring, progress bars for protein, carbs, fat and fiber, meals grouped by type, edit or delete entries, "repeat previous day", and a logging streak. |
| **Coach** | Right after you log a food, the coach says what you had, which nutrients are low or over, where your protein came from, and tips on variety, meal timing, fat and fiber. It then gives a concrete **"you should add…"** plan and you can add each item with one tap. The plan follows your diet preference. |
| **Quick check** | Try out a day's food (e.g. "4 eggs") without logging it, and see the analysis and suggestions. |
| **Progress** | 7/14/30-day charts for any nutrient with your target line, daily averages, days on target, and a weight log with a trend chart. |
| **Storage** | Everything is saved on the device as JSON. No account or network is needed. |

## Requirements

- Xcode 16 or later. The project uses file-system-synchronized groups, so any new file you add under `CalorieTracker/` is picked up automatically.
- iOS 17.0 or later, on iPhone or iPad.

## Running the app

1. Open `CalorieTracker.xcodeproj` in Xcode.
2. Select the **CalorieTracker** scheme and an iPhone simulator.
3. Press **⌘R**.

To run on a real device, set your team under *Signing & Capabilities* and change the bundle identifier (`com.example.CalorieTracker`) to one you own.

Run the tests with **⌘U**, or from the command line:

```bash
xcodebuild test -project CalorieTracker.xcodeproj -scheme CalorieTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

GitHub Actions (`.github/workflows/ios.yml`) builds the app and runs the tests on every push.

## Project structure

```
CalorieTracker/
├── App/            CalorieTrackerApp (entry point), RootView, MainTabView, AppRouter
├── Models/         Nutrients, UserProfile (+ enums & unit conversion), FoodItem, MealEntry
├── Services/
│   ├── NutritionCalculator.swift   BMR / TDEE / macro targets
│   ├── NutritionCoach.swift        analysis, feedback messages, gap-filling food suggestions
│   ├── FoodDatabase.swift          built-in food library + search
│   ├── AppStore.swift              observable app state (profile, log, custom foods, weights)
│   └── Persistence.swift           JSON storage in Documents
├── Views/
│   ├── Onboarding/   multi-step profile setup + recommended plan
│   ├── Today/        dashboard, meal sections, entry editor
│   ├── LogFood/      food browser, food detail, custom food editor, coach feedback sheet
│   ├── Coach/        day analysis + "Quick check"
│   ├── History/      charts, averages, weight log
│   ├── Profile/      profile & target editors
│   └── Components/   rings, bars, badges, cards
└── Assets.xcassets
CalorieTrackerTests/  unit tests for the calculator, coach, food database and store
```

### How the suggestions are chosen

`NutritionCoach.suggestFoods` fills the gaps greedily:

1. Work out how much of each target is still missing.
2. Score every food your diet allows at 1 to N servings. A food scores higher the more it fills the biggest gaps (protein is weighted most), and loses points for overshooting any target.
3. Take the best-scoring food, subtract what it adds, and repeat up to 5 times. Picking from the same food category again costs points, so the plan stays varied: a protein, a carb, a legume, a fruit…

## Disclaimer

Nutrition values are approximate averages and the targets are general guidance. They are not medical advice.
