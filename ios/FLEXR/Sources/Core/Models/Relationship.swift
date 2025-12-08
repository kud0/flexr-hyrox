import Foundation

// MARK: - User Relationship

struct UserRelationship: Identifiable, Codable, Equatable {
    let id: UUID
    let userAId: UUID
    let userBId: UUID
    let relationshipType: RelationshipType
    var status: RelationshipStatus
    let initiatedByUserId: UUID
    var originGymId: UUID?
    var racePartnerMetadata: RacePartnerMetadata?
    var lastInteractionAt: Date?
    let interactionCount: Int
    let createdAt: Date
    var acceptedAt: Date?
    var endedAt: Date?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userAId = "user_a_id"
        case userBId = "user_b_id"
        case relationshipType = "relationship_type"
        case status
        case initiatedByUserId = "initiated_by_user_id"
        case originGymId = "origin_gym_id"
        case racePartnerMetadata = "race_partner_metadata"
        case lastInteractionAt = "last_interaction_at"
        case interactionCount = "interaction_count"
        case createdAt = "created_at"
        case acceptedAt = "accepted_at"
        case endedAt = "ended_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Computed Properties

    func otherUserId(currentUserId: UUID) -> UUID {
        return userAId == currentUserId ? userBId : userAId
    }

    func initiatedByMe(currentUserId: UUID) -> Bool {
        return initiatedByUserId == currentUserId
    }

    var isAccepted: Bool {
        return status == .accepted
    }

    var isPending: Bool {
        return status == .pending
    }

    var isEnded: Bool {
        return status == .ended
    }
}

// MARK: - Relationship Type

enum RelationshipType: String, Codable, CaseIterable {
    case gymMember = "gym_member"
    case friend
    case racePartner = "race_partner"

    var displayName: String {
        switch self {
        case .gymMember:
            return "Gym Member"
        case .friend:
            return "Friend"
        case .racePartner:
            return "Race Partner"
        }
    }

    var icon: String {
        switch self {
        case .gymMember:
            return "figure.walk"
        case .friend:
            return "person.2.fill"
        case .racePartner:
            return "figure.2"
        }
    }

    var description: String {
        switch self {
        case .gymMember:
            return "Connected through your gym"
        case .friend:
            return "Training friend"
        case .racePartner:
            return "Doubles/relay race partner"
        }
    }
}

// MARK: - Relationship Status

enum RelationshipStatus: String, Codable, CaseIterable {
    case pending
    case accepted
    case blocked
    case ended

    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .accepted:
            return "Connected"
        case .blocked:
            return "Blocked"
        case .ended:
            return "Ended"
        }
    }

    var icon: String {
        switch self {
        case .pending:
            return "clock"
        case .accepted:
            return "checkmark.circle.fill"
        case .blocked:
            return "hand.raised.fill"
        case .ended:
            return "xmark.circle"
        }
    }
}

// MARK: - Race Partner Metadata

struct RacePartnerMetadata: Codable, Equatable {
    var raceDate: Date?
    var raceType: RaceType?
    var raceLocation: String?
    var raceName: String?
    var targetTimeSeconds: Int?

    enum CodingKeys: String, CodingKey {
        case raceDate = "race_date"
        case raceType = "race_type"
        case raceLocation = "race_location"
        case raceName = "race_name"
        case targetTimeSeconds = "target_time_seconds"
    }

