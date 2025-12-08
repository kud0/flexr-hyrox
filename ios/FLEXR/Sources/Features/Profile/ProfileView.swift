// FLEXR - Professional Profile Page
// Comprehensive user profile with stats, performance, and settings

import SwiftUI

struct EnhancedProfileView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var planService = PlanService.shared
    @StateObject private var statsService = UserStatsService.shared
    @StateObject private var healthKitService = HealthKitService()
    @StateObject private var watchConnectivity = WatchConnectivityService.shared

    @State private var showResetConfirmation = false
    @State private var showRegeneratePlan = false
    @State private var showNewPlanConfirmation = false
    @State private var showOnboarding = false
    @State private var healthKitAuthorized = false
    @State private var notificationsEnabled = true
    @State private var unitPreference: UnitPreference = .metric
    @State private var paceDisplay: PaceDisplay = .minPerKm
    @State private var showFeedback = false
    @State private var showPulsePrompt = false
    @StateObject private var feedbackService = UserFeedbackService.shared

    var body: some View {
        NavigationStack {
            if let user = appState.currentUser {
                List {
                    // MARK: - Profile Header
                    profileHeader(user: user)

                    // MARK: - Quick Stats
                    quickStats

                    // MARK: - Race Countdown
                    if let raceDate = user.raceDate {
                        raceCountdown(raceDate: raceDate, user: user)
                    }

                    // MARK: - Performance Overview
                    performanceOverview

                    // MARK: - Training Setup
                    trainingSetup(user: user)

                    // MARK: - Equipment & Gear
                    equipmentSection(user: user)

                    // MARK: - Settings & Preferences
                    settingsSection

                    // MARK: - Connections
                    connectionsSection

                    // MARK: - Developer Tools
                    #if DEBUG
                    developerTools
                    #endif

                    // MARK: - About
                    aboutSection

                    // MARK: - Account
                    accountSection
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color.black)
                .navigationTitle("Profile")
                .navigationBarTitleDisplayMode(.large)
                .toolbarBackground(Color.black, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .alert("Reset All Data?", isPresented: $showResetConfirmation) {
                    Button("Cancel", role: .cancel) {}
                    Button("Reset", role: .destructive) {
                        resetAllData()
                    }
                } message: {
                    Text("This will clear your training plan and all workout data. This action cannot be undone.")
                }
                .alert("Create New Training Plan?", isPresented: $showNewPlanConfirmation) {
                    Button("Cancel", role: .cancel) {}
                    Button("Continue", role: .destructive) {
                        createNewPlan()
                    }
                } message: {
                    Text("This will replace your current training plan. Your progress will be lost. You'll go through the setup process again to create a new personalized plan.")
                }
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingCoordinator()
                        .environmentObject(appState)
                }
                .sheet(isPresented: $showFeedback) {
                    FeedbackView()
                }
                .overlay {
                    // Quick Pulse Prompt Overlay
                    if showPulsePrompt {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                            .onTapGesture {
                                feedbackService.dismissPulsePrompt()
                                showPulsePrompt = false
                            }

                        QuickPulsePrompt(isPresented: $showPulsePrompt)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            } else {
                notSignedInView
            }
        }
        .onAppear {
            checkHealthKitAuthorization()
            loadUserSettings()
            loadUserStats()
            checkPulsePrompt()
        }
        .onChange(of: feedbackService.showPulsePrompt) { _, shouldShow in
            if shouldShow {
                withAnimation(.spring(response: 0.4)) {
                    showPulsePrompt = true
                }
            }
        }
    }

    private func checkPulsePrompt() {
        Task {
            await feedbackService.checkShouldShowPulsePrompt()
        }
    }

    // MARK: - Profile Header

    @ViewBuilder
    private func profileHeader(user: User) -> some View {
        Section {
            VStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [DesignSystem.Colors.primary, DesignSystem.Colors.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)

                    Text(user.initials)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }

                // Name & Email
                VStack(spacing: 4) {
                    Text(user.displayName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.text.primary)

                    Text(user.email)
                        .font(.system(size: 15))
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }

                // Badges
                HStack(spacing: 12) {
                    // Experience Badge
                    Badge(
                        icon: experienceIcon(user.experienceLevel),
                        text: user.experienceLevel.displayName,
                        color: experienceColor(user.experienceLevel)
                    )

                    // Member Since Badge
                    Badge(
                        icon: "calendar",
                        text: "Since \(memberSinceText(user.createdAt))",
                        color: .gray
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))
    }

    // MARK: - Quick Stats

    @ViewBuilder
    private var quickStats: some View {
        Section {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    StatCard(
                        icon: "figure.run",
                        value: "\(totalWorkouts)",
                        label: "Workouts",
                        color: DesignSystem.Colors.primary
                    )
                }

                HStack(spacing: 12) {
                    StatCard(
                        icon: "clock.fill",
                        value: totalTrainingTime,
                        label: "Total Time",
                        color: .green
                    )

                    StatCard(
                        icon: "calendar.badge.clock",
                        value: "\(thisWeekSessions)",
                        label: "This Week",
                        color: .purple
                    )
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Quick Stats")
        }
        .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))
    }

    // MARK: - Race Countdown

    @ViewBuilder
    private func raceCountdown(raceDate: Date, user: User) -> some View {
        Section {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "flag.checkered.2.crossed")
                        .font(.system(size: 32))
                        .foregroundColor(.red)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Race Day Countdown")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.text.primary)

                        Text(raceDate, style: .date)
                            .font(.system(size: 15))
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                    }

                    Spacer()
                }

                // Countdown
                if let days = user.daysUntilRace {
                    HStack(spacing: 24) {
                        CountdownBlock(value: "\(days)", label: "Days")
                        CountdownBlock(value: "\(days % 7)", label: "Days in Week")
                        CountdownBlock(value: "\(days / 7)", label: "Weeks")
                    }
                    .frame(maxWidth: .infinity)

                    // Progress bar
                    if days <= 90 {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Training Progress")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(DesignSystem.Colors.text.tertiary)

                                Spacer()

                                Text("\(Int((1.0 - Double(days) / 90.0) * 100))%")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(DesignSystem.Colors.primary)
                            }

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.2))

                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            LinearGradient(
                                                colors: [DesignSystem.Colors.primary, DesignSystem.Colors.accent],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * (1.0 - Double(days) / 90.0))
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Race Preparation")
        }
        .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))
    }

    // MARK: - Performance Overview

    @ViewBuilder
    private var performanceOverview: some View {
        Section {
            // Personal Bests
            NavigationLink {
                PersonalBestsView()
            } label: {
                HStack {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.yellow)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Personal Bests")
                            .font(.system(size: 17))
                        Text("View your best times")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Recent Improvements
            NavigationLink {
                ImprovementsView()
            } label: {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recent Improvements")
                            .font(.system(size: 17))
                        Text("Track your progress")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            Text("Performance")
        }
        .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))
    }

    // MARK: - Training Setup

    @ViewBuilder
    private func trainingSetup(user: User) -> some View {
        Section {
            // Training Preferences - Edit all training settings in one place
            NavigationLink {
                TrainingPreferencesView(user: user)
                    .environmentObject(appState)
            } label: {
                SettingsRow(
                    icon: "slider.horizontal.3",
                    iconColor: .purple,
                    title: "Training Preferences",
                    value: nil
                )
            }

            // Create New Plan Button
            Button {
                showNewPlanConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(DesignSystem.Colors.primary)
                        .frame(width: 28, height: 28)

                    Text("Create New Plan")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.primary)

                    Spacer()
                }
                .frame(minHeight: 44)
            }
        } header: {
            Text("Training Setup")
        } footer: {
            Text("Modify your training preferences to regenerate your plan, or start fresh with a new plan")
        }
        .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))
    }

    // MARK: - Equipment Section

    @ViewBuilder
    private func equipmentSection(user: User) -> some View {
        Section {
            NavigationLink {
                EquipmentListView(equipment: user.equipment ?? [])
            } label: {
                HStack {
                    SettingsRow(
                        icon: "dumbbell.fill",
                        iconColor: .purple,
                        title: "Available Equipment",
                        value: nil
                    )

                    Text("\(user.equipment?.count ?? 0) items")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Equipment & Gear")
        }
        .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))
    }

    // MARK: - Settings Section

    @ViewBuilder
    private var settingsSection: some View {
        Section {
            // Unit Preference
            Picker("Units", selection: $unitPreference) {
                Text("Metric").tag(UnitPreference.metric)
                Text("Imperial").tag(UnitPreference.imperial)
            }
            .pickerStyle(.menu)
            .onChange(of: unitPreference) { _, newValue in
                saveUserSettings()
            }

            // Pace Display
            Picker("Pace Display", selection: $paceDisplay) {
                Text("min/km").tag(PaceDisplay.minPerKm)
                Text("min/mile").tag(PaceDisplay.minPerMile)
            }
            .pickerStyle(.menu)
            .onChange(of: paceDisplay) { _, newValue in
                saveUserSettings()
            }

            // Notifications
            Toggle(isOn: $notificationsEnabled) {
                SettingsRow(
                    icon: "bell.fill",
                    iconColor: .orange,
                    title: "Notifications",
                    value: nil
                )
            }
            .tint(DesignSystem.Colors.primary)
            .onChange(of: notificationsEnabled) { _, newValue in
                saveUserSettings()
            }
        } header: {
            Text("Preferences")
        }
        .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))
    }

    // MARK: - Connections Section

    @ViewBuilder
    private var connectionsSection: some View {
        Section {
            HStack {
                SettingsRow(
                    icon: "applewatch",
                    iconColor: .pink,
                    title: "Apple Watch",
                    value: nil
                )
                Spacer()
                if watchConnectivity.isPaired {
                    if watchConnectivity.isWatchAppInstalled {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 14))
                            Text(watchConnectivity.isReachable ? "Connected" : "Paired")
                                .font(.system(size: 15))
                                .foregroundColor(watchConnectivity.isReachable ? .green : .secondary)
                        }
                    } else {
                        Text("App Not Installed")
                            .font(.system(size: 15))
                            .foregroundColor(.orange)
                    }
                } else {
                    Text("Not Paired")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
            }

            Toggle(isOn: $healthKitAuthorized) {
                SettingsRow(
                    icon: "heart.fill",
                    iconColor: .red,
                    title: "Health",
                    value: healthKitAuthorized ? "Connected" : nil
                )
            }
            .tint(.green)
            .onChange(of: healthKitAuthorized) { oldValue, newValue in
                print("🔐 ProfileView: HealthKit toggle changed from \(oldValue) to \(newValue)")
                if newValue && !oldValue {
                    // User toggled ON - request authorization
                    Task {
                        print("📱 ProfileView: Requesting HealthKit authorization...")
                        await healthKitService.requestAuthorization()
                        // Recheck status after request
                        await MainActor.run {
                            checkHealthKitAuthorization()
                        }
                    }
                }
            }
            .disabled(healthKitAuthorized) // Disable if already authorized
        } header: {
            Text("Connections")
        }
        .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))
    }

    // MARK: - Developer Tools

    @ViewBuilder
    private var developerTools: some View {
        Section {
            Button {
                resetOnboardingOnly()
            } label: {
                SettingsRow(
                    icon: "arrow.counterclockwise",
                    iconColor: .blue,
                    title: "Test Onboarding",
                    value: nil
                )
            }

            Button {
                showResetConfirmation = true
            } label: {
                SettingsRow(
                    icon: "trash.fill",
                    iconColor: .red,
                    title: "Reset All Data",
                    value: nil
                )
            }

            Button {
                Task {
                    try? await appState.generateInitialPlan()
                }
            } label: {
                SettingsRow(
                    icon: "sparkles",
                    iconColor: .yellow,
                    title: "Generate Test Plan",
                    value: nil
                )
            }
        } header: {
            Text("Developer Tools")
        } footer: {
            Text("These options are only visible in debug builds.")
        }
        .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))
    }

    // MARK: - About Section

    @ViewBuilder
    private var aboutSection: some View {
        Section {
            // Feedback Button - Direct line to hear from users
            Button {
                showFeedback = true
            } label: {
                SettingsRow(
                    icon: "bubble.left.and.bubble.right.fill",
                    iconColor: DesignSystem.Colors.primary,
                    title: "Send Feedback",
                    value: nil
                )
            }

            NavigationLink {
                AppVersionView()
            } label: {
                SettingsRow(
                    icon: "info.circle.fill",
                    iconColor: .blue,
                    title: "App Version",
                    value: "1.0.0"
                )
            }

            NavigationLink {
                HelpSupportView()
            } label: {
                SettingsRow(
                    icon: "questionmark.circle.fill",
                    iconColor: .green,
                    title: "Help & Support",
                    value: nil
                )
            }

            NavigationLink {
                TermsOfServiceView()
            } label: {
                SettingsRow(
                    icon: "doc.text.fill",
                    iconColor: .gray,
                    title: "Terms of Service",
                    value: nil
                )
            }

            NavigationLink {
                PrivacyPolicyView()
            } label: {
                SettingsRow(
                    icon: "hand.raised.fill",
                    iconColor: .gray,
                    title: "Privacy Policy",
                    value: nil
                )
            }
        } header: {
            Text("About")
        }
        .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))
    }

    // MARK: - Account Section

    @ViewBuilder
    private var accountSection: some View {
        Section {
            Button {
                appState.signOut()
            } label: {
                HStack {
                    Spacer()
                    Text("Sign Out")
                        .font(.system(size: 17))
                        .foregroundColor(.red)
                    Spacer()
                }
            }
        }
        .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))
    }

    // MARK: - Not Signed In View

    @ViewBuilder
    private var notSignedInView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.circle")
                .font(.system(size: 100))
                .foregroundColor(.gray)

            VStack(spacing: 8) {
                Text("Not Signed In")
                    .font(.system(size: 28, weight: .bold))

                Text("Sign in to access your training plan\nand track your progress")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            #if DEBUG
            Button {
                Task {
                    try? await appState.signIn(email: "demo@flexr.app", password: "demo")
                }
            } label: {
                Text("Sign In (Demo)")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.green)
                    .cornerRadius(12)
                    .padding(.horizontal, 32)
            }
            #endif

            Spacer()
        }
        .background(Color.black)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Helper Functions

    private func checkHealthKitAuthorization() {
        // Check current authorization status (this also updates healthKitService.isAuthorized)
        let authorized = healthKitService.checkAuthorizationStatus()
        healthKitAuthorized = authorized
        print("🔐 ProfileView: HealthKit authorization = \(authorized)")
    }

    private func loadUserSettings() {
        // Load user settings from UserDefaults or AppState
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notifications_enabled")
        if let unitString = UserDefaults.standard.string(forKey: "unit_preference"),
           let unit = UnitPreference(rawValue: unitString) {
            unitPreference = unit
        }
        if let paceString = UserDefaults.standard.string(forKey: "pace_display"),
           let pace = PaceDisplay(rawValue: paceString) {
            paceDisplay = pace
        }
    }

    private func saveUserSettings() {
        UserDefaults.standard.set(notificationsEnabled, forKey: "notifications_enabled")
        UserDefaults.standard.set(unitPreference.rawValue, forKey: "unit_preference")
        UserDefaults.standard.set(paceDisplay.rawValue, forKey: "pace_display")
    }

    private func createNewPlan() {
        let userId = appState.currentUser?.id

        Task {
            if let userId = userId {
                await deleteUserPlanFromSupabase(userId: userId)
            }

            await MainActor.run {
                planService.weeklyPlan = nil
                planService.todaysWorkouts = []
                planService.allWeeks = []
                planService.currentPlan = nil

                showOnboarding = true
            }

            print("✅ Old plan cleared - showing onboarding")
        }
    }

    private func deleteUserPlanFromSupabase(userId: UUID) async {
        let supabase = SupabaseService.shared.client

        print("🗑️ Deleting current plan for user: \(userId.uuidString)")

        do {
            try await supabase
                .database.from("planned_workouts")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .execute()

            try await supabase
                .database.from("training_weeks")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .execute()

            try await supabase
                .database.from("training_plans")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .execute()

            print("✅ Successfully deleted current training plan")
        } catch {
            print("❌ Error deleting plan: \(error)")
        }
    }

    private func resetOnboardingOnly() {
        UserDefaults.standard.removeObject(forKey: "onboarding.completed")
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        UserDefaults.standard.synchronize()

        print("Onboarding reset - app will restart")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            exit(0)
        }
    }

    private func resetAllData() {
        let userId = appState.currentUser?.id

        Task {
            if let userId = userId {
                await deleteUserDataFromSupabase(userId: userId)
            }

            await MainActor.run {
                UserDefaults.standard.removeObject(forKey: "onboarding.completed")
                UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
                UserDefaults.standard.synchronize()

                let planService = PlanService.shared
                planService.weeklyPlan = nil
                planService.todaysWorkouts = []
                planService.allWeeks = []
                planService.currentPlan = nil

                appState.signOut()
            }

            try? await appState.signIn(email: "demo@flexr.app", password: "demo")

            print("Reset complete - all data deleted and signed back in")
        }
    }

    private func deleteUserDataFromSupabase(userId: UUID) async {
        let supabase = SupabaseService.shared.client

        print("🗑️ Deleting all data for user: \(userId.uuidString)")

        do {
            try await supabase
                .database.from("planned_workouts")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .execute()

            try await supabase
                .database.from("training_weeks")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .execute()

            try await supabase
                .database.from("training_plans")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .execute()

            print("🎉 Successfully deleted all user training data from Supabase")
        } catch {
            print("❌ Error deleting user data: \(error)")
        }
    }

    // MARK: - Computed Properties

    private var totalWorkouts: Int {
        statsService.totalWorkouts
    }

    private var totalTrainingTime: String {
        let hours = statsService.totalTrainingMinutes / 60
        let remainingMinutes = statsService.totalTrainingMinutes % 60
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(remainingMinutes)m"
        }
    }

    private var thisWeekSessions: Int {
        statsService.thisWeekSessions
    }

    private func loadUserStats() {
        guard let userId = appState.currentUser?.id else { return }

        Task {
            await statsService.fetchUserStats(userId: userId)
        }
    }

    private func memberSinceText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }

    private func experienceIcon(_ level: ExperienceLevel) -> String {
        switch level {
        case .beginner: return "star.fill"
        case .intermediate: return "star.fill"
        case .advanced: return "star.fill"
        case .elite: return "crown.fill"
        }
    }

    private func experienceColor(_ level: ExperienceLevel) -> Color {
        switch level {
        case .beginner: return .green
        case .intermediate: return .blue
        case .advanced: return .purple
        case .elite: return .yellow
        }
    }
}

