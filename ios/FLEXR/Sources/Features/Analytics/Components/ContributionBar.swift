import SwiftUI

/// Contribution/impact bar - Shows relative contribution of a metric
/// Design: Simple horizontal bar with percentage
/// Usage: Readiness breakdown (HRV 80%, Sleep 70%, etc.)
struct ContributionBar: View {
    let percentage: Double
    let color: Color
    let height: CGFloat

    init(
        percentage: Double,
        color: Color = DesignSystem.Colors.primary,
        height: CGFloat = 8
    ) {
        self.percentage = max(0, min(1, percentage))
        self.color = color
        self.height = height
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(DesignSystem.Colors.surface.opacity(0.5))
                    .frame(height: height)

                // Filled portion
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color)
                    .frame(width: geometry.size.width * percentage, height: height)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        DesignSystem.Colors.background.ignoresSafeArea()

        VStack(spacing: DesignSystem.Spacing.large) {
            // Example usage in a metric card
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                Text("HRV CONTRIBUTION")
                    .font(DesignSystem.Typography.sectionHeader)
                    .foregroundColor(DesignSystem.Colors.text.secondary)

                Text("45 ms")
                    .font(DesignSystem.Typography.metricLarge)
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                    ContributionBar(
                        percentage: 0.8,
                        color: DesignSystem.Colors.success,
                        height: 8
                    )

                    Text("80% contribution to readiness")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }
            }
            .padding()
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.Radius.large)

            // Different colors and percentages
            VStack(spacing: DesignSystem.Spacing.medium) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Sleep")
                            .font(DesignSystem.Typography.subheadline)
                        Spacer()
                        Text("70%")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                    }
                    ContributionBar(percentage: 0.7, color: DesignSystem.Colors.primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Resting HR")
                            .font(DesignSystem.Typography.subheadline)
                        Spacer()
                        Text("60%")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                    }
                    ContributionBar(percentage: 0.6, color: DesignSystem.Colors.zone5)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Training Load")
                            .font(DesignSystem.Typography.subheadline)
                        Spacer()
                        Text("45%")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                    }
                    ContributionBar(percentage: 0.45, color: DesignSystem.Colors.warning)
                }
            }
            .padding()
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.Radius.large)
        }
        .padding()
    }
}
