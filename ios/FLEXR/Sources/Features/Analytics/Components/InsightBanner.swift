import SwiftUI

/// Insight banner - Contextual insights and recommendations
/// Design: Subtle banner with icon and text
/// Usage: "You're ready for intensity", "Add more Zone 2", etc.
struct InsightBanner: View {
    enum InsightType {
        case positive
        case neutral
        case warning
        case recommendation

        var color: Color {
            switch self {
            case .positive: return DesignSystem.Colors.success
            case .neutral: return DesignSystem.Colors.primary
            case .warning: return DesignSystem.Colors.warning
            case .recommendation: return DesignSystem.Colors.secondary
            }
        }

        var icon: String {
            switch self {
            case .positive: return "checkmark.circle.fill"
            case .neutral: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .recommendation: return "lightbulb.fill"
            }
        }
    }

    let type: InsightType
    let title: String?
    let message: String

    init(type: InsightType, title: String? = nil, message: String) {
        self.type = type
        self.title = title
        self.message = message
    }

    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.small) {
            Image(systemName: type.icon)
                .font(.system(size: 20))
                .foregroundColor(type.color)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                if let title = title {
                    Text(title)
                        .font(DesignSystem.Typography.subheadlineEmphasized)
                        .foregroundColor(.white)
                }

                Text(message)
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(DesignSystem.Spacing.medium)
        .background(type.color.opacity(0.1))
        .cornerRadius(DesignSystem.Radius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                .strokeBorder(type.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        DesignSystem.Colors.background.ignoresSafeArea()

        VStack(spacing: DesignSystem.Spacing.medium) {
            // Positive insight
            InsightBanner(
                type: .positive,
                title: "Ready for Intensity",
                message: "Your readiness score is 78. This is a good day for a hard workout."
            )

            // Neutral info
            InsightBanner(
                type: .neutral,
                message: "Based on 47 training sessions over the last 30 days."
            )

            // Warning
            InsightBanner(
                type: .warning,
                title: "Low Recovery",
                message: "Your HRV is 15% below average. Consider a lighter session today."
            )

            // Recommendation
            InsightBanner(
                type: .recommendation,
                title: "Training Focus",
                message: "Add 2x ski erg intervals this week to improve your weakest station."
            )

            // Long text example
            InsightBanner(
                type: .positive,
                message: "Your sled push improved 18% this month. Your resistance band work is paying off. Keep adding 3x per week to maintain progress."
            )
        }
        .padding()
    }
}
