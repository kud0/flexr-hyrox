import SwiftUI

/// Race Prediction Timeline View - Shows progression and future projection
/// Design: 90-day history + 30-day projection with insights on what's driving improvement
struct RacePredictionTimelineView: View {
    @StateObject private var viewModel = RacePredictionTimelineViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.analyticsSectionSpacing) {
                // Hero predicted time
                heroPredictionSection

                // Key insight
                if let insight = viewModel.keyInsight {
                    InsightBanner(type: .positive, message: insight)
                }

                // Timeline chart (90-day history + projection)
                timelineSection

                // Breakdown of contributing factors
                contributingFactorsSection

                // Station performance impact
                stationImpactSection

                // What's next
                nextStepsSection
            }
            .padding(.horizontal, DesignSystem.Spacing.screenHorizontal)
            .padding(.top, DesignSystem.Spacing.screenTop)
            .padding(.bottom, DesignSystem.Spacing.screenBottom)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle("Race Prediction")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Hero Prediction

    private var heroPredictionSection: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            // Current prediction
            VStack(spacing: DesignSystem.Spacing.small) {
                Text("PREDICTED HYROX TIME")
                    .font(DesignSystem.Typography.footnoteEmphasized)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
                    .tracking(0.5)

                Text(viewModel.predictedTime)
                    .font(DesignSystem.Typography.metricHero)
                    .foregroundColor(DesignSystem.Colors.primary)
                    .monospacedDigit()

                // Change indicator
                HStack(spacing: DesignSystem.Spacing.xSmall) {
                    Image(systemName: viewModel.isImproving ? "arrow.down.right" : "arrow.up.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(viewModel.isImproving ? DesignSystem.Colors.success : DesignSystem.Colors.warning)

                    Text("\(abs(viewModel.timeChangeMinutes)) min \(viewModel.isImproving ? "faster" : "slower") than last month")
                        .font(DesignSystem.Typography.bodyEmphasized)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.large)

            // Goal comparison
            if let goalTime = viewModel.goalTime {
                HStack(spacing: DesignSystem.Spacing.medium) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("YOUR GOAL")
                            .font(DesignSystem.Typography.footnoteEmphasized)
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                            .tracking(0.5)

                        Text(goalTime)
                            .font(DesignSystem.Typography.heading2)
                            .foregroundColor(.white)
                            .monospacedDigit()
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(viewModel.goalStatus.uppercased())
                            .font(DesignSystem.Typography.footnoteEmphasized)
                            .foregroundColor(viewModel.goalStatusColor)
                            .tracking(0.5)

                        Text("\(viewModel.minutesToGoal) min \(viewModel.isAheadOfGoal ? "ahead" : "behind")")
                            .font(DesignSystem.Typography.bodyEmphasized)
                            .foregroundColor(viewModel.goalStatusColor)
                    }
                }
                .padding(DesignSystem.Spacing.medium)
                .background(DesignSystem.Colors.surface)
                .cornerRadius(DesignSystem.Radius.medium)
            }
        }
    }

    // MARK: - Timeline Chart

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("90-DAY PROGRESSION")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                // Timeline visualization
                ZStack(alignment: .leading) {
                    // Background grid
                    VStack(spacing: 0) {
                        ForEach(0..<5) { _ in
                            Divider()
                                .background(DesignSystem.Colors.divider.opacity(0.3))
                                .padding(.vertical, 15)
                        }
                    }

                    // Actual timeline chart
                    TrendLineChart(
                        dataPoints: viewModel.historicalTimes + viewModel.projectedTimes,
                        labels: viewModel.timelineLabels,
                        color: DesignSystem.Colors.primary,
                        height: 180
                    )

                    // "Projection" label
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("PROJECTION")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.text.tertiary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(DesignSystem.Colors.surface.opacity(0.8))
                                .cornerRadius(4)
                                .padding(.trailing, 40)
                        }
                    }
                }
                .frame(height: 180)

                // Timeline labels
                HStack {
                    Text("90 days ago")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.text.secondary)

                    Spacer()

                    Text("Today")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.white)

                    Spacer()

                    Text("30 days")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.text.tertiary)
                }
            }
            .padding(DesignSystem.Spacing.analyticsCardPadding)
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.Radius.large)
        }
    }

    // MARK: - Contributing Factors

    private var contributingFactorsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("WHAT'S DRIVING YOUR IMPROVEMENT")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(spacing: DesignSystem.Spacing.analyticsBreakdownSpacing) {
                ForEach(viewModel.contributingFactors) { factor in
                    HStack(spacing: DesignSystem.Spacing.medium) {
                        // Icon
                        Image(systemName: factor.icon)
                            .font(.system(size: 24))
                            .foregroundColor(DesignSystem.Colors.primary)
                            .frame(width: 40)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(factor.title)
                                .font(DesignSystem.Typography.bodyEmphasized)
                                .foregroundColor(.white)

                            Text(factor.description)
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.text.secondary)
                        }

                        Spacer()

                        // Impact indicator
                        ContributionBar(
                            percentage: factor.contribution,
                            color: DesignSystem.Colors.success,
                            height: 8
                        )
                        .frame(width: 60)
                    }
                    .padding(DesignSystem.Spacing.medium)
                    .background(DesignSystem.Colors.surface)
                    .cornerRadius(DesignSystem.Radius.medium)
                }
            }
        }
    }

    // MARK: - Station Impact

    private var stationImpactSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("STATION PERFORMANCE IMPACT")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(spacing: DesignSystem.Spacing.small) {
                ForEach(viewModel.stationImpacts) { station in
                    HStack(spacing: DesignSystem.Spacing.medium) {
                        // Station emoji
                        Text(station.emoji)
                            .font(.system(size: 28))
                            .frame(width: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(station.name)
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(.white)

                            Text("\(station.timeImpact) sec impact on total time")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.text.secondary)
                        }

                        Spacer()

                        Text(station.change > 0 ? "+\(station.change)%" : "\(station.change)%")
                            .font(DesignSystem.Typography.bodyEmphasized)
                            .foregroundColor(station.change > 0 ? DesignSystem.Colors.success : DesignSystem.Colors.warning)
                    }
                    .padding()
                    .background(DesignSystem.Colors.surface)
                    .cornerRadius(DesignSystem.Radius.medium)
                }
            }
        }
    }

    // MARK: - Next Steps

    private var nextStepsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("TO REACH YOUR GOAL")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(spacing: DesignSystem.Spacing.small) {
                ForEach(viewModel.nextSteps, id: \.self) { step in
                    HStack(alignment: .top, spacing: DesignSystem.Spacing.small) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(DesignSystem.Colors.primary)

                        Text(step)
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

class RacePredictionTimelineViewModel: ObservableObject {
    @Published var predictedTime: String = "1:24" // h:mm format (no seconds)
    @Published var timeChangeMinutes: Int = 3
    @Published var isImproving: Bool = true
    @Published var keyInsight: String? = "You're on pace to beat your goal by 2 minutes - keep up the SkiErg work"

    // Goal
    @Published var goalTime: String? = "1:20" // h:mm format (no seconds)
    @Published var minutesToGoal: Int = 4
    @Published var isAheadOfGoal: Bool = false
    @Published var goalStatus: String = "Behind pace"

    // Timeline data (in minutes - converted for display)
    @Published var historicalTimes: [Double] = [
        92, 91, 90, 89.5, 89, 88.5, 88, 87.5, 87, 86.5, 86, 85.5, 85, 84.5
    ]
    @Published var projectedTimes: [Double] = [84.5, 84, 83.5, 83]
    @Published var timelineLabels: [String] = [
        "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""
    ] // 18 labels total (14 historical + 4 projected)

    // Contributing factors
    @Published var contributingFactors: [PredictionContributingFactor] = [
        PredictionContributingFactor(
            icon: "figure.run",
            title: "Running Pace",
            description: "8:15 min/km avg - improving steadily",
            contribution: 0.45
        ),
        PredictionContributingFactor(
            icon: "figure.strengthtraining.traditional",
            title: "Station Efficiency",
            description: "12% faster transitions",
            contribution: 0.30
        ),
        PredictionContributingFactor(
            icon: "arrow.3.trianglepath",
            title: "Training Consistency",
            description: "4 sessions per week for 8 weeks",
            contribution: 0.25
        )
    ]

    // Station impacts
    @Published var stationImpacts: [StationImpact] = [
        StationImpact(emoji: "🚣", name: "SkiErg", timeImpact: -45, change: 12),
        StationImpact(emoji: "🏃", name: "Run 1km", timeImpact: -20, change: 5),
        StationImpact(emoji: "🪂", name: "Sled Push", timeImpact: -15, change: 8),
        StationImpact(emoji: "🏋️", name: "Burpees", timeImpact: 10, change: -3)
    ]

    // Recommendations
    @Published var nextSteps: [String] = [
        "Shave 30 sec off SkiErg - focus on 500m splits",
        "Improve burpee efficiency - practice chest-to-floor form",
        "Maintain running volume at 4+ sessions per week",
        "Add one high-intensity interval session weekly"
    ]

    var goalStatusColor: Color {
        isAheadOfGoal ? DesignSystem.Colors.success : DesignSystem.Colors.warning
    }

    func loadData() async {
        // TODO: Load real data from WorkoutAnalyticsService
        // For now using mock data
    }
}

// MARK: - Supporting Types

struct PredictionContributingFactor: Identifiable, Hashable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let contribution: Double // 0-1 scale
}

struct StationImpact: Identifiable, Hashable {
    let id = UUID()
    let emoji: String
    let name: String
    let timeImpact: Int // Seconds saved (negative = faster)
    let change: Int // Percentage improvement
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RacePredictionTimelineView()
    }
}
