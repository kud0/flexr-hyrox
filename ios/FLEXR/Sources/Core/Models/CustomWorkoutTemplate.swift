// FLEXR - Custom Workout Template Model
// For BYOP (Bring Your Own Program) feature

import Foundation

struct CustomWorkoutTemplate: Codable, Identifiable {
    var id: UUID
    var userId: UUID?
    var name: String
    var description: String?
    var workoutType: String

    // Template segments
    var segments: [TemplateSegment]

    // Metadata
    var estimatedDurationMinutes: Int?
    var difficulty: WorkoutDifficulty?
    var tags: [String]

    // Sharing
    var isPublic: Bool
    var timesUsed: Int

    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, description, segments, tags, difficulty
        case userId = "user_id"
        case workoutType = "workout_type"
        case estimatedDurationMinutes = "estimated_duration_minutes"
        case isPublic = "is_public"
        case timesUsed = "times_used"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        workoutType: String = "custom",
        segments: [TemplateSegment] = [],
        estimatedDurationMinutes: Int? = nil,
        difficulty: WorkoutDifficulty? = nil,
        tags: [String] = [],
        isPublic: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.workoutType = workoutType
        self.segments = segments
        self.estimatedDurationMinutes = estimatedDurationMinutes
        self.difficulty = difficulty
        self.tags = tags
        self.isPublic = isPublic
        self.timesUsed = 0
    }
}

struct TemplateSegment: Codable, Identifiable {
    var id: UUID
    var segmentType: SegmentType
    var stationType: StationType?
    var targetDurationSeconds: Int?
    var targetDistanceMeters: Int?
    var targetReps: Int?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case id, notes
        case segmentType = "segment_type"
        case stationType = "station_type"
        case targetDurationSeconds = "target_duration_seconds"
        case targetDistanceMeters = "target_distance_meters"
        case targetReps = "target_reps"
    }

    init(
        segmentType: SegmentType,
        stationType: StationType? = nil,
        targetDurationSeconds: Int? = nil,
        targetDistanceMeters: Int? = nil,
        targetReps: Int? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.segmentType = segmentType
        self.stationType = stationType
        self.targetDurationSeconds = targetDurationSeconds
        self.targetDistanceMeters = targetDistanceMeters
        self.targetReps = targetReps
        self.notes = notes
    }
}

// MARK: - Quick Templates
extension CustomWorkoutTemplate {
    /// Full HYROX simulation template
    static var fullSimulation: CustomWorkoutTemplate {
        var segments: [TemplateSegment] = []

        // Warmup
        segments.append(TemplateSegment(
            segmentType: .warmup,
            targetDurationSeconds: 600 // 10 min
        ))

        // 8 rounds of run + station
        let stations: [StationType] = [
            .skiErg, .sledPush, .sledPull, .burpeeBroadJump,
            .rowing, .farmersCarry, .sandbagLunges, .wallBalls
        ]

        for station in stations {
            // 1km run
            segments.append(TemplateSegment(
                segmentType: .run,
                targetDistanceMeters: 1000
            ))

            // Station
            segments.append(TemplateSegment(
                segmentType: .station,
                stationType: station,
                targetDistanceMeters: station.standardDistance,
                targetReps: station.standardReps
            ))
        }

        // Cooldown
        segments.append(TemplateSegment(
            segmentType: .cooldown,
            targetDurationSeconds: 300 // 5 min
        ))

        return CustomWorkoutTemplate(
            name: "Full HYROX Simulation",
            description: "Complete 8km run + 8 stations simulation",
            workoutType: "full_simulation",
            segments: segments,
            estimatedDurationMinutes: 75,
            difficulty: .veryHard,
            tags: ["simulation", "race_prep", "full"]
        )
    }

    /// Half HYROX simulation
    static var halfSimulation: CustomWorkoutTemplate {
        var segments: [TemplateSegment] = []

        segments.append(TemplateSegment(
            segmentType: .warmup,
            targetDurationSeconds: 600
        ))

        // 4 rounds
        let stations: [StationType] = [.skiErg, .sledPush, .rowing, .wallBalls]

        for station in stations {
            segments.append(TemplateSegment(
                segmentType: .run,
                targetDistanceMeters: 1000
            ))
            segments.append(TemplateSegment(
                segmentType: .station,
                stationType: station,
                targetDistanceMeters: station.standardDistance,
                targetReps: station.standardReps
            ))
        }

        segments.append(TemplateSegment(
            segmentType: .cooldown,
            targetDurationSeconds: 300
        ))

        return CustomWorkoutTemplate(
            name: "Half HYROX Simulation",
            description: "4km run + 4 stations - perfect for weekday training",
            workoutType: "half_simulation",
            segments: segments,
            estimatedDurationMinutes: 40,
            difficulty: .hard,
            tags: ["simulation", "half"]
        )
    }

