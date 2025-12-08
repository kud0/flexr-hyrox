// FLEXR - Friends List View
// Manage friends and race partners

import SwiftUI

struct FriendsListView: View {
    @StateObject private var supabase = SupabaseService.shared
    @State private var friends: [UserRelationship] = []
    @State private var racePartners: [UserRelationship] = []
    @State private var pendingRequests: [RelationshipRequest] = []
    @State private var selectedTab: Tab = .friends
    @State private var isLoading = true
    @State private var showAddFriendSheet = false
    @State private var userHasRacePartner = false

    #if DEBUG
    @State private var useMockData = true
    #else
    @State private var useMockData = false
    #endif

    enum Tab: String, CaseIterable {
        case friends = "Friends"
        case partners = "Partner"
        case requests = "Requests"

        var icon: String {
            switch self {
            case .friends: return "person.2.fill"
            case .partners: return "figure.2"
            case .requests: return "bell.fill"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Tab selector
                    tabSelector

                    // Content based on selected tab
                    if isLoading {
                        loadingView
                    } else {
                        TabView(selection: $selectedTab) {
                            friendsTab
                                .tag(Tab.friends)

                            partnersTab
                                .tag(Tab.partners)

                            requestsTab
                                .tag(Tab.requests)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                    }
                }
            }
            .navigationTitle("Social")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddFriendSheet = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .foregroundStyle(DesignSystem.Colors.primary)
                    }
                }
            }
            .task {
                await loadAll()
            }
            .sheet(isPresented: $showAddFriendSheet) {
                AddFriendSheet {
                    await loadAll()
                }
            }
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    withAnimation {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 16))

                            Text(tab.rawValue)
                                .font(DesignSystem.Typography.subheadline)

                            if tab == .requests && !pendingRequests.isEmpty {
                                ZStack {
                                    Circle()
                                        .fill(DesignSystem.Colors.error)
                                        .frame(width: 18, height: 18)

                                    Text("\(pendingRequests.count)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .foregroundStyle(
                            selectedTab == tab
                                ? DesignSystem.Colors.primary
                                : DesignSystem.Colors.text.secondary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)

                        if selectedTab == tab {
                            Rectangle()
                                .fill(DesignSystem.Colors.primary)
                                .frame(height: 2)
                        } else {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 2)
                        }
                    }
                }
            }
        }
        .background(DesignSystem.Colors.background)
    }

    // MARK: - Friends Tab

    private var friendsTab: some View {
        Group {
            if friends.isEmpty {
                emptyState(
                    icon: "person.2",
                    title: "No friends yet",
                    message: "Add friends to compare workouts and share progress"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(friends) { relationship in
                            NavigationLink {
                                FriendAnalyticsView(friend: relationship)
                            } label: {
                                RelationshipCard(
                                    relationship: relationship,
                                    canUpgradeToPartner: !userHasRacePartner,
                                    onRemove: {
                                        await removeFriend(relationship)
                                    },
                                    onUpgrade: {
                                        await upgradeToPartner(relationship)
                                    }
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
        }
    }

    // MARK: - Partners Tab

    private var partnersTab: some View {
        Group {
            if racePartners.isEmpty {
                emptyState(
                    icon: "person.2.badge.gearshape",
                    title: "No race partner yet",
                    message: "Link with your HYROX doubles partner to see shared analytics and training data"
                )
            } else {
                // Show THE ONE race partner with full analytics
                PartnerAnalyticsView(partner: racePartners.first!)
            }
        }
    }

    // MARK: - Requests Tab

    private var requestsTab: some View {
        Group {
            if pendingRequests.isEmpty {
                emptyState(
                    icon: "bell.slash",
                    title: "No pending requests",
                    message: "Friend requests will appear here"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(pendingRequests) { request in
                            RequestCard(
                                request: request,
                                onAccept: {
                                    await acceptRequest(request)
                                },
                                onReject: {
                                    await rejectRequest(request)
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }

    // MARK: - Empty State

    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(DesignSystem.Colors.text.tertiary)

            Text(title)
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            Text(message)
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.text.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func loadAll() async {
        isLoading = true
        defer { isLoading = false }

        #if DEBUG
        if useMockData {
            // Simulate network delay
            try? await Task.sleep(nanoseconds: 500_000_000)

            // Filter mock data by relationship type
            friends = UserRelationship.mockRelationships.filter { $0.relationshipType == .friend }
            racePartners = UserRelationship.mockRelationships.filter { $0.relationshipType == .racePartner }
            pendingRequests = RelationshipRequest.mockRequests
            userHasRacePartner = !racePartners.isEmpty
            return
        }
        #endif

        async let friendsTask = supabase.getUserRelationships(type: .friend, status: .accepted)
        async let partnersTask = supabase.getUserRelationships(type: .racePartner, status: .accepted)
        async let requestsTask = supabase.getPendingRequests()

        do {
            friends = try await friendsTask
            racePartners = try await partnersTask
            pendingRequests = try await requestsTask
            userHasRacePartner = !racePartners.isEmpty
        } catch {
            print("Failed to load relationships: \(error)")
        }
    }

    private func removeFriend(_ relationship: UserRelationship) async {
        do {
            let otherUserId = relationship.userAId == supabase.client.auth.session.user.id
                ? relationship.userBId
                : relationship.userAId
            try await supabase.removeRelationship(withUserId: otherUserId)
            await loadAll()
        } catch {
            print("Failed to remove friend: \(error)")
        }
    }

    private func upgradeToPartner(_ relationship: UserRelationship) async {
        do {
            let otherUserId = relationship.userAId == supabase.client.auth.session.user.id
                ? relationship.userBId
                : relationship.userAId
            _ = try await supabase.upgradeRelationship(withUserId: otherUserId, to: .racePartner)
            await loadAll()
        } catch {
            print("Failed to upgrade to partner: \(error)")
        }
    }

    private func acceptRequest(_ request: RelationshipRequest) async {
        do {
            _ = try await supabase.acceptRelationshipRequest(requestId: request.id)
            await loadAll()
        } catch {
            print("Failed to accept request: \(error)")
        }
    }

    private func rejectRequest(_ request: RelationshipRequest) async {
        do {
            try await supabase.rejectRelationshipRequest(requestId: request.id)
            await loadAll()
        } catch {
            print("Failed to reject request: \(error)")
        }
    }
}

// MARK: - Relationship Card Component

private struct RelationshipCard: View {
    let relationship: UserRelationship
    var isPartner: Bool = false
    var canUpgradeToPartner: Bool = true
    let onRemove: () async -> Void
    let onUpgrade: (() async -> Void)?

    @State private var showActionSheet = false

    init(
        relationship: UserRelationship,
        isPartner: Bool = false,
        canUpgradeToPartner: Bool = true,
        onRemove: @escaping () async -> Void,
        onUpgrade: (() async -> Void)? = nil
    ) {
        self.relationship = relationship
        self.isPartner = isPartner
        self.canUpgradeToPartner = canUpgradeToPartner
        self.onRemove = onRemove
        self.onUpgrade = onUpgrade
    }

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        isPartner
                            ? DesignSystem.Colors.success.opacity(0.2)
                            : DesignSystem.Colors.primary.opacity(0.2)
                    )
                    .frame(width: 56, height: 56)

                Image(systemName: isPartner ? "person.2.badge.gearshape.fill" : "person.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(isPartner ? DesignSystem.Colors.success : DesignSystem.Colors.primary)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text("Friend") // TODO: Get actual user name
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.text.primary)

                Text(relationship.relationshipType.displayName)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)

                if let gym = relationship.originGymId {
                    Text("Met at gym")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.text.tertiary)
                }
            }

            Spacer()

            Button {
                showActionSheet = true
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundStyle(DesignSystem.Colors.text.tertiary)
                    .padding(8)
            }
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(16)
        .confirmationDialog("Manage Connection", isPresented: $showActionSheet) {
            if !isPartner, canUpgradeToPartner, let upgrade = onUpgrade {
                Button("Upgrade to Race Partner") {
                    Task { await upgrade() }
                }
            }

            Button("Remove", role: .destructive) {
                Task { await onRemove() }
            }

            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Request Card Component

private struct RequestCard: View {
    let request: RelationshipRequest
    let onAccept: () async -> Void
    let onReject: () async -> Void

    @State private var isProcessing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                    Text("Friend Request") // TODO: Get actual user name
                        .font(DesignSystem.Typography.bodyEmphasized)
                        .foregroundStyle(DesignSystem.Colors.text.primary)

                    Text(request.relationshipType.displayName)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.text.secondary)

                    if let message = request.message {
                        Text("\"\(message)\"")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundStyle(DesignSystem.Colors.text.secondary)
                            .italic()
                    }
                }

                Spacer()
            }

            // Actions
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
                        .background(DesignSystem.Colors.surface)
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
                        await onAccept()
                        isProcessing = false
                    }
                } label: {
                    if isProcessing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Accept")
                            .font(DesignSystem.Typography.subheadline)
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(DesignSystem.Colors.primary)
                .cornerRadius(8)
                .disabled(isProcessing)
            }
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(16)
    }
}

// MARK: - Add Friend Sheet

private struct AddFriendSheet: View {
    let onComplete: () async -> Void

    @StateObject private var supabase = SupabaseService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var inviteCode = ""
    @State private var isRedeeming = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 48))
                            .foregroundStyle(DesignSystem.Colors.primary)

                        Text("Add Friend")
                            .font(DesignSystem.Typography.title2)
                            .foregroundStyle(DesignSystem.Colors.text.primary)

                        Text("Enter your friend's invite code")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundStyle(DesignSystem.Colors.text.secondary)
                    }
                    .padding(.top, 40)

                    // Invite code input
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("XXXX-XXXX-XXXX", text: $inviteCode)
                            .font(DesignSystem.Typography.title3)
                            .foregroundStyle(DesignSystem.Colors.text.primary)
                            .textCase(.uppercase)
                            .autocorrectionDisabled()
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(DesignSystem.Colors.surface)
                            .cornerRadius(12)

                        if let error = errorMessage {
                            Text(error)
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.error)
                        }
                    }

                    // Redeem button
                    Button {
                        Task { await redeemCode() }
                    } label: {
                        if isRedeeming {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Add Friend")
                                .font(DesignSystem.Typography.headline)
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        inviteCode.isEmpty
                            ? DesignSystem.Colors.text.tertiary
                            : DesignSystem.Colors.primary
                    )
                    .cornerRadius(12)
                    .disabled(inviteCode.isEmpty || isRedeeming)

                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func redeemCode() async {
        isRedeeming = true
        errorMessage = nil
        defer { isRedeeming = false }

        do {
            _ = try await supabase.redeemInviteCode(code: inviteCode)
            await onComplete()
            dismiss()
        } catch {
            errorMessage = "Invalid or expired code"
            print("Failed to redeem code: \(error)")
        }
    }
}

