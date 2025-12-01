import Foundation

struct PerformanceProfile: Codable, Equatable {
    let userId: UUID
    var freshRunPace: RunPace
    var compromisedRunPaces: [StationType: RunPace]
    var stationBenchmarks: [StationType: StationBenchmark]
    var recoveryProfile: RecoveryProfile
    var lastUpdated: Date
    var totalWorkoutsAnalyzed: Int
    var confidenceScore: Double

    init(
        userId: UUID,
        freshRunPace: RunPace,
        compromisedRunPaces: [StationType: RunPace] = [:],
        stationBenchmarks: [StationType: StationBenchmark] = [:],
        recoveryProfile: RecoveryProfile,
        lastUpdated: Date = Date(),
        totalWorkoutsAnalyzed: Int = 0,
        confidenceScore: Double = 0.0
    ) {
        self.userId = userId
        self.freshRunPace = freshRunPace
        self.compromisedRunPaces = compromisedRunPaces
        self.stationBenchmarks = stationBenchmarks
        self.recoveryProfile = recoveryProfile
        self.lastUpdated = lastUpdated
        self.totalWorkoutsAnalyzed = totalWorkoutsAnalyzed
        self.confidenceScore = confidenceScore
    }

    // MARK: - Pace Predictions

    func predictedPace(after station: StationType?) -> RunPace {
        if let station = station, let compromisedPace = compromisedRunPaces[station] {
            return compromisedPace
        }
        return freshRunPace
    }

    func paceSlowdown(after station: StationType) -> Double {
        guard let compromisedPace = compromisedRunPaces[station] else { return 0 }
        return compromisedPace.minPerKm - freshRunPace.minPerKm
    }

    // MARK: - Station Performance

    func benchmark(for station: StationType) -> StationBenchmark? {
        return stationBenchmarks[station]
    }

    func isImproving(for station: StationType) -> Bool {
        guard let benchmark = stationBenchmarks[station] else { return false }
        return benchmark.trend == .improving
    }

    // MARK: - Workout Predictions

    func predictWorkoutTime(segments: [WorkoutSegment]) -> TimeInterval {
        var totalTime: TimeInterval = 0
        var previousStation: StationType?

        for segment in segments {
            switch segment.segmentType {
            case .run:
                let pace = predictedPace(after: previousStation)
                if let distance = segment.targetDistance {
                    let timeInSeconds = (distance / 1000) * pace.minPerKm * 60
                    totalTime += timeInSeconds
                }

            case .station:
                if let station = segment.stationType,
                   let benchmark = stationBenchmarks[station] {
                    totalTime += benchmark.avgDuration
                    previousStation = station
                }

            case .transition:
                totalTime += recoveryProfile.avgTransitionTime

            case .rest:
                if let duration = segment.targetDuration {
                    totalTime += duration
                }

            default:
                break
            }
        }

        return totalTime
    }

    func predictedFinishTime(for workoutType: WorkoutType) -> TimeInterval {
        // Standard HYROX predictions based on profile
        switch workoutType {
        case .fullSimulation:
            // 8km run + 8 stations
            let runTime = 8 * freshRunPace.minPerKm * 60
            let stationTime = stationBenchmarks.values.reduce(0) { $0 + $1.avgDuration }
            let transitionTime = 8 * recoveryProfile.avgTransitionTime
            return runTime + stationTime + transitionTime

        default:
            return 0
        }
    }
}

// MARK: - Run Pace

struct RunPace: Codable, Equatable {
    var minPerKm: Double
    var minPerMile: Double
    var confidenceLevel: Double // 0.0 - 1.0
    var sampleSize: Int
    var lastRecorded: Date

    init(
        minPerKm: Double,
        minPerMile: Double = 0,
        confidenceLevel: Double = 0.5,
        sampleSize: Int = 0,
        lastRecorded: Date = Date()
    ) {
        self.minPerKm = minPerKm
        self.minPerMile = minPerMile > 0 ? minPerMile : minPerKm * 1.60934
        self.confidenceLevel = confidenceLevel
        self.sampleSize = sampleSize
        self.lastRecorded = lastRecorded
    }

    var paceString: String {
        let minutes = Int(minPerKm)
        let seconds = Int((minPerKm - Double(minutes)) * 60)
        return String(format: "%d:%02d /km", minutes, seconds)
    }

    var speedKmh: Double {
        return 60 / minPerKm
    }

