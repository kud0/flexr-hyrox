import SwiftUI

// MARK: - Station Analytics View
// Phase 3: Station Overview, Strength/Weakness, Progress, Time Distribution

struct StationAnalyticsView: View {
    @ObservedObject private var analyticsService = AnalyticsService.shared
    @State private var analyticsData: AnalyticsData?
    @State private var selectedTimeframe: AnalyticsTimeframe = .week
    @State private var selectedStation: String = "SkiErg"

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                // Header
                headerView

                // Station Overview Table
                StationOverviewCardView(stations: analyticsData?.stationPerformance ?? [])

                // Strength vs Weakness
                StrengthWeaknessCardView(stations: analyticsData?.stationPerformance ?? [])

                // Time Distribution
                TimeDistributionCardView(timeDistribution: analyticsData?.timeDistribution)
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
            Text("STATIONS")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(1)

            Text("Performance")
                .font(DesignSystem.Typography.largeTitle)
                .foregroundColor(DesignSystem.Colors.text.primary)
        }
        .padding(.top, 8)
    }
}

// MARK: - Station Overview Card
struct StationOverviewCardView: View {
    let stations: [StationPerformance]

    var body: some View {
        MetricCard(title: "STATION OVERVIEW") {
            VStack(spacing: 0) {
                if !stations.isEmpty {
                    // Header row
                    HStack {
                        Text("Station")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                            .frame(width: 90, alignment: .leading)

                        Text("Best")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                            .frame(width: 50, alignment: .trailing)

                        Text("Avg")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                            .frame(width: 50, alignment: .trailing)

                        Text("vs Best")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                            .frame(width: 50, alignment: .trailing)

                        Text("Trend")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                            .frame(width: 50, alignment: .trailing)
                    }
                    .padding(.bottom, 12)

                    Divider()
                        .background(DesignSystem.Colors.divider)

                    // Station rows
                    ForEach(stations, id: \.stationName) { station in
                        stationRow(station: station)
                        if station.stationName != stations.last?.stationName {
                            Divider()
                                .background(DesignSystem.Colors.divider)
                        }
                    }

                    Divider()
                        .background(DesignSystem.Colors.divider)
                        .padding(.top, 8)

                    // Total row
                    let totalBest = stations.map { $0.bestTime }.reduce(0, +)
                    let totalAvg = stations.map { $0.averageTime }.reduce(0, +)
                    let totalDiff = totalAvg - totalBest

                    HStack {
                        Text("Total Stations")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(DesignSystem.Colors.text.primary)

                        Spacer()

                        Text(formatTime(totalBest))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(DesignSystem.Colors.primary)
                            .monospacedDigit()

                        Text(formatTime(totalAvg))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                            .monospacedDigit()
                            .frame(width: 50, alignment: .trailing)

                        Text("+\(Int(totalDiff))s")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                            .monospacedDigit()
                            .frame(width: 50, alignment: .trailing)
                    }
                    .padding(.top, 8)
                } else {
                    // Empty state
                    VStack(spacing: 12) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 48))
                            .foregroundColor(DesignSystem.Colors.text.secondary)

                        Text("No station data yet")
                            .font(DesignSystem.Typography.bodyEmphasized)
                            .foregroundColor(DesignSystem.Colors.text.secondary)

                        Text("Complete HYROX workouts to track stations")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.text.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }
            }
        }
    }

    private func stationRow(station: StationPerformance) -> some View {
        HStack {
            HStack(spacing: 6) {
                Text("🏋️")
                    .font(.system(size: 16))
                Text(station.stationName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.text.primary)
            }
            .frame(width: 90, alignment: .leading)

            Text(formatTime(station.bestTime))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(DesignSystem.Colors.text.primary)
                .monospacedDigit()
                .frame(width: 50, alignment: .trailing)

            Text(formatTime(station.averageTime))
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .monospacedDigit()
                .frame(width: 50, alignment: .trailing)

            let diff = Int(station.averageTime - station.bestTime)
            Text("+\(diff)s")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .monospacedDigit()
                .frame(width: 50, alignment: .trailing)

            Text(formatTrend(station.trend))
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(station.trend == .improving ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                .frame(width: 50, alignment: .trailing)
        }
        .padding(.vertical, 10)
    }

    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }

    private func formatTrend(_ trend: RacePrediction.Trend) -> String {
        switch trend {
        case .improving: return "▼"
        case .stable: return "→"
        case .declining: return "▲"
        }
    }
}

