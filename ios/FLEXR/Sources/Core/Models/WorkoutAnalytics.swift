// FLEXR - Workout Analytics Models
// Comprehensive workout tracking and performance analysis
// Focus: Progress tracking and PRs for HYROX athletes

import Foundation

// MARK: - Workout Type Extension

extension Workout {
    /// Check if this workout is a personal record
    func isPR(comparedTo previousWorkouts: [Workout]) -> Bool {
        guard let duration = totalDuration else { return false }

        let sameTypeWorkouts = previousWorkouts.filter { $0.type == self.type }
        guard !sameTypeWorkouts.isEmpty else { return true } // First workout of this type

        let bestPrevious = sameTypeWorkouts.compactMap { $0.totalDuration }.min()
        return bestPrevious.map { duration < $0 } ?? false
    }

    /// Calculate improvement percentage compared to previous workout
    func improvementPercentage(comparedTo previous: Workout) -> Double? {
        guard let currentDuration = totalDuration,
              let previousDuration = previous.totalDuration else {
            return nil
        }

        let improvement = ((previousDuration - currentDuration) / previousDuration) * 100
        return improvement
    }

    /// Performance score (0-100) based on multiple factors
    var performanceScore: Double {
        var score: Double = 50 // Base score

        // Factor 1: Completion rate (max 30 points)
        let completionRate = Double(segments.filter { $0.isCompleted }.count) / Double(segments.count)
        score += completionRate * 30

        // Factor 2: Pace consistency for runs (max 10 points)
        // Note: Pace calculation would need segment distance/duration data
        // Placeholder for now
        score += 5 // Base consistency score

        // Factor 3: Heart rate efficiency (max 10 points)
        // Lower average HR for same performance = better efficiency
        // This is simplified - would need baseline comparison
        score += 10 // Placeholder

        return min(100, max(0, score))
    }
}

// MARK: - PR Record

struct PRRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    let workoutId: UUID

    // PR Category
    let prType: PRType
    let workoutType: AnalyticsWorkoutType
    let workoutSubtype: String?

    // PR Value
    let metricValue: Double
    let metricUnit: String

    // Context
    let previousPRId: UUID?
    let improvementPercentage: Double?

    // Metadata
    let achievedAt: Date
    let conditions: [String: String]?
    let notes: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case workoutId = "workout_id"
        case prType = "pr_type"
        case workoutType = "workout_type"
        case workoutSubtype = "workout_subtype"
        case metricValue = "metric_value"
        case metricUnit = "metric_unit"
        case previousPRId = "previous_pr_id"
        case improvementPercentage = "improvement_percentage"
        case achievedAt = "achieved_at"
        case conditions
        case notes
        case createdAt = "created_at"
    }

    // MARK: - Display Helpers

    var displayTitle: String {
        switch prType {
        case .fastestTime:
            return "Fastest \(workoutType.displayName)"
        case .longestDistance:
            return "Longest \(workoutType.displayName)"
        case .highestReps:
            return "Most Reps"
        case .heaviestWeight:
            return "Heaviest Weight"
        case .bestPace:
            return "Best Pace"
        case .highestScore:
            return "Highest Score"
        }
    }

    var displayValue: String {
        switch metricUnit {
        case "minutes":
            let mins = Int(metricValue)
            let secs = Int((metricValue - Double(mins)) * 60)
            return String(format: "%d:%02d", mins, secs)
        case "seconds":
            let mins = Int(metricValue) / 60
            let secs = Int(metricValue) % 60
            return String(format: "%d:%02d", mins, secs)
        case "meters":
            if metricValue >= 1000 {
                return String(format: "%.2f km", metricValue / 1000)
            }
            return "\(Int(metricValue))m"
        case "kg":
            return "\(Int(metricValue))kg"
        case "reps":
            return "\(Int(metricValue)) reps"
        case "score":
            return String(format: "%.1f", metricValue)
        default:
            return String(format: "%.1f %@", metricValue, metricUnit)
        }
    }

    var displayImprovement: String? {
        guard let improvement = improvementPercentage else { return nil }

        let prefix = improvement > 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.1f", improvement))%"
    }

    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: achievedAt)
    }
}

