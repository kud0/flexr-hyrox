// FLEXR - External Workout Model
// Represents workouts imported from HealthKit/external sources

import Foundation
import HealthKit

/// Represents a workout from an external source (HealthKit, Apple Watch, other apps)
struct ExternalWorkout: Identifiable, Equatable {
    let id: UUID
    let healthKitId: UUID?          // Original HealthKit UUID
    let date: Date
    let endDate: Date
    let activityType: ExternalActivityType
    let source: WorkoutSource
    let sourceName: String          // App name that created it (e.g., "Strava", "Nike Run Club")
    let sourceVersion: String?

    // Metrics
    let duration: TimeInterval      // seconds
    let activeCalories: Double?
    let totalCalories: Double?
    let distance: Double?           // meters
    let averageHeartRate: Double?
    let maxHeartRate: Double?
    let averagePace: Double?        // seconds per km (for running)

    // Computed
    var durationMinutes: Int {
        Int(duration / 60)
    }

    var distanceKm: Double? {
        guard let d = distance else { return nil }
        return d / 1000.0
    }

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes) min"
    }

    var formattedDistance: String? {
        guard let km = distanceKm else { return nil }
        if km >= 1 {
            return String(format: "%.1f km", km)
        } else if let m = distance {
            return "\(Int(m)) m"
        }
        return nil
    }

    var formattedPace: String? {
        guard let pace = averagePace, pace > 0 else { return nil }
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }

    /// Check if this is a FLEXR-generated workout
    var isFLEXRWorkout: Bool {
        sourceName.lowercased().contains("flexr")
    }
}

// MARK: - External Activity Type

/// Maps HealthKit workout activity types to simplified categories
enum ExternalActivityType: String, Codable, CaseIterable {
    case running
    case cycling
    case walking
    case hiking
    case swimming
    case strength
    case hiit
    case crossTraining
    case yoga
    case pilates
    case rowing
    case elliptical
    case stairClimbing
    case functionalTraining
    case other

    var displayName: String {
        switch self {
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .walking: return "Walking"
        case .hiking: return "Hiking"
        case .swimming: return "Swimming"
        case .strength: return "Strength"
        case .hiit: return "HIIT"
        case .crossTraining: return "Cross Training"
        case .yoga: return "Yoga"
        case .pilates: return "Pilates"
        case .rowing: return "Rowing"
        case .elliptical: return "Elliptical"
        case .stairClimbing: return "Stairs"
        case .functionalTraining: return "Functional"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .running: return "figure.run"
        case .cycling: return "figure.outdoor.cycle"
        case .walking: return "figure.walk"
        case .hiking: return "figure.hiking"
        case .swimming: return "figure.pool.swim"
        case .strength: return "dumbbell.fill"
        case .hiit: return "flame.fill"
        case .crossTraining: return "figure.mixed.cardio"
        case .yoga: return "figure.yoga"
        case .pilates: return "figure.pilates"
        case .rowing: return "oar.2.crossed"
        case .elliptical: return "figure.elliptical"
        case .stairClimbing: return "figure.stairs"
        case .functionalTraining: return "figure.strengthtraining.functional"
        case .other: return "sportscourt.fill"
        }
    }

    var color: String {
        switch self {
        case .running: return "0A84FF"      // Blue
        case .cycling: return "FF9F0A"      // Orange
        case .walking: return "30D158"      // Green
        case .hiking: return "5E5CE6"       // Purple
        case .swimming: return "64D2FF"     // Cyan
        case .strength: return "FF453A"     // Red
        case .hiit: return "FF375F"         // Pink
        case .crossTraining: return "FFD60A" // Yellow
        case .yoga: return "BF5AF2"         // Purple
        case .pilates: return "AC8E68"      // Brown
        case .rowing: return "32ADE6"       // Light blue
        case .elliptical: return "FF9F0A"   // Orange
        case .stairClimbing: return "FF6482" // Salmon
        case .functionalTraining: return "FFD60A"
        case .other: return "8E8E93"        // Gray
        }
    }

    /// Map from HealthKit workout activity type
    static func from(hkType: HKWorkoutActivityType) -> ExternalActivityType {
        switch hkType {
        case .running, .trackAndField:
            return .running
        case .cycling:
            return .cycling
        case .walking:
            return .walking
        case .hiking:
            return .hiking
        case .swimming, .waterSports:
            return .swimming
        case .traditionalStrengthTraining, .functionalStrengthTraining:
            return .strength
        case .highIntensityIntervalTraining:
            return .hiit
        case .crossTraining, .mixedCardio:
            return .crossTraining
        case .yoga:
            return .yoga
        case .pilates:
            return .pilates
        case .rowing:
            return .rowing
        case .elliptical:
            return .elliptical
        case .stairClimbing, .stairs:
            return .stairClimbing
        default:
            return .other
        }
    }

    /// Check if this is a cardio activity (counts toward aerobic training)
    var isCardio: Bool {
        switch self {
        case .running, .cycling, .walking, .hiking, .swimming, .hiit, .rowing, .elliptical, .stairClimbing:
            return true
        default:
            return false
        }
    }

    /// Check if this is strength training
    var isStrength: Bool {
        switch self {
        case .strength, .functionalTraining, .crossTraining:
            return true
        default:
            return false
        }
    }
}

// MARK: - External Workouts Summary

/// Aggregated stats for external workouts
struct ExternalWorkoutsSummary {
    let totalWorkouts: Int
    let totalDurationMinutes: Int
    let totalDistanceKm: Double
    let totalCalories: Int
    let workoutsByType: [ExternalActivityType: Int]
    let workoutsBySource: [String: Int]

    var formattedDuration: String {
        let hours = totalDurationMinutes / 60
        let mins = totalDurationMinutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins) min"
    }

    static var empty: ExternalWorkoutsSummary {
        ExternalWorkoutsSummary(
            totalWorkouts: 0,
            totalDurationMinutes: 0,
            totalDistanceKm: 0,
            totalCalories: 0,
            workoutsByType: [:],
            workoutsBySource: [:]
        )
    }
}
