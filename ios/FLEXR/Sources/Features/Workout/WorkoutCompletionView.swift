// FLEXR - Workout Completion View
// Post-workout summary and feedback

import SwiftUI

struct WorkoutCompletionView: View {
    let workout: Workout
    let completionPercentage: Double  // 0-100, based on main segments
    let isFullyComplete: Bool         // true if >75% + >5 min
    let onDismiss: () -> Void

    @StateObject private var feedbackService = FeedbackService.shared
    @State private var rpeScore: Int = 0
    @State private var moodScore: Int = 0
    @State private var selectedTags: Set<FeedbackTag> = []
    @State private var notes: String = ""
    @State private var showingFullStats = false
    @State private var isSaving = false
    @State private var showRegenerationBanner = false
    @State private var regenerationSignal: String?

    // Convenience init for backwards compatibility
    init(workout: Workout, completionPercentage: Double = 100, isFullyComplete: Bool = true, onDismiss: @escaping () -> Void) {
        self.workout = workout
        self.completionPercentage = completionPercentage
        self.isFullyComplete = isFullyComplete
        self.onDismiss = onDismiss
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.large) {
                    // Celebration Header
                    CelebrationHeader(
                        workout: workout,
                        completionPercentage: completionPercentage,
                        isFullyComplete: isFullyComplete
                    )

                    // Quick Stats
                    QuickStatsGrid(workout: workout)

                    // Route Map (only if route data exists)
                    if let routeData = workout.routeData {
                        VStack(alignment: .leading, spacing: 12) {
                            // Section header
                            Text("ROUTE")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(DesignSystem.Colors.text.tertiary)
                                .tracking(1.2)
                                .padding(.horizontal)

                            // Route map component
                            CompletedRouteMapView(routeData: routeData)
                                .background(DesignSystem.Colors.surface)
                                .cornerRadius(DesignSystem.Radius.large)

                            // GPS source indicator
                            if let gpsSource = workout.gpsSource {
                                HStack(spacing: 6) {
                                    Image(systemName: gpsSource == .watch ? "applewatch" : "iphone")
                                    Text("Tracked on \(gpsSource.displayName)")
                                }
                                .font(DesignSystem.Typography.caption2)
                                .foregroundColor(DesignSystem.Colors.text.tertiary)
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Segment Breakdown
                    SegmentBreakdownCard(workout: workout)

                    // MARK: - Feedback Section
                    FeedbackHeaderCard()

                    // RPE Score (1-10)
                    RPEScoreCard(rpeScore: $rpeScore)

                    // Mood Score (emojis)
                    MoodScoreCard(moodScore: $moodScore)

                    // Quick Tags
                    QuickTagsCard(selectedTags: $selectedTags)

                    // Notes Section
                    WorkoutNotesCard(notes: $notes)

                    // Compromised Running Insight (if applicable)
                    if hasCompromisedRunData {
                        CompromisedRunningInsightCard(workout: workout)
                    }

                    // Regeneration Banner (shown when next week is regenerated due to feedback)
                    if showRegenerationBanner {
                        RegenerationBannerCard(signal: regenerationSignal)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                }
                .padding()
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Workout Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        saveAndDismiss()
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(DesignSystem.Colors.accent)
                        } else {
                            Text("Done")
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(DesignSystem.Colors.accent)
                        }
                    }
                    .disabled(isSaving)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var hasCompromisedRunData: Bool {
        workout.segments.contains { $0.isCompromised == true }
    }

    private func saveAndDismiss() {
        isSaving = true

        // Build feedback object
        let feedback = WorkoutFeedback(
            userId: workout.userId,
            workoutId: workout.id,
            rpeScore: rpeScore > 0 ? rpeScore : nil,
            moodScore: moodScore > 0 ? moodScore : nil,
            tags: Array(selectedTags),
            freeText: notes.isEmpty ? nil : notes,
            actualDurationSeconds: Int(workout.actualDuration),
            avgHeartRate: workout.averageHeartRate.map { Int($0) },
            maxHeartRate: workout.maxHeartRate.map { Int($0) },
            caloriesBurned: workout.estimatedCalories,
            completionPercentage: completionPercentage
        )

        Task {
            do {
                let result = try await feedbackService.submitFeedback(feedback)

                await MainActor.run {
                    isSaving = false

                    // Check if regeneration was triggered
                    if result.regenerationTriggered {
                        regenerationSignal = result.signal
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showRegenerationBanner = true
                        }
                        // Auto-dismiss after showing the banner
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            onDismiss()
                        }
                    } else {
                        onDismiss()
                    }
                }
            } catch {
                print("Error saving feedback: \(error)")
                await MainActor.run {
                    isSaving = false
                    // Still dismiss even if save fails - don't block user
                    onDismiss()
                }
            }
        }
    }
}

