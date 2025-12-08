// FLEXR - Plan Service
// Handles AI-generated training plans and daily workouts

import Foundation

@MainActor
class PlanService: ObservableObject {
    static let shared = PlanService()

    @Published var currentPlan: TrainingPlan?
    @Published var todaysWorkouts: [PlannedWorkout] = []
    @Published var weeklyPlan: WeeklyPlan?
    @Published var allWeeks: [TrainingWeekSummary] = []
    @Published var isGeneratingPlan = false
    @Published var error: String?

    // NEW: Plan reasoning and overview from AI
    @Published var planReasoning: PlanReasoning?
    @Published var planSummary: PlanSummaryInfo?

    private let supabase = SupabaseService.shared

    // Store user ID for mock auth support - gets set when generating plan
    private var currentUserId: UUID?

    // MARK: - Caching

    /// Cache for weekly plans by week number to avoid repeated DB calls
    private var weeklyPlanCache: [Int: WeeklyPlan] = [:]

    /// Last time today's workouts were fetched (used to avoid fetching multiple times per day)
    private var lastTodaysFetch: Date?

    /// Last time all weeks were fetched
    private var lastAllWeeksFetch: Date?

    /// Cache duration: 5 minutes for general data, same day for today's workouts
    private let cacheDuration: TimeInterval = 5 * 60

    private init() {}

    // MARK: - Cache Management

    /// Invalidate all caches - call after workout completion, plan generation, etc.
    func invalidateCache() {
        weeklyPlanCache.removeAll()
        lastTodaysFetch = nil
        lastAllWeeksFetch = nil
        print("PlanService: Cache invalidated")
    }

    /// Invalidate cache for a specific week
    func invalidateCacheForWeek(_ weekNumber: Int) {
        weeklyPlanCache.removeValue(forKey: weekNumber)
        print("PlanService: Cache invalidated for week \(weekNumber)")
    }

    // MARK: - Computed Properties for Week Selection

    /// Returns weeks that have detailed workouts generated (totalWorkouts > 0)
    /// These are the weeks that should show in the week selector pills
    var availableDetailedWeeks: [Int] {
        allWeeks
            .filter { $0.totalWorkouts > 0 }
            .map { $0.weekNumber }
            .sorted()
    }

    /// Returns the current training week number, or the first available week if not found
    var currentTrainingWeek: Int {
        allWeeks.first(where: { $0.isCurrentWeek })?.weekNumber
            ?? availableDetailedWeeks.first
            ?? 1
    }

    /// Get the current user ID (from real auth or mock auth)
    private func getUserId() async -> UUID? {
        // First try real Supabase auth session
        if let sessionUserId = (try? await supabase.client.auth.session).map({ $0.user.id }) {
            return sessionUserId
        }
        // Fall back to stored mock user ID
        return currentUserId
    }

    /// Set user ID for mock auth - call this when user signs in with mock auth
    func setUserId(_ userId: UUID) {
        self.currentUserId = userId
    }

    // MARK: - Check for Existing Plan

