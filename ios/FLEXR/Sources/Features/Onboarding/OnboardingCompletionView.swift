import SwiftUI

// MARK: - Onboarding Completion View
// Loading state while generating training plan, then success

struct OnboardingCompletionView: View {
    @ObservedObject var onboardingData: OnboardingData
    @Environment(\.dismiss) private var dismiss
    var onComplete: () -> Void // Callback to dismiss entire onboarding flow

    @State private var isGenerating = true
    @State private var generationProgress: Double = 0.0
    @State private var currentStep = "Analyzing your profile..."

    private let generationSteps = [
        "Analyzing your performance data...",
        "Calculating optimal training zones...",
        "Prescribing training loads...",
        "Generating your first week...",
        "Optimizing workout structure..."
    ]

    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()

            if isGenerating {
                generatingView
            } else {
                successView
            }
        }
        .onAppear {
            startGeneration()
        }
    }

    // MARK: - Generating View

    private var generatingView: some View {
        VStack(spacing: DesignSystem.Spacing.xxxLarge) {
            Spacer()

            // Animated logo or icon
            ZStack {
                Circle()
                    .stroke(DesignSystem.Colors.backgroundSecondary, lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: generationProgress)
                    .stroke(
                        DesignSystem.Colors.primary,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: generationProgress)

                Image(systemName: "figure.run")
                    .font(.system(size: 48))
                    .foregroundColor(DesignSystem.Colors.primary)
            }

            // Progress text
            VStack(spacing: DesignSystem.Spacing.small) {
                Text("Analyzing Your Data")
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.text.primary)

                Text(currentStep)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
                    .multilineTextAlignment(.center)
            }

            // Progress percentage
            Text("\(Int(generationProgress * 100))%")
                .font(DesignSystem.Typography.title3)
                .foregroundColor(DesignSystem.Colors.primary)

            Spacer()
        }
        .padding(DesignSystem.Spacing.large)
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: DesignSystem.Spacing.xxxLarge) {
            Spacer()

            // Success icon
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.primary.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.primary)
            }
            .scaleEffect(1.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.6), value: isGenerating)

            // Success message
            VStack(spacing: DesignSystem.Spacing.medium) {
                Text("Your plan is ready!")
                    .font(DesignSystem.Typography.title1)
                    .foregroundColor(DesignSystem.Colors.text.primary)

                Text("The AI has analyzed your data and generated an adaptive training plan")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.xxxLarge)
            }

            // Summary cards
            VStack(spacing: DesignSystem.Spacing.small) {
                SummaryCard(
                    icon: "calendar",
                    title: "\(onboardingData.daysPerWeek) days/week",
                    subtitle: "\(onboardingData.sessionsPerDay.rawValue) session\(onboardingData.sessionsPerDay.rawValue == 1 ? "" : "s") per day"
                )

                if let weeksToRace = onboardingData.weeksToRace {
                    SummaryCard(
                        icon: "flag.checkered",
                        title: "\(weeksToRace) weeks to race",
                        subtitle: onboardingData.targetTime?.displayName ?? "Your goal"
                    )
                }

                SummaryCard(
                    icon: "dumbbell.fill",
                    title: onboardingData.equipmentLocation?.displayName ?? "Equipment",
                    subtitle: "Exercises tailored to your access"
                )
            }
            .padding(.horizontal, DesignSystem.Spacing.large)

            Spacer()

            // Start training button
            Button(action: {
                // Dismiss the sheet first
                dismiss()
                // Then dismiss the entire onboarding flow
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onComplete()
                }
            }) {
                Text("Start Training")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(DesignSystem.Colors.primary)
                    .cornerRadius(DesignSystem.Radius.medium)
            }
            .padding(.horizontal, DesignSystem.Spacing.large)
            .padding(.bottom, DesignSystem.Spacing.large)
        }
    }

    // MARK: - Generation Logic

    private func startGeneration() {
        Task {
            for (index, step) in generationSteps.enumerated() {
                await MainActor.run {
                    currentStep = step
                    generationProgress = Double(index + 1) / Double(generationSteps.count)
                }

                // Simulate API call delay
                try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
            }

            // Show success
            await MainActor.run {
                withAnimation(DesignSystem.Animation.normal) {
                    isGenerating = false
                }
            }
        }
    }
}

// MARK: - Summary Card Component

struct SummaryCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.text.primary)

                Text(subtitle)
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }

            Spacer()
        }
        .padding()
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(DesignSystem.Radius.medium)
    }
}

// MARK: - Preview

#Preview {
    OnboardingCompletionView(onboardingData: OnboardingData(), onComplete: {})
}