    var daysUntilRace: Int? {
        guard let raceDate = raceDate else { return nil }
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: Date(), to: raceDate).day
    }

    var isRaceApproaching: Bool {
        guard let days = daysUntilRace else { return false }
        return days <= 14 && days > 0
    }

    var targetTimeFormatted: String? {
        guard let seconds = targetTimeSeconds else { return nil }
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

// MARK: - Race Type

enum RaceType: String, Codable, CaseIterable {
    case individual
    case doubles
    case relay

    var displayName: String {
        switch self {
        case .individual:
            return "Individual"
        case .doubles:
            return "Doubles"
        case .relay:
            return "Relay (4-person)"
        }
    }

    var icon: String {
        switch self {
        case .individual:
            return "person.fill"
        case .doubles:
            return "person.2.fill"
        case .relay:
            return "person.3.fill"
        }
    }
}

// MARK: - Relationship With User

struct RelationshipWithUser: Identifiable, Codable, Equatable {
    let relationshipId: UUID
    let relationshipType: RelationshipType
    let status: RelationshipStatus
    let initiatedByMe: Bool
    let originGymId: UUID?
    let acceptedAt: Date?
    let createdAt: Date
    let otherUser: UserBasicInfo
    let myPermissions: RelationshipPermissions
    let theirPermissions: RelationshipPermissions

    var id: UUID {
        relationshipId
    }

    enum CodingKeys: String, CodingKey {
        case relationshipId = "relationship_id"
        case relationshipType = "relationship_type"
        case status
        case initiatedByMe = "initiated_by_me"
        case originGymId = "origin_gym_id"
        case acceptedAt = "accepted_at"
        case createdAt = "created_at"
        case otherUser = "other_user"
        case myPermissions = "my_permissions"
        case theirPermissions = "their_permissions"
    }
}

// MARK: - User Basic Info

struct UserBasicInfo: Codable, Equatable {
    let id: UUID
    var firstName: String?
    var lastName: String?
    var fitnessLevel: ExperienceLevel
    var primaryGoal: String?

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case fitnessLevel = "fitness_level"
        case primaryGoal = "primary_goal"
    }

    var displayName: String {
        if let first = firstName, let last = lastName {
            return "\(first) \(last)"
        } else if let first = firstName {
            return first
        } else if let last = lastName {
            return last
        } else {
            return "Unknown"
        }
    }

    var initials: String {
        var letters = ""
        if let first = firstName?.first {
            letters.append(first)
        }
        if let last = lastName?.first {
            letters.append(last)
        }
        return letters.isEmpty ? "?" : letters
    }
}

// MARK: - Relationship Permissions

struct RelationshipPermissions: Codable, Equatable {
    var shareWorkoutHistory: Bool
    var shareWorkoutDetails: Bool
    var sharePerformanceStats: Bool
    var shareStationStrengths: Bool
    var shareTrainingPlan: Bool
    var shareRaceGoals: Bool
    var sharePersonalRecords: Bool
    var shareHeartRate: Bool
    var shareWorkoutVideos: Bool
    var shareLocation: Bool
    var allowWorkoutComparisons: Bool
    var allowKudos: Bool
    var allowComments: Bool
    var showOnLeaderboards: Bool

    enum CodingKeys: String, CodingKey {
        case shareWorkoutHistory = "share_workout_history"
        case shareWorkoutDetails = "share_workout_details"
        case sharePerformanceStats = "share_performance_stats"
        case shareStationStrengths = "share_station_strengths"
        case shareTrainingPlan = "share_training_plan"
        case shareRaceGoals = "share_race_goals"
        case sharePersonalRecords = "share_personal_records"
        case shareHeartRate = "share_heart_rate"
        case shareWorkoutVideos = "share_workout_videos"
        case shareLocation = "share_location"
        case allowWorkoutComparisons = "allow_workout_comparisons"
        case allowKudos = "allow_kudos"
        case allowComments = "allow_comments"
        case showOnLeaderboards = "show_on_leaderboards"
    }

    // MARK: - Default Permissions by Type

    static func defaultPermissions(for type: RelationshipType) -> RelationshipPermissions {
        switch type {
        case .gymMember:
            return .gymMember
        case .friend:
            return .friend
        case .racePartner:
            return .racePartner
        }
    }

    static let gymMember = RelationshipPermissions(
        shareWorkoutHistory: false,
        shareWorkoutDetails: false,
        sharePerformanceStats: false,
        shareStationStrengths: false,
        shareTrainingPlan: false,
        shareRaceGoals: false,
        sharePersonalRecords: false,
        shareHeartRate: false,
        shareWorkoutVideos: false,
        shareLocation: false,
        allowWorkoutComparisons: false,
        allowKudos: true,
        allowComments: false,
        showOnLeaderboards: true
    )

