import SwiftUI

// MARK: - Recovery Analytics View
// Phase 5: Readiness Breakdown, Training Load, Sleep

struct RecoveryAnalyticsView: View {
    @ObservedObject private var analyticsService = AnalyticsService.shared
    @State private var analyticsData: AnalyticsData?
    @State private var selectedTimeframe: AnalyticsTimeframe = .week

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                // Header
                headerView

                // Today's Readiness Breakdown
                ReadinessBreakdownCardView(readiness: analyticsData?.readiness)

                // Training Load
                TrainingLoadCardView(trainingLoad: analyticsData?.trainingLoad)

                // Sleep summary
                SleepSummaryCardView()
            }
            .padding(.horizontal, DesignSystem.Spacing.large)
            .padding(.bottom, DesignSystem.Spacing.xxLarge)
        }
        .background(Color.black)
        .onAppear {
            refreshData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .workoutSaved)) { _ in
            refreshData()
        }
    }

    private func refreshData() {
        analyticsData = analyticsService.calculateAnalytics(timeframe: selectedTimeframe)
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("RECOVERY")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(1)

            Text("Readiness & Load")
                .font(DesignSystem.Typography.largeTitle)
                .foregroundColor(DesignSystem.Colors.text.primary)
        }
        .padding(.top, 8)
    }
}

// MARK: - Readiness Breakdown Card
struct ReadinessBreakdownCardView: View {
    let readiness: Readiness?

    var body: some View {
        MetricCard(title: "TODAY'S READINESS") {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                if let readiness = readiness {
                    // Main score
                    HStack {
                        ScoreBadge(score: readiness.readinessScore, size: 100)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 8) {
                            Text("READINESS SCORE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(DesignSystem.Colors.text.secondary)
                                .tracking(0.5)

                            Text("\(readiness.readinessScore)/100")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(DesignSystem.Colors.primary)
                                .monospacedDigit()
                        }
                    }

                    Divider()
                        .background(DesignSystem.Colors.divider)
                        .padding(.vertical, 4)

                    // Component breakdown
                    VStack(spacing: 0) {
                        componentRow(
                            label: "HRV",
                            value: "\(Int(readiness.hrvScore))ms",
                            vsBaseline: "Baseline",
                            impact: 85
                        )
                        componentRow(
                            label: "Resting HR",
                            value: "\(readiness.restingHeartRate) bpm",
                            vsBaseline: "Normal",
                            impact: 75
                        )
                        componentRow(
                            label: "Sleep Duration",
                            value: String(format: "%.1fh", readiness.sleepHours),
                            vsBaseline: "Target: 7-8h",
                            impact: 80
                        )
                        componentRow(
                            label: "Sleep Quality",
                            value: "-",
                            vsBaseline: "-",
                            impact: 70
                        )
                        componentRow(
                            label: "Training Load",
                            value: "Calculated",
                            vsBaseline: "✓",
                            impact: 90
                        )
                        componentRow(
                            label: "Days Since Hard",
                            value: "-",
                            vsBaseline: "-",
                            impact: 75,
                            isLast: true
                        )
                    }

                    // Recommendation
                    HStack(spacing: 8) {
                        Image(systemName: readiness.readinessScore >= 70 ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(readiness.readinessScore >= 70 ? DesignSystem.Colors.success : DesignSystem.Colors.warning)
                            .font(.system(size: 16))

                        Text(readiness.readinessScore >= 70 ? "Ready for training" : "Consider recovery focus")
                            .font(DesignSystem.Typography.bodyEmphasized)
                            .foregroundColor(DesignSystem.Colors.text.primary)
                    }
                    .padding(.top, 8)
                } else {
                    // Empty state
                    VStack(spacing: 12) {
                        Image(systemName: "heart.text.square")
                            .font(.system(size: 48))
                            .foregroundColor(DesignSystem.Colors.text.secondary)

                        Text("No readiness data yet")
                            .font(DesignSystem.Typography.bodyEmphasized)
                            .foregroundColor(DesignSystem.Colors.text.secondary)

                        Text("Complete workouts to track your recovery")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.text.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }
            }
        }
    }

    private func componentRow(
        label: String,
        value: String,
        vsBaseline: String,
        impact: Int,
        isLast: Bool = false
    ) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(DesignSystem.Colors.text.primary)
                    .frame(width: 110, alignment: .leading)

                Text(value)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.text.primary)
                    .monospacedDigit()
                    .frame(width: 70, alignment: .leading)

                Text(vsBaseline)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.success)
                    .frame(width: 60, alignment: .leading)

                Spacer()

                // Impact bar
                ProgressBar(
                    progress: Double(impact) / 100,
                    height: 6,
                    backgroundColor: DesignSystem.Colors.backgroundSecondary,
                    foregroundColor: DesignSystem.Colors.primary
                )
                .frame(width: 60)
            }
            .padding(.vertical, 10)

            if !isLast {
                Divider()
                    .background(DesignSystem.Colors.divider)
            }
        }
    }
}

// MARK: - Training Load Card
struct TrainingLoadCardView: View {
    let trainingLoad: TrainingLoad?

