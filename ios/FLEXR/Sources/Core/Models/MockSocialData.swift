// FLEXR - Mock Social Data
// Development mock data for social features

import Foundation

#if DEBUG
extension ActivityFeedItem {
    static let mockItems: [ActivityFeedItem] = [
        ActivityFeedItem(
            id: UUID(),
            userId: UUID(),
            user: UserBasicInfo(
                id: UUID(),
                firstName: "Sarah",
                lastName: "Johnson",
                fitnessLevel: .advanced,
                primaryGoal: "performance"
            ),
            gym: GymBasicInfo(id: UUID(), name: "HYROX Gym Downtown"),
            activityType: .workoutCompleted,
            entityType: "workout",
            entityId: UUID(),
            metadata: [
                "description": AnyCodable("Completed full HYROX simulation - 47:23"),
                "workout_type": AnyCodable("hyrox"),
                "duration": AnyCodable(2843)
            ],
            visibility: .gym,
            kudosCount: 12,
            commentCount: 3,
            userHasGivenKudos: false,
            userKudosType: nil,
            createdAt: Date().addingTimeInterval(-3600)
        ),
        ActivityFeedItem(
            id: UUID(),
            userId: UUID(),
            user: UserBasicInfo(
                id: UUID(),
                firstName: "Mike",
                lastName: "Chen",
                fitnessLevel: .intermediate,
                primaryGoal: "weight_loss"
            ),
            gym: GymBasicInfo(id: UUID(), name: "HYROX Gym Downtown"),
            activityType: .personalRecord,
            entityType: "pr",
            entityId: UUID(),
            metadata: [
                "description": AnyCodable("New PR on 1km SkiErg - 3:45!"),
                "record_type": AnyCodable("fastest_1000m_ski_erg"),
                "value": AnyCodable(225.0)
            ],
            visibility: .gym,
            kudosCount: 24,
            commentCount: 8,
            userHasGivenKudos: true,
            userKudosType: .fire,
            createdAt: Date().addingTimeInterval(-7200)
        ),
        ActivityFeedItem(
            id: UUID(),
            userId: UUID(),
            user: UserBasicInfo(
                id: UUID(),
                firstName: "Emma",
                lastName: "Davis",
                fitnessLevel: .beginner,
                primaryGoal: "general_fitness"
            ),
            gym: GymBasicInfo(id: UUID(), name: "HYROX Gym Downtown"),
            activityType: .milestoneReached,
            entityType: "milestone",
            entityId: UUID(),
            metadata: [
                "description": AnyCodable("10 workouts completed this month!"),
                "milestone_type": AnyCodable("workouts_10")
            ],
            visibility: .gym,
            kudosCount: 18,
            commentCount: 5,
            userHasGivenKudos: false,
            userKudosType: nil,
            createdAt: Date().addingTimeInterval(-14400)
        ),
        ActivityFeedItem(
            id: UUID(),
            userId: UUID(),
            user: UserBasicInfo(
                id: UUID(),
                firstName: "Lisa",
                lastName: "Martinez",
                fitnessLevel: .intermediate,
                primaryGoal: "performance"
            ),
            gym: GymBasicInfo(id: UUID(), name: "HYROX Gym Downtown"),
            activityType: .gymJoined,
            entityType: "gym",
            entityId: UUID(),
            metadata: [
                "description": AnyCodable("New member at HYROX Gym Downtown!"),
                "gym_name": AnyCodable("HYROX Gym Downtown")
            ],
            visibility: .gym,
            kudosCount: 8,
            commentCount: 4,
            userHasGivenKudos: false,
            userKudosType: nil,
            createdAt: Date().addingTimeInterval(-28800)
        )
    ]
}

