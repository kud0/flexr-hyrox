import SwiftUI

@main
struct FLEXRApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var healthKitService = HealthKitService()
    @ObservedObject private var watchConnectivity = WatchConnectivityService.shared
    @ObservedObject private var authService = AppleSignInService.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("onboardedUserId") private var onboardedUserId: String = ""
    @State private var isGeneratingPlan = false
    @State private var pendingUser: User?
    @State private var isCheckingExistingPlan = false
    @State private var hasCheckedForExistingPlan = false

    init() {
        configureAppearance()
        initializeCoreData()
    }

    private func initializeCoreData() {
        // Initialize Core Data stack
        _ = CoreDataManager.shared.persistentContainer
        print("✅ Core Data initialized at app launch")
    }

    /// Check if current user has completed onboarding (handles user switching)
    private var currentUserCompletedOnboarding: Bool {
        guard let userId = authService.currentUserId else { return false }
        return hasCompletedOnboarding && onboardedUserId == userId.uuidString
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isCheckingSession {
                    // Still checking for existing session - show splash/loading
                    ZStack {
                        DesignSystem.Colors.background.ignoresSafeArea()
                        VStack(spacing: 16) {
                            Image(systemName: "figure.run")
                                .font(.system(size: 60))
                                .foregroundStyle(DesignSystem.Colors.primary)
                            ProgressView()
                                .tint(DesignSystem.Colors.primary)
                        }
                    }
                } else if !authService.isSignedIn {
                    // Not signed in - show Apple Sign In
                    AppleSignInButton {
                        try? await authService.signIn()
                    }
                    .environmentObject(appState)
                        .onReceive(authService.$isSignedIn) { isSignedIn in
                            if isSignedIn {
                                // User just signed in - send userId to Watch
                                if let userId = authService.currentUserId {
                                    watchConnectivity.sendUserIdToWatch(userId)
                                    print("FLEXRApp: Sent userId to Watch after sign in")
                                }
                            }
                        }
                } else if isCheckingExistingPlan {
                    // Checking if user already has a plan in Supabase
                    PlanGeneratingView()
                        .task {
                            await checkForExistingPlan()
                        }
                } else if currentUserCompletedOnboarding {
                    ContentView()
                        .environmentObject(appState)
                        .environmentObject(healthKitService)
                        .onAppear {
                            // Send userId to Watch for returning users
                            if let userId = appState.currentUser?.id {
                                watchConnectivity.sendUserIdToWatch(userId)
                                print("FLEXRApp: Sent userId to Watch on app launch")
                            }

                            // Sync workouts from HealthKit to Analytics
                            print("🚀 FLEXRApp: Starting HealthKit workout sync on app launch...")
                            Task {
                                await healthKitService.syncWorkoutsToAnalytics()
                                print("🚀 FLEXRApp: HealthKit sync completed")

                                // First load training cycle data (needed for next week check)
                                await PlanService.shared.fetchFullTrainingCycle()
                                print("🗓️ FLEXRApp: Training cycle loaded, available weeks: \(PlanService.shared.availableDetailedWeeks)")

                                // Check if we need to generate next week's plan (Sunday evening)
                                let generated = await PlanService.shared.checkAndGenerateNextWeekIfNeeded()
                                if generated {
                                    print("🗓️ FLEXRApp: Generated next week's training plan")
                                } else {
                                    print("🗓️ FLEXRApp: No new week generated (not Sunday evening or already generated)")
                                }
                            }
                        }
                } else if isGeneratingPlan {
                    // Show loading screen while generating plan
                    PlanGeneratingView()
                        .task {
                            guard let user = pendingUser else {
                                hasCompletedOnboarding = true
                                return
                            }

                            do {
                                print("FLEXRApp: Generating initial plan for user \(user.id)")
                                try await PlanService.shared.generateInitialPlan(for: user)
                                print("FLEXRApp: Plan generation complete")

                                // Send userId to Watch for independent workout fetching
                                watchConnectivity.sendUserIdToWatch(user.id)
                                print("FLEXRApp: Sent userId to Watch")
                            } catch {
                                print("FLEXRApp: Failed to generate plan: \(error)")
                            }

                            // Transition to main app
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                hasCompletedOnboarding = true
                            }
                        }
                } else {
                    OnboardingCoordinator(onComplete: { user in
                        print("FLEXRApp: onComplete called with user \(user.id)")
                        // Save user data
                        appState.currentUser = user
                        pendingUser = user

                        // Save the userId that completed onboarding
                        onboardedUserId = user.id.uuidString

                        // Mark onboarding as complete
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            hasCompletedOnboarding = true
                        }
                    })
                    .environmentObject(appState)
                    .environmentObject(healthKitService)
                    .onAppear {
                        // Check if this user already has a plan (switching devices)
                        // Only check once to avoid infinite loops
                        if let userId = authService.currentUserId, !currentUserCompletedOnboarding, !hasCheckedForExistingPlan {
                            print("FLEXRApp: New device detected, checking for existing plan...")
                            hasCheckedForExistingPlan = true
                            isCheckingExistingPlan = true
                        }
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    /// Check if user already has a training plan in Supabase (for device switching)
    private func checkForExistingPlan() async {
        guard let userId = authService.currentUserId else {
            isCheckingExistingPlan = false
            return
        }

        print("FLEXRApp: Checking for existing plan for user \(userId)")

        do {
            let hasExistingPlan = try await PlanService.shared.userHasExistingPlan(userId: userId)

            if hasExistingPlan {
                print("FLEXRApp: User has existing plan - skipping onboarding")
                // Mark onboarding as complete for this user
                onboardedUserId = userId.uuidString
                hasCompletedOnboarding = true

                // Send userId to Watch
                watchConnectivity.sendUserIdToWatch(userId)
            } else {
                print("FLEXRApp: No existing plan - showing onboarding")
            }
        } catch {
            print("FLEXRApp: Error checking for existing plan: \(error)")
        }

        withAnimation {
            isCheckingExistingPlan = false
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
