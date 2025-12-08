// FLEXR - Workout Feedback Model
// User feedback after completing workouts - used for AI personalization

import Foundation

// MARK: - Workout Feedback

struct WorkoutFeedback: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let workoutId: UUID

    // Subjective feedback
    var rpeScore: Int?           // 1-10 Rate of Perceived Exertion
    var moodScore: Int?          // 1-5 maps to emoji
    var tags: [FeedbackTag]
    var freeText: String?

    // Objective metrics (from HealthKit/Watch)
    var actualDurationSeconds: Int?
    var avgHeartRate: Int?
    var maxHeartRate: Int?
    var caloriesBurned: Int?
    var completionPercentage: Double?

    // Metadata
    let createdAt: Date
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case workoutId = "workout_id"
        case rpeScore = "rpe_score"
        case moodScore = "mood_score"
        case tags
        case freeText = "free_text"
        case actualDurationSeconds = "actual_duration_seconds"
        case avgHeartRate = "avg_heart_rate"
        case maxHeartRate = "max_heart_rate"
        case caloriesBurned = "calories_burned"
        case completionPercentage = "completion_percentage"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID = UUID(),
        userId: UUID,
        workoutId: UUID,
        rpeScore: Int? = nil,
        moodScore: Int? = nil,
        tags: [FeedbackTag] = [],
        freeText: String? = nil,
        actualDurationSeconds: Int? = nil,
        avgHeartRate: Int? = nil,
        maxHeartRate: Int? = nil,
        caloriesBurned: Int? = nil,
        completionPercentage: Double? = nil,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.workoutId = workoutId
        self.rpeScore = rpeScore
        self.moodScore = moodScore
        self.tags = tags
        self.freeText = freeText
        self.actualDurationSeconds = actualDurationSeconds
        self.avgHeartRate = avgHeartRate
        self.maxHeartRate = maxHeartRate
        self.caloriesBurned = caloriesBurned
        self.completionPercentage = completionPercentage
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Custom decoder to handle tags as strings from database
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        workoutId = try container.decode(UUID.self, forKey: .workoutId)
        rpeScore = try container.decodeIfPresent(Int.self, forKey: .rpeScore)
        moodScore = try container.decodeIfPresent(Int.self, forKey: .moodScore)
        freeText = try container.decodeIfPresent(String.self, forKey: .freeText)
        actualDurationSeconds = try container.decodeIfPresent(Int.self, forKey: .actualDurationSeconds)
        avgHeartRate = try container.decodeIfPresent(Int.self, forKey: .avgHeartRate)
        maxHeartRate = try container.decodeIfPresent(Int.self, forKey: .maxHeartRate)
        caloriesBurned = try container.decodeIfPresent(Int.self, forKey: .caloriesBurned)
        completionPercentage = try container.decodeIfPresent(Double.self, forKey: .completionPercentage)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)

        // Decode tags as string array and convert to enum
        let tagStrings = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        tags = tagStrings.compactMap { FeedbackTag(rawValue: $0) }
    }

    // Custom encoder to convert tags to strings for database
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(workoutId, forKey: .workoutId)
        try container.encodeIfPresent(rpeScore, forKey: .rpeScore)
        try container.encodeIfPresent(moodScore, forKey: .moodScore)
        try container.encode(tags.map { $0.rawValue }, forKey: .tags)
        try container.encodeIfPresent(freeText, forKey: .freeText)
        try container.encodeIfPresent(actualDurationSeconds, forKey: .actualDurationSeconds)
        try container.encodeIfPresent(avgHeartRate, forKey: .avgHeartRate)
        try container.encodeIfPresent(maxHeartRate, forKey: .maxHeartRate)
        try container.encodeIfPresent(caloriesBurned, forKey: .caloriesBurned)
        try container.encodeIfPresent(completionPercentage, forKey: .completionPercentage)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
}

// MARK: - Feedback Tags

enum FeedbackTag: String, Codable, CaseIterable {
    // Difficulty
    case tooEasy = "too_easy"
    case justRight = "just_right"
    case tooHard = "too_hard"

    // Energy
    case highEnergy = "high_energy"
    case normalEnergy = "normal_energy"
    case lowEnergy = "low_energy"
    case exhausted = "exhausted"

    // Body
    case feltStrong = "felt_strong"
    case tightMuscles = "tight_muscles"
    case minorPain = "minor_pain"
    case injuryConcern = "injury_concern"

