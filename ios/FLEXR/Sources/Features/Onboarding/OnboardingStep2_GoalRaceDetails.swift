import SwiftUI

// MARK: - Step 2: Goal & Race Details
// Primary goal, race date (conditional), target time (conditional)

struct OnboardingStep2_GoalRaceDetails: View {
    @ObservedObject var onboardingData: OnboardingData
    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxLarge) {
                // Header
                header

                // Primary Goal Selection
                goalSelection

                // Previous HYROX Experience Section
                previousRaceSection

                // Conditional: Race Date (if goal requires race)
                if onboardingData.primaryGoal?.requiresRaceDate == true {
                    raceDatePicker
                    targetTimeSelection
                }

                // Just Finished Race Toggle (always visible)
                justFinishedRaceToggle

                Spacer(minLength: DesignSystem.Spacing.xxxLarge)

                // Navigation buttons
                navigationButtons
            }
            .padding(DesignSystem.Spacing.large)
        }
        .background(DesignSystem.Colors.background)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text("What's your goal?")
                .font(DesignSystem.Typography.title1)
                .foregroundColor(DesignSystem.Colors.text.primary)

            Text("This helps the AI build the right plan for your timeline")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.text.secondary)
        }
    }

    // MARK: - Goal Selection

    private var goalSelection: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            ForEach(OnboardingData.PrimaryGoal.allCases, id: \.self) { goal in
                GoalCard(
                    goal: goal,
                    isSelected: onboardingData.primaryGoal == goal
                ) {
                    withAnimation(DesignSystem.Animation.normal) {
                        onboardingData.primaryGoal = goal
                        // Reset race date if goal doesn't require it
                        if !goal.requiresRaceDate {
                            onboardingData.raceDate = nil
                            onboardingData.targetTime = nil
                        }
                    }
                }
            }
        }
    }

    // MARK: - Race Date Picker

    private var raceDatePicker: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("Race Date")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.text.primary)

            DatePicker(
                "Select date",
                selection: Binding(
                    get: { onboardingData.raceDate ?? Date().addingTimeInterval(86400 * 90) },
                    set: { onboardingData.raceDate = $0 }
                ),
                in: Date()...,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .accentColor(DesignSystem.Colors.primary)
            .padding()
            .background(DesignSystem.Colors.backgroundSecondary)
            .cornerRadius(DesignSystem.Radius.medium)

            if let weeksToRace = onboardingData.weeksToRace {
                Text("📅 \(weeksToRace) weeks to race")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.primary)
                    .padding(.horizontal, DesignSystem.Spacing.small)
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Target Time Selection

    private var targetTimeSelection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("Target Time")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.text.primary)

            Text("What's your goal finish time?")
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.text.secondary)

            VStack(spacing: DesignSystem.Spacing.small) {
                ForEach(OnboardingData.TargetTime.allCases, id: \.self) { time in
                    TargetTimeButton(
                        targetTime: time,
                        isSelected: onboardingData.targetTime == time
                    ) {
                        onboardingData.targetTime = time
                    }
                }
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Previous Race Section

    private var previousRaceSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            // Main toggle
            HStack(spacing: DesignSystem.Spacing.medium) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Have you completed HYROX before?")
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.text.primary)

                    Text("This helps the AI calibrate your training intensity")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }

                Spacer()

                Toggle("", isOn: $onboardingData.hasCompletedHyroxBefore)
                    .labelsHidden()
                    .tint(DesignSystem.Colors.primary)
            }
            .padding()
            .background(DesignSystem.Colors.backgroundSecondary)
            .cornerRadius(DesignSystem.Radius.medium)

            // Conditional: Previous race details
            if onboardingData.hasCompletedHyroxBefore {
                VStack(spacing: DesignSystem.Spacing.medium) {
                    // Number of races
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                        Text("How many HYROX races have you completed?")
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.text.primary)

                        ForEach(OnboardingData.NumberOfRaces.allCases, id: \.self) { count in
                            RaceCountButton(
                                raceCount: count,
                                isSelected: onboardingData.numberOfHyroxRaces == count
                            ) {
                                onboardingData.numberOfHyroxRaces = count
                            }
                        }
                    }

                    // Best time input
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                        Text("What was your best finishing time?")
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.text.primary)

                        BestTimeInput(bestTime: $onboardingData.bestHyroxTime)
                    }

                    // Division selection
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                        Text("Which division?")
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.text.primary)

                        ForEach(OnboardingData.HyroxDivision.allCases, id: \.self) { division in
                            DivisionButton(
                                division: division,
                                isSelected: onboardingData.bestHyroxDivision == division
                            ) {
                                onboardingData.bestHyroxDivision = division
                            }
                        }
                    }

                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Just Finished Race Toggle

    private var justFinishedRaceToggle: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Just finished a race?")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.text.primary)

                Text("The AI will add recovery time if needed")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }

            Spacer()

            Toggle("", isOn: $onboardingData.justFinishedRace)
                .labelsHidden()
                .tint(DesignSystem.Colors.primary)
        }
        .padding()
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(DesignSystem.Radius.medium)
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            Button(action: onBack) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.text.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(DesignSystem.Colors.backgroundSecondary)
                .cornerRadius(DesignSystem.Radius.medium)
            }

            Button(action: onNext) {
                Text("Continue")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        onboardingData.isStepComplete(2)
                            ? DesignSystem.Colors.primary
                            : DesignSystem.Colors.backgroundSecondary
                    )
                    .cornerRadius(DesignSystem.Radius.medium)
            }
            .disabled(!onboardingData.isStepComplete(2))
        }
    }
}

