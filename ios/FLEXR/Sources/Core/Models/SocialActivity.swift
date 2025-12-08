import Foundation

// MARK: - Activity Feed

struct GymActivityFeed: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    var gymId: UUID?
    let activityType: ActivityType
    var entityType: String?
    var entityId: UUID?
    var metadata: [String: AnyCodable]
    let visibility: ActivityVisibility
    let kudosCount: Int
    let commentCount: Int
    let expiresAt: Date
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case gymId = "gym_id"
        case activityType = "activity_type"
        case entityType = "entity_type"
        case entityId = "entity_id"
        case metadata, visibility
        case kudosCount = "kudos_count"
        case commentCount = "comment_count"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
    }
}

// MARK: - Activity Feed Item (with user details)

struct ActivityFeedItem: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    let user: UserBasicInfo
    var gym: GymBasicInfo?
    let activityType: ActivityType
    var entityType: String?
    var entityId: UUID?
    var metadata: [String: AnyCodable]
    let visibility: ActivityVisibility
    let kudosCount: Int
    let commentCount: Int
    let userHasGivenKudos: Bool
    var userKudosType: KudosType?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case user, gym
        case activityType = "activity_type"
        case entityType = "entity_type"
        case entityId = "entity_id"
        case metadata, visibility
        case kudosCount = "kudos_count"
        case commentCount = "comment_count"
        case userHasGivenKudos = "user_has_given_kudos"
        case userKudosType = "user_kudos_type"
        case createdAt = "created_at"
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    var activityDescription: String {
        switch activityType {
        case .workoutCompleted:
            return "completed a workout"
        case .personalRecord:
            return "set a new PR"
        case .milestoneReached:
            return "reached a milestone"
        case .gymJoined:
            return "joined the gym"
        case .achievementUnlocked:
            return "unlocked an achievement"
        case .friendAdded:
            return "made a new connection"
        case .racePartnerLinked:
            return "linked with a race partner"
        }
    }
}

// MARK: - Activity Type

enum ActivityType: String, Codable, CaseIterable {
    case workoutCompleted = "workout_completed"
    case personalRecord = "personal_record"
    case milestoneReached = "milestone_reached"
    case gymJoined = "gym_joined"
    case achievementUnlocked = "achievement_unlocked"
    case friendAdded = "friend_added"
    case racePartnerLinked = "race_partner_linked"

    var displayName: String {
        switch self {
        case .workoutCompleted:
            return "Workout Completed"
        case .personalRecord:
            return "Personal Record"
        case .milestoneReached:
            return "Milestone"
        case .gymJoined:
            return "New Member"
        case .achievementUnlocked:
            return "Achievement"
        case .friendAdded:
            return "New Friend"
        case .racePartnerLinked:
            return "Race Partner"
        }
    }

    var iconName: String {
        switch self {
        case .workoutCompleted:
            return "checkmark.circle.fill"
        case .personalRecord:
            return "trophy.fill"
        case .milestoneReached:
            return "flag.checkered"
        case .gymJoined:
            return "person.crop.circle.badge.plus"
        case .achievementUnlocked:
            return "star.fill"
        case .friendAdded:
            return "person.2.fill"
        case .racePartnerLinked:
            return "figure.2"
        }
    }
}

// MARK: - Activity Visibility
// Note: ActivityVisibility is defined in RunningSession.swift and shared across the app

// MARK: - Gym Basic Info

struct GymBasicInfo: Codable, Equatable {
    let id: UUID
    let name: String

    var displayName: String {
        name
    }
}

// MARK: - Kudos

struct ActivityKudos: Identifiable, Codable, Equatable {
    let id: UUID
    let activityId: UUID
    let userId: UUID
    let kudosType: KudosType
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case activityId = "activity_id"
        case userId = "user_id"
        case kudosType = "kudos_type"
        case createdAt = "created_at"
    }
}

// MARK: - Kudos Type

enum KudosType: String, Codable, CaseIterable {
    case kudos
    case fire
    case lightning
    case strong
    case bullseye
    case heart

