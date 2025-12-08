// FLEXR - Performance Stats Card
// Quick overview stats for the workout

import SwiftUI

struct PerformanceStatsCard: View {
    let elapsedTime: TimeInterval
    let targetTime: TimeInterval
    let averagePace: TimeInterval?
    let targetPace: TimeInterval?
    let completedSegments: Int
    let totalSegments: Int

    var body: some View {
        HStack(spacing: 12) {
            // Time stat
            StatColumn(
                label: "TIME",
                value: elapsedTime.formattedElapsed,
                subtitle: "/ \(targetTime.formattedElapsed)",
                color: .white
            )

            Divider()
                .background(DesignSystem.Colors.surface)

            // Pace stat
            if let avgPace = averagePace, let targetPace = targetPace {
                StatColumn(
                    label: "AVG PACE",
                    value: avgPace.formattedPace,
                    subtitle: "Target: \(targetPace.formattedPace)",
                    color: paceColor(avgPace, target: targetPace)
                )

                Divider()
                    .background(DesignSystem.Colors.surface)
            }

            // Progress stat
            StatColumn(
                label: "PROGRESS",
                value: "\(completedSegments)/\(totalSegments)",
                subtitle: "\(Int((Double(completedSegments) / Double(totalSegments)) * 100))%",
                color: DesignSystem.Colors.primary
            )
        }
        .padding(16)
        .background(DesignSystem.Colors.surface.opacity(0.5))
        .cornerRadius(12)
    }

    private func paceColor(_ actual: TimeInterval, target: TimeInterval) -> Color {
        if actual < target - 5 {
            return .green
        } else if actual > target + 10 {
            return .orange
        } else {
            return .white
        }
    }
}

struct StatColumn: View {
    let label: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(DesignSystem.Colors.text.tertiary)
                .tracking(1.0)

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .monospacedDigit()

            Text(subtitle)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }
}

private extension TimeInterval {
    var formattedElapsed: String {
        let minutes = Int(self / 60)
        let seconds = Int(self.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedPace: String {
        let minutes = Int(self / 60)
        let seconds = Int(self.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    PerformanceStatsCard(
        elapsedTime: 765,
        targetTime: 3360,
        averagePace: 312,
        targetPace: 300,
        completedSegments: 3,
        totalSegments: 8
    )
    .padding()
    .background(Color.black)
}
