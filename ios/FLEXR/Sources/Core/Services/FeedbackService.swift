// FLEXR - Feedback Service
// Handles saving and retrieving workout feedback for AI personalization

import Foundation

@MainActor
class FeedbackService: ObservableObject {
    static let shared = FeedbackService()

    @Published var isSubmitting = false
    @Published var error: String?

    private let supabase = SupabaseService.shared

    private init() {}

    // MARK: - Submit Feedback

    /// Submit feedback for a completed workout
    /// Returns whether a regeneration was triggered based on strong feedback signals
    @discardableResult
    func submitFeedback(_ feedback: WorkoutFeedback) async throws -> FeedbackSubmitResult {
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await supabase.client
                .from("workout_feedback")
                .insert(feedback)
                .execute()

            print("FeedbackService: Feedback submitted for workout \(feedback.workoutId)")

            // Check if feedback signals warrant regenerating next week
            let regenerationResult = await checkAndTriggerRegeneration(userId: feedback.userId)

            return FeedbackSubmitResult(
                success: true,
                regenerationTriggered: regenerationResult.regenerated,
                regeneratedWeek: regenerationResult.weekRegenerated,
                signal: regenerationResult.signal
            )
        } catch {
            print("FeedbackService: Error submitting feedback - \(error)")
            self.error = error.localizedDescription
            throw error
        }
    }

    /// Check feedback signals and trigger regeneration if needed
    private func checkAndTriggerRegeneration(userId: UUID) async -> (regenerated: Bool, weekRegenerated: Int?, signal: String?) {
        do {
            let result: RegenerationResponse = try await supabase.client.functions.invoke(
                "generate-next-week",
                options: .init(body: RegenerationRequest(
                    user_id: userId.uuidString,
                    action: "regenerate_if_needed"
                ))
            )

            if result.regenerated {
                print("FeedbackService: 🔄 Next week regenerated due to \(result.signal ?? "unknown") signal")
                // Invalidate cache so user sees new workouts
                PlanService.shared.invalidateCache()
            }

            return (result.regenerated, result.weekRegenerated, result.signal)
        } catch {
            print("FeedbackService: Error checking regeneration - \(error)")
            return (false, nil, nil)
        }
    }

    /// Update existing feedback
    func updateFeedback(_ feedback: WorkoutFeedback) async throws {
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await supabase.client
                .from("workout_feedback")
                .update(feedback)
                .eq("id", value: feedback.id.uuidString)
                .execute()

            print("FeedbackService: Feedback updated for workout \(feedback.workoutId)")
        } catch {
            print("FeedbackService: Error updating feedback - \(error)")
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Fetch Feedback

    /// Get feedback for a specific workout
    func getFeedback(forWorkout workoutId: UUID) async -> WorkoutFeedback? {
        do {
            let response: [WorkoutFeedback] = try await supabase.client
                .from("workout_feedback")
                .select()
                .eq("workout_id", value: workoutId.uuidString)
                .limit(1)
                .execute()
                .value

            return response.first
        } catch {
            print("FeedbackService: Error fetching feedback - \(error)")
            return nil
        }
    }

    /// Get all feedback for a user within a date range (for weekly analysis)
    func getFeedback(forUser userId: UUID, from startDate: Date, to endDate: Date) async -> [WorkoutFeedback] {
        do {
            let response: [WorkoutFeedback] = try await supabase.client
                .from("workout_feedback")
                .select()
                .eq("user_id", value: userId.uuidString)
                .gte("created_at", value: startDate.ISO8601Format())
                .lte("created_at", value: endDate.ISO8601Format())
                .order("created_at", ascending: false)
                .execute()
                .value

            return response
        } catch {
            print("FeedbackService: Error fetching feedback range - \(error)")
            return []
        }
    }

    /// Get recent feedback for a user (last N workouts)
    func getRecentFeedback(forUser userId: UUID, limit: Int = 10) async -> [WorkoutFeedback] {
        do {
            let response: [WorkoutFeedback] = try await supabase.client
                .from("workout_feedback")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value

            return response
        } catch {
            print("FeedbackService: Error fetching recent feedback - \(error)")
            return []
        }
    }

    // MARK: - Analytics Helpers

    /// Calculate average RPE for a set of feedback
    func averageRPE(from feedback: [WorkoutFeedback]) -> Double? {
        let rpeScores = feedback.compactMap { $0.rpeScore }
        guard !rpeScores.isEmpty else { return nil }
        return Double(rpeScores.reduce(0, +)) / Double(rpeScores.count)
    }

    /// Get most common tags from feedback
    func commonTags(from feedback: [WorkoutFeedback], topN: Int = 5) -> [FeedbackTag] {
        var tagCounts: [FeedbackTag: Int] = [:]

        for item in feedback {
            for tag in item.tags {
                tagCounts[tag, default: 0] += 1
            }
        }

        return tagCounts
            .sorted { $0.value > $1.value }
            .prefix(topN)
            .map { $0.key }
    }

    /// Determine RPE trend (increasing, stable, decreasing)
    func rpeTrend(from feedback: [WorkoutFeedback]) -> String {
        let rpeScores = feedback
            .sorted { $0.createdAt < $1.createdAt }
            .compactMap { $0.rpeScore }

        guard rpeScores.count >= 3 else { return "stable" }

        let firstHalf = Array(rpeScores.prefix(rpeScores.count / 2))
        let secondHalf = Array(rpeScores.suffix(rpeScores.count / 2))

        let firstAvg = Double(firstHalf.reduce(0, +)) / Double(firstHalf.count)
        let secondAvg = Double(secondHalf.reduce(0, +)) / Double(secondHalf.count)

        let difference = secondAvg - firstAvg

        if difference > 0.5 {
            return "increasing"
        } else if difference < -0.5 {
            return "decreasing"
        } else {
            return "stable"
        }
    }

    /// Build a weekly summary for AI consumption
    func buildWeeklySummary(forUser userId: UUID, weekStart: Date, weekEnd: Date) async -> WeeklyFeedbackSummary {
        let feedback = await getFeedback(forUser: userId, from: weekStart, to: weekEnd)

        return WeeklyFeedbackSummary(
            workoutsWithFeedback: feedback.count,
            avgRPE: averageRPE(from: feedback),
            rpeTrend: rpeTrend(from: feedback),
            commonTags: commonTags(from: feedback),
            userNotes: feedback.compactMap { $0.freeText }.filter { !$0.isEmpty },
            avgCompletionPercentage: {
                let completions = feedback.compactMap { $0.completionPercentage }
                guard !completions.isEmpty else { return nil }
                return completions.reduce(0, +) / Double(completions.count)
            }()
        )
    }
}