    /// Check if user already has a training plan (used for device switching)
    func userHasExistingPlan(userId: UUID) async throws -> Bool {
        do {
            // Check if any planned workouts exist for this user
            let workouts: [PlannedWorkout] = try await supabase.client
                .database.from("planned_workouts")
                .select("*")
                .eq("user_id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value

            let hasPlan = !workouts.isEmpty
            print("PlanService.userHasExistingPlan: User \(userId) has plan: \(hasPlan)")
            return hasPlan
        } catch {
            print("PlanService.userHasExistingPlan error: \(error)")
            throw error
        }
    }

    // MARK: - Generate Initial Plan (Called after onboarding)

    /// Generate a complete training plan using Grok AI
    func generateInitialPlan(for user: User) async throws {
        isGeneratingPlan = true
        defer { isGeneratingPlan = false }

        // Use the user ID from the passed user object (works with mock auth too)
        let userId = user.id

        // Store for later fetches (needed for mock auth)
        self.currentUserId = userId

        // Build the plan request based on user's onboarding data
        // Calculate default session duration based on experience level
        let defaultDuration: Int = {
            switch user.experienceLevel {
            case .beginner: return 45
            case .intermediate: return 60
            case .advanced: return 75
            case .elite: return 90
            }
        }()

        let request = PlanGenerationRequest(
            userId: userId.uuidString,  // Use user.id from the passed User object
            goal: user.trainingGoal.rawValue,
            raceDate: user.raceDate?.ISO8601Format(),
            raceDivision: nil, // Optional - can be added later
            targetTime: nil, // Optional - can be added later
            daysPerWeek: user.trainingPreferences.daysPerWeek,
            sessionsPerDay: user.trainingPreferences.sessionsPerDay,
            preferredTypes: user.trainingPreferences.preferredTypes.map { $0.rawValue },
            sessionDuration: defaultDuration,
            experienceLevel: user.experienceLevel.rawValue,
            equipment: user.equipment ?? [],
            fitnessBackground: nil, // Optional - can be added later
            programStartDate: user.programStartDate?.ISO8601Format(),
            preferredRecoveryDay: user.preferredRecoveryDay?.rawValue
        )

        // Call Grok Edge Function to generate the plan
        let response: PlanGenerationResponse = try await supabase.client.functions.invoke(
            "generate-training-plan",
            options: .init(body: request)
        )

        if response.success {
            // Store AI reasoning from response
            self.planReasoning = response.planReasoning
            self.planSummary = response.planSummary

            // Invalidate cache and fetch fresh plan data
            invalidateCache()
            await fetchTodaysWorkouts(forceRefresh: true)
            await fetchWeeklyPlan(forceRefresh: true)
            await fetchFullTrainingCycle()

            print("PlanService: Plan generated with \(response.detailedWeeksGenerated ?? 0) detailed weeks")
            if let reasoning = response.planReasoning {
                print("PlanService: Focus areas: \(reasoning.keyFocusAreas.joined(separator: ", "))")
            }
        } else {
            throw PlanError.generationFailed(response.error ?? "Unknown error")
        }
    }

    // MARK: - Regenerate Plan (Update preferences)

    /// Regenerate training plan with updated user preferences
    func regeneratePlan(for user: User) async throws {
        isGeneratingPlan = true
        defer { isGeneratingPlan = false }

        print("PlanService.regeneratePlan: Starting plan regeneration for user \(user.id)")

        // Use the user ID from the passed user object
        let userId = user.id

        // Store for later fetches
        self.currentUserId = userId

        // Calculate session duration based on experience level
        let defaultDuration: Int = {
            switch user.experienceLevel {
            case .beginner: return 45
            case .intermediate: return 60
            case .advanced: return 75
            case .elite: return 90
            }
        }()

        // Build the plan request with updated preferences
        let request = PlanGenerationRequest(
            userId: userId.uuidString,
            goal: user.trainingGoal.rawValue,
            raceDate: user.raceDate?.ISO8601Format(),
            raceDivision: nil,
            targetTime: nil,
            daysPerWeek: user.trainingPreferences.daysPerWeek,
            sessionsPerDay: user.trainingPreferences.sessionsPerDay,
            preferredTypes: user.trainingPreferences.preferredTypes.map { $0.rawValue },
            sessionDuration: defaultDuration,
            experienceLevel: user.experienceLevel.rawValue,
            equipment: user.equipment ?? [],
            fitnessBackground: nil,
            programStartDate: user.programStartDate?.ISO8601Format(),
            preferredRecoveryDay: user.preferredRecoveryDay?.rawValue
        )

        print("PlanService.regeneratePlan: Calling edge function with updated preferences")

        // Call Grok Edge Function to regenerate the plan
        // The backend should handle deleting the old plan and creating a new one
        let response: PlanGenerationResponse = try await supabase.client.functions.invoke(
            "generate-training-plan",
            options: .init(body: request)
        )

        if response.success {
            print("PlanService.regeneratePlan: Plan regenerated successfully")

            // Store AI reasoning from response
            self.planReasoning = response.planReasoning
            self.planSummary = response.planSummary

            // Invalidate cache and fetch fresh plan data
            invalidateCache()
            await fetchTodaysWorkouts(forceRefresh: true)
            await fetchWeeklyPlan(forceRefresh: true)
            await fetchFullTrainingCycle()
        } else {
            print("PlanService.regeneratePlan: Failed - \(response.error ?? "Unknown error")")
            throw PlanError.generationFailed(response.error ?? "Unknown error")
        }
    }

    // MARK: - Fetch Today's Workouts

    /// Get today's AI-generated workouts (cached for same day)
    /// - Parameter forceRefresh: If true, bypasses cache and fetches fresh data
    func fetchTodaysWorkouts(forceRefresh: Bool = false) async {
        let today = Calendar.current.startOfDay(for: Date())

        // Check cache: only fetch if we haven't fetched today OR force refresh
        if !forceRefresh,
           let lastFetch = lastTodaysFetch,
           Calendar.current.isDate(lastFetch, inSameDayAs: today),
           !todaysWorkouts.isEmpty {
            print("PlanService: Using cached today's workouts")
            return
        }

        guard let userId = await getUserId() else {
            print("PlanService: No user ID available for fetching workouts")
            return
        }

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        do {
            let workouts: [PlannedWorkout] = try await supabase.client
                .database.from("planned_workouts")
                .select("*, planned_workout_segments(*)")
                .eq("user_id", value: userId.uuidString)
                .gte("scheduled_date", value: today.ISO8601Format())
                .lt("scheduled_date", value: tomorrow.ISO8601Format())
                .order("session_number", ascending: true)
                .execute()
                .value

            self.todaysWorkouts = workouts
            self.lastTodaysFetch = Date()
            print("PlanService: Fetched \(workouts.count) workouts for today (from DB)")
        } catch {
            print("Failed to fetch today's workouts: \(error)")
        }
    }

    // MARK: - Fetch Weekly Plan

    /// Get planned workouts for a specific week number (1-4)
    /// - Parameters:
    ///   - weekNumber: The week number to fetch (1 = first week of plan). If nil, fetches current week.
    ///   - forceRefresh: If true, bypasses cache and fetches fresh data
    func fetchWeeklyPlan(weekNumber: Int? = nil, forceRefresh: Bool = false) async {
        // Determine which week to fetch (use current if not specified)
        let targetWeek = weekNumber ?? currentTrainingWeek

        // Check cache first
        if !forceRefresh, let cached = weeklyPlanCache[targetWeek] {
            print("PlanService: Using cached weekly plan for week \(targetWeek)")
            self.weeklyPlan = cached
            return
        }

        guard let userId = await getUserId() else {
            print("PlanService.fetchWeeklyPlan: No user ID available")
            return
        }

        print("PlanService.fetchWeeklyPlan: Fetching week \(targetWeek) from DB for user \(userId)")

        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday = 2

        var weekStart: Date
        var weekEnd: Date

        if let requestedWeek = weekNumber {
            // Fetch by week number from training_weeks table
            do {
                let weekMeta: WeekMetadata? = try await supabase.client
                    .database.from("training_weeks")
                    .select()
                    .eq("user_id", value: userId.uuidString)
                    .eq("week_number", value: requestedWeek)
                    .single()
                    .execute()
                    .value

                if let meta = weekMeta {
                    weekStart = meta.startDate
                    weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
                } else {
                    print("PlanService.fetchWeeklyPlan: No week metadata found for week \(requestedWeek)")
                    self.weeklyPlan = nil
                    return
                }
            } catch {
                print("PlanService.fetchWeeklyPlan: Error fetching week metadata: \(error)")
                return
            }
        } else {
            // Default: Use current week based on today's date
            let today = Date()
            weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
            weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
        }

        let weekStartISO = weekStart.ISO8601Format()
        let weekEndISO = weekEnd.ISO8601Format()
        print("PlanService.fetchWeeklyPlan: Week range \(weekStartISO) to \(weekEndISO)")

        do {
            // Fetch workouts for the week with segments
            let workouts: [PlannedWorkout] = try await supabase.client
                .database.from("planned_workouts")
                .select("*, planned_workout_segments(*)")
                .eq("user_id", value: userId.uuidString)
                .gte("scheduled_date", value: weekStartISO)
                .lt("scheduled_date", value: weekEndISO)
                .order("scheduled_date", ascending: true)
                .order("session_number", ascending: true)
                .execute()
                .value

            print("PlanService.fetchWeeklyPlan: Fetched \(workouts.count) workouts")

            // Debug: Check segments for each workout
            for workout in workouts {
                let segmentCount = workout.segments?.count ?? 0
                print("PlanService: Workout '\(workout.name)' has \(segmentCount) segments")
            }

            // Fetch week metadata first (needed even if no workouts)
            let weekMeta: WeekMetadata? = try? await supabase.client
                .database.from("training_weeks")
                .select()
                .eq("user_id", value: userId.uuidString)
                .gte("start_date", value: weekStart.ISO8601Format())
                .lt("start_date", value: weekEnd.ISO8601Format())
                .single()
                .execute()
                .value

            // If no workouts but we have week metadata, show the phase info with "coming soon" workouts
            guard !workouts.isEmpty else {
                print("PlanService.fetchWeeklyPlan: No workouts found for this week")

                // Still show week overview with phase/focus if we have metadata
                if let weekMeta = weekMeta {
                    print("PlanService.fetchWeeklyPlan: Creating week plan with metadata but no workouts")
                    var dayPlans: [DayPlan] = []
                    for day in 0..<7 {
                        let date = calendar.date(byAdding: .day, value: day, to: weekStart)!
                        dayPlans.append(DayPlan(
                            date: date,
                            workouts: [], // Empty - will show "Coming Soon"
                            isRestDay: false,
                            isToday: calendar.isDateInToday(date)
                        ))
                    }

                    self.weeklyPlan = WeeklyPlan(
                        weekNumber: weekMeta.weekNumber,
                        totalWeeks: weekMeta.totalWeeks,
                        phase: TrainingPhase(rawValue: weekMeta.phase) ?? .base,
                        focus: weekMeta.focus,
                        days: dayPlans
                    )
                    return
                }

                // No metadata either - truly empty
                self.weeklyPlan = nil
                return
            }

            // We have workouts - weekMeta already fetched above
            print("PlanService.fetchWeeklyPlan: Week metadata: \(String(describing: weekMeta))")

            // Group by day - use UTC calendar to match database storage
            var utcCalendar = Calendar.current
            utcCalendar.timeZone = TimeZone(identifier: "UTC")!

            // Debug: Print all workout dates
            for workout in workouts {
                let dayOfWeek = utcCalendar.component(.weekday, from: workout.scheduledDate)
                let dayName = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][dayOfWeek - 1]
                print("PlanService DEBUG: Workout '\(workout.name)' scheduled for \(workout.scheduledDate) (\(dayName))")
            }

            var dayWorkouts: [DayPlan] = []
            let grouped = Dictionary(grouping: workouts) { workout in
                // Get the date components in UTC to match how the database stores dates
                let utcComponents = utcCalendar.dateComponents([.year, .month, .day], from: workout.scheduledDate)
                return utcCalendar.date(from: utcComponents)!
            }

            for day in 0..<7 {
                let date = calendar.date(byAdding: .day, value: day, to: weekStart)!
                // Convert the local date to UTC date components for matching
                let localComponents = calendar.dateComponents([.year, .month, .day], from: date)
                let utcDateKey = utcCalendar.date(from: localComponents)!
                let workoutsForDay = grouped[utcDateKey] ?? []

                dayWorkouts.append(DayPlan(
                    date: date,
                    workouts: workoutsForDay,
                    isRestDay: workoutsForDay.isEmpty,
                    isToday: calendar.isDateInToday(date)
                ))
            }

            print("PlanService.fetchWeeklyPlan: Created \(dayWorkouts.count) day plans")

            let plan = WeeklyPlan(
                weekNumber: weekMeta?.weekNumber ?? 1,
                totalWeeks: weekMeta?.totalWeeks,
                phase: TrainingPhase(rawValue: weekMeta?.phase ?? "base") ?? .base,
                focus: weekMeta?.focus ?? "Building your foundation",
                days: dayWorkouts
            )

            self.weeklyPlan = plan

            // Cache the plan by week number
            if let weekNum = weekMeta?.weekNumber {
                weeklyPlanCache[weekNum] = plan
                print("PlanService.fetchWeeklyPlan: SUCCESS - weeklyPlan set and cached for week \(weekNum)")
            } else {
                print("PlanService.fetchWeeklyPlan: SUCCESS - weeklyPlan set (no week number for caching)")
            }
        } catch {
            print("Failed to fetch weekly plan: \(error)")
        }
    }