    var body: some View {
        MetricCard(title: "TRAINING LOAD MANAGEMENT") {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                if let trainingLoad = trainingLoad {
                    // Load stats
                    HStack(spacing: DesignSystem.Spacing.large) {
                        loadStat(label: "Weekly Target", value: String(format: "%.1fh", trainingLoad.weeklyTarget))
                        loadStat(label: "Current Week", value: String(format: "%.1fh", trainingLoad.currentWeekHours))
                        loadStat(
                            label: "Progress",
                            value: String(format: "%.0f%%", (trainingLoad.currentWeekHours / trainingLoad.weeklyTarget) * 100),
                            isGood: trainingLoad.currentWeekHours >= trainingLoad.weeklyTarget * 0.8
                        )
                    }

                    Divider()
                        .background(DesignSystem.Colors.divider)

                    // Status
                    HStack {
                        Image(systemName: trainingLoad.currentWeekHours >= trainingLoad.weeklyTarget * 0.8 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundColor(trainingLoad.currentWeekHours >= trainingLoad.weeklyTarget * 0.8 ? DesignSystem.Colors.success : DesignSystem.Colors.warning)
                            .font(.system(size: 16))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(trainingLoad.currentWeekHours >= trainingLoad.weeklyTarget ? "Weekly target met" : "Building towards target")
                                .font(DesignSystem.Typography.bodyEmphasized)
                                .foregroundColor(DesignSystem.Colors.text.primary)

                            Text("Target: \(String(format: "%.1f", trainingLoad.weeklyTarget))h weekly")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.text.secondary)
                        }
                    }
                } else {
                    // Empty state
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 48))
                            .foregroundColor(DesignSystem.Colors.text.secondary)

                        Text("No training load data")
                            .font(DesignSystem.Typography.bodyEmphasized)
                            .foregroundColor(DesignSystem.Colors.text.secondary)

                        Text("Start training to track your load")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.text.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }
            }
        }
    }

    private func loadStat(label: String, value: String, isGood: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.text.secondary)

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(isGood ? DesignSystem.Colors.success : DesignSystem.Colors.text.primary)
                .monospacedDigit()
        }
    }
}

// MARK: - Sleep Summary Card
struct SleepSummaryCardView: View {
    @EnvironmentObject var healthKitService: HealthKitService

    private var sleepData: [DailySleepData] {
        healthKitService.weeklySleepData
    }

    private var averageSleep: Double {
        guard !sleepData.isEmpty else { return 0 }
        return sleepData.map { $0.totalHours }.reduce(0, +) / Double(sleepData.count)
    }

    private var deepPercentage: Int {
        guard !sleepData.isEmpty else { return 0 }
        let totalSleep = sleepData.map { $0.totalHours }.reduce(0, +)
        let totalDeep = sleepData.map { $0.deepHours }.reduce(0, +)
        return totalSleep > 0 ? Int((totalDeep / totalSleep) * 100) : 0
    }

    private var isOptimalSleep: Bool {
        averageSleep >= 7.0 && averageSleep <= 9.0
    }

    var body: some View {
        MetricCard(title: "SLEEP ANALYSIS (LAST 7 NIGHTS)") {
            VStack(spacing: 0) {
                if sleepData.isEmpty {
                    // Empty state
                    VStack(spacing: 8) {
                        Image(systemName: "moon.zzz")
                            .font(.system(size: 32))
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                        Text("No sleep data available")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                        Text("Connect Apple Health to see your sleep")
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(DesignSystem.Colors.text.tertiary)
                    }
                    .padding(.vertical, 24)
                } else {
                    // Header
                    HStack {
                        Text("Night")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                            .frame(width: 40, alignment: .leading)

                        Text("Total")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                            .frame(width: 50, alignment: .trailing)

                        Text("Deep")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                            .frame(width: 50, alignment: .trailing)

                        Text("REM")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                            .frame(width: 50, alignment: .trailing)

                        Text("Quality")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                            .frame(width: 55, alignment: .trailing)
                    }
                    .padding(.bottom, 8)

                    Divider()
                        .background(DesignSystem.Colors.divider)

                    // Rows
                    ForEach(sleepData) { sleep in
                        sleepRow(sleep: sleep)
                        if sleep.id != sleepData.last?.id {
                            Divider()
                                .background(DesignSystem.Colors.divider)
                        }
                    }

                    Divider()
                        .background(DesignSystem.Colors.divider)
                        .padding(.top, 8)

                    // Summary
                    HStack {
                        Image(systemName: isOptimalSleep ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundColor(isOptimalSleep ? DesignSystem.Colors.success : DesignSystem.Colors.warning)
                            .font(.system(size: 14))

                        Text("Avg: \(String(format: "%.1fh", averageSleep)) • Optimal: 7-8h \(isOptimalSleep ? "✓" : "") • Deep%: \(deepPercentage)% (\(deepPercentage >= 13 && deepPercentage <= 23 ? "Good" : "Low"))")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.text.primary)
                    }
                    .padding(.top, 8)
                }
            }
        }
    }

    private func sleepRow(sleep: DailySleepData) -> some View {
        HStack {
            Text(sleep.dayName)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(DesignSystem.Colors.text.primary)
                .frame(width: 40, alignment: .leading)

            Text(sleep.formattedTotal)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(sleep.totalHours > 0 ? DesignSystem.Colors.text.primary : DesignSystem.Colors.text.tertiary)
                .monospacedDigit()
                .frame(width: 50, alignment: .trailing)

            Text(sleep.formattedDeep)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .monospacedDigit()
                .frame(width: 50, alignment: .trailing)

            Text(sleep.formattedRem)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .monospacedDigit()
                .frame(width: 50, alignment: .trailing)

            Text(sleep.quality > 0 ? "\(sleep.quality)%" : "-")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(qualityColor(for: sleep.quality))
                .monospacedDigit()
                .frame(width: 55, alignment: .trailing)
        }
        .padding(.vertical, 8)
    }

    private func qualityColor(for quality: Int) -> Color {
        if quality == 0 { return DesignSystem.Colors.text.tertiary }
        if quality >= 85 { return DesignSystem.Colors.success }
        if quality >= 70 { return DesignSystem.Colors.warning }
        return DesignSystem.Colors.error
    }
}

// MARK: - Preview
#Preview {
    RecoveryAnalyticsView()
}
