import SwiftUI

@main
struct FLEXRApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var healthKitService = HealthKitService()

    init() {
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(healthKitService)
                .onAppear {
                    Task {
                        await healthKitService.requestAuthorization()
                    }
                }
        }
    }

    private func configureAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(DesignSystem.Colors.background)

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(DesignSystem.Colors.background)
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(DesignSystem.Colors.text.primary)
        ]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
    }
}
