// FLEXR - Weekly Plan View
// Apple Fitness+ Style Design

import SwiftUI

struct WeeklyPlanView: View {
    @StateObject private var planService = PlanService.shared
    @State private var isRefreshing = false
    @State private var showFullCycle = false
    @State private var selectedWeek: Int? = nil  // Start nil, will be set from service
    @State private var showRegenerateConfirm = false
    @State private var isRegenerating = false
    @State private var isInitialLoading = true

    // Computed property for safe selected week
    private var effectiveSelectedWeek: Int {
        selectedWeek ?? planService.currentTrainingWeek
    }

    private var weekRangeFormatted: String {
        let calendar = Calendar.current
        let today = Date()
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: weekStart)) - \(formatter.string(from: weekEnd))".uppercased()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                    // Custom Header with Week Selector
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                        FlexrHeader(
                            title: "Training Plan",
                            subtitle: weekRangeFormatted
                        )

                        // Week Selector Pills - All generated weeks (past, current, next)
                        // Pills accumulate over time as each Sunday adds the next week
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                let weeksToShow = planService.displayableWeeks.isEmpty ? [planService.currentTrainingWeek] : planService.displayableWeeks
                                let currentWeek = planService.currentTrainingWeek
                                ForEach(weeksToShow, id: \.self) { week in
                                    WeekPill(
                                        weekNumber: week,
                                        isSelected: effectiveSelectedWeek == week,
                                        isCurrentWeek: week == currentWeek,
                                        action: {
                                            withAnimation(DesignSystem.Animation.spring) {
                                                selectedWeek = week
                                            }
                                            Task {
                                                await planService.fetchWeeklyPlan(weekNumber: week)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.large)
                    .padding(.top, DesignSystem.Spacing.small)

                    if isInitialLoading && planService.allWeeks.isEmpty {
                        // Show loading while fetching initial data
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(DesignSystem.Colors.primary)
                            Text("Loading your plan...")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.text.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else if planService.isGeneratingPlan {
                        GeneratingPlanView()
                            .padding(.top, 40)
                    } else if let weeklyPlan = planService.weeklyPlan {
                        // Plan Reasoning Teaser (if available)
                        if let reasoning = planService.planReasoning {
                            PlanReasoningTeaser(
                                reasoning: reasoning,
                                showFullCycle: $showFullCycle
                            )
                            .padding(.horizontal, DesignSystem.Spacing.medium)
                        }

                        // Week Overview Card (Progress Card)
                        WeekOverviewCard(plan: weeklyPlan)
                            .padding(.horizontal, DesignSystem.Spacing.medium)

                        // Day-by-Day List
                        VStack(spacing: 32) {
                            ForEach(weeklyPlan.days) { day in
                                DayCard(day: day)
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.medium)
                        .padding(.bottom, DesignSystem.Spacing.large)
                    } else {
                        EmptyPlanView()
                            .padding(.top, 20)
                    }
                }
            }
            .background(Color.black)
            .navigationBarHidden(true)
            .gesture(
                DragGesture(minimumDistance: 50)
                    .onEnded { value in
                        let weeksToShow = planService.displayableWeeks.isEmpty ? [planService.currentTrainingWeek] : planService.displayableWeeks
                        guard let currentIndex = weeksToShow.firstIndex(of: effectiveSelectedWeek) else { return }

                        if value.translation.width < -50 {
                            // Swipe left - go to next week
                            let nextIndex = currentIndex + 1
                            if nextIndex < weeksToShow.count {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedWeek = weeksToShow[nextIndex]
                                }
                                Task {
                                    await planService.fetchWeeklyPlan(weekNumber: weeksToShow[nextIndex])
                                }
                            }
                        } else if value.translation.width > 50 {
                            // Swipe right - go to previous week
                            let prevIndex = currentIndex - 1
                            if prevIndex >= 0 {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedWeek = weeksToShow[prevIndex]
                                }
                                Task {
                                    await planService.fetchWeeklyPlan(weekNumber: weeksToShow[prevIndex])
                                }
                            }
                        }
                    }
            )
            .refreshable {
                await refreshPlan()
            }
            .onAppear {
                Task {
                    await loadPlan()
                }
            }
            .sheet(isPresented: $showFullCycle) {
                TrainingCycleView()
            }
            .alert("Regenerate Week \(selectedWeek)?", isPresented: $showRegenerateConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Regenerate", role: .destructive) {
                    Task {
                        await regenerateSelectedWeek()
                    }
                }
            } message: {
                Text("This will create new workouts for Week \(selectedWeek). Your current workouts for this week will be replaced.")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showRegenerateConfirm = true
                        } label: {
                            Label("Regenerate Week \(selectedWeek)", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
            }
            .overlay {
                if isRegenerating {
                    ZStack {
                        Color.black.opacity(0.6).ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(DesignSystem.Colors.primary)
                            Text("Regenerating Week \(effectiveSelectedWeek)...")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(.white)
                        }
                        .padding(32)
                        .background(DesignSystem.Colors.surface)
                        .cornerRadius(16)
                    }
                }
            }
        }
    }

    private func regenerateSelectedWeek() async {
        isRegenerating = true
        defer { isRegenerating = false }

        do {
            // Delete existing workouts for this week and regenerate
            try await planService.forceRegenerateWeek(weekNumber: effectiveSelectedWeek)
            // Refresh the view
            await planService.fetchWeeklyPlan(weekNumber: effectiveSelectedWeek, forceRefresh: true)
            await planService.fetchFullTrainingCycle()
        } catch {
            print("Failed to regenerate week: \(error)")
        }
    }

    private func loadPlan() async {
        isInitialLoading = true
        defer { isInitialLoading = false }

        // First fetch the full training cycle to get available weeks
        await planService.fetchFullTrainingCycle()

        // Debug logging
        print("WeeklyPlanView: allWeeks count = \(planService.allWeeks.count)")
        print("WeeklyPlanView: availableDetailedWeeks = \(planService.availableDetailedWeeks)")
        print("WeeklyPlanView: currentTrainingWeek = \(planService.currentTrainingWeek)")
        print("WeeklyPlanView: selectedWeek BEFORE = \(String(describing: selectedWeek))")
        for week in planService.allWeeks.prefix(5) {
            print("  Week \(week.weekNumber): isCurrentWeek=\(week.isCurrentWeek), totalWorkouts=\(week.totalWorkouts), startDate=\(week.startDate)")
        }

        // Set to current training week if not already set
        if selectedWeek == nil {
            let currentWeek = planService.currentTrainingWeek
            print("WeeklyPlanView: Setting selectedWeek to \(currentWeek)")
            selectedWeek = currentWeek
        }

        // Fetch workouts for the selected week
        await planService.fetchWeeklyPlan(weekNumber: effectiveSelectedWeek)
    }

    private func refreshPlan() async {
        isRefreshing = true
        await planService.fetchWeeklyPlan(weekNumber: effectiveSelectedWeek)
        await planService.fetchFullTrainingCycle()
        isRefreshing = false
    }
}

