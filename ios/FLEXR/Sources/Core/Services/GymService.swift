// FLEXR - Gym Service
// Handles gym and membership operations

import Foundation

// MARK: - Gym Service Extension
extension SupabaseService {

    // MARK: - Gym Operations

    /// Search gyms with filters
    func searchGyms(
        query: String? = nil,
        city: String? = nil,
        state: String? = nil,
        country: String? = nil,
        gymType: GymType? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        radiusKm: Double? = nil,
        isVerified: Bool? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> [Gym] {
        var queryBuilder = client
            .database.from("gyms")
            .select()

        if let query = query {
            queryBuilder = queryBuilder.or("name.ilike.%\(query)%,description.ilike.%\(query)%")
        }
        if let city = city {
            queryBuilder = queryBuilder.eq("location_city", value: city)
        }
        if let state = state {
            queryBuilder = queryBuilder.eq("location_state", value: state)
        }
        if let country = country {
            queryBuilder = queryBuilder.eq("location_country", value: country)
        }
        let gyms: [Gym]

        if let gymType = gymType {
            if let isVerified = isVerified {
                gyms = try await queryBuilder
                    .eq("gym_type", value: gymType.rawValue)
                    .eq("is_verified", value: isVerified)
                    .order("member_count", ascending: false)
                    .range(from: offset, to: offset + limit - 1)
                    .execute()
                    .value
            } else {
                gyms = try await queryBuilder
                    .eq("gym_type", value: gymType.rawValue)
                    .order("member_count", ascending: false)
                    .range(from: offset, to: offset + limit - 1)
                    .execute()
                    .value
            }
        } else if let isVerified = isVerified {
            gyms = try await queryBuilder
                .eq("is_verified", value: isVerified)
                .order("member_count", ascending: false)
                .range(from: offset, to: offset + limit - 1)
                .execute()
                .value
        } else {
            gyms = try await queryBuilder
                .order("member_count", ascending: false)
                .range(from: offset, to: offset + limit - 1)
                .execute()
                .value
        }

        // If location-based search, filter by distance
        if let lat = latitude, let lon = longitude, let radius = radiusKm {
            return gyms.filter { gym in
                guard let gymLat = gym.latitude, let gymLon = gym.longitude else { return false }
                let distance = calculateDistance(
                    lat1: lat, lon1: lon,
                    lat2: gymLat, lon2: gymLon
                )
                return distance <= radius
            }
        }

        return gyms
    }

    /// Get gym by ID with membership info
    func getGym(id: UUID) async throws -> GymWithMembership {
        let gym: Gym = try await client
            .database.from("gyms")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value

        // Try to get user's membership
        var membership: GymMembership?
        if let userId = (try? await client.auth.session)?.user.id {
            membership = try? await client
                .database.from("gym_memberships")
                .select()
                .eq("gym_id", value: id.uuidString)
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()
                .value
        }

        return GymWithMembership(gym: gym, membership: membership)
    }

    /// Create a new gym
    func createGym(
        name: String,
        description: String?,
        gymType: GymType,
        locationAddress: String?,
        locationCity: String?,
        locationState: String?,
        locationCountry: String?,
        locationPostalCode: String?,
        latitude: Double?,
        longitude: Double?,
        websiteUrl: String?,
        phoneNumber: String?,
        email: String?,
        instagramHandle: String?,
        isPublic: Bool,
        allowAutoJoin: Bool
    ) async throws -> Gym {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        struct GymInsert: Encodable {
            let name: String
            let description: String?
            let gym_type: String
            let location_address: String?
            let location_city: String?
            let location_state: String?
            let location_country: String?
            let location_postal_code: String?
            let latitude: Double?
            let longitude: Double?
            let website_url: String?
            let phone_number: String?
            let email: String?
            let instagram_handle: String?
            let is_public: Bool
            let allow_auto_join: Bool
            let created_by_user_id: String
        }

        let insert = GymInsert(
            name: name,
            description: description,
            gym_type: gymType.rawValue,
            location_address: locationAddress,
            location_city: locationCity,
            location_state: locationState,
            location_country: locationCountry,
            location_postal_code: locationPostalCode,
            latitude: latitude,
            longitude: longitude,
            website_url: websiteUrl,
            phone_number: phoneNumber,
            email: email,
            instagram_handle: instagramHandle,
            is_public: isPublic,
            allow_auto_join: allowAutoJoin,
            created_by_user_id: userId.uuidString
        )

        let gym: Gym = try await client
            .database.from("gyms")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value

        return gym
    }

    /// Update gym details
    func updateGym(
        id: UUID,
        name: String?,
        description: String?,
        locationAddress: String?,
        locationCity: String?,
        locationState: String?,
        locationCountry: String?,
        locationPostalCode: String?,
        latitude: Double?,
        longitude: Double?,
        websiteUrl: String?,
        phoneNumber: String?,
        email: String?,
        instagramHandle: String?,
        isPublic: Bool?,
        allowAutoJoin: Bool?
    ) async throws -> Gym {
        var updates: [String: AnyEncodable] = [:]

        if let name = name { updates["name"] = AnyEncodable(name) }
        if let description = description { updates["description"] = AnyEncodable(description) }
        if let locationAddress = locationAddress { updates["location_address"] = AnyEncodable(locationAddress) }
        if let locationCity = locationCity { updates["location_city"] = AnyEncodable(locationCity) }
        if let locationState = locationState { updates["location_state"] = AnyEncodable(locationState) }
        if let locationCountry = locationCountry { updates["location_country"] = AnyEncodable(locationCountry) }
        if let locationPostalCode = locationPostalCode { updates["location_postal_code"] = AnyEncodable(locationPostalCode) }
        if let latitude = latitude { updates["latitude"] = AnyEncodable(latitude) }
        if let longitude = longitude { updates["longitude"] = AnyEncodable(longitude) }
        if let websiteUrl = websiteUrl { updates["website_url"] = AnyEncodable(websiteUrl) }
        if let phoneNumber = phoneNumber { updates["phone_number"] = AnyEncodable(phoneNumber) }
        if let email = email { updates["email"] = AnyEncodable(email) }
        if let instagramHandle = instagramHandle { updates["instagram_handle"] = AnyEncodable(instagramHandle) }
        if let isPublic = isPublic { updates["is_public"] = AnyEncodable(isPublic) }
        if let allowAutoJoin = allowAutoJoin { updates["allow_auto_join"] = AnyEncodable(allowAutoJoin) }

        let gym: Gym = try await client
            .database.from("gyms")
            .update(updates)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value

        return gym
    }

    // MARK: - Membership Operations

    /// Join a gym
    func joinGym(
        gymId: UUID,
        role: MembershipRole = .member,
        privacySettings: GymPrivacySettings = .default
    ) async throws -> GymMembership {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        struct MembershipInsert: Encodable {
            let user_id: String
            let gym_id: String
            let role: String
            let status: String
            let privacy_settings: GymPrivacySettings
        }

        let insert = MembershipInsert(
            user_id: userId.uuidString,
            gym_id: gymId.uuidString,
            role: role.rawValue,
            status: MembershipStatus.active.rawValue,
            privacy_settings: privacySettings
        )

        let membership: GymMembership = try await client
            .database.from("gym_memberships")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value

        return membership
    }

    /// Leave a gym
    func leaveGym(gymId: UUID) async throws {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        try await client
            .database.from("gym_memberships")
            .update([
                "status": AnyEncodable(MembershipStatus.left.rawValue),
                "left_at": AnyEncodable(Date().ISO8601Format())
            ])
            .eq("user_id", value: userId.uuidString)
            .eq("gym_id", value: gymId.uuidString)
            .execute()
    }

    /// Update membership privacy settings
    func updateMembershipPrivacy(
        gymId: UUID,
        privacySettings: GymPrivacySettings
    ) async throws -> GymMembership {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let membership: GymMembership = try await client
            .database.from("gym_memberships")
            .update(["privacy_settings": privacySettings])
            .eq("user_id", value: userId.uuidString)
            .eq("gym_id", value: gymId.uuidString)
            .select()
            .single()
            .execute()
            .value

        return membership
    }

    /// Get gym members
    func getGymMembers(
        gymId: UUID,
        role: MembershipRole? = nil,
        limit: Int = 50,
        offset: Int = 0
    ) async throws -> [GymMember] {
        var query = client
            .database.from("gym_memberships")
            .select("user_id, role, joined_at, total_workouts_at_gym, users!inner(first_name, last_name, fitness_level, primary_goal)")
            .eq("gym_id", value: gymId.uuidString)
            .eq("status", value: MembershipStatus.active.rawValue)

        let members: [GymMember]

        if let role = role {
            members = try await query
                .eq("role", value: role.rawValue)
                .order("joined_at", ascending: false)
                .range(from: offset, to: offset + limit - 1)
                .execute()
                .value
        } else {
            members = try await query
                .order("joined_at", ascending: false)
                .range(from: offset, to: offset + limit - 1)
                .execute()
                .value
        }

        return members
    }

    /// Get user's gym memberships
    func getUserMemberships(
        status: MembershipStatus? = nil
    ) async throws -> [GymWithMembership] {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        struct MembershipWithGym: Decodable {
            let membership: GymMembership
            let gym: Gym
        }

        let results: [MembershipWithGym]

        if let status = status {
            results = try await client
                .database.from("gym_memberships")
                .select("*, gyms!inner(*)")
                .eq("user_id", value: userId.uuidString)
                .eq("status", value: status.rawValue)
                .order("joined_at", ascending: false)
                .execute()
                .value
        } else {
            results = try await client
                .database.from("gym_memberships")
                .select("*, gyms!inner(*)")
                .eq("user_id", value: userId.uuidString)
                .order("joined_at", ascending: false)
                .execute()
                .value
        }

        return results.map { GymWithMembership(gym: $0.gym, membership: $0.membership) }
    }

    // MARK: - Helper Functions

    /// Calculate distance between two coordinates (Haversine formula)
    private func calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let earthRadius = 6371.0 // km

        let dLat = (lat2 - lat1) * .pi / 180.0
        let dLon = (lon2 - lon1) * .pi / 180.0

        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180.0) * cos(lat2 * .pi / 180.0) *
                sin(dLon / 2) * sin(dLon / 2)

        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadius * c
    }
}
