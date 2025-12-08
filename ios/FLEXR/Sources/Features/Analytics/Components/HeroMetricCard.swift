import SwiftUI

/// Hero metric card - Large, impactful card for main analytics screens
/// Design: 400pt height minimum, 120pt font, 24pt padding, breathing room
/// Usage: Main dashboard cards showing ONE key metric with big impact
struct HeroMetricCard<Content: View>: View {
    let title: String
    let content: () -> Content
    let tapAction: (() -> Void)?

    init(
        title: String,
        tapAction: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.tapAction = tapAction
        self.content = content
    }

    var body: some View {
        Button(action: {
            tapAction?()
        }) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                // Section header
                Text(title.uppercased())
                    .font(DesignSystem.Typography.sectionHeader)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
                    .tracking(0.5)

                // Main content
                content()

                // Tap indicator if actionable
                if tapAction != nil {
                    HStack {
                        Spacer()
                        Text("See details")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundColor(DesignSystem.Colors.primary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DesignSystem.Spacing.analyticsCardPadding)
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.Radius.xLarge)
            .shadow(
                color: DesignSystem.Shadow.medium.color,
                radius: DesignSystem.Shadow.medium.radius,
                x: DesignSystem.Shadow.medium.x,
                y: DesignSystem.Shadow.medium.y
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(tapAction == nil)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        DesignSystem.Colors.background.ignoresSafeArea()

        VStack(spacing: DesignSystem.Spacing.analyticsCardSpacing) {
            // Example 1: Readiness score
            HeroMetricCard(title: "Today's Readiness", tapAction: {}) {
                VStack(spacing: DesignSystem.Spacing.small) {
                    // Large score badge
                    ZStack {
                        Circle()
                            .strokeBorder(DesignSystem.Colors.success.opacity(0.3), lineWidth: 8)
                        Circle()
                            .trim(from: 0, to: 0.78)
                            .stroke(DesignSystem.Colors.success, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 4) {
                            Text("78")
                                .font(DesignSystem.Typography.metricHero)
                                .foregroundColor(.white)
                            Text("/ 100")
                                .font(DesignSystem.Typography.metricSmall)
                                .foregroundColor(DesignSystem.Colors.text.secondary)
                        }
                    }
                    .frame(width: 160, height: 160)

                    // Insight text
                    VStack(spacing: 4) {
                        Text("You're ready for intensity")
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

            // Example 2: Race prediction
            HeroMetricCard(title: "Race Prediction", tapAction: {}) {
                VStack(spacing: DesignSystem.Spacing.medium) {
                    Text("1:18:45")
                        .font(DesignSystem.Typography.metricBreakdown)
                        .foregroundColor(.white)

                    HStack(spacing: DesignSystem.Spacing.xSmall) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(DesignSystem.Colors.success)
                        Text("2:15 faster than last month")
                            .font(DesignSystem.Typography.insightMedium)
                            .foregroundColor(DesignSystem.Colors.success)
                    }

                    Text("Based on 47 training sessions")
                        .font(DesignSystem.Typography.insightSmall)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
    }
}