    // MARK: - Fetch Full Training Cycle

    /// Get all weeks of the training plan with AI reasoning
    func fetchFullTrainingCycle() async {
        guard let userId = await getUserId() else {
            print("PlanService.fetchFullTrainingCycle: No user ID available")
            return
        }

        do {
            // Fetch the training plan with reasoning
            let plans: [TrainingPlanInfoExtended] = try await supabase.client
                .database.from("training_plans")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("start_date", ascending: false)
                .limit(1)
                .execute()
                .value

            // Store plan reasoning if available and not already set
            if let plan = plans.first, self.planReasoning == nil {
                self.planReasoning = plan.planReasoning
            }

            // Fetch all training weeks with extended info
            let weeks: [TrainingWeekInfoExtended] = try await supabase.client
                .database.from("training_weeks")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("week_number", ascending: true)
                .execute()
                .value

            print("PlanService.fetchFullTrainingCycle: Found \(plans.count) plans and \(weeks.count) weeks")

            // Build summary for each week
            var summaries: [TrainingWeekSummary] = []
            let plan = plans.first

            for week in weeks {
                // Count workouts for this week
                let weekStart = week.startDate
                let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: weekStart)!

                let workoutCount: Int = try await supabase.client
                    .database.from("planned_workouts")
                    .select("id", head: false, count: .exact)
                    .eq("user_id", value: userId.uuidString)
                    .gte("scheduled_date", value: weekStart.ISO8601Format())
                    .lt("scheduled_date", value: weekEnd.ISO8601Format())
                    .execute()
                    .count ?? 0

                let completedCount: Int = try await supabase.client
                    .database.from("planned_workouts")
                    .select("id", head: false, count: .exact)
                    .eq("user_id", value: userId.uuidString)
                    .eq("status", value: "completed")
                    .gte("scheduled_date", value: weekStart.ISO8601Format())
                    .lt("scheduled_date", value: weekEnd.ISO8601Format())
                    .execute()
                    .count ?? 0

                // Check if today falls within this training week (weekStart to weekStart + 7 days)
                // Use local calendar to normalize both dates to local timezone for comparison
                var localCalendar = Calendar.current
                localCalendar.timeZone = TimeZone.current

                let today = localCalendar.startOfDay(for: Date())
                let weekStartLocal = localCalendar.startOfDay(for: weekStart)
                let weekEndDate = localCalendar.date(byAdding: .day, value: 7, to: weekStartLocal)!
                let isCurrentWeek = today >= weekStartLocal && today < weekEndDate

                print("PlanService: Week \(week.weekNumber) - startLocal: \(weekStartLocal), today: \(today), isCurrentWeek: \(isCurrentWeek)")

                summaries.append(TrainingWeekSummary(
                    weekNumber: week.weekNumber,
                    totalWeeks: week.totalWeeks ?? plan?.totalWeeks ?? 12,
                    phase: TrainingPhase(rawValue: week.phase) ?? .base,
                    focus: week.focus,
                    startDate: weekStart,
                    totalWorkouts: workoutCount,
                    completedWorkouts: completedCount,
                    isCurrentWeek: isCurrentWeek,
                    isPast: weekStartLocal < today && !isCurrentWeek,
                    isDeload: week.isDeload ?? false,
                    phaseDescription: week.phaseDescription,
                    intensityGuidance: week.intensityGuidance
                ))
            }

            self.allWeeks = summaries
            print("PlanService.fetchFullTrainingCycle: Built \(summaries.count) week summaries")

        } catch {
            print("PlanService.fetchFullTrainingCycle error: \(error)")
        }
    }

    // MARK: - Generate Next Week

    /// Generate detailed workouts for the next week that needs them
    /// Called on Sunday evening to prepare next week's plan
    /// Returns the week number that was generated, or nil if all weeks already have workouts
    @discardableResult
    func generateNextWeek(specificWeek: Int? = nil, showLoadingUI: Bool = false) async throws -> Int? {
        guard let userId = await getUserId() else {
            throw PlanError.notAuthenticated
        }

        // Only show loading UI if explicitly requested (not for background Sunday generation)
        if showLoadingUI {
            isGeneratingPlan = true
        }
        defer {
            if showLoadingUI {
                isGeneratingPlan = false
            }
        }

        struct GenerateNextWeekRequest: Encodable {
            let user_id: String
            let week_number: Int?
        }

        struct GenerateNextWeekResponse: Decodable {
            let success: Bool
            let week_generated: Int?
            let workouts_created: Int?
            let message: String?
            let error: String?
        }

        let request = GenerateNextWeekRequest(
            user_id: userId.uuidString,
            week_number: specificWeek
        )

        let response: GenerateNextWeekResponse = try await supabase.client.functions.invoke(
            "generate-next-week",
            options: .init(body: request)
        )

        if !response.success {
            throw PlanError.generationFailed(response.error ?? "Unknown error")
        }

        // Invalidate cache and refresh plan data
        invalidateCache()
        await fetchFullTrainingCycle()
        if let generatedWeek = response.week_generated {
            await fetchWeeklyPlan(weekNumber: generatedWeek, forceRefresh: true)
        }

        print("PlanService: Generated week \(response.week_generated ?? 0) with \(response.workouts_created ?? 0) workouts")
        return response.week_generated
    }

    /// Force regenerate a specific week (deletes existing workouts first)
    func forceRegenerateWeek(weekNumber: Int) async throws {
        guard let userId = await getUserId() else {
            throw PlanError.notAuthenticated
        }

        // Get week dates to find workouts to delete
        guard let weekSummary = allWeeks.first(where: { $0.weekNumber == weekNumber }) else {
            throw PlanError.generationFailed("Week \(weekNumber) not found in training plan")
        }

        let weekStart = weekSummary.startDate
        let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: weekStart)!

        // Delete existing workouts for this week
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]

        // First get workout IDs
        struct WorkoutIdResult: Decodable {
            let id: UUID
        }

        let workoutsToDelete: [WorkoutIdResult] = try await supabase.client
            .from("planned_workouts")
            .select("id")
            .eq("user_id", value: userId.uuidString)
            .gte("scheduled_date", value: dateFormatter.string(from: weekStart))
            .lt("scheduled_date", value: dateFormatter.string(from: weekEnd))
            .execute()
            .value

        if !workoutsToDelete.isEmpty {
            let workoutIds = workoutsToDelete.map { $0.id.uuidString }
            print("PlanService: Deleting \(workoutIds.count) existing workouts for week \(weekNumber)")

            // Delete segments first
            try await supabase.client
                .from("planned_workout_segments")
                .delete()
                .in("planned_workout_id", values: workoutIds)
                .execute()

            // Delete workouts
            try await supabase.client
                .from("planned_workouts")
                .delete()
                .in("id", values: workoutIds)
                .execute()
        }

        // Now generate new workouts for this week
        let _ = try await generateNextWeek(specificWeek: weekNumber, showLoadingUI: false)

        print("PlanService: Successfully regenerated week \(weekNumber)")
    }

    /// Check if we need to generate next week's plan (called on app launch and periodically)
    /// Returns true if a new week was generated
    func checkAndGenerateNextWeekIfNeeded() async -> Bool {
        // Only run on Sunday after 6 PM local time
        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now)
        let hour = calendar.component(.hour, from: now)

        // weekday 1 = Sunday, check if it's Sunday after 6 PM
        guard weekday == 1 && hour >= 18 else {
            print("PlanService: Not Sunday evening, skipping next week generation check")
            return false
        }

        // Calculate which week SHOULD be generated (current week + 2)
        // This ensures next week is always ready BEFORE it starts
        // e.g., Sunday of Week 3 generates Week 5, so Week 4 is already ready
        let currentWeek = currentTrainingWeek
        let weekToGenerate = currentWeek + 2

        print("PlanService: Current week: \(currentWeek), checking if week \(weekToGenerate) needs generation")

        // Check if the week to generate exists in the plan
        guard allWeeks.contains(where: { $0.weekNumber == weekToGenerate }) else {
            print("PlanService: Week \(weekToGenerate) doesn't exist in the plan (end of training cycle)")
            return false
        }

        // Check if week already has workouts (already generated)
        if availableDetailedWeeks.contains(weekToGenerate) {
            print("PlanService: Week \(weekToGenerate) already has workouts, skipping generation")
            return false
        }

        // Generate the next week's workouts
        do {
            let generated = try await generateNextWeek(specificWeek: weekToGenerate)
            if generated != nil {
                print("PlanService: Successfully generated week \(weekToGenerate)")
                // Refresh the data so UI updates
                await fetchFullTrainingCycle()
            }
            return generated != nil
        } catch {
            print("PlanService: Failed to generate week \(weekToGenerate): \(error)")
            return false
        }
    }

    /// Returns ALL weeks that have detailed workouts generated
    /// Shows past weeks (for review), current week, and next week (generated on Sunday)
    /// Pills accumulate over time - user can scroll through their entire training history
    var displayableWeeks: [Int] {
        // Simply return all weeks that have workouts, sorted
        // This allows users to see past, present, and future weeks
        return availableDetailedWeeks.sorted()
    }

    // MARK: - Regenerate Week

    /// Ask AI to regenerate this week's plan (e.g., after missed workouts)
    func regenerateWeek(reason: RegenerationReason) async throws {
        guard let userId = try? await supabase.client.auth.session.user.id else {
            throw PlanError.notAuthenticated
        }

        isGeneratingPlan = true
        defer { isGeneratingPlan = false }

        let request = WeekRegenerationRequest(
            userId: userId.uuidString,
            reason: reason.rawValue
        )

        let _: EmptyResponse = try await supabase.client.functions.invoke(
            "regenerate-week",
            options: .init(body: request)
        )

        await fetchWeeklyPlan()
        await fetchTodaysWorkouts()
    }

    // MARK: - Adapt Workout

    /// Adapt today's workout based on readiness or time constraints
    func adaptWorkout(_ workout: PlannedWorkout, adaptation: WorkoutAdaptation) async throws -> PlannedWorkout {
        guard let userId = try? await supabase.client.auth.session.user.id else {
            throw PlanError.notAuthenticated
        }

        let request = AdaptWorkoutRequest(
            userId: userId.uuidString,
            workoutId: workout.id.uuidString,
            adaptation: adaptation
        )

        let response: AdaptWorkoutResponse = try await supabase.client.functions.invoke(
            "adapt-workout",
            options: .init(body: request)
        )

        // Update local state
        if let index = todaysWorkouts.firstIndex(where: { $0.id == workout.id }) {
            todaysWorkouts[index] = response.adaptedWorkout
        }

        return response.adaptedWorkout
    }
}

