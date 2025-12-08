// FLEXR - Workout Active View
// Main active workout screen with swipeable pages (Apple Fitness+ style)

import SwiftUI

struct WorkoutActiveView: View {
    @ObservedObject var viewModel: WorkoutExecutionViewModel
    @EnvironmentObject var healthKitService: HealthKitService

    @State private var selectedPage = 0
    @State private var showingTransition = false

    // Apple Fitness+ green
    private let fitnessGreen = Color(red: 0.67, green: 1.0, blue: 0.0) // #ABFF00

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Floating Header (Replaced by ActiveWorkoutBoardView header)
//                ActiveWorkoutHeader(
//                    segmentIcon: currentSegmentIcon,
//                    segmentLabel: currentSegmentLabel,
//                    segmentNumber: viewModel.currentSegmentIndex + 1,
//                    totalSegments: viewModel.workout.segments.count,
//                    segmentColor: currentSegmentColor
//                )
//                .padding(.horizontal, 16)
//                .padding(.top, 8)

                // Main TabView Content
                // Main Active View (Digital Whiteboard)
                ActiveWorkoutBoardView(
                    viewModel: viewModel
                )
                
//                TabView(selection: $selectedPage) {
//                    // Page 1: Metrics
//                    MetricsPageView(
//                        viewModel: viewModel,
//                        heartRate: Int(healthKitService.currentHeartRate ?? 0),
//                        onComplete: { viewModel.completeCurrentSegment() }
//                    )
//                    .tag(0)
//
//                    // Page 2: Heart Rate Zones
//                    HeartRatePageView(
//                        currentHR: Int(healthKitService.currentHeartRate ?? 0),
//                        avgHR: Int(healthKitService.currentHeartRate ?? 0), // TODO: track avg
//                        maxHR: Int(healthKitService.currentHeartRate ?? 0)  // TODO: track max
//                    )
//                    .tag(1)
//
//                    // Page 3: Segment Info
//                    SegmentInfoPageView(
//                        currentSegment: viewModel.currentSegment,
//                        nextSegment: nextSegment,
//                        upcomingSegment: upcomingSegment
//                    )
//                    .tag(2)
//
//                    // Page 4: Controls
//                    ControlsPageView(
//                        isPaused: viewModel.isPaused,
//                        onPause: { viewModel.pause() },
//                        onResume: { viewModel.resume() },
//                        onEnd: { viewModel.endWorkout() },
//                        onNext: { viewModel.completeCurrentSegment() },
//                        onSkip: { viewModel.skipCurrentSegment() }
//                    )
//                    .tag(3)
//                }
//                .tabViewStyle(.page(indexDisplayMode: .automatic))
            }

            // Segment Transition Overlay
            if viewModel.isTransitioning {
                SegmentTransitionSheet(
                    completedSegment: viewModel.completedSegment,
                    completionTime: viewModel.segmentElapsedTime,
                    nextSegment: viewModel.nextSegment,
                    onStart: { viewModel.continueToNextSegment() }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: viewModel.isTransitioning) { _, isTransitioning in
            if isTransitioning {
                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }

    // MARK: - Computed Properties

    private var currentSegmentIcon: String {
        guard let segment = viewModel.currentSegment else { return "figure.run" }
        return segment.stationType?.icon ?? segment.segmentType.icon
    }

    private var currentSegmentLabel: String {
        guard let segment = viewModel.currentSegment else { return "Workout" }

        // For runs: show distance
        if segment.segmentType == .run, let distance = segment.targetDistance {
            return "\(Int(distance))M"
        }

        // For stations: show reps or distance
        if let reps = segment.targetReps, reps > 0 {
            return "\(reps) REPS"
        } else if let distance = segment.targetDistance, distance > 0 {
            return "\(Int(distance))M"
        } else if let duration = segment.targetDuration {
            let mins = Int(duration) / 60
            return "\(mins) MIN"
        }

        return segment.displayName.uppercased()
    }

    private var currentSegmentColor: Color {
        guard let segment = viewModel.currentSegment else { return fitnessGreen }

        switch segment.segmentType {
        case .run: return fitnessGreen
        case .warmup: return .yellow
        case .cooldown: return .mint
        case .rest: return .gray
        default: return fitnessGreen
        }
    }

    private var nextSegment: WorkoutSegment? {
        let nextIndex = viewModel.currentSegmentIndex + 1
        guard nextIndex < viewModel.workout.segments.count else { return nil }
        return viewModel.workout.segments[nextIndex]
    }

    private var upcomingSegment: WorkoutSegment? {
        let upcomingIndex = viewModel.currentSegmentIndex + 2
        guard upcomingIndex < viewModel.workout.segments.count else { return nil }
        return viewModel.workout.segments[upcomingIndex]
    }
}

#Preview {
    WorkoutActiveView(
        viewModel: WorkoutExecutionViewModel(
            workout: Workout(
                userId: UUID(),
                date: Date(),
                type: .fullSimulation,
                segments: [
                    WorkoutSegment(workoutId: UUID(), segmentType: .warmup, targetDuration: 600),
                    WorkoutSegment(workoutId: UUID(), segmentType: .run, targetDistance: 1000),
                    WorkoutSegment(workoutId: UUID(), segmentType: .station, stationType: .skiErg, targetDistance: 1000)
                ]
            )
        )
    )
    .environmentObject(HealthKitService())
}
