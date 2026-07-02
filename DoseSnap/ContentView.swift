import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        Group {
            if appState.profile.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView(profile: appState.profile)
            }
        }
        .environmentObject(appState)
        .preferredColorScheme(.light)
    }
}

private struct MainTabView: View {
    init() {
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        tabAppearance.backgroundColor = UIColor(AppTheme.warmSurface.opacity(0.85))
        tabAppearance.shadowColor = UIColor(AppTheme.ink.opacity(0.08))
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        let navigationAppearance = UINavigationBarAppearance()
        navigationAppearance.configureWithDefaultBackground()
        navigationAppearance.backgroundColor = UIColor(AppTheme.cream.opacity(0.85))
        navigationAppearance.shadowColor = .clear
        navigationAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(AppTheme.ink),
            .font: UIFont.systemFont(ofSize: 17, weight: .bold)
        ]
        UINavigationBar.appearance().standardAppearance = navigationAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationAppearance
        UINavigationBar.appearance().compactAppearance = navigationAppearance
    }

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Accueil", systemImage: "house")
            }

            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label("Historique", systemImage: "clock.arrow.circlepath")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Reglages", systemImage: "gearshape")
            }
        }
        .tint(AppTheme.accent)
    }
}

#Preview {
    ContentView()
}