    static let friend = RelationshipPermissions(
        shareWorkoutHistory: true,
        shareWorkoutDetails: true,
        sharePerformanceStats: true,
        shareStationStrengths: true,
        shareTrainingPlan: false,
        shareRaceGoals: false,
        sharePersonalRecords: true,
        shareHeartRate: false,
        shareWorkoutVideos: false,
        shareLocation: false,
        allowWorkoutComparisons: true,
        allowKudos: true,
        allowComments: true,
        showOnLeaderboards: true
    )

    static let racePartner = RelationshipPermissions(
        shareWorkoutHistory: true,
        shareWorkoutDetails: true,
        sharePerformanceStats: true,
        shareStationStrengths: true,
        shareTrainingPlan: true,
        shareRaceGoals: true,
        sharePersonalRecords: true,
        shareHeartRate: true,
        shareWorkoutVideos: false,
        shareLocation: false,
        allowWorkoutComparisons: true,
        allowKudos: true,
        allowComments: true,
        showOnLeaderboards: true
    )

    static let `private` = RelationshipPermissions(
        shareWorkoutHistory: false,
        shareWorkoutDetails: false,
        sharePerformanceStats: false,
        shareStationStrengths: false,
        shareTrainingPlan: false,
        shareRaceGoals: false,
        sharePersonalRecords: false,
        shareHeartRate: false,
        shareWorkoutVideos: false,
        shareLocation: false,
        allowWorkoutComparisons: false,
        allowKudos: false,
        allowComments: false,
        showOnLeaderboards: false
    )
}

// MARK: - Relationship Request

struct RelationshipRequest: Identifiable, Codable, Equatable {
    let id: UUID
    let fromUserId: UUID
    let toUserId: UUID
    let relationshipType: RelationshipType
    var message: String?
    var status: RequestStatus
    let expiresAt: Date
    let createdAt: Date
    var respondedAt: Date?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case fromUserId = "from_user_id"
        case toUserId = "to_user_id"
        case relationshipType = "relationship_type"
        case message, status
        case expiresAt = "expires_at"
        case createdAt = "created_at"
        case respondedAt = "responded_at"
        case updatedAt = "updated_at"
    }

    var isExpired: Bool {
        return Date() > expiresAt
    }

    var isPending: Bool {
        return status == .pending && !isExpired
    }
}

// MARK: - Request Status

enum RequestStatus: String, Codable, CaseIterable {
    case pending
    case accepted
    case declined
    case cancelled

    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .accepted:
            return "Accepted"
        case .declined:
            return "Declined"
        case .cancelled:
            return "Cancelled"
        }
    }

    var icon: String {
        switch self {
        case .pending:
            return "clock"
        case .accepted:
            return "checkmark.circle.fill"
        case .declined:
            return "xmark.circle"
        case .cancelled:
            return "xmark"
        }
    }
}

// MARK: - Relationship Request With User

struct RelationshipRequestWithUser: Identifiable, Codable, Equatable {
    let id: UUID
    let relationshipType: RelationshipType
    let message: String?
    let createdAt: Date
    let expiresAt: Date
    let fromUser: UserBasicInfo?
    let toUser: UserBasicInfo?

    enum CodingKeys: String, CodingKey {
        case id
        case relationshipType = "relationship_type"
        case message
        case createdAt = "created_at"
        case expiresAt = "expires_at"
        case fromUser = "from_user"
        case toUser = "to_user"
    }

    var isExpired: Bool {
        return Date() > expiresAt
    }
}

// MARK: - Invite Code

struct RelationshipInviteCode: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    let code: String
    let relationshipType: RelationshipType
    let maxUses: Int
    var currentUses: Int
    let expiresAt: Date
    var isActive: Bool
    var metadata: [String: String]?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case code
        case relationshipType = "relationship_type"
        case maxUses = "max_uses"
        case currentUses = "current_uses"
        case expiresAt = "expires_at"
        case isActive = "is_active"
        case metadata
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var isExpired: Bool {
        return Date() > expiresAt
    }

    var isValid: Bool {
        return isActive && !isExpired && currentUses < maxUses
    }

    var usesRemaining: Int {
        return max(0, maxUses - currentUses)
    }

    var daysUntilExpiry: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: Date(), to: expiresAt).day ?? 0
    }
}

