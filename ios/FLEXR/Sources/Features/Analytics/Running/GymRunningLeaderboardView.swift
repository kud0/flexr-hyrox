// FLEXR - Gym Running Leaderboard View
// Local gym competition for motivation
// Focus: Performance benchmarking within gym community

import SwiftUI

struct GymRunningLeaderboardView: View {
    let gymId: UUID
    let sessionType: RunningSessionType

    @StateObject private var supabase = SupabaseService.shared
    @EnvironmentObject var appState: AppState

    @State private var leaderboard: [RunningSession] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

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
            } else if leaderboard.isEmpty {
                emptyStateView
            } else {
                leaderboardView
            }
        }
        .navigationTitle("\(sessionType.displayName)")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadLeaderboard()
        }
        .refreshable {
            await loadLeaderboard()
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

    // MARK: - Leaderboard View

    private var leaderboardView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Info header
                infoHeader

                // Leaderboard entries
                ForEach(Array(leaderboard.enumerated()), id: \.element.id) { index, session in
                    LeaderboardRow(
                        rank: index + 1,
                        session: session,
                        sessionType: sessionType,
                        isCurrentUser: session.userId == appState.currentUser?.id
                    )

                    if index < leaderboard.count - 1 {
                        Divider()
                            .padding(.leading, 80)
                    }
                }
            }
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.Radius.large)
            .padding()
        }
    }

    // MARK: - Info Header

    private var infoHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: sessionType.icon)
                    .foregroundStyle(sessionTypeColor)

                Text(distanceRequirement)
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)

                Spacer()

                Text("Top \(leaderboard.count)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.text.tertiary)
            }

            if sessionType == .longRun {
                Text("Ranked by total distance")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.text.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("Ranked by fastest average pace")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.text.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(DesignSystem.Colors.background.opacity(0.5))
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "trophy")
                .font(.system(size: 80))
                .foregroundStyle(DesignSystem.Colors.text.tertiary)

            VStack(spacing: 8) {
                Text("No Times Posted Yet")
                    .font(DesignSystem.Typography.heading2)
                    .foregroundStyle(DesignSystem.Colors.text.primary)

                Text("Be the first at your gym to post a \(sessionType.displayName.lowercased()) time!")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 12) {
                Text(encouragementText)
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

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

            Text("Loading leaderboard...")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.text.secondary)
        }
    }

    // MARK: - Helper Properties

    private var distanceRequirement: String {
        switch sessionType {
        case .timeTrial5k:
            return "5K Time Trials (4.9-5.1km)"
        case .timeTrial10k:
            return "10K Time Trials (9.9-10.1km)"
        case .longRun:
            return "Long Runs"
        default:
            return sessionType.displayName
        }
    }

    private var encouragementText: String {
        switch sessionType {
        case .timeTrial5k:
            return "Post your 5K time and set the bar for your gym community"
        case .timeTrial10k:
            return "Post your 10K time and challenge your training partners"
        case .longRun:
            return "Complete a long run and show your endurance"
        default:
            return "Complete this workout type to appear on the leaderboard"
        }
    }

    private var sessionTypeColor: Color {
        switch sessionType.color {
        case "blue": return DesignSystem.Colors.primary
        case "red": return DesignSystem.Colors.error
        case "orange": return DesignSystem.Colors.warning
        case "purple": return DesignSystem.Colors.accent
        case "green": return DesignSystem.Colors.success
        default: return DesignSystem.Colors.text.secondary
        }
    }

    // MARK: - Actions

    private func loadLeaderboard() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        #if DEBUG
        if useMockData {
            try? await Task.sleep(nanoseconds: 500_000_000)
            leaderboard = RunningSession.mockLeaderboard
            return
        }
        #endif

        do {
            leaderboard = try await supabase.getGymLeaderboard(
                gymId: gymId,
                sessionType: sessionType,
                limit: 100
            )
        } catch {
            errorMessage = "Failed to load leaderboard"
            print("Failed to load leaderboard: \(error)")
        }
    }
}

// MARK: - Leaderboard Row Component

private struct LeaderboardRow: View {
    let rank: Int
    let session: RunningSession
    let sessionType: RunningSessionType
    let isCurrentUser: Bool

