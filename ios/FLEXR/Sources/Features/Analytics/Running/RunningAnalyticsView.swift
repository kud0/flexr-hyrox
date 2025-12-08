// FLEXR - Running Analytics View
// Main hub for running performance data
// Focus: Metrics that matter to HYROX athletes

import SwiftUI

struct RunningAnalyticsView: View {
    @StateObject private var supabase = SupabaseService.shared
    @EnvironmentObject var appState: AppState

    @State private var recentSessions: [RunningSession] = []
    @State private var stats: RunningStats?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                if isLoading {
                    loadingView
                } else if recentSessions.isEmpty {
                    emptyStateView
                } else {
                    contentView
                }
            }
            .navigationTitle("Running Analytics")
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

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Recent runs section
                recentRunsSection

                // Stats summary section
                if let stats = stats {
                    statsSummarySection(stats: stats)
                }

                // Personal records section
                if let stats = stats {
                    personalRecordsSection(stats: stats)
                }

                // Gym leaderboards section
                // Note: primaryGymId needs to be added to User model
                // if let gymId = appState.currentUser?.primaryGymId {
                //     gymLeaderboardsSection(gymId: gymId)
                // } else {
                //     noGymLeaderboardSection
                // }
            }
            .padding()
        }
    }

    // MARK: - Recent Runs Section

    private var recentRunsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Runs")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundStyle(DesignSystem.Colors.text.primary)

                Spacer()

                if recentSessions.count > 5 {
                    NavigationLink("See All") {
                        AllRunningSessionsView()
                    }
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(DesignSystem.Colors.primary)
                }
            }

            if recentSessions.isEmpty {
                emptyRecentRunsCard
            } else {
                ForEach(recentSessions.prefix(5)) { session in
                    NavigationLink {
                        RunningSessionDetailView(session: session)
                    } label: {
                        RunningSessionCard(session: session)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private var emptyRecentRunsCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.run")
                .font(.system(size: 48))
                .foregroundStyle(DesignSystem.Colors.text.tertiary)

            Text("No runs recorded yet")
                .font(DesignSystem.Typography.bodyEmphasized)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            Text("Start tracking your runs to see performance analytics")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.text.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.medium)
    }

    // MARK: - Stats Summary Section

    private func statsSummarySection(stats: RunningStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Month")
                .font(DesignSystem.Typography.heading3)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    icon: "figure.run",
                    value: "\(stats.totalRuns)",
                    label: "Total Runs",
                    color: DesignSystem.Colors.primary
                )

                StatCard(
                    icon: "location.fill",
                    value: stats.displayTotalDistance,
                    label: "Distance",
                    color: DesignSystem.Colors.secondary
                )

                StatCard(
                    icon: "speedometer",
                    value: stats.displayAvgPace,
                    label: "Avg Pace",
                    color: DesignSystem.Colors.accent
                )
            }
        }
    }

    // MARK: - Personal Records Section

    private func personalRecordsSection(stats: RunningStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Records")
                .font(DesignSystem.Typography.heading3)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            VStack(spacing: 8) {
                if let fastest5k = stats.fastest5k {
                    PersonalRecordRow(
                        title: "Fastest 5K",
                        session: fastest5k
                    )
                }

                if let fastest10k = stats.fastest10k {
                    PersonalRecordRow(
                        title: "Fastest 10K",
                        session: fastest10k
                    )
                }

                if let longestRun = stats.longestRun {
                    PersonalRecordRow(
                        title: "Longest Run",
                        session: longestRun
                    )
                }

                if stats.fastest5k == nil && stats.fastest10k == nil && stats.longestRun == nil {
                    Text("Complete time trials to set personal records")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(DesignSystem.Colors.text.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(DesignSystem.Colors.surface)
                        .cornerRadius(DesignSystem.Radius.medium)
                }
            }
        }
    }

    // MARK: - Gym Leaderboards Section

    private func gymLeaderboardsSection(gymId: UUID) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gym Leaderboards")
                .font(DesignSystem.Typography.heading3)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            VStack(spacing: 8) {
                LeaderboardPreviewCard(
                    title: "Fastest 5K",
                    icon: "stopwatch",
                    gymId: gymId,
                    sessionType: .timeTrial5k
                )

                LeaderboardPreviewCard(
                    title: "Fastest 10K",
                    icon: "stopwatch.fill",
                    gymId: gymId,
                    sessionType: .timeTrial10k
                )

                LeaderboardPreviewCard(
                    title: "Long Runs",
                    icon: "figure.run",
                    gymId: gymId,
                    sessionType: .longRun
                )
            }
        }
    }

    private var noGymLeaderboardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gym Leaderboards")
                .font(DesignSystem.Typography.heading3)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            VStack(spacing: 12) {
                Image(systemName: "building.2")
                    .font(.system(size: 48))
                    .foregroundStyle(DesignSystem.Colors.text.tertiary)

                Text("Join a Gym for Leaderboards")
                    .font(DesignSystem.Typography.bodyEmphasized)
                    .foregroundStyle(DesignSystem.Colors.text.primary)

                Text("Compare your running performance with your gym community")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)
                    .multilineTextAlignment(.center)

                NavigationLink {
                    GymSearchView()
                } label: {
                    Text("Find Your Gym")
                        .font(DesignSystem.Typography.bodyEmphasized)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(DesignSystem.Colors.primary)
                        .cornerRadius(DesignSystem.Radius.medium)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.Radius.medium)
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "figure.run.circle")
                .font(.system(size: 80))
                .foregroundStyle(DesignSystem.Colors.primary)

            VStack(spacing: 8) {
                Text("Start Tracking Your Runs")
                    .font(DesignSystem.Typography.heading2)
                    .foregroundStyle(DesignSystem.Colors.text.primary)

                Text("Import your runs from Apple Health or manually add sessions to see detailed performance analytics")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 12) {
                Button {
                    // TODO: Implement HealthKit import
                } label: {
                    HStack {
                        Image(systemName: "heart.fill")
                        Text("Import from Apple Health")
                    }
                    .font(DesignSystem.Typography.bodyEmphasized)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignSystem.Colors.primary)
                    .cornerRadius(DesignSystem.Radius.medium)
                }

                Button {
                    // TODO: Implement manual entry
                } label: {
                    Text("Add Run Manually")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignSystem.Colors.surface)
                        .cornerRadius(DesignSystem.Radius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                                .strokeBorder(DesignSystem.Colors.primary, lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding()
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(DesignSystem.Colors.primary)
                .scaleEffect(1.2)

            Text("Loading running data...")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.text.secondary)
        }
    }

    // MARK: - Actions

    private func loadData() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let sessionsTask = supabase.getRunningSessionsFor(limit: 5)
            async let statsTask = supabase.getRunningStats()

            recentSessions = try await sessionsTask
            stats = try await statsTask
        } catch {
            errorMessage = "Failed to load running data"
            print("Failed to load running data: \(error)")
        }
    }
}

