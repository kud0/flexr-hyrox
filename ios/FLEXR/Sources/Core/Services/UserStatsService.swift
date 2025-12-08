// FLEXR - User Stats Service
// Fetches real workout statistics from Supabase

import Foundation
import Supabase

@MainActor
class UserStatsService: ObservableObject {
    static let shared = UserStatsService()

    @Published var totalWorkouts: Int = 0
    @Published var totalTrainingMinutes: Int = 0
    @Published var thisWeekSessions: Int = 0
    @Published var isLoading: Bool = false

    private let supabase = SupabaseService.shared.client

    private init() {}

    // MARK: - Fetch All Stats

    func fetchUserStats(userId: UUID) async {
        isLoading = true

        async let workouts = fetchTotalWorkouts(userId: userId)
        async let trainingTime = fetchTotalTrainingTime(userId: userId)
        async let weekSessions = fetchThisWeekSessions(userId: userId)

        let results = await (workouts, trainingTime, weekSessions)

        totalWorkouts = results.0
        totalTrainingMinutes = results.1
        thisWeekSessions = results.2

        isLoading = false

        print("📊 User stats loaded: \(totalWorkouts) workouts")
    }

    // MARK: - Total Workouts

    private func fetchTotalWorkouts(userId: UUID) async -> Int {
        do {
            // Count completed workouts from workouts table
            let response: [WorkoutCount] = try await supabase
                .database.from("workouts")
                .select("id", head: false, count: .exact)
                .eq("user_id", value: userId.uuidString)
                .eq("status", value: "completed")
                .execute()
                .value

            return response.count
        } catch {
            print("❌ Error fetching total workouts: \(error)")
            return 0
        }
    }

    // MARK: - Total Training Time

    private func fetchTotalTrainingTime(userId: UUID) async -> Int {
        do {
            // Sum all workout durations
            let workouts: [WorkoutDuration] = try await supabase
                .database.from("workouts")
                .select("actual_duration_minutes")
                .eq("user_id", value: userId.uuidString)
                .eq("status", value: "completed")
                .execute()
                .value

            let totalMinutes = workouts.compactMap { $0.actualDurationMinutes }.reduce(0, +)
            return totalMinutes
        } catch {
            print("❌ Error fetching training time: \(error)")
            return 0
        }
    }

    // MARK: - This Week Sessions

    private func fetchThisWeekSessions(userId: UUID) async -> Int {
        do {
            let calendar = Calendar.current
            let today = Date()

            // Get start of week (Monday)
            guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
                return 0
            }

            let workouts: [WorkoutDate] = try await supabase
                .database.from("workouts")
                .select("scheduled_at")
                .eq("user_id", value: userId.uuidString)
                .eq("status", value: "completed")
                .gte("scheduled_at", value: weekStart.ISO8601Format())
                .execute()
                .value

            return workouts.count
        } catch {
            print("❌ Error fetching this week sessions: \(error)")
            return 0
        }
    }

    // MARK: - Personal Bests

    func fetchPersonalBests(userId: UUID) async -> [StationBest] {
        do {
            // Fetch best times for each station type
            let segments: [SegmentPerformance] = try await supabase
                .database.from("workout_segments")
                .select("station_type, actual_duration, actual_distance")
                .eq("user_id", value: userId.uuidString)
                .not("station_type", operator: .is, value: "null")
                .order("actual_duration", ascending: true)
                .execute()
                .value

            // Group by station type and get best for each
            var bestsByStation: [String: StationBest] = [:]

            for segment in segments {
                guard let stationType = segment.station_type,
                      let duration = segment.actual_duration else { continue }

                if let existing = bestsByStation[stationType] {
                    if duration < existing.duration {
                        bestsByStation[stationType] = StationBest(
                            stationType: stationType,
                            duration: duration,
                            distance: segment.actual_distance
                        )
                    }
                } else {
                    bestsByStation[stationType] = StationBest(
                        stationType: stationType,
                        duration: duration,
                        distance: segment.actual_distance
                    )
                }
            }

            return Array(bestsByStation.values)
        } catch {
            print("❌ Error fetching personal bests: \(error)")
            return []
        }
    }
}

// MARK: - Supporting Types

struct WorkoutCount: Decodable {
    let id: UUID
}

struct WorkoutDate: Decodable {
    let scheduledAt: Date?

    enum CodingKeys: String, CodingKey {
        case scheduledAt = "scheduled_at"
    }
}

struct WorkoutDuration: Decodable {
    let actualDurationMinutes: Int?

    enum CodingKeys: String, CodingKey {
        case actualDurationMinutes = "actual_duration_minutes"
    }
}

struct SegmentPerformance: Decodable {
    let station_type: String?
    let actual_duration: TimeInterval?
    let actual_distance: Double?
}

struct StationBest: Identifiable {
    let id = UUID()
    let stationType: String
    let duration: TimeInterval
    let distance: Double?

    var displayName: String {
        // Convert snake_case to display name
        stationType
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    var formattedTime: String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
}
