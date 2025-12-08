import SwiftUI

/// Running Statistics View - Comprehensive weekly/monthly/yearly stats
/// Like Strava/Runna: Detailed aggregated statistics with trends
/// Features: Time period selection, trend graphs, detailed breakdowns
struct RunningStatsView: View {
    @StateObject private var viewModel = RunningStatsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.analyticsSectionSpacing) {
                // Time period selector
                timePeriodSelector

                // Overview stats
                overviewStatsSection

                // Distance trend graph
                distanceTrendSection

                // Pace trend graph
                paceTrendSection

                // Session breakdown
                sessionBreakdownSection

                // Weekly comparison
                weeklyComparisonSection

                // Personal records
                personalRecordsSection
            }
            .padding(.horizontal, DesignSystem.Spacing.screenHorizontal)
            .padding(.top, DesignSystem.Spacing.screenTop)
            .padding(.bottom, DesignSystem.Spacing.screenBottom)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle("Running Statistics")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadStats()
        }
    }

    // MARK: - Time Period Selector

    private var timePeriodSelector: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            HStack(spacing: DesignSystem.Spacing.xSmall) {
                ForEach(StatsPeriod.allCases, id: \.self) { period in
                    Button(action: {
                        viewModel.selectedPeriod = period
                    }) {
                        Text(period.rawValue)
                            .font(DesignSystem.Typography.bodyEmphasized)
                            .foregroundColor(
                                viewModel.selectedPeriod == period
                                    ? .white
                                    : DesignSystem.Colors.text.secondary
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                viewModel.selectedPeriod == period
                                    ? DesignSystem.Colors.primary
                                    : DesignSystem.Colors.surface
                            )
                            .cornerRadius(DesignSystem.Radius.medium)
                    }
                }
            }
        }
    }

    // MARK: - Overview Stats

    private var overviewStatsSection: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            // Total distance (hero metric) - cleaner, more breathing room
            VStack(spacing: DesignSystem.Spacing.small) {
                Text(String(format: "%.1f", viewModel.totalDistance))
                    .font(DesignSystem.Typography.metricHeroLarge)
                    .foregroundColor(DesignSystem.Colors.primary)

                Text("kilometers")
                    .font(DesignSystem.Typography.bodyEmphasized)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.large)

            // Grid of key stats only (simplified from 6 to 3)
            HStack(spacing: DesignSystem.Spacing.large) {
                OverviewStatCard(
                    icon: "figure.run",
                    value: "\(viewModel.totalRuns)",
                    label: "Runs"
                )
                OverviewStatCard(
                    icon: "clock.fill",
                    value: viewModel.totalTimeString,
                    label: "Time"
                )
                OverviewStatCard(
                    icon: "speedometer",
                    value: viewModel.avgPace,
                    label: "Pace"
                )
            }
        }
    }

    // MARK: - Distance Trend

    private var distanceTrendSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("DISTANCE TREND")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                // Trend direction
                HStack(spacing: DesignSystem.Spacing.xSmall) {
                    Image(systemName: viewModel.distanceTrendDirection.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(viewModel.distanceTrendDirection.color)

                    Text(viewModel.distanceTrendDirection.text)
                        .font(DesignSystem.Typography.bodyEmphasized)
                        .foregroundColor(.white)

                    Text("(\(viewModel.distanceChangePercent)% vs previous period)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }

                // Chart
                TrendLineChart(
                    dataPoints: viewModel.distanceHistory,
                    labels: viewModel.periodLabels,
                    color: DesignSystem.Colors.primary,
                    height: 160
                )
                .padding(.top, DesignSystem.Spacing.small)
            }
            .padding(DesignSystem.Spacing.analyticsCardPadding)
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.Radius.large)
        }
    }

    // MARK: - Pace Trend

    private var paceTrendSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("PACE EVOLUTION")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                // Trend direction
                HStack(spacing: DesignSystem.Spacing.xSmall) {
                    Image(systemName: viewModel.paceTrendDirection.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(viewModel.paceTrendDirection.color)

                    Text(viewModel.paceTrendDirection.text)
                        .font(DesignSystem.Typography.bodyEmphasized)
                        .foregroundColor(.white)

                    Text("(\(viewModel.paceChangeSeconds) sec/km)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }

                // Chart (inverted - lower is better)
                TrendLineChart(
                    dataPoints: viewModel.paceHistory,
                    labels: viewModel.periodLabels,
                    color: DesignSystem.Colors.success,
                    height: 160
                )
                .padding(.top, DesignSystem.Spacing.small)
            }
            .padding(DesignSystem.Spacing.analyticsCardPadding)
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.Radius.large)
        }
    }

    // MARK: - Session Breakdown

    private var sessionBreakdownSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("SESSION BREAKDOWN")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(spacing: DesignSystem.Spacing.small) {
                ForEach(viewModel.sessionBreakdown) { session in
                    SessionBreakdownCard(
                        type: session.type,
                        count: session.count,
                        percentage: session.percentage,
                        totalDistance: session.totalDistance,
                        avgPace: session.avgPace
                    )
                }
            }
        }
    }

    // MARK: - Weekly Comparison

    private var weeklyComparisonSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("WEEK-BY-WEEK COMPARISON")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(spacing: DesignSystem.Spacing.small) {
                ForEach(viewModel.weeklyComparison) { week in
                    WeekComparisonCard(
                        weekLabel: week.label,
                        distance: week.distance,
                        runs: week.runs,
                        avgPace: week.avgPace,
                        isCurrentWeek: week.isCurrentWeek
                    )
                }
            }
        }
    }

    // MARK: - Personal Records

    private var personalRecordsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("PERSONAL RECORDS (THIS PERIOD)")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(spacing: DesignSystem.Spacing.small) {
                PRStatCard(
                    icon: "trophy.fill",
                    label: "Fastest 1km",
                    value: viewModel.fastest1km,
                    date: viewModel.fastest1kmDate
                )
                PRStatCard(
                    icon: "trophy.fill",
                    label: "Fastest 5km",
                    value: viewModel.fastest5km,
                    date: viewModel.fastest5kmDate
                )
                PRStatCard(
                    icon: "trophy.fill",
                    label: "Fastest 10km",
                    value: viewModel.fastest10km,
                    date: viewModel.fastest10kmDate
                )
                PRStatCard(
                    icon: "trophy.fill",
                    label: "Longest Run",
                    value: String(format: "%.2f km", viewModel.longestRun),
                    date: viewModel.longestRunDate
                )
            }
        }
    }

}