// MARK: - PR Type

enum PRType: String, Codable, CaseIterable {
    case fastestTime = "fastest_time"
    case longestDistance = "longest_distance"
    case highestReps = "highest_reps"
    case heaviestWeight = "heaviest_weight"
    case bestPace = "best_pace"
    case highestScore = "highest_score"

    var icon: String {
        switch self {
        case .fastestTime:
            return "stopwatch.fill"
        case .longestDistance:
            return "arrow.up.right"
        case .highestReps:
            return "number.circle.fill"
        case .heaviestWeight:
            return "dumbbell.fill"
        case .bestPace:
            return "speedometer"
        case .highestScore:
            return "star.fill"
        }
    }
}

// MARK: - Workout Stats Summary

struct WorkoutStatsSummary: Codable {
    let userId: UUID
    let month: Date
    let workoutType: AnalyticsWorkoutType

    // Counts
    let totalWorkouts: Int
    let totalPRs: Int

    // Time metrics
    let avgDurationMinutes: Double?
    let bestTimeMinutes: Double?
    let totalTrainingMinutes: Double?

    // Distance metrics
    let totalDistanceMeters: Double?
    let avgPacePerKm: Double?

    // Performance metrics
    let avgPerformanceScore: Double?
    let avgHeartRate: Double?

    // Latest workout
    let lastWorkoutAt: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case month
        case workoutType = "workout_type"
        case totalWorkouts = "total_workouts"
        case totalPRs = "total_prs"
        case avgDurationMinutes = "avg_duration_minutes"
        case bestTimeMinutes = "best_time_minutes"
        case totalTrainingMinutes = "total_training_minutes"
        case totalDistanceMeters = "total_distance_meters"
        case avgPacePerKm = "avg_pace_per_km"
        case avgPerformanceScore = "avg_performance_score"
        case avgHeartRate = "avg_heart_rate"
        case lastWorkoutAt = "last_workout_at"
    }

    // MARK: - Display Helpers

    var displayMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: month)
    }

    var displayTotalDistance: String? {
        guard let distance = totalDistanceMeters else { return nil }
        if distance >= 1000 {
            return String(format: "%.1f km", distance / 1000)
        }
        return "\(Int(distance))m"
    }

    var displayAvgDuration: String? {
        guard let duration = avgDurationMinutes else { return nil }
        let mins = Int(duration)
        let secs = Int((duration - Double(mins)) * 60)
        return String(format: "%d:%02d", mins, secs)
    }

    var displayBestTime: String? {
        guard let duration = bestTimeMinutes else { return nil }
        let mins = Int(duration)
        let secs = Int((duration - Double(mins)) * 60)
        return String(format: "%d:%02d", mins, secs)
    }

    var displayAvgPace: String? {
        guard let pace = avgPacePerKm else { return nil }
        let mins = Int(pace) / 60
        let secs = Int(pace) % 60
        return String(format: "%d:%02d /km", mins, secs)
    }

    var displayPerformanceScore: String? {
        guard let score = avgPerformanceScore else { return nil }
        return String(format: "%.1f", score)
    }

    var displayAvgHeartRate: String? {
        guard let hr = avgHeartRate else { return nil }
        return "\(Int(hr)) bpm"
    }
}

// MARK: - Gym Activity Feed Item

struct GymActivityFeedItem: Identifiable, Codable, Equatable {
    let id: UUID
    let gymId: UUID
    let userId: UUID

    // Activity details
    let activityType: GymActivityType
    let workoutId: UUID?
    let prId: UUID?
    let runningSessionId: UUID?

