// FLEXR - Minimal Video Overlay
// Clean, subtle, doesn't block the athlete
// Just the essential info people want to see

import SwiftUI

struct MinimalOverlay: View {
    @ObservedObject var workoutVM: WorkoutExecutionViewModel

    // FLEXR Electric Blue
    private let electricBlue = Color(red: 0.039, green: 0.518, blue: 1.0)

    var body: some View {
        ZStack {
            // Top corner: Timer + Recording
            topLeftCorner

            // Top right: Heart rate
            topRightCorner

            // Bottom: Current segment
            bottomInfo
        }
    }

    // MARK: - Components

    private var topLeftCorner: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    // Recording indicator
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)

                        Text("REC")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.9))
                    }

                    // Timer
                    Text(formattedTime(workoutVM.totalElapsedTime))
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
                )

                Spacer()
            }
            .padding(.leading, 16)
            .padding(.top, 50)

            Spacer()
        }
    }

    private var topRightCorner: some View {
        VStack {
            HStack {
                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    // Heart icon
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(hrZoneColor)

                    // BPM
                    HStack(spacing: 2) {
                        Text("\(currentHeartRate)")
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)

                        Text("BPM")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .offset(y: 8)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
                )
            }
            .padding(.trailing, 16)
            .padding(.top, 50)

            Spacer()
        }
    }

    private var bottomInfo: some View {
        VStack {
            Spacer()

            HStack(spacing: 8) {
                // Current segment
                Text(currentSegmentName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .textCase(.uppercase)

                Spacer()

                // Round counter
                HStack(spacing: 3) {
                    Text("\(1)")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(electricBlue)

                    Text("/\(1)")
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: -2)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Computed Properties

    private var currentHeartRate: Int {
        // TODO: Get from HealthKit or Watch
        return 152
    }

    private var hrZoneColor: Color {
        let hr = currentHeartRate
        let maxHR = 220 - 30 // TODO: Use actual max HR

        let percentage = Double(hr) / Double(maxHR)

        if percentage < 0.7 {
            return .green
        } else if percentage < 0.85 {
            return .yellow
        } else {
            return .red
        }
    }

    private var currentSegmentName: String {
        workoutVM.currentSegment?.displayName ?? "Ready"
    }
}

// MARK: - Even More Minimal Version

struct UltraMinimalOverlay: View {
    @ObservedObject var workoutVM: WorkoutExecutionViewModel

    private let electricBlue = Color(red: 0.039, green: 0.518, blue: 1.0)

    var body: some View {
        VStack {
            Spacer()

            // Just one bar at bottom with essential info
            HStack {
                // Timer
                Text(formattedTime(workoutVM.totalElapsedTime))
                    .font(.system(size: 24, weight: .bold, design: .monospaced))

                Spacer()

                // Segment
                Text(workoutVM.currentSegment?.displayName ?? "Ready")
                    .font(.system(size: 16, weight: .semibold))
                    .textCase(.uppercase)

                Spacer()

                // HR
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.red)

                    Text("152")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                }

                Spacer()

                // Round
                Text("\(1)/\(1)")
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundColor(electricBlue)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
            )
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Preview

    // MARK: - Helper Functions

    private func formattedTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }


#Preview("Minimal") {
    ZStack {
        Color.gray.ignoresSafeArea()

        MinimalOverlay(
            workoutVM: WorkoutExecutionViewModel(workout: Workout(userId: UUID(), date: Date(), type: .fullSimulation, segments: [WorkoutSegment(workoutId: UUID(), segmentType: .warmup, targetDuration: 600), WorkoutSegment(workoutId: UUID(), segmentType: .run, targetDistance: 1000), WorkoutSegment(workoutId: UUID(), segmentType: .station, stationType: .skiErg, targetDistance: 1000)]))
        )
    }
}

#Preview("Ultra Minimal") {
    ZStack {
        Color.gray.ignoresSafeArea()

        UltraMinimalOverlay(
            workoutVM: WorkoutExecutionViewModel(workout: Workout(userId: UUID(), date: Date(), type: .fullSimulation, segments: [WorkoutSegment(workoutId: UUID(), segmentType: .warmup, targetDuration: 600), WorkoutSegment(workoutId: UUID(), segmentType: .run, targetDistance: 1000), WorkoutSegment(workoutId: UUID(), segmentType: .station, stationType: .skiErg, targetDistance: 1000)]))
        )
    }
}
