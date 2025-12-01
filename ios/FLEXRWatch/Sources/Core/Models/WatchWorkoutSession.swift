import Foundation
import HealthKit

/// Represents the active workout session state on Apple Watch
class WatchWorkoutSession: ObservableObject, Codable {
    // MARK: - Properties

    let id: UUID
    let workoutId: UUID
    let workoutName: String
    let segments: [WorkoutSegment]
    let startTime: Date

    @Published var currentSegmentIndex: Int
    @Published var segmentStartTime: Date?
    @Published var isTransitioning: Bool
    @Published var isPaused: Bool
    @Published var endTime: Date?

    // Live metrics
    @Published var currentHeartRate: Int = 0
    @Published var averageHeartRate: Int = 0
    @Published var maxHeartRate: Int = 0
    @Published var currentPace: Double = 0.0 // min/km
    @Published var currentDistance: Double = 0.0 // meters
    @Published var currentReps: Int = 0
    @Published var activeCalories: Int = 0

    // Segment-specific metrics
    @Published var segmentMetrics: [SegmentMetrics] = []

    // Haptic feedback state
    @Published var shouldTriggerHaptic: HapticFeedbackType?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        workoutId: UUID,
        workoutName: String,
        segments: [WorkoutSegment],
        startTime: Date = Date()
    ) {
        self.id = id
        self.workoutId = workoutId
        self.workoutName = workoutName
        self.segments = segments
        self.startTime = startTime
        self.currentSegmentIndex = 0
        self.isTransitioning = false
        self.isPaused = false
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, workoutId, workoutName, segments, startTime
        case currentSegmentIndex, segmentStartTime, isTransitioning, isPaused, endTime
        case currentHeartRate, averageHeartRate, maxHeartRate
        case currentPace, currentDistance, currentReps, activeCalories
        case segmentMetrics
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        workoutId = try container.decode(UUID.self, forKey: .workoutId)
        workoutName = try container.decode(String.self, forKey: .workoutName)
        segments = try container.decode([WorkoutSegment].self, forKey: .segments)
        startTime = try container.decode(Date.self, forKey: .startTime)
        currentSegmentIndex = try container.decode(Int.self, forKey: .currentSegmentIndex)
        segmentStartTime = try container.decodeIfPresent(Date.self, forKey: .segmentStartTime)
        isTransitioning = try container.decode(Bool.self, forKey: .isTransitioning)
        isPaused = try container.decode(Bool.self, forKey: .isPaused)
        endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        currentHeartRate = try container.decode(Int.self, forKey: .currentHeartRate)
        averageHeartRate = try container.decode(Int.self, forKey: .averageHeartRate)
        maxHeartRate = try container.decode(Int.self, forKey: .maxHeartRate)
        currentPace = try container.decode(Double.self, forKey: .currentPace)
        currentDistance = try container.decode(Double.self, forKey: .currentDistance)
        currentReps = try container.decode(Int.self, forKey: .currentReps)
        activeCalories = try container.decode(Int.self, forKey: .activeCalories)
        segmentMetrics = try container.decode([SegmentMetrics].self, forKey: .segmentMetrics)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(workoutId, forKey: .workoutId)
        try container.encode(workoutName, forKey: .workoutName)
        try container.encode(segments, forKey: .segments)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(currentSegmentIndex, forKey: .currentSegmentIndex)
        try container.encodeIfPresent(segmentStartTime, forKey: .segmentStartTime)
        try container.encode(isTransitioning, forKey: .isTransitioning)
        try container.encode(isPaused, forKey: .isPaused)
        try container.encodeIfPresent(endTime, forKey: .endTime)
        try container.encode(currentHeartRate, forKey: .currentHeartRate)
        try container.encode(averageHeartRate, forKey: .averageHeartRate)
        try container.encode(maxHeartRate, forKey: .maxHeartRate)
        try container.encode(currentPace, forKey: .currentPace)
        try container.encode(currentDistance, forKey: .currentDistance)
        try container.encode(currentReps, forKey: .currentReps)
        try container.encode(activeCalories, forKey: .activeCalories)
        try container.encode(segmentMetrics, forKey: .segmentMetrics)
    }

    // MARK: - Computed Properties

    var currentSegment: WorkoutSegment? {
        guard currentSegmentIndex < segments.count else { return nil }
        return segments[currentSegmentIndex]
    }

    var nextSegment: WorkoutSegment? {
        let nextIndex = currentSegmentIndex + 1
        guard nextIndex < segments.count else { return nil }
        return segments[nextIndex]
    }

    var totalElapsedTime: TimeInterval {
        if let endTime = endTime {
            return endTime.timeIntervalSince(startTime)
        }
        return Date().timeIntervalSince(startTime)
    }

    var segmentElapsedTime: TimeInterval {
        guard let segmentStart = segmentStartTime else { return 0 }
        return Date().timeIntervalSince(segmentStart)
    }

    var isComplete: Bool {
        return endTime != nil || currentSegmentIndex >= segments.count
    }

    var completionPercentage: Double {
        guard segments.count > 0 else { return 0 }
        return Double(currentSegmentIndex) / Double(segments.count)
    }

    // MARK: - Segment Management

    func startSegment(at index: Int) {
        guard index < segments.count else { return }
        currentSegmentIndex = index
        segmentStartTime = Date()
        isTransitioning = false
        currentReps = 0
        currentDistance = 0.0

        // Trigger haptic feedback
        shouldTriggerHaptic = .segmentStart
    }

    func completeCurrentSegment() {
        guard let segment = currentSegment,
              let segmentStart = segmentStartTime else { return }

        let duration = Date().timeIntervalSince(segmentStart)

        // Record segment metrics
        let metrics = SegmentMetrics(
            segmentId: segment.id,
            segmentName: segment.name,
            segmentType: segment.type,
            duration: duration,
            averageHeartRate: calculateSegmentAverageHR(),
            maxHeartRate: maxHeartRate,
            distance: currentDistance > 0 ? currentDistance : nil,
            reps: currentReps > 0 ? currentReps : nil,
            pace: segment.type == .run ? currentPace : nil
        )

        segmentMetrics.append(metrics)

        // Move to transition state
        isTransitioning = true
        shouldTriggerHaptic = .segmentComplete
    }

    func startNextSegment() {
        let nextIndex = currentSegmentIndex + 1
        if nextIndex < segments.count {
            startSegment(at: nextIndex)
        } else {
            finishWorkout()
        }
    }

    func finishWorkout() {
        endTime = Date()
        shouldTriggerHaptic = .workoutComplete
    }

    // MARK: - Metrics Updates

    func updateHeartRate(_ heartRate: Int) {
        currentHeartRate = heartRate
        maxHeartRate = max(maxHeartRate, heartRate)
        updateAverageHeartRate(heartRate)

        // Check for heart rate alerts
        if shouldAlertHighHeartRate(heartRate) {
            shouldTriggerHaptic = .heartRateWarning
        }
    }

    func updatePace(_ pace: Double) {
        currentPace = pace
    }

    func updateDistance(_ distance: Double) {
        currentDistance = distance
    }

    func incrementReps() {
        currentReps += 1
        shouldTriggerHaptic = .repComplete
    }

    func updateCalories(_ calories: Int) {
        activeCalories = calories
    }

    // MARK: - Private Helpers

    private var heartRateSamples: [Int] = []

    private func updateAverageHeartRate(_ heartRate: Int) {
        heartRateSamples.append(heartRate)

        // Keep last 60 samples (1 minute at 1Hz)
        if heartRateSamples.count > 60 {
            heartRateSamples.removeFirst()
        }

        if !heartRateSamples.isEmpty {
            averageHeartRate = heartRateSamples.reduce(0, +) / heartRateSamples.count
        }
    }

    private func calculateSegmentAverageHR() -> Int {
        guard !heartRateSamples.isEmpty else { return currentHeartRate }
        return heartRateSamples.reduce(0, +) / heartRateSamples.count
    }

    private func shouldAlertHighHeartRate(_ heartRate: Int) -> Bool {
        // Alert if HR is above 90% of estimated max (220 - age)
        // For now, use a fixed threshold of 180 BPM
        return heartRate > 180
    }

    // MARK: - Summary Generation

    func generateSummary() -> WorkoutSummary {
        let totalTime = endTime?.timeIntervalSince(startTime) ?? totalElapsedTime
        let totalDistance = segmentMetrics.compactMap { $0.distance }.reduce(0, +)
        let compromisedRuns = detectCompromisedRuns()

        return WorkoutSummary(
            workoutName: workoutName,
            totalTime: totalTime,
            segmentsCompleted: currentSegmentIndex,
            totalSegments: segments.count,
            averageHeartRate: averageHeartRate,
            maxHeartRate: maxHeartRate,
            activeCalories: activeCalories,
            totalDistance: totalDistance,
            compromisedRuns: compromisedRuns,
            segmentResults: segmentMetrics.map { metrics in
                SegmentResult(
                    segmentName: metrics.segmentName,
                    type: metrics.segmentType,
                    duration: metrics.duration,
                    averageHeartRate: metrics.averageHeartRate,
                    maxHeartRate: metrics.maxHeartRate,
                    distance: metrics.distance,
                    reps: metrics.reps
                )
            }
        )
    }

    private func detectCompromisedRuns() -> [CompromisedRun] {
        var compromised: [CompromisedRun] = []

        for metrics in segmentMetrics where metrics.segmentType == .run {
            // Check if average HR during run was too high (>85% max)
            let hrThreshold = 153 // ~85% of 180 max
            if metrics.averageHeartRate > hrThreshold {
                let expectedTime = metrics.segmentType == .run ? 300.0 : 0 // 5 min baseline
                let compromisedSeconds = Int(metrics.duration - expectedTime)

                if compromisedSeconds > 0 {
                    compromised.append(CompromisedRun(
                        segmentName: metrics.segmentName,
                        compromisedSeconds: compromisedSeconds,
                        reason: "High heart rate (\(metrics.averageHeartRate) BPM)"
                    ))
                }
            }
        }

        return compromised
    }
}

// MARK: - Supporting Types

struct SegmentMetrics: Codable {
    let id: UUID
    let segmentId: UUID
    let segmentName: String
    let segmentType: SegmentType
    let duration: TimeInterval
    let averageHeartRate: Int
    let maxHeartRate: Int
    let distance: Double?
    let reps: Int?
    let pace: Double?

    init(
        id: UUID = UUID(),
        segmentId: UUID,
        segmentName: String,
        segmentType: SegmentType,
        duration: TimeInterval,
        averageHeartRate: Int,
        maxHeartRate: Int,
        distance: Double? = nil,
        reps: Int? = nil,
        pace: Double? = nil
    ) {
        self.id = id
        self.segmentId = segmentId
        self.segmentName = segmentName
        self.segmentType = segmentType
        self.duration = duration
        self.averageHeartRate = averageHeartRate
        self.maxHeartRate = maxHeartRate
        self.distance = distance
        self.reps = reps
        self.pace = pace
    }
}

enum HapticFeedbackType {
    case segmentStart
    case segmentComplete
    case repComplete
    case heartRateWarning
    case workoutComplete
    case milestone
}
