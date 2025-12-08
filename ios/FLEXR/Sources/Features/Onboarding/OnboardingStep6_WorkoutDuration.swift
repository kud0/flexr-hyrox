import SwiftUI

// MARK: - Step 6: Workout Duration Preference
// How much time do you have for workouts?

struct OnboardingStep6_WorkoutDuration: View {
    @ObservedObject var onboardingData: OnboardingData
    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxLarge) {
                // Header
                header

                // Duration options
                VStack(spacing: DesignSystem.Spacing.small) {
                    ForEach(OnboardingData.WorkoutDuration.allCases, id: \.self) { duration in
                        DurationCard(
                            duration: duration,
                            isSelected: onboardingData.preferredWorkoutDuration == duration
                        ) {
                            onboardingData.preferredWorkoutDuration = duration
                        }
                    }
                }

                // Info box
                infoBox

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
            Text("Workout duration")
                .font(DesignSystem.Typography.title1)
                .foregroundColor(DesignSystem.Colors.text.primary)

            Text("How much time do you typically have for training?")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.text.secondary)
        }
    }

    // MARK: - Info Box

    private var infoBox: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            Image(systemName: "lightbulb.fill")
                .font(.title3)
                .foregroundColor(DesignSystem.Colors.primary)

            VStack(alignment: .leading, spacing: 4) {
                Text("Flexible scheduling")
                    .font(DesignSystem.Typography.caption1.weight(.semibold))
                    .foregroundColor(DesignSystem.Colors.text.primary)

                Text("The AI will build workouts that fit your available time. You can always adjust specific sessions later.")
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(DesignSystem.Colors.backgroundSecondary.opacity(0.5))
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
                        onboardingData.isStepComplete(6)
                            ? DesignSystem.Colors.primary
                            : DesignSystem.Colors.backgroundSecondary
                    )
                    .cornerRadius(DesignSystem.Radius.medium)
            }
            .disabled(!onboardingData.isStepComplete(6))
        }
    }
}

// MARK: - Duration Card Component

struct DurationCard: View {
    let duration: OnboardingData.WorkoutDuration
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.medium) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(duration.displayName)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.text.primary)

                    Text(duration.description)
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }

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

// MARK: - Preview

#Preview {
    OnboardingStep6_WorkoutDuration(
        onboardingData: OnboardingData(),
        onNext: {},
        onBack: {}
    )
}
