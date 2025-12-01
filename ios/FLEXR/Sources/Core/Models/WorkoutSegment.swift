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
    var isCompromised: Bool? // for runs after stations

    // Context
    var previousStation: StationType? // for compromised run analysis
    var transitionTime: TimeInterval? // time between segments

    // Metadata
    var startTime: Date?
    var endTime: Date?
    var notes: String?

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
        isCompromised: Bool? = nil,
        previousStation: StationType? = nil,
        transitionTime: TimeInterval? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil,
        notes: String? = nil
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
        self.isCompromised = isCompromised
        self.previousStation = previousStation
        self.transitionTime = transitionTime
        self.startTime = startTime
        self.endTime = endTime
        self.notes = notes
    }

    // MARK: - Computed Properties

    var isCompleted: Bool {
        actualDuration != nil || actualDistance != nil || actualReps != nil
    }

    var displayName: String {
        if segmentType == .station, let station = stationType {
            return station.displayName
        }
        return segmentType.displayName
    }

    var targetDescription: String {
        var components: [String] = []

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
            return "figure.rowing"
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

struct HeartRateZones: Codable, Equatable {
    var zone1Duration: TimeInterval = 0 // Recovery (50-60% max HR)
    var zone2Duration: TimeInterval = 0 // Aerobic (60-70% max HR)
    var zone3Duration: TimeInterval = 0 // Tempo (70-80% max HR)
    var zone4Duration: TimeInterval = 0 // Threshold (80-90% max HR)
    var zone5Duration: TimeInterval = 0 // Max (90-100% max HR)

    var totalDuration: TimeInterval {
        zone1Duration + zone2Duration + zone3Duration + zone4Duration + zone5Duration
    }

    var dominantZone: Int {
        let zones = [zone1Duration, zone2Duration, zone3Duration, zone4Duration, zone5Duration]
        guard let maxDuration = zones.max(),
              let index = zones.firstIndex(of: maxDuration) else {
            return 3
        }
        return index + 1
    }

    func percentage(for zone: Int) -> Double {
        guard totalDuration > 0, zone >= 1, zone <= 5 else { return 0 }

        let zoneDuration: TimeInterval
        switch zone {
        case 1: zoneDuration = zone1Duration
        case 2: zoneDuration = zone2Duration
        case 3: zoneDuration = zone3Duration
        case 4: zoneDuration = zone4Duration
        case 5: zoneDuration = zone5Duration
        default: return 0
        }

        return (zoneDuration / totalDuration) * 100
    }
}
