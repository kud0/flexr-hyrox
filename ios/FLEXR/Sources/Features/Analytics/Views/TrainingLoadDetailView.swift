import SwiftUI

/// Training Load Detail View - Deep dive into volume, intensity, and recovery balance
/// Storytelling: Shows if training load is sustainable, optimized, or needs adjustment
/// Design: Hero load metric + volume trends + intensity distribution + recovery insights
struct TrainingLoadDetailView: View {
    @StateObject private var viewModel = TrainingLoadViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.analyticsSectionSpacing) {
                // Hero load metric
                heroSection

                // Key insight
                if let insight = viewModel.keyInsight {
                    InsightBanner(type: viewModel.loadStatus.insightType, message: insight)
                }

                // Weekly load trend
                loadTrendSection

                // Volume vs Intensity breakdown
                volumeIntensitySection

                // Recovery status
                recoveryStatusSection

                // Training stress balance
                stressBalanceSection

                // Recommendations
                recommendationsSection
            }
            .padding(.horizontal, DesignSystem.Spacing.screenHorizontal)
            .padding(.top, DesignSystem.Spacing.screenTop)
            .padding(.bottom, DesignSystem.Spacing.screenBottom)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle("Training Load")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            // Load icon
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 64, weight: .semibold))
                .foregroundColor(viewModel.loadStatus.color)
                .padding(.vertical, DesignSystem.Spacing.medium)

            // Current load status
            VStack(spacing: DesignSystem.Spacing.small) {
                Text("TRAINING LOAD STATUS")
                    .font(DesignSystem.Typography.footnoteEmphasized)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
                    .tracking(0.5)

                Text(viewModel.loadStatus.title)
                    .font(DesignSystem.Typography.metricHero)
                    .foregroundColor(viewModel.loadStatus.color)

                Text(viewModel.loadStatus.subtitle)
                    .font(DesignSystem.Typography.bodyEmphasized)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Load Trend

    private var loadTrendSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("4-WEEK LOAD PROGRESSION")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                // Load trend chart
                TrendLineChart(
                    dataPoints: viewModel.weeklyLoad,
                    labels: viewModel.weekLabels,
                    color: viewModel.loadStatus.color,
                    height: 140
                )

                // Load change indicator
                HStack(spacing: DesignSystem.Spacing.xSmall) {
                    Image(systemName: viewModel.loadTrend.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(viewModel.loadTrend.color)

                    Text(viewModel.loadTrend.text)
                        .font(DesignSystem.Typography.bodyEmphasized)
                        .foregroundColor(.white)

                    Text("(\(viewModel.loadChangePercent)% vs last week)")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }
                .padding(.top, DesignSystem.Spacing.small)
            }
            .padding(DesignSystem.Spacing.analyticsCardPadding)
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.Radius.large)
        }
    }

    // MARK: - Volume vs Intensity

    private var volumeIntensitySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("VOLUME VS INTENSITY")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(spacing: DesignSystem.Spacing.analyticsBreakdownSpacing) {
                MetricBreakdownCard(
                    icon: "ruler",
                    iconColor: DesignSystem.Colors.primary,
                    title: "Weekly Volume",
                    value: viewModel.weeklyVolume,
                    unit: "hours",
                    change: "\(viewModel.volumeChange >= 0 ? "+" : "")\(viewModel.volumeChange)%",
                    changeColor: viewModel.volumeChange > 0 ? DesignSystem.Colors.success : DesignSystem.Colors.warning,
                    contributionPercent: 0.55
                )

                MetricBreakdownCard(
                    icon: "bolt.fill",
                    iconColor: DesignSystem.Colors.warning,
                    title: "Intensity Score",
                    value: "\(viewModel.intensityScore)",
                    unit: "/100",
                    change: "\(viewModel.intensityChange >= 0 ? "+" : "")\(viewModel.intensityChange)%",
                    changeColor: viewModel.intensityChange > 0 ? DesignSystem.Colors.warning : DesignSystem.Colors.success,
                    contributionPercent: 0.45
                )
            }

            // Volume/Intensity balance insight
            HStack(alignment: .top, spacing: DesignSystem.Spacing.medium) {
                Image(systemName: viewModel.balanceInsight.icon)
                    .font(.system(size: 18))
                    .foregroundColor(viewModel.balanceInsight.color)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.balanceInsight.title)
                        .font(DesignSystem.Typography.bodyEmphasized)
                        .foregroundColor(.white)

                    Text(viewModel.balanceInsight.description)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                        .lineLimit(2)
                }
            }
            .padding(DesignSystem.Spacing.medium)
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.Radius.medium)
        }
    }

    // MARK: - Recovery Status

    private var recoveryStatusSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("RECOVERY STATUS")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(spacing: DesignSystem.Spacing.small) {
                ForEach(viewModel.recoveryMetrics) { metric in
                    HStack(spacing: DesignSystem.Spacing.medium) {
                        // Metric icon - cleaner
                        ZStack {
                            Circle()
                                .fill(metric.color.opacity(0.15))
                                .frame(width: 36, height: 36)

                            Image(systemName: metric.icon)
                                .font(.system(size: 18))
                                .foregroundColor(metric.color)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(metric.title)
                                .font(DesignSystem.Typography.bodyEmphasized)
                                .foregroundColor(.white)

                            Text(metric.description)
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.text.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        // Status indicator
                        Text(metric.status)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(metric.statusColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(metric.statusColor.opacity(0.15))
                            .cornerRadius(4)
                    }
                    .padding(DesignSystem.Spacing.medium)
                    .background(DesignSystem.Colors.surface)
                    .cornerRadius(DesignSystem.Radius.medium)
                }
            }
        }
    }

    // MARK: - Stress Balance

    private var stressBalanceSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("TRAINING STRESS BALANCE")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                // Acute vs Chronic ratio
                HStack(spacing: DesignSystem.Spacing.medium) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ACUTE LOAD")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.text.secondary)

                        Text(viewModel.acuteLoad)
                            .font(DesignSystem.Typography.heading2)
                            .foregroundColor(.white)
                            .monospacedDigit()

                        Text("Last 7 days")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()
                        .frame(height: 60)

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("CHRONIC LOAD")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.text.secondary)

                        Text(viewModel.chronicLoad)
                            .font(DesignSystem.Typography.heading2)
                            .foregroundColor(.white)
                            .monospacedDigit()

                        Text("Last 28 days")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }

                Divider()
                    .padding(.vertical, DesignSystem.Spacing.small)

                // A:C ratio
                VStack(spacing: 8) {
                    HStack {
                        Text("ACUTE:CHRONIC RATIO")
                            .font(DesignSystem.Typography.footnoteEmphasized)
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                            .tracking(0.5)

                        Spacer()

                        Text(viewModel.acuteChronicRatio)
                            .font(DesignSystem.Typography.heading2)
                            .foregroundColor(viewModel.ratioColor)
                            .monospacedDigit()
                    }

                    Text(viewModel.ratioInterpretation)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(DesignSystem.Spacing.analyticsCardPadding)
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.Radius.large)
        }
    }

    // MARK: - Recommendations

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("LOAD MANAGEMENT TIPS")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(spacing: DesignSystem.Spacing.small) {
                ForEach(viewModel.recommendations, id: \.self) { recommendation in
                    HStack(alignment: .top, spacing: DesignSystem.Spacing.small) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(DesignSystem.Colors.primary)

                        Text(recommendation)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(.white)

                        Spacer()
                    }
                    .padding()
                    .background(DesignSystem.Colors.surface)
                    .cornerRadius(DesignSystem.Radius.medium)
                }
            }
        }
    }
}

