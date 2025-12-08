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
                .database.from("users")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value as User

            if existingUser == nil {
                // Create new user record
                do {
                    try await createUserRecord(userId: userId, email: response.user.email)
                    print("✅ User record created successfully for: \(userId)")
                } catch {
                    print("❌ Failed to create user record: \(error)")
                    throw error
                }
            } else {
                print("ℹ️ User already exists: \(userId)")
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
            appleUserId: userId.uuidString, // Use UUID as apple_user_id
            email: email ?? ""
        )

        try await client
            .database.from("users")
            .insert(newUser)
            .execute()
    }

    /// Fetch current user data
    func fetchCurrentUser() async {
        guard let session = try? await client.auth.session else { return }

        do {
            let user: User = try await client
                .database.from("users")
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

    /// Update user preferences in Supabase
    func updateUser(_ user: User) async throws {
        print("SupabaseService.updateUser: Updating user \(user.id)")

        // Create update payload with only the fields that can be updated
        struct UserUpdate: Encodable {
            let training_goal: String
            let race_date: String?
            let experience_level: String
            let training_preferences: UserTrainingPreferences

            enum CodingKeys: String, CodingKey {
                case training_goal
                case race_date
                case experience_level
                case training_preferences
            }
        }

        let update = UserUpdate(
            training_goal: user.trainingGoal.rawValue,
            race_date: user.raceDate?.ISO8601Format(),
            experience_level: user.experienceLevel.rawValue,
            training_preferences: user.trainingPreferences
        )

        try await client
            .database.from("users")
            .update(update)
            .eq("id", value: user.id.uuidString)
            .execute()

        print("SupabaseService.updateUser: User updated successfully")

        // Update local cached user
        self.currentUser = user
    }

    // MARK: - Workouts

    /// Generate quick workout for ad-hoc sessions
    /// Returns workout with sections for proper UI grouping
    func generateQuickWorkout(
        workoutType: String,
        readinessScore: Int,
        targetDurationMinutes: Int? = nil,
        focusStations: [String]? = nil,
        strengthFocus: String? = nil
    ) async throws -> Workout {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        struct GenerateRequest: Encodable {
            let user_id: String
            let readiness_score: Int
            let workout_type: String
            let target_duration_minutes: Int?
            let focus_stations: [String]?
            let strength_focus: String?
        }

        let request = GenerateRequest(
            user_id: userId.uuidString,
            readiness_score: readinessScore,
            workout_type: workoutType,
            target_duration_minutes: targetDurationMinutes,
            focus_stations: focusStations,
            strength_focus: strengthFocus
        )

        // Response - just get workout ID, we'll reconstruct sections from DB
        struct GenerateResponse: Decodable {
            let success: Bool
            let workout: WorkoutRef?
            let error: String?

            struct WorkoutRef: Decodable {
                let id: UUID
            }
        }

        let result: GenerateResponse = try await client.functions.invoke(
            "generate-workout",
            options: .init(body: request)
        )

        guard result.success, let workoutRef = result.workout else {
            throw SupabaseError.functionError(result.error ?? "Failed to generate workout")
        }

        // Fetch the complete workout with segments from DB
        let workout: Workout = try await client
            .from("workouts")
            .select("*, workout_segments(*)")
            .eq("id", value: workoutRef.id.uuidString)
            .single()
            .execute()
            .value

        // Reconstruct sections from segments if they have section metadata
        var workoutWithSections = workout
        workoutWithSections.sections = reconstructSections(from: workout.segments, metadata: workout.sectionsMetadata)

        return workoutWithSections
    }

    /// Schedule a workout for today by creating a planned_workout entry
    /// This ensures it shows up alongside AI-planned workouts
    func scheduleWorkoutForToday(_ workoutId: UUID) async throws {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        // First, fetch the workout details
        let workout: Workout = try await client
            .from("workouts")
            .select("*, workout_segments(*)")
            .eq("id", value: workoutId.uuidString)
            .single()
            .execute()
            .value

        let today = Calendar.current.startOfDay(for: Date())

        // Count existing sessions for today to set session_number
        let existingCount: Int = try await client
            .from("planned_workouts")
            .select("id", head: true, count: .exact)
            .eq("user_id", value: userId.uuidString)
            .gte("scheduled_date", value: today.ISO8601Format())
            .lt("scheduled_date", value: Calendar.current.date(byAdding: .day, value: 1, to: today)!.ISO8601Format())
            .execute()
            .count ?? 0

        // Create planned_workout entry
        struct PlannedWorkoutInsert: Encodable {
            let user_id: String
            let name: String
            let description: String?
            let workout_type: String
            let scheduled_date: String
            let session_number: Int
            let estimated_duration: Int
            let intensity: String
            let status: String
            let ai_explanation: String?
        }

        let insert = PlannedWorkoutInsert(
            user_id: userId.uuidString,
            name: workout.type.displayName,
            description: "Quick workout - \(workout.type.displayName)",
            workout_type: workout.type.rawValue,
            scheduled_date: today.ISO8601Format(),
            session_number: existingCount + 1,
            estimated_duration: Int((workout.totalDuration ?? 1800) / 60), // Convert to minutes
            intensity: "moderate",
            status: "planned",
            ai_explanation: workout.notes ?? "AI-generated quick workout based on your readiness and preferences."
        )

        // Insert the planned workout
        struct InsertedWorkout: Decodable {
            let id: UUID
        }

        let inserted: InsertedWorkout = try await client
            .from("planned_workouts")
            .insert(insert)
            .select("id")
            .single()
            .execute()
            .value

        // Now insert the segments
        if !workout.segments.isEmpty {
            struct SegmentInsert: Encodable {
                let planned_workout_id: String
                let segment_type: String
                let station_type: String?
                let order_index: Int
                let name: String
                let instructions: String
                let target_duration_seconds: Int?
                let target_distance_meters: Int?
                let target_reps: Int?
                let target_pace: String?
            }

            let segmentInserts = workout.segments.enumerated().map { index, seg in
                // Generate name and instructions from segment info
                let segmentName: String
                let segmentInstructions: String

                if let stationType = seg.stationType {
                    segmentName = stationType.displayName
                    segmentInstructions = "Complete \(seg.targetDescription)"
                } else {
                    segmentName = seg.segmentType.displayName
                    switch seg.segmentType {
                    case .run:
                        segmentInstructions = "Run \(seg.targetDescription)"
                    case .warmup:
                        segmentInstructions = "Warm up for \(seg.targetDescription)"
                    case .cooldown:
                        segmentInstructions = "Cool down for \(seg.targetDescription)"
                    case .rest:
                        segmentInstructions = "Rest for \(seg.targetDescription)"
                    default:
                        segmentInstructions = "Complete \(seg.targetDescription)"
                    }
                }

                return SegmentInsert(
                    planned_workout_id: inserted.id.uuidString,
                    segment_type: seg.segmentType.rawValue,
                    station_type: seg.stationType?.rawValue,
                    order_index: index,
                    name: segmentName,
                    instructions: segmentInstructions,
                    target_duration_seconds: seg.targetDuration.map { Int($0) },
                    target_distance_meters: seg.targetDistance.map { Int($0) },
                    target_reps: seg.targetReps,
                    target_pace: seg.targetPace
                )
            }

            try await client
                .from("planned_workout_segments")
                .insert(segmentInserts)
                .execute()
        }
    }

    /// Fetch today's workout
    func fetchTodaysWorkout() async throws -> Workout? {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let workout: Workout? = try await client
            .database.from("workouts")
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
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let workouts: [Workout] = try await client
            .database.from("workouts")
            .select("*, workout_segments(*)")
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        // Decode route data for workouts that have it
        return workouts.map { workout in
            var mutableWorkout = workout

            // TODO: Implement route data deserialization when Workout model supports it
            // This will require updates to the Workout model to include route data fields

            return mutableWorkout
        }
    }

    /// Get full workout history for analytics
    /// Fetches all completed workouts with their segments
    func getWorkoutHistory(limit: Int = 100) async throws -> [Workout] {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let workouts: [Workout] = try await client
            .database.from("workouts")
            .select("*, segments:workout_segments(*)")
            .eq("user_id", value: userId.uuidString)
            .eq("status", value: "completed")
            .order("completed_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return workouts
    }

    /// Start workout
    func startWorkout(workoutId: UUID) async throws {
        try await client
            .database.from("workouts")
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
            .database.from("workouts")
            .update(updates)
            .eq("id", value: workoutId.uuidString)
            .execute()
    }

    /// Update segment
    func updateSegment(_ segment: WorkoutSegment) async throws {
        try await client
            .database.from("workout_segments")
            .update(segment)
            .eq("id", value: segment.id.uuidString)
            .execute()
    }

    /// Save workout summary from Apple Watch
    func saveWorkoutSummary(_ summary: WorkoutSummary) async throws {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        // Serialize route data as JSON if available
        var routeDataJson: String? = nil
        if let routeData = summary.routeData {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            if let jsonData = try? encoder.encode(routeData),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                routeDataJson = jsonString
                print("📍 Route data serialized: \(routeData.coordinates.count) coordinates")
            }
        }

        // Extract elevation metrics
        let elevationGain = summary.routeData?.elevationGain
        let elevationLoss = summary.routeData?.elevationLoss

        // Create workout record with route data
        struct CompletedWorkoutInsert: Encodable {
            let user_id: String
            let workout_name: String
            let workout_date: String
            let total_duration_seconds: Double
            let total_distance_meters: Double
            let active_calories: Int
            let average_heart_rate: Int
            let max_heart_rate: Int
            let segments_completed: Int
            let total_segments: Int
            let status: String
            let completed_at: String
            let route_data: String?
            let gps_source: String?
            let elevation_gain: Double?
            let elevation_loss: Double?
        }

        let workoutInsert = CompletedWorkoutInsert(
            user_id: userId.uuidString,
            workout_name: summary.workoutName,
            workout_date: Date().ISO8601Format(),
            total_duration_seconds: summary.totalTime,
            total_distance_meters: summary.totalDistance,
            active_calories: summary.activeCalories,
            average_heart_rate: summary.averageHeartRate,
            max_heart_rate: summary.maxHeartRate,
            segments_completed: summary.segmentsCompleted,
            total_segments: summary.totalSegments,
            status: "completed",
            completed_at: Date().ISO8601Format(),
            route_data: routeDataJson,
            gps_source: nil,
            elevation_gain: elevationGain,
            elevation_loss: elevationLoss
        )

        // Insert workout
        try await client
            .database.from("completed_workouts")
            .insert(workoutInsert)
            .execute()

        if routeDataJson != nil {
            print("✅ Workout with route data saved to Supabase: \(summary.workoutName)")
        } else {
            print("✅ Workout summary saved to Supabase: \(summary.workoutName)")
        }
    }

    // MARK: - Performance Profile

    /// Fetch performance profile
    func fetchPerformanceProfile() async throws -> PerformanceProfile? {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let profile: PerformanceProfile? = try await client
            .database.from("performance_profiles")
            .select()
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value

        return profile
    }

    /// Trigger weekly learning update
    func triggerWeeklyLearning() async throws {
        guard let userId = (try? await client.auth.session)?.user.id else {
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
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        struct InsightRequest: Encodable {
            let user_id: String
            let insight_type: String
        }

        struct InsightResponse: Decodable {
            let success: Bool
            let insight: Insight
        }

        let result: InsightResponse = try await client.functions.invoke(
            "get-insights",
            options: .init(body: InsightRequest(
                user_id: userId.uuidString,
                insight_type: type.rawValue
            ))
        )

        return result.insight
    }

    // MARK: - Training Architecture

    /// Save training architecture
    func saveTrainingArchitecture(_ architecture: TrainingArchitecture) async throws {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        var architectureToSave = architecture
        architectureToSave.userId = userId

        // Deactivate other architectures first
        try await client
            .database.from("training_architectures")
            .update(["is_active": false])
            .eq("user_id", value: userId.uuidString)
            .execute()

        // Insert new one
        try await client
            .database.from("training_architectures")
            .insert(architectureToSave)
            .execute()
    }

    /// Fetch active training architecture
    func fetchActiveArchitecture() async throws -> TrainingArchitecture? {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let architecture: TrainingArchitecture? = try await client
            .database.from("training_architectures")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("is_active", value: true)
            .single()
            .execute()
            .value

        return architecture
    }

    // MARK: - Training Plan Generation

    /// Generate training plan using Grok AI
    func generateTrainingPlan(for userId: UUID, onboardingData: OnboardingData) async throws {
        let url = "\(Config.Supabase.url.absoluteString)/functions/v1/generate-training-plan"

        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Config.Supabase.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120 // 2 minutes for AI generation

        // Build request payload matching Edge Function schema
        var payload: [String: Any] = [
            "user_id": userId.uuidString,
            "goal": onboardingData.primaryGoal?.rawValue ?? "train_style",
            "race_date": onboardingData.raceDate?.ISO8601Format() as Any,
            "target_time": onboardingData.targetTime?.displayName as Any,
            "days_per_week": onboardingData.daysPerWeek,
            "sessions_per_day": onboardingData.sessionsPerDay.rawValue,
            "preferred_types": onboardingData.preferredWorkoutTypes.map { $0.rawValue },
            "session_duration": onboardingData.preferredWorkoutDuration?.minutes ?? 60,
            "experience_level": onboardingData.fitnessLevel,
            "equipment": ["full_gym"], // For now, assume full gym
            "fitness_background": onboardingData.trainingBackground?.rawValue as Any
        ]

        // Add program start date if set
        if let startDate = onboardingData.programStartDate {
            payload["program_start_date"] = startDate.ISO8601Format()
        }

        // Add preferred recovery day for 6+ days/week
        if onboardingData.daysPerWeek >= 6 {
            payload["preferred_recovery_day"] = onboardingData.preferredRecoveryDay.rawValue
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        print("🎯 Calling generate-training-plan function...")
        print("📤 Request URL: \(url)")
        print("📤 Payload: \(payload)")

        // Create custom URLSession with timeout for AI generation
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120 // 2 minutes for AI generation
        config.timeoutIntervalForResource = 120
        let session = URLSession(configuration: config)

        do {
            print("⏱️ Waiting for response (timeout: 120s)...")
            let (data, response) = try await session.data(for: request)
            print("📥 Received response!")

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                throw SupabaseError.functionError("Invalid response")
            }

            print("📥 Response status: \(httpResponse.statusCode)")
            let responseText = String(data: data, encoding: .utf8) ?? "No response body"
            print("📥 Response body: \(responseText)")

            if httpResponse.statusCode != 200 {
                print("❌ Plan generation failed with status \(httpResponse.statusCode)")
                throw SupabaseError.functionError("Plan generation failed: \(httpResponse.statusCode) - \(responseText)")
            }

            print("✅ Training plan generated successfully!")
        } catch {
            print("❌ Plan generation error: \(error)")
            throw error
        }
    }

    // MARK: - Onboarding

    /// Submit onboarding data
    func submitOnboardingData(_ data: OnboardingData) async throws {
        guard let session = try? await client.auth.session else {
            throw SupabaseError.notAuthenticated
        }

        let userId = session.user.id
        print("📝 Submitting onboarding for user: \(userId)")

        // Ensure user record exists (create if missing)
        // Check if user exists by selecting only the ID to avoid decoding errors
        do {
            struct UserIdCheck: Decodable {
                let id: UUID
            }

            let _: UserIdCheck = try await client
                .database.from("users")
                .select("id")
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            print("ℹ️ User record exists")
        } catch {
            // Check if it's a "no results" error (user doesn't exist) or a duplicate key error (user exists)
            let errorString = String(describing: error)
            if errorString.contains("PGRST116") {
                // User doesn't exist - create it
                print("⚠️ User record missing, creating now...")
                do {
                    try await createUserRecord(userId: userId, email: session.user.email)
                    print("✅ User record created for: \(userId)")
                } catch {
                    // If duplicate key error, user was created by another process - that's OK
                    let createErrorString = String(describing: error)
                    if !createErrorString.contains("23505") {
                        print("❌ Failed to create user record: \(error)")
                        throw error
                    }
                    print("ℹ️ User record already exists (created by another process)")
                }
            } else {
                // Some other error - log but continue (user likely exists with NULL fields)
                print("⚠️ User check error (likely exists with NULL fields): \(error)")
            }
        }

        // Prepare user updates
        var updates: [String: AnyEncodable] = [:]

        if let age = data.age {
            updates["age"] = AnyEncodable(age)
        }
        if let weight = data.weight {
            updates["weight_kg"] = AnyEncodable(weight)
        }
        if let height = data.height {
            updates["height_cm"] = AnyEncodable(height)
        }
        updates["gender"] = AnyEncodable(data.gender.rawValue)

        if let background = data.trainingBackground {
            updates["training_background"] = AnyEncodable(background.rawValue)
        }
        if let goal = data.primaryGoal {
            updates["primary_goal"] = AnyEncodable(goal.rawValue)
        }
        if let raceDate = data.raceDate {
            updates["race_date"] = AnyEncodable(raceDate.ISO8601Format())
        }
        if let targetTime = data.targetTime {
            updates["target_time_seconds"] = AnyEncodable(targetTime.seconds)
        }
        if let weeks = data.weeksToRace {
            updates["weeks_to_race"] = AnyEncodable(weeks)
        }
        updates["just_finished_race"] = AnyEncodable(data.justFinishedRace)
        updates["days_per_week"] = AnyEncodable(data.daysPerWeek)
        updates["sessions_per_day"] = AnyEncodable(data.sessionsPerDay.rawValue)
        updates["preferred_time"] = AnyEncodable(data.preferredTime.rawValue)

        if let location = data.equipmentLocation {
            updates["equipment_location"] = AnyEncodable(location.rawValue)
        }
        updates["onboarding_completed_at"] = AnyEncodable(Date().ISO8601Format())

        // Update user record
        try await client
            .database.from("users")
            .update(updates)
            .eq("id", value: userId.uuidString)
            .execute()

        // Save performance benchmarks if provided
        if data.running1kmSeconds != nil || data.running5kmSeconds != nil || data.comfortableZ2Pace != nil {
            print("💪 Saving performance benchmarks for user: \(userId)")
            do {
                try await saveBenchmarks(userId: userId, data: data)
                print("✅ Benchmarks saved successfully")
            } catch {
                print("❌ Failed to save benchmarks: \(error)")
                throw error
            }
        }

        // Save equipment access
        if let location = data.equipmentLocation {
            print("🏋️ Saving equipment access for user: \(userId)")
            do {
                try await saveEquipmentAccess(userId: userId, location: location, homeEquipment: data.homeGymEquipment)
                print("✅ Equipment saved successfully")
            } catch {
                print("❌ Failed to save equipment: \(error)")
                throw error
            }
        }

        // Refresh current user
        await fetchCurrentUser()
    }

    /// Save performance benchmarks
    private func saveBenchmarks(userId: UUID, data: OnboardingData) async throws {
        struct BenchmarkInsert: Encodable {
            let user_id: String
            let running_1km_seconds: Double?
            let running_5km_seconds: Double?
            let running_zone2_pace_seconds: Double?
            let source: String
        }

        let benchmark = BenchmarkInsert(
            user_id: userId.uuidString,
            running_1km_seconds: data.running1kmSeconds,
            running_5km_seconds: data.running5kmSeconds,
            running_zone2_pace_seconds: data.comfortableZ2Pace,
            source: "user_input"
        )

        try await client
            .database.from("user_performance_benchmarks")
            .insert(benchmark)
            .execute()
    }

    /// Save equipment access
    private func saveEquipmentAccess(userId: UUID, location: OnboardingData.EquipmentLocation, homeEquipment: Set<OnboardingData.HomeEquipment>) async throws {
        struct EquipmentInsert: Encodable {
            let user_id: String
            let location_type: String
            let has_rower: Bool
            let has_skierg: Bool
            let has_barbell: Bool
            let has_dumbbells: Bool
            let has_kettlebells: Bool
            let has_pullup_bar: Bool
            let has_resistance_bands: Bool
        }

        // Smart defaults based on location
        var equipment = EquipmentInsert(
            user_id: userId.uuidString,
            location_type: location.rawValue,
            has_rower: false,
            has_skierg: false,
            has_barbell: false,
            has_dumbbells: false,
            has_kettlebells: false,
            has_pullup_bar: false,
            has_resistance_bands: false
        )

        // Apply smart defaults
        switch location {
        case .hyroxGym, .crossfitGym:
            equipment = EquipmentInsert(
                user_id: userId.uuidString,
                location_type: location.rawValue,
                has_rower: true,
                has_skierg: true,
                has_barbell: true,
                has_dumbbells: true,
                has_kettlebells: true,
                has_pullup_bar: true,
                has_resistance_bands: true
            )
        case .commercialGym:
            equipment = EquipmentInsert(
                user_id: userId.uuidString,
                location_type: location.rawValue,
                has_rower: true,
                has_skierg: false,
                has_barbell: true,
                has_dumbbells: true,
                has_kettlebells: true,
                has_pullup_bar: true,
                has_resistance_bands: false
            )
        case .homeGym:
            // Use user-selected equipment
            equipment = EquipmentInsert(
                user_id: userId.uuidString,
                location_type: location.rawValue,
                has_rower: homeEquipment.contains(.rower),
                has_skierg: homeEquipment.contains(.skierg),
                has_barbell: homeEquipment.contains(.barbell),
                has_dumbbells: homeEquipment.contains(.dumbbells),
                has_kettlebells: homeEquipment.contains(.kettlebells),
                has_pullup_bar: homeEquipment.contains(.pullupBar),
                has_resistance_bands: homeEquipment.contains(.resistanceBands)
            )
        case .minimal:
            // Bodyweight only
            equipment = EquipmentInsert(
                user_id: userId.uuidString,
                location_type: location.rawValue,
                has_rower: false,
                has_skierg: false,
                has_barbell: false,
                has_dumbbells: false,
                has_kettlebells: false,
                has_pullup_bar: false,
                has_resistance_bands: true
            )
        }

        try await client
            .database.from("user_equipment_access")
            .insert(equipment)
            .execute()
    }

    // MARK: - Device Tokens

    /// Register device token for push notifications
    func registerDeviceToken(_ token: String) async throws {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        // Get current tokens
        let user: User = try await client
            .database.from("users")
            .select("device_tokens")
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value

        var tokens = user.deviceTokens ?? []
        if !tokens.contains(token) {
            tokens.append(token)

            try await client
                .database.from("users")
                .update(["device_tokens": tokens])
                .eq("id", value: userId.uuidString)
                .execute()
        }
    }

    // MARK: - Section Reconstruction

    /// Reconstruct WorkoutSections from segments that have section metadata
    /// Uses metadata from workout.sectionsMetadata for format details
    private func reconstructSections(from segments: [WorkoutSegment], metadata: [SectionMetadata]?) -> [WorkoutSection]? {
        // Group segments by section type
        var sectionGroups: [String: [WorkoutSegment]] = [:]
        var sectionOrder: [String] = []

        for segment in segments {
            guard let sectionType = segment.sectionType else {
                // No section metadata - can't reconstruct
                return nil
            }

            if sectionGroups[sectionType] == nil {
                sectionGroups[sectionType] = []
                sectionOrder.append(sectionType)
            }

            sectionGroups[sectionType]?.append(segment)
        }

        // If no section metadata found, return nil
        guard !sectionOrder.isEmpty else { return nil }

        // Build a lookup for metadata by type
        var metadataLookup: [String: SectionMetadata] = [:]
        if let metadata = metadata {
            for meta in metadata {
                metadataLookup[meta.type.rawValue] = meta
            }
        }

        // Build sections in order
        var sections: [WorkoutSection] = []

        for sectionTypeStr in sectionOrder {
            guard let segmentsForSection = sectionGroups[sectionTypeStr],
                  let sectionType = SectionType(rawValue: sectionTypeStr) else {
                continue
            }

            // Get format info from metadata if available
            let meta = metadataLookup[sectionTypeStr]
            let label = meta?.label ?? segmentsForSection.first?.sectionLabel ?? sectionType.displayName
            let wodFormat = meta?.format ?? segmentsForSection.first?.sectionFormat.flatMap { WODFormat(rawValue: $0) }
            let formatDetails = meta?.formatDetails

            let section = WorkoutSection(
                type: sectionType,
                label: label,
                format: wodFormat,
                formatDetails: formatDetails,
                segments: segmentsForSection
            )

            sections.append(section)
        }

        return sections.isEmpty ? nil : sections
    }
}

// MARK: - Error Types
enum SupabaseError: Error, LocalizedError {
    case notAuthenticated
    case authError(String)
    case functionError(String)
    case databaseError(String)
    case racePartnerLimitReached

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
        case .racePartnerLimitReached:
            return "You can only have one race partner. Remove your current partner first to link with someone new."
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
    let appleUserId: String
    let email: String

    enum CodingKeys: String, CodingKey {
        case id
        case appleUserId = "apple_user_id"
        case email
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

// MARK: - Running Sessions extension
extension SupabaseService {

    /// Get recent running sessions
    func getRunningSessions(limit: Int = 10) async throws -> [RunningSession] {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let sessions: [RunningSession] = try await client
            .database.from("running_sessions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("started_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return sessions
    }

    /// Get gym activity feed
    func getGymActivityFeed(gymId: UUID, limit: Int = 50) async throws -> [ActivityFeedItem] {
        let feed: [ActivityFeedItem] = try await client
            .database.from("activity_feed")
            .select("*, user:users(*), gym:gyms(*)")
            .eq("gym_id", value: gymId.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return feed
    }

    // MARK: - Station Analytics

    /// Get station performance history from workout segments
    func getStationPerformances(stationName: String? = nil, limit: Int = 100) async throws -> [SegmentPerformanceDTO] {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        // Query workout_segments joined with workouts
        // Filter for completed station segments
        var query = client
            .from("workout_segments")
            .select("*, workout:workouts!inner(id, completed_at, type, user_id)")

        // Apply filters
        if let stationName = stationName {
            let segments: [SegmentPerformanceDTO] = try await query
                .eq("workout.user_id", value: userId.uuidString)
                .eq("type", value: "station")
                .eq("completion_status", value: "completed")
                .eq("name", value: stationName)
                .order("workout.completed_at", ascending: false)
                .limit(limit)
                .execute()
                .value
            return segments
        } else {
            let segments: [SegmentPerformanceDTO] = try await query
                .eq("workout.user_id", value: userId.uuidString)
                .eq("type", value: "station")
                .eq("completion_status", value: "completed")
                .order("workout.completed_at", ascending: false)
                .limit(limit)
                .execute()
                .value
            return segments
        }
    }

    /// Get aggregated station statistics
    func getStationStats() async throws -> [StationStatsDTO] {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        // Get all station segments for this user
        let segments: [SegmentPerformanceDTO] = try await client
            .from("workout_segments")
            .select("*, workout:workouts!inner(id, completed_at, type, user_id)")
            .eq("workout.user_id", value: userId.uuidString)
            .eq("type", value: "station")
            .eq("completion_status", value: "completed")
            .order("workout.completed_at", ascending: false)
            .execute()
            .value

        // Group by station name and compute stats
        let grouped = Dictionary(grouping: segments) { $0.name }

        var stats: [StationStatsDTO] = []
        for (stationName, stationSegments) in grouped {
            let durations = stationSegments.compactMap { $0.actualDurationMinutes }
            guard !durations.isEmpty else { continue }

            let avgDuration = durations.reduce(0, +) / Double(durations.count)
            let bestDuration = durations.min() ?? 0

            // Calculate trend (compare last 5 vs previous 5)
            let sortedDurations = stationSegments
                .sorted { ($0.workout?.completedAt ?? Date()) > ($1.workout?.completedAt ?? Date()) }
                .compactMap { $0.actualDurationMinutes }

            var trendPercent: Double = 0
            if sortedDurations.count >= 10 {
                let recent = Array(sortedDurations.prefix(5)).reduce(0, +) / 5
                let previous = Array(sortedDurations.dropFirst(5).prefix(5)).reduce(0, +) / 5
                if previous > 0 {
                    trendPercent = ((previous - recent) / previous) * 100 // Positive = improving
                }
            }

            stats.append(StationStatsDTO(
                stationName: stationName,
                totalPerformances: stationSegments.count,
                avgDurationMinutes: avgDuration,
                bestDurationMinutes: bestDuration,
                trendPercent: trendPercent
            ))
        }

        return stats.sorted { $0.stationName < $1.stationName }
    }

    // MARK: - Heart Rate Analytics

    /// Get heart rate statistics from workouts
    func getHeartRateStats(days: Int = 30) async throws -> HeartRateStatsDTO {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        // Get workouts with HR data
        let workouts: [Workout] = try await client
            .from("workouts")
            .select("*, segments:workout_segments(*)")
            .eq("user_id", value: userId.uuidString)
            .gte("completed_at", value: ISO8601DateFormatter().string(from: cutoffDate))
            .order("completed_at", ascending: false)
            .execute()
            .value

        // Aggregate HR stats
        var avgHRs: [Double] = []
        var maxHRs: [Double] = []

        for workout in workouts {
            if let avgHR = workout.averageHeartRate {
                avgHRs.append(avgHR)
            }
            if let maxHR = workout.maxHeartRate {
                maxHRs.append(maxHR)
            }
        }

        // Get running sessions for zone data
        let runningSessions = try await getRunningSessions(limit: 100)
        let recentSessions = runningSessions.filter {
            ($0.startedAt ?? $0.createdAt) >= cutoffDate
        }

        // Aggregate zone time
        var zone1Total: TimeInterval = 0
        var zone2Total: TimeInterval = 0
        var zone3Total: TimeInterval = 0
        var zone4Total: TimeInterval = 0
        var zone5Total: TimeInterval = 0

        for session in recentSessions {
            if let zones = session.heartRateZones {
                zone1Total += zones.zone1Seconds
                zone2Total += zones.zone2Seconds
                zone3Total += zones.zone3Seconds
                zone4Total += zones.zone4Seconds
                zone5Total += zones.zone5Seconds
            }
        }

        let totalZoneTime = zone1Total + zone2Total + zone3Total + zone4Total + zone5Total

        return HeartRateStatsDTO(
            avgHeartRate: avgHRs.isEmpty ? nil : avgHRs.reduce(0, +) / Double(avgHRs.count),
            maxHeartRate: maxHRs.max(),
            workoutCount: workouts.count,
            zone1Percent: totalZoneTime > 0 ? (zone1Total / totalZoneTime) * 100 : 0,
            zone2Percent: totalZoneTime > 0 ? (zone2Total / totalZoneTime) * 100 : 0,
            zone3Percent: totalZoneTime > 0 ? (zone3Total / totalZoneTime) * 100 : 0,
            zone4Percent: totalZoneTime > 0 ? (zone4Total / totalZoneTime) * 100 : 0,
            zone5Percent: totalZoneTime > 0 ? (zone5Total / totalZoneTime) * 100 : 0
        )
    }
}

// MARK: - Analytics DTOs

struct SegmentPerformanceDTO: Codable {
    let id: UUID
    let name: String
    let type: String
    let actualDurationMinutes: Double?
    let completionStatus: String?
    let workout: WorkoutRefDTO?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case actualDurationMinutes = "actual_duration_minutes"
        case completionStatus = "completion_status"
        case workout
    }
}

struct WorkoutRefDTO: Codable {
    let id: UUID
    let completedAt: Date?
    let type: String?

    enum CodingKeys: String, CodingKey {
        case id
        case completedAt = "completed_at"
        case type
    }
}

struct StationStatsDTO {
    let stationName: String
    let totalPerformances: Int
    let avgDurationMinutes: Double
    let bestDurationMinutes: Double
    let trendPercent: Double
}

struct HeartRateStatsDTO {
    let avgHeartRate: Double?
    let maxHeartRate: Double?
    let workoutCount: Int
    let zone1Percent: Double
    let zone2Percent: Double
    let zone3Percent: Double
    let zone4Percent: Double
    let zone5Percent: Double
}
