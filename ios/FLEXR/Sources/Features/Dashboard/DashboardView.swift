// FLEXR - Dashboard View (Apple Fitness+ Style)
// Main home screen with today's overview

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var healthKitService: HealthKitService
    @StateObject private var planService = PlanService.shared

    @State private var showingWorkoutDetail = false
    @State private var selectedPlannedWorkout: PlannedWorkout?
    @State private var showingPlannedWorkoutExecution = false
    @State private var showAIExplanation = false
    @State private var showingQuickWorkoutSheet = false
    @State private var isGeneratingWorkout = false
    @State private var generatedWorkout: Workout?
    @State private var showingGeneratedWorkout = false
    @State private var showingWorkoutExecution = false
    @State private var generationError: String?

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default: return "Good Night"
        }
    }

    private var todayFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date()).uppercased()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                    // Custom Header
                    FlexrHeader(
                        title: greeting,
                        subtitle: todayFormatted
                    )
                    .padding(.horizontal, DesignSystem.Spacing.large)
                    .padding(.top, DesignSystem.Spacing.small)

                    // Activity Rings Summary
                    ActivityRingsSummaryCard(
                        weeklyPlan: planService.weeklyPlan,
                        steps: healthKitService.steps,
                        weeklyTrainingMinutes: healthKitService.weeklyTrainingMinutes,
                        weeklyTrainingSessions: healthKitService.weeklyTrainingSessions
                    )
                    .padding(.horizontal, DesignSystem.Spacing.large)

                    // Today's Workout Card
                    if planService.todaysWorkouts.isEmpty {
                        RestDayCard(onAddWorkout: {
                            showingQuickWorkoutSheet = true
                        })
                        .padding(.horizontal, DesignSystem.Spacing.large)
                    } else {
                        ForEach(planService.todaysWorkouts) { workout in
                            TodayWorkoutCard(
                                workout: workout,
                                showAIExplanation: $showAIExplanation,
                                onStart: {
                                    selectedPlannedWorkout = workout
                                    showingPlannedWorkoutExecution = true
                                },
                                onFeelingDifferent: {
                                    showingQuickWorkoutSheet = true
                                }
                            )
                            .padding(.horizontal, DesignSystem.Spacing.large)
                        }
                    }

                    // Recovery & Load Card
                    RecoveryLoadCard(
                        readinessScore: healthKitService.calculateReadinessScore(),
                        hrv: healthKitService.heartRateVariability,
                        weeklyPlan: planService.weeklyPlan,
                        recentWorkouts: appState.recentWorkouts
                    )
                    .padding(.horizontal, DesignSystem.Spacing.large)

                    // Recent Activity
                    if !appState.recentWorkouts.isEmpty {
                        RecentActivityCard(workouts: Array(appState.recentWorkouts.prefix(5)))
                            .padding(.horizontal, DesignSystem.Spacing.large)
                    }
                }
                .padding(.bottom, 40)
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .refreshable {
                await refreshData()
            }
            .task {
                await loadInitialData()
            }
            .sheet(isPresented: $showingQuickWorkoutSheet) {
                QuickWorkoutSheet { workoutType, followUpData in
                    handleQuickWorkoutSelection(
                        type: workoutType,
                        followUpData: followUpData,
                        scheduledWorkout: planService.todaysWorkouts.first
                    )
                }
            }
            .sheet(isPresented: $showingGeneratedWorkout) {
                if let workout = generatedWorkout {
                    GeneratedWorkoutPreviewSheet(
                        workout: workout,
                        onStart: {
                            showingGeneratedWorkout = false
                            // Start workout via AppState (persists across navigation)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                appState.beginWorkout(workout)
                            }
                        },
                        onSaveToToday: {
                            saveWorkoutToToday(workout)
                        },
                        onRegenerate: {
                            showingGeneratedWorkout = false
                            showingQuickWorkoutSheet = true
                        }
                    )
                    .environmentObject(healthKitService)
                }
            }
            .sheet(isPresented: $showingPlannedWorkoutExecution) {
                if let plannedWorkout = selectedPlannedWorkout {
                    PlannedWorkoutDetailView(workout: plannedWorkout)
                        .environmentObject(healthKitService)
                }
            }
            .overlay {
                if isGeneratingWorkout {
                    GeneratingWorkoutOverlay()
                }
            }
            .alert("Workout Generation Failed", isPresented: .init(
                get: { generationError != nil },
                set: { if !$0 { generationError = nil } }
            )) {
                Button("OK") { generationError = nil }
            } message: {
                Text(generationError ?? "Unknown error")
            }
        }
    }

    private func loadInitialData() async {
        // Load HealthKit data (steps, HRV, training status, etc.)
        await healthKitService.loadBaselineMetrics()

        // Uses cache if available for plan data
        await planService.fetchTodaysWorkouts()
        await planService.fetchWeeklyPlan()
    }

    private func refreshData() async {
        // Force refresh bypasses cache
        await planService.fetchTodaysWorkouts(forceRefresh: true)
        await planService.fetchWeeklyPlan(forceRefresh: true)
        await healthKitService.loadBaselineMetrics()
    }

    /// Handle quick workout selection - calls AI to generate workout
    private func handleQuickWorkoutSelection(
        type: QuickWorkoutType,
        followUpData: Any?,
        scheduledWorkout: PlannedWorkout?
    ) {
        // Map QuickWorkoutType to edge function workout_type
        let workoutType: String
        var focusStations: [String]? = nil
        var targetDuration: Int? = nil
        var strengthFocus: String? = nil

        switch type {
        case .run:
            workoutType = "running"
            if let duration = followUpData as? RunDuration {
                switch duration {
                case .short: targetDuration = 25
                case .medium: targetDuration = 45
                case .long: targetDuration = 70
                }
            }
        case .strength:
            workoutType = "strength"
            targetDuration = 60  // Longer, more comprehensive strength session
            // Map StrengthFocus to string for edge function
            if let focus = followUpData as? StrengthFocus {
                switch focus {
                case .upper: strengthFocus = "upper"
                case .lower: strengthFocus = "lower"
                case .fullBody: strengthFocus = "full_body"
                }
            }
        case .gymClass:
            workoutType = "functional"
            targetDuration = 60  // Full 1-hour class-style workout
        case .stationPractice:
            workoutType = "station_focus"
            if let station = followUpData as? HYROXStation {
                focusStations = [station.rawValue.lowercased().replacingOccurrences(of: " ", with: "_")]
            }
            targetDuration = 30
        case .quickHit:
            workoutType = "station_focus"
            targetDuration = 20
        case .challenge:
            workoutType = "half_simulation"
            targetDuration = 45
        case .recovery:
            workoutType = "recovery"
            targetDuration = 30
        }

        let readinessScore = healthKitService.calculateReadinessScore()

        // Show loading
        isGeneratingWorkout = true

        // Generate workout via edge function
        Task {
            do {
                let workout = try await SupabaseService.shared.generateQuickWorkout(
                    workoutType: workoutType,
                    readinessScore: readinessScore,
                    targetDurationMinutes: targetDuration,
                    focusStations: focusStations,
                    strengthFocus: strengthFocus
                )

                await MainActor.run {
                    isGeneratingWorkout = false
                    generatedWorkout = workout
                    showingGeneratedWorkout = true

                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    isGeneratingWorkout = false
                    generationError = error.localizedDescription
                    print("Failed to generate workout: \(error)")
                }
            }
        }
    }

    /// Save the generated workout to today's plan (as additional session)
    private func saveWorkoutToToday(_ workout: Workout) {
        Task {
            do {
                // Schedule the workout for today
                try await SupabaseService.shared.scheduleWorkoutForToday(workout.id)

                await MainActor.run {
                    // Dismiss the preview sheet
                    showingGeneratedWorkout = false

                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)

                    // Refresh today's workouts to show the new one
                    Task {
                        await planService.fetchTodaysWorkouts()
                    }
                }
            } catch {
                await MainActor.run {
                    generationError = "Failed to save workout: \(error.localizedDescription)"
                    print("Failed to save workout to today: \(error)")
                }
            }
        }
    }

}

