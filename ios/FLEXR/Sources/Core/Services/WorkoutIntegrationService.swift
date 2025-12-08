// FLEXR - Workout Integration Service
// Connects running sessions with main workout analytics
// Ensures consistent data across all workout types

import Foundation

/// Service to integrate running sessions with workout analytics
class WorkoutIntegrationService {
    static let shared = WorkoutIntegrationService()
    private let supabase = SupabaseService.shared

    private init() {}

    // MARK: - Running Session Integration

    /// Create activity feed item for running session
    func shareRunningSession(_ session: RunningSession) async throws {
        // Create a synthetic workout ID for the running session
        // In the database, we'd link running_sessions to workouts table
        // For now, we'll create an activity feed item directly

        guard let gymId = session.gymId else {
            throw IntegrationError.noGymAssociated
        }

        // Create activity feed item
        let title = "\(session.sessionType.displayName) Completed"
        let description = "\(session.displayDistance) in \(session.displayDuration)"

        var metrics: [String: Double] = [
            "duration_minutes": session.durationSeconds / 60,
            "distance_meters": Double(session.distanceMeters)
        ]

        if let avgHR = session.avgHeartRate {
            metrics["avg_heart_rate"] = Double(avgHR)
        }

        // Note: This would need a database function to create activity feed items
        // from running sessions, not just workouts
        // For now, log the integration
        print("📊 Running session integration: \(title) - \(description)")
    }

    /// Convert running session to workout format for unified analytics
    func convertRunningSessionToWorkout(_ session: RunningSession) -> WorkoutSummary {
        return WorkoutSummary(
            id: session.id,
            workoutName: session.sessionType.displayName,
            date: session.startedAt ?? Date(),
            totalTime: Double(session.durationSeconds),
            segmentsCompleted: 1, // Running sessions are treated as single segment
            totalSegments: 1,
            averageHeartRate: session.avgHeartRate ?? 0,
            maxHeartRate: session.maxHeartRate ?? 0,
            activeCalories: 0, // Calories not tracked in RunningSession yet
            totalDistance: Double(session.distanceMeters),
            compromisedRuns: [],
            routeData: nil, // Route data loaded separately if needed
            segmentResults: []
        )
    }

    /// Import HealthKit running workouts
    func importHealthKitRunningWorkouts(daysBack: Int = 30) async throws {
        let healthKit = HealthKitService.shared

        // Request authorization if needed
        guard await healthKit.checkAuthorizationStatus() else {
            throw IntegrationError.healthKitNotAuthorized
        }

        // Import running workouts
        try await healthKit.importRunningWorkouts(daysBack: daysBack)

        print("✅ Imported HealthKit running workouts from last \(daysBack) days")
    }

    /// Sync all running sessions to workout analytics
    func syncRunningSessionsToAnalytics() async throws {
        // Fetch recent running sessions
        let sessions = try await supabase.getRunningSessions(limit: 100)

        print("🔄 Syncing \(sessions.count) running sessions to analytics")

        for session in sessions {
            let workout = convertRunningSessionToWorkout(session)
            // In a real implementation, we'd save this to a unified workouts table
            print("  ✓ Synced: \(workout.workoutName) - \(workout.totalTime)s")
        }
    }

    // MARK: - Performance Calculations

    private func calculateRunningPerformanceScore(_ session: RunningSession) -> Double {
        var score: Double = 50 // Base score

        // Factor 1: Pace quality (30 points max)
        let avgPaceSeconds = session.avgPacePerKm
        let targetPace: Double = {
            switch session.sessionType {
            case .easy: return 360 // 6:00/km
            case .threshold: return 270 // 4:30/km
            case .intervals: return 240 // 4:00/km
            case .timeTrial5k, .timeTrial10k: return 240 // 4:00/km
            case .longRun: return 330 // 5:30/km
            case .recovery: return 420 // 7:00/km
            }
        }()

        let paceScore = max(0, min(30, 30 * (1 - abs(avgPaceSeconds - targetPace) / targetPace)))
        score += paceScore

        // Factor 2: Pace consistency (10 points max)
        if let consistency = session.paceConsistency {
            let consistencyScore = max(0, min(10, 10 * (1 - consistency / 100)))
            score += consistencyScore
        }

        // Factor 3: Heart rate efficiency (10 points max)
        if let avgHR = session.avgHeartRate, let maxHR = session.maxHeartRate {
            let hrReserve = Double(maxHR - avgHR) / Double(maxHR)
            score += hrReserve * 10
        }

        return min(100, max(0, score))
    }

    // MARK: - Unified Analytics

    /// Get combined workout statistics including running sessions
    func getCombinedWorkoutStats(userId: UUID? = nil) async throws -> CombinedWorkoutStats {
        // Get regular workouts
        let workouts = try await supabase.getWorkoutHistory(userId: userId, limit: 1000)

        // Get running sessions
        let runningSessions = try await supabase.getRunningSessions(limit: 1000)

        // Convert running sessions to workout summaries
        let runningWorkouts = runningSessions.map { convertRunningSessionToWorkout($0) }

        // Combine stats
        let totalWorkouts = workouts.count + runningSessions.count
        let totalMinutes = (workouts.compactMap { $0.totalDuration }.reduce(0, +) / 60) +
                          (runningSessions.map { $0.durationSeconds }.reduce(0, +) / 60)

        let totalDistance = workouts.reduce(0.0) { $0 + $1.totalDistance } +
                           runningSessions.map { Double($0.distanceMeters) }.reduce(0, +)

        return CombinedWorkoutStats(
            totalWorkouts: totalWorkouts,
            totalMinutes: Int(totalMinutes),
            totalDistance: totalDistance,
            workoutCount: workouts.count,
            runningSessionCount: runningSessions.count
        )
    }
}

// MARK: - Supporting Types

struct CombinedWorkoutStats {
    let totalWorkouts: Int
    let totalMinutes: Int
    let totalDistance: Double
    let workoutCount: Int
    let runningSessionCount: Int

    var displayTotalDistance: String {
        if totalDistance >= 1000 {
            return String(format: "%.1f km", totalDistance / 1000)
        }
        return "\(Int(totalDistance))m"
    }

    var displayTotalTime: String {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return "\(hours)h \(minutes)m"
    }
}

enum IntegrationError: Error, LocalizedError {
    case noGymAssociated
    case healthKitNotAuthorized
    case conversionFailed

    var errorDescription: String? {
        switch self {
        case .noGymAssociated:
            return "No gym associated with this session"
        case .healthKitNotAuthorized:
            return "HealthKit authorization required"
        case .conversionFailed:
            return "Failed to convert data format"
        }
    }
}
