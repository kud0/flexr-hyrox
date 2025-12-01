import Foundation

struct Workout: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    var date: Date
    var type: WorkoutType
    var status: WorkoutStatus
    var segments: [WorkoutSegment]
    var totalDuration: TimeInterval?
    var estimatedCalories: Int?
    var readinessScore: Int?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        date: Date,
        type: WorkoutType,
        status: WorkoutStatus = .planned,
        segments: [WorkoutSegment] = [],
        totalDuration: TimeInterval? = nil,
        estimatedCalories: Int? = nil,
        readinessScore: Int? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.type = type
        self.status = status
        self.segments = segments
        self.totalDuration = totalDuration
        self.estimatedCalories = estimatedCalories
        self.readinessScore = readinessScore
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    var completedSegments: [WorkoutSegment] {
        segments.filter { $0.isCompleted }
    }

    var completionPercentage: Double {
        guard !segments.isEmpty else { return 0 }
        return Double(completedSegments.count) / Double(segments.count)
    }

    var actualDuration: TimeInterval {
        segments.compactMap { $0.actualDuration }.reduce(0, +)
    }

    var averageHeartRate: Double? {
        let hrValues = segments.compactMap { $0.avgHeartRate }
        guard !hrValues.isEmpty else { return nil }
        return hrValues.reduce(0, +) / Double(hrValues.count)
    }

    var maxHeartRate: Double? {
        segments.compactMap { $0.maxHeartRate }.max()
    }

    var totalDistance: Double {
        segments.compactMap { $0.actualDistance ?? $0.targetDistance }.reduce(0, +)
    }

    var runSegments: [WorkoutSegment] {
        segments.filter { $0.segmentType == .run }
    }

    var stationSegments: [WorkoutSegment] {
        segments.filter { $0.segmentType == .station }
    }

    var isCompleted: Bool {
        status == .completed
    }

    var canStart: Bool {
        status == .planned || status == .paused
    }

    var canPause: Bool {
        status == .inProgress
    }

    var canResume: Bool {
        status == .paused
    }
}

// MARK: - Workout Status

enum WorkoutStatus: String, Codable, CaseIterable {
    case planned
    case inProgress = "in_progress"
    case paused
    case completed
    case cancelled

    var displayName: String {
        switch self {
        case .planned:
            return "Planned"
        case .inProgress:
            return "In Progress"
        case .paused:
            return "Paused"
        case .completed:
            return "Completed"
        case .cancelled:
            return "Cancelled"
        }
    }

    var color: String {
        switch self {
        case .planned:
            return "blue"
        case .inProgress:
            return "green"
        case .paused:
            return "orange"
        case .completed:
            return "purple"
        case .cancelled:
            return "gray"
        }
    }
}

// MARK: - Workout Actions

extension Workout {
    mutating func start() {
        status = .inProgress
        updatedAt = Date()
    }

    mutating func pause() {
        status = .paused
        updatedAt = Date()
    }

    mutating func resume() {
        status = .inProgress
        updatedAt = Date()
    }

    mutating func complete() {
        status = .completed
        totalDuration = actualDuration
        updatedAt = Date()
    }

    mutating func cancel() {
        status = .cancelled
        updatedAt = Date()
    }

    mutating func addSegment(_ segment: WorkoutSegment) {
        segments.append(segment)
        updatedAt = Date()
    }

    mutating func updateSegment(_ segment: WorkoutSegment) {
        if let index = segments.firstIndex(where: { $0.id == segment.id }) {
            segments[index] = segment
            updatedAt = Date()
        }
    }

    mutating func removeSegment(_ segmentId: UUID) {
        segments.removeAll { $0.id == segmentId }
        updatedAt = Date()
    }
}

// MARK: - Workout Template

struct WorkoutTemplate: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let type: WorkoutType
    let segmentTemplates: [WorkoutSegmentTemplate]
    let estimatedDuration: TimeInterval
    let difficulty: WorkoutDifficulty
    let tags: [String]

    func createWorkout(for userId: UUID, on date: Date) -> Workout {
        let segments = segmentTemplates.map { $0.createSegment() }

        return Workout(
            userId: userId,
            date: date,
            type: type,
            status: .planned,
            segments: segments,
            estimatedCalories: calculateEstimatedCalories()
        )
    }

    private func calculateEstimatedCalories() -> Int {
        // Basic estimation: ~12 calories per minute for HYROX-style training
        return Int(estimatedDuration / 60 * 12)
    }
}

struct WorkoutSegmentTemplate: Identifiable, Codable {
    let id: UUID
    let segmentType: SegmentType
    let stationType: StationType?
    let targetDuration: TimeInterval?
    let targetDistance: Double?
    let targetReps: Int?
    let restDuration: TimeInterval?

    func createSegment() -> WorkoutSegment {
        return WorkoutSegment(
            workoutId: UUID(), // Will be updated when added to workout
            segmentType: segmentType,
            stationType: stationType,
            targetDuration: targetDuration,
            targetDistance: targetDistance,
            targetReps: targetReps
        )
    }
}

enum WorkoutDifficulty: String, Codable {
    case easy
    case moderate
    case hard
    case veryHard = "very_hard"

    var displayName: String {
        switch self {
        case .easy:
            return "Easy"
        case .moderate:
            return "Moderate"
        case .hard:
            return "Hard"
        case .veryHard:
            return "Very Hard"
        }
    }
}
