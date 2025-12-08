// FLEXR Watch - Plan Service
// Fetches workouts directly from Supabase (works without iPhone)

@preconcurrency import Foundation
@preconcurrency import Combine
@preconcurrency import Supabase

class WatchPlanService: ObservableObject {
    static let shared = WatchPlanService()

    @MainActor @Published var todaysWorkouts: [WatchPlannedWorkout] = []
    @MainActor @Published var upcomingWorkouts: [WatchPlannedWorkout] = []  // Rest of the week
    @MainActor @Published var isLoading = false
    @MainActor @Published var error: String?
    @MainActor @Published var lastFetchDate: Date?

    nonisolated(unsafe) private let client: SupabaseClient

    // User ID synced from iPhone or cached
    @MainActor @Published var userId: UUID?

    // Same mock user ID as iOS app for development
    // Must match the current iOS demo user ID
    #if DEBUG
    // Must match the user ID used on iPhone (real auth or mock)
    // Check Supabase planned_workouts table for the correct user_id
    private static let mockUserId = UUID(uuidString: "5da188a5-4140-48a7-a37a-b07ed98cc670")!
    #endif

    private init() {
        // Use same Supabase config as iOS
        let url = URL(string: "https://umvwmoxikxxxmxpwrsgc.supabase.co")!
        let key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVtdndtb3hpa3h4eG14cHdyc2djIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ2MDcyMDEsImV4cCI6MjA4MDE4MzIwMX0.ZGskBgfbsQD2uRZZJLCoAsXM4w87qNoF8PSZAXcSSyk"

        self.client = SupabaseClient(supabaseURL: url, supabaseKey: key)

        // Load cached user ID or use mock for development
        loadCachedUserId()

        #if DEBUG
        // In DEBUG, always use mock user ID to ensure sync with iOS app
        // Clear any stale cached ID and use the current mock
        if userId != Self.mockUserId {
            userId = Self.mockUserId
            UserDefaults.standard.set(Self.mockUserId.uuidString, forKey: "watch.userId")
            print("WatchPlanService: Using mock userId for development: \(Self.mockUserId)")
        }
        #endif
    }
    
    // MARK: - User ID Management
    
    private func loadCachedUserId() {
        if let idString = UserDefaults.standard.string(forKey: "watch.userId"),
           let id = UUID(uuidString: idString) {
            self.userId = id
            print("WatchPlanService: Loaded cached userId: \(id)")
        }
    }
    
    func setUserId(_ id: UUID) {
        self.userId = id
        UserDefaults.standard.set(id.uuidString, forKey: "watch.userId")
        print("WatchPlanService: Saved userId: \(id)")
    }
    
    // MARK: - Fetch Today's Workouts

    nonisolated func fetchTodaysWorkouts() async {
        let userId = await MainActor.run { self.userId }
        guard let userId = userId else {
            print("WatchPlanService: No userId available")
            await MainActor.run { self.error = "Not synced with iPhone yet" }
            return
        }

        print("WatchPlanService: Fetching workouts for userId: \(userId)")

        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }

        // Use Monday as week start (matching iOS)
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        calendar.timeZone = TimeZone(identifier: "UTC")!  // Match Supabase UTC storage
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        let todayStr = dateFormatter.string(from: today)
        let tomorrowStr = dateFormatter.string(from: tomorrow)

        print("WatchPlanService: TODAY Query range - \(todayStr) to \(tomorrowStr)")

        do {
            // Perform the fetch in a detached task to avoid actor isolation
            let workouts: [WatchPlannedWorkout] = try await Task.detached { [client] in
                return try await client.database
                    .from("planned_workouts")
                    .select("*, planned_workout_segments(*)")
                    .eq("user_id", value: userId.uuidString)
                    .gte("scheduled_date", value: todayStr)
                    .lt("scheduled_date", value: tomorrowStr)
                    .order("session_number", ascending: true)
                    .execute()
                    .value
            }.value

            await MainActor.run {
                self.todaysWorkouts = workouts
                self.lastFetchDate = Date()
            }

            // Cache for offline
            await cacheWorkouts(workouts)

            print("WatchPlanService: Fetched \(workouts.count) workouts for today")

            // Also fetch upcoming workouts (rest of week) for flexibility
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: today)!
            let weekEndStr = dateFormatter.string(from: weekEnd)
            print("WatchPlanService: UPCOMING Query range - \(tomorrowStr) to \(weekEndStr)")