// MARK: - Friend List Item

struct FriendListItem: Identifiable, Codable, Equatable {
    let userId: UUID
    var firstName: String?
    var lastName: String?
    var fitnessLevel: ExperienceLevel
    var primaryGoal: String?
    let relationshipId: UUID
    let relationshipType: RelationshipType
    let since: Date
    var lastWorkout: Date?
    let isActive: Bool

    var id: UUID {
        userId
    }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case fitnessLevel = "fitness_level"
        case primaryGoal = "primary_goal"
        case relationshipId = "relationship_id"
        case relationshipType = "relationship_type"
        case since
        case lastWorkout = "last_workout"
        case isActive = "is_active"
    }

    var displayName: String {
        if let first = firstName, let last = lastName {
            return "\(first) \(last)"
        } else if let first = firstName {
            return first
        } else if let last = lastName {
            return last
        } else {
            return "Unknown"
        }
    }

    var activityStatus: String {
        if isActive {
            return "Active this week"
        } else if let lastWorkout = lastWorkout {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return "Last workout \(formatter.localizedString(for: lastWorkout, relativeTo: Date()))"
        } else {
            return "No recent activity"
        }
    }
}

// MARK: - Race Partner Summary

struct RacePartnerSummary: Identifiable, Codable, Equatable {
    let partnerUserId: UUID
    var partnerFirstName: String?
    var partnerLastName: String?
    let relationshipId: UUID
    var racePartnerMetadata: RacePartnerMetadata?

    // Training comparison
    let myWorkoutsThisWeek: Int
    let partnerWorkoutsThisWeek: Int
    let myTotalDistanceKm: Double
    let partnerTotalDistanceKm: Double

    // Scores
    let complementaryScore: Double // 0-1
    let combinedReadiness: Int // 0-100
    let daysUntilRace: Int?

    var id: UUID {
        partnerUserId
    }

    enum CodingKeys: String, CodingKey {
        case partnerUserId = "partner_user_id"
        case partnerFirstName = "partner_first_name"
        case partnerLastName = "partner_last_name"
        case relationshipId = "relationship_id"
        case racePartnerMetadata = "race_partner_metadata"
        case myWorkoutsThisWeek = "my_workouts_this_week"
        case partnerWorkoutsThisWeek = "partner_workouts_this_week"
        case myTotalDistanceKm = "my_total_distance_km"
        case partnerTotalDistanceKm = "partner_total_distance_km"
        case complementaryScore = "complementary_score"
        case combinedReadiness = "combined_readiness"
        case daysUntilRace = "days_until_race"
    }

    var partnerDisplayName: String {
        if let first = partnerFirstName, let last = partnerLastName {
            return "\(first) \(last)"
        } else if let first = partnerFirstName {
            return first
        } else if let last = partnerLastName {
            return last
        } else {
            return "Your Partner"
        }
    }

    var trainingBalance: TrainingBalance {
        let diff = abs(myWorkoutsThisWeek - partnerWorkoutsThisWeek)
        if diff == 0 {
            return .perfect
        } else if diff == 1 {
            return .balanced
        } else if diff <= 2 {
            return .slightGap
        } else {
            return .largeGap
        }
    }

    enum TrainingBalance {
        case perfect
        case balanced
        case slightGap
        case largeGap

        var displayName: String {
            switch self {
            case .perfect:
                return "Perfect sync"
            case .balanced:
                return "Well balanced"
            case .slightGap:
                return "Slight gap"
            case .largeGap:
                return "Training gap"
            }
        }

        var icon: String {
            switch self {
            case .perfect:
                return "checkmark.circle.fill"
            case .balanced:
                return "checkmark.circle"
            case .slightGap:
                return "exclamationmark.circle"
            case .largeGap:
                return "exclamationmark.triangle"
            }
        }
    }
}
