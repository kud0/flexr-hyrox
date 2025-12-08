// FLEXR - Projected Finish Banner
// Top banner showing projected finish time and delta

import SwiftUI

struct ProjectedFinishBanner: View {
    let projectedTime: TimeInterval
    let targetTime: TimeInterval
    let currentTime: TimeInterval
    let overallProgress: Double

    private var delta: TimeInterval {
        projectedTime - targetTime
    }

    private var isAhead: Bool {
        delta < 0
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MISSION CONTROL")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.text.tertiary)
                        .tracking(1.2)

                    HStack(spacing: 8) {
                        Text(currentTime.formattedElapsed)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .monospacedDigit()

                        Text("/ \(targetTime.formattedElapsed)")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                            .monospacedDigit()
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("PROJECTED")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.text.tertiary)
                        .tracking(1.0)

                    HStack(spacing: 6) {
                        Text(projectedTime.formattedElapsed)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(isAhead ? .green : .red)
                            .monospacedDigit()

                        Text(deltaText)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(isAhead ? .green : .red)
                            .monospacedDigit()
                    }
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(DesignSystem.Colors.surface)
                        .frame(height: 6)

                    // Progress
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignSystem.Colors.primary,
                                    DesignSystem.Colors.primary.opacity(0.7)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * overallProgress, height: 6)
                        .animation(.easeOut(duration: 0.3), value: overallProgress)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.95),
                    Color.black.opacity(0.85)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            DesignSystem.Colors.primary.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 1),
            alignment: .bottom
        )
    }

    private var deltaText: String {
        let seconds = Int(abs(delta))
        let sign = isAhead ? "-" : "+"
        return "\(sign)\(seconds)s"
    }
}

// MARK: - TimeInterval Extension

private extension TimeInterval {
    var formattedElapsed: String {
        let hours = Int(self / 3600)
        let minutes = Int((self.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int(self.truncatingRemainder(dividingBy: 60))

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

#Preview {
    VStack {
        ProjectedFinishBanner(
            projectedTime: 3512, // 58:32
            targetTime: 3360, // 56:00
            currentTime: 765, // 12:45
            overallProgress: 0.38
        )
        Spacer()
    }
    .background(Color.black)
}
