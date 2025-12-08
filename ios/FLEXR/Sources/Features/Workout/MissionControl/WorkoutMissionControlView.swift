// FLEXR - Workout Mission Control
// The command center - tactical overview of your entire HYROX workout
// See everything: timeline, live data, predictions, AI insights

import SwiftUI

struct WorkoutMissionControlView: View {
    @StateObject private var viewModel: MissionControlViewModel
    @State private var showingPauseMenu = false
    @State private var showingEndConfirmation = false

    // Callbacks to parent
    var onEndWorkout: (() -> Void)?
    var onPause: (() -> Void)?
    var onResume: (() -> Void)?
    var onCompleteSegment: (() -> Void)?

    init(workout: Workout,
         onEndWorkout: (() -> Void)? = nil,
         onPause: (() -> Void)? = nil,
         onResume: (() -> Void)? = nil,
         onCompleteSegment: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: MissionControlViewModel(workout: workout))
        self.onEndWorkout = onEndWorkout
        self.onPause = onPause
        self.onResume = onResume
        self.onCompleteSegment = onCompleteSegment
    }

    var body: some View {
        ZStack {
            // Main content
            ScrollView {
                VStack(spacing: 0) {
                    // Projected finish banner (sticky header)
                    ProjectedFinishBanner(
                        projectedTime: viewModel.projectedFinishTime,
                        targetTime: viewModel.targetFinishTime,
                        currentTime: viewModel.totalElapsedTime,
                        overallProgress: viewModel.overallProgress
                    )

                    // Main content
                    VStack(spacing: 16) {
                        // Timeline section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("TIMELINE")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(DesignSystem.Colors.text.tertiary)
                                .tracking(1.2)
                                .padding(.horizontal, 20)

                            VStack(spacing: 8) {
                                // Completed segments
                                ForEach(Array(viewModel.completedSegments.enumerated()), id: \.element.id) { index, segment in
                                    CompletedSegmentCard(
                                        segment: segment,
                                        segmentNumber: index + 1,
                                        status: viewModel.segmentStatus(segment)
                                    )
                                }

                                // Current segment (live)
                                if let current = viewModel.currentSegment {
                                    LiveSegmentCard(
                                        segment: current,
                                        elapsedTime: viewModel.segmentElapsedTime,
                                        progress: viewModel.segmentProgress,
                                        currentPace: viewModel.currentPace,
                                        currentHeartRate: viewModel.currentHeartRate,
                                        hrZone: viewModel.currentHRZone,
                                        projectedTime: nil
                                    )
                                }

                                // Upcoming segments
                                ForEach(Array(viewModel.upcomingSegments.enumerated()), id: \.element.id) { index, segment in
                                    UpcomingSegmentCard(
                                        segment: segment,
                                        isNext: index == 0,
                                        intel: viewModel.getStationIntel(segment)
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Analytics section
                        VStack(spacing: 16) {
                            // Performance stats
                            PerformanceStatsCard(
                                elapsedTime: viewModel.totalElapsedTime,
                                targetTime: viewModel.targetFinishTime,
                                averagePace: viewModel.paceDegradationData.isEmpty ? nil : viewModel.paceDegradationData.map { $0.pace }.reduce(0, +) / Double(viewModel.paceDegradationData.count),
                                targetPace: 300,
                                completedSegments: viewModel.currentSegmentIndex,
                                totalSegments: viewModel.workout.segments.count
                            )

                            // Pace degradation
                            if !viewModel.paceDegradationData.isEmpty {
                                PaceDegradationGraph(
                                    paceData: viewModel.paceDegradationData,
                                    targetPace: 300
                                )
                            }

                            // HR zones
                            HRZonesCard(
                                zones: viewModel.hrZoneDistribution,
                                currentHR: viewModel.currentHeartRate,
                                currentZone: viewModel.currentHRZone
                            )

                            // AI insights
                            AIInsightsCard(insights: viewModel.insights)
                        }
                        .padding(.horizontal, 20)

                        // Bottom padding for action buttons
                        Color.clear.frame(height: 100)
                    }
                    .padding(.top, 20)
                }
            }
            .background(Color.black)

            // Floating action buttons
            VStack {
                Spacer()

                HStack(spacing: 12) {
                    // Pause/Resume button
                    ActionButton(
                        icon: viewModel.isPaused ? "play.fill" : "pause.fill",
                        label: viewModel.isPaused ? "Resume" : "Pause",
                        color: .yellow
                    ) {
                        if viewModel.isPaused {
                            viewModel.resume()
                            onResume?()
                        } else {
                            viewModel.pause()
                            onPause?()
                            showingPauseMenu = true
                        }
                    }

                    // Skip segment button
                    ActionButton(
                        icon: "forward.fill",
                        label: "Next",
                        color: DesignSystem.Colors.primary
                    ) {
                        viewModel.completeSegment()
                        onCompleteSegment?()
                    }

                    // End workout button
                    ActionButton(
                        icon: "xmark",
                        label: "End",
                        color: .red
                    ) {
                        showingEndConfirmation = true
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    .ultraThinMaterial.opacity(0.95)
                )
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignSystem.Colors.primary.opacity(0.2),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 1),
                    alignment: .top
                )
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingPauseMenu) {
            PauseMenuSheet(
                elapsedTime: viewModel.totalElapsedTime,
                currentSegment: viewModel.currentSegment?.displayName ?? "",
                onResume: {
                    viewModel.resume()
                    onResume?()
                    showingPauseMenu = false
                },
                onEnd: {
                    viewModel.endWorkout()
                    onEndWorkout?()
                    showingPauseMenu = false
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .alert("End Workout?", isPresented: $showingEndConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("End Workout", role: .destructive) {
                viewModel.endWorkout()
                onEndWorkout?()
            }
        } message: {
            Text("Are you sure you want to end this workout? Your progress will be saved.")
        }
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))

                Text(label)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(color.opacity(0.15))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Pause Menu Sheet

struct PauseMenuSheet: View {
    let elapsedTime: TimeInterval
    let currentSegment: String
    let onResume: () -> Void
    let onEnd: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("PAUSED")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text("Elapsed: \(elapsedTime.formattedElapsed)")
                    .font(.system(size: 17, weight: .medium, design: .monospaced))
                    .foregroundColor(DesignSystem.Colors.text.secondary)

                Text("Current: \(currentSegment)")
                    .font(.system(size: 15))
                    .foregroundColor(DesignSystem.Colors.text.tertiary)
            }
            .padding(.top, 32)

            // Actions
            VStack(spacing: 12) {
                Button(action: onResume) {
                    Text("Resume Workout")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(DesignSystem.Colors.primary)
                        .cornerRadius(14)
                }

                Button(action: onEnd) {
                    Text("End Workout")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(Color.black)
    }
}

private extension TimeInterval {
    var formattedElapsed: String {
        let minutes = Int(self / 60)
        let seconds = Int(self.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Preview

#Preview {
    WorkoutMissionControlView(
        workout: Workout(
            userId: UUID(),
            date: Date(),
            type: .fullSimulation,
            segments: [
                WorkoutSegment(workoutId: UUID(), segmentType: .warmup, targetDuration: 300),
                WorkoutSegment(workoutId: UUID(), segmentType: .run, targetDuration: 300, targetDistance: 1000, targetPace: "5:00"),
                WorkoutSegment(workoutId: UUID(), segmentType: .station, stationType: .skiErg, targetDuration: 270, targetDistance: 1000),
                WorkoutSegment(workoutId: UUID(), segmentType: .run, targetDuration: 300, targetDistance: 1000),
                WorkoutSegment(workoutId: UUID(), segmentType: .station, stationType: .sledPush, targetDuration: 45, targetDistance: 50),
                WorkoutSegment(workoutId: UUID(), segmentType: .run, targetDuration: 300, targetDistance: 1000),
                WorkoutSegment(workoutId: UUID(), segmentType: .station, stationType: .sledPull, targetDuration: 50, targetDistance: 50),
                WorkoutSegment(workoutId: UUID(), segmentType: .run, targetDuration: 300, targetDistance: 1000)
            ]
        )
    )
}
