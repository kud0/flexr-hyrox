// FLEXR - Workout Detail View
// Shows workout details before starting

import SwiftUI

struct WorkoutDetailView: View {
    let workout: Workout
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var healthKitService: HealthKitService
    @Environment(\.dismiss) private var dismiss

    @State private var isStartingWorkout = false

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.large) {
                // Header
                WorkoutHeaderCard(workout: workout)

                // Readiness Score
                if let readiness = workout.readinessScore {
                    ReadinessScoreCard(score: readiness)
                }

                // Segments Overview
                SegmentsOverviewCard(segments: workout.segments)

                // Equipment Needed
                if !requiredEquipment.isEmpty {
                    EquipmentNeededCard(equipment: requiredEquipment)
                }

                // AI Notes
                if let notes = workout.notes, !notes.isEmpty {
                    AINotesCard(notes: notes)
                }
            }
            .padding()
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle(workout.type.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            StartWorkoutButton(
                isLoading: isStartingWorkout,
                action: startWorkout
            )
            .padding()
            .background(DesignSystem.Colors.background)
        }
    }

    private var requiredEquipment: [StationType] {
        workout.segments
            .compactMap { $0.stationType }
            .removingDuplicates()
    }

    private func startWorkout() {
        isStartingWorkout = true

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Start HealthKit monitoring
        healthKitService.startLiveHeartRateMonitoring()

        // Start workout via AppState (persists across navigation)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isStartingWorkout = false
            appState.beginWorkout(workout)
        }
    }
}

// MARK: - Workout Header Card

// MARK: - Workout Header Card

struct WorkoutHeaderCard: View {
    let workout: Workout

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            FlexrHeader(
                title: workout.type.displayName,
                badgeText: workout.status.displayName,
                badgeColor: statusColor
            )

            MetricRow(items: [
                .init(
                    value: formattedDuration,
                    label: "Duration",
                    icon: "clock.fill"
                ),
                .init(
                    value: "\(workout.segments.count)",
                    label: "Segments",
                    icon: "list.bullet"
                ),
                .init(
                    value: "\(workout.estimatedCalories ?? 0)",
                    label: "Calories",
                    icon: "flame.fill",
                    color: .orange
                )
            ])
        }
    }

    private var formattedDuration: String {
        let duration = workout.totalDuration ?? workout.type.estimatedDuration
        let minutes = Int(duration / 60)
        return "\(minutes) min"
    }

    private var statusColor: Color {
        switch workout.status {
        case .planned: return .blue
        case .inProgress: return .green
        case .paused: return .orange
        case .completed: return .purple
        case .cancelled: return .gray
        }
    }
}

// MARK: - Readiness Score Card

struct ReadinessScoreCard: View {
    let score: Int

    var body: some View {
        FlexrCard {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    Text("Readiness Score")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.text.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(score)")
                            .font(DesignSystem.Typography.title1)
                            .foregroundColor(scoreColor)

                        Text("/ 100")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                    }

                    Text(scoreDescription)
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }

                Spacer()

                // Circular Progress
                ZStack {
                    Circle()
                        .stroke(DesignSystem.Colors.surfaceElevated, lineWidth: 8)
                        .frame(width: 60, height: 60)

                    Circle()
                        .trim(from: 0, to: CGFloat(score) / 100)
                        .stroke(
                            LinearGradient(
                                colors: [scoreColor, scoreColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                }
            }
        }
    }

    private var scoreColor: Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }

    private var scoreDescription: String {
        switch score {
        case 80...100: return "Excellent - Ready for high intensity"
        case 60..<80: return "Good - Moderate intensity recommended"
        case 40..<60: return "Fair - Light training suggested"
        default: return "Low - Consider rest or recovery"
        }
    }
}

// MARK: - Segments Overview Card

struct SegmentsOverviewCard: View {
    let segments: [WorkoutSegment]
    @State private var isExpanded = false

    var body: some View {
        FlexrCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                HStack {
                    Text("Workout Segments")
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.text.primary)

                    Spacer()

                    Button {
                        withAnimation(DesignSystem.Animation.spring) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                    }
                }

                // Summary
                HStack(spacing: DesignSystem.Spacing.medium) {
                    SegmentTypeSummary(type: .run, count: runCount)
                    SegmentTypeSummary(type: .station, count: stationCount)
                    if restCount > 0 {
                        SegmentTypeSummary(type: .rest, count: restCount)
                    }
                }

