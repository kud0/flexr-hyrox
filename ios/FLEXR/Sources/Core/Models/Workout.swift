import Foundation

struct Workout: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    var name: String?  // Workout name from AI generation
    var date: Date
    var type: WorkoutType
    var status: WorkoutStatus
    var segments: [WorkoutSegment]
    var sections: [WorkoutSection]?  // Grouped sections for UI display
    var sectionsMetadata: [SectionMetadata]?  // Lightweight metadata for reconstruction
    var totalDuration: TimeInterval?
    var estimatedDurationMinutes: Int?  // AI-estimated duration
    var estimatedCalories: Int?
    var readinessScore: Int?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    var routeData: RouteData?
    var gpsSource: GPSSource?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case date = "scheduled_at"
        case type = "workout_type"
        case legacyType = "type"  // Fallback for old DB column
        case status
        case segments = "workout_segments"
        case sections
        case sectionsMetadata = "sections_metadata"
        case totalDuration = "total_duration"
        case estimatedDurationMinutes = "estimated_duration_minutes"
        case estimatedCalories = "estimated_calories"
        case readinessScore = "readiness_score"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case routeData = "route_data"
        case gpsSource = "gps_source"
    }

    // Custom decoder to handle DB response with backwards compatibility
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        name = try container.decodeIfPresent(String.self, forKey: .name)

        // Try workout_type first, fall back to type for older records
        if let workoutType = try container.decodeIfPresent(WorkoutType.self, forKey: .type) {
            type = workoutType
        } else if let legacyType = try container.decodeIfPresent(WorkoutType.self, forKey: .legacyType) {
            type = legacyType
        } else {
            type = .custom  // Default fallback
        }

        status = try container.decodeIfPresent(WorkoutStatus.self, forKey: .status) ?? .planned

        // Handle optional date
        if let scheduledAt = try container.decodeIfPresent(Date.self, forKey: .date) {
            date = scheduledAt
        } else {
            date = Date()
        }

        segments = try container.decodeIfPresent([WorkoutSegment].self, forKey: .segments) ?? []
        sections = try container.decodeIfPresent([WorkoutSection].self, forKey: .sections)
        sectionsMetadata = try container.decodeIfPresent([SectionMetadata].self, forKey: .sectionsMetadata)

        totalDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .totalDuration)
        estimatedDurationMinutes = try container.decodeIfPresent(Int.self, forKey: .estimatedDurationMinutes)
        estimatedCalories = try container.decodeIfPresent(Int.self, forKey: .estimatedCalories)
        readinessScore = try container.decodeIfPresent(Int.self, forKey: .readinessScore)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        routeData = try container.decodeIfPresent(RouteData.self, forKey: .routeData)
        gpsSource = try container.decodeIfPresent(GPSSource.self, forKey: .gpsSource)
    }

    init(
        id: UUID = UUID(),
        userId: UUID,
        name: String? = nil,
        date: Date,
        type: WorkoutType,
        status: WorkoutStatus = .planned,
        segments: [WorkoutSegment] = [],
        sections: [WorkoutSection]? = nil,
        sectionsMetadata: [SectionMetadata]? = nil,
        totalDuration: TimeInterval? = nil,
        estimatedDurationMinutes: Int? = nil,
        estimatedCalories: Int? = nil,
        readinessScore: Int? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        routeData: RouteData? = nil,
        gpsSource: GPSSource? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.date = date
        self.type = type
        self.status = status
        self.segments = segments
        self.sections = sections
        self.sectionsMetadata = sectionsMetadata
        self.totalDuration = totalDuration
        self.estimatedDurationMinutes = estimatedDurationMinutes
        self.estimatedCalories = estimatedCalories
        self.readinessScore = readinessScore
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.routeData = routeData
        self.gpsSource = gpsSource
    }

    // Custom encoder - only encode to workout_type, not legacy type
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(date, forKey: .date)
        try container.encode(type, forKey: .type)
        try container.encode(status, forKey: .status)
        try container.encode(segments, forKey: .segments)
        try container.encodeIfPresent(sections, forKey: .sections)
        try container.encodeIfPresent(sectionsMetadata, forKey: .sectionsMetadata)
        try container.encodeIfPresent(totalDuration, forKey: .totalDuration)
        try container.encodeIfPresent(estimatedDurationMinutes, forKey: .estimatedDurationMinutes)
        try container.encodeIfPresent(estimatedCalories, forKey: .estimatedCalories)
        try container.encodeIfPresent(readinessScore, forKey: .readinessScore)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(routeData, forKey: .routeData)
        try container.encodeIfPresent(gpsSource, forKey: .gpsSource)
        // Note: legacyType is decode-only, not encoded
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

// MARK: - GPS Source

enum GPSSource: String, Codable {
    case watch
    case iphone

    var displayName: String {
        switch self {
        case .watch:
            return "Apple Watch"
        case .iphone:
            return "iPhone"
        }
    }
}

// MARK: - Workout Source

/// Identifies where a workout originated from
enum WorkoutSource: String, Codable {
    case flexr = "flexr"                    // Created in FLEXR app
    case healthKit = "healthkit"            // Imported from HealthKit (other apps)
    case appleFitness = "apple_fitness"     // Apple Fitness+
    case appleWatch = "apple_watch"         // Direct Apple Watch workout
    case strava = "strava"                  // Strava (future)
    case external = "external"              // Generic external source

    var displayName: String {
        switch self {
        case .flexr:
            return "FLEXR"
        case .healthKit:
            return "HealthKit"
        case .appleFitness:
            return "Apple Fitness+"
        case .appleWatch:
            return "Apple Watch"
        case .strava:
            return "Strava"
        case .external:
            return "External"
        }
    }

    var icon: String {
        switch self {
        case .flexr:
            return "bolt.fill"
        case .healthKit:
            return "heart.fill"
        case .appleFitness:
            return "figure.run"
        case .appleWatch:
            return "applewatch"
        case .strava:
            return "figure.outdoor.cycle"
        case .external:
            return "arrow.down.circle"
        }
    }

    var isExternal: Bool {
        return self != .flexr
    }
}
