import Foundation

struct WorkoutSegment: Identifiable, Codable, Equatable {
    let id: UUID
    var workoutId: UUID
    var segmentType: SegmentType
    var stationType: StationType?
    var order: Int?

    // Targets
    var targetDuration: TimeInterval?
    var targetDistance: Double? // in meters
    var targetReps: Int?

    // Actuals
    var actualDuration: TimeInterval?
    var actualDistance: Double?
    var actualReps: Int?

    // Heart Rate Data
    var avgHeartRate: Double?
    var maxHeartRate: Double?
    var heartRateZones: HeartRateZones?

    // Running Data
    var avgPace: Double? // in seconds per km
    var maxPace: Double?
    var minPace: Double?
    var targetPace: String? // e.g., "5:00-5:15"
    var isCompromised: Bool? // for runs after stations

    // Context
    var previousStation: StationType? // for compromised run analysis
    var transitionTime: TimeInterval? // time between segments

    // Strength Training Data
    var exerciseName: String?
    var sets: Int?
    var repsPerSet: Int?
    var weightSuggestion: String?

    // Metadata
    var startTime: Date?
    var endTime: Date?
    var notes: String?

    // Section grouping (for functional workouts)
    var sectionType: String?
    var sectionLabel: String?
    var sectionFormat: String?
    var sectionFormatDetailsRaw: Data?  // Raw JSON for format details

    enum CodingKeys: String, CodingKey {
        case id
        case workoutId = "workout_id"
        case segmentType = "segment_type"
        case stationType = "station_type"
        case order = "order_index"
        case targetDuration = "target_duration_seconds"
        case targetDistance = "target_distance_meters"
        case targetReps = "target_reps"
        case actualDuration = "actual_duration_seconds"
        case actualDistance = "actual_distance_meters"
        case actualReps = "actual_reps"
        case avgHeartRate = "avg_heart_rate"
        case maxHeartRate = "max_heart_rate"
        case heartRateZones = "heart_rate_zones"
        case avgPace = "avg_pace"
        case maxPace = "max_pace"
        case minPace = "min_pace"
        case targetPace = "target_pace"
        case isCompromised = "is_compromised"
        case previousStation = "previous_station"
        case transitionTime = "transition_time"
        case exerciseName = "exercise_name"
        case sets
        case repsPerSet = "reps_per_set"
        case weightSuggestion = "weight_suggestion"
        case startTime = "start_time"
        case endTime = "end_time"
        case notes
        case sectionType = "section_type"
        case sectionLabel = "section_label"
        case sectionFormat = "section_format"
        case sectionFormatDetailsRaw = "section_format_details"
    }

    // Custom decoder to handle edge function response (which may have different field names)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // ID - generate if not present (edge function AI response doesn't include it)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()

        // Workout ID - may not be present in AI-generated segments
        workoutId = try container.decodeIfPresent(UUID.self, forKey: .workoutId) ?? UUID()

        segmentType = try container.decode(SegmentType.self, forKey: .segmentType)
        stationType = try container.decodeIfPresent(StationType.self, forKey: .stationType)
        order = try container.decodeIfPresent(Int.self, forKey: .order)

        targetDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .targetDuration)
        targetDistance = try container.decodeIfPresent(Double.self, forKey: .targetDistance)
        targetReps = try container.decodeIfPresent(Int.self, forKey: .targetReps)

        actualDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .actualDuration)
        actualDistance = try container.decodeIfPresent(Double.self, forKey: .actualDistance)
        actualReps = try container.decodeIfPresent(Int.self, forKey: .actualReps)

        avgHeartRate = try container.decodeIfPresent(Double.self, forKey: .avgHeartRate)
        maxHeartRate = try container.decodeIfPresent(Double.self, forKey: .maxHeartRate)
        heartRateZones = try container.decodeIfPresent(HeartRateZones.self, forKey: .heartRateZones)

        avgPace = try container.decodeIfPresent(Double.self, forKey: .avgPace)
        maxPace = try container.decodeIfPresent(Double.self, forKey: .maxPace)
        minPace = try container.decodeIfPresent(Double.self, forKey: .minPace)
        targetPace = try container.decodeIfPresent(String.self, forKey: .targetPace)
        isCompromised = try container.decodeIfPresent(Bool.self, forKey: .isCompromised)

        previousStation = try container.decodeIfPresent(StationType.self, forKey: .previousStation)
        transitionTime = try container.decodeIfPresent(TimeInterval.self, forKey: .transitionTime)

        exerciseName = try container.decodeIfPresent(String.self, forKey: .exerciseName)
        sets = try container.decodeIfPresent(Int.self, forKey: .sets)
        repsPerSet = try container.decodeIfPresent(Int.self, forKey: .repsPerSet)
        weightSuggestion = try container.decodeIfPresent(String.self, forKey: .weightSuggestion)

        startTime = try container.decodeIfPresent(Date.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)

        // Section grouping fields
        sectionType = try container.decodeIfPresent(String.self, forKey: .sectionType)
        sectionLabel = try container.decodeIfPresent(String.self, forKey: .sectionLabel)
        sectionFormat = try container.decodeIfPresent(String.self, forKey: .sectionFormat)
        // Skip format details here - we'll decode in reconstructSections later
        // The JSONB comes as a dict which we can't easily store without FormatDetails
        sectionFormatDetailsRaw = nil
    }

    init(
        id: UUID = UUID(),
        workoutId: UUID,
        segmentType: SegmentType,
        stationType: StationType? = nil,
        order: Int? = nil,
        targetDuration: TimeInterval? = nil,
        targetDistance: Double? = nil,
        targetReps: Int? = nil,
        actualDuration: TimeInterval? = nil,
        actualDistance: Double? = nil,
        actualReps: Int? = nil,
        avgHeartRate: Double? = nil,
        maxHeartRate: Double? = nil,
        heartRateZones: HeartRateZones? = nil,
        avgPace: Double? = nil,
        maxPace: Double? = nil,
        minPace: Double? = nil,
        targetPace: String? = nil,
        isCompromised: Bool? = nil,
        previousStation: StationType? = nil,
        transitionTime: TimeInterval? = nil,
        exerciseName: String? = nil,
        sets: Int? = nil,
        repsPerSet: Int? = nil,
        weightSuggestion: String? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil,
        notes: String? = nil,
        sectionType: String? = nil,
        sectionLabel: String? = nil,
        sectionFormat: String? = nil,
        sectionFormatDetailsRaw: Data? = nil
    ) {
        self.id = id
        self.workoutId = workoutId
        self.segmentType = segmentType
        self.stationType = stationType
        self.order = order
        self.targetDuration = targetDuration
        self.targetDistance = targetDistance
        self.targetReps = targetReps
        self.actualDuration = actualDuration
        self.actualDistance = actualDistance
        self.actualReps = actualReps
        self.avgHeartRate = avgHeartRate
        self.maxHeartRate = maxHeartRate
        self.heartRateZones = heartRateZones
        self.avgPace = avgPace
        self.maxPace = maxPace
        self.minPace = minPace
        self.targetPace = targetPace
        self.isCompromised = isCompromised
        self.previousStation = previousStation
        self.transitionTime = transitionTime
        self.exerciseName = exerciseName
        self.sets = sets
        self.repsPerSet = repsPerSet
        self.weightSuggestion = weightSuggestion
        self.startTime = startTime
        self.endTime = endTime
        self.notes = notes
        self.sectionType = sectionType
        self.sectionLabel = sectionLabel
        self.sectionFormat = sectionFormat
        self.sectionFormatDetailsRaw = sectionFormatDetailsRaw
    }

    // MARK: - Computed Properties

    var isCompleted: Bool {
        actualDuration != nil || actualDistance != nil || actualReps != nil
    }

    var displayName: String {
        // For any segment with a custom exercise name (strength, WODs, finishers), use it
        if let exercise = exerciseName, !exercise.isEmpty {
            return exercise
        }
        // For HYROX stations without custom name, show station type
        if segmentType == .station, let station = stationType {
            return station.displayName
        }
        // Fallback to segment type name
        return segmentType.displayName
    }

    var targetDescription: String {
        var components: [String] = []

        // Strength workout format: "4 x 6 @ 75% 1RM"
        if let sets = sets, let repsPerSet = repsPerSet {
            var strengthDesc = "\(sets) × \(repsPerSet)"
            if let weight = weightSuggestion {
                strengthDesc += " @ \(weight)"
            }
            components.append(strengthDesc)
        }

        if let distance = targetDistance {
            components.append("\(Int(distance))m")
        }

        if let reps = targetReps {
            components.append("\(reps) reps")
        }

        if let duration = targetDuration {
            let minutes = Int(duration / 60)
            let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
            components.append(String(format: "%d:%02d", minutes, seconds))
        }

        return components.joined(separator: " • ")
    }

    var performancePercentage: Double? {
        // Calculate performance vs target
        if let target = targetDuration, let actual = actualDuration {
            return (target / actual) * 100
        }

        if let target = targetDistance, let actual = actualDistance {
            return (actual / target) * 100
        }

        if let target = targetReps, let actual = actualReps {
            return (Double(actual) / Double(target)) * 100
        }

        return nil
    }
}

