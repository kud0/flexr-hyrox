import SwiftUI
import Charts

// MARK: - Running Workouts View
// Dedicated to standalone running workouts (Easy, Tempo, Intervals, Long runs)
// Separate from HYROX compromised running analysis

struct RunningWorkoutsView: View {
    @EnvironmentObject var healthKitService: HealthKitService
    @ObservedObject private var analyticsService = AnalyticsService.shared
    @State private var analyticsData: AnalyticsData?
    @State private var selectedTimeframe: Timeframe = .ninetyDays
    @State private var isImporting = false
    @State private var showImportSuccess = false
    @State private var runningSessions: [RunningSession] = []
    @State private var isLoading = false
    @State private var showAllRuns = false
    @State private var selectedSession: RunningSession?

    // Filter sessions to this week only (use startedAt for actual workout date)
    private var thisWeekSessions: [RunningSession] {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        return runningSessions.filter { ($0.startedAt ?? $0.createdAt) >= startOfWeek }
    }

    // Filter sessions from last week (7-14 days ago)
    private var lastWeekSessions: [RunningSession] {
        let calendar = Calendar.current
        let now = Date()
        let startOfLastWeek = calendar.date(byAdding: .day, value: -14, to: now) ?? now
        let endOfLastWeek = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        return runningSessions.filter {
            let date = $0.startedAt ?? $0.createdAt
            return date >= startOfLastWeek && date < endOfLastWeek
        }
    }

    enum Timeframe: String, CaseIterable {
        case sevenDays = "7d"
        case thirtyDays = "30d"
        case ninetyDays = "90d"
        case all = "All"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                // Header
                headerView

                // Import from Health button (shows when no data)
                if runningSessions.isEmpty && !isLoading {
                    importFromHealthCard
                }

                // This Week's Running (calculated from Supabase running sessions)
                ThisWeekRunningCardView(runningSessions: thisWeekSessions, lastWeekSessions: lastWeekSessions)

                // Recent runs from Supabase
                if !runningSessions.isEmpty {
                    recentRunsSection
                }

                // Stats Cards
                HStack(spacing: DesignSystem.Spacing.medium) {
                    WeeklyVolumeStatCard(runningSessions: thisWeekSessions)
                        .frame(height: 150)
                    Zone2PercentageCard(runningSessions: thisWeekSessions)
                        .frame(height: 150)
                }
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
        .alert("Import Complete", isPresented: $showImportSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Running workouts from Apple Health have been imported.")
        }
        .sheet(isPresented: $showAllRuns) {
            NavigationView {
                AllRunsListView()
            }
        }
        .sheet(item: $selectedSession) { session in
            NavigationView {
                RunningSessionDetailView(session: session)
            }
        }
    }

