import SwiftUI

/// Running Analytics Detail View - Deep dive into running performance
/// Storytelling: Shows pace evolution, volume trends, and session type breakdown
/// Design: Hero pace metric + trends + session insights + recommendations
struct RunningAnalyticsDetailView: View {
    @StateObject private var viewModel = RunningAnalyticsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.analyticsSectionSpacing) {
                // Hero running metric
                heroSection

                // Key insight
                if let insight = viewModel.keyInsight {
                    InsightBanner(type: .positive, message: insight)
                }

                // Pace trend (30 days)
                paceTrendSection

                // Weekly volume
                weeklyVolumeSection

                // Session type breakdown
                sessionBreakdownSection

                // Best performances
                bestPerformancesSection

                // Recent runs (detailed list)
                recentRunsSection

                // Recommendations
                recommendationsSection
            }
            .padding(.horizontal, DesignSystem.Spacing.screenHorizontal)
            .padding(.top, DesignSystem.Spacing.screenTop)
            .padding(.bottom, DesignSystem.Spacing.screenBottom)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle("Running Analytics")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            // Running icon
            Image(systemName: "figure.run")
                .font(.system(size: 64, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.primary)
                .padding(.vertical, DesignSystem.Spacing.medium)

            // Current average pace
            VStack(spacing: DesignSystem.Spacing.small) {
                Text("AVERAGE PACE (30 DAYS)")
                    .font(DesignSystem.Typography.footnoteEmphasized)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
                    .tracking(0.5)

                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.primary))
                        .padding(.vertical, 20)
                } else {
                    Text(viewModel.averagePace)
                        .font(DesignSystem.Typography.metricHero)
                        .foregroundColor(DesignSystem.Colors.primary)
                        .monospacedDigit()

                    // Improvement indicator (only show if we have data and improvement)
                    if viewModel.hasData && viewModel.paceImprovement != 0 {
                        HStack(spacing: DesignSystem.Spacing.xSmall) {
                            Image(systemName: viewModel.paceImprovement > 0 ? "arrow.down.right" : "arrow.up.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(viewModel.paceImprovement > 0 ? DesignSystem.Colors.success : DesignSystem.Colors.warning)

                            Text("\(abs(viewModel.paceImprovement))% \(viewModel.paceImprovement > 0 ? "faster" : "slower") than last month")
                                .font(DesignSystem.Typography.bodyEmphasized)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
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
                    Image(systemName: viewModel.paceTrend.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(viewModel.paceTrend.color)

                    Text(viewModel.paceTrend.text)
                        .font(DesignSystem.Typography.bodyEmphasized)
                        .foregroundColor(.white)
                }

                // Chart
                TrendLineChart(
                    dataPoints: viewModel.paceHistory,
                    labels: viewModel.dateLabels,
                    color: DesignSystem.Colors.primary,
                    height: 140
                )
                .padding(.top, DesignSystem.Spacing.small)
            }
            .padding(DesignSystem.Spacing.analyticsCardPadding)
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.Radius.large)
        }
    }

    // MARK: - Weekly Volume

    private var weeklyVolumeSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("WEEKLY VOLUME")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(spacing: DesignSystem.Spacing.analyticsBreakdownSpacing) {
                MetricBreakdownCard(
                    icon: "ruler",
                    iconColor: DesignSystem.Colors.primary,
                    title: "Total Distance",
                    value: viewModel.weeklyDistance,
                    unit: "km",
                    change: "+\(viewModel.distanceChange)%",
                    changeColor: DesignSystem.Colors.success,
                    contributionPercent: 0.5
                )

                MetricBreakdownCard(
                    icon: "clock.fill",
                    iconColor: DesignSystem.Colors.accent,
                    title: "Total Time",
                    value: viewModel.weeklyTime,
                    unit: "hrs",
                    change: "+\(viewModel.timeChange)%",
                    changeColor: DesignSystem.Colors.success,
                    contributionPercent: 0.35
                )

                MetricBreakdownCard(
                    icon: "flame.fill",
                    iconColor: DesignSystem.Colors.warning,
                    title: "Sessions",
                    value: "\(viewModel.weeklySessions)",
                    unit: "runs",
                    change: "+\(viewModel.sessionChange)",
                    changeColor: DesignSystem.Colors.success,
                    contributionPercent: 0.15
                )
            }
        }
    }

    // MARK: - Session Type Breakdown

    private var sessionBreakdownSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("SESSION TYPES")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(spacing: DesignSystem.Spacing.small) {
                ForEach(viewModel.sessionTypes) { session in
                    HStack(spacing: DesignSystem.Spacing.medium) {
                        // Session icon
                        ZStack {
                            Circle()
                                .fill(session.color.opacity(0.2))
                                .frame(width: 40, height: 40)

                            Image(systemName: session.icon)
                                .font(.system(size: 20))
                                .foregroundColor(session.color)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.name)
                                .font(DesignSystem.Typography.bodyEmphasized)
                                .foregroundColor(.white)

                            Text("\(session.count) sessions • \(session.avgPace) avg pace")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.text.secondary)
                        }

                        Spacer()

                        // Percentage
                        Text("\(session.percentage)%")
                            .font(DesignSystem.Typography.bodyEmphasized)
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                    }
                    .padding()
                    .background(DesignSystem.Colors.surface)
                    .cornerRadius(DesignSystem.Radius.medium)
                }
            }
        }
    }

    // MARK: - Best Performances

    private var bestPerformancesSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("RECENT BESTS")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(spacing: DesignSystem.Spacing.small) {
                ForEach(viewModel.bestPerformances) { best in
                    HStack(spacing: DesignSystem.Spacing.medium) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(best.title)
                                .font(DesignSystem.Typography.bodyEmphasized)
                                .foregroundColor(.white)

                            Text(best.date)
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.text.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(best.value)
                                .font(DesignSystem.Typography.heading3)
                                .foregroundColor(DesignSystem.Colors.primary)
                                .monospacedDigit()

                            if let improvement = best.improvement {
                                Text(improvement)
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.success)
                            }
                        }
                    }
                    .padding()
                    .background(DesignSystem.Colors.surface)
                    .cornerRadius(DesignSystem.Radius.medium)
                }
            }
        }
    }

    // MARK: - Recent Runs

    private var recentRunsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            HStack {
                Text("RECENT RUNS")
                    .font(DesignSystem.Typography.sectionHeader)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
                    .tracking(0.5)

                Spacer()

                NavigationLink(destination: RunningHistoryView()) {
                    HStack(spacing: 4) {
                        Text("View all")
                            .font(DesignSystem.Typography.subheadlineEmphasized)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                }
            }

            VStack(spacing: DesignSystem.Spacing.small) {
                ForEach(viewModel.recentRuns) { run in
                    NavigationLink(destination: RunDetailView(run: run)) {
                        RunCard(run: run)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    // MARK: - Recommendations

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("TO KEEP IMPROVING")
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

@MainActor
class RunningAnalyticsViewModel: ObservableObject {
    @Published var averagePace: String = "--:--"
    @Published var paceImprovement: Int = 0
    @Published var keyInsight: String? = nil
    @Published var isLoading: Bool = true
    @Published var hasData: Bool = false

    // Pace trend
    @Published var paceHistory: [Double] = []
    @Published var dateLabels: [String] = []
    @Published var paceTrend: TrendDirection = .stable

    // Weekly volume
    @Published var weeklyDistance: String = "0"
    @Published var distanceChange: Int = 0
    @Published var weeklyTime: String = "0"
    @Published var timeChange: Int = 0
    @Published var weeklySessions: Int = 0
    @Published var sessionChange: Int = 0

    // Session types (classified by pace)
    @Published var sessionTypes: [AnalyticsSessionType] = []

    // Best performances
    @Published var bestPerformances: [BestPerformance] = []

    // Recent runs
    @Published var recentRuns: [RecentRun] = []

    // Recommendations
    @Published var recommendations: [String] = []

    private let healthKitService = HealthKitService.shared

    func loadData() async {
        isLoading = true

        // Fetch running workouts from HealthKit (last 30 days)
        let allWorkouts = await healthKitService.fetchAllWorkouts(daysBack: 30)
        let runningWorkouts = allWorkouts.filter { $0.activityType == .running }
            .sorted { $0.date > $1.date }

        guard !runningWorkouts.isEmpty else {
            isLoading = false
            hasData = false
            keyInsight = "No running data yet - start logging runs to see your analytics"
            recommendations = [
                "Start with 2-3 easy runs per week to build your base",
                "Track your runs with Apple Watch or a running app",
                "Aim for consistent effort rather than speed initially"
            ]
            return
        }

        hasData = true

        // Calculate average pace (30 days)
        let workoutsWithPace = runningWorkouts.filter { $0.averagePace != nil }
        if !workoutsWithPace.isEmpty {
            let avgPaceSeconds = workoutsWithPace.reduce(0.0) { $0 + ($1.averagePace ?? 0) } / Double(workoutsWithPace.count)
            averagePace = formatPace(avgPaceSeconds)

            // Calculate pace improvement vs previous 30 days
            let previousWorkouts = await healthKitService.fetchAllWorkouts(daysBack: 60)
            let previousRunning = previousWorkouts.filter { workout in
                workout.activityType == .running &&
                workout.date < Calendar.current.date(byAdding: .day, value: -30, to: Date())!
            }
            let previousWithPace = previousRunning.filter { $0.averagePace != nil }

            if !previousWithPace.isEmpty {
                let previousAvgPace = previousWithPace.reduce(0.0) { $0 + ($1.averagePace ?? 0) } / Double(previousWithPace.count)
                if previousAvgPace > 0 {
                    let improvement = ((previousAvgPace - avgPaceSeconds) / previousAvgPace) * 100
                    paceImprovement = Int(improvement)
                }
            }
        }

        // Build pace history (last 15 runs with pace data)
        let recentWithPace = workoutsWithPace.prefix(15).reversed()
        paceHistory = recentWithPace.map { $0.averagePace ?? 0 }

        // Generate date labels
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d"
        dateLabels = recentWithPace.map { dateFormatter.string(from: $0.date) }

        // Determine pace trend
        if paceHistory.count >= 3 {
            let firstHalf = Array(paceHistory.prefix(paceHistory.count / 2))
            let secondHalf = Array(paceHistory.suffix(paceHistory.count / 2))
            let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
            let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)

            if secondAvg < firstAvg * 0.97 {
                paceTrend = .improving
            } else if secondAvg > firstAvg * 1.03 {
                paceTrend = .declining
            } else {
                paceTrend = .stable
            }
        }

        // Weekly volume - current week
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let thisWeekRuns = runningWorkouts.filter { $0.date >= weekStart }

        let weeklyDistanceKm = thisWeekRuns.reduce(0.0) { $0 + ($1.distanceKm ?? 0) }
        weeklyDistance = String(format: "%.1f", weeklyDistanceKm)

        let weeklyTimeHours = thisWeekRuns.reduce(0.0) { $0 + $1.duration } / 3600
        weeklyTime = String(format: "%.1f", weeklyTimeHours)

        weeklySessions = thisWeekRuns.count

        // Compare with previous week
        let previousWeekStart = calendar.date(byAdding: .day, value: -7, to: weekStart)!
        let previousWeekRuns = runningWorkouts.filter { $0.date >= previousWeekStart && $0.date < weekStart }

        if !previousWeekRuns.isEmpty {
            let prevDistance = previousWeekRuns.reduce(0.0) { $0 + ($1.distanceKm ?? 0) }
            if prevDistance > 0 {
                distanceChange = Int(((weeklyDistanceKm - prevDistance) / prevDistance) * 100)
            }

            let prevTime = previousWeekRuns.reduce(0.0) { $0 + $1.duration } / 3600
            if prevTime > 0 {
                timeChange = Int(((weeklyTimeHours - prevTime) / prevTime) * 100)
            }

            sessionChange = thisWeekRuns.count - previousWeekRuns.count
        }

        // Classify session types by pace
        classifySessionTypes(workoutsWithPace)

        // Best performances
        calculateBestPerformances(runningWorkouts)

        // Recent runs (last 5)
        recentRuns = runningWorkouts.prefix(5).map { workout in
            let runType = classifyRunType(workout)
            return RecentRun(
                date: workout.date,
                distance: workout.distanceKm ?? 0,
                duration: workout.formattedDuration,
                avgPace: workout.averagePace != nil ? formatPace(workout.averagePace!) : "--:--",
                type: runType,
                routeName: nil
            )
        }

        // Generate insights and recommendations
        generateInsightsAndRecommendations(runningWorkouts)

        isLoading = false
    }

    private func formatPace(_ secondsPerKm: Double) -> String {
        let minutes = Int(secondsPerKm) / 60
        let seconds = Int(secondsPerKm) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func classifyRunType(_ workout: ExternalWorkout) -> RecentRun.RunType {
        guard let pace = workout.averagePace else { return .zone2 }

        // Classify based on pace (rough estimates)
        // Fast: < 4:30/km (270 sec)
        // Medium: 4:30-5:30/km (270-330 sec)
        // Easy: > 5:30/km (330 sec)
        if pace < 270 {
            return .intervals
        } else if pace < 330 {
            return .racePace
        } else {
            return .zone2
        }
    }

    private func classifySessionTypes(_ workouts: [ExternalWorkout]) {
        var zone2Count = 0
        var racePaceCount = 0
        var intervalsCount = 0
        var zone2Paces: [Double] = []
        var racePacePaces: [Double] = []
        var intervalsPaces: [Double] = []

        for workout in workouts {
            guard let pace = workout.averagePace else { continue }

            let type = classifyRunType(workout)
            switch type {
            case .zone2:
                zone2Count += 1
                zone2Paces.append(pace)
            case .racePace:
                racePaceCount += 1
                racePacePaces.append(pace)
            case .intervals:
                intervalsCount += 1
                intervalsPaces.append(pace)
            }
        }

        let total = zone2Count + racePaceCount + intervalsCount
        guard total > 0 else { return }

        var types: [AnalyticsSessionType] = []

        if zone2Count > 0 {
            let avgPace = zone2Paces.reduce(0, +) / Double(zone2Paces.count)
            types.append(AnalyticsSessionType(
                icon: "tortoise.fill",
                name: "Zone 2 Easy",
                color: DesignSystem.Colors.zone2,
                count: zone2Count,
                avgPace: formatPace(avgPace),
                percentage: Int((Double(zone2Count) / Double(total)) * 100)
            ))
        }

        if racePaceCount > 0 {
            let avgPace = racePacePaces.reduce(0, +) / Double(racePacePaces.count)
            types.append(AnalyticsSessionType(
                icon: "hare.fill",
                name: "Race Pace",
                color: DesignSystem.Colors.primary,
                count: racePaceCount,
                avgPace: formatPace(avgPace),
                percentage: Int((Double(racePaceCount) / Double(total)) * 100)
            ))
        }

        if intervalsCount > 0 {
            let avgPace = intervalsPaces.reduce(0, +) / Double(intervalsPaces.count)
            types.append(AnalyticsSessionType(
                icon: "bolt.fill",
                name: "Intervals",
                color: DesignSystem.Colors.warning,
                count: intervalsCount,
                avgPace: formatPace(avgPace),
                percentage: Int((Double(intervalsCount) / Double(total)) * 100)
            ))
        }

        sessionTypes = types.sorted { $0.percentage > $1.percentage }
    }

    private func calculateBestPerformances(_ workouts: [ExternalWorkout]) {
        var bests: [BestPerformance] = []

        // Best pace
        if let fastest = workouts.filter({ $0.averagePace != nil }).min(by: { ($0.averagePace ?? 999) < ($1.averagePace ?? 999) }) {
            bests.append(BestPerformance(
                title: "Best avg pace",
                value: formatPace(fastest.averagePace!),
                date: formatRelativeDate(fastest.date),
                improvement: nil
            ))
        }

        // Longest run
        if let longest = workouts.filter({ $0.distanceKm != nil }).max(by: { ($0.distanceKm ?? 0) < ($1.distanceKm ?? 0) }) {
            bests.append(BestPerformance(
                title: "Longest run",
                value: String(format: "%.1f km", longest.distanceKm ?? 0),
                date: formatRelativeDate(longest.date),
                improvement: nil
            ))
        }

        // Longest duration
        if let longestTime = workouts.max(by: { $0.duration < $1.duration }) {
            let hours = Int(longestTime.duration) / 3600
            let minutes = (Int(longestTime.duration) % 3600) / 60
            let value = hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes) min"
            bests.append(BestPerformance(
                title: "Longest session",
                value: value,
                date: formatRelativeDate(longestTime.date),
                improvement: nil
            ))
        }

        bestPerformances = bests
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func generateInsightsAndRecommendations(_ workouts: [ExternalWorkout]) {
        var recs: [String] = []

        // Analyze training distribution
        let zone2Percentage = Double(sessionTypes.first(where: { $0.name == "Zone 2 Easy" })?.percentage ?? 0)

        if zone2Percentage < 60 {
            recs.append("Add more Zone 2 easy runs - aim for 70-80% of volume at easy pace")
        }

        if weeklySessions < 3 {
            recs.append("Try to run at least 3 times per week for consistent improvement")
        }

        if paceImprovement > 3 {
            keyInsight = "Your pace is improving - you're getting faster each month"
        } else if paceImprovement < -3 {
            keyInsight = "Your pace has slowed recently - consider more recovery or check for overtraining"
        } else if hasData {
            keyInsight = "Your running is consistent - keep building your base"
        }

        // Distance recommendations
        if let weeklyDist = Double(weeklyDistance), weeklyDist < 15 {
            recs.append("Gradually increase weekly distance to build endurance base")
        }

        // Add general recommendations if we have few specific ones
        if recs.count < 2 {
            recs.append("Mix up your training with different paces and distances")
            recs.append("Include one longer run per week for endurance")
        }

        recommendations = recs
    }
}

// MARK: - Supporting Types

struct AnalyticsSessionType: Identifiable, Hashable {
    let id = UUID()
    let icon: String
    let name: String
    let color: Color
    let count: Int
    let avgPace: String
    let percentage: Int
}

struct BestPerformance: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let value: String
    let date: String
    let improvement: String?
}

struct RecentRun: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let distance: Double
    let duration: String
    let avgPace: String
    let type: RunType
    let routeName: String?

    enum RunType {
        case zone2
        case racePace
        case intervals

        var color: Color {
            switch self {
            case .zone2: return DesignSystem.Colors.zone2
            case .racePace: return DesignSystem.Colors.primary
            case .intervals: return DesignSystem.Colors.warning
            }
        }

        var icon: String {
            switch self {
            case .zone2: return "tortoise.fill"
            case .racePace: return "hare.fill"
            case .intervals: return "bolt.fill"
            }
        }

        var name: String {
            switch self {
            case .zone2: return "Zone 2"
            case .racePace: return "Race Pace"
            case .intervals: return "Intervals"
            }
        }
    }

    var dateString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Run Card

struct RunCard: View {
    let run: RecentRun

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            // Type indicator
            ZStack {
                Circle()
                    .fill(run.type.color.opacity(0.2))
                    .frame(width: 48, height: 48)

                Image(systemName: run.type.icon)
                    .font(.system(size: 20))
                    .foregroundColor(run.type.color)
            }

            // Run info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(String(format: "%.1f km", run.distance))
                        .font(DesignSystem.Typography.bodyEmphasized)
                        .foregroundColor(.white)

                    Text("•")
                        .foregroundColor(DesignSystem.Colors.text.tertiary)

                    Text(run.type.name)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(run.type.color)
                }

                if let routeName = run.routeName {
                    Text(routeName)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }

                Text(run.dateString)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.text.tertiary)
            }

            Spacer()

            // Pace
            VStack(alignment: .trailing, spacing: 2) {
                Text(run.avgPace)
                    .font(DesignSystem.Typography.heading3)
                    .foregroundColor(DesignSystem.Colors.primary)
                    .monospacedDigit()

                Text("avg pace")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.text.tertiary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.text.tertiary)
        }
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.medium)
    }
}