// MARK: - Segment Type

enum SegmentType: String, Codable, CaseIterable {
    case run
    case station
    case transition
    case rest
    case warmup
    case cooldown
    case strength
    case finisher

    var displayName: String {
        switch self {
        case .run:
            return "Run"
        case .station:
            return "Station"
        case .transition:
            return "Transition"
        case .rest:
            return "Rest"
        case .warmup:
            return "Warm-up"
        case .cooldown:
            return "Cool-down"
        case .strength:
            return "Strength"
        case .finisher:
            return "Finisher"
        }
    }

    var icon: String {
        switch self {
        case .run:
            return "figure.run"
        case .station:
            return "dumbbell.fill"
        case .transition:
            return "arrow.right"
        case .rest:
            return "pause.fill"
        case .warmup:
            return "flame.fill"
        case .cooldown:
            return "snowflake"
        case .strength:
            return "dumbbell.fill"
        case .finisher:
            return "flame.fill"
        }
    }
}

// MARK: - Station Type

enum StationType: String, Codable, CaseIterable {
    case skiErg = "ski_erg"
    case sledPush = "sled_push"
    case sledPull = "sled_pull"
    case burpeeBroadJump = "burpee_broad_jump"
    case rowing = "rowing"
    case farmersCarry = "farmers_carry"
    case sandbagLunges = "sandbag_lunges"
    case wallBalls = "wall_balls"

    var displayName: String {
        switch self {
        case .skiErg:
            return "Ski Erg"
        case .sledPush:
            return "Sled Push"
        case .sledPull:
            return "Sled Pull"
        case .burpeeBroadJump:
            return "Burpee Broad Jump"
        case .rowing:
            return "Rowing"
        case .farmersCarry:
            return "Farmers Carry"
        case .sandbagLunges:
            return "Sandbag Lunges"
        case .wallBalls:
            return "Wall Balls"
        }
    }

    var icon: String {
        switch self {
        case .skiErg:
            return "figure.skiing.downhill"
        case .sledPush, .sledPull:
            return "figure.strengthtraining.functional"
        case .burpeeBroadJump:
            return "figure.jumprope"
        case .rowing:
            return "oar.2.crossed"
        case .farmersCarry:
            return "figure.walk"
        case .sandbagLunges:
            return "figure.strengthtraining.traditional"
        case .wallBalls:
            return "sportscourt.fill"
        }
    }

    var standardDistance: Double? {
        switch self {
        case .skiErg, .rowing:
            return 1000 // meters
        case .sledPush, .sledPull:
            return 50 // meters
        case .farmersCarry:
            return 200 // meters
        default:
            return nil
        }
    }

    var standardReps: Int? {
        switch self {
        case .burpeeBroadJump:
            return 80
        case .sandbagLunges:
            return 100
        case .wallBalls:
            return 100
        default:
            return nil
        }
    }

    var muscleGroups: [MuscleGroup] {
        switch self {
        case .skiErg:
            return [.shoulders, .core, .legs]
        case .sledPush:
            return [.legs, .glutes, .core]
        case .sledPull:
            return [.back, .legs, .arms]
        case .burpeeBroadJump:
            return [.fullBody, .legs, .core]
        case .rowing:
            return [.back, .legs, .arms, .core]
        case .farmersCarry:
            return [.grip, .core, .shoulders]
        case .sandbagLunges:
            return [.legs, .glutes, .core]
        case .wallBalls:
            return [.legs, .shoulders, .core]
        }
    }
}

enum MuscleGroup: String, Codable {
    case fullBody = "full_body"
    case legs
    case glutes
    case core
    case back
    case shoulders
    case arms
    case grip
}

// MARK: - Heart Rate Zones
// Note: HeartRateZones is defined in RunningSession.swift and shared across the app
