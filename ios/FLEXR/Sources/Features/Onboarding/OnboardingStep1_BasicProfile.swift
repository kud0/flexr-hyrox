import SwiftUI

// MARK: - Step 1: Basic Profile
// Age, weight, height, gender, training background (5 questions)

struct OnboardingStep1_BasicProfile: View {
    @ObservedObject var onboardingData: OnboardingData
    let onNext: () -> Void
    let onBack: () -> Void

    @FocusState private var focusedField: Field?

    enum Field {
        case age, weight, height
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxLarge) {
                // Header
                header

                // Input fields
                VStack(spacing: DesignSystem.Spacing.large) {
                    // Age
                    InputField(
                        title: "Age",
                        placeholder: "Enter your age",
                        value: Binding(
                            get: { onboardingData.age.map(String.init) ?? "" },
                            set: { onboardingData.age = Int($0) }
                        ),
                        keyboardType: .numberPad,
                        isFocused: focusedField == .age
                    )
                    .focused($focusedField, equals: .age)

                    // Weight
                    InputField(
                        title: "Weight (kg)",
                        placeholder: "Enter your weight",
                        value: Binding(
                            get: { onboardingData.weight.map { String(format: "%.1f", $0) } ?? "" },
                            set: { onboardingData.weight = Double($0) }
                        ),
                        keyboardType: .decimalPad,
                        isFocused: focusedField == .weight
                    )
                    .focused($focusedField, equals: .weight)

                    // Height
                    InputField(
                        title: "Height (cm)",
                        placeholder: "Enter your height",
                        value: Binding(
                            get: { onboardingData.height.map { String(format: "%.0f", $0) } ?? "" },
                            set: { onboardingData.height = Double($0) }
                        ),
                        keyboardType: .numberPad,
                        isFocused: focusedField == .height
                    )
                    .focused($focusedField, equals: .height)

                    // Gender
                    genderSelection

                    // Training Background
                    trainingBackgroundSelection
                }

                Spacer(minLength: DesignSystem.Spacing.xxxLarge)

                // Continue button
                continueButton
            }
            .padding(DesignSystem.Spacing.large)
        }
        .background(DesignSystem.Colors.background)
        .onTapGesture {
            focusedField = nil
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text("Let's start with the basics")
                .font(DesignSystem.Typography.title1)
                .foregroundColor(DesignSystem.Colors.text.primary)

            Text("The AI will use this to personalize your training plan")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.text.secondary)
        }
    }

    // MARK: - Gender Selection

    private var genderSelection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("Gender")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.text.primary)

            HStack(spacing: DesignSystem.Spacing.medium) {
                ForEach(OnboardingData.Gender.allCases, id: \.self) { gender in
                    GenderButton(
                        gender: gender,
                        isSelected: onboardingData.gender == gender
                    ) {
                        onboardingData.gender = gender
                    }
                }
            }
        }
    }

    // MARK: - Training Background Selection

    private var trainingBackgroundSelection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("Training Background")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.text.primary)

            Text("This helps the AI set the right starting intensity")
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.text.secondary)

            VStack(spacing: DesignSystem.Spacing.small) {
                ForEach(OnboardingData.TrainingBackground.allCases, id: \.self) { background in
                    BackgroundCard(
                        background: background,
                        isSelected: onboardingData.trainingBackground == background
                    ) {
                        onboardingData.trainingBackground = background
                    }
                }
            }
        }
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button(action: {
            focusedField = nil
            onNext()
        }) {
            Text("Continue")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    onboardingData.isStepComplete(1)
                        ? DesignSystem.Colors.primary
                        : DesignSystem.Colors.backgroundSecondary
                )
                .cornerRadius(DesignSystem.Radius.medium)
        }
        .disabled(!onboardingData.isStepComplete(1))
    }
}

// MARK: - Input Field Component

struct InputField: View {
    let title: String
    let placeholder: String
    @Binding var value: String
    let keyboardType: UIKeyboardType
    let isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text(title)
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.text.primary)

            TextField(placeholder, text: $value)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.text.primary)
                .keyboardType(keyboardType)
                .padding()
                .background(DesignSystem.Colors.backgroundSecondary)
                .cornerRadius(DesignSystem.Radius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                        .stroke(
                            isFocused ? DesignSystem.Colors.primary : Color.clear,
                            lineWidth: 2
                        )
                )
        }
    }
}

// MARK: - Gender Button Component

struct GenderButton: View {
    let gender: OnboardingData.Gender
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(gender.displayName)
                .font(DesignSystem.Typography.body)
                .foregroundColor(isSelected ? .black : DesignSystem.Colors.text.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    isSelected
                        ? DesignSystem.Colors.primary
                        : DesignSystem.Colors.backgroundSecondary
                )
                .cornerRadius(DesignSystem.Radius.medium)
        }
    }
}

// MARK: - Background Card Component

struct BackgroundCard: View {
    let background: OnboardingData.TrainingBackground
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.medium) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(background.displayName)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.text.primary)

                    Text(background.description)
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
    OnboardingStep1_BasicProfile(
        onboardingData: OnboardingData(),
        onNext: {},
        onBack: {}
    )
}
