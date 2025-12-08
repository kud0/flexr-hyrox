// FLEXR - Workout Sharing
// Share workout results with gym community or externally
// Focus: Social engagement and motivation

import SwiftUI

struct WorkoutSharingSheet: View {
    let workout: Workout
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supabase = SupabaseService.shared

    @State private var shareToGym = true
    @State private var shareToPublic = false
    @State private var shareCaption = ""
    @State private var isSharing = false
    @State private var shareError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Workout preview card
                    workoutPreviewCard

                    // Sharing options
                    sharingOptionsSection

                    // Caption input
                    captionSection

                    // Share button
                    shareButton
                }
                .padding()
            }
            .navigationTitle("Share Workout")
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

    // MARK: - Workout Preview

    private var workoutPreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.type.displayName)
                        .font(DesignSystem.Typography.heading3)
                        .foregroundStyle(DesignSystem.Colors.text.primary)

                    Text(formatDate(workout.date))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.text.secondary)
                }

                Spacer()

                if let duration = workout.totalDuration {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formatDuration(duration))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(DesignSystem.Colors.primary)

                        Text("Duration")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.text.secondary)
                    }
                }
            }

            Divider()
                .background(DesignSystem.Colors.divider)

            // Key stats
            HStack(spacing: 20) {
                statItem(
                    icon: "list.bullet",
                    value: "\(workout.segments.count)",
                    label: "Segments"
                )

                statItem(
                    icon: "checkmark.circle.fill",
                    value: "\(Int(workout.completionPercentage * 100))%",
                    label: "Complete"
                )

                if workout.totalDistance > 0 {
                    statItem(
                        icon: "figure.run",
                        value: formatDistance(workout.totalDistance),
                        label: "Distance"
                    )
                }
            }
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.large)
    }

    // MARK: - Sharing Options

    private var sharingOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Share With")
                .font(DesignSystem.Typography.heading3)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            VStack(spacing: 12) {
                sharingOption(
                    title: "Gym Feed",
                    description: "Visible to members of your gym",
                    icon: "person.3.fill",
                    isSelected: $shareToGym
                )

                sharingOption(
                    title: "Public Profile",
                    description: "Visible to everyone on FLEXR",
                    icon: "globe",
                    isSelected: $shareToPublic
                )
            }
        }
    }

    private func sharingOption(
        title: String,
        description: String,
        icon: String,
        isSelected: Binding<Bool>
    ) -> some View {
        Button {
            isSelected.wrappedValue.toggle()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected.wrappedValue ? DesignSystem.Colors.primary : DesignSystem.Colors.text.secondary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.text.primary)

                    Text(description)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.text.secondary)
                }

                Spacer()

                Image(systemName: isSelected.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected.wrappedValue ? DesignSystem.Colors.success : DesignSystem.Colors.text.tertiary)
            }
            .padding()
            .background(
                isSelected.wrappedValue
                    ? DesignSystem.Colors.primary.opacity(0.1)
                    : DesignSystem.Colors.surface
            )
            .cornerRadius(DesignSystem.Radius.medium)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Caption Section

    private var captionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Caption (Optional)")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            TextField("Share your thoughts...", text: $shareCaption, axis: .vertical)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.text.primary)
                .lineLimit(3...6)
                .padding()
                .background(DesignSystem.Colors.surface)
                .cornerRadius(DesignSystem.Radius.medium)
        }
    }

    // MARK: - Share Button

    private var shareButton: some View {
        VStack(spacing: 12) {
            if let error = shareError {
                Text(error)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.error)
            }

            Button {
                Task {
                    await shareWorkout()
                }
            } label: {
                HStack {
                    if isSharing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Workout")
                    }
                }
                .font(DesignSystem.Typography.bodyEmphasized)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canShare ? DesignSystem.Colors.primary : DesignSystem.Colors.text.tertiary)
                .cornerRadius(DesignSystem.Radius.medium)
            }
            .disabled(!canShare || isSharing)
        }
    }

    // MARK: - Helper Views

    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(DesignSystem.Colors.primary)

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(DesignSystem.Colors.text.primary)

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(DesignSystem.Colors.text.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Computed Properties

    private var canShare: Bool {
        shareToGym || shareToPublic
    }

    // MARK: - Actions

    private func shareWorkout() async {
        isSharing = true
        shareError = nil

        do {
            // Determine visibility
            let visibility: String = {
                if shareToPublic { return "public" }
                if shareToGym { return "gym" }
                return "private"
            }()

            // Update workout visibility and notes
            _ = try await supabase.updateWorkout(
                id: workout.id,
                visibility: visibility,
                notes: shareCaption.isEmpty ? nil : shareCaption
            )

            // Create activity feed item
            _ = try await supabase.createActivityFeedItem(workoutId: workout.id)

            // Success - dismiss sheet
            dismiss()
        } catch {
            shareError = "Failed to share: \(error.localizedDescription)"
        }

        isSharing = false
    }

    // MARK: - Formatting Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func formatDistance(_ distance: Double) -> String {
        if distance >= 1000 {
            return String(format: "%.1fkm", distance / 1000)
        }
        return "\(Int(distance))m"
    }
}

// MARK: - Preview

#Preview {
    WorkoutSharingSheet(
        workout: Workout(
            userId: UUID(),
            date: Date(),
            type: .strength,
            segments: []
        )
    )
}
