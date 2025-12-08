// FLEXR - Upcoming Segment Card
// Collapsed preview of what's next with intel

import SwiftUI

struct UpcomingSegmentCard: View {
    let segment: WorkoutSegment
    let isNext: Bool
    let intel: StationIntel?

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: segment.stationType?.icon ?? segment.segmentType.icon)
                .font(.system(size: 18))
                .foregroundColor(isNext ? DesignSystem.Colors.primary : DesignSystem.Colors.text.secondary)
                .frame(width: 32)

            // Segment info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if isNext {
                        Text("NEXT:")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(DesignSystem.Colors.primary)
                            .tracking(1.0)
                    }

                    Text(segment.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isNext ? .white : DesignSystem.Colors.text.secondary)
                }

                HStack(spacing: 8) {
                    if let targetDistance = segment.targetDistance {
                        Text("\(Int(targetDistance))m")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.text.tertiary)
                    } else if let targetReps = segment.targetReps {
                        Text("\(targetReps) reps")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.text.tertiary)
                    }

                    if let target = segment.targetDuration {
                        Text("Target: \(target.formattedTime)")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(DesignSystem.Colors.text.tertiary)
                    }
                }
            }

            Spacer()

            // Intel indicator
            if let intel = intel {
                VStack(alignment: .trailing, spacing: 2) {
                    if intel.isStrength {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 12))
                            Text("STRENGTH")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(0.5)
                        }
                        .foregroundColor(DesignSystem.Colors.primary)
                    }

                    if let avg = intel.average {
                        Text("Avg: \(avg.formattedTime)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(DesignSystem.Colors.text.tertiary)
                    }
                }
            }

            if isNext {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.primary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            isNext
                ? DesignSystem.Colors.surface.opacity(0.5)
                : Color.clear
        )
        .overlay(
            isNext
                ? RoundedRectangle(cornerRadius: 10)
                    .stroke(DesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
                : nil
        )
        .cornerRadius(10)
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
    VStack(spacing: 8) {
        UpcomingSegmentCard(
            segment: WorkoutSegment(
                workoutId: UUID(),
                segmentType: .station,
                stationType: .sledPush,
                targetDuration: 45,
                targetDistance: 50
            ),
            isNext: true,
            intel: StationIntel(
                personalBest: 38,
                average: 41,
                target: 45,
                isStrength: true,
                rank: 2,
                recentPerformances: [41, 39, 43],
                strategy: "Start explosive"
            )
        )

        UpcomingSegmentCard(
            segment: WorkoutSegment(
                workoutId: UUID(),
                segmentType: .run,
                targetDuration: 300,
                targetDistance: 1000
            ),
            isNext: false,
            intel: nil
        )
    }
    .padding()
    .background(Color.black)
}
