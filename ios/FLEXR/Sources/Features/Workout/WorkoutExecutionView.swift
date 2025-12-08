// FLEXR - Workout Execution View
// Active workout execution screen with Apple Fitness+ style UI

import SwiftUI

struct WorkoutExecutionView: View {
    @StateObject private var viewModel: WorkoutExecutionViewModel
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var healthKitService: HealthKitService
    @Environment(\.dismiss) private var dismiss

    @State private var showingEndConfirmation = false
    @State private var showingCompletionView = false
    @State private var showingVideoRecording = false

    init(workout: Workout) {
        _viewModel = StateObject(wrappedValue: WorkoutExecutionViewModel(workout: workout))
    }

    var body: some View {
        ZStack {
            // Active Board View (Digital Whiteboard)
            ActiveWorkoutBoardView(viewModel: viewModel)

            // Segment Transition Overlay - DISABLED
//            if viewModel.isTransitioning {
//                SegmentTransitionSheet(
//                    completedSegment: viewModel.completedSegment,
//                    completionTime: viewModel.segmentElapsedTime,
//                    nextSegment: viewModel.nextSegment,
//                    onStart: { viewModel.continueToNextSegment() }
//                )
//                .transition(.move(edge: .bottom).combined(with: .opacity))
//                .zIndex(100) // Ensure it's on top
//            }

            // Floating Record Button - DISABLED for now
            // TODO: Design video recording UI
            /*
            VStack {
                HStack {
                    Spacer()

                    Button {
                        startRecording()
                    } label: {
                        Image(systemName: "video.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(
                                Circle()
                                    .fill(Color.red)
                                    .shadow(color: .red.opacity(0.5), radius: 8, x: 0, y: 4)
                            )
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                }

                Spacer()
            }
            */
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.start()
            // Start live heart rate monitoring
            healthKitService.startLiveHeartRateMonitoring()
        }
        .onDisappear {
            healthKitService.stopLiveHeartRateMonitoring()
        }
        .alert(endWorkoutAlertTitle, isPresented: $showingEndConfirmation) {
            Button("Keep Going", role: .cancel) { }
            Button(endWorkoutButtonText, role: .destructive) {
                viewModel.endWorkout()
                showingCompletionView = true
            }
        } message: {
            Text(endWorkoutAlertMessage)
        }
        .fullScreenCover(isPresented: $showingCompletionView) {
            WorkoutCompletionView(
                workout: viewModel.workout,
                completionPercentage: viewModel.mainCompletionPercentage,
                isFullyComplete: viewModel.isWorkoutConsideredComplete
            ) {
                // Invalidate cache so next visit fetches fresh data
                PlanService.shared.invalidateCache()
                dismiss()
            }
        }
        .fullScreenCover(isPresented: $showingVideoRecording) {
            VideoRecordingView(workoutVM: viewModel)
                .environmentObject(healthKitService)
        }
        .onChange(of: viewModel.isWorkoutComplete) { _, isComplete in
            if isComplete {
                showingCompletionView = true
            }
        }
        // Transition haptics no longer needed since transition is instant
//        .onChange(of: viewModel.isTransitioning) { _, isTransitioning in
//            if isTransitioning {
//                // Haptic feedback
//                let generator = UINotificationFeedbackGenerator()
//                generator.notificationOccurred(.success)
//            }
//        }
    }

    // MARK: - End Workout Alert Content

    private var endWorkoutAlertTitle: String {
        if viewModel.isWorkoutConsideredComplete {
            return "End Workout?"
        } else {
            return "End Early?"
        }
    }

    private var endWorkoutAlertMessage: String {
        let completed = viewModel.completedMainSegments
        let total = viewModel.totalMainSegments
        let percentage = Int(viewModel.mainCompletionPercentage)

        if viewModel.isWorkoutConsideredComplete {
            return "Great work! You've completed \(completed) of \(total) main segments (\(percentage)%)."
        } else if viewModel.totalElapsedTime < 300 {
            // Less than 5 minutes
            let minutes = Int(viewModel.totalElapsedTime / 60)
            return "You've only been working out for \(minutes) minute\(minutes == 1 ? "" : "s"). This will be saved as partial.\n\nYour AI coach will still learn from this session."
        } else {
            return "You've completed \(completed) of \(total) main segments (\(percentage)%).\n\nThis will be saved as partial. Your AI coach will still learn from this session."
        }
    }

    private var endWorkoutButtonText: String {
        if viewModel.isWorkoutConsideredComplete {
            return "End & Save"
        } else {
            return "End & Save Partial"
        }
    }

    // MARK: - Recording Functions

    private func startRecording() {
        showingVideoRecording = true
        print("🎥 Opening camera view")
    }
}

// MARK: - Workout Top Bar

struct WorkoutTopBar: View {
    let elapsedTime: TimeInterval
    let currentSegmentIndex: Int
    let totalSegments: Int
    let isPaused: Bool
    let onPause: () -> Void