    var body: some View {
        NavigationLink {
            RunningSessionDetailView(session: session)
        } label: {
            HStack(spacing: 12) {
                // Rank badge
                ZStack {
                    Circle()
                        .fill(rankColor.opacity(0.2))
                        .frame(width: 48, height: 48)

                    if rank <= 3 {
                        Image(systemName: medalIcon)
                            .font(.system(size: 24))
                            .foregroundStyle(rankColor)
                    } else {
                        Text("\(rank)")
                            .font(DesignSystem.Typography.heading3)
                            .foregroundStyle(DesignSystem.Colors.text.primary)
                    }
                }

                // User info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("User") // TODO: Get actual user name
                            .font(DesignSystem.Typography.bodyEmphasized)
                            .foregroundStyle(DesignSystem.Colors.text.primary)

                        if isCurrentUser {
                            Text("(You)")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.primary)
                        }
                    }

                    Text(session.createdAt, style: .date)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.text.secondary)
                }

                Spacer()

                // Performance metric
                VStack(alignment: .trailing, spacing: 4) {
                    if sessionType == .longRun {
                        // Show distance for long runs
                        Text(session.displayDistance)
                            .font(DesignSystem.Typography.heading3)
                            .foregroundStyle(DesignSystem.Colors.primary)

                        Text(session.displayDuration)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.text.secondary)
                    } else {
                        // Show pace for time trials
                        Text(session.displayPace)
                            .font(DesignSystem.Typography.heading3)
                            .foregroundStyle(DesignSystem.Colors.primary)

                        Text(session.displayDuration)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.text.secondary)
                    }
                }
            }
            .padding()
            .background(
                isCurrentUser
                    ? DesignSystem.Colors.primary.opacity(0.05)
                    : Color.clear
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var rankColor: Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0.0) // Gold
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75) // Silver
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2) // Bronze
        default: return DesignSystem.Colors.text.tertiary
        }
    }

    private var medalIcon: String {
        switch rank {
        case 1: return "medal.fill"
        case 2: return "medal.fill"
        case 3: return "medal.fill"
        default: return ""
        }
    }
}

// MARK: - Mock Data Extension

extension RunningSession {
    static let mockLeaderboard: [RunningSession] = [
        RunningSession(
            id: UUID(),
            userId: UUID(),
            gymId: UUID(),
            sessionType: .timeTrial5k,
            workoutId: nil,
            distanceMeters: 5000,
            durationSeconds: 1200, // 20:00
            elevationGainMeters: 20,
            avgPacePerKm: 240, // 4:00/km
            fastestKmPace: 232,
            slowestKmPace: 248,
            avgHeartRate: 175,
            maxHeartRate: 189,
            heartRateZones: nil,
            splits: nil,
            routeData: nil,
            paceConsistency: 6.2,
            fadeFactor: 1.8,
            createdAt: Date().addingTimeInterval(-86400 * 3),
            startedAt: nil,
            endedAt: nil,
            visibility: .gym,
            notes: nil
        ),
        RunningSession(
            id: UUID(),
            userId: UUID(),
            gymId: UUID(),
            sessionType: .timeTrial5k,
            workoutId: nil,
            distanceMeters: 5000,
            durationSeconds: 1260, // 21:00
            elevationGainMeters: 18,
            avgPacePerKm: 252, // 4:12/km
            fastestKmPace: 245,
            slowestKmPace: 260,
            avgHeartRate: 172,
            maxHeartRate: 185,
            heartRateZones: nil,
            splits: nil,
            routeData: nil,
            paceConsistency: 7.5,
            fadeFactor: 2.1,
            createdAt: Date().addingTimeInterval(-86400 * 5),
            startedAt: nil,
            endedAt: nil,
            visibility: .gym,
            notes: nil
        ),
        RunningSession(
            id: UUID(),
            userId: UUID(),
            gymId: UUID(),
            sessionType: .timeTrial5k,
            workoutId: nil,
            distanceMeters: 5000,
            durationSeconds: 1320, // 22:00
            elevationGainMeters: 25,
            avgPacePerKm: 264, // 4:24/km
            fastestKmPace: 252,
            slowestKmPace: 276,
            avgHeartRate: 168,
            maxHeartRate: 182,
            heartRateZones: nil,
            splits: nil,
            routeData: nil,
            paceConsistency: 8.5,
            fadeFactor: 2.3,
            createdAt: Date().addingTimeInterval(-86400 * 7),
            startedAt: nil,
            endedAt: nil,
            visibility: .gym,
            notes: nil
        )
    ]
}

#Preview {
    NavigationStack {
        GymRunningLeaderboardView(
            gymId: UUID(),
            sessionType: .timeTrial5k
        )
        .environmentObject(AppState())
    }
}
