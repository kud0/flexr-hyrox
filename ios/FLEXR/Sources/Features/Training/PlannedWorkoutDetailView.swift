// FLEXR - Workout Detail View
// Shows complete workout breakdown with all segments

import SwiftUI

struct PlannedWorkoutDetailView: View {
    let workout: PlannedWorkout
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var healthKitService: HealthKitService

    @State private var isStartingWorkout = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    workoutHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 20)

                    // Quick stats
                    quickStatsSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)

                    // AI Explanation
                    if let explanation = workout.aiExplanation {
                        aiExplanationSection(explanation)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                    }

                    // Segments
                    if let segments = workout.segments, !segments.isEmpty {
                        segmentsSection(segments)
                    } else {
                        noSegmentsView
                            .padding(.horizontal, 20)
                    }

                    // Start button
                    if workout.status == .planned {
                        startButtonSection
                            .padding(20)
                    }
                }
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.gray, Color.white.opacity(0.1))
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var workoutHeader: some View {
        FlexrHeader(
            title: workout.name,
            subtitle: workout.description,
            badgeText: workout.workoutType.displayName,
            badgeColor: intensityColor
        )
    }

    // MARK: - Quick Stats

    private var quickStatsSection: some View {
        MetricRow(items: [
            .init(
                value: "\(workout.estimatedDuration) min",
                label: "Duration",
                icon: "clock.fill"
            ),
            .init(
                value: "\(workout.segments?.count ?? 0)",
                label: "Segments",
                icon: "list.bullet"
            ),
            .init(
                value: workout.intensity.displayName,
                label: "Intensity",
                icon: "flame.fill",
                color: intensityColor
            )
        ])
    }

    // MARK: - AI Explanation

    // MARK: - AI Explanation

    private func aiExplanationSection(_ explanation: String) -> some View {
        FlexrCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 17))
                        .foregroundColor(DesignSystem.Colors.primary)
                    Text("Why This Workout")
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.text.primary)
                }

                Text(explanation)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Segments

    private func segmentsSection(_ segments: [PlannedWorkoutSegment]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workout Breakdown")
                .font(DesignSystem.Typography.title2)
                .foregroundColor(DesignSystem.Colors.text.primary)
                .padding(.horizontal, 20)

            // Group by segment type
            let warmup = segments.filter { $0.segmentType == .warmup }
            let main = segments.filter { $0.segmentType == .main }
            let cooldown = segments.filter { $0.segmentType == .cooldown }

            // HYROX-specific segments (run between stations, station work)
            let runs = segments.filter { $0.segmentType == .run }
            let stations = segments.filter { $0.segmentType == .station }

            // Combined workout segments (main + run + station) for display
            let workoutSegments = segments.filter {
                $0.segmentType == .main || $0.segmentType == .run || $0.segmentType == .station
            }.sorted { $0.orderIndex < $1.orderIndex }

            VStack(spacing: 12) {
                if !warmup.isEmpty {
                    SegmentGroupView(title: "Warm-up", segments: warmup, color: Color(hex: "FF9F0A"))
                }

                // Show combined workout if it has run/station segments (HYROX style)
                if !runs.isEmpty || !stations.isEmpty {
                    SegmentGroupView(title: "Workout", segments: workoutSegments, color: DesignSystem.Colors.primary)
                } else if !main.isEmpty {
                    // Fallback to main set for non-HYROX workouts
                    SegmentGroupView(title: "Main Set", segments: main, color: DesignSystem.Colors.primary)
                }

                if !cooldown.isEmpty {
                    SegmentGroupView(title: "Cool-down", segments: cooldown, color: Color(hex: "64D2FF"))
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var noSegmentsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.badge.xmark")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("No detailed segments")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.gray)

            Text("This workout doesn't have detailed instructions yet")
                .font(.system(size: 15))
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Start Button

    // MARK: - Start Button

    private var startButtonSection: some View {
        FlexrButton(
            title: "Start Workout",
            icon: "play.fill",
            style: .primary,
            isLoading: isStartingWorkout,
            action: startWorkout
        )
    }

    // MARK: - Helper Methods

    private func startWorkout() {
        isStartingWorkout = true

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Start HealthKit monitoring
        healthKitService.startLiveHeartRateMonitoring()

        // Convert and start workout via AppState
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isStartingWorkout = false
            if let convertedWorkout = convertToWorkout() {
                dismiss() // Close detail sheet
                appState.beginWorkout(convertedWorkout)
            }
        }
    }

    /// Convert PlannedWorkout to Workout for execution
    private func convertToWorkout() -> Workout? {
        guard let plannedSegments = workout.segments, !plannedSegments.isEmpty else {
            return nil
        }

        // Group segments by type to build sections
        let warmupSegs = plannedSegments.filter { $0.segmentType == .warmup }
        let mainSegs = plannedSegments.filter { $0.segmentType == .main || $0.segmentType == .run || $0.segmentType == .station }
        let cooldownSegs = plannedSegments.filter { $0.segmentType == .cooldown }

        var allWorkoutSegments: [WorkoutSegment] = []
        var sections: [WorkoutSection] = []

        // Helper to convert PlannedWorkoutSegment to WorkoutSegment
        func convert(_ planned: PlannedWorkoutSegment, sectionType: String, sectionLabel: String) -> WorkoutSegment {
            let segmentType: SegmentType
            switch planned.segmentType {
            case .warmup: segmentType = .warmup
            case .main: segmentType = .strength
            case .cooldown: segmentType = .cooldown
            case .rest: segmentType = .rest
            case .transition: segmentType = .transition
            case .run: segmentType = .run
            case .station: segmentType = .station
            }

            return WorkoutSegment(
                workoutId: workout.id,
                segmentType: segmentType,
                stationType: planned.stationType.flatMap { StationType(rawValue: $0) },
                targetDuration: planned.targetDurationSeconds.map { Double($0) },
                targetDistance: planned.targetDistanceMeters.map { Double($0) },
                targetReps: planned.targetReps,
                targetPace: planned.targetPace,
                sets: planned.sets,
                repsPerSet: planned.targetReps,
                weightSuggestion: planned.intensityDescription,
                sectionType: sectionType,
                sectionLabel: sectionLabel
            )
        }

        // Build Warm-up section
        if !warmupSegs.isEmpty {
            let warmupWorkoutSegs = warmupSegs.map { convert($0, sectionType: "warmup", sectionLabel: "WARM-UP") }
            allWorkoutSegments.append(contentsOf: warmupWorkoutSegs)

            sections.append(WorkoutSection(
                type: .warmup,
                label: "WARM-UP",
                format: nil,
                formatDetails: nil,
                segments: warmupWorkoutSegs
            ))
        }

        // Build Main/Strength section
        if !mainSegs.isEmpty {
            let mainWorkoutSegs = mainSegs.map { convert($0, sectionType: "strength", sectionLabel: "STRENGTH") }
            allWorkoutSegments.append(contentsOf: mainWorkoutSegs)

            sections.append(WorkoutSection(
                type: .strength,
                label: "STRENGTH",
                format: nil,
                formatDetails: nil,
                segments: mainWorkoutSegs
            ))
        }

        // Build Cool-down section
        if !cooldownSegs.isEmpty {
            let cooldownWorkoutSegs = cooldownSegs.map { convert($0, sectionType: "cooldown", sectionLabel: "COOL-DOWN") }
            allWorkoutSegments.append(contentsOf: cooldownWorkoutSegs)

            sections.append(WorkoutSection(
                type: .cooldown,
                label: "COOL-DOWN",
                format: nil,
                formatDetails: nil,
                segments: cooldownWorkoutSegs
            ))
        }

        return Workout(
            id: workout.id,
            userId: workout.userId,
            name: workout.name,
            date: workout.scheduledDate,
            type: workout.workoutType,
            status: .inProgress,
            segments: allWorkoutSegments,
            sections: sections,
            totalDuration: Double(workout.estimatedDuration * 60),
            estimatedCalories: nil,
            readinessScore: nil,
            notes: workout.aiExplanation
        )
    }

    private var intensityColor: Color {
        switch workout.intensity {
        case .recovery: return Color(hex: "64D2FF")
        case .easy: return DesignSystem.Colors.primary
        case .moderate: return Color(hex: "FFD60A")
        case .hard: return Color(hex: "FF9F0A")
        case .veryHard, .maxEffort: return Color(hex: "FF453A")
        }
    }
}

// MARK: - Quick Stat Item

// MARK: - Quick Stat Item (Deprecated)
// Replaced by MetricRow

// MARK: - Segment Group View

struct SegmentGroupView: View {
    let title: String
    let segments: [PlannedWorkoutSegment]
    let color: Color

    var body: some View {
        FlexrCard {
            VStack(alignment: .leading, spacing: 12) {
                // Group header
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: 4, height: 20)

                    Text(title.uppercased())
                        .font(DesignSystem.Typography.subheadlineEmphasized)
                        .foregroundColor(color)

                    Spacer()

                    Text("\(segments.count) \(segments.count == 1 ? "exercise" : "exercises")")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }

                // Segments list
                VStack(spacing: 0) {
                    ForEach(Array(segments.sorted(by: { $0.orderIndex < $1.orderIndex }).enumerated()), id: \.element.id) { index, segment in
                        // Using UnifiedSegmentRow logic here but locally adapted or reuse.
                        // Since SegmentRowView is somewhat complex with expansion, we can modify it to use Unified look.
                        SegmentRowView(segment: segment, index: index + 1, accentColor: color)

                        if index < segments.count - 1 {
                            Divider()
                                .background(DesignSystem.Colors.divider)
                                .padding(.leading, 50)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Segment Row View

struct SegmentRowView: View {
    let segment: PlannedWorkoutSegment
    let index: Int
    let accentColor: Color

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            // Main row
            Button {
                withAnimation(DesignSystem.Animation.spring) {
                    isExpanded.toggle()
                }
            } label: {
                UnifiedSegmentRow(
                    index: index,
                    icon: "", // UnifiedRow uses number if no icon
                    title: segment.name,
                    subtitle: segment.primaryTarget,
                    value: nil,
                    color: accentColor
                )
                .overlay(alignment: .trailing) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                        .padding(.trailing, 16)
                }
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                expandedContent
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
            }
        }
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Instructions
            VStack(alignment: .leading, spacing: 6) {
                Text("Instructions")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(accentColor)

                Text(segment.instructions)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(4)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)

            // Secondary info (pace, HR zone, etc.)
            if let secondaryInfo = segment.secondaryInfo {
                HStack(spacing: 8) {
                    Image(systemName: "gauge.with.dots.needle.50percent")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                    Text(secondaryInfo)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
            }

            // Equipment
            if let equipment = segment.equipment {
                HStack(spacing: 8) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                    Text(equipment)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.leading, 48)
    }
}

#Preview {
    let workoutId = UUID()
    return PlannedWorkoutDetailView(workout: PlannedWorkout(
        id: workoutId,
        userId: UUID(),
        scheduledDate: Date(),
        sessionNumber: 1,
        workoutType: .halfSimulation,
        name: "Half HYROX Simulation",
        description: "Practice 4 stations with running between each",
        estimatedDuration: 45,
        intensity: .moderate,
        aiExplanation: "This workout builds race-specific endurance while allowing recovery between efforts.",
        segments: [
            PlannedWorkoutSegment(
                id: UUID(),
                plannedWorkoutId: workoutId,
                orderIndex: 1,
                segmentType: .warmup,
                name: "Easy Jog",
                instructions: "Start with 5 minutes of easy jogging to raise your heart rate. Keep the pace conversational.",
                targetDurationSeconds: 300,
                targetDistanceMeters: nil,
                targetReps: nil,
                targetCalories: nil,
                sets: 1,
                restBetweenSetsSeconds: nil,
                targetPace: "6:00/km",
                targetHeartRateZone: 2,
                intensityDescription: "Easy, conversational",
                equipment: nil,
                stationType: nil
            ),
            PlannedWorkoutSegment(
                id: UUID(),
                plannedWorkoutId: workoutId,
                orderIndex: 2,
                segmentType: .run,
                name: "Run 1",
                instructions: "1km run at race pace. Focus on smooth, efficient stride.",
                targetDurationSeconds: nil,
                targetDistanceMeters: 1000,
                targetReps: nil,
                targetCalories: nil,
                sets: 1,
                restBetweenSetsSeconds: nil,
                targetPace: "5:30/km",
                targetHeartRateZone: 3,
                intensityDescription: "Race pace",
                equipment: nil,
                stationType: nil
            ),
            PlannedWorkoutSegment(
                id: UUID(),
                plannedWorkoutId: workoutId,
                orderIndex: 3,
                segmentType: .station,
                name: "Ski Erg",
                instructions: "1000m ski erg. Maintain steady pace, focus on lat engagement and full range of motion.",
                targetDurationSeconds: nil,
                targetDistanceMeters: 1000,
                targetReps: nil,
                targetCalories: nil,
                sets: 1,
                restBetweenSetsSeconds: nil,
                targetPace: "2:00/500m",
                targetHeartRateZone: 3,
                intensityDescription: "Moderate effort",
                equipment: "Ski Erg",
                stationType: "ski_erg"
            ),
            PlannedWorkoutSegment(
                id: UUID(),
                plannedWorkoutId: workoutId,
                orderIndex: 4,
                segmentType: .run,
                name: "Run 2",
                instructions: "1km run. Focus on recovering while maintaining pace.",
                targetDurationSeconds: nil,
                targetDistanceMeters: 1000,
                targetReps: nil,
                targetCalories: nil,
                sets: 1,
                restBetweenSetsSeconds: nil,
                targetPace: "5:30/km",
                targetHeartRateZone: 3,
                intensityDescription: "Race pace",
                equipment: nil,
                stationType: nil
            ),
            PlannedWorkoutSegment(
                id: UUID(),
                plannedWorkoutId: workoutId,
                orderIndex: 5,
                segmentType: .station,
                name: "Sled Push",
                instructions: "50m sled push. Stay low, drive through your legs, keep arms straight.",
                targetDurationSeconds: nil,
                targetDistanceMeters: 50,
                targetReps: nil,
                targetCalories: nil,
                sets: 1,
                restBetweenSetsSeconds: nil,
                targetPace: nil,
                targetHeartRateZone: 4,
                intensityDescription: "Hard effort",
                equipment: "Sled",
                stationType: "sled_push"
            ),
            PlannedWorkoutSegment(
                id: UUID(),
                plannedWorkoutId: workoutId,
                orderIndex: 6,
                segmentType: .cooldown,
                name: "Easy Walk",
                instructions: "5 minutes easy walk to bring heart rate down. Light stretching.",
                targetDurationSeconds: 300,
                targetDistanceMeters: nil,
                targetReps: nil,
                targetCalories: nil,
                sets: 1,
                restBetweenSetsSeconds: nil,
                targetPace: nil,
                targetHeartRateZone: 1,
                intensityDescription: "Recovery",
                equipment: nil,
                stationType: nil
            )
        ],
        status: .planned
    ))
}
