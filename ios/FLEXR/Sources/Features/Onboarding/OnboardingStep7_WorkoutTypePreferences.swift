import SwiftUI

// MARK: - Step 7: Workout Type Preferences
// What types of workouts do you enjoy?

struct OnboardingStep7_WorkoutTypePreferences: View {
    @ObservedObject var onboardingData: OnboardingData
    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxLarge) {
                // Header
                header

                // Workout types grid
                workoutTypesGrid

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
            Text("Workout preferences")
                .font(DesignSystem.Typography.title1)
                .foregroundColor(DesignSystem.Colors.text.primary)

            Text("Select the types of workouts you enjoy (choose multiple)")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.text.secondary)
        }
    }

    // MARK: - Workout Types Grid

    private var workoutTypesGrid: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            ForEach(OnboardingData.PreferredWorkoutType.allCases, id: \.self) { type in
                WorkoutTypeCard(
                    type: type,
                    isSelected: onboardingData.preferredWorkoutTypes.contains(type)
                ) {
                    toggleWorkoutType(type)
                }
            }
        }
    }

    private func toggleWorkoutType(_ type: OnboardingData.PreferredWorkoutType) {
        if onboardingData.preferredWorkoutTypes.contains(type) {
            onboardingData.preferredWorkoutTypes.remove(type)
        } else {
            onboardingData.preferredWorkoutTypes.insert(type)
        }
    }

    // MARK: - Info Box

    private var infoBox: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            Image(systemName: "lightbulb.fill")
                .font(.title3)
                .foregroundColor(DesignSystem.Colors.primary)

            VStack(alignment: .leading, spacing: 4) {
                Text("Variety is key")
                    .font(DesignSystem.Typography.caption1.weight(.semibold))
                    .foregroundColor(DesignSystem.Colors.text.primary)

                Text("Your plan will include variety, but the AI will prioritize the types you selected. HYROX requires balanced training across all areas.")
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
                        onboardingData.isStepComplete(7)
                            ? DesignSystem.Colors.primary
                            : DesignSystem.Colors.backgroundSecondary
                    )
                    .cornerRadius(DesignSystem.Radius.medium)
            }
            .disabled(!onboardingData.isStepComplete(7))
        }
    }
}

// MARK: - Workout Type Card Component

struct WorkoutTypeCard: View {
    let type: OnboardingData.PreferredWorkoutType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.medium) {
                // Icon
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.text.secondary)
                    .frame(width: 40)

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.displayName)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.text.primary)

                    Text(type.description)
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }

                Spacer()

                // Checkmark
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
    OnboardingStep7_WorkoutTypePreferences(
        onboardingData: OnboardingData(),
        onNext: {},
        onBack: {}
    )
}