// MARK: - Models

struct TrainingPlan: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let startDate: Date
    let endDate: Date?
    let totalWeeks: Int
    let currentWeek: Int
    let goal: String
    let raceDate: Date?
    let phases: [PlanPhase]

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case totalWeeks = "total_weeks"
        case currentWeek = "current_week"
        case goal
        case raceDate = "race_date"
        case phases
    }
}

struct PlanPhase: Codable, Identifiable {
    let id: UUID
    let phase: TrainingPhase
    let startWeek: Int
    let endWeek: Int
    let focus: String

    enum CodingKeys: String, CodingKey {
        case id, phase, focus
        case startWeek = "start_week"
        case endWeek = "end_week"
    }
}

enum TrainingPhase: String, Codable, CaseIterable {
    case base = "base"
    case build = "build"
    case peak = "peak"
    case taper = "taper"
    case race = "race"
    case recovery = "recovery"

    var displayName: String {
        switch self {
        case .base: return "Base Building"
        case .build: return "Build Phase"
        case .peak: return "Peak Performance"
        case .taper: return "Taper"
        case .race: return "Race Week"
        case .recovery: return "Recovery"
        }
    }

    var description: String {
        switch self {
        case .base: return "Building aerobic foundation and movement patterns"
        case .build: return "Increasing intensity and HYROX-specific work"
        case .peak: return "Maximum race-specific training"
        case .taper: return "Reducing volume while maintaining intensity"
        case .race: return "Final preparation and race day"
        case .recovery: return "Active recovery and restoration"
        }
    }
}

