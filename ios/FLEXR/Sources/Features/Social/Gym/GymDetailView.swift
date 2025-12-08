// FLEXR - Gym Detail View
// View gym information and join/leave

import SwiftUI

struct GymDetailView: View {
    let gymId: UUID

    @StateObject private var supabase = SupabaseService.shared
    @State private var gymWithMembership: GymWithMembership?
    @State private var isLoading = true
    @State private var showJoinSheet = false
    @State private var showLeaveAlert = false

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()

            if isLoading {
                loadingView
            } else if let gym = gymWithMembership {
                content(gym: gym)
            } else {
                errorView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadGym()
        }
        .sheet(isPresented: $showJoinSheet) {
            JoinGymSheet(gymId: gymId) {
                await loadGym()
            }
        }
        .alert("Leave Gym", isPresented: $showLeaveAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Leave", role: .destructive) {
                Task { await leaveGym() }
            }
        } message: {
            Text("Are you sure you want to leave this gym? You can rejoin anytime.")
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(gym: GymWithMembership) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                header(gym: gym.gym)

                // Stats
                stats(gym: gym.gym)

                // Actions
                actions(gym: gym)

                // Info sections
                if gym.isMember {
                    NavigationLink(destination: GymMembersView(gymId: gymId)) {
                        actionRow(
                            title: "Members",
                            icon: "person.2.fill",
                            value: "\(gym.gym.memberCount)"
                        )
                    }

                    NavigationLink(destination: GymLeaderboardsView(gymId: gymId)) {
                        actionRow(
                            title: "Leaderboards",
                            icon: "chart.bar.fill",
                            value: nil
                        )
                    }

                    NavigationLink(destination: GymActivityFeedView()) {
                        actionRow(
                            title: "Activity Feed",
                            icon: "chart.line.uptrend.xyaxis",
                            value: nil
                        )
                    }
                }

                // Location
                if !gym.gym.fullAddress.isEmpty {
                    locationSection(gym: gym.gym)
                }

                // Contact
                contactSection(gym: gym.gym)
            }
            .padding()
        }
    }

    // MARK: - Header

    private func header(gym: Gym) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.primary.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: gym.gymType.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(DesignSystem.Colors.primary)
            }

            HStack(spacing: 8) {
                Text(gym.name)
                    .font(DesignSystem.Typography.title2)
                    .foregroundStyle(DesignSystem.Colors.text.primary)

                if gym.isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(DesignSystem.Colors.primary)
                }
            }

            Text(gym.gymType.displayName)
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.text.secondary)

            if let description = gym.description {
                Text(description)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }

    // MARK: - Stats

    private func stats(gym: Gym) -> some View {
        HStack(spacing: 24) {
            statItem(
                value: "\(gym.memberCount)",
                label: "Members",
                icon: "person.2.fill"
            )

            Divider()
                .frame(height: 40)
                .background(DesignSystem.Colors.divider)

            statItem(
                value: "\(gym.activeMemberCount)",
                label: "Active",
                icon: "bolt.fill"
            )

            Divider()
                .frame(height: 40)
                .background(DesignSystem.Colors.divider)

            statItem(
                value: gym.activityLevel.rawValue,
                label: "Activity",
                icon: gym.activityLevel.icon
            )
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(16)
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(DesignSystem.Colors.primary)

            Text(value)
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.text.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    @ViewBuilder
    private func actions(gym: GymWithMembership) -> some View {
        if gym.isMember {
            Button {
                showLeaveAlert = true
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Member")
                }
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.success)
                .frame(maxWidth: .infinity)
                .padding()
                .background(DesignSystem.Colors.success.opacity(0.2))
                .cornerRadius(12)
            }
        } else {
            Button {
                showJoinSheet = true
            } label: {
                HStack {
                    Image(systemName: "person.badge.plus")
                    Text("Join Gym")
                }
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(DesignSystem.Colors.primary)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Sections

    private func actionRow(title: String, icon: String, value: String?) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(DesignSystem.Colors.primary)
                .frame(width: 32)

            Text(title)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            Spacer()

            if let value = value {
                Text(value)
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundStyle(DesignSystem.Colors.text.tertiary)
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(12)
    }

    private func locationSection(gym: Gym) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Location", systemImage: "mappin.circle.fill")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            Text(gym.fullAddress)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.text.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(12)
    }

    private func contactSection(gym: Gym) -> some View {
        VStack(spacing: 12) {
            if let website = gym.websiteUrl {
                Link(destination: URL(string: website)!) {
                    contactRow(icon: "globe", text: "Visit Website")
                }
            }

            if let phone = gym.phoneNumber {
                Link(destination: URL(string: "tel:\(phone)")!) {
                    contactRow(icon: "phone.fill", text: phone)
                }
            }

            if let email = gym.email {
                Link(destination: URL(string: "mailto:\(email)")!) {
                    contactRow(icon: "envelope.fill", text: email)
                }
            }

            if let instagram = gym.instagramHandle {
                Link(destination: URL(string: "https://instagram.com/\(instagram)")!) {
                    contactRow(icon: "camera.fill", text: "@\(instagram)")
                }
            }
        }
    }

    private func contactRow(icon: String, text: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(DesignSystem.Colors.primary)
                .frame(width: 24)

            Text(text)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            Spacer()

            Image(systemName: "arrow.up.right")
                .font(.system(size: 12))
                .foregroundStyle(DesignSystem.Colors.text.tertiary)
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(12)
    }

    // MARK: - Loading & Error

    private var loadingView: some View {
        ProgressView()
            .tint(DesignSystem.Colors.primary)
            .scaleEffect(1.2)
    }

    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(DesignSystem.Colors.text.tertiary)

            Text("Failed to load gym")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            Button("Try Again") {
                Task { await loadGym() }
            }
            .font(DesignSystem.Typography.body)
            .foregroundStyle(DesignSystem.Colors.primary)
        }
    }

    // MARK: - Actions

    private func loadGym() async {
        isLoading = true
        defer { isLoading = false }

        do {
            gymWithMembership = try await supabase.getGym(id: gymId)
        } catch {
            print("Failed to load gym: \(error)")
        }
    }

    private func leaveGym() async {
        do {
            try await supabase.leaveGym(gymId: gymId)
            await loadGym()
        } catch {
            print("Failed to leave gym: \(error)")
        }
    }
}