extension Gym {
    static let mockGyms: [Gym] = [
        Gym(
            id: UUID(),
            name: "HYROX Gym Downtown",
            description: "Official HYROX training facility with full competition setup",
            locationAddress: "123 Main Street",
            locationCity: "New York",
            locationState: "NY",
            locationCountry: "USA",
            locationPostalCode: "10001",
            latitude: 40.7589,
            longitude: -73.9851,
            gymType: .hyroxAffiliate,
            isVerified: true,
            verifiedAt: Date().addingTimeInterval(-86400 * 365),
            websiteUrl: nil,
            phoneNumber: nil,
            email: nil,
            instagramHandle: nil,
            memberCount: 156,
            activeMemberCount: 120,
            isPublic: true,
            allowAutoJoin: true,
            createdByUserId: UUID(),
            createdAt: Date().addingTimeInterval(-86400 * 365),
            updatedAt: Date().addingTimeInterval(-86400 * 7)
        ),
        Gym(
            id: UUID(),
            name: "CrossFit Brooklyn Heights",
            description: "Premier CrossFit box with HYROX training programs",
            locationAddress: "456 Brooklyn Ave",
            locationCity: "Brooklyn",
            locationState: "NY",
            locationCountry: "USA",
            locationPostalCode: "11201",
            latitude: 40.6942,
            longitude: -73.9866,
            gymType: .crossfit,
            isVerified: true,
            verifiedAt: Date().addingTimeInterval(-86400 * 180),
            websiteUrl: nil,
            phoneNumber: nil,
            email: nil,
            instagramHandle: nil,
            memberCount: 89,
            activeMemberCount: 65,
            isPublic: true,
            allowAutoJoin: true,
            createdByUserId: UUID(),
            createdAt: Date().addingTimeInterval(-86400 * 180),
            updatedAt: Date().addingTimeInterval(-86400 * 2)
        ),
        Gym(
            id: UUID(),
            name: "24/7 Fitness Center",
            description: "24-hour access with dedicated functional fitness area",
            locationAddress: "789 Fitness Blvd",
            locationCity: "Manhattan",
            locationState: "NY",
            locationCountry: "USA",
            locationPostalCode: "10019",
            latitude: 40.7614,
            longitude: -73.9776,
            gymType: .commercialGym,
            isVerified: false,
            verifiedAt: nil,
            websiteUrl: nil,
            phoneNumber: nil,
            email: nil,
            instagramHandle: nil,
            memberCount: 342,
            activeMemberCount: 180,
            isPublic: true,
            allowAutoJoin: true,
            createdByUserId: UUID(),
            createdAt: Date().addingTimeInterval(-86400 * 90),
            updatedAt: Date().addingTimeInterval(-86400)
        )
    ]
}

extension GymLeaderboard {
    static func mockLeaderboard(type: LeaderboardType = .overallDistance) -> GymLeaderboard {
        let now = Date()
        return GymLeaderboard(
            id: UUID(),
            gymId: UUID(),
            leaderboardType: type,
            period: .weekly,
            periodStart: now.addingTimeInterval(-86400 * 7),
            periodEnd: now,
            rankings: [
                LeaderboardEntry(
                    rank: 1,
                    userId: UUID(),
                    value: type == .overallDistance ? 45000 : 3600,
                    metadata: ["user_name": AnyCodable("Alex Rivera")]
                ),
                LeaderboardEntry(
                    rank: 2,
                    userId: UUID(),
                    value: type == .overallDistance ? 42000 : 3450,
                    metadata: ["user_name": AnyCodable("Sarah Johnson")]
                ),
                LeaderboardEntry(
                    rank: 3,
                    userId: UUID(),
                    value: type == .overallDistance ? 38500 : 3300,
                    metadata: ["user_name": AnyCodable("Mike Chen")]
                ),
                LeaderboardEntry(
                    rank: 4,
                    userId: UUID(),
                    value: type == .overallDistance ? 35000 : 3100,
                    metadata: ["user_name": AnyCodable("Emma Davis")]
                ),
                LeaderboardEntry(
                    rank: 5,
                    userId: UUID(),
                    value: type == .overallDistance ? 32000 : 2950,
                    metadata: ["user_name": AnyCodable("James Wilson")]
                )
            ],
            totalParticipants: 42,
            lastComputedAt: now
        )
    }
}