// MARK: - View Model

class TrainingLoadViewModel: ObservableObject {
    @Published var loadStatus: LoadStatus = .balanced
    @Published var keyInsight: String? = "Your training load is perfectly balanced - sustainable progress without overreaching"

    // Load trend
    @Published var weeklyLoad: [Double] = [450, 480, 510, 520] // Training load units
    @Published var weekLabels: [String] = ["Week 1", "Week 2", "Week 3", "Week 4"]
    @Published var loadTrend: LoadTrendStatus = LoadTrendStatus(
        icon: "checkmark.circle.fill",
        text: "Well managed",
        color: DesignSystem.Colors.success
    )
    @Published var loadChangePercent: Int = 8

    // Volume vs Intensity
    @Published var weeklyVolume: String = "8.5"
    @Published var volumeChange: Int = 6
    @Published var intensityScore: Int = 72
    @Published var intensityChange: Int = 3

    @Published var balanceInsight = BalanceInsight(
        icon: "checkmark.circle.fill",
        color: DesignSystem.Colors.success,
        title: "Optimal balance",
        description: "Volume is increasing gradually while intensity stays controlled - ideal for sustainable progress"
    )

    // Recovery metrics
    @Published var recoveryMetrics: [RecoveryMetric] = [
        RecoveryMetric(
            icon: "heart.fill",
            color: DesignSystem.Colors.error,
            title: "HRV Recovery",
            description: "52ms average - trending up",
            status: "Good",
            statusColor: DesignSystem.Colors.success
        ),
        RecoveryMetric(
            icon: "bed.double.fill",
            color: DesignSystem.Colors.accent,
            title: "Sleep Quality",
            description: "7.5hrs average - consistent",
            status: "Good",
            statusColor: DesignSystem.Colors.success
        ),
        RecoveryMetric(
            icon: "figure.cooldown",
            color: DesignSystem.Colors.primary,
            title: "Fatigue Level",
            description: "Moderate - manageable",
            status: "Watch",
            statusColor: DesignSystem.Colors.warning
        )
    ]

