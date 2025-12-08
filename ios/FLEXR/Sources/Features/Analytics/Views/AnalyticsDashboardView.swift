import SwiftUI

// MARK: - Main Analytics Dashboard
// Phase 1: Readiness, Race Time, Training Load, Quick Stats

struct AnalyticsDashboardView: View {
    @EnvironmentObject var healthKitService: HealthKitService
    @State private var selectedTimeframe: Timeframe = .week
    @State private var analyticsData: AnalyticsData?
    @ObservedObject private var analyticsService = AnalyticsService.shared

    enum Timeframe: String, CaseIterable {
        case today = "Today"
        case week = "Week"
        case all = "All"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                // Header with timeframe selector
                headerView

                if let data = analyticsData {
                    // Readiness and Race Time Cards (side by side)
                    HStack(spacing: DesignSystem.Spacing.medium) {
                        ReadinessCardView(data: data.readiness)
                            .frame(height: 280)
                        PredictedRaceTimeCardView(data: data.racePrediction)
                            .frame(height: 280)
                    }

                    // Weekly Training Load Card
                    WeeklyTrainingLoadCardView(data: data.trainingLoad)

                    // Quick Stats Grid
                    QuickStatsGridView(data: data.quickStats)
                } else {
                    // Loading or empty state
                    VStack(spacing: 16) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.system(size: 56))
                            .foregroundColor(DesignSystem.Colors.text.secondary)

                        Text("No analytics data yet")
                            .font(DesignSystem.Typography.title2)
                            .foregroundColor(DesignSystem.Colors.text.primary)

                        Text("Complete workouts to see your performance analytics")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 64)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.large)
            .padding(.bottom, DesignSystem.Spacing.xxLarge)
        }
        .background(Color.black)
        .onAppear {
            refreshAnalytics()
        }
        .onChange(of: selectedTimeframe) { _ in
            refreshAnalytics()
        }
        .onReceive(NotificationCenter.default.publisher(for: .workoutSaved)) { _ in
            refreshAnalytics()
        }
    }

    private func refreshAnalytics() {
        // Update HealthKit cache before calculating analytics
        let sleepHours: Double? = healthKitService.sleepAnalysis.map { $0.totalDuration / 3600.0 }
        analyticsService.updateHealthKitCache(
            hrv: healthKitService.heartRateVariability,
            sleepHours: sleepHours,
            restingHR: healthKitService.restingHeartRate,
            readinessScore: healthKitService.calculateReadinessScore()
        )

        // Fetch running sessions for pace/HR zones (async)
        Task {
            await fetchRunningSessionData()
        }

        let timeframe: AnalyticsTimeframe
        switch selectedTimeframe {
        case .today:
            timeframe = .week // Use week for "today" as well
        case .week:
            timeframe = .week
        case .all:
            timeframe = .all
        }

        analyticsData = analyticsService.calculateAnalytics(timeframe: timeframe)
    }

    /// Fetch running session data from Supabase and update cache
    private func fetchRunningSessionData() async {
        do {
            let sessions = try await SupabaseService.shared.getRunningSessionsFor(limit: 50)

            // Extract all split paces
            var allSplitPaces: [TimeInterval] = []
            var aggregatedHRZones: HeartRateZones?

            for session in sessions {
                // Collect split paces
                if let splits = session.splits {
                    allSplitPaces.append(contentsOf: splits.map { $0.pacePerKm })
                } else {
                    // Use average pace if no splits available
                    allSplitPaces.append(session.avgPacePerKm)
                }

                // Aggregate HR zones (use latest session with HR data)
                if aggregatedHRZones == nil, let hrZones = session.heartRateZones {
                    aggregatedHRZones = hrZones
                }
            }

            // Update cache on main thread
            await MainActor.run {
                analyticsService.updateRunningCache(
                    splits: allSplitPaces,
                    heartRateZones: aggregatedHRZones
                )
                // Recalculate analytics with new cache data
                let timeframe: AnalyticsTimeframe = selectedTimeframe == .all ? .all : .week
                analyticsData = analyticsService.calculateAnalytics(timeframe: timeframe)
            }
        } catch {
            print("⚠️ Failed to fetch running sessions for analytics: \(error)")
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("PERFORMANCE")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(1)

            HStack {
                Text("Analytics")
                    .font(DesignSystem.Typography.largeTitle)
                    .foregroundColor(DesignSystem.Colors.text.primary)

                Spacer()

                // Timeframe Picker
                HStack(spacing: 0) {
                    ForEach(Timeframe.allCases, id: \.self) { timeframe in
                        Button {
                            withAnimation(DesignSystem.Animation.fast) {
                                selectedTimeframe = timeframe
                            }
                        } label: {
                            Text(timeframe.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(
                                    selectedTimeframe == timeframe
                                        ? DesignSystem.Colors.text.primary
                                        : DesignSystem.Colors.text.secondary
                                )
                                .padding(.horizontal, 12)
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

// MARK: - Readiness Card
struct ReadinessCardView: View {
    let data: Readiness

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("READINESS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            ScoreBadge(score: data.readinessScore, size: 80)

            VStack(alignment: .leading, spacing: 6) {
                metricRow(
                    icon: "heart.fill",
                    label: "HRV",
                    value: "\(data.hrvScore)ms",
                    change: "+5%"
                )
                metricRow(
                    icon: "bed.double.fill",
                    label: "Sleep",
                    value: String(format: "%.1fh", data.sleepHours)
                )
                metricRow(
                    icon: "heart.circle.fill",
                    label: "RHR",
                    value: "\(data.restingHeartRate) bpm"
                )
            }

            Spacer()
        }
        .padding(DesignSystem.Spacing.medium)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.large)
    }

    private func metricRow(icon: String, label: String, value: String, change: String? = nil) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: 16)

            Text(label)
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.text.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.text.primary)

            if let change = change {
                Text(change)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.success)
            }
        }
    }
}