// MARK: - Generating Workout Overlay

struct GeneratingWorkoutOverlay: View {
    @State private var dots = ""
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Animated icon
                Image(systemName: "sparkles")
                    .font(.system(size: 50))
                    .foregroundColor(DesignSystem.Colors.primary)
                    .symbolEffect(.pulse)

                VStack(spacing: 8) {
                    Text("Creating Your Workout\(dots)")
                        .font(DesignSystem.Typography.title2)
                        .foregroundColor(.white)

                    Text("AI is designing something just for you")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }
            }
        }
        .onReceive(timer) { _ in
            if dots.count >= 3 {
                dots = ""
            } else {
                dots += "."
            }
        }
    }
}

// MARK: - Generated Workout Preview Sheet

struct GeneratedWorkoutPreviewSheet: View {
    let workout: Workout
    let onStart: () -> Void
    let onSaveToToday: () -> Void
    let onRegenerate: () -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var healthKitService: HealthKitService
    @State private var isSaving = false
    @State private var showSavedConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // AI Generated badge
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(DesignSystem.Colors.primary)
                        Text("AI Generated Workout")
                            .font(DesignSystem.Typography.subheadlineEmphasized)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Workout name
                    Text(workout.type.displayName)
                        .font(DesignSystem.Typography.title1)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    // Quick stats
                    HStack(spacing: 24) {
                        QuickStatItem(
                            icon: "clock.fill",
                            value: formatDuration(workout.totalDuration ?? Double(workout.segments.count * 180)),
                            label: "Duration"
                        )

                        QuickStatItem(
                            icon: "list.bullet",
                            value: "\(workout.segments.count)",
                            label: "Segments"
                        )

                        if let readiness = workout.readinessScore {
                            QuickStatItem(
                                icon: "heart.fill",
                                value: "\(readiness)%",
                                label: "Readiness"
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // Workout breakdown - sections or flat segments
                    if let sections = workout.sections, !sections.isEmpty {
                        // New sections-based display
                        VStack(alignment: .leading, spacing: 16) {
                            Text("WORKOUT BREAKDOWN")
                                .font(DesignSystem.Typography.footnoteEmphasized)
                                .foregroundColor(DesignSystem.Colors.text.secondary)
                                .tracking(0.5)

                            ForEach(sections) { section in
                                SectionPreviewCard(section: section)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                    } else if !workout.segments.isEmpty {
                        // Fallback to flat segment list for older workouts
                        VStack(alignment: .leading, spacing: 12) {
                            Text("WORKOUT BREAKDOWN")
                                .font(DesignSystem.Typography.footnoteEmphasized)
                                .foregroundColor(DesignSystem.Colors.text.secondary)
                                .tracking(0.5)

                            ForEach(Array(workout.segments.enumerated()), id: \.element.id) { index, segment in
                                SegmentPreviewRow(segment: segment, index: index + 1)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                    }

                    // Notes if available
                    if let notes = workout.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 14))
                                Text("AI Coach Notes")
                                    .font(DesignSystem.Typography.subheadlineEmphasized)
                            }
                            .foregroundColor(DesignSystem.Colors.primary)

                            Text(notes)
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.text.secondary)
                                .lineSpacing(4)
                        }
                        .padding(16)
                        .background(DesignSystem.Colors.surface)
                        .cornerRadius(DesignSystem.Radius.medium)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                    }

                    Spacer(minLength: 100)
                }
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.text.secondary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    // Start button
                    FlexrButton(
                        title: "Start Now",
                        icon: "play.fill",
                        style: .primary,
                        action: onStart
                    )

