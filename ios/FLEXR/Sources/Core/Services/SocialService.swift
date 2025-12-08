// FLEXR - Social Service
// Handles activity feed, kudos, comments, comparisons, leaderboards, and PRs

import Foundation

// MARK: - Social Service Extension
extension SupabaseService {

    // MARK: - Activity Feed

    /// Get activity feed for user's gym
    func getActivityFeed(
        gymId: UUID,
        activityTypes: [ActivityType]? = nil,
        limit: Int = 50,
        offset: Int = 0
    ) async throws -> [ActivityFeedItem] {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let activities: [ActivityFeedItem]

        if let types = activityTypes {
            let typeValues = types.map { $0.rawValue }
            activities = try await client
                .database.from("gym_activity_feed")
                .select()
                .eq("gym_id", value: gymId.uuidString)
                .in("activity_type", values: typeValues)
                .order("created_at", ascending: false)
                .range(from: offset, to: offset + limit - 1)
                .execute()
                .value
        } else {
            activities = try await client
                .database.from("gym_activity_feed")
                .select()
                .eq("gym_id", value: gymId.uuidString)
                .order("created_at", ascending: false)
                .range(from: offset, to: offset + limit - 1)
                .execute()
                .value
        }

        return activities
    }

    /// Get user's personal activity feed
    func getUserActivityFeed(
        userId: UUID? = nil,
        limit: Int = 50,
        offset: Int = 0
    ) async throws -> [ActivityFeedItem] {
        guard let currentUserId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let targetUserId = userId ?? currentUserId

        let activities: [ActivityFeedItem] = try await client
            .database.from("gym_activity_feed")
            .select()
            .eq("user_id", value: targetUserId.uuidString)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value

        return activities
    }

    /// Create activity feed item
    func createActivity(
        gymId: UUID,
        activityType: ActivityType,
        title: String,
        description: String?,
        metadata: [String: AnyCodable],
        visibility: ActivityVisibility = .public
    ) async throws -> ActivityFeedItem {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        struct ActivityInsert: Encodable {
            let gym_id: String
            let user_id: String
            let activity_type: String
            let title: String
            let description: String?
            let metadata: [String: AnyCodable]
            let visibility: String
        }

        let insert = ActivityInsert(
            gym_id: gymId.uuidString,
            user_id: userId.uuidString,
            activity_type: activityType.rawValue,
            title: title,
            description: description,
            metadata: metadata,
            visibility: visibility.rawValue
        )

        let activity: ActivityFeedItem = try await client
            .database.from("gym_activity_feed")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value

        return activity
    }

    // MARK: - Kudos

    /// Give kudos to an activity
    func giveKudos(
        activityId: UUID,
        kudosType: KudosType
    ) async throws -> ActivityKudos {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        struct KudosInsert: Encodable {
            let activity_id: String
            let user_id: String
            let kudos_type: String
        }

        let insert = KudosInsert(
            activity_id: activityId.uuidString,
            user_id: userId.uuidString,
            kudos_type: kudosType.rawValue
        )

        let kudos: ActivityKudos = try await client
            .database.from("activity_kudos")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value

        return kudos
    }

