// FLEXR - Supabase Service
// Handles all backend communication with Supabase

import Foundation
import Supabase

// MARK: - Supabase Configuration
// Using centralized Config

// MARK: - Supabase Client
@MainActor
class SupabaseService: ObservableObject {
    static let shared = SupabaseService()

    let client: SupabaseClient

    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: SupabaseError?

    private init() {
        self.client = SupabaseClient(
            supabaseURL: Config.Supabase.url,
            supabaseKey: Config.Supabase.anonKey
        )

        // Listen to auth state changes
        Task {
            for await state in client.auth.authStateChanges {
                await MainActor.run {
                    self.isAuthenticated = state.session != nil
                    if state.session != nil {
                        Task { await self.fetchCurrentUser() }
                    } else {
                        self.currentUser = nil
                    }
                }
            }
        }
    }

    // MARK: - Authentication

    /// Sign in with Apple
    func signInWithApple(idToken: String, nonce: String) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await client.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )

            // Check if user exists in our users table
            let userId = response.user.id
            let existingUser = try? await client
                .from("users")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value as User

            if existingUser == nil {
                // Create new user record
                try await createUserRecord(userId: userId, email: response.user.email)
            }

            await fetchCurrentUser()
        } catch {
            self.error = .authError(error.localizedDescription)
            throw error
        }
    }

    /// Sign out
    func signOut() async throws {
        try await client.auth.signOut()
        currentUser = nil
        isAuthenticated = false
    }

    /// Create user record in users table
    private func createUserRecord(userId: UUID, email: String?) async throws {
        let newUser = UserInsert(
            id: userId,
            email: email ?? "",
            trainingGoal: .trainStyle,
            experienceLevel: .intermediate
        )

        try await client
            .from("users")
            .insert(newUser)
            .execute()
    }

    /// Fetch current user data
    func fetchCurrentUser() async {
        guard let session = client.auth.currentSession else { return }

        do {
            let user: User = try await client
                .from("users")
                .select()
                .eq("id", value: session.user.id.uuidString)
                .single()
                .execute()
                .value

            self.currentUser = user
        } catch {
            print("Failed to fetch user: \(error)")
        }
    }

    // MARK: - Workouts

    /// Generate AI workout
    func generateWorkout(readinessScore: Int, workoutType: WorkoutType? = nil) async throws -> Workout {
        guard let userId = client.auth.currentSession?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        struct GenerateRequest: Encodable {
            let user_id: String
            let readiness_score: Int
            let workout_type: String?
        }

        let request = GenerateRequest(
            user_id: userId.uuidString,
            readiness_score: readinessScore,
            workout_type: workoutType?.rawValue
        )

        let response = try await client.functions.invoke(
            "generate-workout",
            options: .init(body: request)
        )

        struct GenerateResponse: Decodable {
            let success: Bool
            let workout: Workout
        }

        let result = try JSONDecoder().decode(GenerateResponse.self, from: response.data)

        if result.success {
            return result.workout
        } else {
            throw SupabaseError.functionError("Failed to generate workout")
        }
    }

    /// Fetch today's workout
    func fetchTodaysWorkout() async throws -> Workout? {
        guard let userId = client.auth.currentSession?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let workout: Workout? = try await client
            .from("workouts")
            .select("*, workout_segments(*)")
            .eq("user_id", value: userId.uuidString)
            .gte("scheduled_at", value: today.ISO8601Format())
            .lt("scheduled_at", value: tomorrow.ISO8601Format())
            .order("scheduled_at", ascending: true)
            .limit(1)
            .single()
            .execute()
            .value

        return workout
    }

    /// Fetch recent workouts
    func fetchRecentWorkouts(limit: Int = 10) async throws -> [Workout] {
        guard let userId = client.auth.currentSession?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let workouts: [Workout] = try await client
            .from("workouts")
            .select("*, workout_segments(*)")
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return workouts
    }

    /// Start workout
    func startWorkout(workoutId: UUID) async throws {
        try await client
            .from("workouts")
            .update(["status": "in_progress", "started_at": Date().ISO8601Format()])
            .eq("id", value: workoutId.uuidString)
            .execute()
    }

    /// Complete workout
    func completeWorkout(workoutId: UUID, rating: Int?, notes: String?) async throws {
        var updates: [String: AnyEncodable] = [
            "status": AnyEncodable("completed"),
            "completed_at": AnyEncodable(Date().ISO8601Format())
        ]

        if let rating = rating {
            updates["user_rating"] = AnyEncodable(rating)
        }
        if let notes = notes {
            updates["user_notes"] = AnyEncodable(notes)
        }

        try await client
            .from("workouts")
            .update(updates)
            .eq("id", value: workoutId.uuidString)
            .execute()
    }

    /// Update segment
    func updateSegment(_ segment: WorkoutSegment) async throws {
        try await client
            .from("workout_segments")
            .update(segment)
            .eq("id", value: segment.id.uuidString)
            .execute()
    }

    // MARK: - Performance Profile

    /// Fetch performance profile
    func fetchPerformanceProfile() async throws -> PerformanceProfile? {
        guard let userId = client.auth.currentSession?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let profile: PerformanceProfile? = try await client
            .from("performance_profiles")
            .select()
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value

        return profile
    }

    /// Trigger weekly learning update
    func triggerWeeklyLearning() async throws {
        guard let userId = client.auth.currentSession?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        struct LearningRequest: Encodable {
            let user_id: String
        }

        _ = try await client.functions.invoke(
            "weekly-learning",
            options: .init(body: LearningRequest(user_id: userId.uuidString))
        )
    }

    // MARK: - Insights

    /// Get AI insights
    func getInsights(type: InsightType) async throws -> Insight {
        guard let userId = client.auth.currentSession?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        struct InsightRequest: Encodable {
            let user_id: String
            let insight_type: String
        }

        let response = try await client.functions.invoke(
            "get-insights",
            options: .init(body: InsightRequest(
                user_id: userId.uuidString,
                insight_type: type.rawValue
            ))
        )

        struct InsightResponse: Decodable {
            let success: Bool
            let insight: Insight
        }

        let result = try JSONDecoder().decode(InsightResponse.self, from: response.data)
        return result.insight
    }

    // MARK: - Training Architecture

    /// Save training architecture
    func saveTrainingArchitecture(_ architecture: TrainingArchitecture) async throws {
        guard let userId = client.auth.currentSession?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        var architectureToSave = architecture
        architectureToSave.userId = userId

        // Deactivate other architectures first
        try await client
            .from("training_architectures")
            .update(["is_active": false])
            .eq("user_id", value: userId.uuidString)
            .execute()

        // Insert new one
        try await client
            .from("training_architectures")
            .insert(architectureToSave)
            .execute()
    }

    /// Fetch active training architecture
    func fetchActiveArchitecture() async throws -> TrainingArchitecture? {
        guard let userId = client.auth.currentSession?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let architecture: TrainingArchitecture? = try await client
            .from("training_architectures")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("is_active", value: true)
            .single()
            .execute()
            .value

        return architecture
    }

    // MARK: - Custom Workouts (BYOP)

    /// Create custom workout template
    func createCustomTemplate(_ template: CustomWorkoutTemplate) async throws {
        guard let userId = client.auth.currentSession?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        var templateToSave = template
        templateToSave.userId = userId

        try await client
            .from("custom_workout_templates")
            .insert(templateToSave)
            .execute()
    }

    /// Fetch user's custom templates
    func fetchCustomTemplates() async throws -> [CustomWorkoutTemplate] {
        guard let userId = client.auth.currentSession?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let templates: [CustomWorkoutTemplate] = try await client
            .from("custom_workout_templates")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return templates
    }

    /// Start workout from custom template
    func startWorkoutFromTemplate(_ templateId: UUID) async throws -> Workout {
        guard let userId = client.auth.currentSession?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        // Fetch template
        let template: CustomWorkoutTemplate = try await client
            .from("custom_workout_templates")
            .select()
            .eq("id", value: templateId.uuidString)
            .single()
            .execute()
            .value

        // Create workout from template
        let workout = WorkoutInsert(
            userId: userId,
            name: template.name,
            description: template.description,
            workoutType: .custom,
            status: .planned,
            estimatedDurationMinutes: template.estimatedDurationMinutes,
            difficulty: template.difficulty,
            isCustom: true,
            templateId: templateId
        )

        let savedWorkout: Workout = try await client
            .from("workouts")
            .insert(workout)
            .select()
            .single()
            .execute()
            .value

        // Create segments from template
        let segments = template.segments.enumerated().map { index, seg in
            WorkoutSegmentInsert(
                workoutId: savedWorkout.id,
                segmentType: seg.segmentType,
                stationType: seg.stationType,
                orderIndex: index,
                targetDurationSeconds: seg.targetDurationSeconds,
                targetDistanceMeters: seg.targetDistanceMeters,
                targetReps: seg.targetReps
            )
        }

        try await client
            .from("workout_segments")
            .insert(segments)
            .execute()

        // Increment times_used
        try await client.rpc(
            "increment_template_usage",
            params: ["template_id": templateId.uuidString]
        ).execute()

        return savedWorkout
    }

    // MARK: - Device Tokens

    /// Register device token for push notifications
    func registerDeviceToken(_ token: String) async throws {
        guard let userId = client.auth.currentSession?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        // Get current tokens
        let user: User = try await client
            .from("users")
            .select("device_tokens")
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value

        var tokens = user.deviceTokens ?? []
        if !tokens.contains(token) {
            tokens.append(token)

            try await client
                .from("users")
                .update(["device_tokens": tokens])
                .eq("id", value: userId.uuidString)
                .execute()
        }
    }
}