                    // Save to today button
                    Button(action: {
                        isSaving = true
                        onSaveToToday()
                    }) {
                        HStack(spacing: 8) {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.primary))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 16))
                            }
                            Text("Save to Today")
                                .font(DesignSystem.Typography.bodyEmphasized)
                        }
                        .foregroundColor(DesignSystem.Colors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(DesignSystem.Colors.primary.opacity(0.15))
                        .cornerRadius(DesignSystem.Radius.medium)
                    }
                    .disabled(isSaving)

                    // Regenerate button
                    Button(action: onRegenerate) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 14))
                            Text("Try Something Else")
                                .font(DesignSystem.Typography.bodyMedium)
                        }
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                    }
                }
                .padding(20)
                .background(
                    DesignSystem.Colors.background
                        .shadow(color: .black.opacity(0.3), radius: 10, y: -5)
                )
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        return "\(minutes) min"
    }
}

// MARK: - Quick Stat Item

private struct QuickStatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(DesignSystem.Colors.primary)

            Text(value)
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(.white)

            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.text.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Segment Preview Row

private struct SegmentPreviewRow: View {
    let segment: WorkoutSegment
    let index: Int

    var body: some View {
        HStack(spacing: 12) {
            // Index
            Text("\(index)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: 24)

            // Icon
            Image(systemName: segment.segmentType.icon)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 24)

            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(segment.displayName)
                    .font(DesignSystem.Typography.bodyEmphasized)
                    .foregroundColor(.white)

                if !segment.targetDescription.isEmpty {
                    Text(segment.targetDescription)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.small)
    }
}

// MARK: - Section Preview Card

private struct SectionPreviewCard: View {
    let section: WorkoutSection

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: section.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(sectionColor)

