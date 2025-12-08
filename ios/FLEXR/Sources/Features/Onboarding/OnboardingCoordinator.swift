import SwiftUI

// MARK: - Onboarding Coordinator
// Manages 9-step complete onboarding flow with progress tracking

struct OnboardingCoordinator: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var onboardingData = OnboardingData()
    @State private var currentStep = 1
    @State private var isGeneratingPlan = false
    @State private var showingCompletion = false

    // Completion callback for FLEXRApp
    var onComplete: ((User) -> Void)?

    private let totalSteps = 9

    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                progressBar

                // Current step content
                stepContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }

            // Show plan generating overlay when generating
            if isGeneratingPlan {
                PlanGeneratingView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut, value: isGeneratingPlan)
        .sheet(isPresented: $showingCompletion) {
            OnboardingCompletionView(onboardingData: onboardingData) {
                // Dismiss the entire onboarding flow
                dismiss()
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            HStack {
                Text("Step \(currentStep) of \(totalSteps)")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.text.secondary)

                Spacer()

                Button("Exit") {
                    dismiss()
                }
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.primary)
            }
            .padding(.horizontal, DesignSystem.Spacing.large)
            .padding(.top, DesignSystem.Spacing.medium)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(DesignSystem.Colors.backgroundSecondary)
                        .frame(height: 4)

                    Rectangle()
                        .fill(DesignSystem.Colors.primary)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, DesignSystem.Spacing.large)
        }
    }

    private var progress: Double {
        Double(currentStep) / Double(totalSteps)
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        Group {
            switch currentStep {
            case 1:
                OnboardingStep1_BasicProfile(
                    onboardingData: onboardingData,
                    onNext: { goToNextStep() },
                    onBack: { goToPreviousStep() }
                )
            case 2:
                OnboardingStep2_GoalRaceDetails(
                    onboardingData: onboardingData,
                    onNext: { goToNextStep() },
                    onBack: { goToPreviousStep() }
                )
            case 3:
                OnboardingStep3_TrainingAvailability(
                    onboardingData: onboardingData,
                    onNext: { goToNextStep() },
                    onBack: { goToPreviousStep() }
                )
            case 4:
                OnboardingStep4_EquipmentAccess(
                    onboardingData: onboardingData,
                    onNext: { goToNextStep() },
                    onBack: { goToPreviousStep() }
                )
            case 5:
                OnboardingStep5_PerformanceNumbers(
                    onboardingData: onboardingData,
                    onNext: { goToNextStep() },
                    onBack: { goToPreviousStep() }
                )
            case 6:
                OnboardingStep6_WorkoutDuration(
                    onboardingData: onboardingData,
                    onNext: { goToNextStep() },
                    onBack: { goToPreviousStep() }
                )
            case 7:
                OnboardingStep7_WorkoutTypePreferences(
                    onboardingData: onboardingData,
                    onNext: { goToNextStep() },
                    onBack: { goToPreviousStep() }
                )
            case 8:
                OnboardingStep8_WatchPairing(
                    onboardingData: onboardingData,
                    onNext: { goToNextStep() },
                    onBack: { goToPreviousStep() }
                )
            case 9:
                OnboardingStep9_HealthKitPermission(
                    onboardingData: onboardingData,
                    onNext: { completeOnboarding() },
                    onBack: { goToPreviousStep() }
                )
            default:
                EmptyView()
            }
        }
        .id(currentStep) // Force view refresh on step change
    }

    // MARK: - Navigation

    private func goToNextStep() {
        guard onboardingData.canProceed(from: currentStep) else {
            // Show validation error
            return
        }

        withAnimation(DesignSystem.Animation.normal) {
            currentStep = min(currentStep + 1, totalSteps)
        }
    }

    private func goToPreviousStep() {
        withAnimation(DesignSystem.Animation.normal) {
            currentStep = max(currentStep - 1, 1)
        }
    }

    private func skipOnboarding() {
        // Allow user to skip with basic defaults
        // This would set minimal required fields and complete
        onboardingData.trainingBackground = .gymRegular
        onboardingData.primaryGoal = .trainStyle
        onboardingData.equipmentLocation = .commercialGym
        onboardingData.preferredWorkoutDuration = .standard
        onboardingData.preferredWorkoutTypes = [.running, .strength, .stationFocus]
        completeOnboarding()
    }

    private func completeOnboarding() {
        isGeneratingPlan = true

        // Submit onboarding data to API
        submitOnboardingData()
    }

    private func submitOnboardingData() {
        Task {
            do {
                // Submit onboarding data to backend
                try await SupabaseService.shared.submitOnboardingData(onboardingData)

                // Get current user ID
                guard let session = try? await SupabaseService.shared.client.auth.session else {
                    throw NSError(domain: "OnboardingError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No active session"])
                }
                let userId = session.user.id

                // Build User object from onboarding data
                let user = buildUserFromOnboardingData(userId: userId, email: session.user.email ?? "")

                // Update appState
                await MainActor.run {
                    appState.currentUser = user
                }

                // Generate training plan using Grok AI (non-blocking - continue even if fails)
                print("🎯 Generating training plan for user \(userId)...")
                do {
                    try await SupabaseService.shared.generateTrainingPlan(for: userId, onboardingData: onboardingData)
                    print("✅ Training plan generated successfully!")
                } catch {
                    // Log error but don't block completion - plan can be generated later
                    print("⚠️ Plan generation failed (will retry later): \(error)")
                }

                // Call completion callback if provided
                await MainActor.run {
                    isGeneratingPlan = false
                    onComplete?(user)
                    showingCompletion = true
                }
            } catch {
                // Handle error
                await MainActor.run {
                    isGeneratingPlan = false
                    // TODO: Show error alert
                    print("❌ Failed to complete onboarding: \(error)")
                }
            }
        }
    }

    private func buildUserFromOnboardingData(userId: UUID, email: String) -> User {
        // Map onboarding goal to TrainingGoal
        let trainingGoal: TrainingGoal = {
            switch onboardingData.primaryGoal {
            case .firstHyrox, .prepareForRace: return .competeRace
            case .podium: return .competeRace
            case .trainStyle: return .trainStyle
            case .multipleRaces: return .competeRace
            case .none: return .trainStyle
            }
        }()

        // Map experience
        let experienceLevel: ExperienceLevel = {
            switch onboardingData.trainingBackground {
            case .newToFitness: return .beginner
            case .gymRegular, .runner: return .intermediate
            case .crossfit: return .advanced
            case .hyroxVeteran: return .elite
            case .none: return .intermediate
            }
        }()

        let preferences = UserTrainingPreferences(
            daysPerWeek: onboardingData.daysPerWeek,
            sessionsPerDay: onboardingData.sessionsPerDay.rawValue,
            preferredTypes: []
        )

        return User(
            id: userId,
            email: email,
            name: "FLEXR Athlete",
            createdAt: Date(),
            trainingGoal: trainingGoal,
            raceDate: onboardingData.raceDate,
            programStartDate: onboardingData.programStartDate,
            preferredRecoveryDay: onboardingData.daysPerWeek >= 6 ? onboardingData.preferredRecoveryDay : nil,
            trainingPreferences: preferences,
            experienceLevel: experienceLevel,
            equipment: nil,
            hasAppleWatch: onboardingData.hasAppleWatch
        )
    }
}

// MARK: - Preview

#Preview {
    OnboardingCoordinator()
}
