// FLEXR - User Feedback Service
// Handles submitting feedback and managing pulse prompts

import Foundation

@MainActor
class UserFeedbackService: ObservableObject {
    static let shared = UserFeedbackService()

    @Published var isSubmitting = false
    @Published var showPulsePrompt = false
    @Published var lastSubmissionSuccess = false

    private let supabase = SupabaseService.shared
    private let planService = PlanService.shared

    // Cached user ID for pulse tracking
    private var cachedUserId: UUID?

    // Pulse prompt settings
    private let daysBeforeFirstPrompt = 14  // Show first pulse after 2 weeks
    private let daysBetweenPrompts = 7       // Then weekly

    private init() {}

    // MARK: - Submit Feedback

    func submitFeedback(
        category: UserFeedbackCategory,
        message: String,
        appContext: String? = nil
    ) async throws {
        guard let userId = try? await supabase.client.auth.session.user.id else {
            throw FeedbackError.notAuthenticated
        }

        isSubmitting = true
        defer { isSubmitting = false }

        // Get current training week for context
        let currentWeek = planService.currentTrainingWeek

        // Calculate days since signup (approximate from training plan start)
        let daysSinceSignup = calculateDaysSinceSignup()

        let feedback = UserFeedbackRequest(
            userId: userId,
            category: category,
            message: message,
            appContext: appContext,
            trainingWeek: currentWeek,
            daysSinceSignup: daysSinceSignup
        )

        try await supabase.client
            .from("user_feedback_requests")
            .insert(feedback)
            .execute()

        lastSubmissionSuccess = true
        print("UserFeedbackService: Feedback submitted - \(category.rawValue)")

        // If this was a pulse check, record it
        if category == .pulseCheck {
            await recordPulseResponse()
        }
    }

    // MARK: - Pulse Prompt Logic

    func checkShouldShowPulsePrompt() async {
        guard let userId = try? await supabase.client.auth.session.user.id else {
            return
        }

        // Cache userId for later use in synchronous methods
        cachedUserId = userId

        // Check if user has been using app long enough
        let daysSinceSignup = calculateDaysSinceSignup()
        guard daysSinceSignup >= daysBeforeFirstPrompt else {
            return
        }

        // Check last prompt time from UserDefaults (simple approach)
        let lastPromptKey = "lastPulsePrompt_\(userId.uuidString)"
        let lastPrompt = UserDefaults.standard.object(forKey: lastPromptKey) as? Date

        if let lastPrompt = lastPrompt {
            let daysSinceLastPrompt = Calendar.current.dateComponents([.day], from: lastPrompt, to: Date()).day ?? 0
            if daysSinceLastPrompt < daysBetweenPrompts {
                return  // Too soon
            }
        }

        // Show the prompt
        showPulsePrompt = true
    }

    func recordPulseShown() {
        guard let userId = cachedUserId else { return }

        let lastPromptKey = "lastPulsePrompt_\(userId.uuidString)"
        UserDefaults.standard.set(Date(), forKey: lastPromptKey)
    }

    func dismissPulsePrompt() {
        showPulsePrompt = false
        recordPulseShown()  // Record even if dismissed without responding
    }

    private func recordPulseResponse() async {
        recordPulseShown()
    }

    // MARK: - Helpers

    private func calculateDaysSinceSignup() -> Int {
        // Use training plan start date as proxy for signup
        guard let firstWeek = planService.allWeeks.first else {
            return 0
        }

        let startDate = firstWeek.startDate
        let days = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return max(0, days)
    }
}

// MARK: - Errors

enum FeedbackError: LocalizedError {
    case notAuthenticated
    case submissionFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to submit feedback"
        case .submissionFailed:
            return "Failed to submit feedback. Please try again."
        }
    }
}