// MARK: - Regeneration Banner Card

struct RegenerationBannerCard: View {
    let signal: String?

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DesignSystem.Colors.primary, DesignSystem.Colors.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Your AI Coach Heard You")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.text.primary)

                    Text(bannerMessage)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }

                Spacer()
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [DesignSystem.Colors.primary.opacity(0.15), DesignSystem.Colors.accent.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(DesignSystem.Radius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                .stroke(
                    LinearGradient(
                        colors: [DesignSystem.Colors.primary.opacity(0.3), DesignSystem.Colors.accent.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private var bannerMessage: String {
        switch signal {
        case "too_easy":
            return "Next week's workouts have been adjusted to be more challenging."
        case "too_hard":
            return "Next week's workouts have been adjusted for better recovery."
        case "needs_adjustment":
            return "Next week will prioritize recovery based on your feedback."
        default:
            return "Next week's workouts have been personalized based on your feedback."
        }
    }
}

// MARK: - Celebration Header

struct CelebrationHeader: View {
    let workout: Workout
    let completionPercentage: Double
    let isFullyComplete: Bool

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            // Animated checkmark or partial indicator
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isFullyComplete
                                ? [DesignSystem.Colors.primary, DesignSystem.Colors.accent]
                                : [DesignSystem.Colors.warning, DesignSystem.Colors.warning.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: isFullyComplete ? "checkmark" : "flag.checkered")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.black)
            }

            Text(isFullyComplete ? "Great Work!" : "Good Effort!")
                .font(DesignSystem.Typography.heading1)
                .foregroundColor(DesignSystem.Colors.text.primary)

            if isFullyComplete {
                Text("You completed \(workout.type.displayName)")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            } else {
                VStack(spacing: 4) {
                    Text("\(Int(completionPercentage))% of main workout completed")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text.secondary)

                    Text("Your AI coach will still learn from this session")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.text.tertiary)
                }
            }
        }
        .padding(.vertical, DesignSystem.Spacing.large)
    }
}

// MARK: - Quick Stats Grid

struct QuickStatsGrid: View {
    let workout: Workout

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: DesignSystem.Spacing.medium) {
            StatBox(
                icon: "clock.fill",
                value: formattedDuration,
                label: "Duration",
                color: .blue
            )

            StatBox(
                icon: "flame.fill",
                value: "\(workout.estimatedCalories ?? 0)",
                label: "Calories",
                color: .orange
            )

            StatBox(
                icon: "heart.fill",
                value: formattedAvgHR,
                label: "Avg HR",
                color: .red
            )

            StatBox(
                icon: "figure.run",
                value: "\(workout.runSegments.count)",
                label: "Runs",
                color: .cyan
            )

            StatBox(
                icon: "dumbbell.fill",
                value: "\(workout.stationSegments.count)",
                label: "Stations",
                color: .purple
            )

            StatBox(
                icon: "arrow.left.arrow.right",
                value: formattedDistance,
                label: "Distance",
                color: .green
            )
        }
    }

    private var formattedDuration: String {
        let duration = workout.actualDuration
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var formattedAvgHR: String {
        guard let avgHR = workout.averageHeartRate else { return "--" }
        return "\(Int(avgHR))"
    }

    private var formattedDistance: String {
        let km = workout.totalDistance / 1000
        return String(format: "%.1f km", km)
    }
}

struct StatBox: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(DesignSystem.Typography.heading3)
                .foregroundColor(DesignSystem.Colors.text.primary)

            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.text.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.medium)
    }
}

// MARK: - Segment Breakdown Card

struct SegmentBreakdownCard: View {
    let workout: Workout
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            HStack {
                Text("Segment Breakdown")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundColor(DesignSystem.Colors.text.primary)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }
            }

            if isExpanded {
                VStack(spacing: DesignSystem.Spacing.small) {
                    ForEach(Array(workout.segments.enumerated()), id: \.element.id) { index, segment in
                        SegmentResultRow(index: index + 1, segment: segment)
                    }
                }
            } else {
                // Compact view - just show run vs station times
                HStack(spacing: DesignSystem.Spacing.large) {
                    CompactSegmentStat(
                        label: "Running",
                        duration: totalRunTime,
                        color: .blue
                    )

                    CompactSegmentStat(
                        label: "Stations",
                        duration: totalStationTime,
                        color: .orange
                    )
                }
            }
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.medium)
    }

    private var totalRunTime: TimeInterval {
        workout.runSegments.compactMap { $0.actualDuration }.reduce(0, +)
    }

    private var totalStationTime: TimeInterval {
        workout.stationSegments.compactMap { $0.actualDuration }.reduce(0, +)
    }
}

