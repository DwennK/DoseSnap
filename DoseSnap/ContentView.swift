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
        .overlay(alignment: .bottom) {
            if let toast = appState.toast {
                ToastBanner(toast: toast)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 92)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: appState.toast)
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
                Label("Réglages", systemImage: "gearshape")
            }
        }
        .tint(AppTheme.accent)
    }
}

private struct ToastBanner: View {
    var toast: AppToast

    var body: some View {
        Label(toast.message, systemImage: toast.systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(AppTheme.deepNavy.opacity(0.94), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
            .shadow(color: AppTheme.deepNavy.opacity(0.26), radius: 16, x: 0, y: 8)
            .accessibilityAddTraits(.isStaticText)
    }
}

#Preview {
    ContentView()
}