// MARK: - Week Overview Card (Progress Card)

struct WeekOverviewCard: View {
    let plan: WeeklyPlan

    private var progress: Double {
        guard plan.totalSessions > 0 else { return 0 }
        return Double(plan.completedSessions) / Double(plan.totalSessions)
    }

    var body: some View {
        FlexrCard {
            HStack(alignment: .top, spacing: 20) {
                // Left: Phase info
                VStack(alignment: .leading, spacing: 12) {
                    Text("CURRENT PHASE")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                        .tracking(0.5)

                    // Phase badge with pulsing dot
                    HStack(spacing: 6) {
                        Circle()
                            .fill(DesignSystem.Colors.primary)
                            .frame(width: 8, height: 8)
                            .shadow(color: DesignSystem.Colors.primary, radius: 4)

                        Text(plan.phase.displayName.uppercased())
                            .font(DesignSystem.Typography.subheadlineEmphasized)
                            .foregroundColor(DesignSystem.Colors.primary)
                            .tracking(0.5)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(DesignSystem.Colors.primary.opacity(0.1))
                    .cornerRadius(8)

                    // Phase description
                    Text(plan.focus)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()

                // Right: Progress ring
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(DesignSystem.Colors.text.tertiary, lineWidth: 6)
                        .frame(width: 80, height: 80)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(DesignSystem.Colors.primary, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(DesignSystem.Animation.spring, value: progress)

                    // Center text
                    VStack(spacing: 0) {
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            Text("\(plan.completedSessions)")
                                .font(DesignSystem.Typography.title3)
                                .foregroundColor(DesignSystem.Colors.text.primary)
                            Text("/\(plan.totalSessions)")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.text.secondary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Day Card

struct DayCard: View {
    let day: DayPlan

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM"
        return formatter.string(from: day.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Day header
            HStack(alignment: .center, spacing: 12) {
                // Day badge
                if day.isToday {
                    Text("TODAY")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.white)
                        .cornerRadius(6)
                } else {
                    Text(day.dayName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(DesignSystem.Colors.surface)
                        .cornerRadius(6)
                }

                // Date
                Text(formattedDate)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(day.isToday ? .white : DesignSystem.Colors.text.secondary)
            }

            // Day content
            if day.isRestDay {
                RestDayContent()
            } else if day.workouts.isEmpty {
                // Workouts not yet generated for this week
                WorkoutsComingSoonContent()
            } else {
                VStack(spacing: 16) {
                    ForEach(Array(day.workouts.enumerated()), id: \.element.id) { index, workout in
                        WorkoutRow(
                            workout: workout,
                            isToday: day.isToday,
                            isFirstUncompleted: isFirstUncompletedWorkout(workout, at: index, in: day.workouts)
                        )
                    }
                }
            }
        }
    }

    private func isFirstUncompletedWorkout(_ workout: PlannedWorkout, at index: Int, in workouts: [PlannedWorkout]) -> Bool {
        // Find the first uncompleted workout
        guard let firstUncompletedIndex = workouts.firstIndex(where: { $0.status != .completed }) else {
            return false
        }
        return index == firstUncompletedIndex && workout.status != .completed
    }
}

// MARK: - Rest Day Content

struct RestDayContent: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 28))
                .foregroundColor(.gray)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text("Rest & Recovery")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)

                Text("Let your body adapt and grow stronger")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }

            Spacer()
        }
    }
}

