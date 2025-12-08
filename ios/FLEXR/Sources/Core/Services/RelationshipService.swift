// FLEXR - Relationship Service
// Handles user relationships (gym members, friends, race partners)

import Foundation

// MARK: - Relationship Service Extension
extension SupabaseService {

    // MARK: - Relationship Operations

    /// Get user's relationships
    func getUserRelationships(
        type: RelationshipType? = nil,
        status: RelationshipStatus? = nil
    ) async throws -> [UserRelationship] {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        // Use RPC function to handle canonical ordering
        struct RelationshipQuery: Encodable {
            let p_user_id: String
            let p_type: String?
            let p_status: String?
        }

        let query = RelationshipQuery(
            p_user_id: userId.uuidString,
            p_type: type?.rawValue,
            p_status: status?.rawValue
        )

        let relationships: [UserRelationship] = try await client
            .database.rpc("get_user_relationships", params: query)
            .execute()
            .value

        return relationships
    }

    /// Get specific relationship
    func getRelationship(withUserId otherUserId: UUID) async throws -> UserRelationship? {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let relationship: UserRelationship? = try? await client
            .database.from("user_relationships")
            .select()
            .or("and(user_a_id.eq.\(userId.uuidString),user_b_id.eq.\(otherUserId.uuidString)),and(user_a_id.eq.\(otherUserId.uuidString),user_b_id.eq.\(userId.uuidString))")
            .single()
            .execute()
            .value

        return relationship
    }

    /// Create relationship (internal - called after request accepted)
    private func createRelationship(
        withUserId otherUserId: UUID,
        type: RelationshipType,
        gymId: UUID?
    ) async throws -> UserRelationship {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        // Ensure canonical ordering (smaller UUID first)
        let (userAId, userBId) = userId.uuidString < otherUserId.uuidString
            ? (userId, otherUserId)
            : (otherUserId, userId)

        struct RelationshipInsert: Encodable {
            let user_a_id: String
            let user_b_id: String
            let relationship_type: String
            let status: String
            let origin_gym_id: String?
        }

        let insert = RelationshipInsert(
            user_a_id: userAId.uuidString,
            user_b_id: userBId.uuidString,
            relationship_type: type.rawValue,
            status: RelationshipStatus.accepted.rawValue,
            origin_gym_id: gymId?.uuidString
        )

        let relationship: UserRelationship = try await client
            .database.from("user_relationships")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value

        return relationship
    }

    /// Remove relationship
    func removeRelationship(withUserId otherUserId: UUID) async throws {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        try await client
            .database.from("user_relationships")
            .delete()
            .or("and(user_a_id.eq.\(userId.uuidString),user_b_id.eq.\(otherUserId.uuidString)),and(user_a_id.eq.\(otherUserId.uuidString),user_b_id.eq.\(userId.uuidString))")
            .execute()
    }

    /// Check if user has an active race partner
    func hasRacePartner() async throws -> Bool {
        let racePartners = try await getUserRelationships(
            type: .racePartner,
            status: .accepted
        )
        return !racePartners.isEmpty
    }

    /// Get current race partner (if any)
    func getCurrentRacePartner() async throws -> UserRelationship? {
        let racePartners = try await getUserRelationships(
            type: .racePartner,
            status: .accepted
        )
        return racePartners.first
    }

    /// Upgrade relationship type (e.g., gym_member -> friend -> race_partner)
    func upgradeRelationship(
        withUserId otherUserId: UUID,
        to newType: RelationshipType
    ) async throws -> UserRelationship {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        // CRITICAL: Enforce single race partner constraint
        if newType == .racePartner {
            if try await hasRacePartner() {
                throw SupabaseError.racePartnerLimitReached
            }
        }

        let relationship: UserRelationship = try await client
            .database.from("user_relationships")
            .update(["relationship_type": newType.rawValue])
            .or("and(user_a_id.eq.\(userId.uuidString),user_b_id.eq.\(otherUserId.uuidString)),and(user_a_id.eq.\(otherUserId.uuidString),user_b_id.eq.\(userId.uuidString))")
            .select()
            .single()
            .execute()
            .value

        return relationship
    }

    // MARK: - Relationship Requests

    /// Send relationship request
    func sendRelationshipRequest(
        to recipientId: UUID,
        type: RelationshipType,
        message: String? = nil
    ) async throws -> RelationshipRequest {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        struct RequestInsert: Encodable {
            let sender_id: String
            let recipient_id: String
            let request_type: String
            let message: String?
            let status: String
        }

        let insert = RequestInsert(
            sender_id: userId.uuidString,
            recipient_id: recipientId.uuidString,
            request_type: type.rawValue,
            message: message,
            status: RequestStatus.pending.rawValue
        )

        let request: RelationshipRequest = try await client
            .database.from("relationship_requests")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value

        return request
    }

    /// Get pending relationship requests (received)
    func getPendingRequests() async throws -> [RelationshipRequest] {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let requests: [RelationshipRequest] = try await client
            .database.from("relationship_requests")
            .select()
            .eq("recipient_id", value: userId.uuidString)
            .eq("status", value: RequestStatus.pending.rawValue)
            .order("created_at", ascending: false)
            .execute()
            .value

        return requests
    }