// MARK: - Predicted Race Time Card
struct PredictedRaceTimeCardView: View {
    let data: RacePrediction

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("PREDICTED RACE TIME")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            Text(data.formattedTime)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(DesignSystem.Colors.text.primary)
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text("± \(Int(data.marginOfError / 60)) minutes")
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.text.secondary)

            Divider()
                .background(DesignSystem.Colors.divider)
                .padding(.vertical, 4)

            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(DesignSystem.Colors.success)
                    .font(.system(size: 14))
                Text("Target: Sub 1:15")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.text.primary)
            }

            TrendIndicator(
                value: data.trend == .improving ? "↓" : "→",
                isPositive: data.trend == .improving,
                label: "from last month"
            )

            Spacer()
        }
        .padding(DesignSystem.Spacing.medium)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.large)
    }
}

// MARK: - Weekly Training Load Card
struct WeeklyTrainingLoadCardView: View {
    let data: TrainingLoad
    private let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        MetricCard(title: "WEEKLY TRAINING LOAD") {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                // Progress summary
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Target:")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                    Text("\(Int(data.weeklyTarget)) hours")
                        .font(DesignSystem.Typography.bodyEmphasized)
                        .foregroundColor(DesignSystem.Colors.text.primary)

                    Spacer()

                    Text("Completed:")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                    Text(String(format: "%.1f hours", data.currentWeekHours))
                        .font(DesignSystem.Typography.bodyEmphasized)
                        .foregroundColor(DesignSystem.Colors.text.primary)

                    Text("\(Int((data.currentWeekHours / data.weeklyTarget) * 100))%")
                        .font(DesignSystem.Typography.bodyEmphasized)
                        .foregroundColor(DesignSystem.Colors.primary)
                }

                // Progress bar
                ProgressBar(
                    progress: data.currentWeekHours / data.weeklyTarget,
                    height: 12,
                    backgroundColor: DesignSystem.Colors.backgroundSecondary,
                    foregroundColor: DesignSystem.Colors.primary
                )

                Divider()
                    .background(DesignSystem.Colors.divider)
                    .padding(.vertical, 4)

                // Daily breakdown
                HStack(spacing: 4) {
                    ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                        VStack(spacing: 6) {
                            // Day label
                            Text(day)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.text.secondary)

                            // Bar
                            let hours = data.dailyBreakdown[index].hours
                            let maxHours = data.weeklyTarget / 7.0 * 1.5 // For scaling
                            let barHeight: CGFloat = hours > 0 ? max(20, CGFloat(hours / maxHours) * 60) : 8

                            Rectangle()
                                .fill(hours > 0 ? DesignSystem.Colors.primary : DesignSystem.Colors.backgroundSecondary)
                                .frame(height: barHeight)
                                .cornerRadius(4)

                            // Hours label
                            if hours > 0 {
                                Text(String(format: "%.1fh", hours))
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(DesignSystem.Colors.text.primary)
                            } else {
                                Text("–")
                                    .font(.system(size: 10))
                                    .foregroundColor(DesignSystem.Colors.text.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}

// MARK: - Quick Stats Grid
struct QuickStatsGridView: View {
    let data: QuickStats

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text("QUICK STATS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)
                .padding(.horizontal, DesignSystem.Spacing.xSmall)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: DesignSystem.Spacing.small),
                    GridItem(.flexible(), spacing: DesignSystem.Spacing.small)
                ],
                spacing: DesignSystem.Spacing.small
            ) {
                StatCard(
                    icon: "calendar.badge.clock",
                    value: "\(Int(data.weeklyDistance)) km",
                    label: "This Week",
                    color: DesignSystem.Colors.primary
                )
                .frame(height: 120)

                StatCard(
                    icon: "calendar",
                    value: "\(Int(data.monthlyDistance)) km",
                    label: "This Month",
                    color: DesignSystem.Colors.primary
                )
                .frame(height: 120)

                StatCard(
                    icon: "figure.run",
                    value: "\(data.totalRuns)",
                    label: "Total Runs",
                    color: DesignSystem.Colors.primary
                )
                .frame(height: 120)

                StatCard(
                    icon: "clock.fill",
                    value: String(format: "%.1f", data.totalHours),
                    label: "Total Hours",
                    color: DesignSystem.Colors.primary
                )
                .frame(height: 120)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    AnalyticsDashboardView()
}