// MARK: - Error Types
enum SupabaseError: Error, LocalizedError {
    case notAuthenticated
    case authError(String)
    case functionError(String)
    case databaseError(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to perform this action"
        case .authError(let message):
            return "Authentication error: \(message)"
        case .functionError(let message):
            return "Function error: \(message)"
        case .databaseError(let message):
            return "Database error: \(message)"
        }
    }
}

// MARK: - Supporting Types
enum InsightType: String, Codable {
    case weeklySummary = "weekly_summary"
    case trainingBalance = "training_balance"
    case raceReadiness = "race_readiness"
    case recovery = "recovery"
    case compromisedRunning = "compromised_running"
}

struct Insight: Codable {
    let headline: String
    let summary: String
    let details: [String]
    let recommendations: [Recommendation]
    let metricsHighlight: MetricHighlight?

    struct Recommendation: Codable {
        let action: String
        let reason: String
        let priority: String
    }

    struct MetricHighlight: Codable {
        let label: String
        let value: String
        let trend: String
        let isPositive: Bool

        enum CodingKeys: String, CodingKey {
            case label, value, trend
            case isPositive = "is_positive"
        }
    }

    enum CodingKeys: String, CodingKey {
        case headline, summary, details, recommendations
        case metricsHighlight = "metrics_highlight"
    }
}

