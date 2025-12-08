import SwiftUI

// MARK: - Training Preferences View
// Allows users to modify their training variables and regenerate their plan

struct TrainingPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var planService = PlanService.shared

    // Editable preferences
    @State private var trainingGoal: TrainingGoal
    @State private var raceDate: Date?
    @State private var experienceLevel: ExperienceLevel
    @State private var daysPerWeek: Int
    @State private var sessionsPerDay: Int
    @State private var preferredTypes: [WorkoutType]
    @State private var preferredRecoveryDay: DayOfWeek
    @State private var programStartDate: Date?

    // UI State
    @State private var showRaceDatePicker = false
    @State private var isRegenerating = false
    @State private var showSuccessMessage = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    init(user: User) {
        // Initialize state with current user values
        _trainingGoal = State(initialValue: user.trainingGoal)
        _raceDate = State(initialValue: user.raceDate)
        _experienceLevel = State(initialValue: user.experienceLevel)
        _daysPerWeek = State(initialValue: user.trainingPreferences.daysPerWeek)
        _sessionsPerDay = State(initialValue: user.trainingPreferences.sessionsPerDay)
        _preferredTypes = State(initialValue: user.trainingPreferences.preferredTypes)
        _preferredRecoveryDay = State(initialValue: user.preferredRecoveryDay ?? .sunday)
        _programStartDate = State(initialValue: user.programStartDate ?? Date())
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                    // Header
                    headerView

                    // Training Goal Section
                    PreferenceSection(title: "TRAINING GOAL") {
                        VStack(spacing: DesignSystem.Spacing.small) {
                            ForEach(TrainingGoal.allCases, id: \.self) { goal in
                                PreferenceCard(
                                    title: goal.displayName,
                                    description: goal.description,
                                    isSelected: trainingGoal == goal
                                ) {
                                    withAnimation(DesignSystem.Animation.fast) {
                                        trainingGoal = goal
                                        if goal == .trainStyle {
                                            raceDate = nil
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Race Date Section (if competing)
                    if trainingGoal == .competeRace {
                        PreferenceSection(title: "RACE DATE") {
                            Button {
                                showRaceDatePicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(DesignSystem.Colors.primary)

                                    if let raceDate = raceDate {
                                        Text(raceDate.formatted(date: .long, time: .omitted))
                                            .foregroundColor(DesignSystem.Colors.text.primary)
                                    } else {
                                        Text("Select race date")
                                            .foregroundColor(DesignSystem.Colors.text.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(DesignSystem.Colors.text.secondary)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .padding(DesignSystem.Spacing.medium)
                                .background(DesignSystem.Colors.surface)
                                .cornerRadius(DesignSystem.Radius.medium)
                            }
                        }
                    }

                    // Experience Level Section
                    PreferenceSection(title: "EXPERIENCE LEVEL") {
                        VStack(spacing: DesignSystem.Spacing.small) {
                            ForEach(ExperienceLevel.allCases, id: \.self) { level in
                                PreferenceCard(
                                    title: level.displayName,
                                    description: level.description,
                                    isSelected: experienceLevel == level
                                ) {
                                    withAnimation(DesignSystem.Animation.fast) {
                                        experienceLevel = level
                                    }
                                }
                            }
                        }
                    }

                    // Training Frequency Section
                    PreferenceSection(title: "TRAINING FREQUENCY") {
                        VStack(spacing: DesignSystem.Spacing.medium) {
                            // Days per week
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                                Text("Days per week")
                                    .font(DesignSystem.Typography.bodyEmphasized)
                                    .foregroundColor(DesignSystem.Colors.text.primary)

                                HStack(spacing: DesignSystem.Spacing.small) {
                                    ForEach(3...6, id: \.self) { days in
                                        Button {
                                            withAnimation(DesignSystem.Animation.fast) {
                                                daysPerWeek = days
                                            }
                                        } label: {
                                            Text("\(days)")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(
                                                    daysPerWeek == days
                                                        ? DesignSystem.Colors.text.primary
                                                        : DesignSystem.Colors.text.secondary
                                                )
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(
                                                    daysPerWeek == days
                                                        ? DesignSystem.Colors.primary
                                                        : DesignSystem.Colors.backgroundSecondary
                                                )
                                                .cornerRadius(DesignSystem.Radius.small)
                                        }
                                    }
                                }
                            }

                            // Sessions per day
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                                Text("Sessions per day")
                                    .font(DesignSystem.Typography.bodyEmphasized)
                                    .foregroundColor(DesignSystem.Colors.text.primary)

                                HStack(spacing: DesignSystem.Spacing.small) {
                                    ForEach(1...2, id: \.self) { sessions in
                                        Button {
                                            withAnimation(DesignSystem.Animation.fast) {
                                                sessionsPerDay = sessions
                                            }
                                        } label: {
                                            VStack(spacing: 4) {
                                                Text("\(sessions)")
                                                    .font(.system(size: 20, weight: .bold))
                                                Text(sessions == 1 ? "session" : "sessions")
                                                    .font(.system(size: 12))
                                            }
                                            .foregroundColor(
                                                sessionsPerDay == sessions
                                                    ? DesignSystem.Colors.text.primary
                                                    : DesignSystem.Colors.text.secondary
                                            )
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 16)
                                            .background(
                                                sessionsPerDay == sessions
                                                    ? DesignSystem.Colors.primary
                                                    : DesignSystem.Colors.backgroundSecondary
                                            )
                                            .cornerRadius(DesignSystem.Radius.small)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(DesignSystem.Spacing.medium)
                        .background(DesignSystem.Colors.surface)
                        .cornerRadius(DesignSystem.Radius.medium)
                    }

                    // Recovery Day Section (only show for 6+ days/week)
                    if daysPerWeek >= 6 {
                        PreferenceSection(title: "RECOVERY DAY") {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                                Text("With \(daysPerWeek) training days, you need one recovery day with a single session")
                                    .font(DesignSystem.Typography.caption1)
                                    .foregroundColor(DesignSystem.Colors.text.secondary)
                                    .padding(.bottom, DesignSystem.Spacing.xSmall)

                                HStack(spacing: DesignSystem.Spacing.small) {
                                    RecoveryDayButton(
                                        day: .saturday,
                                        isSelected: preferredRecoveryDay == .saturday,
                                        action: {
                                            withAnimation(DesignSystem.Animation.fast) {
                                                preferredRecoveryDay = .saturday
                                            }
                                        }
                                    )

                                    RecoveryDayButton(
                                        day: .sunday,
                                        isSelected: preferredRecoveryDay == .sunday,
                                        action: {
                                            withAnimation(DesignSystem.Animation.fast) {
                                                preferredRecoveryDay = .sunday
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(DesignSystem.Spacing.medium)
                            .background(DesignSystem.Colors.surface)
                            .cornerRadius(DesignSystem.Radius.medium)
                        }
                    }

                    // Preferred Workout Types Section
                    PreferenceSection(title: "PREFERRED WORKOUT TYPES") {
                        Text("Select your favorite workout types (optional)")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                            .padding(.bottom, DesignSystem.Spacing.small)

                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: DesignSystem.Spacing.small),
                                GridItem(.flexible(), spacing: DesignSystem.Spacing.small)
                            ],
                            spacing: DesignSystem.Spacing.small
                        ) {
                            ForEach([
                                WorkoutType.running,
                                WorkoutType.fullSimulation,
                                WorkoutType.stationFocus,
                                WorkoutType.interval,
                                WorkoutType.strength,
                                WorkoutType.recovery
                            ], id: \.self) { type in
                                WorkoutTypeButton(
                                    type: type,
                                    isSelected: preferredTypes.contains(type)
                                ) {
                                    withAnimation(DesignSystem.Animation.fast) {
                                        if preferredTypes.contains(type) {
                                            preferredTypes.removeAll { $0 == type }
                                        } else {
                                            preferredTypes.append(type)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Regenerate Plan Button
                    Button {
                        Task {
                            await regeneratePlan()
                        }
                    } label: {
                        HStack {
                            if isRegenerating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 16, weight: .semibold))
                            }

                            Text(isRegenerating ? "Regenerating Plan..." : "Update My Plan")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            isRegenerating
                                ? DesignSystem.Colors.primary.opacity(0.6)
                                : DesignSystem.Colors.primary
                        )
                        .cornerRadius(DesignSystem.Radius.medium)
                    }
                    .disabled(isRegenerating)
                    .padding(.top, DesignSystem.Spacing.medium)
                }
                .padding(.horizontal, DesignSystem.Spacing.large)
                .padding(.bottom, DesignSystem.Spacing.xxLarge)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showRaceDatePicker) {
            raceDatePickerSheet
        }
        .alert("Success", isPresented: $showSuccessMessage) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your training plan has been updated successfully!")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("TRAINING SETTINGS")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(1)

            Text("Preferences")
                .font(DesignSystem.Typography.largeTitle)
                .foregroundColor(DesignSystem.Colors.text.primary)

            Text("Modify your training variables and regenerate your plan")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .padding(.top, 4)
        }
        .padding(.top, 8)
    }

    private var raceDatePickerSheet: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Race Date",
                    selection: Binding(
                        get: { raceDate ?? Date().addingTimeInterval(90 * 24 * 60 * 60) },
                        set: { raceDate = $0 }
                    ),
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()

                Spacer()
            }
            .background(Color.black)
            .navigationTitle("Select Race Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showRaceDatePicker = false
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func regeneratePlan() async {
        guard let user = appState.currentUser else {
            errorMessage = "User not found"
            showErrorAlert = true
            return
        }

        // Validate race date for competing goal
        if trainingGoal == .competeRace && raceDate == nil {
            errorMessage = "Please select a race date"
            showErrorAlert = true
            return
        }

        isRegenerating = true

        do {
            // Update user preferences
            var updatedUser = user
            updatedUser.trainingGoal = trainingGoal
            updatedUser.raceDate = raceDate
            updatedUser.experienceLevel = experienceLevel
            updatedUser.trainingPreferences = UserTrainingPreferences(
                daysPerWeek: daysPerWeek,
                sessionsPerDay: sessionsPerDay,
                preferredTypes: preferredTypes
            )
            updatedUser.preferredRecoveryDay = preferredRecoveryDay

            // Save updated user to AppState and Supabase
            appState.currentUser = updatedUser
            try await SupabaseService.shared.updateUser(updatedUser)

            // Regenerate the training plan
            try await planService.regeneratePlan(for: updatedUser)

            isRegenerating = false
            showSuccessMessage = true
        } catch {
            isRegenerating = false
            errorMessage = "Failed to update plan: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
}

// MARK: - Supporting Views

struct PreferenceSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            content
        }
    }
}

struct PreferenceCard: View {
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.medium) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(DesignSystem.Typography.bodyEmphasized)
                        .foregroundColor(DesignSystem.Colors.text.primary)

                    Text(description)
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(
                        isSelected
                            ? DesignSystem.Colors.primary
                            : DesignSystem.Colors.text.secondary
                    )
                    .font(.system(size: 24))
            }
            .padding(DesignSystem.Spacing.medium)
            .background(
                isSelected
                    ? DesignSystem.Colors.surface
                    : DesignSystem.Colors.backgroundSecondary
            )
            .cornerRadius(DesignSystem.Radius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                    .stroke(
                        isSelected ? DesignSystem.Colors.primary : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }
}

struct WorkoutTypeButton: View {
    let type: WorkoutType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.system(size: 28))
                    .foregroundColor(
                        isSelected
                            ? DesignSystem.Colors.primary
                            : DesignSystem.Colors.text.secondary
                    )

                Text(type.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.text.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSelected
                    ? DesignSystem.Colors.surface
                    : DesignSystem.Colors.backgroundSecondary
            )
            .cornerRadius(DesignSystem.Radius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                    .stroke(
                        isSelected ? DesignSystem.Colors.primary : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }
}

struct RecoveryDayButton: View {
    let day: DayOfWeek
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(
                        isSelected
                            ? DesignSystem.Colors.primary
                            : DesignSystem.Colors.text.secondary
                    )

                Text(day.displayName)
                    .font(DesignSystem.Typography.bodyEmphasized)
                    .foregroundColor(DesignSystem.Colors.text.primary)

                Text("Recovery Day")
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSelected
                    ? DesignSystem.Colors.surface
                    : DesignSystem.Colors.backgroundSecondary
            )
            .cornerRadius(DesignSystem.Radius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                    .stroke(
                        isSelected ? DesignSystem.Colors.primary : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        TrainingPreferencesView(user: User(
            id: UUID(),
            email: "test@example.com",
            name: "Test User",
            createdAt: Date(),
            trainingGoal: .competeRace,
            raceDate: Date().addingTimeInterval(90 * 24 * 60 * 60),
            trainingPreferences: UserTrainingPreferences(
                daysPerWeek: 4,
                sessionsPerDay: 1,
                preferredTypes: [.running, .fullSimulation]
            ),
            experienceLevel: .intermediate,
            deviceTokens: nil,
            equipment: nil,
            hasAppleWatch: true
        ))
        .environmentObject(AppState())
    }
    .preferredColorScheme(.dark)
}
