import SwiftUI

/// Readiness Detail View - Deep dive into recovery metrics
/// Shows: HRV, Sleep, Resting HR with 7-day trends and insights
struct ReadinessDetailView: View {
    @StateObject private var viewModel = ReadinessDetailViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.analyticsSectionSpacing) {
                // Hero Readiness Score
                heroScoreSection

                // Key insight banner
                if let insight = viewModel.keyInsight {
                    InsightBanner(type: .positive, message: insight)
                }

                // 7-day trend
                trendSection

                // Breakdown metrics
                breakdownSection

                // Contributing factors
                contributingFactorsSection

                // Recommendations
                recommendationsSection
            }
            .padding(.horizontal, DesignSystem.Spacing.screenHorizontal)
            .padding(.top, DesignSystem.Spacing.screenTop)
            .padding(.bottom, DesignSystem.Spacing.screenBottom)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle("Readiness")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Hero Score

    private var heroScoreSection: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            // Circular ring with score
            ZStack {
                // Background ring
                Circle()
                    .stroke(
                        DesignSystem.Colors.surface,
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)

                // Progress ring
                Circle()
                    .trim(from: 0, to: CGFloat(viewModel.readinessScore) / 100)
                    .stroke(
                        viewModel.scoreColor,
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))

                // Score text
                VStack(spacing: 4) {
                    Text("\(viewModel.readinessScore)")
                        .font(DesignSystem.Typography.metricHeroLarge)
                        .foregroundColor(.white)

                    Text("Readiness")
                        .font(DesignSystem.Typography.bodyEmphasized)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }
            }
            .padding(.vertical, DesignSystem.Spacing.large)

            // Status message
            Text(viewModel.statusMessage)
                .font(DesignSystem.Typography.insightLarge)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text(viewModel.statusDetail)
                .font(DesignSystem.Typography.insightMedium)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.large)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 7-Day Trend

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("7-DAY TREND")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                // Trend direction indicator
                HStack(spacing: DesignSystem.Spacing.xSmall) {
                    Image(systemName: viewModel.trendDirection.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(viewModel.trendDirection.color)

                    Text(viewModel.trendDirection.text)
                        .font(DesignSystem.Typography.bodyEmphasized)
                        .foregroundColor(.white)

                    Text("(\(viewModel.trendChange > 0 ? "+" : "")\(viewModel.trendChange) points)")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }

                // Chart
                TrendLineChart(
                    dataPoints: viewModel.last7Days,
                    labels: viewModel.dayLabels,
                    color: viewModel.scoreColor,
                    height: 120
                )
                .padding(.top, DesignSystem.Spacing.small)
            }
            .padding(DesignSystem.Spacing.analyticsCardPadding)
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.Radius.large)
        }
    }

    // MARK: - Breakdown Metrics

    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("BREAKDOWN")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(spacing: DesignSystem.Spacing.analyticsBreakdownSpacing) {
                // HRV
                MetricBreakdownCard(
                    icon: "waveform.path.ecg",
                    title: "Heart Rate Variability",
                    value: "\(viewModel.hrvScore)",
                    unit: "ms",
                    change: String(format: "+%.1f%%", viewModel.hrvChange),
                    changeColor: DesignSystem.Colors.success,
                    contributionPercent: viewModel.hrvContribution
                )

                // Sleep
                MetricBreakdownCard(
                    icon: "bed.double.fill",
                    title: "Sleep Quality",
                    value: String(format: "%.1f", viewModel.sleepHours),
                    unit: "hrs",
                    change: String(format: "+%.1f%%", viewModel.sleepChange),
                    changeColor: DesignSystem.Colors.success,
                    contributionPercent: viewModel.sleepContribution
                )

                // Resting HR
                MetricBreakdownCard(
                    icon: "heart.fill",
                    title: "Resting Heart Rate",
                    value: "\(viewModel.restingHR)",
                    unit: "bpm",
                    change: String(format: "%.1f%%", viewModel.restingHRChange),
                    changeColor: DesignSystem.Colors.success,
                    contributionPercent: viewModel.restingHRContribution
                )
            }
        }
    }

    // MARK: - Contributing Factors

    private var contributingFactorsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("WHAT'S AFFECTING YOUR READINESS")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(spacing: DesignSystem.Spacing.small) {
                ForEach(viewModel.contributingFactors) { factor in
                    HStack(spacing: DesignSystem.Spacing.medium) {
                        // Impact indicator
                        Circle()
                            .fill(factor.impact > 0 ? DesignSystem.Colors.success : DesignSystem.Colors.warning)
                            .frame(width: 8, height: 8)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(factor.title)
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(.white)

                            Text(factor.description)
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.text.secondary)
                        }

                        Spacer()

                        Text("\(factor.impact > 0 ? "+" : "")\(factor.impact)%")
                            .font(DesignSystem.Typography.bodyEmphasized)
                            .foregroundColor(factor.impact > 0 ? DesignSystem.Colors.success : DesignSystem.Colors.warning)
                    }
                    .padding()
                    .background(DesignSystem.Colors.surface)
                    .cornerRadius(DesignSystem.Radius.medium)
                }
            }
        }
    }

    // MARK: - Recommendations

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("RECOMMENDATIONS")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(spacing: DesignSystem.Spacing.small) {
                ForEach(viewModel.recommendations, id: \.self) { recommendation in
                    InsightBanner(type: .recommendation, message: recommendation)
                }
            }
        }
    }
}

