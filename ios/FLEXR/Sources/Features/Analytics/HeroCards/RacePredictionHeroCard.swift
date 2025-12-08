import SwiftUI

/// Race prediction hero card - Shows predicted race time with trend
/// Design: Large time display + trend indicator + session count
/// Usage: Second card on analytics home screen
struct RacePredictionHeroCard: View {
    let predictedTime: String // Format: "1:24" (h:mm - no seconds)
    let changeMinutes: Int // Positive = slower, Negative = faster
    let sessionCount: Int
    let onTap: (() -> Void)?

    private var changeText: String {
        let absMinutes = abs(changeMinutes)
        let seconds = absMinutes % 60
        let minutes = absMinutes / 60

        if changeMinutes < 0 {
            return "\(minutes):\(String(format: "%02d", seconds)) faster than last month"
        } else if changeMinutes > 0 {
            return "\(minutes):\(String(format: "%02d", seconds)) slower than last month"
        } else {
            return "Same as last month"
        }
    }

    private var changeColor: Color {
        if changeMinutes < 0 { return DesignSystem.Colors.success }
        if changeMinutes > 0 { return DesignSystem.Colors.warning }
        return DesignSystem.Colors.text.secondary
    }

    private var trendIcon: String {
        if changeMinutes < 0 { return "arrow.down" }
        if changeMinutes > 0 { return "arrow.up" }
        return "arrow.left.and.right"
    }

    var body: some View {
        HeroMetricCard(title: "Race Prediction", tapAction: onTap) {
            VStack(spacing: DesignSystem.Spacing.medium) {
                // Large predicted time
                Text(predictedTime)
                    .font(DesignSystem.Typography.metricBreakdown)
                    .foregroundColor(.white)

                // Trend indicator
                HStack(spacing: DesignSystem.Spacing.xSmall) {
                    Image(systemName: trendIcon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(changeColor)

                    Text(changeText)
                        .font(DesignSystem.Typography.insightMedium)
                        .foregroundColor(changeColor)
                }

                // Session count context
                Text("Based on \(sessionCount) training sessions")
                    .font(DesignSystem.Typography.insightSmall)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        DesignSystem.Colors.background.ignoresSafeArea()

        VStack(spacing: DesignSystem.Spacing.analyticsCardSpacing) {
            // Improving
            RacePredictionHeroCard(
                predictedTime: "1:18:45",
                changeMinutes: -135, // 2:15 faster
                sessionCount: 47,
                onTap: {}
            )

            // Declining
            RacePredictionHeroCard(
                predictedTime: "1:25:30",
                changeMinutes: 90, // 1:30 slower
                sessionCount: 23,
                onTap: {}
            )

            // Stable
            RacePredictionHeroCard(
                predictedTime: "1:22:00",
                changeMinutes: 0,
                sessionCount: 38,
                onTap: {}
            )
        }
        .padding()
    }
}