// MARK: - Weekly Summary for AI

struct WeeklyFeedbackSummary: Codable {
    let workoutsWithFeedback: Int
    let avgRPE: Double?
    let rpeTrend: String
    let commonTags: [FeedbackTag]
    let userNotes: [String]
    let avgCompletionPercentage: Double?

    enum CodingKeys: String, CodingKey {
        case workoutsWithFeedback = "workouts_with_feedback"
        case avgRPE = "avg_rpe"
        case rpeTrend = "rpe_trend"
        case commonTags = "common_tags"
        case userNotes = "user_notes"
        case avgCompletionPercentage = "avg_completion_percentage"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(workoutsWithFeedback, forKey: .workoutsWithFeedback)
        try container.encodeIfPresent(avgRPE, forKey: .avgRPE)
        try container.encode(rpeTrend, forKey: .rpeTrend)
        try container.encode(commonTags.map { $0.rawValue }, forKey: .commonTags)
        try container.encode(userNotes, forKey: .userNotes)
        try container.encodeIfPresent(avgCompletionPercentage, forKey: .avgCompletionPercentage)
    }
}

// MARK: - Feedback Submit Result

struct FeedbackSubmitResult {
    let success: Bool
    let regenerationTriggered: Bool
    let regeneratedWeek: Int?
    let signal: String?
}

// MARK: - Regeneration Request (to Edge Function)

struct RegenerationRequest: Codable {
    let user_id: String
    let action: String
}

// MARK: - Regeneration Response (from Edge Function)

struct RegenerationResponse: Codable {
    let success: Bool
    let regenerated: Bool
    let reason: String?
    let signal: String?
    let weekRegenerated: Int?
    let workoutsCreated: Int?
    let workoutsFailed: Int?

    enum CodingKeys: String, CodingKey {
        case success
        case regenerated
        case reason
        case signal
        case weekRegenerated = "week_regenerated"
        case workoutsCreated = "workouts_created"
        case workoutsFailed = "workouts_failed"
    }
}