// MARK: - Run Detail View (COMPREHENSIVE DATA VIEW)

struct RunDetailView: View {
    let run: RecentRun
    @StateObject private var viewModel = RunDetailViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.analyticsSectionSpacing) {
                // HERO STATS
                heroStatsSection

                // ROUTE MAP
                routeMapSection

                // PACE ANALYSIS (kilometer by kilometer)
                paceAnalysisSection

                // HEART RATE ZONES
                heartRateZonesSection

                // ELEVATION PROFILE
                elevationSection

                // SPLITS (detailed)
                splitsSection

                // PERFORMANCE METRICS
                performanceMetricsSection

                // CADENCE & STRIDE
                cadenceSection

                // POWER METRICS (if available)
                powerMetricsSection

                // WEATHER CONDITIONS
                weatherSection

                // PERSONAL RECORDS
                personalRecordsSection

                // COMPARISON TO PREVIOUS RUNS
                comparisonSection
            }
            .padding(.horizontal, DesignSystem.Spacing.screenHorizontal)
            .padding(.top, DesignSystem.Spacing.screenTop)
            .padding(.bottom, DesignSystem.Spacing.screenBottom)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle(run.routeName ?? "Run Details")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadData(for: run)
        }
    }

    // MARK: - Hero Stats

    private var heroStatsSection: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            // Distance
            Text(String(format: "%.2f km", run.distance))
                .font(DesignSystem.Typography.metricHeroLarge)
                .foregroundColor(DesignSystem.Colors.primary)

            // Main stats grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: DesignSystem.Spacing.medium) {
                RunningStatCard(label: "DURATION", value: run.duration)
                RunningStatCard(label: "AVG PACE", value: run.avgPace + "/km")
                RunningStatCard(label: "AVG HR", value: "156 bpm")
                RunningStatCard(label: "CALORIES", value: "485")
                RunningStatCard(label: "ELEVATION", value: "+45m")
                RunningStatCard(label: "CADENCE", value: "172 spm")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.large)
    }

    // MARK: - Route Map

    private var routeMapSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("ROUTE MAP")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)

            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                    .fill(DesignSystem.Colors.surface)
                    .frame(height: 250)

                VStack(spacing: 8) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 40))
                        .foregroundColor(DesignSystem.Colors.text.tertiary)
                    Text("TODO: MapKit integration")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text.tertiary)
                    Text("Show GPS route, start/finish markers, lap markers")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.text.tertiary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    // MARK: - Pace Analysis

    private var paceAnalysisSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("PACE ANALYSIS")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)

            // Pace graph (kilometer by kilometer)
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                    .fill(DesignSystem.Colors.surface)
                    .frame(height: 180)

                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 32))
                        .foregroundColor(DesignSystem.Colors.primary)
                    Text("TODO: Pace graph by kilometer")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                    Text("Show pace variation, fastest/slowest km, negative/positive splits")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.text.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }

            // Pace stats
            HStack(spacing: DesignSystem.Spacing.medium) {
                PaceStatCard(label: "Fastest km", value: "4:12", detail: "Km 3")
                PaceStatCard(label: "Slowest km", value: "5:02", detail: "Km 7")
                PaceStatCard(label: "Variability", value: "±8%", detail: "Consistent")
            }
        }
    }

    // MARK: - Heart Rate Zones

    private var heartRateZonesSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("HEART RATE ANALYSIS")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)

            // HR graph over time
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                    .fill(DesignSystem.Colors.surface)
                    .frame(height: 160)

                VStack(spacing: 8) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 32))
                        .foregroundColor(DesignSystem.Colors.error)
                    Text("TODO: HR graph over time")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }
            }

            // Zone breakdown
            VStack(spacing: DesignSystem.Spacing.small) {
                ZoneBar(zone: 1, percentage: 5, duration: "2:15", color: Color(hex: "4A90E2"))
                ZoneBar(zone: 2, percentage: 35, duration: "13:30", color: Color(hex: "50C878"))
                ZoneBar(zone: 3, percentage: 45, duration: "17:15", color: Color(hex: "FFB347"))
                ZoneBar(zone: 4, percentage: 12, duration: "4:36", color: Color(hex: "FF6B6B"))
                ZoneBar(zone: 5, percentage: 3, duration: "1:08", color: Color(hex: "C44569"))
            }
        }
    }

    // MARK: - Elevation

    private var elevationSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("ELEVATION PROFILE")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)

            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                    .fill(DesignSystem.Colors.surface)
                    .frame(height: 140)

                VStack(spacing: 8) {
                    Image(systemName: "mountain.2.fill")
                        .font(.system(size: 32))
                        .foregroundColor(DesignSystem.Colors.accent)
                    Text("TODO: Elevation chart")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }
            }

            HStack(spacing: DesignSystem.Spacing.medium) {
                ElevationStatCard(label: "Total Gain", value: "+45m")
                ElevationStatCard(label: "Total Loss", value: "-42m")
                ElevationStatCard(label: "Max Elevation", value: "128m")
            }
        }
    }

    // MARK: - Splits

    private var splitsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("KILOMETER SPLITS")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)

            VStack(spacing: DesignSystem.Spacing.xSmall) {
                RunningSplitRow(km: 1, time: "4:38", pace: "4:38", hr: 145)
                RunningSplitRow(km: 2, time: "9:22", pace: "4:44", hr: 152)
                RunningSplitRow(km: 3, time: "13:54", pace: "4:32", hr: 158)
                RunningSplitRow(km: 4, time: "18:42", pace: "4:48", hr: 161)
                RunningSplitRow(km: 5, time: "23:28", pace: "4:46", hr: 164)
                RunningSplitRow(km: 6, time: "28:20", pace: "4:52", hr: 167)
                RunningSplitRow(km: 7, time: "33:22", pace: "5:02", hr: 165)
                RunningSplitRow(km: 8, time: "38:04", pace: "4:42", hr: 162)
            }
        }
    }

    // MARK: - Performance Metrics

    private var performanceMetricsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("PERFORMANCE METRICS")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: DesignSystem.Spacing.small) {
                RunningMetricCard(label: "Training Load", value: "124", unit: "")
                RunningMetricCard(label: "Efficiency Factor", value: "1.42", unit: "")
                RunningMetricCard(label: "Running Power", value: "245W", unit: "avg")
                RunningMetricCard(label: "Ground Contact", value: "242ms", unit: "avg")
                RunningMetricCard(label: "Vertical Oscillation", value: "8.2cm", unit: "")
                RunningMetricCard(label: "Stride Length", value: "1.18m", unit: "avg")
            }
        }
    }

    // MARK: - Cadence

    private var cadenceSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("CADENCE & STRIDE")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)

            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                    .fill(DesignSystem.Colors.surface)
                    .frame(height: 140)

                VStack(spacing: 8) {
                    Image(systemName: "figure.run.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(DesignSystem.Colors.warning)
                    Text("TODO: Cadence graph over time")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }
            }

            HStack(spacing: DesignSystem.Spacing.medium) {
                RunningStatCard(label: "AVG CADENCE", value: "172 spm")
                RunningStatCard(label: "MAX CADENCE", value: "185 spm")
                RunningStatCard(label: "MIN CADENCE", value: "158 spm")
            }
        }
    }

    // MARK: - Power Metrics

    private var powerMetricsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("POWER METRICS")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)

            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                    .fill(DesignSystem.Colors.surface)
                    .frame(height: 140)

                VStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 32))
                        .foregroundColor(DesignSystem.Colors.warning)
                    Text("TODO: Running power graph")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                    Text("Show power zones, normalized power, variability index")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.text.tertiary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    // MARK: - Weather

    private var weatherSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("WEATHER CONDITIONS")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)

            HStack(spacing: DesignSystem.Spacing.large) {
                WeatherCard(icon: "thermometer", label: "Temperature", value: "18°C")
                WeatherCard(icon: "wind", label: "Wind", value: "12 km/h")
                WeatherCard(icon: "humidity.fill", label: "Humidity", value: "65%")
            }
        }
    }

    // MARK: - Personal Records

    private var personalRecordsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("PERSONAL RECORDS")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)

            VStack(spacing: DesignSystem.Spacing.small) {
                RunningPRCard(achievement: "🏆 Fastest 5K", value: "21:45", improvement: "Personal best!")
                RunningPRCard(achievement: "🎯 Best avg pace", value: "4:21/km", improvement: "2 sec faster")
            }
        }
    }

    // MARK: - Comparison

    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("COMPARISON TO PREVIOUS RUNS")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)

            VStack(spacing: DesignSystem.Spacing.small) {
                RunningComparisonCard(metric: "Avg Pace", current: run.avgPace, previous: "4:52", change: -5.2)
                RunningComparisonCard(metric: "Avg HR", current: "156 bpm", previous: "162 bpm", change: -3.7)
                RunningComparisonCard(metric: "Cadence", current: "172 spm", previous: "168 spm", change: 2.4)
            }
        }
    }
}