// MARK: - Workouts Coming Soon Content

struct WorkoutsComingSoonContent: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 28))
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: 44, height: 44)
                .background(DesignSystem.Colors.primary.opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text("Workouts Coming Soon")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)

                Text("Detailed workouts will be generated as this week approaches")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }

            Spacer()
        }
    }
}

// MARK: - Workout Row

struct WorkoutRow: View {
    let workout: PlannedWorkout
    let isToday: Bool
    let isFirstUncompleted: Bool

    @State private var isExpanded: Bool
    @State private var showDetail = false
    @State private var showingWorkoutDetail = false
    @State private var selectedWorkout: PlannedWorkout?
    @State private var isStartingWorkout = false
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var healthKitService: HealthKitService

    init(workout: PlannedWorkout, isToday: Bool, isFirstUncompleted: Bool) {
        self.workout = workout
        self.isToday = isToday
        self.isFirstUncompleted = isFirstUncompleted
        // Expand first uncompleted workout by default
        _isExpanded = State(initialValue: isFirstUncompleted)
    }

    var body: some View {
        // Main workout card with left accent bar
        FlexrCard(padding: 0) {
            ZStack(alignment: .leading) {
                // Left accent bar
                Rectangle()
                    .fill(workoutTypeColor)
                    .frame(width: 4)
                
                VStack(alignment: .leading, spacing: 0) {
                    // Tappable header
                    // Tappable header
                    HStack(alignment: .top, spacing: 0) {
                        // Main Content (Expand Trigger)
                        Button {
                            withAnimation(DesignSystem.Animation.spring) {
                                isExpanded.toggle()
                            }
                        } label: {
                            HStack(alignment: .top, spacing: 16) {
                                // Workout icon
                                Image(systemName: workout.workoutType.icon)
                                    .font(.system(size: 22))
                                    .foregroundColor(workoutTypeColor)
                                    .frame(width: 48, height: 48)
                                    .background(workoutTypeColor.opacity(0.1))
                                    .cornerRadius(12)
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(workout.name)
                                        .font(DesignSystem.Typography.title3)
                                        .foregroundColor(DesignSystem.Colors.text.primary)
                                        .multilineTextAlignment(.leading)
                                    
                                    HStack(spacing: 6) {
                                        // Duration
                                        HStack(spacing: 3) {
                                            Image(systemName: "clock")
                                                .font(.caption)
                                            Text("\(workout.estimatedDuration) min")
                                                .lineLimit(1)
                                        }
                                        .font(DesignSystem.Typography.caption1)
                                        .foregroundColor(DesignSystem.Colors.text.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 5)
                                        .background(DesignSystem.Colors.background)
                                        .cornerRadius(6)
                                        
                                        // Intensity
                                        HStack(spacing: 3) {
                                            Image(systemName: "bolt.fill")
                                                .font(.caption)
                                            Text(workout.intensity.tagLabel)
                                                .lineLimit(1)
                                        }
                                        .font(DesignSystem.Typography.caption1)
                                        .foregroundColor(intensityColor)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 5)
                                        .background(DesignSystem.Colors.background)
                                        .cornerRadius(6)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        // Chevron (Navigation Trigger)
                        Button {
                            showDetail = true
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(DesignSystem.Colors.text.secondary)
                                .frame(width: 44, height: 44) // Larger touch target
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(20)
                    .padding(.leading, 4)
                    
                    // Expanded content
                    if isExpanded {
                        VStack(alignment: .leading, spacing: 16) {
                            // AI Coach Insight
                            if let explanation = workout.aiExplanation {
                                AICoachInsight(explanation: explanation)
                                    .padding(.horizontal, 20)
                            }
                            
                            // Start button
                            if isToday && workout.status != .completed {
                                FlexrButton(
                                    title: "Start Workout",
                                    icon: "play.fill",
                                    style: .action,
                                    isLoading: isStartingWorkout,
                                    action: startWorkout
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .onTapGesture {
             // Handle tap if needed, separate from button
             if !isExpanded {
                 withAnimation(DesignSystem.Animation.spring) {
                     isExpanded.toggle()
                 }
             }
        }
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                .stroke(DesignSystem.Colors.divider, lineWidth: 1)
        )
        .sheet(isPresented: $showDetail) {
            PlannedWorkoutDetailView(workout: workout)
                .environmentObject(healthKitService)
        }
    }

    private var workoutTypeColor: Color {
        switch workout.workoutType {
        case .running, .warmup, .cooldown:
            return DesignSystem.Colors.running
        case .strength:
            return DesignSystem.Colors.warning
        case .hybrid:
            return DesignSystem.Colors.error
        default:
            return DesignSystem.Colors.primary
        }
    }

    private var intensityColor: Color {
        switch workout.intensity {
        case .recovery: return DesignSystem.Colors.secondary
        case .easy: return DesignSystem.Colors.success
        case .moderate: return DesignSystem.Colors.warning
        case .hard: return DesignSystem.Colors.zone4
        case .veryHard, .maxEffort: return DesignSystem.Colors.error
        }
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
}

// MARK: - AI Coach Insight

struct AICoachInsight: View {
    let explanation: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // AI icon with gradient
            Image(systemName: "sparkles")
                .font(.system(size: 16))
                .foregroundStyle(
                    LinearGradient(
                        colors: [DesignSystem.Colors.primary, DesignSystem.Colors.burpees],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("Coach Insight")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Text(explanation)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(DesignSystem.Colors.text.secondary)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(DesignSystem.Colors.primary.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DesignSystem.Colors.primary.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Start Workout Button

// MARK: - Start Workout Button (Replaced by Unified FlexrButton)
// This explicit definition is deprecated in favor of UnifiedComponents.FlexrButton
// Keeping the file clean by removing it or commenting it out.

// MARK: - Week Pill

struct WeekPill: View {
    let weekNumber: Int
    let isSelected: Bool
    let isCurrentWeek: Bool
    let action: () -> Void

    init(weekNumber: Int, isSelected: Bool, isCurrentWeek: Bool = false, action: @escaping () -> Void) {
        self.weekNumber = weekNumber
        self.isSelected = isSelected
        self.isCurrentWeek = isCurrentWeek
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                // Current week indicator dot
                if isCurrentWeek && !isSelected {
                    Circle()
                        .fill(DesignSystem.Colors.primary)
                        .frame(width: 6, height: 6)
                }
                Text("Week \(weekNumber)")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : (isCurrentWeek ? DesignSystem.Colors.primary : DesignSystem.Colors.text.secondary))
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.surface)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isCurrentWeek && !isSelected ? DesignSystem.Colors.primary.opacity(0.5) : (isSelected ? Color.white.opacity(0.1) : Color.clear),
                        lineWidth: isCurrentWeek && !isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Week Summary Card

struct WeekSummaryCard: View {
    let plan: WeeklyPlan

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("Week Summary")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)

            HStack(spacing: 0) {
                SummaryMetric(
                    value: "\(plan.totalSessions)",
                    label: "Total",
                    icon: "figure.run"
                )

                Divider()
                    .background(Color.white.opacity(0.15))
                    .frame(height: 44)

                SummaryMetric(
                    value: "\(plan.completedSessions)",
                    label: "Completed",
                    icon: "checkmark.circle.fill",
                    color: DesignSystem.Colors.success
                )

                Divider()
                    .background(Color.white.opacity(0.15))
                    .frame(height: 44)

                SummaryMetric(
                    value: "\(plan.totalSessions - plan.completedSessions)",
                    label: "Remaining",
                    icon: "clock.fill",
                    color: DesignSystem.Colors.warning
                )
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

struct SummaryMetric: View {
    let value: String
    let label: String
    let icon: String
    var color: Color = .white

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Empty Plan View

struct EmptyPlanView: View {
    @EnvironmentObject var appState: AppState
    @State private var showOnboarding = false
    @State private var isGenerating = false
    @State private var showError = false
    @State private var errorMessage = ""

    private var isLoggedIn: Bool {
        appState.currentUser != nil
    }

    /// Check if the CURRENT user has completed onboarding
    private var hasCompletedOnboarding: Bool {
        guard let userId = appState.currentUser?.id else { return false }
        let completedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        let onboardedUserId = UserDefaults.standard.string(forKey: "onboardedUserId") ?? ""
        return completedOnboarding && onboardedUserId == userId.uuidString
    }

    var body: some View {
        VStack(spacing: 24) {
            if !isLoggedIn {
                notLoggedInView
            } else if !hasCompletedOnboarding {
                needsOnboardingView
            } else if isGenerating {
                GeneratingPlanView()
            } else {
                readyToGenerateView
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .sheet(isPresented: $showOnboarding) {
            OnboardingCoordinator(onComplete: { user in
                appState.currentUser = user
                // Save user-specific onboarding completion
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                UserDefaults.standard.set(user.id.uuidString, forKey: "onboardedUserId")
                generatePlan()
            })
            .environmentObject(appState)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Not Logged In

    private var notLoggedInView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "person.crop.circle")
                .font(.system(size: 72))
                .foregroundColor(.gray)

            Text("Sign In to Start")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Sign in from the Profile tab to unlock your intelligent training plan")
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Spacer()
        }
    }

    // MARK: - Needs Onboarding

    private var needsOnboardingView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "figure.run")
                .font(.system(size: 72))
                .foregroundColor(DesignSystem.Colors.primary)

            Text("Build Your Intelligent Plan")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Answer a few questions so the AI can analyze YOUR data and build a plan that adapts as you improve")
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            // What we'll analyze
            VStack(alignment: .leading, spacing: 14) {
                OnboardingPreviewItem(icon: "target", text: "Your performance goals")
                OnboardingPreviewItem(icon: "calendar", text: "Target race date")
                OnboardingPreviewItem(icon: "dumbbell.fill", text: "Current fitness baseline")
                OnboardingPreviewItem(icon: "clock", text: "Weekly training capacity")
            }
            .padding(20)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)

            Button {
                showOnboarding = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Get Started")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(DesignSystem.Colors.primary)
                .cornerRadius(12)
            }

            Text("Takes about 3 minutes")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.gray)

            Spacer()
        }
    }

    // MARK: - Ready to Generate

    private var readyToGenerateView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "brain.head.profile")
                .font(.system(size: 72))
                .foregroundColor(.gray)

            Text("Ready to Get Faster?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Generate your intelligent plan based on YOUR performance data")
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Button {
                generatePlan()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Analyze & Generate")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(DesignSystem.Colors.primary)
                .cornerRadius(12)
            }

            Spacer()
        }
    }

    private func generatePlan() {
        isGenerating = true
        Task {
            do {
                try await appState.generateInitialPlan()
                await MainActor.run {
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    errorMessage = error.localizedDescription
                    showError = true
                    print("Plan generation error: \(error)")
                }
            }
        }
    }
}

// MARK: - Generating Plan View

struct GeneratingPlanView: View {
    @State private var currentStep = 0

    private let steps = [
        "Analyzing your profile",
        "Calculating training load",
        "Building weekly structure",
        "Finalizing your plan"
    ]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated progress ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 8)
                    .frame(width: 80, height: 80)

                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(DesignSystem.Colors.primary)
                    .scaleEffect(1.5)
            }

            Text("Building Your Plan")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            // Steps
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    GeneratingStepView(
                        text: step,
                        isComplete: index < currentStep,
                        isActive: index == currentStep
                    )
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .onAppear {
                startStepAnimation()
            }

            Spacer()
        }
        .padding(32)
    }

    private func startStepAnimation() {
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { timer in
            if currentStep < steps.count - 1 {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    currentStep += 1
                }
            } else {
                timer.invalidate()
            }
        }
    }
}

// MARK: - Supporting Views

struct OnboardingPreviewItem: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white)
        }
    }
}

struct GeneratingStepView: View {
    let text: String
    var isComplete: Bool = false
    var isActive: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            if isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(DesignSystem.Colors.success)
            } else if isActive {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(DesignSystem.Colors.primary)
                    .scaleEffect(0.8)
                    .frame(width: 20, height: 20)
            } else {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 20, height: 20)
            }

            Text(text)
                .font(.system(size: 15, weight: isActive ? .medium : .regular))
                .foregroundColor(isActive ? .white : .gray)
        }
    }
}

// MARK: - Plan Reasoning Teaser

struct PlanReasoningTeaser: View {
    let reasoning: PlanReasoning
    @Binding var showFullCycle: Bool

    var body: some View {
        Button {
            showFullCycle = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.primary)

                    Text("Your Personalized Plan")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    Text("View Full Plan")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.primary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.primary)
                }

                // Key Focus Areas (horizontal scroll)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(reasoning.keyFocusAreas.prefix(4), id: \.self) { area in
                            Text(area)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(DesignSystem.Colors.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(DesignSystem.Colors.primary.opacity(0.15))
                                .cornerRadius(8)
                        }
                    }
                }

                // Brief coach note
                Text(reasoning.athleteSpecificNotes)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(DesignSystem.Colors.primary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    WeeklyPlanView()
}
