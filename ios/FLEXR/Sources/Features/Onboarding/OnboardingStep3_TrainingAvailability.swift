import SwiftUI

// MARK: - Step 3: Training Availability
// Days per week, sessions per day, preferred time, session timing

struct OnboardingStep3_TrainingAvailability: View {
    @ObservedObject var onboardingData: OnboardingData
    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxLarge) {
                // Header
                header

                // Days per week slider
                daysPerWeekSelection

                // Sessions per day
                sessionsPerDaySelection

                // Preferred time (for 1 session/day)
                if onboardingData.sessionsPerDay == .one {
                    preferredTimeSelection
                }

                // Session timing (for 2 sessions/day)
                if onboardingData.sessionsPerDay == .two {
                    sessionTimingSelection
                }

                // Recovery day selection (for 6+ days/week)
                if onboardingData.daysPerWeek >= 6 {
                    recoveryDaySelection
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Start date selection
                startDateSelection

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
            Text("Training availability")
                .font(DesignSystem.Typography.title1)
                .foregroundColor(DesignSystem.Colors.text.primary)

            Text("How many days can you train each week?")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.text.secondary)
        }
    }

    // MARK: - Days Per Week Selection

    private var daysPerWeekSelection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            HStack {
                Text("Training Days")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.text.primary)

                Spacer()

                Text("\(onboardingData.daysPerWeek) days/week")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primary)
            }

            Slider(
                value: Binding(
                    get: { Double(onboardingData.daysPerWeek) },
                    set: { onboardingData.daysPerWeek = Int($0) }
                ),
                in: 3...7,
                step: 1
            )
            .tint(DesignSystem.Colors.primary)
            .padding(.vertical, DesignSystem.Spacing.small)

            HStack {
                Text("3 days")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.text.secondary)

                Spacer()

                Text("7 days")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }

            // Recommendation
            recommendationText
        }
        .padding()
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(DesignSystem.Radius.medium)
    }

    private var recommendationText: some View {
        Group {
            if onboardingData.daysPerWeek <= 3 {
                Label("Minimum for progress", systemImage: "info.circle")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            } else if onboardingData.daysPerWeek <= 5 {
                Label("Optimal for most athletes", systemImage: "checkmark.circle")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.primary)
            } else {
                Label("High volume - ensure adequate recovery", systemImage: "exclamationmark.triangle")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(.orange)
            }
        }
    }

    // MARK: - Sessions Per Day Selection

    private var sessionsPerDaySelection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("Sessions Per Day")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.text.primary)

            HStack(spacing: DesignSystem.Spacing.medium) {
                ForEach(OnboardingData.SessionsPerDay.allCases, id: \.self) { sessions in
                    SessionsButton(
                        sessions: sessions,
                        isSelected: onboardingData.sessionsPerDay == sessions
                    ) {
                        withAnimation(DesignSystem.Animation.normal) {
                            onboardingData.sessionsPerDay = sessions
                        }
                    }
                }
            }
        }
    }

    // MARK: - Preferred Time Selection

    private var preferredTimeSelection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("Preferred Time")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.text.primary)

            Text("When do you usually train?")
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.text.secondary)

            VStack(spacing: DesignSystem.Spacing.small) {
                ForEach(OnboardingData.PreferredTime.allCases, id: \.self) { time in
                    PreferredTimeButton(
                        time: time,
                        isSelected: onboardingData.preferredTime == time
                    ) {
                        onboardingData.preferredTime = time
                    }
                }
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Session Timing Selection

    private var sessionTimingSelection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("Session Timing")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.text.primary)

            Text("When will you do your 2 daily sessions?")
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.text.secondary)

            VStack(spacing: DesignSystem.Spacing.small) {
                ForEach(OnboardingData.SessionTiming.allCases, id: \.self) { timing in
                    SessionTimingButton(
                        timing: timing,
                        isSelected: onboardingData.sessionTiming == timing
                    ) {
                        onboardingData.sessionTiming = timing
                    }
                }
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Recovery Day Selection

    private var recoveryDaySelection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("Recovery Day")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.text.primary)

            Text("Which day should be lighter for recovery?")
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.text.secondary)

            // Day selector grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: DesignSystem.Spacing.small) {
                ForEach(DayOfWeek.allCases, id: \.self) { day in
                    RecoveryDayOptionButton(
                        day: day,
                        isSelected: onboardingData.preferredRecoveryDay == day
                    ) {
                        withAnimation(DesignSystem.Animation.fast) {
                            onboardingData.preferredRecoveryDay = day
                        }
                    }
                }
            }

            // Info about intense session
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)

                Text("\(onboardingData.preferredRecoveryDay.previousDay.displayName) will be your intense session day")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }
            .padding(DesignSystem.Spacing.small)
            .background(DesignSystem.Colors.backgroundSecondary)
            .cornerRadius(DesignSystem.Radius.small)
        }
        .padding()
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(DesignSystem.Radius.medium)
    }

    // MARK: - Start Date Selection

    private var startDateSelection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("When do you want to start?")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.text.primary)

            Text("Your personalized plan will begin from this date")
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.text.secondary)

            HStack(spacing: DesignSystem.Spacing.medium) {
                // Start Today
                StartDateOptionButton(
                    title: "Start Today",
                    subtitle: formattedDate(Date()),
                    isSelected: isStartingToday
                ) {
                    withAnimation(DesignSystem.Animation.fast) {
                        onboardingData.programStartDate = Date()
                    }
                }

                // Start Next Monday
                StartDateOptionButton(
                    title: "Next Monday",
                    subtitle: formattedDate(nextMonday),
                    isSelected: !isStartingToday
                ) {
                    withAnimation(DesignSystem.Animation.fast) {
                        onboardingData.programStartDate = nextMonday
                    }
                }
            }

            // Info about week structure
            if onboardingData.daysPerWeek >= 6 && onboardingData.preferredRecoveryDay != .sunday {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(DesignSystem.Colors.primary)

                    Text("Your training week will start on \(dayAfterRecovery.displayName) (day after recovery)")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }
                .padding(DesignSystem.Spacing.small)
                .background(DesignSystem.Colors.backgroundSecondary)
                .cornerRadius(DesignSystem.Radius.small)
            }
        }
        .padding()
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(DesignSystem.Radius.medium)
    }

    // MARK: - Start Date Helpers

    private var isStartingToday: Bool {
        guard let startDate = onboardingData.programStartDate else { return true }
        return Calendar.current.isDateInToday(startDate)
    }

    private var nextMonday: Date {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        // weekday: 1 = Sunday, 2 = Monday, etc.
        let daysUntilMonday = weekday == 2 ? 7 : (9 - weekday) % 7
        return calendar.date(byAdding: .day, value: daysUntilMonday == 0 ? 7 : daysUntilMonday, to: today)!
    }

    private var dayAfterRecovery: DayOfWeek {
        // The day after recovery is considered "Day 1" of the training week
        let allDays = DayOfWeek.allCases
        guard let recoveryIndex = allDays.firstIndex(of: onboardingData.preferredRecoveryDay) else {
            return .monday
        }
        let nextIndex = (recoveryIndex + 1) % allDays.count
        return allDays[nextIndex]
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
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
                    .background(DesignSystem.Colors.primary)
                    .cornerRadius(DesignSystem.Radius.medium)
            }
        }
    }
}