    var body: some View {
        HStack {
            // Elapsed Time
            VStack(alignment: .leading, spacing: 2) {
                Text("ELAPSED")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.text.tertiary)

                Text(elapsedTime.formattedWorkoutTime)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(DesignSystem.Colors.text.primary)
            }

            Spacer()

            // Segment Counter
            Text("\(currentSegmentIndex + 1)/\(totalSegments)")
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(DesignSystem.Colors.surface)
                .cornerRadius(DesignSystem.Radius.small)

            Spacer()

            // Pause Button
            Button(action: onPause) {
                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                    .font(.title2)
                    .foregroundColor(DesignSystem.Colors.text.primary)
                    .frame(width: 44, height: 44)
                    .background(DesignSystem.Colors.surface)
                    .cornerRadius(DesignSystem.Radius.small)
            }
        }
        .padding()
        .background(DesignSystem.Colors.background)
    }
}

// MARK: - Active Segment Card

struct ActiveSegmentCard: View {
    let segment: WorkoutSegment?
    let segmentElapsedTime: TimeInterval
    let heartRate: Double
    let onComplete: () -> Void

    var body: some View {
        if let segment = segment {
            VStack(spacing: DesignSystem.Spacing.large) {
                // Segment Type Badge
                SegmentTypeBadge(segment: segment)

                // Main Metrics
                VStack(spacing: DesignSystem.Spacing.medium) {
                    // Heart Rate (Primary)
                    HeartRateDisplay(heartRate: Int(heartRate))

                    // Target/Progress
                    TargetProgressDisplay(
                        segment: segment,
                        elapsed: segmentElapsedTime
                    )
                }
                .padding(.vertical, DesignSystem.Spacing.large)

                // Elapsed Time for Segment
                VStack(spacing: 4) {
                    Text("SEGMENT TIME")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.text.tertiary)

                    Text(segmentElapsedTime.formattedWorkoutTime)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(DesignSystem.Colors.text.primary)
                }

                Spacer()

                // Complete Button
                Button(action: onComplete) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("COMPLETE SEGMENT")
                            .font(DesignSystem.Typography.bodyMedium)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.medium)
                    .background(
                        LinearGradient(
                            colors: [DesignSystem.Colors.primary, DesignSystem.Colors.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(DesignSystem.Radius.medium)
                }
                .padding(.horizontal)
            }
            .padding()
        } else {
            ContentUnavailableView(
                "No Active Segment",
                systemImage: "figure.run.circle",
                description: Text("Workout completed!")
            )
        }
    }
}

struct SegmentTypeBadge: View {
    let segment: WorkoutSegment

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            // Icon
            Image(systemName: segment.stationType?.icon ?? segment.segmentType.icon)
                .font(.system(size: 48))
                .foregroundColor(segmentColor)

            // Name
            Text(segment.displayName)
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(DesignSystem.Colors.text.primary)

            // Target Description
            if !segment.targetDescription.isEmpty {
                Text(segment.targetDescription)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(segmentColor.opacity(0.1))
        .cornerRadius(DesignSystem.Radius.large)
    }

    private var segmentColor: Color {
        switch segment.segmentType {
        case .run: return .blue
        case .station: return .orange
        case .rest: return .green
        case .warmup: return .yellow
        case .cooldown: return .cyan
        default: return .gray
        }
    }
}

struct HeartRateDisplay: View {
    let heartRate: Int

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "heart.fill")
                .font(.title)
                .foregroundColor(.red)
                .symbolEffect(.pulse, options: .repeating)

            Text("\(heartRate)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundColor(.red)

            Text("BPM")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.text.secondary)
        }
    }
}

struct TargetProgressDisplay: View {
    let segment: WorkoutSegment
    let elapsed: TimeInterval

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.large) {
            if let targetDuration = segment.targetDuration {
                TargetMetric(
                    label: "Target",
                    value: targetDuration.formattedWorkoutTime,
                    progress: min(1.0, elapsed / targetDuration)
                )
            }

            if let targetDistance = segment.targetDistance {
                TargetMetric(
                    label: "Distance",
                    value: "\(Int(targetDistance))m",
                    progress: nil
                )
            }

            if let targetReps = segment.targetReps {
                TargetMetric(
                    label: "Reps",
                    value: "\(targetReps)",
                    progress: nil
                )
            }
        }
    }
}

struct TargetMetric: View {
    let label: String
    let value: String
    let progress: Double?

    var body: some View {
        VStack(spacing: 4) {
            Text(label.uppercased())
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.text.tertiary)

            Text(value)
                .font(DesignSystem.Typography.heading3)
                .foregroundColor(DesignSystem.Colors.text.primary)

            if let progress = progress {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: DesignSystem.Colors.accent))
                    .frame(width: 60)
            }
        }
    }
}

// MARK: - Segment Transition Card

struct SegmentTransitionCard: View {
    let completedSegment: WorkoutSegment?
    let nextSegment: WorkoutSegment?
    let onContinue: () -> Void

    @State private var countdown: Int = 10
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            // Completed Segment Summary
            if let completed = completedSegment {
                VStack(spacing: DesignSystem.Spacing.small) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)