    var displayName: String {
        switch self {
        case .kudos:
            return "Kudos"
        case .fire:
            return "Fire"
        case .lightning:
            return "Lightning"
        case .strong:
            return "Strong"
        case .bullseye:
            return "Bullseye"
        case .heart:
            return "Heart"
        }
    }

    var emoji: String {
        switch self {
        case .kudos:
            return "👍"
        case .fire:
            return "🔥"
        case .lightning:
            return "⚡"
        case .strong:
            return "💪"
        case .bullseye:
            return "🎯"
        case .heart:
            return "❤️"
        }
    }

    var iconName: String {
        switch self {
        case .kudos:
            return "hand.thumbsup.fill"
        case .fire:
            return "flame.fill"
        case .lightning:
            return "bolt.fill"
        case .strong:
            return "figure.strengthtraining.traditional"
        case .bullseye:
            return "target"
        case .heart:
            return "heart.fill"
        }
    }
}

// MARK: - Comment

struct ActivityComment: Identifiable, Codable, Equatable {
    let id: UUID
    let activityId: UUID
    let userId: UUID
    let user: UserBasicInfo
    var commentText: String
    var parentCommentId: UUID?
    let isDeleted: Bool
    var deletedAt: Date?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case activityId = "activity_id"
        case userId = "user_id"
        case user
        case commentText = "comment_text"
        case parentCommentId = "parent_comment_id"
        case isDeleted = "is_deleted"
        case deletedAt = "deleted_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    var isEdited: Bool {
        return updatedAt > createdAt
    }
}

// MARK: - Workout Comparison

struct WorkoutComparison: Identifiable, Codable, Equatable {
    let id: UUID
    let workoutAId: UUID
    let workoutBId: UUID
    let userAId: UUID
    let userBId: UUID
    let similarityScore: Double
    let comparisonData: ComparisonData
    let expiresAt: Date
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case workoutAId = "workout_a_id"
        case workoutBId = "workout_b_id"
        case userAId = "user_a_id"
        case userBId = "user_b_id"
        case similarityScore = "similarity_score"
        case comparisonData = "comparison_data"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var similarityPercentage: Int {
        return Int(similarityScore * 100)
    }

    var similarityLevel: SimilarityLevel {
        if similarityScore >= 0.8 {
            return .veryHigh
        } else if similarityScore >= 0.6 {
            return .high
        } else if similarityScore >= 0.4 {
            return .medium
        } else if similarityScore >= 0.2 {
            return .low
        } else {
            return .veryLow
        }
    }

    enum SimilarityLevel {
        case veryHigh, high, medium, low, veryLow

        var displayName: String {
            switch self {
            case .veryHigh: return "Very Similar"
            case .high: return "Similar"
            case .medium: return "Somewhat Similar"
            case .low: return "Different"
            case .veryLow: return "Very Different"
            }
        }
    }
}

// MARK: - Comparison Data

struct ComparisonData: Codable, Equatable {
    let segmentComparisons: [SegmentComparison]
    let totalTimeDifference: Int? // seconds
    let totalDistanceDifference: Double? // km
    let winner: Winner?
    let insights: [String]
    let strengthsA: [String]
    let strengthsB: [String]

    enum CodingKeys: String, CodingKey {
        case segmentComparisons = "segment_comparisons"
        case totalTimeDifference = "total_time_difference"
        case totalDistanceDifference = "total_distance_difference"
        case winner, insights
        case strengthsA = "strengths_a"
        case strengthsB = "strengths_b"
    }

    enum Winner: String, Codable {
        case userA = "user_a"
        case userB = "user_b"
        case tie
    }
}

// MARK: - Segment Comparison

struct SegmentComparison: Codable, Equatable {
    let segmentType: String
    let segmentName: String
    let userATime: Int?
    let userBTime: Int?
    let userADistance: Double?
    let userBDistance: Double?
    let difference: Double
    let percentageDifference: Double

    enum CodingKeys: String, CodingKey {
        case segmentType = "segment_type"
        case segmentName = "segment_name"
        case userATime = "user_a_time"
        case userBTime = "user_b_time"
        case userADistance = "user_a_distance"
        case userBDistance = "user_b_distance"
        case difference
        case percentageDifference = "percentage_difference"
    }