            let upcoming: [WatchPlannedWorkout] = try await Task.detached { [client] in
                return try await client.database
                    .from("planned_workouts")
                    .select("*, planned_workout_segments(*)")
                    .eq("user_id", value: userId.uuidString)
                    .gte("scheduled_date", value: tomorrowStr)
                    .lt("scheduled_date", value: weekEndStr)
                    .order("scheduled_date", ascending: true)
                    .execute()
                    .value
            }.value

            await MainActor.run {
                self.upcomingWorkouts = upcoming
            }
            print("WatchPlanService: Fetched \(upcoming.count) upcoming workouts")

        } catch {
            print("WatchPlanService: Fetch error: \(error)")
            await MainActor.run {
                self.error = error.localizedDescription
            }

            // Try to load from cache
            await loadCachedWorkouts()
        }

        await MainActor.run {
            self.isLoading = false
        }
    }
    
    // MARK: - Fetch Upcoming Workouts (Debug)

    #if DEBUG
    /// Fetches workouts for the next 7 days - useful for testing
    nonisolated func fetchUpcomingWorkouts() async {
        let userId = await MainActor.run { self.userId }
        guard let userId = userId else {
            print("WatchPlanService: No userId available")
            return
        }

        print("WatchPlanService: Fetching UPCOMING workouts for userId: \(userId)")

        await MainActor.run { self.isLoading = true }

        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let today = calendar.startOfDay(for: Date())
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: today)!

        do {
            let workouts: [WatchPlannedWorkout] = try await Task.detached { [client] in
                return try await client.database
                    .from("planned_workouts")
                    .select("*, planned_workout_segments(*)")
                    .eq("user_id", value: userId.uuidString)
                    .gte("scheduled_date", value: today.ISO8601Format())
                    .lt("scheduled_date", value: nextWeek.ISO8601Format())
                    .order("scheduled_date", ascending: true)
                    .execute()
                    .value
            }.value

            print("WatchPlanService: Found \(workouts.count) upcoming workouts in next 7 days")
            for workout in workouts {
                print("  - \(workout.name) on \(workout.scheduledDate)")
            }

            // Show these for testing
            await MainActor.run {
                self.todaysWorkouts = workouts
                self.lastFetchDate = Date()
            }
        } catch {
            print("WatchPlanService: Upcoming fetch error: \(error)")
        }

        await MainActor.run { self.isLoading = false }
    }
    #endif

    // MARK: - Caching

    nonisolated private func cacheWorkouts(_ workouts: [WatchPlannedWorkout]) async {
        do {
            let data = try JSONEncoder().encode(workouts)
            UserDefaults.standard.set(data, forKey: "watch.cachedWorkouts")
            UserDefaults.standard.set(Date(), forKey: "watch.cacheDate")
        } catch {
            print("WatchPlanService: Cache save error: \(error)")
        }
    }
    
    nonisolated private func loadCachedWorkouts() async {
        guard let data = UserDefaults.standard.data(forKey: "watch.cachedWorkouts"),
              let cacheDate = UserDefaults.standard.object(forKey: "watch.cacheDate") as? Date else {
            return
        }
        
        // Only use cache if less than 24 hours old
        guard Date().timeIntervalSince(cacheDate) < 86400 else {
            print("WatchPlanService: Cache expired")
            return
        }
        
        do {
            let workouts = try JSONDecoder().decode([WatchPlannedWorkout].self, from: data)
            await MainActor.run {
                self.todaysWorkouts = workouts
                self.lastFetchDate = cacheDate
            }
            print("WatchPlanService: Loaded \(workouts.count) workouts from cache")
        } catch {
            print("WatchPlanService: Cache load error: \(error)")
        }
    }
}

// MARK: - Models are in WatchPlanModels.swift
