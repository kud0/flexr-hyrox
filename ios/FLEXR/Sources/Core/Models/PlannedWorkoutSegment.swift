// FLEXR - Planned Workout Segment Model
// Detailed AI-generated workout instructions

import Foundation

/// Represents a detailed segment within a planned workout
/// Contains precise targets and instructions from AI plan generation
struct PlannedWorkoutSegment: Identifiable, Codable, Equatable {
    let id: UUID
    let plannedWorkoutId: UUID
    let orderIndex: Int
    let segmentType: PlannedSegmentType

    // What to do
    let name: String
    let instructions: String

    // Specific targets
    let targetDurationSeconds: Int?
    let targetDistanceMeters: Int?
    let targetReps: Int?
    let targetCalories: Int?

    // For intervals/sets
    let sets: Int?
    let restBetweenSetsSeconds: Int?

    // Intensity guidance
    let targetPace: String?
    let targetHeartRateZone: Int?
    let intensityDescription: String?

    // Equipment/Station
    let equipment: String?
    let stationType: String?

    enum CodingKeys: String, CodingKey {
        case id
        case plannedWorkoutId = "planned_workout_id"
        case orderIndex = "order_index"
        case segmentType = "segment_type"
        case name, instructions
        case targetDurationSeconds = "target_duration_seconds"
        case targetDistanceMeters = "target_distance_meters"
        case targetReps = "target_reps"
        case targetCalories = "target_calories"
        case sets
        case restBetweenSetsSeconds = "rest_between_sets_seconds"
        case targetPace = "target_pace"
        case targetHeartRateZone = "target_heart_rate_zone"
        case intensityDescription = "intensity_description"
        case equipment
        case stationType = "station_type"
    }

    // MARK: - Computed Properties

    /// Formatted duration string (e.g., "5:00" for 300 seconds)
    var formattedDuration: String? {
        guard let seconds = targetDurationSeconds else { return nil }
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        if remainingSeconds == 0 {
            return "\(minutes) min"
        }
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    /// Formatted distance string (e.g., "1000m" or "1km")
    var formattedDistance: String? {
        guard let meters = targetDistanceMeters else { return nil }
        if meters >= 1000 && meters % 1000 == 0 {
            return "\(meters / 1000)km"
        }
        return "\(meters)m"
    }

    /// Formatted rest between sets (e.g., "90s rest")
    var formattedRest: String? {
        guard let seconds = restBetweenSetsSeconds else { return nil }
        if seconds >= 60 {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            if remainingSeconds == 0 {
                return "\(minutes) min rest"
            }
            return "\(minutes)m \(remainingSeconds)s rest"
        }
        return "\(seconds)s rest"
    }

    /// Primary target description for display
    var primaryTarget: String {
        var components: [String] = []

        if let sets = sets, sets > 1 {
            components.append("\(sets) sets")
        }

        if let reps = targetReps {
            components.append("\(reps) reps")
        }

        if let distance = formattedDistance {
            components.append(distance)
        }

        if let duration = formattedDuration {
            components.append(duration)
        }

        if let calories = targetCalories {
            components.append("\(calories) cal")
        }

        return components.isEmpty ? "Complete" : components.joined(separator: " × ")
    }

    /// Secondary info (pace, HR zone, etc.)
    var secondaryInfo: String? {
        var components: [String] = []

        if let pace = targetPace {
            components.append(pace)
        }

        if let hrZone = targetHeartRateZone {
            components.append("Zone \(hrZone)")
        }

        if let intensity = intensityDescription {
            components.append(intensity)
        }

        if let rest = formattedRest {
            components.append(rest)
        }

        return components.isEmpty ? nil : components.joined(separator: " • ")
    }

    /// Icon for the segment type
    var icon: String {
        switch segmentType {
        case .warmup:
            return "flame.fill"
        case .main:
            return "figure.mixed.cardio"
        case .cooldown:
            return "snowflake"
        case .rest:
            return "pause.circle.fill"
        case .transition:
            return "arrow.right.circle.fill"
        case .run:
            return "figure.run"
        case .station:
            return "figure.strengthtraining.functional"
        }
    }

    /// Color for the segment type
    var typeColor: String {
        switch segmentType {
        case .warmup:
            return "FF9F0A" // Orange
        case .main:
            return "0A84FF" // Electric blue (FLEXR primary)
        case .cooldown:
            return "64D2FF" // Blue
        case .rest:
            return "BF5AF2" // Purple
        case .transition:
            return "8E8E93" // Gray
        case .run:
            return "0A84FF" // Blue for running
        case .station:
            return "FFD60A" // Yellow for stations
        }
    }
}

// MARK: - Segment Type

enum PlannedSegmentType: String, Codable, CaseIterable {
    case warmup
    case main
    case cooldown
    case rest
    case transition
    case run      // HYROX running segment
    case station  // HYROX station work

    var displayName: String {
        switch self {
        case .warmup: return "Warm-up"
        case .main: return "Main Set"
        case .cooldown: return "Cool-down"
        case .rest: return "Rest"
        case .transition: return "Transition"
        case .run: return "Run"
        case .station: return "Station"
        }
    }

    var sortOrder: Int {
        switch self {
        case .warmup: return 0
        case .run: return 1
        case .station: return 1
        case .main: return 1
        case .transition: return 2
        case .rest: return 3
        case .cooldown: return 4
        }
    }

    /// Returns true if this is a running segment (shows pace UI)
    var isRun: Bool {
        return self == .run
    }

    /// Returns true if this is a HYROX station
    var isStation: Bool {
        return self == .station
    }
}

// MARK: - PlannedWorkout Extension

extension PlannedWorkout {
    /// Total workout duration from segments (in seconds)
    var totalSegmentDuration: Int {
        guard let segs = segments else { return estimatedDuration * 60 }
        return segs.reduce(0) { total, segment in
            var segmentDuration = segment.targetDurationSeconds ?? 0
            // Account for sets
            if let sets = segment.sets, sets > 1 {
                segmentDuration *= sets
                if let rest = segment.restBetweenSetsSeconds {
                    segmentDuration += rest * (sets - 1)
                }
            }
            return total + segmentDuration
        }
    }

    /// Warmup segments
    var warmupSegments: [PlannedWorkoutSegment] {
        segments?.filter { $0.segmentType == .warmup } ?? []
    }

    /// Main workout segments
    var mainSegments: [PlannedWorkoutSegment] {
        segments?.filter { $0.segmentType == .main } ?? []
    }

    /// Cooldown segments
    var cooldownSegments: [PlannedWorkoutSegment] {
        segments?.filter { $0.segmentType == .cooldown } ?? []
    }
}