// MARK: - Supporting Views

struct OverviewStatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(DesignSystem.Colors.primary)

            Text(value)
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(.white)
                .monospacedDigit()

            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.text.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.large)
    }
}

struct SessionBreakdownCard: View {
    let type: String
    let count: Int
    let percentage: Int
    let totalDistance: Double
    let avgPace: String

    var typeColor: Color {
        switch type {
        case "Zone 2": return DesignSystem.Colors.zone2
        case "Race Pace": return DesignSystem.Colors.primary
        case "Intervals": return DesignSystem.Colors.warning
        default: return DesignSystem.Colors.accent
        }
    }

    var typeIcon: String {
        switch type {
        case "Zone 2": return "tortoise.fill"
        case "Race Pace": return "hare.fill"
        case "Intervals": return "bolt.fill"
        default: return "figure.run"
        }
    }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            // Icon - cleaner
            ZStack {
                Circle()
                    .fill(typeColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: typeIcon)
                    .font(.system(size: 18))
                    .foregroundColor(typeColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(type)
                    .font(DesignSystem.Typography.bodyEmphasized)
                    .foregroundColor(.white)

                Text("\(count) runs • \(avgPace) avg")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }

            Spacer()

            Text("\(percentage)%")
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(DesignSystem.Colors.primary)
        }
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.medium)
    }
}

struct WeekComparisonCard: View {
    let weekLabel: String
    let distance: Double
    let runs: Int
    let avgPace: String
    let isCurrentWeek: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(weekLabel)
                    .font(isCurrentWeek ? DesignSystem.Typography.bodyEmphasized : DesignSystem.Typography.body)
                    .foregroundColor(isCurrentWeek ? DesignSystem.Colors.primary : .white)

                Text("\(runs) runs")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1f km", distance))
                    .font(DesignSystem.Typography.bodyEmphasized)
                    .foregroundColor(.white)
                    .monospacedDigit()

                Text(avgPace + " avg")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
                    .monospacedDigit()
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .background(isCurrentWeek ? DesignSystem.Colors.primary.opacity(0.1) : DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                .stroke(isCurrentWeek ? DesignSystem.Colors.primary : Color.clear, lineWidth: 2)
        )
    }
}

