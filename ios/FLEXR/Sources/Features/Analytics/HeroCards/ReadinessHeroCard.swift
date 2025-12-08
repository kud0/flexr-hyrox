import SwiftUI

/// Readiness hero card - Shows today's readiness score with circular progress
/// Design: Large circular score badge + insight text + tap to detail
/// Usage: First card on analytics home screen
struct ReadinessHeroCard: View {
    let score: Int
    let hrvScore: Int
    let sleepHours: Double
    let restingHR: Int
    let onTap: (() -> Void)?

    private var scoreColor: Color {
        if score >= 80 { return DesignSystem.Colors.success }
        if score >= 60 { return DesignSystem.Colors.warning }
        return DesignSystem.Colors.error
    }

    private var insightText: String {
        if score >= 80 { return "You're ready for intensity" }
        if score >= 60 { return "Good for moderate training" }
        return "Focus on recovery today"
    }

    var body: some View {
        HeroMetricCard(title: "Today's Readiness", tapAction: onTap) {
            VStack(spacing: DesignSystem.Spacing.medium) {
                // Large circular score badge
                ZStack {
                    // Background ring
                    Circle()
                        .strokeBorder(scoreColor.opacity(0.2), lineWidth: 12)
                        .frame(width: 160, height: 160)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: CGFloat(score) / 100.0)
                        .stroke(
                            scoreColor,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(-90))

                    // Score text
                    VStack(spacing: 4) {
                        Text("\(score)")
                            .font(DesignSystem.Typography.metricHero)
                            .foregroundColor(.white)

                        Text("/ 100")
                            .font(DesignSystem.Typography.metricSmall)
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.small)

                // Insight text
                VStack(spacing: 4) {
                    Text(insightText)
                        .font(DesignSystem.Typography.insightMedium)
                        .foregroundColor(.white)

                    Text("Based on HRV, sleep, and resting HR")
                        .font(DesignSystem.Typography.insightSmall)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }
                .multilineTextAlignment(.center)
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
            // High readiness
            ReadinessHeroCard(
                score: 85,
                hrvScore: 52,
                sleepHours: 8.2,
                restingHR: 48,
                onTap: {}
            )

            // Medium readiness
            ReadinessHeroCard(
                score: 68,
                hrvScore: 42,
                sleepHours: 6.5,
                restingHR: 55,
                onTap: {}
            )

            // Low readiness
            ReadinessHeroCard(
                score: 45,
                hrvScore: 32,
                sleepHours: 5.2,
                restingHR: 62,
                onTap: {}
            )
        }
        .padding()
    }
}
