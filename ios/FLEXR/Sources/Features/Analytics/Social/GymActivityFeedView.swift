// FLEXR - Gym Activity Feed
// Social feed showing recent gym activity, PRs, and achievements
// Focus: Community engagement for HYROX athletes

import SwiftUI

struct GymActivityFeedView: View {
    @StateObject private var supabase = SupabaseService.shared
    @EnvironmentObject private var appState: AppState

    @State private var activities: [GymActivityFeedItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if isLoading {
                        loadingView
                    } else if let error = errorMessage {
                        errorView(message: error)
                    } else if activities.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(activities) { activity in
                            ActivityFeedCard(activity: activity)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Gym Activity")
            .refreshable {
                await loadActivities()
            }
            .task {
                await loadActivities()
            }
        }
    }

    // MARK: - Loading States

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading activity...")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.text.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(DesignSystem.Colors.error)

            Text(message)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.text.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 40))
                .foregroundStyle(DesignSystem.Colors.text.tertiary)

            Text("No activity yet")
                .font(DesignSystem.Typography.heading3)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            Text("Be the first to complete a workout and show up here")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.text.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Data Loading

    private func loadActivities() async {
        isLoading = true
        errorMessage = nil

        // TODO: Get user's gym ID from profile (Schema update needed)
        // Temporary bypass for UI Refactor verification
        let gymId = UUID() // Placeholder UUID
        /*
        guard let gymId = appState.currentUser?.gymId else {
            errorMessage = "No gym associated with your account"
            isLoading = false
            return
        }
        */

        do {
            activities = try await supabase.getGymActivityFeed(gymId: gymId, limit: 50)
            isLoading = false
        } catch {
            errorMessage = "Failed to load activity: \(error.localizedDescription)"
            isLoading = false
        }
    }
}

// MARK: - Activity Feed Card

private struct ActivityFeedCard: View {
    let activity: GymActivityFeedItem

    var body: some View {
        HStack(spacing: 12) {
            // Activity icon
            activityIcon

            // Activity content
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.Colors.text.primary)

                if let description = activity.description {
                    Text(description)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.text.secondary)
                }

                if let metrics = activity.displayMetrics {
                    Text(metrics)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.text.tertiary)
                }

                Text(activity.displayTime)
                    .font(.system(size: 11))
                    .foregroundStyle(DesignSystem.Colors.text.tertiary)
            }

            Spacer()
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.medium)
    }

    private var activityIcon: some View {
        ZStack {
            Circle()
                .fill(activityColor.opacity(0.2))
                .frame(width: 44, height: 44)

            Image(systemName: activity.icon)
                .font(.system(size: 20))
                .foregroundStyle(activityColor)
        }
    }

    private var activityColor: Color {
        switch activity.activityType {
        case .workoutCompleted:
            return DesignSystem.Colors.primary
        case .prAchieved:
            return DesignSystem.Colors.accent
        case .challengeJoined:
            return DesignSystem.Colors.secondary
        case .challengeCompleted:
            return DesignSystem.Colors.success
        case .milestoneReached:
            return DesignSystem.Colors.warning
        }
    }
}

// MARK: - Preview

#Preview {
    GymActivityFeedView()
        .environmentObject(AppState())
}