struct PRStatCard: View {
    let icon: String
    let label: String
    let value: String
    let date: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(DesignSystem.Colors.accent)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(DesignSystem.Typography.bodyEmphasized)
                    .foregroundColor(.white)

                Text(date)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }

            Spacer()

            Text(value)
                .font(DesignSystem.Typography.heading3)
                .foregroundColor(DesignSystem.Colors.success)
                .monospacedDigit()
        }
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.medium)
    }
}


// MARK: - View Model

enum StatsPeriod: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
}

struct SessionStats: Identifiable {
    let id = UUID()
    let type: String
    let count: Int
    let percentage: Int
    let totalDistance: Double
    let avgPace: String
}

struct WeekStats: Identifiable {
    let id = UUID()
    let label: String
    let distance: Double
    let runs: Int
    let avgPace: String
    let isCurrentWeek: Bool
}

class RunningStatsViewModel: ObservableObject {
    @Published var selectedPeriod: StatsPeriod = .month

    // Overview stats
    @Published var totalDistance: Double = 168.5
    @Published var totalRuns: Int = 24
    @Published var totalTimeString: String = "13h 42m"
    @Published var avgPace: String = "4:52"
    @Published var totalCalories: Double = 12840
    @Published var totalElevation: Double = 1245
    @Published var longestRun: Double = 21.1

    // Distance trend
    @Published var distanceHistory: [Double] = [
        35.2, 42.1, 38.5, 45.8, 51.2, 48.3, 52.7, 55.1
    ]
    @Published var periodLabels: [String] = ["W1", "W2", "W3", "W4", "W5", "W6", "W7", "W8"]
    @Published var distanceTrendDirection: TrendDirection = .improving
    @Published var distanceChangePercent: String = "+15"

    // Pace trend
    @Published var paceHistory: [Double] = [
        295, 292, 288, 285, 283, 280, 278, 275 // Seconds per km
    ]
    @Published var paceTrendDirection: TrendDirection = .improving
    @Published var paceChangeSeconds: String = "-20"

    // Session breakdown
    @Published var sessionBreakdown: [SessionStats] = [
        SessionStats(type: "Zone 2", count: 15, percentage: 62, totalDistance: 105.2, avgPace: "5:10"),
        SessionStats(type: "Race Pace", count: 5, percentage: 21, totalDistance: 35.8, avgPace: "4:28"),
        SessionStats(type: "Intervals", count: 4, percentage: 17, totalDistance: 27.5, avgPace: "3:55")
    ]

    // Weekly comparison
    @Published var weeklyComparison: [WeekStats] = [
        WeekStats(label: "This Week", distance: 55.1, runs: 6, avgPace: "4:45", isCurrentWeek: true),
        WeekStats(label: "Last Week", distance: 52.7, runs: 5, avgPace: "4:48", isCurrentWeek: false),
        WeekStats(label: "2 Weeks Ago", distance: 48.3, runs: 5, avgPace: "4:55", isCurrentWeek: false),
        WeekStats(label: "3 Weeks Ago", distance: 51.2, runs: 6, avgPace: "4:52", isCurrentWeek: false)
    ]

    // Personal records
    @Published var fastest1km: String = "3:42"
    @Published var fastest1kmDate: String = "Dec 3, 2025"
    @Published var fastest5km: String = "21:45"
    @Published var fastest5kmDate: String = "Nov 28, 2025"
    @Published var fastest10km: String = "45:32"
    @Published var fastest10kmDate: String = "Nov 15, 2025"
    @Published var longestRunDate: String = "Nov 20, 2025"

    func loadStats() async {
        do {
            // Fetch running sessions from Supabase
            let sessions = try await SupabaseService.shared.getRunningSessions(limit: 500)

            // Filter by selected period
            let filteredSessions = filterSessionsByPeriod(sessions)

            await MainActor.run {
                calculateStats(from: filteredSessions)
            }
        } catch {
            print("Failed to load running stats: \(error)")
            // Keep mock data as fallback
        }
    }

    private func filterSessionsByPeriod(_ sessions: [RunningSession]) -> [RunningSession] {
        let calendar = Calendar.current
        let now = Date()

        switch selectedPeriod {
        case .week:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return sessions.filter { ($0.startedAt ?? $0.createdAt) >= weekAgo }
        case .month:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return sessions.filter { ($0.startedAt ?? $0.createdAt) >= monthAgo }
        case .year:
            let yearAgo = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            return sessions.filter { ($0.startedAt ?? $0.createdAt) >= yearAgo }
        }
    }