    // Stress balance
    @Published var acuteLoad: String = "520"
    @Published var chronicLoad: String = "465"
    @Published var acuteChronicRatio: String = "1.12"
    @Published var ratioInterpretation: String = "Optimal range (0.8-1.3) - pushing fitness without overtraining"

    var ratioColor: Color {
        let ratio = Double(acuteChronicRatio) ?? 1.0
        if ratio >= 0.8 && ratio <= 1.3 {
            return DesignSystem.Colors.success
        } else if ratio > 1.3 {
            return DesignSystem.Colors.warning
        } else {
            return DesignSystem.Colors.accent
        }
    }

    // Recommendations
    @Published var recommendations: [String] = [
        "Continue gradual load increases (8-10% per week max)",
        "Keep intensity moderate this week - you're building good volume",
        "Schedule one complete rest day per week",
        "Your recovery metrics are good - current load is sustainable"
    ]

    func loadData() async {
        // Determine load status
        let ratio = Double(acuteChronicRatio) ?? 1.0
        if ratio >= 0.8 && ratio <= 1.3 {
            loadStatus = .balanced
            loadTrend = LoadTrendStatus(icon: "checkmark.circle.fill", text: "Well managed", color: DesignSystem.Colors.success)
        } else if ratio > 1.3 {
            loadStatus = .high
            loadTrend = LoadTrendStatus(icon: "exclamationmark.triangle.fill", text: "Monitor closely", color: DesignSystem.Colors.warning)
        } else {
            loadStatus = .low
            loadTrend = LoadTrendStatus(icon: "arrow.down.circle.fill", text: "Room to increase", color: DesignSystem.Colors.accent)
        }

        // TODO: Load real data from WorkoutAnalyticsService
    }
}

// MARK: - Supporting Types

enum LoadStatus {
    case balanced
    case high
    case low

    var title: String {
        switch self {
        case .balanced: return "Balanced"
        case .high: return "High"
        case .low: return "Low"
        }
    }

    var subtitle: String {
        switch self {
        case .balanced: return "Sustainable and progressive"
        case .high: return "Monitor recovery closely"
        case .low: return "Room to increase volume"
        }
    }

    var color: Color {
        switch self {
        case .balanced: return DesignSystem.Colors.success
        case .high: return DesignSystem.Colors.warning
        case .low: return DesignSystem.Colors.accent
        }
    }

    var insightType: InsightBanner.InsightType {
        switch self {
        case .balanced: return .positive
        case .high: return .warning
        case .low: return .recommendation
        }
    }
}

struct BalanceInsight: Identifiable, Hashable {
    let id = UUID()
    let icon: String
    let color: Color
    let title: String
    let description: String
}

struct RecoveryMetric: Identifiable, Hashable {
    let id = UUID()
    let icon: String
    let color: Color
    let title: String
    let description: String
    let status: String
    let statusColor: Color
}

struct LoadTrendStatus: Hashable {
    let icon: String
    let text: String
    let color: Color
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TrainingLoadDetailView()
    }
}
