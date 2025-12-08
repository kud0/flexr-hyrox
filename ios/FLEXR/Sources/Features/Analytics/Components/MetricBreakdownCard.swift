import SwiftUI

/// Metric breakdown card - 180pt card showing detailed metric with large value
/// Design: Clean, focused, ONE metric per card with context
/// Usage: Detail screens for breaking down metrics (HRV, Sleep, RHR, etc.)
struct MetricBreakdownCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let unit: String?
    let change: String?
    let changeColor: Color?
    let contributionPercent: Double?

    init(
        icon: String,
        iconColor: Color = DesignSystem.Colors.primary,
        title: String,
        value: String,
        unit: String? = nil,
        change: String? = nil,
        changeColor: Color? = nil,
        contributionPercent: Double? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.value = value
        self.unit = unit
        self.change = change
        self.changeColor = changeColor
        self.contributionPercent = contributionPercent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            // Header with icon and title
            HStack(spacing: DesignSystem.Spacing.small) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)

                Text(title)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(.white)
            }

            // Large value
            HStack(alignment: .firstTextBaseline, spacing: DesignSystem.Spacing.xxSmall) {
                Text(value)
                    .font(DesignSystem.Typography.metricMedium)
                    .foregroundColor(.white)

                if let unit = unit {
                    Text(unit)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }
            }

            // Change indicator
            if let change = change, let changeColor = changeColor {
                HStack(spacing: DesignSystem.Spacing.xxSmall) {
                    Image(systemName: changeColor == DesignSystem.Colors.success ? "arrow.up" : "arrow.down")
                        .font(.system(size: 14, weight: .bold))
                    Text(change)
                        .font(DesignSystem.Typography.subheadlineEmphasized)
                }
                .foregroundColor(changeColor)
            }

            // Contribution bar if provided
            if let contributionPercent = contributionPercent {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 4)
                                .fill(DesignSystem.Colors.surface.opacity(0.5))
                                .frame(height: 8)

                            // Filled portion
                            RoundedRectangle(cornerRadius: 4)
                                .fill(iconColor)
                                .frame(width: geometry.size.width * contributionPercent, height: 8)
                        }
                    }
                    .frame(height: 8)

                    Text("\(Int(contributionPercent * 100))% contribution")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.analyticsCardPadding)
        .frame(minHeight: DesignSystem.CardHeight.standard)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.large)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        DesignSystem.Colors.background.ignoresSafeArea()

        VStack(spacing: DesignSystem.Spacing.analyticsBreakdownSpacing) {
            // Example 1: HRV with improvement
            MetricBreakdownCard(
                icon: "💚",
                iconColor: DesignSystem.Colors.success,
                title: "HRV",
                value: "45",
                unit: "ms",
                change: "5ms from yesterday",
                changeColor: DesignSystem.Colors.success,
                contributionPercent: 0.8
            )

            // Example 2: Sleep neutral
            MetricBreakdownCard(
                icon: "😴",
                iconColor: DesignSystem.Colors.primary,
                title: "Sleep",
                value: "7.5",
                unit: "hours",
                change: "Same as usual",
                changeColor: DesignSystem.Colors.text.secondary,
                contributionPercent: 0.7
            )

            // Example 3: Resting HR improved
            MetricBreakdownCard(
                icon: "❤️",
                iconColor: DesignSystem.Colors.zone5,
                title: "Resting Heart Rate",
                value: "52",
                unit: "bpm",
                change: "3 bpm from average",
                changeColor: DesignSystem.Colors.success,
                contributionPercent: 0.6
            )
        }
        .padding()
    }
}