// MARK: - Join Gym Sheet

private struct JoinGymSheet: View {
    let gymId: UUID
    let onJoin: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabase = SupabaseService.shared
    @State private var privacySettings = GymPrivacySettings.default
    @State private var isJoining = false

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Privacy Settings")
                            .font(DesignSystem.Typography.title3)
                            .foregroundStyle(DesignSystem.Colors.text.primary)

                        VStack(spacing: 16) {
                            Toggle("Show on leaderboard", isOn: $privacySettings.showOnLeaderboard)
                            Toggle("Show in member list", isOn: $privacySettings.showInMemberList)
                            Toggle("Show workout activity", isOn: $privacySettings.showWorkoutActivity)
                            Toggle("Allow workout comparisons", isOn: $privacySettings.allowWorkoutComparisons)
                            Toggle("Show profile to members", isOn: $privacySettings.showProfileToMembers)
                        }
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.text.primary)
                        .tint(DesignSystem.Colors.primary)

                        Button {
                            Task {
                                await joinGym()
                            }
                        } label: {
                            if isJoining {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Join Gym")
                                    .font(DesignSystem.Typography.headline)
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignSystem.Colors.primary)
                        .cornerRadius(12)
                        .disabled(isJoining)
                    }
                    .padding()
                }
            }
            .navigationTitle("Join Gym")
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

    private func joinGym() async {
        isJoining = true
        defer { isJoining = false }

        do {
            _ = try await supabase.joinGym(
                gymId: gymId,
                privacySettings: privacySettings
            )
            await onJoin()
            dismiss()
        } catch {
            print("Failed to join gym: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        GymDetailView(gymId: UUID())
    }
}
