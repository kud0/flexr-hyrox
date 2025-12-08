// FLEXR - Gym Activity Feed View
// Display gym activity timeline with kudos and comments

import SwiftUI

struct GymActivityFeedView: View {
    let gymId: UUID

    @StateObject private var supabase = SupabaseService.shared
    @State private var activities: [ActivityFeedItem] = []
    @State private var isLoading = true
    @State private var selectedActivityTypes: Set<ActivityType> = []
    @State private var showFilterSheet = false

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Filter button
                filterBar

                // Activity feed
                if isLoading {
                    loadingView
                } else if activities.isEmpty {
                    emptyState
                } else {
                    activityList
                }
            }
        }
        .navigationTitle("Activity Feed")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadActivities()
        }
        .sheet(isPresented: $showFilterSheet) {
            FilterSheet(
                selectedTypes: $selectedActivityTypes,
                onApply: {
                    Task { await loadActivities() }
                }
            )
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack {
            Text("\(activities.count) activities")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.text.secondary)

            Spacer()

            Button {
                showFilterSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: selectedActivityTypes.isEmpty ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                    Text("Filter")
                }
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.primary)
            }
        }
        .padding()
        .background(DesignSystem.Colors.background)
    }

    // MARK: - Activity List

    private var activityList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(activities) { activity in
                    ActivityCard(activity: activity, gymId: gymId)
                }
            }
            .padding()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 64))
                .foregroundStyle(DesignSystem.Colors.text.tertiary)

            Text("No activity yet")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            Text("Workout activity from gym members will appear here")
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

            Text("Loading activity...")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.text.secondary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    // MARK: - Actions

    private func loadActivities() async {
        isLoading = true
        defer { isLoading = false }

        do {
            activities = try await supabase.getActivityFeed(
                gymId: gymId,
                activityTypes: selectedActivityTypes.isEmpty ? nil : Array(selectedActivityTypes),
                limit: 50
            )
        } catch {
            print("Failed to load activity feed: \(error)")
        }
    }
}

// MARK: - Activity Card Component

private struct ActivityCard: View {
    let activity: ActivityFeedItem
    let gymId: UUID

    @StateObject private var supabase = SupabaseService.shared
    @State private var kudosGiven = false
    @State private var kudosCount: Int
    @State private var commentsCount: Int
    @State private var showComments = false

    init(activity: ActivityFeedItem, gymId: UUID) {
        self.activity = activity
        self.gymId = gymId
        _kudosCount = State(initialValue: activity.kudosCount)
        _commentsCount = State(initialValue: activity.commentCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            header

            // Content
            content

            // Actions
            actions
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(16)
        .sheet(isPresented: $showComments) {
            CommentsSheet(activityId: activity.id)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.primary.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: "person.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(DesignSystem.Colors.primary)
            }

            // User info
            VStack(alignment: .leading, spacing: 2) {
                Text("Member") // TODO: Get actual user name
                    .font(DesignSystem.Typography.bodyEmphasized)
                    .foregroundStyle(DesignSystem.Colors.text.primary)

                Text(activity.createdAt, style: .relative)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)
            }

            Spacer()

            // Activity type icon
            Image(systemName: activity.activityType.icon)
                .font(.system(size: 16))
                .foregroundStyle(activity.activityType.color)
        }
    }

    // MARK: - Content

    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(activity.activityType.displayName)
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            if let description = activity.metadata["description"]?.stringValue {
                Text(description)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)
            }

            // Metadata (if available)
            if !activity.metadata.isEmpty {
                metadataView
            }
        }
    }

    private var metadataView: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(activity.metadata.keys.sorted()), id: \.self) { key in
                if let value = activity.metadata[key] {
                    HStack {
                        Text(formatKey(key))
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.text.tertiary)

                        Spacer()

                        Text(formatValue(value))
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.text.secondary)
                    }
                }
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Actions

    private var actions: some View {
        HStack(spacing: 24) {
            // Kudos button
            Button {
                Task { await toggleKudos() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: kudosGiven ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .font(.system(size: 16))

                    if kudosCount > 0 {
                        Text("\(kudosCount)")
                            .font(DesignSystem.Typography.subheadline)
                    }
                }
                .foregroundStyle(
                    kudosGiven ? DesignSystem.Colors.primary : DesignSystem.Colors.text.secondary
                )
            }

            // Comments button
            Button {
                showComments = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 16))

                    if commentsCount > 0 {
                        Text("\(commentsCount)")
                            .font(DesignSystem.Typography.subheadline)
                    }
                }
                .foregroundStyle(DesignSystem.Colors.text.secondary)
            }

            Spacer()
        }
        .padding(.top, 4)
    }

    // MARK: - Helper Functions

    private func formatKey(_ key: String) -> String {
        key.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private func formatValue(_ value: AnyCodable) -> String {
        if let string = value.value as? String {
            return string
        } else if let number = value.value as? Double {
            return String(format: "%.1f", number)
        } else if let int = value.value as? Int {
            return "\(int)"
        }
        return "\(value.value)"
    }

    private func toggleKudos() async {
        do {
            if kudosGiven {
                try await supabase.removeKudos(activityId: activity.id)
                kudosGiven = false
                kudosCount -= 1
            } else {
                _ = try await supabase.giveKudos(activityId: activity.id, kudosType: .fire)
                kudosGiven = true
                kudosCount += 1
            }
        } catch {
            print("Failed to toggle kudos: \(error)")
        }
    }
}