struct SegmentResultRow: View {
    let index: Int
    let segment: WorkoutSegment

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            // Index
            Text("\(index)")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.text.tertiary)
                .frame(width: 24)

            // Icon
            Image(systemName: segment.stationType?.icon ?? segment.segmentType.icon)
                .foregroundColor(segmentColor)
                .frame(width: 24)

            // Name
            Text(segment.displayName)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.text.primary)

            Spacer()

            // Duration
            if let duration = segment.actualDuration {
                Text(duration.formattedWorkoutTime)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }

            // Performance indicator
            if let perf = segment.performancePercentage {
                PerformanceIndicator(percentage: perf)
            }
        }
        .padding(.vertical, 4)
    }

    private var segmentColor: Color {
        switch segment.segmentType {
        case .run: return .blue
        case .station: return .orange
        default: return .gray
        }
    }
}

struct PerformanceIndicator: View {
    let percentage: Double

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: percentage >= 100 ? "arrow.up" : "arrow.down")
                .font(.caption2)

            Text(String(format: "%.0f%%", percentage))
                .font(DesignSystem.Typography.caption)
        }
        .foregroundColor(percentage >= 100 ? .green : .orange)
    }
}

struct CompactSegmentStat: View {
    let label: String
    let duration: TimeInterval
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.text.secondary)

            Text(duration.formattedWorkoutTime)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(color)
        }
    }
}

// MARK: - Feedback Header Card

struct FeedbackHeaderCard: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [DesignSystem.Colors.primary, DesignSystem.Colors.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("Quick feedback")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.text.primary)

                Text("This helps your AI coach build your perfect next week")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }

            Spacer()
        }
        .padding()
        .background(DesignSystem.Colors.primary.opacity(0.1))
        .cornerRadius(DesignSystem.Radius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                .stroke(DesignSystem.Colors.primary.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - RPE Score Card (1-10)

struct RPEScoreCard: View {
    @Binding var rpeScore: Int

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            HStack {
                Text("How hard was it?")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundColor(DesignSystem.Colors.text.primary)

                Spacer()

                if rpeScore > 0 {
                    Text("\(rpeScore)/10")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(rpeColor)
                }
            }

            // RPE Slider visual
            HStack(spacing: 4) {
                ForEach(1...10, id: \.self) { value in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            rpeScore = value
                        }
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    } label: {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(value <= rpeScore ? rpeColorForValue(value) : Color.white.opacity(0.1))
                            .frame(height: 32)
                    }
                }
            }

            // Labels
            HStack {
                Text("Easy")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.text.tertiary)
                Spacer()
                Text("Max effort")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.text.tertiary)
            }

            // Description
            if rpeScore > 0 {
                Text(rpeDescription)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
                    .transition(.opacity)
            }
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.medium)
    }

    private var rpeColor: Color {
        rpeColorForValue(rpeScore)
    }

    private func rpeColorForValue(_ value: Int) -> Color {
        switch value {
        case 1...3: return .green
        case 4...6: return .yellow
        case 7...8: return .orange
        case 9...10: return .red
        default: return .gray
        }
    }

    private var rpeDescription: String {
        switch rpeScore {
        case 1...2: return "Very light - could do this all day"
        case 3...4: return "Light - comfortable effort"
        case 5...6: return "Moderate - challenging but sustainable"
        case 7...8: return "Hard - pushing your limits"
        case 9: return "Very hard - near maximum effort"
        case 10: return "Maximum - couldn't do one more rep"
        default: return ""
        }
    }
}

// MARK: - Mood Score Card (Emojis)

struct MoodScoreCard: View {
    @Binding var moodScore: Int

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("How do you feel now?")
                .font(DesignSystem.Typography.heading3)
                .foregroundColor(DesignSystem.Colors.text.primary)

            HStack(spacing: 12) {
                ForEach(MoodScore.allCases, id: \.rawValue) { mood in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            moodScore = mood.rawValue
                        }
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    } label: {
                        VStack(spacing: 6) {
                            Text(mood.emoji)
                                .font(.system(size: 32))

                            Text(mood.description)
                                .font(.system(size: 11))
                                .foregroundColor(moodScore == mood.rawValue ? .white : DesignSystem.Colors.text.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(moodScore == mood.rawValue ? DesignSystem.Colors.primary.opacity(0.3) : Color.clear)
                        .cornerRadius(DesignSystem.Radius.small)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.small)
                                .stroke(moodScore == mood.rawValue ? DesignSystem.Colors.primary : Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.medium)
    }
}

// MARK: - Quick Tags Card

struct QuickTagsCard: View {
    @Binding var selectedTags: Set<FeedbackTag>

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("Anything else? (optional)")
                .font(DesignSystem.Typography.heading3)
                .foregroundColor(DesignSystem.Colors.text.primary)