// MARK: - Supporting Views for RunDetailView

private struct RunningStatCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.text.secondary)
            Text(value)
                .font(DesignSystem.Typography.heading3)
                .foregroundColor(.white)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.medium)
    }
}

struct PaceStatCard: View {
    let label: String
    let value: String
    let detail: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.text.secondary)
            Text(value)
                .font(DesignSystem.Typography.heading3)
                .foregroundColor(DesignSystem.Colors.primary)
                .monospacedDigit()
            Text(detail)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.text.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.medium)
    }
}

struct ZoneBar: View {
    let zone: Int
    let percentage: Int
    let duration: String
    let color: Color

    var body: some View {
        HStack {
            Text("Z\(zone)")
                .font(DesignSystem.Typography.bodyEmphasized)
                .foregroundColor(.white)
                .frame(width: 32)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignSystem.Colors.surface)
                        .frame(height: 24)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(percentage) / 100, height: 24)
                }
            }
            .frame(height: 24)

            Text("\(percentage)%")
                .font(DesignSystem.Typography.bodyEmphasized)
                .foregroundColor(.white)
                .frame(width: 40)

            Text(duration)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .frame(width: 50)
        }
    }
}

struct ElevationStatCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.text.secondary)
            Text(value)
                .font(DesignSystem.Typography.heading3)
                .foregroundColor(DesignSystem.Colors.accent)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.medium)
    }
}