struct PlannedWorkout: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let scheduledDate: Date
    let sessionNumber: Int
    let workoutType: WorkoutType
    let name: String
    let description: String?
    let estimatedDuration: Int // minutes
    let intensity: WorkoutIntensity
    let aiExplanation: String? // "Why this workout"
    var segments: [PlannedWorkoutSegment]?
    var status: WorkoutStatus

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case scheduledDate = "scheduled_date"
        case sessionNumber = "session_number"
        case workoutType = "workout_type"
        case name, description
        case estimatedDuration = "estimated_duration"
        case intensity
        case aiExplanation = "ai_explanation"
        case segments = "planned_workout_segments"
        case status
    }
}

enum WorkoutIntensity: String, Codable {
    case recovery = "recovery"
    case easy = "easy"
    case moderate = "moderate"
    case hard = "hard"
    case veryHard = "very_hard"
    case maxEffort = "max_effort"

    var displayName: String {
        switch self {
        case .recovery: return "Recovery"
        case .easy: return "Easy"
        case .moderate: return "Moderate"
        case .hard: return "Hard"
        case .veryHard: return "Very Hard"
        case .maxEffort: return "Max Effort"
        }
    }

    /// Short label for compact UI elements like tags (max 5 characters for consistency)
    var tagLabel: String {
        switch self {
        case .recovery: return "Easy"
        case .easy: return "Easy"
        case .moderate: return "Mod"
        case .hard: return "Hard"
        case .veryHard: return "V.Hard"
        case .maxEffort: return "Max"
        }
    }

