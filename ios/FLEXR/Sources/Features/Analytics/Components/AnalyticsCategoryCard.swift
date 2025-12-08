import SwiftUI

/// Analytics Category Card - 180pt card for detailed analytics categories
/// Design: 2-column grid layout, compact with icon + title + mini insight
/// Usage: "Detailed Analytics" section below hero cards
struct AnalyticsCategoryCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let miniInsight: String
    let onTap: (() -> Void)?

    var body: some View {
        Group {
            if let onTap = onTap {
                Button(action: onTap) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                cardContent
            }
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            // Icon
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(iconColor)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.text.tertiary)
            }

            Spacer()

            // Title
            Text(title)
                .font(DesignSystem.Typography.heading3)
                .foregroundColor(.white)

            // Mini insight
            Text(miniInsight)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 180)
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.large)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        DesignSystem.Colors.background.ignoresSafeArea()

        VStack(spacing: DesignSystem.Spacing.medium) {
            HStack(spacing: DesignSystem.Spacing.medium) {
                AnalyticsCategoryCard(
                    icon: "figure.run",
                    iconColor: DesignSystem.Colors.primary,
                    title: "Running",
                    miniInsight: "Pace improving 5% this month",
                    onTap: nil
                )

                AnalyticsCategoryCard(
                    icon: "heart.fill",
                    iconColor: DesignSystem.Colors.error,
                    title: "Heart Rate",
                    miniInsight: "72% time in Zone 2-3",
                    onTap: nil
                )
            }

            HStack(spacing: DesignSystem.Spacing.medium) {
                AnalyticsCategoryCard(
                    icon: "figure.strengthtraining.traditional",
                    iconColor: DesignSystem.Colors.accent,
                    title: "All Stations",
                    miniInsight: "4 stations improving",
                    onTap: nil
                )

                AnalyticsCategoryCard(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: DesignSystem.Colors.success,
                    title: "Training Load",
                    miniInsight: "Balanced this week",
                    onTap: nil
                )
            }
        }
        .padding()
    }
}