// MARK: - User Extensions

extension User {
    var displayName: String {
        name ?? "FLEXR Athlete"
    }

    var initials: String {
        if let name = name {
            let components = name.components(separatedBy: " ")
            let initials = components.compactMap { $0.first }.prefix(2)
            return String(initials).uppercased()
        }
        return "FA"
    }
}

// MARK: - Supporting Components

struct Badge: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(text)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .cornerRadius(8)
    }
}

// StatCard moved to MetricCard.swift to avoid duplication

struct CountdownBlock: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(DesignSystem.Colors.primary)

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .textCase(.uppercase)
        }
    }
}

// MARK: - Settings Row Component
struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 28, height: 28)

            Text(title)
                .font(.system(size: 17))

            Spacer()

            if let value = value {
                Text(value)
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
            }
        }
        .frame(minHeight: 44)
    }
}

// MARK: - Placeholder Detail Views

struct PersonalBestsView: View {
    var body: some View {
        Text("Personal Bests - Coming Soon")
    }
}

struct ImprovementsView: View {
    var body: some View {
        Text("Improvements - Coming Soon")
    }
}

struct TrainingGoalDetailView: View {
    let goal: TrainingGoal
    var body: some View {
        Text("Training Goal Detail - Coming Soon")
    }
}

struct ExperienceLevelDetailView: View {
    let level: ExperienceLevel
    var body: some View {
        Text("Experience Level Detail - Coming Soon")
    }
}

struct TrainingScheduleView: View {
    let preferences: UserTrainingPreferences
    var body: some View {
        Text("Training Schedule - Coming Soon")
    }
}

struct RaceDateDetailView: View {
    let raceDate: Date
    var body: some View {
        Text("Race Date Detail - Coming Soon")
    }
}

struct EquipmentListView: View {
    let equipment: [String]
    var body: some View {
        List(equipment, id: \.self) { item in
            Text(item)
        }
        .navigationTitle("Equipment")
    }
}

struct AppVersionView: View {
    var body: some View {
        Text("App Version - Coming Soon")
    }
}

struct HelpSupportView: View {
    var body: some View {
        Text("Help & Support - Coming Soon")
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        Text("Terms of Service - Coming Soon")
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        Text("Privacy Policy - Coming Soon")
    }
}

#Preview {
    EnhancedProfileView()
        .environmentObject(AppState())
        .environmentObject(HealthKitService())
}
