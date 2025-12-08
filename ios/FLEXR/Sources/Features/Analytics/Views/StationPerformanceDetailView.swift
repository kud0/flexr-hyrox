import SwiftUI

/// Station Performance Detail View - Deep dive into a single station
/// Shows: Performance trend, technique breakdown, improvement recommendations
/// Can show either improvement story or focus/weakness analysis
struct StationPerformanceDetailView: View {
    let stationName: String
    let emoji: String
    let mode: Mode

    @StateObject private var viewModel: StationPerformanceViewModel
    @Environment(\.dismiss) private var dismiss

    enum Mode {
        case improvement(percentImprovement: Int)
        case focus(improvementPotential: Int)
    }

    init(stationName: String, emoji: String, mode: Mode) {
        self.stationName = stationName
        self.emoji = emoji
        self.mode = mode
        self._viewModel = StateObject(wrappedValue: StationPerformanceViewModel(station: stationName, mode: mode))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.analyticsSectionSpacing) {
                // Hero section
                heroSection

                // Key insight
                if let insight = viewModel.keyInsight {
                    InsightBanner(type: modeInsightType, message: insight)
                }

                // 30-day trend
                trendSection

                // Performance breakdown
                breakdownSection

                // Technique analysis
                techniqueSection

                // Recommended drills
                drillsSection
            }
            .padding(.horizontal, DesignSystem.Spacing.screenHorizontal)
            .padding(.top, DesignSystem.Spacing.screenTop)
            .padding(.bottom, DesignSystem.Spacing.screenBottom)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle(stationName)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            // Station emoji
            Text(emoji)
                .font(.system(size: 80))
                .padding(.vertical, DesignSystem.Spacing.medium)

            // Performance metric
            VStack(spacing: DesignSystem.Spacing.small) {
                Text(modeTitle.uppercased())
                    .font(DesignSystem.Typography.footnoteEmphasized)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
                    .tracking(0.5)

                Text(heroMetric)
                    .font(DesignSystem.Typography.metricHeroLarge)
                    .foregroundColor(modeColor)

                Text(heroSubtitle)
                    .font(DesignSystem.Typography.insightMedium)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Trend Section

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("30-DAY PROGRESSION")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                // Trend direction
                HStack(spacing: DesignSystem.Spacing.xSmall) {
                    Image(systemName: viewModel.trendDirection.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(viewModel.trendDirection.color)

                    Text(viewModel.trendDirection.text)
                        .font(DesignSystem.Typography.bodyEmphasized)
                        .foregroundColor(.white)

                    Text("(\(viewModel.trendChange) sec)")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }

                // Chart
                TrendLineChart(
                    dataPoints: viewModel.last30Days,
                    labels: viewModel.dateLabels,
                    color: modeColor,
                    height: 140
                )
                .padding(.top, DesignSystem.Spacing.small)
            }
            .padding(DesignSystem.Spacing.analyticsCardPadding)
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.Radius.large)
        }
    }

    // MARK: - Breakdown Section

    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("PERFORMANCE BREAKDOWN")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(spacing: DesignSystem.Spacing.analyticsBreakdownSpacing) {
                ForEach(viewModel.performanceMetrics) { metric in
                    MetricBreakdownCard(
                        icon: metric.icon,
                        iconColor: metric.color,
                        title: metric.title,
                        value: metric.value,
                        unit: metric.unit,
                        change: metric.change,
                        changeColor: metric.changeColor,
                        contributionPercent: metric.contribution
                    )
                }
            }
        }
    }

    // MARK: - Technique Section

    private var techniqueSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text(mode.isFocus ? "WHAT'S HOLDING YOU BACK" : "WHAT'S WORKING")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(spacing: DesignSystem.Spacing.small) {
                ForEach(viewModel.techniquePoints) { point in
                    HStack(alignment: .top, spacing: DesignSystem.Spacing.medium) {
                        Image(systemName: point.icon)
                            .font(.system(size: 20))
                            .foregroundColor(point.isPositive ? DesignSystem.Colors.success : DesignSystem.Colors.warning)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(point.title)
                                .font(DesignSystem.Typography.bodyEmphasized)
                                .foregroundColor(.white)

                            Text(point.description)
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.text.secondary)
                        }

                        Spacer()
                    }
                    .padding(DesignSystem.Spacing.medium)
                    .background(DesignSystem.Colors.surface)
                    .cornerRadius(DesignSystem.Radius.medium)
                }
            }
        }
    }

    // MARK: - Drills Section

    private var drillsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text(mode.isFocus ? "DRILLS TO IMPROVE" : "KEEP PROGRESSING")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(spacing: DesignSystem.Spacing.small) {
                ForEach(viewModel.recommendedDrills) { drill in
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                        HStack(spacing: DesignSystem.Spacing.small) {
                            Text(drill.emoji)
                                .font(.system(size: 24))

                            Text(drill.name)
                                .font(DesignSystem.Typography.bodyEmphasized)
                                .foregroundColor(.white)

                            Spacer()
                        }

                        Text(drill.description)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.text.secondary)

                        // Protocol
                        HStack(spacing: DesignSystem.Spacing.xSmall) {
                            Image(systemName: "repeat")
                                .font(.system(size: 12))
                            Text(drill.protocol)
                                .font(DesignSystem.Typography.caption)
                        }
                        .foregroundColor(DesignSystem.Colors.primary)
                        .padding(.top, 4)
                    }
                    .padding(DesignSystem.Spacing.medium)
                    .background(DesignSystem.Colors.surface)
                    .cornerRadius(DesignSystem.Radius.medium)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var modeTitle: String {
        switch mode {
        case .improvement: return "Improvement"
        case .focus: return "Focus Area"
        }
    }

    private var heroMetric: String {
        switch mode {
        case .improvement(let percent): return "+\(percent)%"
        case .focus(let potential): return "\(potential)%"
        }
    }

    private var heroSubtitle: String {
        switch mode {
        case .improvement: return "faster this month"
        case .focus: return "improvement potential"
        }
    }

    private var modeColor: Color {
        switch mode {
        case .improvement: return DesignSystem.Colors.success
        case .focus: return DesignSystem.Colors.warning
        }
    }

    private var modeInsightType: InsightBanner.InsightType {
        switch mode {
        case .improvement: return .positive
        case .focus: return .recommendation
        }
    }
}

