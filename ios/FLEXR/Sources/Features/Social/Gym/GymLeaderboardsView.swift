// FLEXR - Gym Leaderboards View
// Display gym rankings and competition

import SwiftUI

struct GymLeaderboardsView: View {
    let gymId: UUID

    @StateObject private var supabase = SupabaseService.shared
    @State private var leaderboards: [GymLeaderboard] = []
    @State private var selectedPeriod: LeaderboardPeriod = .weekly
    @State private var selectedType: LeaderboardType = .overallDistance
    @State private var isLoading = true
    @State private var currentUserPosition: Int?
    @State private var currentUserId: UUID?

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Filters
                filtersSection

                // Leaderboard
                if isLoading {
                    loadingView
                } else if let leaderboard = currentLeaderboard {
                    leaderboardContent(leaderboard)
                } else {
                    emptyState
                }
            }
        }
        .navigationTitle("Leaderboards")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadLeaderboards()
        }
        .onChange(of: selectedPeriod) { _, _ in
            Task { await loadLeaderboards() }
        }
        .onChange(of: selectedType) { _, _ in
            Task { await loadUserPosition() }
        }
    }

    // MARK: - Filters Section

    private var filtersSection: some View {
        VStack(spacing: 12) {
            // Period selector
            periodSelector

            // Type selector
            typeSelector
        }
        .padding(.vertical, 12)
        .background(DesignSystem.Colors.background)
    }

    private var periodSelector: some View {
        HStack(spacing: 12) {
            ForEach(LeaderboardPeriod.allCases, id: \.self) { period in
                Button {
                    selectedPeriod = period
                } label: {
                    Text(period.displayName)
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(
                            selectedPeriod == period ? .white : DesignSystem.Colors.text.primary
                        )
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            selectedPeriod == period
                                ? DesignSystem.Colors.primary
                                : DesignSystem.Colors.surface
                        )
                        .cornerRadius(20)
                }
            }
        }
        .padding(.horizontal)
    }

    private var typeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LeaderboardType.allCases, id: \.self) { type in
                    TypeChip(
                        type: type,
                        isSelected: selectedType == type
                    ) {
                        selectedType = type
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Current Leaderboard

    private var currentLeaderboard: GymLeaderboard? {
        leaderboards.first { $0.leaderboardType == selectedType && $0.period == selectedPeriod }
    }

    // MARK: - Leaderboard Content

    @ViewBuilder
    private func leaderboardContent(_ leaderboard: GymLeaderboard) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Current user position banner (if not in top 10)
                if let position = currentUserPosition, position > 10 {
                    userPositionBanner(position: position)
                }

                // Rankings
                LazyVStack(spacing: 8) {
                    ForEach(Array(leaderboard.rankings.enumerated()), id: \.offset) { index, entry in
                        rankingRow(entry: entry, position: index + 1)
                    }
                }
            }
            .padding()
        }
    }

    private func userPositionBanner(position: Int) -> some View {
        HStack {
            Image(systemName: "person.fill")
                .foregroundStyle(DesignSystem.Colors.primary)

            Text("Your position: #\(position)")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            Spacer()

            Image(systemName: "arrow.down")
                .foregroundStyle(DesignSystem.Colors.text.tertiary)
        }
        .padding()
        .background(DesignSystem.Colors.primary.opacity(0.2))
        .cornerRadius(12)
    }

    private func rankingRow(entry: LeaderboardEntry, position: Int) -> some View {
        let userId = entry.userId
        let userName = entry.metadata?["user_name"]?.stringValue ?? "Unknown"
        let value = entry.value
        let isCurrentUser = userId == currentUserId

        return HStack(spacing: 16) {
            // Position badge
            positionBadge(position: position)

            // Avatar
            ZStack {
                Circle()
                    .fill(
                        isCurrentUser
                            ? DesignSystem.Colors.primary.opacity(0.3)
                            : DesignSystem.Colors.surface
                    )
                    .frame(width: 44, height: 44)

                Text(userName.prefix(2).uppercased())
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(
                        isCurrentUser
                            ? DesignSystem.Colors.primary
                            : DesignSystem.Colors.text.secondary
                    )
            }

            // User info
            VStack(alignment: .leading, spacing: 2) {
                Text(userName)
                    .font(DesignSystem.Typography.bodyEmphasized)
                    .foregroundStyle(
                        isCurrentUser
                            ? DesignSystem.Colors.primary
                            : DesignSystem.Colors.text.primary
                    )

                Text(selectedType.displayName)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)
            }

            Spacer()

            // Value
            Text(formatValue(value, for: selectedType))
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(
                    isCurrentUser
                        ? DesignSystem.Colors.primary
                        : DesignSystem.Colors.text.primary
                )
        }
        .padding()
        .background(
            isCurrentUser
                ? DesignSystem.Colors.primary.opacity(0.1)
                : DesignSystem.Colors.surface
        )
        .cornerRadius(12)
        .overlay(
            isCurrentUser
                ? RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(DesignSystem.Colors.primary, lineWidth: 2)
                : nil
        )
    }

    private func positionBadge(position: Int) -> some View {
        ZStack {
            Circle()
                .fill(badgeColor(for: position))
                .frame(width: 32, height: 32)

            if position <= 3 {
                Image(systemName: badgeIcon(for: position))
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
            } else {
                Text("\(position)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar")
                .font(.system(size: 64))
                .foregroundStyle(DesignSystem.Colors.text.tertiary)

            Text("No rankings yet")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            Text("Complete workouts to appear on the leaderboard")
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

            Text("Loading leaderboard...")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.text.secondary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    // MARK: - Helper Functions

    private func badgeColor(for position: Int) -> Color {
        switch position {
        case 1: return Color(hex: "FFD700") // Gold
        case 2: return Color(hex: "C0C0C0") // Silver
        case 3: return Color(hex: "CD7F32") // Bronze
        default: return DesignSystem.Colors.text.tertiary
        }
    }

    private func badgeIcon(for position: Int) -> String {
        switch position {
        case 1: return "crown.fill"
        case 2: return "medal.fill"
        case 3: return "medal.fill"
        default: return ""
        }
    }

    private func formatValue(_ value: Double, for type: LeaderboardType) -> String {
        switch type {
        case .overallDistance:
            return String(format: "%.1f km", value / 1000)
        case .overallTime:
            let hours = Int(value) / 3600
            let minutes = (Int(value) % 3600) / 60
            return "\(hours)h \(minutes)m"
        case .overallWorkouts:
            return "\(Int(value))"
        case .consistency:
            return "\(Int(value)) days"
        case .station1kmRun, .stationSkiErg, .stationSledPush, .stationSledPull,
             .stationRowing, .stationWallBalls, .stationBurpeeBroadJump:
            return String(format: "%.1f s", value)
        }
    }

    // MARK: - Actions

    private func loadLeaderboards() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Get current user ID
            if let session = try? await supabase.client.auth.session {
                currentUserId = session.user.id
            }

            leaderboards = try await supabase.getAllGymLeaderboards(
                gymId: gymId,
                period: selectedPeriod
            )
            await loadUserPosition()
        } catch {
            print("Failed to load leaderboards: \(error)")
        }
    }

    private func loadUserPosition() async {
        do {
            currentUserPosition = try await supabase.getUserLeaderboardPosition(
                gymId: gymId,
                leaderboardType: selectedType,
                period: selectedPeriod
            )
        } catch {
            print("Failed to load user position: \(error)")
        }
    }
}