                Text(section.displayTitle)
                    .font(DesignSystem.Typography.subheadlineEmphasized)
                    .foregroundColor(.white)

                Spacer()

                // Duration badge
                if section.estimatedDuration > 0 {
                    Text(formatDuration(section.estimatedDuration))
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(DesignSystem.Colors.surface.opacity(0.5))
                        .cornerRadius(4)
                }
            }

            // Format subtitle if available
            if let subtitle = section.displaySubtitle {
                Text(subtitle)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.text.tertiary)
                    .padding(.leading, 22)
            }

            // Segment list within section
            VStack(alignment: .leading, spacing: 6) {
                ForEach(section.segments) { segment in
                    SectionSegmentRow(segment: segment, section: section)
                }
            }
            .padding(.leading, 22)
            .padding(.top, 4)
        }
        .padding(12)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.medium)
    }

    private var sectionColor: Color {
        switch section.type {
        case .warmup: return Color.orange
        case .strength: return DesignSystem.Colors.primary
        case .wod: return Color.green
        case .finisher: return Color.red
        case .cooldown: return Color.cyan
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(minutes) min"
    }
}

// MARK: - Section Segment Row

private struct SectionSegmentRow: View {
    let segment: WorkoutSegment
    let section: WorkoutSection

    var body: some View {
        HStack(spacing: 8) {
            // Bullet or indicator
            Circle()
                .fill(DesignSystem.Colors.text.tertiary)
                .frame(width: 4, height: 4)

            // Exercise name
            Text(segment.displayName)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.text.primary)

            Spacer()

            // Target info based on segment type
            Text(segmentDetail)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.text.secondary)
        }
    }

    private var segmentDetail: String {
        // For strength: show sets x reps
        if let sets = segment.sets, let reps = segment.repsPerSet {
            if let weight = segment.weightSuggestion {
                return "\(sets)×\(reps) @ \(weight)"
            }
            return "\(sets)×\(reps)"
        }

        // For WOD/station: show reps or duration from notes
        if let reps = segment.targetReps {
            return "\(reps) reps"
        }

        // For timed segments
        if let duration = segment.targetDuration {
            let seconds = Int(duration)
            if seconds < 60 {
                return "\(seconds)s"
            }
            return "\(seconds / 60) min"
        }

        // Fallback to notes if available
        if let notes = segment.notes, !notes.isEmpty {
            // Truncate long notes
            let maxLength = 20
            if notes.count > maxLength {
                return String(notes.prefix(maxLength)) + "..."
            }
            return notes
        }

        return ""
    }
}