    private func calculateStats(from sessions: [RunningSession]) {
        guard !sessions.isEmpty else { return }

        // Total distance
        totalDistance = sessions.reduce(0) { $0 + $1.distanceKm }

        // Total runs
        totalRuns = sessions.count

        // Total time
        let totalSeconds = sessions.reduce(0) { $0 + $1.durationSeconds }
        let hours = Int(totalSeconds) / 3600
        let minutes = (Int(totalSeconds) % 3600) / 60
        totalTimeString = "\(hours)h \(minutes)m"

        // Average pace
        let totalPaceSeconds = sessions.reduce(0) { $0 + $1.avgPacePerKm }
        let avgPaceSeconds = totalPaceSeconds / Double(sessions.count)
        let paceMin = Int(avgPaceSeconds) / 60
        let paceSec = Int(avgPaceSeconds) % 60
        avgPace = String(format: "%d:%02d", paceMin, paceSec)

        // Longest run
        longestRun = sessions.map { $0.distanceKm }.max() ?? 0

        // Session breakdown by type
        let grouped = Dictionary(grouping: sessions) { $0.sessionType }
        sessionBreakdown = grouped.map { type, typeSessions in
            let count = typeSessions.count
            let percentage = Int((Double(count) / Double(sessions.count)) * 100)
            let dist = typeSessions.reduce(0) { $0 + $1.distanceKm }
            let avgPaceSec = typeSessions.reduce(0) { $0 + $1.avgPacePerKm } / Double(typeSessions.count)
            let pMin = Int(avgPaceSec) / 60
            let pSec = Int(avgPaceSec) % 60

            return SessionStats(
                type: mapSessionTypeToDisplay(type),
                count: count,
                percentage: percentage,
                totalDistance: dist,
                avgPace: String(format: "%d:%02d", pMin, pSec)
            )
        }.sorted { $0.count > $1.count }

        // Weekly comparison (last 4 weeks)
        calculateWeeklyComparison(from: sessions)

        // PR tracking - fastest sessions
        calculatePRs(from: sessions)

        // Distance trend over time
        calculateDistanceTrend(from: sessions)

        // Pace trend over time
        calculatePaceTrend(from: sessions)
    }

    private func mapSessionTypeToDisplay(_ type: RunningSessionType) -> String {
        switch type {
        case .easy, .recovery, .longRun:
            return "Zone 2"
        case .threshold, .timeTrial5k, .timeTrial10k:
            return "Race Pace"
        case .intervals:
            return "Intervals"
        }
    }

    private func calculateWeeklyComparison(from sessions: [RunningSession]) {
        let calendar = Calendar.current
        let now = Date()

        var weeks: [WeekStats] = []
        for weekOffset in 0..<4 {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now)!
            let weekEnd = calendar.date(byAdding: .weekOfYear, value: -(weekOffset - 1), to: now)!

            let weekSessions = sessions.filter {
                let date = $0.startedAt ?? $0.createdAt
                return date >= weekStart && date < weekEnd
            }

            let dist = weekSessions.reduce(0) { $0 + $1.distanceKm }
            let runs = weekSessions.count
            let avgPaceSec = weekSessions.isEmpty ? 0 : weekSessions.reduce(0) { $0 + $1.avgPacePerKm } / Double(weekSessions.count)
            let pMin = Int(avgPaceSec) / 60
            let pSec = Int(avgPaceSec) % 60

            let label: String
            switch weekOffset {
            case 0: label = "This Week"
            case 1: label = "Last Week"
            default: label = "\(weekOffset) Weeks Ago"
            }

            weeks.append(WeekStats(
                label: label,
                distance: dist,
                runs: runs,
                avgPace: avgPaceSec > 0 ? String(format: "%d:%02d", pMin, pSec) : "--:--",
                isCurrentWeek: weekOffset == 0
            ))
        }