// MARK: - Type Chip Component

private struct TypeChip: View {
    let type: LeaderboardType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: type.icon)
                    .font(.system(size: 20))

                Text(type.shortName)
                    .font(DesignSystem.Typography.caption)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(minWidth: 80)
            .background(
                isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.surface
            )
            .foregroundStyle(
                isSelected ? .white : DesignSystem.Colors.text.primary
            )
            .cornerRadius(12)
        }
    }
}

// MARK: - Helper Extensions

extension LeaderboardType {
    var shortName: String {
        switch self {
        case .overallDistance: return "Distance"
        case .overallTime: return "Time"
        case .overallWorkouts: return "Workouts"
        case .consistency: return "Consistency"
        case .station1kmRun: return "1km Run"
        case .stationSkiErg: return "SkiErg"
        case .stationSledPush: return "Sled Push"
        case .stationSledPull: return "Sled Pull"
        case .stationRowing: return "Rowing"
        case .stationWallBalls: return "Wall Balls"
        case .stationBurpeeBroadJump: return "Burpees"
        }
    }

    var icon: String {
        switch self {
        case .overallDistance: return "figure.run"
        case .overallTime: return "clock.fill"
        case .overallWorkouts: return "number"
        case .consistency: return "calendar.badge.checkmark"
        case .station1kmRun: return "figure.run"
        case .stationSkiErg: return "figure.skiing.downhill"
        case .stationSledPush, .stationSledPull: return "figure.strengthtraining.traditional"
        case .stationRowing: return "figure.rowing"
        case .stationWallBalls: return "basketball.fill"
        case .stationBurpeeBroadJump: return "figure.jumprope"
        }
    }
}

extension AnyCodable {
    var stringValue: String? {
        value as? String
    }

    var doubleValue: Double? {
        if let double = value as? Double {
            return double
        } else if let int = value as? Int {
            return Double(int)
        }
        return nil
    }
}

#Preview {
    NavigationStack {
        GymLeaderboardsView(gymId: UUID())
    }
}