            // Quick tags in a flow layout
            FlowLayout(spacing: 8) {
                ForEach(FeedbackTag.quickTags, id: \.self) { tag in
                    TagButton(
                        tag: tag,
                        isSelected: selectedTags.contains(tag),
                        action: {
                            withAnimation(.spring(response: 0.2)) {
                                if selectedTags.contains(tag) {
                                    selectedTags.remove(tag)
                                } else {
                                    selectedTags.insert(tag)
                                }
                            }
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }
                    )
                }
            }
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.medium)
    }
}

struct TagButton: View {
    let tag: FeedbackTag
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: tag.icon)
                    .font(.system(size: 12))
                Text(tag.displayName)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .black : DesignSystem.Colors.text.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? DesignSystem.Colors.primary : Color.white.opacity(0.1))
            .cornerRadius(20)
        }
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Workout Notes Card

struct WorkoutNotesCard: View {
    @Binding var notes: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text("Notes (optional)")
                .font(DesignSystem.Typography.heading3)
                .foregroundColor(DesignSystem.Colors.text.primary)

            TextField("How did you feel? Any issues?", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.plain)
                .padding()
                .background(DesignSystem.Colors.background)
                .cornerRadius(DesignSystem.Radius.small)
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.medium)
    }
}

// MARK: - Compromised Running Insight Card

struct CompromisedRunningInsightCard: View {
    let workout: Workout

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            HStack {
                Image(systemName: "figure.run.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)

                Text("Compromised Running")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundColor(DesignSystem.Colors.text.primary)
            }

            Text("Your pace dropped \(paceDropPercentage)% after stations. This is \(performanceLevel) for your experience level.")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.text.secondary)

            // Mini chart showing pace per run
            CompromisedRunChart(runs: compromisedRuns)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), DesignSystem.Colors.surface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(DesignSystem.Radius.medium)
    }

    private var compromisedRuns: [(index: Int, pace: Double, isCompromised: Bool)] {
        workout.runSegments.enumerated().compactMap { index, segment in
            guard let pace = segment.avgPace else { return nil }
            return (index + 1, pace, segment.isCompromised ?? false)
        }
    }

    private var paceDropPercentage: String {
        let runs = workout.runSegments
        guard let firstPace = runs.first?.avgPace,
              let lastPace = runs.last?.avgPace else { return "0" }

        let drop = ((lastPace - firstPace) / firstPace) * 100
        return String(format: "%.0f", abs(drop))
    }

    private var performanceLevel: String {
        let drop = Double(paceDropPercentage) ?? 0
        switch drop {
        case 0..<10: return "excellent"
        case 10..<20: return "good"
        case 20..<30: return "average"
        default: return "below average"
        }
    }
}

struct CompromisedRunChart: View {
    let runs: [(index: Int, pace: Double, isCompromised: Bool)]

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(runs, id: \.index) { run in
                VStack(spacing: 4) {
                    // Bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(run.isCompromised ? Color.orange : Color.blue)
                        .frame(width: 24, height: barHeight(for: run.pace))

                    // Label
                    Text("R\(run.index)")
                        .font(.caption2)
                        .foregroundColor(DesignSystem.Colors.text.tertiary)
                }
            }
        }
        .frame(height: 80)
    }

    private func barHeight(for pace: Double) -> CGFloat {
        guard let minPace = runs.map({ $0.pace }).min(),
              let maxPace = runs.map({ $0.pace }).max(),
              maxPace > minPace else { return 40 }

        let normalized = 1 - (pace - minPace) / (maxPace - minPace)
        return 20 + (normalized * 50)
    }
}

#Preview {
    WorkoutCompletionView(
        workout: Workout(
            userId: UUID(),
            date: Date(),
            type: .fullSimulation,
            segments: [
                WorkoutSegment(workoutId: UUID(), segmentType: .run, targetDistance: 1000, actualDuration: 300),
                WorkoutSegment(workoutId: UUID(), segmentType: .station, stationType: .skiErg, targetDistance: 1000, actualDuration: 240),
                WorkoutSegment(workoutId: UUID(), segmentType: .run, targetDistance: 1000, actualDuration: 320, isCompromised: true)
            ],
            estimatedCalories: 450
        ),
        onDismiss: {}
    )
}