// MARK: - Insert Types (for creating records)
struct UserInsert: Encodable {
    let id: UUID
    let email: String
    let trainingGoal: TrainingGoal
    let experienceLevel: ExperienceLevel

    enum CodingKeys: String, CodingKey {
        case id, email
        case trainingGoal = "training_goal"
        case experienceLevel = "experience_level"
    }
}

struct WorkoutInsert: Encodable {
    let userId: UUID
    let name: String
    let description: String?
    let workoutType: WorkoutType
    let status: WorkoutStatus
    let estimatedDurationMinutes: Int?
    let difficulty: WorkoutDifficulty?
    let isCustom: Bool
    let templateId: UUID?

    enum CodingKeys: String, CodingKey {
        case name, description, status, difficulty
        case userId = "user_id"
        case workoutType = "workout_type"
        case estimatedDurationMinutes = "estimated_duration_minutes"
        case isCustom = "is_custom"
        case templateId = "template_id"
    }
}

struct WorkoutSegmentInsert: Encodable {
    let workoutId: UUID
    let segmentType: SegmentType
    let stationType: StationType?
    let orderIndex: Int
    let targetDurationSeconds: Int?
    let targetDistanceMeters: Int?
    let targetReps: Int?

    enum CodingKeys: String, CodingKey {
        case workoutId = "workout_id"
        case segmentType = "segment_type"
        case stationType = "station_type"
        case orderIndex = "order_index"
        case targetDurationSeconds = "target_duration_seconds"
        case targetDistanceMeters = "target_distance_meters"
        case targetReps = "target_reps"
    }
}

// MARK: - AnyEncodable Helper
struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        _encode = { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