// MARK: - Activity Rings Summary

struct ActivityRingsSummaryCard: View {
    let weeklyPlan: WeeklyPlan?
    let steps: Int
    let weeklyTrainingMinutes: Int  // From HealthKit - all relevant workouts
    let weeklyTrainingSessions: Int // From HealthKit - all relevant workouts

    private var completedSessions: Int {
        weeklyTrainingSessions
    }

    private var totalSessions: Int {
        weeklyPlan?.totalSessions ?? 4
    }

    private var totalMinutes: Int {
        weeklyTrainingMinutes
    }

    private var weeklyGoalMinutes: Int {
        weeklyPlan?.estimatedTotalMinutes ?? 180
    }

    private var dailyStepGoal: Int {
        10000
    }

    var body: some View {
        FlexrCard {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Weekly Summary")
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.text.primary)

                    Spacer()
                }
                .padding(.bottom, DesignSystem.Spacing.medium)

                // Three Rings
                HStack(spacing: 30) {
                    // Sessions Ring
                    ActivityRing(
                        progress: Double(completedSessions) / Double(max(totalSessions, 1)),
                        color: DesignSystem.Colors.primary,
                        icon: "figure.run",
                        value: "\(completedSessions)",
                        label: "Sessions",
                        goal: "\(totalSessions)"
                    )

                    // Minutes Ring
                    ActivityRing(
                        progress: Double(totalMinutes) / Double(max(weeklyGoalMinutes, 1)),
                        color: DesignSystem.Colors.primary,
                        icon: "clock.fill",
                        value: "\(totalMinutes)",
                        label: "Minutes",
                        goal: "\(weeklyGoalMinutes)"
                    )

                    // Steps Ring
                    ActivityRing(
                        progress: Double(steps) / Double(dailyStepGoal),
                        color: DesignSystem.Colors.success,
                        icon: "figure.walk",
                        value: "\(steps)",
                        label: "Steps",
                        goal: "\(dailyStepGoal)"
                    )
                }
            }
        }
    }
}

struct ActivityRing: View {
    let progress: Double
    let color: Color
    let icon: String
    let value: String
    let label: String
    let goal: String

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    .frame(width: 80, height: 80)

                // Progress ring
                Circle()
                    .trim(from: 0, to: clampedProgress)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                // Icon
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }

            // Value
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            // Label
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Today's Workout Card

struct TodayWorkoutCard: View {
    let workout: PlannedWorkout
    @Binding var showAIExplanation: Bool
    let onStart: () -> Void
    var onFeelingDifferent: (() -> Void)? = nil