    var color: String {
        switch self {
        case .recovery: return "808080"
        case .easy: return "33B5E5"
        case .moderate: return "00C851"
        case .hard: return "FFB700"
        case .veryHard: return "FF8800"
        case .maxEffort: return "FF4444"
        }
    }
}

struct WeeklyPlan {
    let weekNumber: Int
    let totalWeeks: Int?
    let phase: TrainingPhase
    let focus: String
    let days: [DayPlan]

    var completedSessions: Int {
        days.flatMap { $0.workouts }.filter { $0.status == .completed }.count
    }

    var totalSessions: Int {
        days.flatMap { $0.workouts }.count
    }

    var completionPercentage: Double {
        guard totalSessions > 0 else { return 0 }
        return Double(completedSessions) / Double(totalSessions) * 100
    }

    var estimatedTotalMinutes: Int {
        days.flatMap { $0.workouts }.reduce(0) { $0 + $1.estimatedDuration }
    }
}

struct DayPlan: Identifiable {
    let id = UUID()
    let date: Date
    let workouts: [PlannedWorkout]
    let isRestDay: Bool
    let isToday: Bool

    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }
}

struct WeekMetadata: Codable {
    let weekNumber: Int
    let totalWeeks: Int?
    let phase: String
    let focus: String
    let startDate: Date