    var fasterUser: String {
        if difference < 0 {
            return "User A"
        } else if difference > 0 {
            return "User B"
        } else {
            return "Tie"
        }
    }
}

// MARK: - Leaderboard

struct GymLeaderboard: Identifiable, Codable, Equatable {
    let id: UUID
    let gymId: UUID
    let leaderboardType: LeaderboardType
    let period: LeaderboardPeriod
    let periodStart: Date
    let periodEnd: Date
    let rankings: [LeaderboardEntry]
    let totalParticipants: Int
    let lastComputedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case gymId = "gym_id"
        case leaderboardType = "leaderboard_type"
        case period
        case periodStart = "period_start"
        case periodEnd = "period_end"
        case rankings
        case totalParticipants = "total_participants"
        case lastComputedAt = "last_computed_at"
    }
}

// MARK: - Leaderboard Type

enum LeaderboardType: String, Codable, CaseIterable {
    case overallWorkouts = "overall_workouts"
    case overallDistance = "overall_distance"
    case overallTime = "overall_time"
    case consistency
    case station1kmRun = "station_1km_run"
    case stationSledPush = "station_sled_push"
    case stationSledPull = "station_sled_pull"
    case stationRowing = "station_rowing"
    case stationSkiErg = "station_ski_erg"
    case stationWallBalls = "station_wall_balls"
    case stationBurpeeBroadJump = "station_burpee_broad_jump"

    var displayName: String {
        switch self {
        case .overallWorkouts:
            return "Most Workouts"
        case .overallDistance:
            return "Total Distance"
        case .overallTime:
            return "Training Time"
        case .consistency:
            return "Consistency"
        case .station1kmRun:
            return "Fastest 1km Run"
        case .stationSledPush:
            return "Fastest Sled Push"
        case .stationSledPull:
            return "Fastest Sled Pull"
        case .stationRowing:
            return "Fastest 1000m Row"
        case .stationSkiErg:
            return "Fastest 1000m Ski Erg"
        case .stationWallBalls:
            return "Fastest 100 Wall Balls"
        case .stationBurpeeBroadJump:
            return "Fastest Burpee Broad Jump"
        }
    }

    var iconName: String {
        switch self {
        case .overallWorkouts:
            return "list.number"
        case .overallDistance:
            return "arrow.right"
        case .overallTime:
            return "clock.fill"
        case .consistency:
            return "calendar.badge.checkmark"
        case .station1kmRun:
            return "figure.run"
        case .stationSledPush, .stationSledPull:
            return "figure.strengthtraining.traditional"
        case .stationRowing:
            return "figure.rowing"
        case .stationSkiErg:
            return "figure.skiing.crosscountry"
        case .stationWallBalls:
            return "sportscourt.fill"
        case .stationBurpeeBroadJump:
            return "figure.jumprope"
        }
    }
}

// MARK: - Leaderboard Period

enum LeaderboardPeriod: String, Codable, CaseIterable {
    case weekly
    case monthly
    case allTime = "all_time"

    var displayName: String {
        switch self {
        case .weekly:
            return "This Week"
        case .monthly:
            return "This Month"
        case .allTime:
            return "All Time"
        }
    }
}

// MARK: - Leaderboard Entry

struct LeaderboardEntry: Codable, Equatable {
    let rank: Int
    let userId: UUID
    let value: Double
    var metadata: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case rank
        case userId = "user_id"
        case value, metadata
    }
}

// MARK: - Leaderboard Entry With User

struct LeaderboardEntryWithUser: Identifiable, Codable, Equatable {
    let rank: Int
    let userId: UUID
    let user: UserBasicInfo
    let value: Double
    var metadata: [String: AnyCodable]?
    let isCurrentUser: Bool

    var id: UUID {
        userId
    }

    enum CodingKeys: String, CodingKey {
        case rank
        case userId = "user_id"
        case user, value, metadata
        case isCurrentUser = "is_current_user"
    }

    var medalEmoji: String? {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return nil
        }
    }
}

// MARK: - Personal Record