                    Text("\(completed.displayName) Complete!")
                        .font(DesignSystem.Typography.heading2)
                        .foregroundColor(DesignSystem.Colors.text.primary)
                }
            }

            Spacer()

            // Next Segment Preview
            if let next = nextSegment {
                VStack(spacing: DesignSystem.Spacing.medium) {
                    Text("UP NEXT")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.text.tertiary)

                    Image(systemName: next.stationType?.icon ?? next.segmentType.icon)
                        .font(.system(size: 64))
                        .foregroundColor(nextSegmentColor(next))

                    Text(next.displayName)
                        .font(DesignSystem.Typography.heading1)
                        .foregroundColor(DesignSystem.Colors.text.primary)

                    if !next.targetDescription.isEmpty {
                        Text(next.targetDescription)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                    }
                }
            }

            Spacer()

            // Countdown & Continue
            VStack(spacing: DesignSystem.Spacing.medium) {
                Text("Starting in \(countdown)s")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.text.secondary)

                Button(action: {
                    timer?.invalidate()
                    onContinue()
                }) {
                    Text("START NOW")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.medium)
                        .background(
                            LinearGradient(
                                colors: [DesignSystem.Colors.primary, DesignSystem.Colors.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(DesignSystem.Radius.medium)
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .onAppear {
            startCountdown()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func startCountdown() {
        countdown = 10
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if countdown > 0 {
                countdown -= 1

                // Haptic at 3, 2, 1
                if countdown <= 3 && countdown > 0 {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
            } else {
                timer?.invalidate()
                onContinue()
            }
        }
    }

    private func nextSegmentColor(_ segment: WorkoutSegment) -> Color {
        switch segment.segmentType {
        case .run: return .blue
        case .station: return .orange
        case .rest: return .green
        default: return .gray
        }
    }
}

// MARK: - Segment Progress Bar

struct SegmentProgressBar: View {
    let segments: [WorkoutSegment]
    let currentIndex: Int
    let completedIndices: Set<Int>

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            HStack(spacing: 4) {
                ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                    SegmentProgressPill(
                        segment: segment,
                        isCompleted: completedIndices.contains(index),
                        isCurrent: index == currentIndex
                    )
                }
            }

            // Legend
            HStack(spacing: DesignSystem.Spacing.medium) {
                LegendItem(color: .blue, label: "Run")
                LegendItem(color: .orange, label: "Station")
                LegendItem(color: .green, label: "Rest")
            }
            .font(DesignSystem.Typography.caption)
        }
    }
}

struct SegmentProgressPill: View {
    let segment: WorkoutSegment
    let isCompleted: Bool
    let isCurrent: Bool

    var body: some View {
        Rectangle()
            .fill(pillColor)
            .frame(height: isCurrent ? 8 : 4)
            .cornerRadius(2)
            .animation(.spring(response: 0.3), value: isCurrent)
            .overlay(
                isCurrent ? RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.white, lineWidth: 1) : nil
            )
    }

    private var pillColor: Color {
        if isCompleted {
            return segmentColor.opacity(1.0)
        } else if isCurrent {
            return segmentColor.opacity(0.8)
        } else {
            return segmentColor.opacity(0.3)
        }
    }

    private var segmentColor: Color {
        switch segment.segmentType {
        case .run: return .blue
        case .station: return .orange
        case .rest: return .green
        default: return .gray
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .foregroundColor(DesignSystem.Colors.text.secondary)
        }
    }
}

// MARK: - Pause Menu Overlay

struct PauseMenuOverlay: View {
    let onResume: () -> Void
    let onEndWorkout: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: DesignSystem.Spacing.large) {
                Text("WORKOUT PAUSED")
                    .font(DesignSystem.Typography.heading1)
                    .foregroundColor(DesignSystem.Colors.text.primary)

                Spacer()

                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(DesignSystem.Colors.accent)

                Spacer()

                VStack(spacing: DesignSystem.Spacing.medium) {
                    Button(action: onResume) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Resume Workout")
                        }
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.medium)
                        .background(
                            LinearGradient(
                                colors: [DesignSystem.Colors.primary, DesignSystem.Colors.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(DesignSystem.Radius.medium)
                    }

                    Button(action: onEndWorkout) {
                        HStack {
                            Image(systemName: "stop.fill")
                            Text("End Workout")
                        }
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.medium)
                        .background(DesignSystem.Colors.surface)
                        .cornerRadius(DesignSystem.Radius.medium)
                    }
                }
                .padding(.horizontal)
            }
            .padding()
        }
    }
}

// MARK: - TimeInterval Extension

extension TimeInterval {
    var formattedWorkoutTime: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

#Preview {
    WorkoutExecutionView(workout: Workout(
        userId: UUID(),
        date: Date(),
        type: .fullSimulation,
        segments: [
            WorkoutSegment(workoutId: UUID(), segmentType: SegmentType.warmup, targetDuration: 600),
            WorkoutSegment(workoutId: UUID(), segmentType: SegmentType.run, targetDistance: 1000),
            WorkoutSegment(workoutId: UUID(), segmentType: SegmentType.station, stationType: StationType.skiErg, targetDistance: 1000)
        ]
    ))
    .environmentObject(AppState())
    .environmentObject(HealthKitService())
}