    enum CodingKeys: String, CodingKey {
        case weekNumber = "week_number"
        case totalWeeks = "total_weeks"
        case phase, focus
        case startDate = "start_date"
    }
}

// MARK: - Request/Response Types

struct PlanGenerationRequest: Encodable {
    let userId: String
    let goal: String
    let raceDate: String?
    let raceDivision: String?
    let targetTime: String?
    let daysPerWeek: Int
    let sessionsPerDay: Int
    let preferredTypes: [String]
    let sessionDuration: Int
    let experienceLevel: String
    let equipment: [String]
    let fitnessBackground: String?
    let programStartDate: String?  // When the user wants to start the program
    let preferredRecoveryDay: String?  // Which day should be recovery (for 6-7 days/week)

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case goal
        case raceDate = "race_date"
        case raceDivision = "race_division"
        case targetTime = "target_time"
        case daysPerWeek = "days_per_week"
        case sessionsPerDay = "sessions_per_day"
        case preferredTypes = "preferred_types"
        case sessionDuration = "session_duration"
        case experienceLevel = "experience_level"
        case equipment
        case fitnessBackground = "fitness_background"
        case programStartDate = "program_start_date"
        case preferredRecoveryDay = "preferred_recovery_day"
    }
}

// Response from plan generation - includes AI reasoning and plan overview
struct PlanGenerationResponse: Decodable {
    let success: Bool
    let error: String?

    // NEW: AI reasoning for the plan
    let planReasoning: PlanReasoning?
    let planSummary: PlanSummaryInfo?
    let weeksOverview: [WeekOverviewInfo]?
    let detailedWeeksGenerated: Int?

    enum CodingKeys: String, CodingKey {
        case success, error
        case planReasoning = "plan_reasoning"
        case planSummary = "plan_summary"
        case weeksOverview = "weeks_overview"
        case detailedWeeksGenerated = "detailed_weeks_generated"
    }
}

struct WeekRegenerationRequest: Encodable {
    let userId: String
    let reason: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case reason
    }
}

enum RegenerationReason: String {
    case missedWorkouts = "missed_workouts"
    case lowReadiness = "low_readiness"
    case scheduleChange = "schedule_change"
    case injury = "injury"
    case userRequest = "user_request"
}

struct AdaptWorkoutRequest: Encodable {
    let userId: String
    let workoutId: String
    let adaptation: WorkoutAdaptation

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case workoutId = "workout_id"
        case adaptation
    }
}

struct WorkoutAdaptation: Encodable {
    let type: AdaptationType
    let newDuration: Int? // For time constraints
    let readinessScore: Int? // For readiness-based adaptation

    enum CodingKeys: String, CodingKey {
        case type
        case newDuration = "new_duration"
        case readinessScore = "readiness_score"
    }
}

enum AdaptationType: String, Codable {
    case lessTime = "less_time"
    case moreTired = "more_tired"
    case moreEnergy = "more_energy"
    case differentEquipment = "different_equipment"
    case lighter = "lighter"
    case harder = "harder"
}

struct AdaptWorkoutResponse: Decodable {
    let success: Bool
    let adaptedWorkout: PlannedWorkout
    let explanation: String

    enum CodingKeys: String, CodingKey {
        case success
        case adaptedWorkout = "adapted_workout"
        case explanation
    }
}

struct EmptyResponse: Decodable {}

// MARK: - Errors

enum PlanError: Error, LocalizedError {
    case notAuthenticated
    case generationFailed(String)
    case adaptationFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in"
        case .generationFailed(let message):
            return "Failed to generate plan: \(message)"
        case .adaptationFailed(let message):
            return "Failed to adapt workout: \(message)"
        }
    }
}