    /// Get sent relationship requests
    func getSentRequests() async throws -> [RelationshipRequest] {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let requests: [RelationshipRequest] = try await client
            .database.from("relationship_requests")
            .select()
            .eq("sender_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return requests
    }

    /// Accept relationship request
    func acceptRelationshipRequest(requestId: UUID) async throws -> UserRelationship {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        // Get the request
        let request: RelationshipRequest = try await client
            .database.from("relationship_requests")
            .select()
            .eq("id", value: requestId.uuidString)
            .eq("recipient_id", value: userId.uuidString)
            .single()
            .execute()
            .value

        guard request.status == .pending else {
            throw SupabaseError.databaseError("Request already processed")
        }

        // Create the relationship
        let relationship = try await createRelationship(
            withUserId: request.fromUserId,
            type: request.relationshipType,
            gymId: nil
        )

        // Update request status
        try await client
            .database.from("relationship_requests")
            .update(["status": RequestStatus.accepted.rawValue])
            .eq("id", value: requestId.uuidString)
            .execute()

        return relationship
    }

    /// Reject relationship request
    func rejectRelationshipRequest(requestId: UUID) async throws {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        try await client
            .database.from("relationship_requests")
            .update(["status": RequestStatus.declined.rawValue])
            .eq("id", value: requestId.uuidString)
            .eq("to_user_id", value: userId.uuidString)
            .execute()
    }

    /// Cancel sent request
    func cancelRelationshipRequest(requestId: UUID) async throws {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        try await client
            .database.from("relationship_requests")
            .delete()
            .eq("id", value: requestId.uuidString)
            .eq("sender_id", value: userId.uuidString)
            .eq("status", value: RequestStatus.pending.rawValue)
            .execute()
    }

    // MARK: - Relationship Permissions

    /// Get relationship permissions
    func getRelationshipPermissions(withUserId otherUserId: UUID) async throws -> RelationshipPermissions? {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let permissions: RelationshipPermissions? = try? await client
            .database.from("relationship_permissions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .or("and(user_a_id.eq.\(userId.uuidString),user_b_id.eq.\(otherUserId.uuidString)),and(user_a_id.eq.\(otherUserId.uuidString),user_b_id.eq.\(userId.uuidString))")
            .single()
            .execute()
            .value

        return permissions
    }

    /// Update relationship permissions
    func updateRelationshipPermissions(
        withUserId otherUserId: UUID,
        permissions: RelationshipPermissions
    ) async throws -> RelationshipPermissions {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let updated: RelationshipPermissions = try await client
            .database.from("relationship_permissions")
            .update(permissions)
            .eq("user_id", value: userId.uuidString)
            .or("and(user_a_id.eq.\(userId.uuidString),user_b_id.eq.\(otherUserId.uuidString)),and(user_a_id.eq.\(otherUserId.uuidString),user_b_id.eq.\(userId.uuidString))")
            .select()
            .single()
            .execute()
            .value

        return updated
    }

    // MARK: - Invite Codes

    /// Generate invite code
    func generateInviteCode(
        type: RelationshipType,
        gymId: UUID? = nil,
        maxUses: Int = 1,
        expiresInDays: Int = 7
    ) async throws -> RelationshipInviteCode {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let code = generateRandomCode()
        let expiresAt = Calendar.current.date(byAdding: .day, value: expiresInDays, to: Date())!

        struct InviteCodeInsert: Encodable {
            let code: String
            let created_by_user_id: String
            let relationship_type: String
            let gym_id: String?
            let max_uses: Int
            let expires_at: String
        }

        let insert = InviteCodeInsert(
            code: code,
            created_by_user_id: userId.uuidString,
            relationship_type: type.rawValue,
            gym_id: gymId?.uuidString,
            max_uses: maxUses,
            expires_at: expiresAt.ISO8601Format()
        )

        let inviteCode: RelationshipInviteCode = try await client
            .database.from("relationship_invite_codes")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value

        return inviteCode
    }

    /// Redeem invite code
    func redeemInviteCode(code: String) async throws -> UserRelationship {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        // Get the invite code
        let inviteCode: RelationshipInviteCode = try await client
            .database.from("relationship_invite_codes")
            .select()
            .eq("code", value: code)
            .eq("is_active", value: true)
            .single()
            .execute()
            .value

        // Validate
        guard inviteCode.currentUses < inviteCode.maxUses else {
            throw SupabaseError.databaseError("Invite code has reached maximum uses")
        }
        guard inviteCode.expiresAt > Date() else {
            throw SupabaseError.databaseError("Invite code has expired")
        }

        // Create relationship
        let relationship = try await createRelationship(
            withUserId: inviteCode.userId,
            type: inviteCode.relationshipType,
            gymId: nil
        )

        // Increment uses
        try await client
            .database.from("relationship_invite_codes")
            .update(["current_uses": inviteCode.currentUses + 1])
            .eq("id", value: inviteCode.id.uuidString)
            .execute()

        return relationship
    }

    /// Get user's invite codes
    func getUserInviteCodes(active: Bool? = nil) async throws -> [RelationshipInviteCode] {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        let codes: [RelationshipInviteCode]

        if let active = active {
            codes = try await client
                .database.from("relationship_invite_codes")
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("is_active", value: active)
                .order("created_at", ascending: false)
                .execute()
                .value
        } else {
            codes = try await client
                .database.from("relationship_invite_codes")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
        }

        return codes
    }

    /// Deactivate invite code
    func deactivateInviteCode(id: UUID) async throws {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        try await client
            .database.from("relationship_invite_codes")
            .update(["is_active": false])
            .eq("id", value: id.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    // MARK: - Helper Functions

    /// Generate random invite code (format: XXXX-XXXX-XXXX)
    private func generateRandomCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Exclude ambiguous chars
        let segments = (0..<3).map { _ in
            String((0..<4).map { _ in chars.randomElement()! })
        }
        return segments.joined(separator: "-")
    }
}