extension UserRelationship {
    static let mockRelationships: [UserRelationship] = [
        UserRelationship(
            id: UUID(),
            userAId: UUID(),
            userBId: UUID(),
            relationshipType: .friend,
            status: .accepted,
            initiatedByUserId: UUID(),
            originGymId: UUID(),
            racePartnerMetadata: nil,
            lastInteractionAt: Date().addingTimeInterval(-86400 * 2),
            interactionCount: 15,
            createdAt: Date().addingTimeInterval(-86400 * 30),
            acceptedAt: Date().addingTimeInterval(-86400 * 29),
            endedAt: nil,
            updatedAt: Date().addingTimeInterval(-86400 * 2)
        ),
        UserRelationship(
            id: UUID(),
            userAId: UUID(),
            userBId: UUID(),
            relationshipType: .racePartner,
            status: .accepted,
            initiatedByUserId: UUID(),
            originGymId: UUID(),
            racePartnerMetadata: RacePartnerMetadata(
                raceDate: Date().addingTimeInterval(86400 * 45), // 45 days from now
                raceType: .doubles,
                raceLocation: "New York, NY",
                raceName: "HYROX New York 2025",
                targetTimeSeconds: 3600 // 1 hour target
            ),
            lastInteractionAt: Date().addingTimeInterval(-86400),
            interactionCount: 25,
            createdAt: Date().addingTimeInterval(-86400 * 15),
            acceptedAt: Date().addingTimeInterval(-86400 * 14),
            endedAt: nil,
            updatedAt: Date().addingTimeInterval(-86400)
        ),
        UserRelationship(
            id: UUID(),
            userAId: UUID(),
            userBId: UUID(),
            relationshipType: .gymMember,
            status: .accepted,
            initiatedByUserId: UUID(),
            originGymId: UUID(),
            racePartnerMetadata: nil,
            lastInteractionAt: Date().addingTimeInterval(-86400 * 5),
            interactionCount: 8,
            createdAt: Date().addingTimeInterval(-86400 * 60),
            acceptedAt: Date().addingTimeInterval(-86400 * 60),
            endedAt: nil,
            updatedAt: Date().addingTimeInterval(-86400 * 5)
        ),
        UserRelationship(
            id: UUID(),
            userAId: UUID(),
            userBId: UUID(),
            relationshipType: .friend,
            status: .accepted,
            initiatedByUserId: UUID(),
            originGymId: UUID(),
            racePartnerMetadata: nil,
            lastInteractionAt: Date().addingTimeInterval(-86400),
            interactionCount: 32,
            createdAt: Date().addingTimeInterval(-86400 * 90),
            acceptedAt: Date().addingTimeInterval(-86400 * 89),
            endedAt: nil,
            updatedAt: Date().addingTimeInterval(-86400)
        ),
        UserRelationship(
            id: UUID(),
            userAId: UUID(),
            userBId: UUID(),
            relationshipType: .friend,
            status: .accepted,
            initiatedByUserId: UUID(),
            originGymId: UUID(),
            racePartnerMetadata: nil,
            lastInteractionAt: Date().addingTimeInterval(-86400 * 3),
            interactionCount: 18,
            createdAt: Date().addingTimeInterval(-86400 * 45),
            acceptedAt: Date().addingTimeInterval(-86400 * 44),
            endedAt: nil,
            updatedAt: Date().addingTimeInterval(-86400 * 3)
        ),
        UserRelationship(
            id: UUID(),
            userAId: UUID(),
            userBId: UUID(),
            relationshipType: .racePartner,
            status: .accepted,
            initiatedByUserId: UUID(),
            originGymId: UUID(),
            racePartnerMetadata: RacePartnerMetadata(
                raceDate: Date().addingTimeInterval(86400 * 120), // 4 months from now
                raceType: .individual,
                raceLocation: "Las Vegas, NV",
                raceName: "HYROX World Championship",
                targetTimeSeconds: 3300 // 55 minute target
            ),
            lastInteractionAt: Date().addingTimeInterval(-86400 * 2),
            interactionCount: 45,
            createdAt: Date().addingTimeInterval(-86400 * 180),
            acceptedAt: Date().addingTimeInterval(-86400 * 179),
            endedAt: nil,
            updatedAt: Date().addingTimeInterval(-86400 * 2)
        )
    ]
}

extension RelationshipRequest {
    static let mockRequests: [RelationshipRequest] = [
        RelationshipRequest(
            id: UUID(),
            fromUserId: UUID(),
            toUserId: UUID(),
            relationshipType: .friend,
            message: "Hey! Great workout today, want to connect?",
            status: .pending,
            expiresAt: Date().addingTimeInterval(86400 * 7),
            createdAt: Date().addingTimeInterval(-3600),
            respondedAt: nil,
            updatedAt: Date().addingTimeInterval(-3600)
        ),
        RelationshipRequest(
            id: UUID(),
            fromUserId: UUID(),
            toUserId: UUID(),
            relationshipType: .racePartner,
            message: "Looking for a doubles partner for the next competition!",
            status: .pending,
            expiresAt: Date().addingTimeInterval(86400 * 7),
            createdAt: Date().addingTimeInterval(-7200),
            respondedAt: nil,
            updatedAt: Date().addingTimeInterval(-7200)
        )
    ]
}

extension ActivityComment {
    static let mockComments: [ActivityComment] = [
        ActivityComment(
            id: UUID(),
            activityId: UUID(),
            userId: UUID(),
            user: UserBasicInfo(
                id: UUID(),
                firstName: "John",
                lastName: "Doe",
                fitnessLevel: .intermediate,
                primaryGoal: "performance"
            ),
            commentText: "Amazing work! That's a solid time 💪",
            parentCommentId: nil,
            isDeleted: false,
            deletedAt: nil,
            createdAt: Date().addingTimeInterval(-1800),
            updatedAt: Date().addingTimeInterval(-1800)
        ),
        ActivityComment(
            id: UUID(),
            activityId: UUID(),
            userId: UUID(),
            user: UserBasicInfo(
                id: UUID(),
                firstName: "Kate",
                lastName: "Smith",
                fitnessLevel: .advanced,
                primaryGoal: "performance"
            ),
            commentText: "Congrats on the PR! 🎉",
            parentCommentId: nil,
            isDeleted: false,
            deletedAt: nil,
            createdAt: Date().addingTimeInterval(-3600),
            updatedAt: Date().addingTimeInterval(-3600)
        )
    ]
}
#endif