// MARK: - Friend Analytics View

struct FriendAnalyticsView: View {
    let friend: UserRelationship

    @State private var selectedPeriod: AnalyticsPeriod = .month

    enum AnalyticsPeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case threeMonths = "3M"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Friend Profile Header
                friendHeader

                // Period Selector
                periodSelector

                // Recent Performance
                performanceSection

                // Training Stats
                trainingStatsSection

                // Activity Graph
                activityGraphSection

                // Personal Records
                personalRecordsSection
            }
            .padding()
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle("Friend Stats")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Friend Header

    private var friendHeader: some View {
        HStack(spacing: 16) {
            // Friend Avatar
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.primary.opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: "person.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(DesignSystem.Colors.primary)
            }

            // Friend Info
            VStack(alignment: .leading, spacing: 4) {
                Text("Friend")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)

                Text("Training Buddy")
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.text.primary)

                HStack(spacing: 6) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 12))
                    Text("Advanced")
                        .font(DesignSystem.Typography.caption)
                }
                .foregroundStyle(DesignSystem.Colors.text.tertiary)
            }

            Spacer()

            // Activity Badge
            VStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(DesignSystem.Colors.warning)

                Text("Active")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.warning)
            }
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(16)
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        HStack(spacing: 8) {
            ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation {
                        selectedPeriod = period
                    }
                } label: {
                    Text(period.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(
                            selectedPeriod == period
                                ? .white
                                : DesignSystem.Colors.text.secondary
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedPeriod == period
                                ? DesignSystem.Colors.primary
                                : DesignSystem.Colors.surface
                        )
                        .cornerRadius(8)
                }
            }

            Spacer()
        }
    }

    // MARK: - Performance Section

    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Performance")
                .font(DesignSystem.Typography.heading3)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            HStack(spacing: 12) {
                PerformanceCard(
                    icon: "figure.run",
                    value: "12",
                    label: "Workouts",
                    trend: "+3",
                    color: DesignSystem.Colors.primary
                )

                PerformanceCard(
                    icon: "clock.fill",
                    value: "6.2h",
                    label: "Volume",
                    trend: "+45m",
                    color: DesignSystem.Colors.secondary
                )

                PerformanceCard(
                    icon: "star.fill",
                    value: "3",
                    label: "PRs",
                    trend: "+2",
                    color: DesignSystem.Colors.warning
                )
            }
        }
    }

    // MARK: - Training Stats

    private var trainingStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Training Stats")
                .font(DesignSystem.Typography.heading3)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            VStack(spacing: 8) {
                StatRow(label: "Avg Heart Rate", value: "168 bpm", icon: "heart.fill")
                StatRow(label: "Avg Pace", value: "5:15 /km", icon: "speedometer")
                StatRow(label: "Total Distance", value: "42.5 km", icon: "location.fill")
                StatRow(label: "Calories Burned", value: "3,245 cal", icon: "flame.fill")
            }
            .padding()
            .background(DesignSystem.Colors.surface)
            .cornerRadius(12)
        }
    }

    // MARK: - Activity Graph

    private var activityGraphSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Overview")
                .font(DesignSystem.Typography.heading3)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            // Simple bar chart
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7) { index in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DesignSystem.Colors.primary)
                            .frame(height: CGFloat([60, 80, 95, 70, 110, 85, 90][index]))

                        Text(["M", "T", "W", "T", "F", "S", "S"][index])
                            .font(.system(size: 10))
                            .foregroundStyle(DesignSystem.Colors.text.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 150)
            .padding()
            .background(DesignSystem.Colors.surface)
            .cornerRadius(12)
        }
    }

    // MARK: - Personal Records

    private var personalRecordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Records")
                .font(DesignSystem.Typography.heading3)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            VStack(spacing: 8) {
                PRCard(
                    exercise: "1km Run",
                    time: "3:42",
                    date: "Nov 28",
                    improvement: "New PR!"
                )

                PRCard(
                    exercise: "5km Run",
                    time: "19:15",
                    date: "Nov 25",
                    improvement: "-30s"
                )

                PRCard(
                    exercise: "HYROX Full",
                    time: "1:08:23",
                    date: "Nov 20",
                    improvement: "-2:15"
                )
            }
        }
    }
}

