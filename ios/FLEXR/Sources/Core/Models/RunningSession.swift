// FLEXR - Running Session Models
// Comprehensive running analytics for HYROX athletes
// Focus: Performance metrics that matter

import Foundation

// MARK: - Running Session Type

enum RunningSessionType: String, Codable, CaseIterable {
    case longRun = "long_run"
    case intervals = "intervals"
    case threshold = "threshold"
    case timeTrial5k = "time_trial_5k"
    case timeTrial10k = "time_trial_10k"
    case recovery = "recovery"
    case easy = "easy"

    var displayName: String {
        switch self {
        case .longRun:
            return "Long Run"
        case .intervals:
            return "Intervals"
        case .threshold:
            return "Threshold"
        case .timeTrial5k:
            return "5K Time Trial"
        case .timeTrial10k:
            return "10K Time Trial"
        case .recovery:
            return "Recovery Run"
        case .easy:
            return "Easy Run"
        }
    }

    var icon: String {
        switch self {
        case .longRun:
            return "figure.run"
        case .intervals:
            return "speedometer"
        case .threshold:
            return "gauge.high"
        case .timeTrial5k, .timeTrial10k:
            return "stopwatch"
        case .recovery:
            return "moon.zzz"
        case .easy:
            return "figure.walk"
        }
    }

    var color: String {
        switch self {
        case .longRun:
            return "blue"
        case .intervals:
            return "red"
        case .threshold:
            return "orange"
        case .timeTrial5k, .timeTrial10k:
            return "purple"
        case .recovery:
            return "green"
        case .easy:
            return "gray"
        }
    }
}

// MARK: - Activity Visibility

enum ActivityVisibility: String, Codable, CaseIterable {
    case `private`
    case friends
    case gym
    case `public`

    var displayName: String {
        switch self {
        case .private:
            return "Private"
        case .friends:
            return "Friends"
        case .gym:
            return "Gym Members"
        case .public:
            return "Public"
        }
    }

    var icon: String {
        switch self {
        case .private:
            return "lock.fill"
        case .friends:
            return "person.2.fill"
        case .gym:
            return "building.2.fill"
        case .public:
            return "globe"
        }
    }
}

// MARK: - Running Session

struct RunningSession: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    let gymId: UUID?
    let sessionType: RunningSessionType
    let workoutId: UUID?

    // Basic metrics
    let distanceMeters: Int
    let durationSeconds: TimeInterval
    let elevationGainMeters: Int?

    // Pace
    let avgPacePerKm: TimeInterval  // seconds per km
    let fastestKmPace: TimeInterval?
    let slowestKmPace: TimeInterval?

    // Heart Rate
    let avgHeartRate: Int?
    let maxHeartRate: Int?
    let heartRateZones: HeartRateZones?

    // Detailed data
    let splits: [Split]?
    let routeData: RouteData?

    // Analysis
    let paceConsistency: Double?  // Standard deviation
    let fadeFactor: Double?       // % slower in second half (negative = negative split)

    let createdAt: Date
    let startedAt: Date?
    let endedAt: Date?
    let visibility: ActivityVisibility
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case gymId = "gym_id"
        case sessionType = "session_type"
        case workoutId = "workout_id"
        case distanceMeters = "distance_meters"
        case durationSeconds = "duration_seconds"
        case elevationGainMeters = "elevation_gain_meters"
        case avgPacePerKm = "avg_pace_per_km"
        case fastestKmPace = "fastest_km_pace"
        case slowestKmPace = "slowest_km_pace"
        case avgHeartRate = "avg_heart_rate"
        case maxHeartRate = "max_heart_rate"
        case heartRateZones = "heart_rate_zones"
        case splits
        case routeData = "route_data"
        case paceConsistency = "pace_consistency"
        case fadeFactor = "fade_factor"
        case createdAt = "created_at"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case visibility
        case notes
    }

    // MARK: - Computed Properties for Display

    var distanceKm: Double {
        Double(distanceMeters) / 1000.0
    }

    var displayDistance: String {
        String(format: "%.2f km", distanceKm)
    }

    var displayDuration: String {
        let hours = Int(durationSeconds) / 3600
        let minutes = (Int(durationSeconds) % 3600) / 60
        let seconds = Int(durationSeconds) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    var displayPace: String {
        formatPace(avgPacePerKm)
    }

    var displayFastestPace: String? {
        guard let pace = fastestKmPace else { return nil }
        return formatPace(pace)
    }

    var displaySlowestPace: String? {
        guard let pace = slowestKmPace else { return nil }
        return formatPace(pace)
    }

    var displayElevationGain: String? {
        guard let elevation = elevationGainMeters else { return nil }
        return "\(elevation)m"
    }

    var displayAvgHeartRate: String? {
        guard let hr = avgHeartRate else { return nil }
        return "\(hr) bpm"
    }

    var displayMaxHeartRate: String? {
        guard let hr = maxHeartRate else { return nil }
        return "\(hr) bpm"
    }

    var displayPaceConsistency: String? {
        guard let consistency = paceConsistency else { return nil }
        // Lower is better
        if consistency < 10 {
            return "Excellent"
        } else if consistency < 20 {
            return "Good"
        } else if consistency < 30 {
            return "Fair"
        } else {
            return "Variable"
        }
    }

    var displayFadeFactor: String? {
        guard let fade = fadeFactor else { return nil }
        if fade < 0 {
            // Negative split (faster in second half)
            return "Negative Split (\(String(format: "%.1f", abs(fade)))%)"
        } else if fade == 0 {
            return "Even Split"
        } else {
            // Positive split (slower in second half)
            return "Positive Split (+\(String(format: "%.1f", fade))%)"
        }
    }

    // MARK: - Helper Functions

    private func formatPace(_ secondsPerKm: TimeInterval) -> String {
        let mins = Int(secondsPerKm) / 60
        let secs = Int(secondsPerKm) % 60
        return String(format: "%d:%02d /km", mins, secs)
    }

    /// Calculate estimated finish time for a given distance
    func estimatedTimeForDistance(_ distanceKm: Double) -> TimeInterval {
        avgPacePerKm * distanceKm
    }

    /// Check if this is a personal record for the distance
    func isPR(comparedTo previousSessions: [RunningSession]) -> Bool {
        let sameDist = previousSessions.filter {
            abs(Double($0.distanceMeters - distanceMeters)) < 100  // Within 100m
        }
        guard !sameDist.isEmpty else { return true }  // First session = PR

        return sameDist.allSatisfy { $0.avgPacePerKm > avgPacePerKm }  // Faster than all previous
    }
}