    var body: some View {
        FlexrCard {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("Today's Workout")
                        .font(DesignSystem.Typography.subheadlineEmphasized)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    Spacer()
                }
                .padding(.bottom, DesignSystem.Spacing.small)

                // Workout Name
                Text(workout.name)
                    .font(DesignSystem.Typography.title1)
                    .foregroundColor(DesignSystem.Colors.text.primary)
                    .padding(.bottom, DesignSystem.Spacing.medium)

                // Type & Duration Row
                HStack(spacing: 20) {
                    // Type
                    HStack(spacing: 8) {
                        Image(systemName: workout.workoutType.icon)
                            .font(.system(size: 18))
                            .foregroundColor(DesignSystem.Colors.primary)

                        Text(workout.workoutType.displayName)
                            .font(DesignSystem.Typography.bodyEmphasized)
                            .foregroundColor(DesignSystem.Colors.text.primary)
                    }

                    // Separator
                    Circle()
                        .fill(DesignSystem.Colors.text.tertiary)
                        .frame(width: 4, height: 4)

                    // Duration
                    HStack(spacing: 4) {
                        Text("\(workout.estimatedDuration)")
                            .font(DesignSystem.Typography.bodyEmphasized)
                            .foregroundColor(DesignSystem.Colors.text.primary)

                        Text("min")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                    }

                    // Separator
                    Circle()
                        .fill(DesignSystem.Colors.text.tertiary)
                        .frame(width: 4, height: 4)

                    // Intensity
                    HStack(spacing: 6) {
                        Circle()
                            .fill(intensityColor)
                            .frame(width: 8, height: 8)

                        Text(workout.intensity.displayName)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                    }

                    Spacer()
                }
                .padding(.bottom, DesignSystem.Spacing.medium)

                // AI Explanation (if available)
                if let aiExplanation = workout.aiExplanation, !aiExplanation.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Button(action: {
                            withAnimation(DesignSystem.Animation.fast) {
                                showAIExplanation.toggle()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 13))
                                    .foregroundColor(DesignSystem.Colors.primary)

                                Text("AI Coach Insight")
                                    .font(DesignSystem.Typography.subheadlineEmphasized)
                                    .foregroundColor(DesignSystem.Colors.primary)

                                Spacer()

                                Image(systemName: showAIExplanation ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(DesignSystem.Colors.text.secondary)
                            }
                        }

                        if showAIExplanation {
                            Text(aiExplanation)
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.text.secondary)
                                .lineSpacing(4)
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(.bottom, DesignSystem.Spacing.medium)
                }

                // Start Button
                if workout.status == .planned {
                    FlexrButton(
                        title: "Start Workout",
                        icon: "play.fill",
                        style: .action,
                        action: onStart
                    )

                    // "Feeling different?" link
                    if let onFeelingDifferent = onFeelingDifferent {
                        Button(action: onFeelingDifferent) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.triangle.branch")
                                    .font(.system(size: 12))
                                Text("Feeling different?")
                                    .font(DesignSystem.Typography.subheadline)
                            }
                            .foregroundColor(DesignSystem.Colors.text.tertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, DesignSystem.Spacing.small)
                        }
                    }
                } else {
                    // Completed badge
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(DesignSystem.Colors.success)

                        Text("Completed")
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                    }
                    .padding(.vertical, DesignSystem.Spacing.small)
                }
            }
        }
    }

    private var intensityColor: Color {
        switch workout.intensity {
        case .recovery: return Color.gray
        case .easy: return DesignSystem.Colors.primary
        case .moderate: return DesignSystem.Colors.primary
        case .hard: return Color.yellow
        case .veryHard: return Color.orange
        case .maxEffort: return Color.red
        }
    }
}

// MARK: - Rest Day Card

struct RestDayCard: View {
    var onAddWorkout: (() -> Void)? = nil