                // Expanded segment list
                if isExpanded {
                    Divider()
                        .background(DesignSystem.Colors.divider)

                    VStack(spacing: DesignSystem.Spacing.small) {
                        ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                            // Simplified row for this view as it uses different segment model
                            HStack(spacing: DesignSystem.Spacing.medium) {
                                Text("\(index + 1)")
                                    .font(DesignSystem.Typography.caption1)
                                    .foregroundColor(DesignSystem.Colors.text.secondary)
                                    .frame(width: 24)

                                Image(systemName: segment.stationType?.icon ?? segment.segmentType.icon)
                                    .foregroundColor(DesignSystem.Colors.primary)
                                    .frame(width: 24)

                                Text(segment.displayName)
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(DesignSystem.Colors.text.primary)
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
    }

    private var runCount: Int {
        segments.filter { $0.segmentType == .run }.count
    }

    private var stationCount: Int {
        segments.filter { $0.segmentType == .station }.count
    }

    private var restCount: Int {
        segments.filter { $0.segmentType == .rest }.count
    }
}

struct SegmentTypeSummary: View {
    let type: SegmentType
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: type.icon)
                .font(.caption)
                .foregroundColor(typeColor)

            Text("\(count)x \(type.displayName)")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.text.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(typeColor.opacity(0.15))
        .cornerRadius(DesignSystem.Radius.small)
    }

    private var typeColor: Color {
        switch type {
        case .run: return .blue
        case .station: return .orange
        case .rest: return .green
        default: return .gray
        }
    }
}



// MARK: - Equipment Needed Card

struct EquipmentNeededCard: View {
    let equipment: [StationType]

    var body: some View {
        FlexrCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                Text("Equipment Needed")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.text.primary)

                FlowLayout(spacing: DesignSystem.Spacing.small) {
                    ForEach(equipment, id: \.self) { station in
                        HStack(spacing: 4) {
                            Image(systemName: station.icon)
                            Text(station.displayName)
                        }
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.text.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(DesignSystem.Colors.surfaceElevated)
                        .cornerRadius(DesignSystem.Radius.small)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.small)
                                .stroke(DesignSystem.Colors.divider, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
}

// MARK: - AI Notes Card

struct AINotesCard: View {
    let notes: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(DesignSystem.Colors.accent)

                Text("AI Coach Notes")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundColor(DesignSystem.Colors.text.primary)
            }

            Text(notes)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.text.secondary)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    DesignSystem.Colors.accent.opacity(0.1),
                    DesignSystem.Colors.surface
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(DesignSystem.Radius.medium)
    }
}

// MARK: - Start Workout Button

// MARK: - Start Workout Button

struct StartWorkoutButton: View {
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        FlexrButton(
            title: "Start Workout",
            icon: "play.fill",
            style: .primary,
            isLoading: isLoading,
            action: action
        )
    }
}

// MARK: - Supporting Views

struct MetricItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.accent)

                Text(value)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.text.primary)
            }

            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.text.secondary)
        }
    }
}

struct StatusBadge: View {
    let status: WorkoutStatus

    var body: some View {
        Text(status.displayName)
            .font(DesignSystem.Typography.caption)
            .foregroundColor(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .cornerRadius(DesignSystem.Radius.small)
    }

    private var statusColor: Color {
        switch status {
        case .planned: return .blue
        case .inProgress: return .green
        case .paused: return .orange
        case .completed: return .purple
        case .cancelled: return .gray
        }
    }
}

// MARK: - Flow Layout



// MARK: - Array Extension

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

#Preview {
    NavigationStack {
        WorkoutDetailView(workout: Workout(
            userId: UUID(),
            date: Date(),
            type: .fullSimulation,
            segments: [
                WorkoutSegment(workoutId: UUID(), segmentType: .warmup, targetDuration: 600),
                WorkoutSegment(workoutId: UUID(), segmentType: .run, targetDistance: 1000),
                WorkoutSegment(workoutId: UUID(), segmentType: .station, stationType: .skiErg, targetDistance: 1000),
                WorkoutSegment(workoutId: UUID(), segmentType: .run, targetDistance: 1000),
                WorkoutSegment(workoutId: UUID(), segmentType: .station, stationType: .sledPush, targetDistance: 50)
            ],
            readinessScore: 85,
            notes: "Focus on maintaining a consistent pace during the runs. Your legs should feel fresh after yesterday's rest day."
        ))
        .environmentObject(AppState())
        .environmentObject(HealthKitService())
    }
}
