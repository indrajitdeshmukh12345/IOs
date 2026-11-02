import SwiftUI

@main
struct CalorieTrackerApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        Group {
            if store.hasProfile {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: store.hasProfile)
    }
}

enum AppTab: Hashable {
    case today, log, coach, progress, profile
}

/// Shared navigation state so any screen can jump to another tab.
final class AppRouter: ObservableObject {
    @Published var selectedTab: AppTab = .today
    @Published var selectedDay: Date = Calendar.current.startOfDay(for: .now)
}

struct MainTabView: View {
    @StateObject private var router = AppRouter()

    var body: some View {
        TabView(selection: $router.selectedTab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "chart.pie.fill") }
                .tag(AppTab.today)

            LogFoodView()
                .tabItem { Label("Log Food", systemImage: "plus.circle.fill") }
                .tag(AppTab.log)

            CoachView()
                .tabItem { Label("Coach", systemImage: "bubble.left.and.text.bubble.right.fill") }
                .tag(AppTab.coach)

            ProgressTabView()
                .tabItem { Label("Progress", systemImage: "chart.xyaxis.line") }
                .tag(AppTab.progress)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(AppTab.profile)
        }
        .environmentObject(router)
    }
}