    private var importFromHealthCard: some View {
        MetricCard(title: "SYNC RUNNING DATA") {
            VStack(spacing: DesignSystem.Spacing.medium) {
                Image(systemName: "figure.run.circle")
                    .font(.system(size: 48))
                    .foregroundColor(DesignSystem.Colors.accent)

                Text("Import runs from Apple Health")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.text.primary)

                Text("Sync your running workouts to see detailed analytics including pace, distance, and heart rate data.")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    importFromHealth()
                } label: {
                    HStack {
                        if isImporting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.down.circle")
                        }
                        Text(isImporting ? "Importing..." : "Import from Health")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(DesignSystem.Colors.accent)
                    .cornerRadius(10)
                }
                .disabled(isImporting)
            }
            .padding(.vertical, 8)
        }
    }

    private var recentRunsSection: some View {
        VStack(spacing: 0) {
            // Header with "See All" button
            HStack {
                Text("RECENT RUNS")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Spacer()

                Button {
                    showAllRuns = true
                } label: {
                    HStack(spacing: 4) {
                        Text("See All")
                            .font(.system(size: 14, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(DesignSystem.Colors.accent)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.large)
            .padding(.top, DesignSystem.Spacing.large)
            .padding(.bottom, DesignSystem.Spacing.medium)

            // Runs list
            VStack(spacing: 0) {
                ForEach(runningSessions.prefix(5)) { session in
                    Button {
                        selectedSession = session
                    } label: {
                        HStack {
                            // Session type icon
                            Circle()
                                .fill(sessionTypeColor(for: session).opacity(0.2))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: session.sessionType.icon)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(sessionTypeColor(for: session))
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.sessionType.displayName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(DesignSystem.Colors.text.primary)
                                Text(relativeDate(for: session))
                                    .font(.system(size: 12))
                                    .foregroundColor(DesignSystem.Colors.text.secondary)
                            }
                            .padding(.leading, 8)

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(session.displayDistance)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(DesignSystem.Colors.text.primary)
                                Text(session.displayPace)
                                    .font(.system(size: 12))
                                    .foregroundColor(DesignSystem.Colors.accent)
                            }

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.text.tertiary)
                                .padding(.leading, 8)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, DesignSystem.Spacing.large)
                    }

                    if session.id != runningSessions.prefix(5).last?.id {
                        Divider()
                            .background(DesignSystem.Colors.divider)
                            .padding(.leading, 60)
                    }
                }
            }
            .padding(.bottom, DesignSystem.Spacing.medium)
        }
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.large)
    }

    private func sessionTypeColor(for session: RunningSession) -> Color {
        switch session.sessionType.color {
        case "blue": return DesignSystem.Colors.primary
        case "red": return DesignSystem.Colors.error
        case "orange": return DesignSystem.Colors.warning
        case "purple": return Color.purple
        case "green": return DesignSystem.Colors.success
        default: return DesignSystem.Colors.text.secondary
        }
    }

    private func relativeDate(for session: RunningSession) -> String {
        let calendar = Calendar.current
        let date = session.startedAt ?? session.createdAt

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let days = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
            if days < 7 {
                return "\(days) days ago"
            } else {
                return date.formatted(date: .abbreviated, time: .omitted)
            }
        }
    }

    private func importFromHealth() {
        isImporting = true
        Task {
            do {
                try await healthKitService.importRunningWorkouts(daysBack: 30)
                await MainActor.run {
                    isImporting = false
                    showImportSuccess = true
                    refreshData()
                }
            } catch {
                print("❌ Failed to import running workouts: \(error)")
                await MainActor.run {
                    isImporting = false
                }
            }
        }
    }

    private func refreshData() {
        isLoading = true

        // Fetch running sessions from Supabase
        Task {
            do {
                let sessions = try await SupabaseService.shared.getRunningSessionsFor(limit: 20)
                await MainActor.run {
                    runningSessions = sessions
                }
            } catch {
                print("⚠️ Failed to fetch running sessions: \(error)")
            }
            await MainActor.run {
                isLoading = false
            }
        }

        let timeframe: AnalyticsTimeframe = switch selectedTimeframe {
        case .sevenDays: .week
        case .thirtyDays: .month
        case .ninetyDays: .threeMonths
        case .all: .all
        }
        analyticsData = analyticsService.calculateAnalytics(timeframe: timeframe)
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("RUNNING WORKOUTS")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(1)

            HStack {
                Text("Training Runs")
                    .font(DesignSystem.Typography.largeTitle)
                    .foregroundColor(DesignSystem.Colors.text.primary)

                Spacer()

                // Timeframe Picker
                HStack(spacing: 0) {
                    ForEach(Timeframe.allCases, id: \.self) { timeframe in
                        Button {
                            withAnimation(DesignSystem.Animation.fast) {
                                selectedTimeframe = timeframe
                                refreshData()
                            }
                        } label: {
                            Text(timeframe.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(
                                    selectedTimeframe == timeframe
                                        ? DesignSystem.Colors.text.primary
                                        : DesignSystem.Colors.text.secondary
                                )
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    selectedTimeframe == timeframe
                                        ? DesignSystem.Colors.surface
                                        : Color.clear
                                )
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(2)
                .background(DesignSystem.Colors.backgroundSecondary)
                .cornerRadius(8)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - This Week's Running Card
struct ThisWeekRunningCardView: View {
    let runningSessions: [RunningSession]
    let lastWeekSessions: [RunningSession]
    let weeklyTargetKm: Double = 30.0

    // Computed stats from running sessions
    private var weeklyVolume: Double {
        runningSessions.reduce(0) { $0 + Double($1.distanceMeters) / 1000.0 }
    }

    private var lastWeekVolume: Double {
        lastWeekSessions.reduce(0) { $0 + Double($1.distanceMeters) / 1000.0 }
    }

    private var volumeChange: (percentage: Double, isPositive: Bool)? {
        guard lastWeekVolume > 0 else { return nil }
        let change = ((weeklyVolume - lastWeekVolume) / lastWeekVolume) * 100
        return (abs(change), change >= 0)
    }

    private var longestRun: Double {
        Double(runningSessions.max(by: { $0.distanceMeters < $1.distanceMeters })?.distanceMeters ?? 0) / 1000.0
    }

    private var averagePace: String {
        guard !runningSessions.isEmpty else { return "--:--" }
        let totalPace = runningSessions.reduce(0.0) { $0 + $1.avgPacePerKm }
        let avgPace = totalPace / Double(runningSessions.count)
        let mins = Int(avgPace) / 60
        let secs = Int(avgPace) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private var totalRunningTime: TimeInterval {
        runningSessions.reduce(0) { total, session in
            total + (session.heartRateZones?.totalTime ?? session.durationSeconds)
        }
    }

    private var trainingLoadStatus: (label: String, color: Color) {
        let hours = totalRunningTime / 3600
        if hours < 2 {
            return ("Low Load", DesignSystem.Colors.text.secondary)
        } else if hours < 4 {
            return ("Moderate", DesignSystem.Colors.primary)
        } else {
            return ("High Load", DesignSystem.Colors.warning)
        }
    }

    private var targetProgress: Double {
        min(weeklyVolume / weeklyTargetKm, 1.0)
    }

    private var progressBarColor: Color {
        if targetProgress < 0.5 {
            return DesignSystem.Colors.text.secondary.opacity(0.3)
        } else if targetProgress < 0.9 {
            return DesignSystem.Colors.primary
        } else {
            return DesignSystem.Colors.success
        }
    }

    // Zone distribution (Z1-Z2 vs Z3 vs Z4-Z5)
    private var zoneDistribution: (easy: Double, tempo: Double, hard: Double) {
        var totalEasy: TimeInterval = 0
        var totalTempo: TimeInterval = 0
        var totalHard: TimeInterval = 0
        var totalTime: TimeInterval = 0

        for session in runningSessions {
            if let zones = session.heartRateZones {
                totalEasy += zones.zone1Seconds + zones.zone2Seconds
                totalTempo += zones.zone3Seconds
                totalHard += zones.zone4Seconds + zones.zone5Seconds
                totalTime += zones.totalTime
            }
        }

        guard totalTime > 0 else { return (0, 0, 0) }

        return (
            totalEasy / totalTime,
            totalTempo / totalTime,
            totalHard / totalTime
        )
    }

    var body: some View {
        MetricCard(title: "THIS WEEK") {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                if !runningSessions.isEmpty {
                    // Total volume with comparison
                    HStack(alignment: .bottom, spacing: 8) {
                        Text("\(String(format: "%.1f", weeklyVolume))")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(DesignSystem.Colors.text.primary)
                            .monospacedDigit()

                        Text("km")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                            .padding(.bottom, 10)

                        Spacer()

                        // Week-over-week comparison
                        if let change = volumeChange {
                            HStack(spacing: 4) {
                                Image(systemName: change.isPositive ? "arrow.up" : "arrow.down")
                                    .font(.system(size: 12, weight: .bold))
                                Text("\(Int(change.percentage))%")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(change.isPositive ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                            .padding(.bottom, 10)
                        }
                    }

                    // Weekly target progress bar
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Weekly Target")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.text.secondary)
                            Spacer()
                            Text("\(String(format: "%.1f", weeklyVolume))/\(String(format: "%.0f", weeklyTargetKm))km")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(DesignSystem.Colors.text.secondary)
                                .monospacedDigit()
                        }

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(DesignSystem.Colors.backgroundSecondary)
                                    .frame(height: 8)

                                // Progress
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(progressBarColor)
                                    .frame(width: geometry.size.width * targetProgress, height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.bottom, 4)

                    // Training load status indicator
                    HStack(spacing: 6) {
                        Circle()
                            .fill(trainingLoadStatus.color)
                            .frame(width: 8, height: 8)
                        Text(trainingLoadStatus.label)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                        Text("•")
                            .foregroundColor(DesignSystem.Colors.text.tertiary)
                        Text("\(String(format: "%.1f", totalRunningTime / 3600))h")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                            .monospacedDigit()
                    }
                    .padding(.bottom, 8)

                    Divider()
                        .background(DesignSystem.Colors.divider)
                        .padding(.vertical, 4)

                    // Quick stats
                    HStack(spacing: DesignSystem.Spacing.large) {
                        quickStat(label: "Longest Run", value: "\(String(format: "%.1f", longestRun))km")
                        quickStat(label: "Avg Pace", value: averagePace)
                        quickStat(label: "Runs", value: "\(runningSessions.count)")
                    }

                    // Zone distribution breakdown
                    if zoneDistribution.easy + zoneDistribution.tempo + zoneDistribution.hard > 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            Divider()
                                .background(DesignSystem.Colors.divider)
                                .padding(.vertical, 4)

                            Text("ZONE DISTRIBUTION")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(DesignSystem.Colors.text.secondary)
                                .tracking(0.5)

                            // Stacked horizontal bar
                            GeometryReader { geometry in
                                HStack(spacing: 0) {
                                    if zoneDistribution.easy > 0 {
                                        Rectangle()
                                            .fill(DesignSystem.Colors.zone2)
                                            .frame(width: geometry.size.width * zoneDistribution.easy)
                                    }
                                    if zoneDistribution.tempo > 0 {
                                        Rectangle()
                                            .fill(DesignSystem.Colors.zone3)
                                            .frame(width: geometry.size.width * zoneDistribution.tempo)
                                    }
                                    if zoneDistribution.hard > 0 {
                                        Rectangle()
                                            .fill(DesignSystem.Colors.zone5)
                                            .frame(width: geometry.size.width * zoneDistribution.hard)
                                    }
                                }
                                .cornerRadius(4)
                            }
                            .frame(height: 12)

                            // Legend
                            HStack(spacing: 16) {
                                zoneLegendItem(color: DesignSystem.Colors.zone2, label: "Easy", percentage: zoneDistribution.easy)
                                zoneLegendItem(color: DesignSystem.Colors.zone3, label: "Tempo", percentage: zoneDistribution.tempo)
                                zoneLegendItem(color: DesignSystem.Colors.zone5, label: "Hard", percentage: zoneDistribution.hard)
                            }
                        }
                    }
                } else {
                    // Empty state
                    VStack(spacing: 12) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 48))
                            .foregroundColor(DesignSystem.Colors.text.secondary)

                        Text("No running data this week")
                            .font(DesignSystem.Typography.bodyEmphasized)
                            .foregroundColor(DesignSystem.Colors.text.secondary)

                        Text("Complete running workouts to track progress")
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

    private func quickStat(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.text.secondary)
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(DesignSystem.Colors.text.primary)
                .monospacedDigit()
        }
    }

    private func zoneLegendItem(color: Color, label: String, percentage: Double) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(DesignSystem.Colors.text.secondary)
            Text("\(Int(percentage * 100))%")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(DesignSystem.Colors.text.primary)
                .monospacedDigit()
        }
    }
}

// MARK: - Weekly Volume Stat Card
struct WeeklyVolumeStatCard: View {
    let runningSessions: [RunningSession]

    private var weeklyVolume: Double {
        runningSessions.reduce(0) { $0 + Double($1.distanceMeters) / 1000.0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("WEEKLY VOLUME")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            if !runningSessions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(String(format: "%.1f", weeklyVolume))")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.primary)
                        .monospacedDigit()

                    Text("kilometers")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 16)
            } else {
                Text("No data")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 32)
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.large)
    }
}