    var body: some View {
        FlexrCard {
            VStack(spacing: 20) {
                Image(systemName: "bed.double.fill")
                    .font(.system(size: 60))
                    .foregroundColor(DesignSystem.Colors.primary)

                VStack(spacing: 8) {
                    Text("Rest Day")
                        .font(DesignSystem.Typography.title1)
                        .foregroundColor(DesignSystem.Colors.text.primary)

                    Text("Recovery is when adaptation happens")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }

                // Quick workout options for rest day
                if let onAddWorkout = onAddWorkout {
                    VStack(spacing: 12) {
                        Text("But if you're feeling antsy...")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.text.tertiary)

                        FlexrButton(
                            title: "Do Something Light",
                            icon: "plus.circle.fill",
                            style: .secondary,
                            action: onAddWorkout
                        )
                    }
                }
            }
            .padding(.vertical, DesignSystem.Spacing.medium)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Recovery & Load Card

struct RecoveryLoadCard: View {
    let readinessScore: Int
    let hrv: Double?
    let weeklyPlan: WeeklyPlan?
    let recentWorkouts: [Workout]

    private var recoveryPercentage: Int {
        readinessScore
    }

    private var weeklyLoad: String {
        let thisWeekWorkouts = recentWorkouts.filter { workout in
            let calendar = Calendar.current
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
            return workout.date >= startOfWeek
        }.count

        let goal = weeklyPlan?.totalSessions ?? 4

        if thisWeekWorkouts == 0 {
            return "Light"
        } else if thisWeekWorkouts < goal {
            return "Moderate"
        } else if thisWeekWorkouts == goal {
            return "Optimal"
        } else {
            return "High"
        }
    }

    private var hrvText: String {
        if let hrv = hrv {
            return "\(Int(hrv))ms"
        }
        return "—"
    }

    private var hrvStatus: String {
        guard let hrv = hrv else { return "Unknown" }
        switch hrv {
        case 60...: return "Good"
        case 40..<60: return "Normal"
        default: return "Low"
        }
    }

    private var readyForIntensity: String {
        switch readinessScore {
        case 85...100: return "High Intensity"
        case 70..<85: return "Moderate Intensity"
        case 50..<70: return "Light Training"
        default: return "Recovery Only"
        }
    }

    private var recoveryColor: Color {
        switch readinessScore {
        case 80...100: return DesignSystem.Colors.success
        case 60..<80: return Color.yellow
        case 40..<60: return Color.orange
        default: return Color.red
        }
    }

    var body: some View {

        FlexrCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                Text("Training Status")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.text.primary)

                // Recovery
                HStack {
                    Text("Recovery:")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text.secondary)

                    Spacer()

                    HStack(spacing: 6) {
                        Text("\(recoveryPercentage)%")
                            .font(DesignSystem.Typography.bodyEmphasized)
                            .foregroundColor(recoveryColor)

                        if recoveryPercentage >= 80 {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(DesignSystem.Colors.success)
                        }
                    }
                }

                // Weekly Load
                HStack {
                    Text("Weekly Load:")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text.secondary)

                    Spacer()

                    Text(weeklyLoad)
                        .font(DesignSystem.Typography.bodyEmphasized)
                        .foregroundColor(DesignSystem.Colors.text.primary)
                }

                // HRV
                HStack {
                    Text("HRV:")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text.secondary)

                    Spacer()

                    HStack(spacing: 6) {
                        Text(hrvText)
                            .font(DesignSystem.Typography.bodyEmphasized)
                            .foregroundColor(DesignSystem.Colors.text.primary)

                        Text("(\(hrvStatus))")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                    }
                }

                // Divider
                Divider()
                    .background(DesignSystem.Colors.divider)

                // Ready For
                HStack {
                    Text("Ready for:")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text.secondary)

                    Spacer()

                    Text(readyForIntensity)
                        .font(DesignSystem.Typography.bodyEmphasized)
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
        }
    }
}

// MARK: - Recent Activity Card

struct RecentActivityCard: View {
    let workouts: [Workout]

    var body: some View {

        FlexrCard {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("Recent Activity")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.text.primary)
                    .padding(.bottom, DesignSystem.Spacing.medium)

                // Workout rows
                ForEach(Array(workouts.enumerated()), id: \.element.id) { index, workout in
                    RecentWorkoutRow(workout: workout)

                    if index < workouts.count - 1 {
                        Divider()
                            .background(DesignSystem.Colors.divider)
                            .padding(.vertical, 8)
                    }
                }
            }
        }
    }
}

struct RecentWorkoutRow: View {
    let workout: Workout

    var body: some View {
        HStack(spacing: 16) {
            // Type Icon
            Image(systemName: workout.type.icon)
                .font(.system(size: 22))
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: 32)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.type.displayName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)

                Text(formattedDate)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }

            Spacer()

            // Metrics
            VStack(alignment: .trailing, spacing: 4) {
                if let duration = workout.totalDuration {
                    Text(duration.formattedWorkoutTime)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                }

                if let calories = workout.estimatedCalories {
                    Text("\(calories) cal")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var formattedDate: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(workout.date) {
            return "Today"
        } else if calendar.isDateInYesterday(workout.date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: workout.date)
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppState())
        .environmentObject(HealthKitService())
}
