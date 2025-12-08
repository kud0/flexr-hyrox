// FLEXR - Gym Admin View
// Manage gym settings, approve members, and handle administrative tasks

import SwiftUI

struct GymAdminView: View {
    let gym: Gym

    @StateObject private var supabase = SupabaseService.shared
    @State private var pendingMembers: [GymMemberRequest] = []
    @State private var activeMembers: [GymMember] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    #if DEBUG
    @State private var useMockData = true
    #else
    @State private var useMockData = false
    #endif

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                if isLoading {
                    loadingView
                } else {
                    List {
                        pendingRequestsSection
                        activeMembersSection
                        settingsSection
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("\(gym.name)")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Sections

    private var pendingRequestsSection: some View {
        Section {
            if pendingMembers.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 32))
                            .foregroundStyle(DesignSystem.Colors.success)

                        Text("No pending requests")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundStyle(DesignSystem.Colors.text.secondary)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
                .listRowBackground(DesignSystem.Colors.surface)
            } else {
                ForEach(pendingMembers) { member in
                    PendingMemberRow(
                        member: member,
                        onApprove: {
                            await approveMember(member)
                        },
                        onReject: {
                            await rejectMember(member)
                        }
                    )
                    .listRowBackground(DesignSystem.Colors.surface)
                }
            }
        } header: {
            HStack {
                Text("Pending Requests")
                    .font(DesignSystem.Typography.bodyEmphasized)
                    .foregroundStyle(DesignSystem.Colors.text.primary)

                if !pendingMembers.isEmpty {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.error)
                            .frame(width: 24, height: 24)

                        Text("\(pendingMembers.count)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }

    private var activeMembersSection: some View {
        Section {
            if activeMembers.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "person.2")
                            .font(.system(size: 32))
                            .foregroundStyle(DesignSystem.Colors.text.tertiary)

                        Text("No active members yet")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundStyle(DesignSystem.Colors.text.secondary)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
                .listRowBackground(DesignSystem.Colors.surface)
            } else {
                ForEach(activeMembers) { member in
                    MemberRow(member: member)
                        .listRowBackground(DesignSystem.Colors.surface)
                }
            }
        } header: {
            HStack {
                Text("Active Members")
                    .font(DesignSystem.Typography.bodyEmphasized)
                    .foregroundStyle(DesignSystem.Colors.text.primary)

                Spacer()

                Text("(\(activeMembers.count))")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)
            }
        }
    }

    private var settingsSection: some View {
        Section {
            NavigationLink {
                GymEditView(gym: gym)
            } label: {
                HStack {
                    Image(systemName: "pencil")
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .frame(width: 24)

                    Text("Edit Gym Information")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.text.primary)
                }
            }
            .listRowBackground(DesignSystem.Colors.surface)

            NavigationLink {
                GymPrivacySettingsView(gym: gym)
            } label: {
                HStack {
                    Image(systemName: "lock.shield")
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .frame(width: 24)

                    Text("Privacy & Access Settings")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.text.primary)
                }
            }
            .listRowBackground(DesignSystem.Colors.surface)

            NavigationLink {
                GymInviteCodeView(gym: gym)
            } label: {
                HStack {
                    Image(systemName: "qrcode")
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .frame(width: 24)

                    Text("Invite Codes")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.text.primary)
                }
            }
            .listRowBackground(DesignSystem.Colors.surface)
        } header: {
            Text("Gym Settings")
                .font(DesignSystem.Typography.bodyEmphasized)
                .foregroundStyle(DesignSystem.Colors.text.primary)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(DesignSystem.Colors.primary)
                .scaleEffect(1.2)

            Text("Loading gym data...")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.text.secondary)
        }
    }

    // MARK: - Actions

    private func loadData() async {
        isLoading = true
        defer { isLoading = false }

        #if DEBUG
        if useMockData {
            // Simulate network delay
            try? await Task.sleep(nanoseconds: 500_000_000)

            // Mock data
            pendingMembers = GymMemberRequest.mockRequests
            activeMembers = GymMember.mockMembers
            return
        }
        #endif

        do {
            // TODO: Load pending members and active members from Supabase
            // async let pending = supabase.getPendingGymMembers(gymId: gym.id)
            // async let active = supabase.getActiveGymMembers(gymId: gym.id)
            //
            // pendingMembers = try await pending
            // activeMembers = try await active

            // For now, simulate empty state
            pendingMembers = []
            activeMembers = []
        } catch {
            errorMessage = "Failed to load gym data"
            print("Failed to load gym data: \(error)")
        }
    }

    private func approveMember(_ member: GymMemberRequest) async {
        do {
            // TODO: Approve member via Supabase
            // try await supabase.approveGymMember(gymId: gym.id, userId: member.userId)

            // Remove from pending list
            pendingMembers.removeAll { $0.id == member.id }

            // Add to active members (would come from backend in real app)
            // await loadData()
        } catch {
            errorMessage = "Failed to approve member"
            print("Failed to approve member: \(error)")
        }
    }

    private func rejectMember(_ member: GymMemberRequest) async {
        do {
            // TODO: Reject member via Supabase
            // try await supabase.rejectGymMember(gymId: gym.id, userId: member.userId)

            // Remove from pending list
            pendingMembers.removeAll { $0.id == member.id }
        } catch {
            errorMessage = "Failed to reject member"
            print("Failed to reject member: \(error)")
        }
    }
}