    /// Remove kudos from an activity
    func removeKudos(activityId: UUID) async throws {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        try await client
            .database.from("activity_kudos")
            .delete()
            .eq("activity_id", value: activityId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    /// Get kudos for an activity
    func getActivityKudos(activityId: UUID) async throws -> [ActivityKudos] {
        let kudos: [ActivityKudos] = try await client
            .database.from("activity_kudos")
            .select()
            .eq("activity_id", value: activityId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return kudos
    }

    // MARK: - Comments

    /// Add comment to activity
    func addComment(
        activityId: UUID,
        content: String,
        parentCommentId: UUID? = nil
    ) async throws -> ActivityComment {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        struct CommentInsert: Encodable {
            let activity_id: String
            let user_id: String
            let content: String
            let parent_comment_id: String?
        }

        let insert = CommentInsert(
            activity_id: activityId.uuidString,
            user_id: userId.uuidString,
            content: content,
            parent_comment_id: parentCommentId?.uuidString
        )

        let comment: ActivityComment = try await client
            .database.from("activity_comments")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value

        return comment
    }

    /// Get comments for activity
    func getActivityComments(activityId: UUID) async throws -> [ActivityComment] {
        let comments: [ActivityComment] = try await client
            .database.from("activity_comments")
            .select()
            .eq("activity_id", value: activityId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value

        return comments
    }

    /// Delete comment
    func deleteComment(commentId: UUID) async throws {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        try await client
            .database.from("activity_comments")
            .delete()
            .eq("id", value: commentId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    // MARK: - Workout Comparisons

    /// Get workout comparisons for a workout
    func getWorkoutComparisons(
        workoutId: UUID,
        minSimilarity: Double = 0.7,
        limit: Int = 10
    ) async throws -> [WorkoutComparison] {
        let comparisons: [WorkoutComparison] = try await client
            .database.from("workout_comparisons")
            .select()
            .eq("workout_a_id", value: workoutId.uuidString)
            .gte("similarity_score", value: minSimilarity)
            .order("similarity_score", ascending: false)
            .limit(limit)
            .execute()
            .value

        return comparisons
    }

    /// Compare workouts between users
    func compareUserWorkouts(
        userAId: UUID,
        userBId: UUID,
        workoutType: WorkoutType? = nil,
        limit: Int = 10
    ) async throws -> [WorkoutComparison] {
        let comparisons: [WorkoutComparison]

        if let type = workoutType {
            comparisons = try await client
                .database.from("workout_comparisons")
                .select()
                .eq("user_a_id", value: userAId.uuidString)
                .eq("user_b_id", value: userBId.uuidString)
                .eq("workout_type", value: type.rawValue)
                .order("similarity_score", ascending: false)
                .limit(limit)
                .execute()
                .value
        } else {
            comparisons = try await client
                .database.from("workout_comparisons")
                .select()
                .eq("user_a_id", value: userAId.uuidString)
                .eq("user_b_id", value: userBId.uuidString)
                .order("similarity_score", ascending: false)
                .limit(limit)
                .execute()
                .value
        }

        return comparisons
    }

    // MARK: - Leaderboards

    /// Get gym leaderboard
    func getGymLeaderboard(
        gymId: UUID,
        leaderboardType: LeaderboardType,
        period: LeaderboardPeriod,
        limit: Int = 50
    ) async throws -> GymLeaderboard? {
        let leaderboard: GymLeaderboard? = try? await client
            .database.from("gym_leaderboards")
            .select()
            .eq("gym_id", value: gymId.uuidString)
            .eq("leaderboard_type", value: leaderboardType.rawValue)
            .eq("period", value: period.rawValue)
            .single()
            .execute()
            .value

        return leaderboard
    }

    /// Get all leaderboards for a gym
    func getAllGymLeaderboards(
        gymId: UUID,
        period: LeaderboardPeriod
    ) async throws -> [GymLeaderboard] {
        let leaderboards: [GymLeaderboard] = try await client
            .database.from("gym_leaderboards")
            .select()
            .eq("gym_id", value: gymId.uuidString)
            .eq("period", value: period.rawValue)
            .order("leaderboard_type", ascending: true)
            .execute()
            .value

        return leaderboards
    }

    /// Get user's leaderboard position
    func getUserLeaderboardPosition(
        gymId: UUID,
        leaderboardType: LeaderboardType,
        period: LeaderboardPeriod
    ) async throws -> Int? {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let leaderboard = try await getGymLeaderboard(
            gymId: gymId,
            leaderboardType: leaderboardType,
            period: period
        )

        guard let rankings = leaderboard?.rankings else { return nil }

        return rankings.firstIndex(where: { entry in
            entry.userId == userId
        }).map { $0 + 1 }
    }

    // MARK: - Personal Records

    /// Get user's personal records
    func getUserPersonalRecords(
        userId: UUID? = nil,
        recordType: RecordType? = nil
    ) async throws -> [UserPersonalRecord] {
        guard let currentUserId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let targetUserId = userId ?? currentUserId

        let records: [UserPersonalRecord]

        if let type = recordType {
            records = try await client
                .database.from("user_personal_records")
                .select()
                .eq("user_id", value: targetUserId.uuidString)
                .eq("record_type", value: type.rawValue)
                .order("achieved_at", ascending: false)
                .execute()
                .value
        } else {
            records = try await client
                .database.from("user_personal_records")
                .select()
                .eq("user_id", value: targetUserId.uuidString)
                .order("achieved_at", ascending: false)
                .execute()
                .value
        }

        return records
    }

    /// Set personal record
    func setPersonalRecord(
        recordType: RecordType,
        value: Double,
        workoutId: UUID,
        metadata: [String: AnyCodable]?
    ) async throws -> UserPersonalRecord {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        struct PRInsert: Encodable {
            let user_id: String
            let record_type: String
            let value: Double
            let workout_id: String
            let metadata: [String: AnyCodable]?
        }

        let insert = PRInsert(
            user_id: userId.uuidString,
            record_type: recordType.rawValue,
            value: value,
            workout_id: workoutId.uuidString,
            metadata: metadata
        )

        let record: UserPersonalRecord = try await client
            .database.from("user_personal_records")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value

        return record
    }

    /// Get personal record for specific type
    func getPersonalRecord(recordType: RecordType) async throws -> UserPersonalRecord? {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let record: UserPersonalRecord? = try? await client
            .database.from("user_personal_records")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("record_type", value: recordType.rawValue)
            .order("achieved_at", ascending: false)
            .limit(1)
            .single()
            .execute()
            .value

        return record
    }

    /// Compare PRs with another user
    func comparePRsWithUser(
        otherUserId: UUID,
        recordType: RecordType? = nil
    ) async throws -> [(type: RecordType, mine: UserPersonalRecord?, theirs: UserPersonalRecord?)] {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let myRecords = try await getUserPersonalRecords(userId: userId, recordType: recordType)
        let theirRecords = try await getUserPersonalRecords(userId: otherUserId, recordType: recordType)

        let types = recordType != nil ? [recordType!] : RecordType.allCases
        var comparisons: [(type: RecordType, mine: UserPersonalRecord?, theirs: UserPersonalRecord?)] = []

        for type in types {
            let mine = myRecords.first(where: { $0.recordType == type })
            let theirs = theirRecords.first(where: { $0.recordType == type })
            comparisons.append((type: type, mine: mine, theirs: theirs))
        }

        return comparisons
    }

    // MARK: - Statistics

    /// Get gym activity statistics
    func getGymActivityStats(gymId: UUID, days: Int = 7) async throws -> GymActivityStats {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!

        struct StatsQuery: Encodable {
            let p_gym_id: String
            let p_start_date: String
        }

        let query = StatsQuery(
            p_gym_id: gymId.uuidString,
            p_start_date: startDate.ISO8601Format()
        )

        let stats: GymActivityStats = try await client
            .database.rpc("get_gym_activity_stats", params: query)
            .execute()
            .value

        return stats
    }

    /// Get user activity statistics
    func getUserActivityStats(
        userId: UUID? = nil,
        days: Int = 30
    ) async throws -> UserActivityStats {
        guard let currentUserId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let targetUserId = userId ?? currentUserId
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!

        struct StatsQuery: Encodable {
            let p_user_id: String
            let p_start_date: String
        }

        let query = StatsQuery(
            p_user_id: targetUserId.uuidString,
            p_start_date: startDate.ISO8601Format()
        )

        let stats: UserActivityStats = try await client
            .database.rpc("get_user_activity_stats", params: query)
            .execute()
            .value

        return stats
    }
}

// MARK: - Supporting Types

struct GymActivityStats: Codable {
    let totalActivities: Int
    let totalWorkouts: Int
    let totalKudos: Int
    let totalComments: Int
    let activeMembers: Int
    let topContributors: [UUID]

    enum CodingKeys: String, CodingKey {
        case totalActivities = "total_activities"
        case totalWorkouts = "total_workouts"
        case totalKudos = "total_kudos"
        case totalComments = "total_comments"
        case activeMembers = "active_members"
        case topContributors = "top_contributors"
    }
}

struct UserActivityStats: Codable {
    let totalWorkouts: Int
    let totalActivities: Int
    let totalKudosReceived: Int
    let totalKudosGiven: Int
    let totalComments: Int
    let streak: Int
    let personalRecords: Int

    enum CodingKeys: String, CodingKey {
        case totalWorkouts = "total_workouts"
        case totalActivities = "total_activities"
        case totalKudosReceived = "total_kudos_received"
        case totalKudosGiven = "total_kudos_given"
        case totalComments = "total_comments"
        case streak
        case personalRecords = "personal_records"
    }
}