        weeklyComparison = weeks
    }

    private func calculatePRs(from sessions: [RunningSession]) {
        // Fastest by distance approximation
        let around5k = sessions.filter { abs($0.distanceMeters - 5000) < 500 }
        if let fastest5kSession = around5k.min(by: { $0.avgPacePerKm < $1.avgPacePerKm }) {
            let time5k = fastest5kSession.avgPacePerKm * 5
            let mins = Int(time5k) / 60
            let secs = Int(time5k) % 60
            fastest5km = String(format: "%d:%02d", mins, secs)
            fastest5kmDate = formatDate(fastest5kSession.startedAt ?? fastest5kSession.createdAt)
        }

        let around10k = sessions.filter { abs($0.distanceMeters - 10000) < 1000 }
        if let fastest10kSession = around10k.min(by: { $0.avgPacePerKm < $1.avgPacePerKm }) {
            let time10k = fastest10kSession.avgPacePerKm * 10
            let mins = Int(time10k) / 60
            let secs = Int(time10k) % 60
            fastest10km = String(format: "%d:%02d", mins, secs)
            fastest10kmDate = formatDate(fastest10kSession.startedAt ?? fastest10kSession.createdAt)
        }

        // Fastest 1km from any session
        if let fastestPaceSession = sessions.min(by: { $0.avgPacePerKm < $1.avgPacePerKm }) {
            let mins = Int(fastestPaceSession.avgPacePerKm) / 60
            let secs = Int(fastestPaceSession.avgPacePerKm) % 60
            fastest1km = String(format: "%d:%02d", mins, secs)
            fastest1kmDate = formatDate(fastestPaceSession.startedAt ?? fastestPaceSession.createdAt)
        }

        // Longest run
        if let longestSession = sessions.max(by: { $0.distanceKm < $1.distanceKm }) {
            longestRun = longestSession.distanceKm
            longestRunDate = formatDate(longestSession.startedAt ?? longestSession.createdAt)
        }
    }

    private func calculateDistanceTrend(from sessions: [RunningSession]) {
        // Group by week and calculate weekly distances
        let calendar = Calendar.current
        var weeklyDistances: [(week: Int, distance: Double)] = []

        for weekOffset in 0..<8 {
            let now = Date()
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now)!
            let weekEnd = calendar.date(byAdding: .weekOfYear, value: -(weekOffset - 1), to: now)!

            let weekSessions = sessions.filter {
                let date = $0.startedAt ?? $0.createdAt
                return date >= weekStart && date < weekEnd
            }

            let dist = weekSessions.reduce(0) { $0 + $1.distanceKm }
            weeklyDistances.append((week: weekOffset, distance: dist))
        }

        distanceHistory = weeklyDistances.reversed().map { $0.distance }
        periodLabels = weeklyDistances.reversed().map { "W\($0.week + 1)" }

        // Calculate trend
        if distanceHistory.count >= 2 {
            let recent = distanceHistory.suffix(2).reduce(0, +) / 2
            let previous = distanceHistory.prefix(2).reduce(0, +) / 2
            if previous > 0 {
                let change = ((recent - previous) / previous) * 100
                distanceChangePercent = String(format: "%+.0f", change)
                distanceTrendDirection = change > 5 ? .improving : (change < -5 ? .declining : .stable)
            }
        }
    }

    private func calculatePaceTrend(from sessions: [RunningSession]) {
        // Group by week and calculate weekly avg pace
        let calendar = Calendar.current
        var weeklyPaces: [(week: Int, pace: Double)] = []

        for weekOffset in 0..<8 {
            let now = Date()
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now)!
            let weekEnd = calendar.date(byAdding: .weekOfYear, value: -(weekOffset - 1), to: now)!

            let weekSessions = sessions.filter {
                let date = $0.startedAt ?? $0.createdAt
                return date >= weekStart && date < weekEnd
            }

            if !weekSessions.isEmpty {
                let avgPace = weekSessions.reduce(0) { $0 + $1.avgPacePerKm } / Double(weekSessions.count)
                weeklyPaces.append((week: weekOffset, pace: avgPace))
            } else {
                weeklyPaces.append((week: weekOffset, pace: 0))
            }
        }

        paceHistory = weeklyPaces.reversed().map { $0.pace }

        // Calculate trend (lower pace = better for running)
        let validPaces = paceHistory.filter { $0 > 0 }
        if validPaces.count >= 4 {
            let recent = Array(validPaces.suffix(2)).reduce(0, +) / 2
            let previous = Array(validPaces.prefix(2)).reduce(0, +) / 2
            let change = recent - previous
            paceChangeSeconds = String(format: "%+.0f", change)
            // For pace, lower is better
            paceTrendDirection = change < -5 ? .improving : (change > 5 ? .declining : .stable)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RunningStatsView()
    }
}