    /// Compromised running focus
    static var compromisedRunning: CustomWorkoutTemplate {
        var segments: [TemplateSegment] = []

        segments.append(TemplateSegment(
            segmentType: .warmup,
            targetDurationSeconds: 600
        ))

        // 3 rounds of station + immediate run
        let stations: [StationType] = [.wallBalls, .skiErg, .burpeeBroadJump]

        for station in stations {
            segments.append(TemplateSegment(
                segmentType: .station,
                stationType: station,
                targetDistanceMeters: station.standardDistance,
                targetReps: station.standardReps
            ))
            segments.append(TemplateSegment(
                segmentType: .run,
                targetDistanceMeters: 400,
                notes: "Run immediately after station - no rest!"
            ))
            segments.append(TemplateSegment(
                segmentType: .rest,
                targetDurationSeconds: 120
            ))
        }

        segments.append(TemplateSegment(
            segmentType: .cooldown,
            targetDurationSeconds: 300
        ))

        return CustomWorkoutTemplate(
            name: "Compromised Running Drills",
            description: "Practice running under fatigue - key HYROX skill",
            workoutType: "station_focus",
            segments: segments,
            estimatedDurationMinutes: 35,
            difficulty: .hard,
            tags: ["compromised", "running", "skill"]
        )
    }

    /// Station technique focus
    static var stationTechnique: CustomWorkoutTemplate {
        var segments: [TemplateSegment] = []

        segments.append(TemplateSegment(
            segmentType: .warmup,
            targetDurationSeconds: 600
        ))

        // All 8 stations at reduced volume
        for station in StationType.allCases {
            segments.append(TemplateSegment(
                segmentType: .station,
                stationType: station,
                targetDistanceMeters: station.standardDistance.map { $0 / 2 },
                targetReps: station.standardReps.map { $0 / 2 },
                notes: "Focus on technique, not speed"
            ))
            segments.append(TemplateSegment(
                segmentType: .rest,
                targetDurationSeconds: 90
            ))
        }

        segments.append(TemplateSegment(
            segmentType: .cooldown,
            targetDurationSeconds: 300
        ))

        return CustomWorkoutTemplate(
            name: "Station Technique Circuit",
            description: "All 8 stations at 50% volume - focus on form",
            workoutType: "station_focus",
            segments: segments,
            estimatedDurationMinutes: 45,
            difficulty: .moderate,
            tags: ["technique", "stations", "circuit"]
        )
    }

    /// All preset templates
    static var presets: [CustomWorkoutTemplate] {
        [
            fullSimulation,
            halfSimulation,
            compromisedRunning,
            stationTechnique
        ]
    }
}

// MARK: - Custom Program
struct CustomProgram: Codable, Identifiable {
    var id: UUID
    var userId: UUID?
    var name: String
    var description: String?

    // Structure
    var durationWeeks: Int
    var schedule: [WeekSchedule]

    // Progress
    var currentWeek: Int
    var startedAt: Date?

    // Source
    var source: String?  // "manual", "trainer", "gym", "imported"
    var sourceName: String? // "John's Coaching", "HYROX Official"

    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, description, schedule, source
        case userId = "user_id"
        case durationWeeks = "duration_weeks"
        case currentWeek = "current_week"
        case startedAt = "started_at"
        case sourceName = "source_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct WeekSchedule: Codable, Identifiable {
    var id: UUID
    var week: Int
    var workouts: [ScheduledWorkout]
    var focus: String? // "Endurance", "Strength", "Recovery", "Race Week"
    var notes: String?

    init(week: Int, workouts: [ScheduledWorkout], focus: String? = nil, notes: String? = nil) {
        self.id = UUID()
        self.week = week
        self.workouts = workouts
        self.focus = focus
        self.notes = notes
    }
}

struct ScheduledWorkout: Codable, Identifiable {
    var id: UUID
    var day: Int // 1-7
    var templateId: UUID?
    var templateName: String?
    var notes: String?

    init(day: Int, templateId: UUID? = nil, templateName: String? = nil, notes: String? = nil) {
        self.id = UUID()
        self.day = day
        self.templateId = templateId
        self.templateName = templateName
        self.notes = notes
    }

    enum CodingKeys: String, CodingKey {
        case id, day, notes
        case templateId = "template_id"
        case templateName = "template_name"
    }
}
