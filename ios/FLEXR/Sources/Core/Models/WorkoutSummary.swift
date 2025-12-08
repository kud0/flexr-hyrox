import Foundation

// MARK: - Workout Summary (Shared between Watch and iPhone)
struct WorkoutSummary: Codable {
    let id: UUID
    let workoutName: String
    let date: Date
    let totalTime: TimeInterval
    let segmentsCompleted: Int
    let totalSegments: Int
    let averageHeartRate: Int
    let maxHeartRate: Int
    let activeCalories: Int
    let totalDistance: Double
    let compromisedRuns: [CompromisedRun]
    let routeData: RouteData?
    let segmentResults: [SegmentResult]

    init(
        id: UUID = UUID(),
        workoutName: String,
        date: Date = Date(),
        totalTime: TimeInterval,
        segmentsCompleted: Int,
        totalSegments: Int,
        averageHeartRate: Int,
        maxHeartRate: Int,
        activeCalories: Int,
        totalDistance: Double,
        compromisedRuns: [CompromisedRun] = [],
        routeData: RouteData? = nil,
        segmentResults: [SegmentResult] = []
    ) {
        self.id = id
        self.workoutName = workoutName
        self.date = date
        self.totalTime = totalTime
        self.segmentsCompleted = segmentsCompleted
        self.totalSegments = totalSegments
        self.averageHeartRate = averageHeartRate
        self.maxHeartRate = maxHeartRate
        self.activeCalories = activeCalories
        self.totalDistance = totalDistance
        self.compromisedRuns = compromisedRuns
        self.routeData = routeData
        self.segmentResults = segmentResults
    }
}

// MARK: - Compromised Run
struct CompromisedRun: Codable {
    let segmentIndex: Int
    let segmentName: String
    let expectedPace: Double // seconds per km
    let actualPace: Double // seconds per km
    let degradation: Double // percentage

    var degradationSeconds: Int {
        Int((actualPace - expectedPace))
    }
}

// MARK: - Segment Result
struct SegmentResult: Codable {
    let index: Int
    let name: String
    let type: String // "run", "skierg", "sled_push", etc.
    let duration: TimeInterval
    let distance: Double?
    let averageHeartRate: Int?
    let caloriesBurned: Int?
    let completedAt: Date
}