// MARK: - Strength vs Weakness Card
struct StrengthWeaknessCardView: View {
    let stations: [StationPerformance]

    private var strengths: [StationPerformance] {
        stations.sorted { $0.performanceScore > $1.performanceScore }.prefix(3).map { $0 }
    }

    private var weaknesses: [StationPerformance] {
        stations.sorted { $0.performanceScore < $1.performanceScore }.prefix(3).map { $0 }
    }

    var body: some View {
        MetricCard(title: "STRENGTH vs WEAKNESS") {
            if !stations.isEmpty {
                HStack(spacing: DesignSystem.Spacing.large) {
                    // Strengths
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                        Text("STRENGTHS (Top 3)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(DesignSystem.Colors.success)
                            .tracking(0.5)

                        ForEach(Array(strengths.enumerated()), id: \.element.stationName) { index, station in
                            strengthWeaknessRow(
                                rank: index + 1,
                                station: station,
                                isStrength: true
                            )
                        }

                        if strengths.count >= 2 {
                            Text("Strong performance\nin these stations")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.text.secondary)
                                .padding(.top, 4)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()
                        .background(DesignSystem.Colors.divider)

                    // Weaknesses
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                        Text("WEAKNESSES (Bottom 3)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(DesignSystem.Colors.error)
                            .tracking(0.5)

                        ForEach(Array(weaknesses.enumerated()), id: \.element.stationName) { index, station in
                            strengthWeaknessRow(
                                rank: index + 1,
                                station: station,
                                isStrength: false
                            )
                        }

                        if weaknesses.count >= 2 {
                            Text("Focus training\non these areas")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.text.secondary)
                                .padding(.top, 4)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 48))
                        .foregroundColor(DesignSystem.Colors.text.secondary)

                    Text("No strength/weakness data")
                        .font(DesignSystem.Typography.bodyEmphasized)
                        .foregroundColor(DesignSystem.Colors.text.secondary)

                    Text("Complete more workouts for analysis")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.text.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            }
        }
    }

    private func strengthWeaknessRow(
        rank: Int,
        station: StationPerformance,
        isStrength: Bool
    ) -> some View {
        HStack(spacing: 8) {
            Text("\(rank).")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .frame(width: 20)

            Text(station.stationName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(DesignSystem.Colors.text.primary)

            Spacer()

            ScoreBadge(score: station.performanceScore, size: 36)
        }
    }
}

// MARK: - Time Distribution Card
struct TimeDistributionCardView: View {
    let timeDistribution: TimeDistribution?

    var body: some View {
        MetricCard(title: "TIME DISTRIBUTION (RACE SIMULATION)") {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                if let data = timeDistribution {
                    Text("Where you spend your time in workouts:")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.text.secondary)

                    // Main distribution
                    distributionBar(label: "Running", percentage: data.runningPercentage, color: DesignSystem.Colors.running)
                    distributionBar(label: "Stations", percentage: data.stationsPercentage, color: DesignSystem.Colors.warning)
                    distributionBar(label: "Transition", percentage: data.transitionsPercentage, color: DesignSystem.Colors.text.secondary)
                } else {
                    // Empty state
                    VStack(spacing: 12) {
                        Image(systemName: "chart.pie")
                            .font(.system(size: 48))
                            .foregroundColor(DesignSystem.Colors.text.secondary)

                        Text("No time distribution data")
                            .font(DesignSystem.Typography.bodyEmphasized)
                            .foregroundColor(DesignSystem.Colors.text.secondary)

                        Text("Complete workouts to see distribution")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.text.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }
            }
        }
    }

    private func distributionBar(label: String, percentage: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.text.primary)

                Spacer()

                Text("\(Int(percentage))%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.text.primary)
                    .monospacedDigit()
            }

            ProgressBar(
                progress: percentage / 100,
                height: 24,
                backgroundColor: DesignSystem.Colors.backgroundSecondary,
                foregroundColor: color
            )
        }
    }
}

// MARK: - Preview
#Preview {
    StationAnalyticsView()
}
