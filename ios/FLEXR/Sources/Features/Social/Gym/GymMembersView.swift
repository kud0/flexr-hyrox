// FLEXR - Gym Members View
// Browse and search gym members

import SwiftUI

struct GymMembersView: View {
    let gymId: UUID

    @StateObject private var supabase = SupabaseService.shared
    @State private var members: [GymMember] = []
    @State private var isLoading = true
    @State private var searchQuery = ""
    @State private var selectedRole: MembershipRole?

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Search and filters
                searchSection

                // Member list
                if isLoading {
                    loadingView
                } else if filteredMembers.isEmpty {
                    emptyState
                } else {
                    memberList
                }
            }
        }
        .navigationTitle("Members")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadMembers()
        }
    }

    // MARK: - Search Section

    private var searchSection: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(DesignSystem.Colors.text.secondary)

                TextField("Search members...", text: $searchQuery)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.text.primary)

                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(DesignSystem.Colors.text.tertiary)
                    }
                }
            }
            .padding()
            .background(DesignSystem.Colors.surface)
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.top)

            // Role filters
            roleFilters
        }
        .background(DesignSystem.Colors.background)
    }

    private var roleFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All members
                FilterChip(
                    title: "All",
                    icon: "person.2.fill",
                    isSelected: selectedRole == nil
                ) {
                    selectedRole = nil
                }

                // Role filters
                ForEach(MembershipRole.allCases, id: \.self) { role in
                    FilterChip(
                        title: role.displayName,
                        icon: role.icon,
                        isSelected: selectedRole == role
                    ) {
                        selectedRole = selectedRole == role ? nil : role
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Member List

    private var memberList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredMembers) { member in
                    NavigationLink(destination: MemberProfileView(member: member, gymId: gymId)) {
                        MemberCard(member: member)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Filtered Members

    private var filteredMembers: [GymMember] {
        var filtered = members

        // Filter by role
        if let role = selectedRole {
            filtered = filtered.filter { $0.role == role }
        }

        // Filter by search query
        if !searchQuery.isEmpty {
            filtered = filtered.filter { member in
                member.displayName.localizedCaseInsensitiveContains(searchQuery)
            }
        }

        return filtered
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 64))
                .foregroundStyle(DesignSystem.Colors.text.tertiary)

            Text("No members found")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            Text(searchQuery.isEmpty ? "This gym has no members yet" : "Try adjusting your search")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.text.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack {
            ProgressView()
                .tint(DesignSystem.Colors.primary)
                .scaleEffect(1.2)

            Text("Loading members...")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.text.secondary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    // MARK: - Actions

    private func loadMembers() async {
        isLoading = true
        defer { isLoading = false }

        do {
            members = try await supabase.getGymMembers(gymId: gymId, limit: 200)
        } catch {
            print("Failed to load gym members: \(error)")
        }
    }
}

// MARK: - Filter Chip Component

private struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))

                Text(title)
                    .font(DesignSystem.Typography.subheadline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.surface
            )
            .foregroundStyle(
                isSelected ? .white : DesignSystem.Colors.text.primary
            )
            .cornerRadius(20)
        }
    }
}

// MARK: - Member Card Component

private struct MemberCard: View {
    let member: GymMember

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.primary.opacity(0.2))
                    .frame(width: 56, height: 56)

                Text(member.initials)
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.primary)
            }

            // Member info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(member.displayName)
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.text.primary)

                    if member.role != .member {
                        Image(systemName: member.role.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(roleColor(for: member.role))
                    }

                    Spacer()
                }

                // Experience level
                Text(member.fitnessLevel.displayName)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)

                // Stats row
                HStack(spacing: 16) {
                    Label("\(member.totalWorkoutsAtGym)", systemImage: "figure.mixed.cardio")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.text.secondary)

                    if let isFriend = member.isFriend, isFriend {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                            Text("Friend")
                        }
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.secondary)
                    }

                    if let isPartner = member.isPartner, isPartner {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.badge.gearshape.fill")
                            Text("Partner")
                        }
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.success)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundStyle(DesignSystem.Colors.text.tertiary)
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(16)
    }

    private func roleColor(for role: MembershipRole) -> Color {
        switch role {
        case .member: return DesignSystem.Colors.text.secondary
        case .coach: return DesignSystem.Colors.secondary
        case .admin: return DesignSystem.Colors.warning
        case .owner: return DesignSystem.Colors.primary
        }
    }
}

// MARK: - Member Profile View (Placeholder)

private struct MemberProfileView: View {
    let member: GymMember
    let gymId: UUID

    @StateObject private var supabase = SupabaseService.shared
    @State private var relationship: UserRelationship?
    @State private var showSendRequestSheet = false

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(DesignSystem.Colors.primary.opacity(0.2))
                                .frame(width: 100, height: 100)

                            Text(member.initials)
                                .font(.system(size: 40, weight: .bold))
                                .foregroundStyle(DesignSystem.Colors.primary)
                        }

                        Text(member.displayName)
                            .font(DesignSystem.Typography.title2)
                            .foregroundStyle(DesignSystem.Colors.text.primary)

                        HStack(spacing: 8) {
                            Image(systemName: member.role.icon)
                                .font(.system(size: 14))

                            Text(member.role.displayName)
                                .font(DesignSystem.Typography.subheadline)
                        }
                        .foregroundStyle(DesignSystem.Colors.text.secondary)
                    }
                    .padding(.top)

                    // Stats
                    statsSection

                    // Actions
                    if relationship == nil {
                        Button {
                            showSendRequestSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                Text("Send Friend Request")
                            }
                            .font(DesignSystem.Typography.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(DesignSystem.Colors.primary)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadRelationship()
        }
    }

    private var statsSection: some View {
        VStack(spacing: 16) {
            statRow(
                icon: "figure.mixed.cardio",
                label: "Workouts at Gym",
                value: "\(member.totalWorkoutsAtGym)"
            )

            statRow(
                icon: "chart.bar.fill",
                label: "Experience Level",
                value: member.fitnessLevel.displayName
            )

            if let goal = member.primaryGoal {
                statRow(
                    icon: "target",
                    label: "Primary Goal",
                    value: goal
                )
            }
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private func statRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(DesignSystem.Colors.primary)
                .frame(width: 32)

            Text(label)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.text.secondary)

            Spacer()

            Text(value)
                .font(DesignSystem.Typography.bodyEmphasized)
                .foregroundStyle(DesignSystem.Colors.text.primary)
        }
    }

    private func loadRelationship() async {
        do {
            relationship = try await supabase.getRelationship(withUserId: member.userId)
        } catch {
            print("Failed to load relationship: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        GymMembersView(gymId: UUID())
    }
}