private struct RunningSplitRow: View {
    let km: Int
    let time: String
    let pace: String
    let hr: Int

    var body: some View {
        HStack {
            Text("KM \(km)")
                .font(DesignSystem.Typography.bodyEmphasized)
                .foregroundColor(.white)
                .frame(width: 60, alignment: .leading)

            Text(time)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .monospacedDigit()
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(pace)
                .font(DesignSystem.Typography.bodyEmphasized)
                .foregroundColor(DesignSystem.Colors.primary)
                .monospacedDigit()
                .frame(width: 60, alignment: .trailing)

            Text("\(hr)")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.error)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.small)
    }
}

private struct RunningMetricCard: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.text.secondary)
            HStack(spacing: 4) {
                Text(value)
                    .font(DesignSystem.Typography.heading3)
                    .foregroundColor(.white)
                if !unit.isEmpty {
                    Text(unit)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.text.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.medium)
    }
}

struct WeatherCard: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(DesignSystem.Colors.primary)
            Text(value)
                .font(DesignSystem.Typography.bodyEmphasized)
                .foregroundColor(.white)
            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.text.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.medium)
    }
}

private struct RunningPRCard: View {
    let achievement: String
    let value: String
    let improvement: String

    var body: some View {
        HStack {
            Text(achievement)
                .font(DesignSystem.Typography.bodyEmphasized)
                .foregroundColor(.white)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(DesignSystem.Typography.heading3)
                    .foregroundColor(DesignSystem.Colors.success)
                    .monospacedDigit()
                Text(improvement)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.success)
            }
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.medium)
    }
}

private struct RunningComparisonCard: View {
    let metric: String
    let current: String
    let previous: String
    let change: Double

    var body: some View {
        HStack {
            Text(metric)
                .font(DesignSystem.Typography.bodyEmphasized)
                .foregroundColor(.white)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(current)
                    .font(DesignSystem.Typography.bodyEmphasized)
                    .foregroundColor(.white)
                    .monospacedDigit()

                HStack(spacing: 4) {
                    Image(systemName: change < 0 ? "arrow.down" : "arrow.up")
                        .font(.system(size: 10))
                        .foregroundColor(change < 0 ? DesignSystem.Colors.success : DesignSystem.Colors.warning)

                    Text(String(format: "%.1f%%", abs(change)))
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(change < 0 ? DesignSystem.Colors.success : DesignSystem.Colors.warning)
                }
            }
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.medium)
    }
}

// MARK: - Run Detail View Model

class RunDetailViewModel: ObservableObject {
    func loadData(for run: RecentRun) async {
        // TODO: Load comprehensive run data from:
        // - HealthKitService (HR, cadence, power, etc.)
        // - LocationTrackingService (route, elevation, splits)
        // - RunningService (analysis, comparisons, PRs)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RunningAnalyticsDetailView()
    }
}
