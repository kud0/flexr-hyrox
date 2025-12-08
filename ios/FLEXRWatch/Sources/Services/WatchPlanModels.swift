// FLEXR Watch - Plan Models
// Data models for workout plans fetched from Supabase

@preconcurrency import Foundation

struct WatchPlannedWorkout: Identifiable {
    let id: UUID
    let userId: UUID
    let scheduledDate: Date
    let sessionNumber: Int
    let workoutType: String
    let name: String
    let watchName: String?  // Short name for Watch display (max 12 chars)
    let description: String?
    let estimatedDuration: Int
    let intensity: String
    let aiExplanation: String?
    var segments: [WatchWorkoutSegment]?
    var status: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case scheduledDate = "scheduled_date"
        case sessionNumber = "session_number"
        case workoutType = "workout_type"
        case name
        case watchName = "watch_name"
        case description
        case estimatedDuration = "estimated_duration"
        case intensity
        case aiExplanation = "ai_explanation"
        case segments = "planned_workout_segments"
        case status
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.userId = try container.decode(UUID.self, forKey: .userId)
        self.scheduledDate = try container.decode(Date.self, forKey: .scheduledDate)
        self.sessionNumber = try container.decode(Int.self, forKey: .sessionNumber)
        self.workoutType = try container.decode(String.self, forKey: .workoutType)
        self.name = try container.decode(String.self, forKey: .name)
        self.watchName = try container.decodeIfPresent(String.self, forKey: .watchName)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.estimatedDuration = try container.decode(Int.self, forKey: .estimatedDuration)
        self.intensity = try container.decode(String.self, forKey: .intensity)
        self.aiExplanation = try container.decodeIfPresent(String.self, forKey: .aiExplanation)
        self.segments = try container.decodeIfPresent([WatchWorkoutSegment].self, forKey: .segments)
        self.status = try container.decode(String.self, forKey: .status)
    }
    
    var intensityColor: String {
        switch intensity {
        case "easy": return "0A84FF" // Electric blue (FLEXR primary)
        case "moderate": return "0A84FF" // Electric blue (FLEXR primary)
        case "hard": return "FFB700"
        case "very_hard": return "FF8800"
        default: return "808080"
        }
    }
}

struct WatchWorkoutSegment: Identifiable {
    let id: UUID
    let plannedWorkoutId: UUID
    let orderIndex: Int
    let segmentType: String
    let name: String
    let instructions: String
    let targetDurationSeconds: Int?
    let targetDistanceMeters: Int?
    let targetReps: Int?
    let sets: Int?
    let restBetweenSetsSeconds: Int?
    let targetPace: String?
    let targetHeartRateZone: Int?
    let intensityDescription: String?
    let equipment: String?
    let stationType: String?  // HYROX station type: ski_erg, sled_push, etc.

    enum CodingKeys: String, CodingKey {
        case id
        case plannedWorkoutId = "planned_workout_id"
        case orderIndex = "order_index"
        case segmentType = "segment_type"
        case name, instructions
        case targetDurationSeconds = "target_duration_seconds"
        case targetDistanceMeters = "target_distance_meters"
        case targetReps = "target_reps"
        case sets
        case restBetweenSetsSeconds = "rest_between_sets_seconds"
        case targetPace = "target_pace"
        case targetHeartRateZone = "target_heart_rate_zone"
        case intensityDescription = "intensity_description"
        case equipment
        case stationType = "station_type"
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.plannedWorkoutId = try container.decode(UUID.self, forKey: .plannedWorkoutId)
        self.orderIndex = try container.decode(Int.self, forKey: .orderIndex)
        self.segmentType = try container.decode(String.self, forKey: .segmentType)
        self.name = try container.decode(String.self, forKey: .name)
        self.instructions = try container.decode(String.self, forKey: .instructions)
        self.targetDurationSeconds = try container.decodeIfPresent(Int.self, forKey: .targetDurationSeconds)
        self.targetDistanceMeters = try container.decodeIfPresent(Int.self, forKey: .targetDistanceMeters)
        self.targetReps = try container.decodeIfPresent(Int.self, forKey: .targetReps)
        self.sets = try container.decodeIfPresent(Int.self, forKey: .sets)
        self.restBetweenSetsSeconds = try container.decodeIfPresent(Int.self, forKey: .restBetweenSetsSeconds)
        self.targetPace = try container.decodeIfPresent(String.self, forKey: .targetPace)
        self.targetHeartRateZone = try container.decodeIfPresent(Int.self, forKey: .targetHeartRateZone)
        self.intensityDescription = try container.decodeIfPresent(String.self, forKey: .intensityDescription)
        self.equipment = try container.decodeIfPresent(String.self, forKey: .equipment)
        self.stationType = try container.decodeIfPresent(String.self, forKey: .stationType)
    }
}

// MARK: - Codable Conformance (nonisolated)

extension WatchPlannedWorkout: Codable {}
extension WatchWorkoutSegment: Codable {}

// MARK: - Sendable Conformance (unchecked to bypass actor isolation)

extension WatchPlannedWorkout: @unchecked Sendable {}
extension WatchWorkoutSegment: @unchecked Sendable {}