// MARK: - Friend Analytics Supporting Components

private struct PerformanceCard: View {
    let icon: String
    let value: String
    let label: String
    let trend: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(DesignSystem.Colors.text.primary)

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(DesignSystem.Colors.text.secondary)

            HStack(spacing: 2) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 8))
                Text(trend)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(DesignSystem.Colors.success)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(12)
    }
}

private struct StatRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(DesignSystem.Colors.primary)
                .frame(width: 24)

            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(DesignSystem.Colors.text.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DesignSystem.Colors.text.primary)
        }
    }
}

private struct PRCard: View {
    let exercise: String
    let time: String
    let date: String
    let improvement: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.text.primary)

                Text(date)
                    .font(.system(size: 12))
                    .foregroundStyle(DesignSystem.Colors.text.tertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(time)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.primary)

                Text(improvement)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.success)
            }
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(12)
    }
}

// MARK: - Partner Analytics View

struct PartnerAnalyticsView: View {
    let partner: UserRelationship

    @State private var selectedPeriod: Period = .month

    enum Period: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case threeMonths = "3M"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Partner Profile Header
                partnerHeader

                // Period Selector
                periodSelector

                // Side-by-Side Comparison
                comparisonSection

                // Training Volume Graph
                trainingVolumeGraph

                // Recent Workouts
                recentWorkoutsSection