// MARK: - Training Cycle Models

/// Basic info fetched from training_plans table
struct TrainingPlanInfo: Codable {
    let id: UUID
    let userId: UUID
    let startDate: Date
    let endDate: Date?
    let totalWeeks: Int
    let currentWeek: Int
    let goal: String
    let raceDate: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case totalWeeks = "total_weeks"
        case currentWeek = "current_week"
        case goal
        case raceDate = "race_date"
    }
}

/// Basic info fetched from training_weeks table
struct TrainingWeekInfo: Codable {
    let id: UUID
    let userId: UUID
    let weekNumber: Int
    let totalWeeks: Int?
    let phase: String
    let focus: String
    let startDate: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case weekNumber = "week_number"
        case totalWeeks = "total_weeks"
        case phase, focus
        case startDate = "start_date"
    }
}

/// Summary of a training week for display in the cycle view
struct TrainingWeekSummary: Identifiable {
    let id = UUID()
    let weekNumber: Int
    let totalWeeks: Int
    let phase: TrainingPhase
    let focus: String
    let startDate: Date
    let totalWorkouts: Int
    let completedWorkouts: Int
    let isCurrentWeek: Bool
    let isPast: Bool

    // NEW: Additional fields from AI
    let isDeload: Bool
    let phaseDescription: String?
    let intensityGuidance: String?

    var completionPercentage: Double {
        guard totalWorkouts > 0 else { return 0 }
        return Double(completedWorkouts) / Double(totalWorkouts) * 100
    }

    var weekRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: startDate)!
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    var status: WeekStatus {
        if isCurrentWeek { return .current }
        if isPast { return completionPercentage >= 80 ? .completedGood : .completedPartial }
        return .upcoming
    }
}

enum WeekStatus {
    case upcoming
    case current
    case completedGood
    case completedPartial
}

// MARK: - Plan Reasoning Models (AI Decision Explanation)

/// AI's reasoning for the personalized plan
struct PlanReasoning: Codable {
    let startingPhaseRationale: String
    let phaseDistributionReasoning: String
    let keyFocusAreas: [String]
    let deloadRationale: String
    let intensityProgression: String
    let athleteSpecificNotes: String

    enum CodingKeys: String, CodingKey {
        case startingPhaseRationale = "starting_phase_rationale"
        case phaseDistributionReasoning = "phase_distribution_reasoning"
        case keyFocusAreas = "key_focus_areas"
        case deloadRationale = "deload_rationale"
        case intensityProgression = "intensity_progression"
        case athleteSpecificNotes = "athlete_specific_notes"
    }
}

/// Summary of the full training plan structure
struct PlanSummaryInfo: Codable {
    let totalWeeks: Int
    let phases: [PhaseInfo]
    let deloadWeeks: [Int]

    enum CodingKeys: String, CodingKey {
        case totalWeeks = "total_weeks"
        case phases
        case deloadWeeks = "deload_weeks"
    }
}

/// Info about a training phase
struct PhaseInfo: Codable, Identifiable {
    var id: String { name }
    let name: String
    let startWeek: Int
    let endWeek: Int
    let description: String

    enum CodingKeys: String, CodingKey {
        case name
        case startWeek = "start_week"
        case endWeek = "end_week"
        case description
    }
}

/// Overview of a single week (from plan generation response)
struct WeekOverviewInfo: Codable, Identifiable {
    var id: Int { weekNumber }
    let weekNumber: Int
    let phase: String
    let phaseDescription: String
    let focus: String
    let intensityGuidance: String
    let isDeload: Bool
    let keyWorkouts: [String]

    enum CodingKeys: String, CodingKey {
        case weekNumber = "week_number"
        case phase
        case phaseDescription = "phase_description"
        case focus
        case intensityGuidance = "intensity_guidance"
        case isDeload = "is_deload"
        case keyWorkouts = "key_workouts"
    }
}

// MARK: - Extended Training Week Info (includes new fields)

/// Extended info fetched from training_weeks table with new fields
struct TrainingWeekInfoExtended: Codable {
    let id: UUID
    let userId: UUID
    let weekNumber: Int
    let totalWeeks: Int?
    let phase: String
    let focus: String
    let startDate: Date
    let isDeload: Bool?
    let phaseDescription: String?
    let intensityGuidance: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case weekNumber = "week_number"
        case totalWeeks = "total_weeks"
        case phase, focus
        case startDate = "start_date"
        case isDeload = "is_deload"
        case phaseDescription = "phase_description"
        case intensityGuidance = "intensity_guidance"
    }
}

/// Extended training plan info with reasoning
struct TrainingPlanInfoExtended: Codable {
    let id: UUID
    let userId: UUID
    let startDate: Date
    let endDate: Date?
    let totalWeeks: Int
    let currentWeek: Int
    let goal: String
    let raceDate: Date?
    let planReasoning: PlanReasoning?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case totalWeeks = "total_weeks"
        case currentWeek = "current_week"
        case goal
        case raceDate = "race_date"
        case planReasoning = "plan_reasoning"
    }
}