// MARK: - View Model

class StationPerformanceViewModel: ObservableObject {
    let stationName: String
    let mode: StationPerformanceDetailView.Mode

    @Published var keyInsight: String?
    @Published var last30Days: [Double] = []
    @Published var dateLabels: [String] = []
    @Published var trendChange: Int = 0
    @Published var trendDirection: TrendDirection = .improving

    @Published var performanceMetrics: [PerformanceMetric] = []
    @Published var techniquePoints: [TechniquePoint] = []
    @Published var recommendedDrills: [Drill] = []

    init(station: String, mode: StationPerformanceDetailView.Mode) {
        self.stationName = station
        self.mode = mode
    }

    func loadData() async {
        // Mock data based on mode
        switch mode {
        case .improvement:
            keyInsight = "Your \(stationName) time improved 12% - technique refinement is paying off"
            last30Days = [180, 178, 175, 173, 172, 170, 168, 165, 163, 160, 158, 155, 153, 150, 148]
            trendChange = -32 // Seconds faster
            trendDirection = .improving

            performanceMetrics = [
                PerformanceMetric(
                    icon: "timer",
                    color: DesignSystem.Colors.primary,
                    title: "Average Time",
                    value: "2:28",
                    unit: "min",
                    change: "-15%",
                    changeColor: DesignSystem.Colors.success,
                    contribution: 0.45
                ),
                PerformanceMetric(
                    icon: "bolt.fill",
                    color: DesignSystem.Colors.warning,
                    title: "Power Output",
                    value: "485",
                    unit: "W",
                    change: "+8%",
                    changeColor: DesignSystem.Colors.success,
                    contribution: 0.30
                ),
                PerformanceMetric(
                    icon: "arrow.left.arrow.right",
                    color: DesignSystem.Colors.accent,
                    title: "Stroke Rate",
                    value: "32",
                    unit: "spm",
                    change: "+5%",
                    changeColor: DesignSystem.Colors.success,
                    contribution: 0.25
                )
            ]

            techniquePoints = [
                TechniquePoint(
                    icon: "checkmark.circle.fill",
                    title: "Improved leg drive",
                    description: "You're generating more power from your legs, reducing upper body fatigue",
                    isPositive: true
                ),
                TechniquePoint(
                    icon: "checkmark.circle.fill",
                    title: "Consistent pacing",
                    description: "Your splits stay within 2 seconds throughout the workout",
                    isPositive: true
                ),
                TechniquePoint(
                    icon: "checkmark.circle.fill",
                    title: "Better recovery",
                    description: "You're maintaining power output deeper into workouts",
                    isPositive: true
                )
            ]

            recommendedDrills = [
                Drill(
                    emoji: "⚡",
                    name: "Power intervals",
                    description: "Short bursts at max effort to build explosive strength",
                    protocol: "10 x 30sec @ max effort, 90sec rest"
                ),
                Drill(
                    emoji: "🎯",
                    name: "Pace control",
                    description: "Maintain target split for entire duration",
                    protocol: "3 x 500m @ 2:20/500m, 2min rest"
                )
            ]

        case .focus:
            keyInsight = "Your \(stationName) is your weakest station - 20% improvement potential identified"
            last30Days = [195, 193, 192, 190, 192, 191, 193, 190, 188, 190, 189, 191, 188, 187, 185]
            trendChange = -10 // Small improvement
            trendDirection = .stable

            performanceMetrics = [
                PerformanceMetric(
                    icon: "timer",
                    color: DesignSystem.Colors.primary,
                    title: "Average Time",
                    value: "3:05",
                    unit: "min",
                    change: "-3%",
                    changeColor: DesignSystem.Colors.warning,
                    contribution: 0.35
                ),
                PerformanceMetric(
                    icon: "figure.strengthtraining.traditional",
                    color: DesignSystem.Colors.error,
                    title: "Technique Score",
                    value: "62",
                    unit: "/100",
                    change: "+2%",
                    changeColor: DesignSystem.Colors.warning,
                    contribution: 0.40
                ),
                PerformanceMetric(
                    icon: "heart.fill",
                    color: DesignSystem.Colors.accent,
                    title: "Avg Heart Rate",
                    value: "165",
                    unit: "bpm",
                    change: "-1%",
                    changeColor: DesignSystem.Colors.success,
                    contribution: 0.25
                )
            ]

            techniquePoints = [
                TechniquePoint(
                    icon: "exclamationmark.triangle.fill",
                    title: "Arm pull timing",
                    description: "You're pulling too early, losing leg power transfer",
                    isPositive: false
                ),
                TechniquePoint(
                    icon: "exclamationmark.triangle.fill",
                    title: "Inconsistent splits",
                    description: "Your pace varies by 8+ seconds between intervals",
                    isPositive: false
                ),
                TechniquePoint(
                    icon: "checkmark.circle.fill",
                    title: "Good endurance",
                    description: "You maintain effort well, just need better efficiency",
                    isPositive: true
                )
            ]

            recommendedDrills = [
                Drill(
                    emoji: "🎬",
                    name: "Slow motion technique",
                    description: "Practice perfect form at 50% speed to build muscle memory",
                    protocol: "5 x 1min @ slow pace, focus on leg-arm sequence"
                ),
                Drill(
                    emoji: "📐",
                    name: "Form drills",
                    description: "Legs only, then arms only, then combined - isolate movement patterns",
                    protocol: "3 rounds: 1min legs, 1min arms, 1min full stroke"
                ),
                Drill(
                    emoji: "🎯",
                    name: "Target splits",
                    description: "Build consistency by hitting exact split targets",
                    protocol: "5 x 200m @ 2:30/500m target, rest 90sec"
                )
            ]
        }

        // Generate date labels
        dateLabels = (0..<15).map { index in
            let dayNumber = 30 - (14 - index) * 2
            return "\(dayNumber)"
        }
    }
}

// MARK: - Supporting Types

struct PerformanceMetric: Identifiable {
    let id = UUID()
    let icon: String
    let color: Color
    let title: String
    let value: String
    let unit: String
    let change: String
    let changeColor: Color
    let contribution: Double
}

struct TechniquePoint: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let isPositive: Bool
}

struct Drill: Identifiable {
    let id = UUID()
    let emoji: String
    let name: String
    let description: String
    let `protocol`: String
}

extension StationPerformanceDetailView.Mode {
    var isFocus: Bool {
        if case .focus = self { return true }
        return false
    }
}

// MARK: - Preview

#Preview("Improvement") {
    NavigationStack {
        StationPerformanceDetailView(
            stationName: "SkiErg",
            emoji: "🚣",
            mode: .improvement(percentImprovement: 12)
        )
    }
}

#Preview("Focus") {
    NavigationStack {
        StationPerformanceDetailView(
            stationName: "Burpees",
            emoji: "🏋️",
            mode: .focus(improvementPotential: 20)
        )
    }
}