struct UserPersonalRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    let recordType: RecordType
    let value: Double
    let unit: RecordUnit
    var workoutId: UUID?
    var segmentId: UUID?
    var previousValue: Double?
    var improvement: Double?
    let isVerified: Bool
    var verifiedByDevice: VerifiedByDevice?
    var metadata: [String: AnyCodable]?
    let achievedAt: Date
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case recordType = "record_type"
        case value, unit
        case workoutId = "workout_id"
        case segmentId = "segment_id"
        case previousValue = "previous_value"
        case improvement
        case isVerified = "is_verified"
        case verifiedByDevice = "verified_by_device"
        case metadata
        case achievedAt = "achieved_at"
        case createdAt = "created_at"
    }

    var improvementPercentage: Double? {
        guard let previous = previousValue, previous > 0 else { return nil }
        return ((previous - value) / previous) * 100
    }

    var valueFormatted: String {
        switch unit {
        case .seconds:
            return formatTime(seconds: Int(value))
        case .meters:
            return String(format: "%.0f m", value)
        case .count:
            return String(format: "%.0f", value)
        case .days:
            return String(format: "%.0f days", value)
        }
    }

    private func formatTime(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}

// MARK: - Record Type

enum RecordType: String, Codable, CaseIterable {
    case fastest1kmRun = "fastest_1km_run"
    case fastestSledPush50m = "fastest_sled_push_50m"
    case fastestSledPull50m = "fastest_sled_pull_50m"
    case fastest1000mRow = "fastest_1000m_row"
    case fastest1000mSkiErg = "fastest_1000m_ski_erg"
    case fastest100WallBalls = "fastest_100_wall_balls"
    case fastest80mBurpeeBroadJump = "fastest_80m_burpee_broad_jump"
    case fastestFullHyrox = "fastest_full_hyrox"
    case longestDistanceSingleWorkout = "longest_distance_single_workout"

    var displayName: String {
        switch self {
        case .fastest1kmRun:
            return "Fastest 1km Run"
        case .fastestSledPush50m:
            return "Fastest 50m Sled Push"
        case .fastestSledPull50m:
            return "Fastest 50m Sled Pull"
        case .fastest1000mRow:
            return "Fastest 1000m Row"
        case .fastest1000mSkiErg:
            return "Fastest 1000m Ski Erg"
        case .fastest100WallBalls:
            return "Fastest 100 Wall Balls"
        case .fastest80mBurpeeBroadJump:
            return "Fastest Burpee Broad Jump"
        case .fastestFullHyrox:
            return "Fastest Full HYROX"
        case .longestDistanceSingleWorkout:
            return "Longest Distance"
        }
    }

    var iconName: String {
        switch self {
        case .fastest1kmRun:
            return "figure.run"
        case .fastestSledPush50m, .fastestSledPull50m:
            return "figure.strengthtraining.traditional"
        case .fastest1000mRow:
            return "figure.rowing"
        case .fastest1000mSkiErg:
            return "figure.skiing.crosscountry"
        case .fastest100WallBalls:
            return "sportscourt.fill"
        case .fastest80mBurpeeBroadJump:
            return "figure.jumprope"
        case .fastestFullHyrox:
            return "trophy.fill"
        case .longestDistanceSingleWorkout:
            return "arrow.right.circle.fill"
        }
    }
}

// MARK: - Record Unit

enum RecordUnit: String, Codable {
    case seconds
    case meters
    case count
    case days

    var symbol: String {
        switch self {
        case .seconds:
            return "s"
        case .meters:
            return "m"
        case .count:
            return ""
        case .days:
            return "d"
        }
    }
}

// MARK: - Verified By Device

enum VerifiedByDevice: String, Codable {
    case appleWatch = "apple_watch"
    case manual
    case video

    var displayName: String {
        switch self {
        case .appleWatch:
            return "Apple Watch"
        case .manual:
            return "Manual"
        case .video:
            return "Video"
        }
    }

    var iconName: String {
        switch self {
        case .appleWatch:
            return "applewatch"
        case .manual:
            return "hand.raised.fill"
        case .video:
            return "video.fill"
        }
    }
}

// MARK: - AnyCodable Helper

struct AnyCodable: Codable, Equatable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }

    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        // Simple equality check - can be enhanced
        return "\(lhs.value)" == "\(rhs.value)"
    }
}