// MARK: - Filter Sheet

private struct FilterSheet: View {
    @Binding var selectedTypes: Set<ActivityType>
    let onApply: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Activity Types")
                            .font(DesignSystem.Typography.title3)
                            .foregroundStyle(DesignSystem.Colors.text.primary)

                        ForEach(ActivityType.allCases, id: \.self) { type in
                            Toggle(isOn: Binding(
                                get: { selectedTypes.contains(type) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedTypes.insert(type)
                                    } else {
                                        selectedTypes.remove(type)
                                    }
                                }
                            )) {
                                HStack {
                                    Image(systemName: type.icon)
                                        .foregroundStyle(type.color)
                                        .frame(width: 24)

                                    Text(type.displayName)
                                        .font(DesignSystem.Typography.body)
                                }
                            }
                            .tint(DesignSystem.Colors.primary)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Filter Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear") {
                        selectedTypes.removeAll()
                    }
                    .foregroundStyle(DesignSystem.Colors.text.secondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply()
                        dismiss()
                    }
                    .foregroundStyle(DesignSystem.Colors.primary)
                }
            }
        }
    }
}

// MARK: - Comments Sheet

private struct CommentsSheet: View {
    let activityId: UUID

    @StateObject private var supabase = SupabaseService.shared
    @State private var comments: [ActivityComment] = []
    @State private var newComment = ""
    @State private var isLoading = true
    @State private var isSending = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Comments list
                    if isLoading {
                        ProgressView()
                            .tint(DesignSystem.Colors.primary)
                    } else if comments.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "bubble.right")
                                .font(.system(size: 48))
                                .foregroundStyle(DesignSystem.Colors.text.tertiary)

                            Text("No comments yet")
                                .font(DesignSystem.Typography.headline)
                                .foregroundStyle(DesignSystem.Colors.text.primary)

                            Text("Be the first to comment")
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundStyle(DesignSystem.Colors.text.secondary)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 16) {
                                ForEach(comments) { comment in
                                    CommentRow(comment: comment)
                                }
                            }
                            .padding()
                        }
                    }

                    // Comment input
                    Divider()
                        .background(DesignSystem.Colors.divider)

                    HStack(spacing: 12) {
                        TextField("Add a comment...", text: $newComment, axis: .vertical)
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.text.primary)
                            .lineLimit(1...4)

                        Button {
                            Task { await sendComment() }
                        } label: {
                            if isSending {
                                ProgressView()
                                    .tint(DesignSystem.Colors.primary)
                            } else {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(
                                        newComment.isEmpty
                                            ? DesignSystem.Colors.text.tertiary
                                            : DesignSystem.Colors.primary
                                    )
                            }
                        }
                        .disabled(newComment.isEmpty || isSending)
                    }
                    .padding()
                    .background(DesignSystem.Colors.surface)
                }
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadComments()
            }
        }
    }

    private func loadComments() async {
        isLoading = true
        defer { isLoading = false }

        do {
            comments = try await supabase.getActivityComments(activityId: activityId)
        } catch {
            print("Failed to load comments: \(error)")
        }
    }

    private func sendComment() async {
        guard !newComment.isEmpty else { return }

        isSending = true
        defer { isSending = false }

        do {
            let comment = try await supabase.addComment(
                activityId: activityId,
                content: newComment
            )
            comments.append(comment)
            newComment = ""
        } catch {
            print("Failed to send comment: \(error)")
        }
    }
}

private struct CommentRow: View {
    let comment: ActivityComment

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.primary.opacity(0.2))
                    .frame(width: 32, height: 32)

                Image(systemName: "person.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(DesignSystem.Colors.primary)
            }

            // Comment content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Member") // TODO: Get actual user name
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(DesignSystem.Colors.text.primary)

                    Text(comment.createdAt, style: .relative)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.text.tertiary)
                }

                Text(comment.commentText)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)
            }
        }
    }
}

// MARK: - Activity Type Extension

extension ActivityType {
    var color: Color {
        switch self {
        case .workoutCompleted: return DesignSystem.Colors.success
        case .personalRecord: return DesignSystem.Colors.warning
        case .milestoneReached: return DesignSystem.Colors.primary
        case .achievementUnlocked: return DesignSystem.Colors.secondary
        case .gymJoined: return DesignSystem.Colors.success
        case .friendAdded: return DesignSystem.Colors.info
        case .racePartnerLinked: return DesignSystem.Colors.primary
        }
    }

    var icon: String {
        switch self {
        case .workoutCompleted: return "checkmark.circle.fill"
        case .personalRecord: return "star.fill"
        case .milestoneReached: return "flag.fill"
        case .achievementUnlocked: return "trophy.fill"
        case .gymJoined: return "person.badge.plus"
        case .friendAdded: return "person.2.fill"
        case .racePartnerLinked: return "figure.2"
        }
    }
}

#Preview {
    NavigationStack {
        GymActivityFeedView(gymId: UUID())
    }
}
