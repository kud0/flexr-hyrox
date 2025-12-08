import Foundation
import CoreLocation

// MARK: - Gym

struct Gym: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    var description: String?

    // Location
    var locationAddress: String?
    var locationCity: String?
    var locationState: String?
    var locationCountry: String?
    var locationPostalCode: String?
    var latitude: Double?
    var longitude: Double?

    // Type and verification
    let gymType: GymType
    let isVerified: Bool
    var verifiedAt: Date?

    // Contact and social
    var websiteUrl: String?
    var phoneNumber: String?
    var email: String?
    var instagramHandle: String?

    // Stats
    let memberCount: Int
    let activeMemberCount: Int

    // Settings
    let isPublic: Bool
    let allowAutoJoin: Bool

    // Metadata
    let createdByUserId: UUID?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, description, latitude, longitude, email
        case locationAddress = "location_address"
        case locationCity = "location_city"
        case locationState = "location_state"
        case locationCountry = "location_country"
        case locationPostalCode = "location_postal_code"
        case gymType = "gym_type"
        case isVerified = "is_verified"
        case verifiedAt = "verified_at"
        case websiteUrl = "website_url"
        case phoneNumber = "phone_number"
        case instagramHandle = "instagram_handle"
        case memberCount = "member_count"
        case activeMemberCount = "active_member_count"
        case isPublic = "is_public"
        case allowAutoJoin = "allow_auto_join"
        case createdByUserId = "created_by_user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Computed Properties

    var fullAddress: String {
        var components: [String] = []
        if let address = locationAddress { components.append(address) }
        if let city = locationCity { components.append(city) }
        if let state = locationState { components.append(state) }
        if let country = locationCountry { components.append(country) }
        return components.joined(separator: ", ")
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var membershipStatus: String {
        if memberCount == 0 {
            return "No members yet"
        } else if memberCount == 1 {
            return "1 member"
        } else {
            return "\(memberCount) members"
        }
    }

    var activityLevel: ActivityLevel {
        guard memberCount > 0 else { return .new }
        let activeRatio = Double(activeMemberCount) / Double(memberCount)

        if activeRatio >= 0.7 {
            return .veryActive
        } else if activeRatio >= 0.5 {
            return .active
        } else if activeRatio >= 0.3 {
            return .moderate
        } else {
            return .quiet
        }
    }

    enum ActivityLevel: String {
        case new = "New"
        case quiet = "Quiet"
        case moderate = "Moderate"
        case active = "Active"
        case veryActive = "Very Active"

        var icon: String {
            switch self {
            case .new: return "sparkles"
            case .quiet: return "moon"
            case .moderate: return "figure.walk"
            case .active: return "figure.run"
            case .veryActive: return "bolt.fill"
            }
        }
    }
}

// MARK: - Gym Type

enum GymType: String, Codable, CaseIterable {
    case crossfit
    case hyroxAffiliate = "hyrox_affiliate"
    case commercialGym = "commercial_gym"
    case boutique
    case homeGym = "home_gym"
    case other

    var displayName: String {
        switch self {
        case .crossfit:
            return "CrossFit"
        case .hyroxAffiliate:
            return "HYROX Affiliate"
        case .commercialGym:
            return "Commercial Gym"
        case .boutique:
            return "Boutique Gym"
        case .homeGym:
            return "Home Gym"
        case .other:
            return "Other"
        }
    }

    var icon: String {
        switch self {
        case .crossfit:
            return "figure.strengthtraining.traditional"
        case .hyroxAffiliate:
            return "figure.mixed.cardio"
        case .commercialGym:
            return "building.2.fill"
        case .boutique:
            return "sparkles"
        case .homeGym:
            return "house.fill"
        case .other:
            return "ellipsis.circle"
        }
    }
}

// MARK: - Gym Membership

struct GymMembership: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    let gymId: UUID

    // Status and role
    var status: MembershipStatus
    var role: MembershipRole

    // Privacy settings
    var privacySettings: GymPrivacySettings

    // Activity
    var lastActivityAt: Date?
    var totalWorkoutsAtGym: Int

    // Dates
    let joinedAt: Date
    var approvedAt: Date?
    var leftAt: Date?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case gymId = "gym_id"
        case status, role
        case privacySettings = "privacy_settings"
        case lastActivityAt = "last_activity_at"
        case totalWorkoutsAtGym = "total_workouts_at_gym"
        case joinedAt = "joined_at"
        case approvedAt = "approved_at"
        case leftAt = "left_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Computed Properties

    var isPending: Bool {
        status == .pending
    }

    var isActive: Bool {
        status == .active
    }

    var canManageGym: Bool {
        role == .admin || role == .owner
    }

    var canCoach: Bool {
        role == .coach || role == .admin || role == .owner
    }

    var memberSince: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: joinedAt, relativeTo: Date())
    }
}