    // Enjoyment
    case lovedIt = "loved_it"
    case boring = "boring"
    case hatedIt = "hated_it"

    // External factors
    case timePressed = "time_pressed"
    case badSleep = "bad_sleep"
    case stressed = "stressed"
    case greatDay = "great_day"

    var displayName: String {
        switch self {
        case .tooEasy: return "Too Easy"
        case .justRight: return "Just Right"
        case .tooHard: return "Too Hard"
        case .highEnergy: return "High Energy"
        case .normalEnergy: return "Normal"
        case .lowEnergy: return "Low Energy"
        case .exhausted: return "Exhausted"
        case .feltStrong: return "Felt Strong"
        case .tightMuscles: return "Tight Muscles"
        case .minorPain: return "Minor Pain"
        case .injuryConcern: return "Injury Concern"
        case .lovedIt: return "Loved It"
        case .boring: return "Boring"
        case .hatedIt: return "Didn't Enjoy"
        case .timePressed: return "Time Pressed"
        case .badSleep: return "Bad Sleep"
        case .stressed: return "Stressed"
        case .greatDay: return "Great Day"
        }
    }

    var icon: String {
        switch self {
        case .tooEasy: return "arrow.down.circle"
        case .justRight: return "checkmark.circle"
        case .tooHard: return "arrow.up.circle"
        case .highEnergy: return "bolt.fill"
        case .normalEnergy: return "bolt"
        case .lowEnergy: return "battery.25"
        case .exhausted: return "battery.0"
        case .feltStrong: return "figure.strengthtraining.traditional"
        case .tightMuscles: return "bandage"
        case .minorPain: return "exclamationmark.triangle"
        case .injuryConcern: return "cross.circle"
        case .lovedIt: return "heart.fill"
        case .boring: return "moon.zzz"
        case .hatedIt: return "hand.thumbsdown"
        case .timePressed: return "clock.badge.exclamationmark"
        case .badSleep: return "bed.double"
        case .stressed: return "brain.head.profile"
        case .greatDay: return "sun.max.fill"
        }
    }

    var category: FeedbackCategory {
        switch self {
        case .tooEasy, .justRight, .tooHard:
            return .difficulty
        case .highEnergy, .normalEnergy, .lowEnergy, .exhausted:
            return .energy
        case .feltStrong, .tightMuscles, .minorPain, .injuryConcern:
            return .body
        case .lovedIt, .boring, .hatedIt:
            return .enjoyment
        case .timePressed, .badSleep, .stressed, .greatDay:
            return .external
        }
    }

    static var difficultyTags: [FeedbackTag] {
        [.tooEasy, .justRight, .tooHard]
    }

    static var quickTags: [FeedbackTag] {
        [.tooEasy, .justRight, .tooHard, .lowEnergy, .tightMuscles, .lovedIt]
    }
}

enum FeedbackCategory: String, CaseIterable {
    case difficulty
    case energy
    case body
    case enjoyment
    case external

    var displayName: String {
        switch self {
        case .difficulty: return "Difficulty"
        case .energy: return "Energy Level"
        case .body: return "How You Feel"
        case .enjoyment: return "Enjoyment"
        case .external: return "External Factors"
        }
    }
}

// MARK: - Mood Score

enum MoodScore: Int, CaseIterable {
    case terrible = 1
    case notGreat = 2
    case okay = 3
    case good = 4
    case amazing = 5

    var emoji: String {
        switch self {
        case .terrible: return "😫"
        case .notGreat: return "😕"
        case .okay: return "😐"
        case .good: return "🙂"
        case .amazing: return "💪"
        }
    }

    var description: String {
        switch self {
        case .terrible: return "Terrible"
        case .notGreat: return "Not Great"
        case .okay: return "Okay"
        case .good: return "Good"
        case .amazing: return "Amazing"
        }
    }
}

// MARK: - Coach Note (for display)

struct CoachNote: Codable {
    let headline: String
    let explanation: String
    let dataPoints: [CoachDataPoint]?

    enum CodingKeys: String, CodingKey {
        case headline = "coach_headline"
        case explanation = "coach_explanation"
        case dataPoints = "coach_data_points"
    }
}

struct CoachDataPoint: Codable {
    let type: String      // "feedback", "metric", "trend"
    let label: String     // "Last week's RPE"
    let value: String     // "7.2 avg"
}