// MARK: - Split

struct Split: Codable, Equatable {
    let km: Int
    let timeSeconds: TimeInterval
    let pacePerKm: TimeInterval
    let heartRate: Int?
    let elevationGain: Int?

    enum CodingKeys: String, CodingKey {
        case km
        case timeSeconds = "time"
        case pacePerKm = "pace"
        case heartRate = "hr"
        case elevationGain = "elevation"
    }

    var displayPace: String {
        // Handle invalid/negative values
        guard pacePerKm > 0 && pacePerKm < 3600 else { return "--:--" }
        let mins = Int(pacePerKm) / 60
        let secs = Int(pacePerKm) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    var displayTime: String {
        // Handle invalid/negative values
        guard timeSeconds > 0 && timeSeconds < 36000 else { return "--:--" }
        let mins = Int(timeSeconds) / 60
        let secs = Int(timeSeconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    var displayHeartRate: String? {
        guard let hr = heartRate else { return nil }
        return "\(hr) bpm"
    }

    /// Check if this split is faster than target pace
    func isFasterThan(_ targetPace: TimeInterval) -> Bool {
        pacePerKm < targetPace
    }

    /// Calculate difference from target pace
    func paceDifference(from targetPace: TimeInterval) -> TimeInterval {
        pacePerKm - targetPace
    }
}

// MARK: - Heart Rate Zones

struct HeartRateZones: Codable, Equatable {
    let zone1Seconds: TimeInterval  // Recovery (<60% max)
    let zone2Seconds: TimeInterval  // Aerobic (60-70%)
    let zone3Seconds: TimeInterval  // Tempo (70-80%)
    let zone4Seconds: TimeInterval  // Threshold (80-90%)
    let zone5Seconds: TimeInterval  // Max (90%+)

    enum CodingKeys: String, CodingKey {
        case zone1Seconds = "zone1"
        case zone2Seconds = "zone2"
        case zone3Seconds = "zone3"
        case zone4Seconds = "zone4"
        case zone5Seconds = "zone5"
    }

    var totalTime: TimeInterval {
        zone1Seconds + zone2Seconds + zone3Seconds + zone4Seconds + zone5Seconds
    }

    func percentInZone(_ zone: Int) -> Double {
        guard totalTime > 0 else { return 0 }
        let time: TimeInterval
        switch zone {
        case 1: time = zone1Seconds
        case 2: time = zone2Seconds
        case 3: time = zone3Seconds
        case 4: time = zone4Seconds
        case 5: time = zone5Seconds
        default: return 0
        }
        return (time / totalTime) * 100
    }

    func displayTime(forZone zone: Int) -> String {
        let time: TimeInterval
        switch zone {
        case 1: time = zone1Seconds
        case 2: time = zone2Seconds
        case 3: time = zone3Seconds
        case 4: time = zone4Seconds
        case 5: time = zone5Seconds
        default: return "0:00"
        }

        let mins = Int(time) / 60
        let secs = Int(time) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    var dominantZone: Int {
        let zones = [
            (1, zone1Seconds),
            (2, zone2Seconds),
            (3, zone3Seconds),
            (4, zone4Seconds),
            (5, zone5Seconds)
        ]
        return zones.max(by: { $0.1 < $1.1 })?.0 ?? 2
    }
}

// MARK: - Route Data
// Note: RouteData is defined in RouteData.swift and shared across the app

// MARK: - Interval Session

struct IntervalSession: Identifiable, Codable, Equatable {
    let id: UUID
    let runningSessionId: UUID

    // Structure
    let workDistanceMeters: Int
    let restDurationSeconds: TimeInterval
    let targetPacePerKm: TimeInterval?
    let totalReps: Int

    // Performance
    let intervals: [IntervalRep]

    // Analysis
    let avgWorkPace: TimeInterval
    let paceDropOff: Double?        // % slower on last vs first
    let recoveryQuality: Double?    // Avg HR drop during rest

    enum CodingKeys: String, CodingKey {
        case id
        case runningSessionId = "running_session_id"
        case workDistanceMeters = "work_distance_meters"
        case restDurationSeconds = "rest_duration_seconds"
        case targetPacePerKm = "target_pace_per_km"
        case totalReps = "total_reps"
        case intervals
        case avgWorkPace = "avg_work_pace"
        case paceDropOff = "pace_drop_off"
        case recoveryQuality = "recovery_quality"
    }

    var displayTargetPace: String? {
        guard let pace = targetPacePerKm else { return nil }
        let mins = Int(pace) / 60
        let secs = Int(pace) % 60
        return String(format: "%d:%02d /km", mins, secs)
    }

    var displayAvgPace: String {
        let mins = Int(avgWorkPace) / 60
        let secs = Int(avgWorkPace) % 60
        return String(format: "%d:%02d /km", mins, secs)
    }

    var displayWorkDistance: String {
        if workDistanceMeters >= 1000 {
            return "\(workDistanceMeters / 1000)k"
        } else {
            return "\(workDistanceMeters)m"
        }
    }

    var displayRestDuration: String {
        let mins = Int(restDurationSeconds) / 60
        let secs = Int(restDurationSeconds) % 60
        if mins > 0 {
            return String(format: "%dm %ds", mins, secs)
        } else {
            return String(format: "%ds", secs)
        }
    }

    var displayPaceDropOff: String? {
        guard let dropOff = paceDropOff else { return nil }
        if dropOff > 0 {
            return "+\(String(format: "%.1f", dropOff))%"
        } else {
            return String(format: "%.1f", dropOff) + "%"
        }
    }

    var displayRecoveryQuality: String? {
        guard let quality = recoveryQuality else { return nil }
        if quality > 20 {
            return "Excellent"
        } else if quality > 15 {
            return "Good"
        } else if quality > 10 {
            return "Fair"
        } else {
            return "Poor"
        }
    }

    /// Check if user hit their target pace
    func hitTargetPace(tolerance: TimeInterval = 5.0) -> Bool {
        guard let target = targetPacePerKm else { return true }
        return abs(avgWorkPace - target) <= tolerance
    }
}

// MARK: - Interval Rep

struct IntervalRep: Codable, Equatable {
    let rep: Int
    let distanceMeters: Int
    let timeSeconds: TimeInterval
    let pacePerKm: TimeInterval
    let avgHeartRate: Int?
    let maxHeartRate: Int?

    enum CodingKeys: String, CodingKey {
        case rep
        case distanceMeters = "distance"
        case timeSeconds = "time"
        case pacePerKm = "pace"
        case avgHeartRate = "hr_avg"
        case maxHeartRate = "hr_max"
    }

    var displayPace: String {
        let mins = Int(pacePerKm) / 60
        let secs = Int(pacePerKm) % 60
        return String(format: "%d:%02d /km", mins, secs)
    }

    var displayTime: String {
        let mins = Int(timeSeconds) / 60
        let secs = Int(timeSeconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    var displayHeartRate: String? {
        guard let hr = avgHeartRate else { return nil }
        return "\(hr) bpm"
    }

    /// Calculate pace difference from target
    func paceDifference(from target: TimeInterval) -> TimeInterval {
        pacePerKm - target
    }

    /// Check if this rep was faster than target
    func isFasterThan(_ targetPace: TimeInterval) -> Bool {
        pacePerKm < targetPace
    }
}