                // Key Metrics Grid
                metricsGrid
            }
            .padding()
        }
        .background(DesignSystem.Colors.background)
    }

    // MARK: - Partner Header

    private var partnerHeader: some View {
        HStack(spacing: 16) {
            // Partner Avatar
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.primary.opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: "person.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(DesignSystem.Colors.primary)
            }

            // Partner Info
            VStack(alignment: .leading, spacing: 4) {
                Text("Race Partner")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)

                Text("Training Partner")
                    .font(DesignSystem.Typography.title3)
                    .foregroundStyle(DesignSystem.Colors.text.primary)

                HStack(spacing: 6) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 12))
                    Text("Advanced")
                        .font(DesignSystem.Typography.caption)
                }
                .foregroundStyle(DesignSystem.Colors.text.tertiary)
            }

            Spacer()

            // Status Badge
            VStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(DesignSystem.Colors.success)

                Text("In Sync")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.success)
            }
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(16)
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        HStack(spacing: 8) {
            ForEach(Period.allCases, id: \.self) { period in
                Button {
                    withAnimation {
                        selectedPeriod = period
                    }
                } label: {
                    Text(period.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(
                            selectedPeriod == period
                                ? .white
                                : DesignSystem.Colors.text.secondary
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedPeriod == period
                                ? DesignSystem.Colors.primary
                                : DesignSystem.Colors.surface
                        )
                        .cornerRadius(8)
                }
            }

            Spacer()
        }
    }

    // MARK: - Comparison Section

    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Training Comparison")
                .font(DesignSystem.Typography.heading3)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            HStack(spacing: 12) {
                // You
                ComparisonCard(
                    title: "You",
                    workouts: 12,
                    volume: "6.2h",
                    isYou: true
                )

                // Partner
                ComparisonCard(
                    title: "Partner",
                    workouts: 14,
                    volume: "7.1h",
                    isYou: false
                )
            }
        }
    }

    // MARK: - Training Volume Graph

    private var trainingVolumeGraph: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Training Volume")
                .font(DesignSystem.Typography.heading3)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            // Simple bar chart placeholder
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<4) { index in
                    VStack(spacing: 4) {
                        VStack(spacing: 2) {
                            // You bar
                            RoundedRectangle(cornerRadius: 4)
                                .fill(DesignSystem.Colors.primary)
                                .frame(height: CGFloat([80, 120, 95, 110][index]))

                            // Partner bar
                            RoundedRectangle(cornerRadius: 4)
                                .fill(DesignSystem.Colors.secondary)
                                .frame(height: CGFloat([90, 110, 100, 130][index]))
                        }

                        Text("W\(index + 1)")
                            .font(.system(size: 10))
                            .foregroundStyle(DesignSystem.Colors.text.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 200)
            .padding()
            .background(DesignSystem.Colors.surface)
            .cornerRadius(12)

            // Legend
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(DesignSystem.Colors.primary)
                        .frame(width: 8, height: 8)
                    Text("You")
                        .font(.system(size: 12))
                        .foregroundStyle(DesignSystem.Colors.text.secondary)
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(DesignSystem.Colors.secondary)
                        .frame(width: 8, height: 8)
                    Text("Partner")
                        .font(.system(size: 12))
                        .foregroundStyle(DesignSystem.Colors.text.secondary)
                }
            }
        }
    }

    // MARK: - Recent Workouts

    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Workouts")
                .font(DesignSystem.Typography.heading3)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            VStack(spacing: 8) {
                ForEach(0..<3) { index in
                    WorkoutComparisonRow(
                        date: "Dec \(5 - index)",
                        yourTime: ["42:15", "38:20", "45:10"][index],
                        partnerTime: ["40:50", "39:15", "43:30"][index]
                    )
                }
            }
        }
    }

    // MARK: - Metrics Grid

    private var metricsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Metrics")
                .font(DesignSystem.Typography.heading3)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    PartnerMetricCard(
                        icon: "flame.fill",
                        label: "Avg HR",
                        yourValue: "165",
                        partnerValue: "172"
                    )

                    PartnerMetricCard(
                        icon: "figure.run",
                        label: "Pace",
                        yourValue: "5:20",
                        partnerValue: "5:10"
                    )
                }

                HStack(spacing: 12) {
                    PartnerMetricCard(
                        icon: "bolt.fill",
                        label: "Power",
                        yourValue: "245W",
                        partnerValue: "260W"
                    )

                    PartnerMetricCard(
                        icon: "star.fill",
                        label: "PRs",
                        yourValue: "8",
                        partnerValue: "12"
                    )
                }
            }
        }
    }
}