// MARK: - Zone 2 Percentage Card
struct Zone2PercentageCard: View {
    let runningSessions: [RunningSession]

    // Calculate Zone 1+2 percentage from heart rate zones
    private var zone2Percentage: Double {
        guard !runningSessions.isEmpty else { return 0 }

        var totalZ1Z2: TimeInterval = 0
        var totalTime: TimeInterval = 0

        for session in runningSessions {
            if let zones = session.heartRateZones {
                totalZ1Z2 += zones.zone1Seconds + zones.zone2Seconds
                totalTime += zones.totalTime
            }
        }

        guard totalTime > 0 else { return 0 }
        return (totalZ1Z2 / totalTime) * 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("ZONE 2 BASE")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            if !runningSessions.isEmpty && zone2Percentage > 0 {
                // Circular progress
                ZStack {
                    Circle()
                        .stroke(DesignSystem.Colors.backgroundSecondary, lineWidth: 12)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: CGFloat(zone2Percentage / 100))
                        .stroke(DesignSystem.Colors.zone2, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(Int(zone2Percentage))%")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(DesignSystem.Colors.text.primary)
                            .monospacedDigit()

                        Text("Z1-Z2")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                    }
                }
                .frame(maxWidth: .infinity)

                HStack {
                    Image(systemName: zone2Percentage >= 70 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundColor(zone2Percentage >= 70 ? DesignSystem.Colors.success : DesignSystem.Colors.warning)
                        .font(.system(size: 12))
                    Text(zone2Percentage >= 70 ? "Target met" : "Below target")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }
                .frame(maxWidth: .infinity)
            } else {
                Text("No HR data")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 32)
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.large)
    }
}

// MARK: - Preview
#Preview {
    RunningWorkoutsView()
}