// MARK: - Membership Status

enum MembershipStatus: String, Codable, CaseIterable {
    case pending
    case active
    case inactive
    case left

    var displayName: String {
        switch self {
        case .pending:
            return "Pending Approval"
        case .active:
            return "Active"
        case .inactive:
            return "Inactive"
        case .left:
            return "Left"
        }
    }

    var icon: String {
        switch self {
        case .pending:
            return "clock"
        case .active:
            return "checkmark.circle.fill"
        case .inactive:
            return "pause.circle"
        case .left:
            return "xmark.circle"
        }
    }
}

// MARK: - Membership Role

enum MembershipRole: String, Codable, CaseIterable {
    case member
    case coach
    case admin
    case owner

    var displayName: String {
        switch self {
        case .member:
            return "Member"
        case .coach:
            return "Coach"
        case .admin:
            return "Admin"
        case .owner:
            return "Owner"
        }
    }

    var icon: String {
        switch self {
        case .member:
            return "person"
        case .coach:
            return "figure.wave"
        case .admin:
            return "person.badge.key"
        case .owner:
            return "crown.fill"
        }
    }

    var permissionLevel: Int {
        switch self {
        case .member:
            return 1
        case .coach:
            return 2
        case .admin:
            return 3
        case .owner:
            return 4
        }
    }
}

// MARK: - Gym Privacy Settings

struct GymPrivacySettings: Codable, Equatable {
    var showOnLeaderboard: Bool
    var showInMemberList: Bool
    var showWorkoutActivity: Bool
    var allowWorkoutComparisons: Bool
    var showProfileToMembers: Bool

    enum CodingKeys: String, CodingKey {
        case showOnLeaderboard = "show_on_leaderboard"
        case showInMemberList = "show_in_member_list"
        case showWorkoutActivity = "show_workout_activity"
        case allowWorkoutComparisons = "allow_workout_comparisons"
        case showProfileToMembers = "show_profile_to_members"
    }

    // Default privacy settings (all visible)
    static let `default` = GymPrivacySettings(
        showOnLeaderboard: true,
        showInMemberList: true,
        showWorkoutActivity: true,
        allowWorkoutComparisons: true,
        showProfileToMembers: true
    )

    // Private settings (all hidden)
    static let `private` = GymPrivacySettings(
        showOnLeaderboard: false,
        showInMemberList: false,
        showWorkoutActivity: false,
        allowWorkoutComparisons: false,
        showProfileToMembers: false
    )
}

// MARK: - Gym With Membership

struct GymWithMembership: Identifiable, Codable, Equatable {
    let gym: Gym
    let membership: GymMembership?

    var id: UUID {
        gym.id
    }

    var isMember: Bool {
        membership != nil && membership?.isActive == true
    }

    var canManage: Bool {
        membership?.canManageGym == true
    }
}

// MARK: - Gym Member

struct GymMember: Identifiable, Codable, Equatable {
    let userId: UUID
    var firstName: String?
    var lastName: String?
    var fitnessLevel: ExperienceLevel
    var primaryGoal: String?
    let role: MembershipRole
    let joinedAt: Date
    let totalWorkoutsAtGym: Int

    var isFriend: Bool?
    var isPartner: Bool?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case fitnessLevel = "fitness_level"
        case primaryGoal = "primary_goal"
        case role
        case joinedAt = "joined_at"
        case totalWorkoutsAtGym = "total_workouts_at_gym"
        case isFriend = "is_friend"
        case isPartner = "is_partner"
    }

    var id: UUID {
        userId
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

// MARK: - Gym Search Filters

struct GymSearchFilters: Codable {
    var query: String?
    var city: String?
    var state: String?
    var country: String?
    var gymType: GymType?
    var latitude: Double?
    var longitude: Double?
    var radiusKm: Double?
    var isVerified: Bool?
    var limit: Int?
    var offset: Int?

    // Default search (nearby, all types)
    static let nearby = GymSearchFilters(radiusKm: 25, limit: 20)

    // Verified only
    static let verified = GymSearchFilters(isVerified: true, limit: 20)
}

// MARK: - Nearby Gym

struct NearbyGym: Identifiable, Codable, Equatable {
    let gym: Gym
    let distanceKm: Double

    var id: UUID {
        gym.id
    }

    var distanceText: String {
        if distanceKm < 1 {
            return String(format: "%.0f m", distanceKm * 1000)
        } else {
            return String(format: "%.1f km", distanceKm)
        }
    }

    var isNearby: Bool {
        distanceKm < 5
    }

    enum CodingKeys: String, CodingKey {
        case gym
        case distanceKm = "distance_km"
    }
}