// MARK: - Pending Member Row Component

private struct PendingMemberRow: View {
    let member: GymMemberRequest
    let onApprove: () async -> Void
    let onReject: () async -> Void

    @State private var isProcessing = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.primary.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: "person.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(DesignSystem.Colors.primary)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(member.displayName)
                        .font(DesignSystem.Typography.bodyEmphasized)
                        .foregroundStyle(DesignSystem.Colors.text.primary)

                    HStack(spacing: 12) {
                        Label(member.fitnessLevel, systemImage: "figure.run")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.text.secondary)

                        if let goal = member.primaryGoal {
                            Label(goal, systemImage: "target")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.text.secondary)
                        }
                    }
                }

                Spacer()
            }

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    Task {
                        isProcessing = true
                        await onReject()
                        isProcessing = false
                    }
                } label: {
                    Text("Decline")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(DesignSystem.Colors.text.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(DesignSystem.Colors.background)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(DesignSystem.Colors.divider, lineWidth: 1)
                        )
                }
                .disabled(isProcessing)

                Button {
                    Task {
                        isProcessing = true
                        await onApprove()
                        isProcessing = false
                    }
                } label: {
                    if isProcessing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Approve")
                            .font(DesignSystem.Typography.subheadline)
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(DesignSystem.Colors.success)
                .cornerRadius(8)
                .disabled(isProcessing)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Member Row Component

private struct MemberRow: View {
    let member: GymMember

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.primary.opacity(0.2))
                    .frame(width: 48, height: 48)

                Image(systemName: "person.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(DesignSystem.Colors.primary)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(member.displayName)
                    .font(DesignSystem.Typography.bodyEmphasized)
                    .foregroundStyle(DesignSystem.Colors.text.primary)

                HStack(spacing: 12) {
                    Label(member.fitnessLevel.displayName, systemImage: "figure.run")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.text.secondary)

                    if member.role != .member {
                        Text(member.role.displayName.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(DesignSystem.Colors.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DesignSystem.Colors.primary.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }

            Spacer()

            // Member since
            Text(member.joinedAt, style: .relative)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.text.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Mock Data Extensions

struct GymMemberRequest: Identifiable {
    let id: UUID
    let userId: UUID
    let displayName: String
    let fitnessLevel: String
    let primaryGoal: String?
    let requestedAt: Date

    static let mockRequests: [GymMemberRequest] = [
        GymMemberRequest(
            id: UUID(),
            userId: UUID(),
            displayName: "John Doe",
            fitnessLevel: "Intermediate",
            primaryGoal: "Performance",
            requestedAt: Date().addingTimeInterval(-3600)
        ),
        GymMemberRequest(
            id: UUID(),
            userId: UUID(),
            displayName: "Jane Smith",
            fitnessLevel: "Advanced",
            primaryGoal: "Competition",
            requestedAt: Date().addingTimeInterval(-7200)
        )
    ]
}

extension GymMember {
    static let mockMembers: [GymMember] = [
        GymMember(
            userId: UUID(),
            firstName: "Alex",
            lastName: "Johnson",
            fitnessLevel: .advanced,
            primaryGoal: "performance",
            role: .admin,
            joinedAt: Date().addingTimeInterval(-86400 * 30),
            totalWorkoutsAtGym: 45,
            isFriend: false,
            isPartner: false
        ),
        GymMember(
            userId: UUID(),
            firstName: "Sarah",
            lastName: "Williams",
            fitnessLevel: .intermediate,
            primaryGoal: "weight_loss",
            role: .member,
            joinedAt: Date().addingTimeInterval(-86400 * 15),
            totalWorkoutsAtGym: 22,
            isFriend: true,
            isPartner: false
        ),
        GymMember(
            userId: UUID(),
            firstName: "Mike",
            lastName: "Brown",
            fitnessLevel: .beginner,
            primaryGoal: "competition",
            role: .member,
            joinedAt: Date().addingTimeInterval(-86400 * 7),
            totalWorkoutsAtGym: 8,
            isFriend: false,
            isPartner: false
        )
    ]
}

// MARK: - Placeholder Views (To be implemented)

struct GymEditView: View {
    let gym: Gym

    var body: some View {
        Text("Edit Gym - Coming Soon")
            .navigationTitle("Edit Gym")
    }
}

struct GymPrivacySettingsView: View {
    let gym: Gym

    var body: some View {
        Text("Privacy Settings - Coming Soon")
            .navigationTitle("Privacy Settings")
    }
}

struct GymInviteCodeView: View {
    let gym: Gym

    var body: some View {
        Text("Invite Codes - Coming Soon")
            .navigationTitle("Invite Codes")
    }
}

#Preview {
    GymAdminView(gym: Gym.mockGyms[0])
}
