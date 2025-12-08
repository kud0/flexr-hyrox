// FLEXR - Metrics Page View
// Page 1: Main metrics display (timer, pace, distance, HR)

import SwiftUI

struct MetricsPageView: View {
    @ObservedObject var viewModel: WorkoutExecutionViewModel
    let heartRate: Int
    let onComplete: () -> Void

    // Apple Fitness+ green
    private let fitnessGreen = Color(red: 0.67, green: 1.0, blue: 0.0)

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            // Large Timer
            Text(viewModel.segmentElapsedTime.formattedWorkoutTime)
                .font(.system(size: 72, weight: .bold, design: .monospaced))
                .foregroundColor(fitnessGreen)
                .monospacedDigit()

            // Segment-specific metrics
            if let segment = viewModel.currentSegment {
                segmentMetrics(for: segment)
            }

            // Heart Rate
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.red)

                Text("\(heartRate)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("BPM")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(.top, 8)

            // Progress indicator (if target exists)
            if let segment = viewModel.currentSegment, let target = segment.targetDuration {
                ProgressView(value: min(1.0, viewModel.segmentElapsedTime / target))
                    .progressViewStyle(LinearProgressViewStyle(tint: fitnessGreen))
                    .frame(width: 200)
                    .padding(.top, 12)

                if viewModel.segmentElapsedTime < target {
                    Text("-\((target - viewModel.segmentElapsedTime).formattedWorkoutTime)")
                        .font(.system(size: 18, weight: .medium, design: .monospaced))
                        .foregroundColor(.orange)
                }
            }

            Spacer()

            // Complete Button
            Button(action: onComplete) {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                    Text("COMPLETE SEGMENT")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(fitnessGreen)
                .cornerRadius(14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .padding(.top, 40)
    }

    // MARK: - Segment-specific Metrics

    @ViewBuilder
    private func segmentMetrics(for segment: WorkoutSegment) -> some View {
        switch segment.segmentType {
        case .run:
            runMetrics(segment: segment)
        case .station:
            stationMetrics(segment: segment)
        case .warmup, .cooldown, .rest:
            timeBasedMetrics(segment: segment)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func runMetrics(segment: WorkoutSegment) -> some View {
        VStack(spacing: 12) {
            // Pace Display
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("5'08\"")  // TODO: Get actual pace from HealthKit
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("/KM")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.gray)
            }

            // Target Pace
            if let targetPace = segment.targetPace {
                Text("Target: \(targetPace)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
            }

            // Distance
            if let targetDistance = segment.targetDistance {
                HStack(spacing: 8) {
                    // Current distance (TODO: get from HealthKit)
                    Text("0M")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text("/")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)

                    Text("\(Int(targetDistance))M")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundColor(.gray)
                }
            }
        }
    }

    @ViewBuilder
    private func stationMetrics(segment: WorkoutSegment) -> some View {
        VStack(spacing: 12) {
            // Target display
            if let reps = segment.targetReps, reps > 0 {
                VStack(spacing: 4) {
                    Text("\(reps)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("REPS")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.gray)
                }
            } else if let distance = segment.targetDistance, distance > 0 {
                VStack(spacing: 4) {
                    Text("\(Int(distance))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("METERS")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.gray)
                }
            }

            // Station name
            if let stationType = segment.stationType {
                Text(stationType.displayName.uppercased())
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(fitnessGreen)
            }
        }
    }

    @ViewBuilder
    private func timeBasedMetrics(segment: WorkoutSegment) -> some View {
        VStack(spacing: 12) {
            // Type label
            Text(segment.segmentType.displayName.uppercased())
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(segmentTypeColor(segment.segmentType))

            // Target duration
            if let duration = segment.targetDuration {
                Text("Target: \(duration.formattedWorkoutTime)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
    }

    private func segmentTypeColor(_ type: SegmentType) -> Color {
        switch type {
        case .warmup: return .yellow
        case .cooldown: return .mint
        case .rest: return .gray
        default: return fitnessGreen
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        MetricsPageView(
            viewModel: WorkoutExecutionViewModel(
                workout: Workout(
                    userId: UUID(),
                    date: Date(),
                    type: .fullSimulation,
                    segments: [
                        WorkoutSegment(workoutId: UUID(), segmentType: .run, targetDistance: 1000, targetPace: "5:00-5:15")
                    ]
                )
            ),
            heartRate: 156,
            onComplete: {}
        )
    }
}
