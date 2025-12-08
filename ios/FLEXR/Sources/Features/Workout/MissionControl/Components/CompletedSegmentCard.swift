// FLEXR - Completed Segment Card
// Shows finished segment with performance delta

import SwiftUI

struct CompletedSegmentCard: View {
    let segment: WorkoutSegment
    let segmentNumber: Int
    let status: SegmentStatus

    private var delta: TimeInterval? {
        guard let actual = segment.actualDuration,
              let target = segment.targetDuration else { return nil }
        return actual - target
    }

    var body: some View {
        HStack(spacing: 12) {
            // Checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(status.color)

            // Segment info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(segment.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)

                    if let targetDistance = segment.targetDistance {
                        Text("\(Int(targetDistance))m")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                    } else if let targetReps = segment.targetReps {
                        Text("\(targetReps) reps")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                    }
                }

                if let actualDuration = segment.actualDuration {
                    Text(actualDuration.formattedTime)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(DesignSystem.Colors.text.tertiary)
                }
            }

            Spacer()

            // Delta indicator
            if let delta = delta {
                HStack(spacing: 4) {
                    Image(systemName: delta < 0 ? "arrow.down" : "arrow.up")
                        .font(.system(size: 12, weight: .bold))

                    Text(deltaText(delta))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
                .foregroundColor(status.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(status.color.opacity(0.15))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(DesignSystem.Colors.surface.opacity(0.3))
        .cornerRadius(10)
    }

    private func deltaText(_ delta: TimeInterval) -> String {
        let seconds = Int(abs(delta))
        return delta < 0 ? "-\(seconds)s" : "+\(seconds)s"
    }
}

private extension TimeInterval {
    var formattedTime: String {
        let minutes = Int(self / 60)
        let seconds = Int(self.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    VStack(spacing: 12) {
        CompletedSegmentCard(
            segment: WorkoutSegment(
                workoutId: UUID(),
                segmentType: .run,
                targetDuration: 300,
                targetDistance: 1000,
                actualDuration: 288
            ),
            segmentNumber: 1,
            status: .ahead
        )

        CompletedSegmentCard(
            segment: WorkoutSegment(
                workoutId: UUID(),
                segmentType: .station,
                stationType: .skiErg,
                targetDuration: 270,
                targetDistance: 1000,
                actualDuration: 275
            ),
            segmentNumber: 2,
            status: .behind
        )
    }
    .padding()
    .background(Color.black)
}
