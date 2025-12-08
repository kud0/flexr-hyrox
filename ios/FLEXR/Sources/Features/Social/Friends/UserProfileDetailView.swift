// FLEXR - User Profile Detail View
// View friend/partner profile with stats and activity

import SwiftUI

struct UserProfileDetailView: View {
    let userId: UUID
    let relationship: UserRelationship?

    @StateObject private var supabase = SupabaseService.shared
    @State private var userInfo: UserBasicInfo?
    @State private var stats: UserStats?
    @State private var recentActivity: [ActivityFeedItem] = []
    @State private var isLoading = true
    @State private var showRemoveConfirmation = false
    @State private var showUpgradeSheet = false

    #if DEBUG
    @State private var useMockData = true
    #else
    @State private var useMockData = false
    #endif

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()

            if isLoading {
                loadingView
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        profileHeader

                        // Stats Section
                        if let stats = stats {
                            statsSection(stats: stats)
                        }

                        // Race Partner Info
                        if relationship?.relationshipType == .racePartner,
                           let metadata = relationship?.racePartnerMetadata {
                            racePartnerSection(metadata: metadata)
                        }

                        // Recent Activity
                        if !recentActivity.isEmpty {
                            recentActivitySection
                        }

                        // Actions
                        actionsSection
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(userInfo?.displayName ?? "Profile")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadProfile()
        }
        .confirmationDialog("Remove Connection", isPresented: $showRemoveConfirmation) {
            Button("Remove", role: .destructive) {
                // TODO: Remove relationship
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.primary.opacity(0.2))
                    .frame(width: 100, height: 100)

                Text(userInfo?.initials ?? "?")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.primary)
            }

            // Name and Info
            VStack(spacing: 4) {
                Text(userInfo?.displayName ?? "Unknown")
                    .font(DesignSystem.Typography.title2)
                    .foregroundStyle(DesignSystem.Colors.text.primary)

                HStack(spacing: 12) {
                    Label(userInfo?.fitnessLevel.displayName ?? "Beginner", systemImage: "figure.run")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(DesignSystem.Colors.text.secondary)

                    if let goal = userInfo?.primaryGoal {
                        Label(goal.capitalized, systemImage: "target")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundStyle(DesignSystem.Colors.text.secondary)
                    }
                }
            }

            // Relationship Badge
            if let relationship = relationship {
                HStack(spacing: 6) {
                    Image(systemName: relationship.relationshipType.icon)
                        .font(.system(size: 14))

                    Text(relationship.relationshipType.displayName)
                        .font(DesignSystem.Typography.subheadline)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(relationshipColor(relationship.relationshipType))
                .cornerRadius(20)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(16)
    }

    // MARK: - Stats Section

    private func statsSection(stats: UserStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stats")
                .font(DesignSystem.Typography.heading3)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ProfileStatCard(
                    icon: "figure.run",
                    value: "\(stats.totalWorkouts)",
                    label: "Workouts",
                    color: DesignSystem.Colors.primary
                )

                ProfileStatCard(
                    icon: "star.fill",
                    value: "\(stats.personalRecords)",
                    label: "PRs",
                    color: DesignSystem.Colors.warning
                )

                ProfileStatCard(
                    icon: "arrow.up.right",
                    value: stats.bestTimeFormatted,
                    label: "Best Time",
                    color: DesignSystem.Colors.success
                )
            }
        }
    }

    // MARK: - Race Partner Section

    private func racePartnerSection(metadata: RacePartnerMetadata) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Race Partner Info")
                .font(DesignSystem.Typography.heading3)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            VStack(spacing: 12) {
                if let raceName = metadata.raceName {
                    InfoRow(label: "Race", value: raceName)
                }

                if let raceLocation = metadata.raceLocation {
                    InfoRow(label: "Location", value: raceLocation)
                }

                if let raceDate = metadata.raceDate {
                    InfoRow(
                        label: "Date",
                        value: raceDate.formatted(date: .abbreviated, time: .omitted)
                    )

                    if let days = metadata.daysUntilRace, days > 0 {
                        InfoRow(label: "Days Until", value: "\(days) days")
                    }
                }

                if let targetTime = metadata.targetTimeFormatted {
                    InfoRow(label: "Target Time", value: targetTime)
                }
            }
            .padding()
            .background(DesignSystem.Colors.surface)
            .cornerRadius(12)
        }
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(DesignSystem.Typography.heading3)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            ForEach(Array(recentActivity.prefix(5)), id: \.id) { activity in
                HStack(spacing: 12) {
                    Image(systemName: activity.activityType.iconName)
                        .font(.system(size: 16))
                        .foregroundStyle(activityColor(activity.activityType))
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(activity.activityType.displayName)
                            .font(DesignSystem.Typography.bodyEmphasized)
                            .foregroundStyle(DesignSystem.Colors.text.primary)

                        if let description = activity.metadata["description"]?.value as? String {
                            Text(description)
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.text.secondary)
                                .lineLimit(1)
                        }

                        Text(activity.timeAgo)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.text.tertiary)
                    }

                    Spacer()
                }
                .padding()
                .background(DesignSystem.Colors.surface)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 12) {
            if relationship?.relationshipType == .friend {
                Button {
                    showUpgradeSheet = true
                } label: {
                    HStack {
                        Image(systemName: "person.2.badge.gearshape")
                        Text("Upgrade to Race Partner")
                    }
                    .font(DesignSystem.Typography.bodyEmphasized)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignSystem.Colors.primary)
                    .cornerRadius(12)
                }
            }

            Button {
                showRemoveConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "person.fill.xmark")
                    Text("Remove Connection")
                }
                .font(DesignSystem.Typography.bodyEmphasized)
                .foregroundStyle(DesignSystem.Colors.error)
                .frame(maxWidth: .infinity)
                .padding()
                .background(DesignSystem.Colors.surface)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(DesignSystem.Colors.error.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack {
            ProgressView()
                .tint(DesignSystem.Colors.primary)
                .scaleEffect(1.2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helper Functions

    private func relationshipColor(_ type: RelationshipType) -> Color {
        switch type {
        case .friend: return DesignSystem.Colors.primary
        case .racePartner: return DesignSystem.Colors.success
        case .gymMember: return DesignSystem.Colors.secondary
        }
    }

    private func activityColor(_ type: ActivityType) -> Color {
        switch type {
        case .workoutCompleted: return DesignSystem.Colors.success
        case .personalRecord: return DesignSystem.Colors.warning
        case .milestoneReached: return DesignSystem.Colors.primary
        case .achievementUnlocked: return DesignSystem.Colors.secondary
        case .gymJoined: return DesignSystem.Colors.success
        case .friendAdded: return DesignSystem.Colors.info
        case .racePartnerLinked: return DesignSystem.Colors.primary
        }
    }

    private func loadProfile() async {
        isLoading = true
        defer { isLoading = false }

        #if DEBUG
        if useMockData {
            // Simulate network delay
            try? await Task.sleep(nanoseconds: 800_000_000)

            // Mock user info
            userInfo = UserBasicInfo(
                id: userId,
                firstName: "Sarah",
                lastName: "Johnson",
                fitnessLevel: .advanced,
                primaryGoal: "performance"
            )

            // Mock stats
            stats = UserStats(
                totalWorkouts: 127,
                personalRecords: 8,
                bestTimeSeconds: 2843
            )

            // Mock activity
            recentActivity = Array(ActivityFeedItem.mockItems.prefix(5))
            return
        }
        #endif

        // TODO: Load real data from Supabase
    }
}

// MARK: - Supporting Views

private struct ProfileStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)

            Text(value)
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.text.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(12)
    }
}

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.text.secondary)

            Spacer()

            Text(value)
                .font(DesignSystem.Typography.bodyEmphasized)
                .foregroundStyle(DesignSystem.Colors.text.primary)
        }
    }
}

// MARK: - User Stats Model

struct UserStats {
    let totalWorkouts: Int
    let personalRecords: Int
    let bestTimeSeconds: Int

    var bestTimeFormatted: String {
        let hours = bestTimeSeconds / 3600
        let minutes = (bestTimeSeconds % 3600) / 60
        let seconds = bestTimeSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

#Preview {
    NavigationStack {
        UserProfileDetailView(
            userId: UUID(),
            relationship: UserRelationship.mockRelationships.first
        )
    }
}
