import SwiftUI

/// Weekly training hero card - Shows weekly training load with circular progress
/// Design: Large progress ring + hours completed/target + percentage
/// Usage: Third card on analytics home screen
struct WeeklyTrainingHeroCard: View {
    let currentHours: Double
    let targetHours: Double
    let onTap: (() -> Void)?

    private var percentage: Double {
        guard targetHours > 0 else { return 0 }
        return min(currentHours / targetHours, 1.0)
    }

    private var remainingHours: Double {
        max(targetHours - currentHours, 0)
    }

    private var ringColor: Color {
        if percentage >= 1.0 { return DesignSystem.Colors.success }
        if percentage >= 0.75 { return DesignSystem.Colors.primary }
        if percentage >= 0.5 { return DesignSystem.Colors.secondary }
        return DesignSystem.Colors.warning
    }

    var body: some View {
        HeroMetricCard(title: "This Week's Training", tapAction: onTap) {
            VStack(spacing: DesignSystem.Spacing.medium) {
                // Large circular progress ring
                ZStack {
                    // Background ring
                    Circle()
                        .strokeBorder(ringColor.opacity(0.2), lineWidth: 16)
                        .frame(width: 200, height: 200)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: percentage)
                        .stroke(
                            ringColor,
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))

                    // Hours text
                    VStack(spacing: 4) {
                        Text(String(format: "%.1f", currentHours))
                            .font(DesignSystem.Typography.metricBreakdownMedium)
                            .foregroundColor(.white)

                        Text("/ \(String(format: "%.1f", targetHours))h")
                            .font(DesignSystem.Typography.metricMedium)
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                    }
                }
                .frame(maxWidth: .infinity)

                // Percentage and remaining
                VStack(spacing: 4) {
                    Text("\(Int(percentage * 100))% complete")
                        .font(DesignSystem.Typography.insightLarge)
                        .foregroundColor(.white)

                    if remainingHours > 0 {
                        Text("\(String(format: "%.1f", remainingHours))h remaining")
                            .font(DesignSystem.Typography.insightSmall)
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                    } else {
                        Text("Weekly target achieved!")
                            .font(DesignSystem.Typography.insightSmall)
                            .foregroundColor(DesignSystem.Colors.success)
                    }
                }
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
            // Nearly complete
            WeeklyTrainingHeroCard(
                currentHours: 6.2,
                targetHours: 8.0,
                onTap: {}
            )

            // Just started
            WeeklyTrainingHeroCard(
                currentHours: 2.5,
                targetHours: 10.0,
                onTap: {}
            )

            // Exceeded target
            WeeklyTrainingHeroCard(
                currentHours: 12.5,
                targetHours: 10.0,
                onTap: {}
            )
        }
        .padding()
    }
}