// MARK: - Goal Card Component

struct GoalCard: View {
    let goal: OnboardingData.PrimaryGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.medium) {
                Text(goal.displayName)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.text.primary)
                    .multilineTextAlignment(.leading)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            .padding()
            .background(
                isSelected
                    ? DesignSystem.Colors.backgroundSecondary.opacity(1.5)
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

// MARK: - Target Time Button Component

struct TargetTimeButton: View {
    let targetTime: OnboardingData.TargetTime
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(targetTime.displayName)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(isSelected ? .black : DesignSystem.Colors.text.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.black)
                }
            }
            .padding()
            .background(
                isSelected
                    ? DesignSystem.Colors.primary
                    : DesignSystem.Colors.backgroundSecondary
            )
            .cornerRadius(DesignSystem.Radius.medium)
        }
    }
}

// MARK: - Race Count Button Component

struct RaceCountButton: View {
    let raceCount: OnboardingData.NumberOfRaces
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(raceCount.displayName)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(isSelected ? .black : DesignSystem.Colors.text.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.black)
                }
            }
            .padding()
            .background(
                isSelected
                    ? DesignSystem.Colors.primary
                    : DesignSystem.Colors.backgroundSecondary
            )
            .cornerRadius(DesignSystem.Radius.medium)
        }
    }
}

// MARK: - Best Time Input Component

struct BestTimeInput: View {
    @Binding var bestTime: TimeInterval?
    @State private var hours: String = ""
    @State private var minutes: String = ""
    @State private var seconds: String = ""

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            // Hours
            VStack(spacing: 4) {
                Text("Hours")
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(DesignSystem.Colors.text.secondary)

                TextField("0", text: $hours)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(DesignSystem.Colors.text.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignSystem.Colors.backgroundSecondary)
                    .cornerRadius(DesignSystem.Radius.small)
                    .onChange(of: hours) { _ in updateBestTime() }
            }

            Text(":")
                .font(DesignSystem.Typography.title2)
                .foregroundColor(DesignSystem.Colors.text.secondary)

            // Minutes
            VStack(spacing: 4) {
                Text("Minutes")
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(DesignSystem.Colors.text.secondary)

                TextField("00", text: $minutes)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(DesignSystem.Colors.text.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignSystem.Colors.backgroundSecondary)
                    .cornerRadius(DesignSystem.Radius.small)
                    .onChange(of: minutes) { _ in updateBestTime() }
            }

            Text(":")
                .font(DesignSystem.Typography.title2)
                .foregroundColor(DesignSystem.Colors.text.secondary)

            // Seconds
            VStack(spacing: 4) {
                Text("Seconds")
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(DesignSystem.Colors.text.secondary)

                TextField("00", text: $seconds)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(DesignSystem.Colors.text.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignSystem.Colors.backgroundSecondary)
                    .cornerRadius(DesignSystem.Radius.small)
                    .onChange(of: seconds) { _ in updateBestTime() }
            }
        }
        .onAppear {
            loadFromBestTime()
        }
    }

    private func updateBestTime() {
        let h = Double(hours) ?? 0
        let m = Double(minutes) ?? 0
        let s = Double(seconds) ?? 0

        if h == 0 && m == 0 && s == 0 {
            bestTime = nil
        } else {
            bestTime = (h * 3600) + (m * 60) + s
        }
    }

    private func loadFromBestTime() {
        guard let time = bestTime else { return }

        let totalSeconds = Int(time)
        hours = String(totalSeconds / 3600)
        minutes = String((totalSeconds % 3600) / 60)
        seconds = String(totalSeconds % 60)
    }
}

// MARK: - Division Button Component

struct DivisionButton: View {
    let division: OnboardingData.HyroxDivision
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(division.displayName)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(isSelected ? .black : DesignSystem.Colors.text.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.black)
                }
            }
            .padding()
            .background(
                isSelected
                    ? DesignSystem.Colors.primary
                    : DesignSystem.Colors.backgroundSecondary
            )
            .cornerRadius(DesignSystem.Radius.medium)
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingStep2_GoalRaceDetails(
        onboardingData: OnboardingData(),
        onNext: {},
        onBack: {}
    )
}