    var isReliable: Bool {
        return confidenceLevel >= 0.7 && sampleSize >= 3
    }
}

// MARK: - Station Benchmark

struct StationBenchmark: Codable, Equatable {
    let stationType: StationType
    var avgDuration: TimeInterval
    var bestDuration: TimeInterval
    var avgReps: Int?
    var bestReps: Int?
    var avgHeartRate: Double
    var peakHeartRate: Double
    var confidenceLevel: Double
    var sampleSize: Int
    var trend: PerformanceTrend
    var lastRecorded: Date

    var improvementRate: Double {
        guard sampleSize > 1 else { return 0 }
        // Percentage improvement from average to best
        return ((avgDuration - bestDuration) / avgDuration) * 100
    }

    var formattedDuration: String {
        let minutes = Int(avgDuration / 60)
        let seconds = Int(avgDuration.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedBestDuration: String {
        let minutes = Int(bestDuration / 60)
        let seconds = Int(bestDuration.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
}

enum PerformanceTrend: String, Codable {
    case improving
    case stable
    case declining
    case insufficient_data

    var icon: String {
        switch self {
        case .improving:
            return "arrow.up.right"
        case .stable:
            return "arrow.right"
        case .declining:
            return "arrow.down.right"
        case .insufficient_data:
            return "questionmark"
        }
    }

    var color: String {
        switch self {
        case .improving:
            return "green"
        case .stable:
            return "blue"
        case .declining:
            return "red"
        case .insufficient_data:
            return "gray"
        }
    }
}

// MARK: - Recovery Profile

struct RecoveryProfile: Codable, Equatable {
    var hrRecoveryRate: Double // BPM per minute
    var avgRecoveryTime: TimeInterval // seconds to drop 20 BPM
    var restingHeartRate: Double?
    var maxHeartRate: Double?
    var hrvBaseline: Double? // HRV in ms
    var avgTransitionTime: TimeInterval
    var confidenceLevel: Double
    var lastUpdated: Date

    init(
        hrRecoveryRate: Double,
        avgRecoveryTime: TimeInterval,
        restingHeartRate: Double? = nil,
        maxHeartRate: Double? = nil,
        hrvBaseline: Double? = nil,
        avgTransitionTime: TimeInterval = 30,
        confidenceLevel: Double = 0.5,
        lastUpdated: Date = Date()
    ) {
        self.hrRecoveryRate = hrRecoveryRate
        self.avgRecoveryTime = avgRecoveryTime
        self.restingHeartRate = restingHeartRate
        self.maxHeartRate = maxHeartRate
        self.hrvBaseline = hrvBaseline
        self.avgTransitionTime = avgTransitionTime
        self.confidenceLevel = confidenceLevel
        self.lastUpdated = lastUpdated
    }

    var recoveryQuality: RecoveryQuality {
        // Based on HR recovery rate (higher is better)
        if hrRecoveryRate >= 25 {
            return .excellent
        } else if hrRecoveryRate >= 20 {
            return .good
        } else if hrRecoveryRate >= 15 {
            return .fair
        } else {
            return .poor
        }
    }

    func estimatedRecoveryTime(from heartRate: Double, to target: Double) -> TimeInterval {
        guard hrRecoveryRate > 0, heartRate > target else { return 0 }
        let bpmDrop = heartRate - target
        return (bpmDrop / hrRecoveryRate) * 60
    }
}

enum RecoveryQuality: String, Codable {
    case excellent
    case good
    case fair
    case poor

    var displayName: String {
        rawValue.capitalized
    }

    var color: String {
        switch self {
        case .excellent:
            return "green"
        case .good:
            return "blue"
        case .fair:
            return "orange"
        case .poor:
            return "red"
        }
    }
}

// MARK: - AI Training Data

struct TrainingDataPoint: Codable {
    let workoutId: UUID
    let segmentId: UUID
    let timestamp: Date
    let segmentType: SegmentType
    let stationType: StationType?
    let previousStation: StationType?
    let duration: TimeInterval
    let distance: Double?
    let reps: Int?
    let avgHeartRate: Double
    let avgPace: Double?
    let hrvBefore: Double?
    let sleepQuality: Double?
    let readinessScore: Int?

    // Used for ML model training to predict:
    // - Compromised run paces
    // - Station performance
    // - Recovery needs
    // - Optimal training load
}
