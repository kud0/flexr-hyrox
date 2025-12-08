// FLEXR - AI Insights Card
// Contextual coaching messages and tactical intelligence

import SwiftUI

struct AIInsightsCard: View {
    let insights: [AIInsight]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14))
                    .foregroundColor(DesignSystem.Colors.primary)

                Text("AI INSIGHTS")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.text.primary)
                    .tracking(1.0)

                Spacer()

                Text("\(insights.count)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DesignSystem.Colors.primary.opacity(0.15))
                    .cornerRadius(6)
            }

            if insights.isEmpty {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 24))
                        .foregroundColor(DesignSystem.Colors.text.tertiary)

                    Text("Keep going! AI is analyzing your performance...")
                        .font(.system(size: 13))
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                // Insights list
                VStack(spacing: 10) {
                    ForEach(insights) { insight in
                        InsightRow(insight: insight)
                    }
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [
                    DesignSystem.Colors.surface.opacity(0.7),
                    DesignSystem.Colors.surface.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [
                            DesignSystem.Colors.primary.opacity(0.3),
                            DesignSystem.Colors.primary.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .cornerRadius(12)
    }
}

struct InsightRow: View {
    let insight: AIInsight

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Image(systemName: insight.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(insight.type.color)
                .frame(width: 24, height: 24)
                .background(insight.type.color.opacity(0.15))
                .cornerRadius(6)

            // Text
            Text(insight.text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    VStack(spacing: 16) {
        // With insights
        AIInsightsCard(
            insights: [
                AIInsight(
                    icon: "chart.line.downtrend.xyaxis",
                    text: "Your run pace is dropping. HR holding steady - station fatigue kicking in.",
                    type: .warning
                ),
                AIInsight(
                    icon: "bolt.fill",
                    text: "Next: Sled Push - your best station. Chance to make up 15s here!",
                    type: .opportunity
                ),
                AIInsight(
                    icon: "checkmark.circle.fill",
                    text: "Strong pacing - 12s ahead of target.",
                    type: .positive
                )
            ]
        )

        // Empty state
        AIInsightsCard(insights: [])
    }
    .padding()
    .background(Color.black)
}