    // Display data
    let title: String
    let description: String?
    let metrics: [String: Double]?

    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case gymId = "gym_id"
        case userId = "user_id"
        case activityType = "activity_type"
        case workoutId = "workout_id"
        case prId = "pr_id"
        case runningSessionId = "running_session_id"
        case title
        case description
        case metrics
        case createdAt = "created_at"
    }

    // MARK: - Display Helpers

    var icon: String {
        switch activityType {
        case .workoutCompleted:
            return "checkmark.circle.fill"
        case .prAchieved:
            return "trophy.fill"
        case .challengeJoined:
            return "flag.fill"
        case .challengeCompleted:
            return "flag.checkered"
        case .milestoneReached:
            return "star.fill"
        }
    }

    var iconColor: String {
        switch activityType {
        case .prAchieved:
            return "gold"
        case .challengeCompleted:
            return "green"
        case .milestoneReached:
            return "purple"
        default:
            return "blue"
        }
    }

    var displayTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    var displayMetrics: String? {
        guard let metrics = metrics else { return nil }

        var components: [String] = []

        if let duration = metrics["duration_minutes"] {
            components.append("\(Int(duration))min")
        }

        if let distance = metrics["distance_meters"], distance > 0 {
            if distance >= 1000 {
                components.append(String(format: "%.1fkm", distance / 1000))
            } else {
                components.append("\(Int(distance))m")
            }
        }

        if let hr = metrics["avg_heart_rate"], hr > 0 {
            components.append("\(Int(hr))bpm")
        }

        if let cal = metrics["calories"], cal > 0 {
            components.append("\(Int(cal))cal")
        }

        return components.isEmpty ? nil : components.joined(separator: " • ")
    }
}

// MARK: - Activity Type

enum GymActivityType: String, Codable, CaseIterable {
    case workoutCompleted = "workout_completed"
    case prAchieved = "pr_achieved"
    case challengeJoined = "challenge_joined"
    case challengeCompleted = "challenge_completed"
    case milestoneReached = "milestone_reached"

    var displayName: String {
        switch self {
        case .workoutCompleted:
            return "Workout Completed"
        case .prAchieved:
            return "PR Achieved"
        case .challengeJoined:
            return "Challenge Joined"
        case .challengeCompleted:
            return "Challenge Completed"
        case .milestoneReached:
            return "Milestone Reached"
        }
    }
}

// MARK: - Analytics Workout Comparison

struct AnalyticsWorkoutComparison: Identifiable, Codable {
    let id: UUID
    let workoutId1: UUID
    let workoutId2: UUID
    let performanceDiff: Double?
    let segmentComparison: [AnalyticsSegmentComparison]?

    enum CodingKeys: String, CodingKey {
        case id
        case workoutId1 = "workout_id_1"
        case workoutId2 = "workout_id_2"
        case performanceDiff = "performance_diff"
        case segmentComparison = "segment_comparison"
    }

    // MARK: - Display Helpers

    var displayPerformanceDiff: String? {
        guard let diff = performanceDiff else { return nil }

        let prefix = diff > 0 ? "+" : ""
        let suffix = diff > 0 ? "slower" : "faster"
        return "\(prefix)\(String(format: "%.1f", abs(diff)))% \(suffix)"
    }
}

struct AnalyticsSegmentComparison: Codable {
    let segmentIndex: Int
    let segmentName: String
    let time1: TimeInterval
    let time2: TimeInterval

    var timeDifference: TimeInterval {
        time2 - time1
    }

    var displayTimeDiff: String {
        let diff = abs(timeDifference)
        let mins = Int(diff) / 60
        let secs = Int(diff) % 60

        let prefix = timeDifference < 0 ? "-" : "+"
        return "\(prefix)\(String(format: "%d:%02d", mins, secs))"
    }
}

// MARK: - Analytics Workout Type (matches database enum)

enum AnalyticsWorkoutType: String, Codable, CaseIterable {
    case strength
    case running
    case hybrid
    case recovery
    case raceSim = "race_sim"

    var displayName: String {
        switch self {
        case .strength:
            return "Strength"
        case .running:
            return "Running"
        case .hybrid:
            return "Hybrid"
        case .recovery:
            return "Recovery"
        case .raceSim:
            return "Race Simulation"
        }
    }

    var icon: String {
        switch self {
        case .strength:
            return "dumbbell.fill"
        case .running:
            return "figure.run"
        case .hybrid:
            return "bolt.fill"
        case .recovery:
            return "heart.fill"
        case .raceSim:
            return "flag.checkered"
        }
    }
}