// MARK: - Supporting Components

private struct ComparisonCard: View {
    let title: String
    let workouts: Int
    let volume: String
    let isYou: Bool

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DesignSystem.Colors.text.secondary)

            VStack(spacing: 4) {
                Text("\(workouts)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(
                        isYou ? DesignSystem.Colors.primary : DesignSystem.Colors.secondary
                    )

                Text("workouts")
                    .font(.system(size: 12))
                    .foregroundStyle(DesignSystem.Colors.text.tertiary)
            }

            Divider()
                .background(DesignSystem.Colors.divider)

            VStack(spacing: 4) {
                Text(volume)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.text.primary)

                Text("total time")
                    .font(.system(size: 12))
                    .foregroundStyle(DesignSystem.Colors.text.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(12)
    }
}

private struct WorkoutComparisonRow: View {
    let date: String
    let yourTime: String
    let partnerTime: String

    var body: some View {
        HStack {
            Text(date)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(DesignSystem.Colors.text.secondary)
                .frame(width: 60, alignment: .leading)

            Spacer()

            HStack(spacing: 12) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("You")
                        .font(.system(size: 11))
                        .foregroundStyle(DesignSystem.Colors.text.tertiary)
                    Text(yourTime)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.primary)
                }

                Text("vs")
                    .font(.system(size: 12))
                    .foregroundStyle(DesignSystem.Colors.text.tertiary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Partner")
                        .font(.system(size: 11))
                        .foregroundStyle(DesignSystem.Colors.text.tertiary)
                    Text(partnerTime)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.secondary)
                }
            }
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(8)
    }
}

private struct PartnerMetricCard: View {
    let icon: String
    let label: String
    let yourValue: String
    let partnerValue: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(DesignSystem.Colors.primary)

            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(DesignSystem.Colors.text.secondary)

            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text("You:")
                        .font(.system(size: 10))
                        .foregroundStyle(DesignSystem.Colors.text.tertiary)
                    Text(yourValue)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(DesignSystem.Colors.text.primary)
                }

                HStack(spacing: 4) {
                    Text("Partner:")
                        .font(.system(size: 10))
                        .foregroundStyle(DesignSystem.Colors.text.tertiary)
                    Text(partnerValue)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(DesignSystem.Colors.text.primary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(12)
    }
}

#Preview {
    FriendsListView()
}