// MARK: - Supporting Components

private struct RunningSessionCard: View {
    let session: RunningSession

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(sessionTypeColor.opacity(0.2))
                    .frame(width: 48, height: 48)

                Image(systemName: session.sessionType.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(sessionTypeColor)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(session.sessionType.displayName)
                    .font(DesignSystem.Typography.bodyEmphasized)
                    .foregroundStyle(DesignSystem.Colors.text.primary)

                HStack(spacing: 12) {
                    Label(session.displayDistance, systemImage: "location.fill")
                    Label(session.displayPace, systemImage: "speedometer")
                }
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.text.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(session.displayDuration)
                    .font(DesignSystem.Typography.bodyEmphasized)
                    .foregroundStyle(DesignSystem.Colors.text.primary)

                Text(session.createdAt, style: .relative)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.text.tertiary)
            }
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.medium)
    }

    private var sessionTypeColor: Color {
        switch session.sessionType.color {
        case "blue": return DesignSystem.Colors.primary
        case "red": return DesignSystem.Colors.error
        case "orange": return DesignSystem.Colors.warning
        case "purple": return DesignSystem.Colors.accent
        case "green": return DesignSystem.Colors.success
        default: return DesignSystem.Colors.text.secondary
        }
    }
}

// Note: StatCard is now in Components/MetricCard.swift and can be used directly

private struct PersonalRecordRow: View {
    let title: String
    let session: RunningSession

    var body: some View {
        NavigationLink {
            RunningSessionDetailView(session: session)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(DesignSystem.Typography.bodyEmphasized)
                        .foregroundStyle(DesignSystem.Colors.text.primary)

                    Text(session.createdAt, style: .date)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.text.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if session.sessionType == .longRun {
                        Text(session.displayDistance)
                            .font(DesignSystem.Typography.heading3)
                            .foregroundStyle(DesignSystem.Colors.primary)
                    } else {
                        Text(session.displayPace)
                            .font(DesignSystem.Typography.heading3)
                            .foregroundStyle(DesignSystem.Colors.primary)
                    }

                    Text(session.displayDuration)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.text.secondary)
                }
            }
            .padding()
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.Radius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct LeaderboardPreviewCard: View {
    let title: String
    let icon: String
    let gymId: UUID
    let sessionType: RunningSessionType

    var body: some View {
        NavigationLink {
            GymRunningLeaderboardView(
                gymId: gymId,
                sessionType: sessionType
            )
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .frame(width: 32)

                Text(title)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.text.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundStyle(DesignSystem.Colors.text.tertiary)
            }
            .padding()
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.Radius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Placeholder Views

struct AllRunningSessionsView: View {
    var body: some View {
        Text("All Running Sessions - Coming Soon")
            .navigationTitle("All Runs")
    }
}

// Note: RunningSessionDetailView is now in its own file: RunningSessionDetailView.swift
// Note: GymRunningLeaderboardView is now in its own file: GymRunningLeaderboardView.swift

#Preview {
    RunningAnalyticsView()
        .environmentObject(AppState())
}