// MARK: - View Model

class ReadinessDetailViewModel: ObservableObject {
    @Published var readinessScore: Int = 78
    @Published var statusMessage: String = "Ready for high-intensity training"
    @Published var statusDetail: String = "Your body has recovered well from recent workouts"
    @Published var keyInsight: String? = "Your readiness is trending up - great recovery this week"

    // Trend
    @Published var last7Days: [Double] = [68, 71, 74, 72, 75, 76, 78]
    @Published var dayLabels: [String] = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    @Published var trendChange: Int = 10
    @Published var trendDirection: TrendDirection = .improving

    // Breakdown metrics
    @Published var hrvScore: Int = 65
    @Published var hrvChange: Double = 8.5
    @Published var hrvContribution: Double = 0.35

    @Published var sleepHours: Double = 7.8
    @Published var sleepChange: Double = 12.0
    @Published var sleepContribution: Double = 0.28

    @Published var restingHR: Int = 52
    @Published var restingHRChange: Double = -3.8
    @Published var restingHRContribution: Double = 0.22

    // Contributing factors
    @Published var contributingFactors: [ContributingFactor] = [
        ContributingFactor(title: "Sleep Quality", description: "7.8 hours of quality sleep", impact: 15),
        ContributingFactor(title: "Training Load", description: "Well managed this week", impact: 8),
        ContributingFactor(title: "Recovery Time", description: "48 hours since last workout", impact: 12),
        ContributingFactor(title: "Stress Levels", description: "Elevated yesterday", impact: -5)
    ]

    // Recommendations
    @Published var recommendations: [String] = [
        "You're ready for high-intensity intervals today",
        "Maintain 8+ hours of sleep to sustain this readiness",
        "Consider a recovery session if readiness drops below 70"
    ]

    var scoreColor: Color {
        if readinessScore >= 75 { return DesignSystem.Colors.success }
        if readinessScore >= 60 { return DesignSystem.Colors.warning }
        return DesignSystem.Colors.error
    }

    func loadData() async {
        // TODO: Load real data from Supabase/HealthKit
        // For now using mock data
    }
}

// MARK: - Supporting Types

enum TrendDirection {
    case improving
    case stable
    case declining

    var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }

    var text: String {
        switch self {
        case .improving: return "Improving"
        case .stable: return "Stable"
        case .declining: return "Declining"
        }
    }

    var color: Color {
        switch self {
        case .improving: return DesignSystem.Colors.success
        case .stable: return DesignSystem.Colors.warning
        case .declining: return DesignSystem.Colors.error
        }
    }
}

struct ContributingFactor: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let description: String
    let impact: Int // Percentage impact on readiness
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ReadinessDetailView()
    }
}