// MARK: - Sessions Button Component

struct SessionsButton: View {
    let sessions: OnboardingData.SessionsPerDay
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(sessions.displayName)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(isSelected ? .black : DesignSystem.Colors.text.primary)

                Text(sessions.description)
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(isSelected ? .black.opacity(0.7) : DesignSystem.Colors.text.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                isSelected
                    ? DesignSystem.Colors.primary
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

// MARK: - Preferred Time Button Component

struct PreferredTimeButton: View {
    let time: OnboardingData.PreferredTime
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(time.displayName)
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

// MARK: - Session Timing Button Component

struct SessionTimingButton: View {
    let timing: OnboardingData.SessionTiming
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.medium) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(timing.displayName)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(isSelected ? .black : DesignSystem.Colors.text.primary)

                    Text(timing.description)
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(isSelected ? .black.opacity(0.7) : DesignSystem.Colors.text.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
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

// MARK: - Recovery Day Option Button Component

struct RecoveryDayOptionButton: View {
    let day: DayOfWeek
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(day.shortName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(isSelected ? .black : DesignSystem.Colors.text.primary)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.black)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                isSelected
                    ? DesignSystem.Colors.primary
                    : DesignSystem.Colors.backgroundSecondary
            )
            .cornerRadius(DesignSystem.Radius.small)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Start Date Option Button Component

struct StartDateOptionButton: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(isSelected ? .black : DesignSystem.Colors.text.primary)

                Text(subtitle)
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(isSelected ? .black.opacity(0.7) : DesignSystem.Colors.text.secondary)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.medium)
            .background(
                isSelected
                    ? DesignSystem.Colors.primary
                    : DesignSystem.Colors.surface
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
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    OnboardingStep3_TrainingAvailability(
        onboardingData: OnboardingData(),
        onNext: {},
        onBack: {}
    )
}
