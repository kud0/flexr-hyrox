import SwiftUI
import Charts

// MARK: - HYROX Running Analytics View
// Focused on compromised running analysis (post-station performance degradation)
// Separate from standalone running workouts

struct HyroxRunningAnalyticsView: View {
    @EnvironmentObject var healthKitService: HealthKitService
    @ObservedObject private var analyticsService = AnalyticsService.shared
    @State private var analyticsData: AnalyticsData?
    @State private var selectedTimeframe: Timeframe = .ninetyDays
    @State private var isLoading = false

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

                // Pace Zones Card
                PaceZonesCardView(paceZones: analyticsData?.paceZones ?? [])

                // Compromised Running Analysis
                CompromisedRunningCardView(compromisedRuns: analyticsData?.compromisedRunning ?? [])

                // Volume & Distribution
                HStack(spacing: DesignSystem.Spacing.medium) {
                    WeeklyVolumeCardView()
                        .frame(height: 280)
                    TimeInZonesCardView()
                        .frame(height: 280)
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
    }

    private func refreshData() {
        isLoading = true

        // Update HealthKit cache
        let sleepHours: Double? = healthKitService.sleepAnalysis.map { $0.totalDuration / 3600.0 }
        analyticsService.updateHealthKitCache(
            hrv: healthKitService.heartRateVariability,
            sleepHours: sleepHours,
            restingHR: healthKitService.restingHeartRate,
            readinessScore: healthKitService.calculateReadinessScore()
        )

        // Fetch running sessions for pace zones
        Task {
            await fetchRunningSessionData()
            await MainActor.run {
                let timeframe: AnalyticsTimeframe = switch selectedTimeframe {
                case .sevenDays: .week
                case .thirtyDays: .month
                case .ninetyDays: .threeMonths
                case .all: .all
                }
                analyticsData = analyticsService.calculateAnalytics(timeframe: timeframe)
                isLoading = false
            }
        }
    }

    private func fetchRunningSessionData() async {
        do {
            let sessions = try await SupabaseService.shared.getRunningSessionsFor(limit: 50)

            var allSplitPaces: [TimeInterval] = []
            var aggregatedHRZones: HeartRateZones?

            for session in sessions {
                if let splits = session.splits {
                    allSplitPaces.append(contentsOf: splits.map { $0.pacePerKm })
                } else {
                    allSplitPaces.append(session.avgPacePerKm)
                }
                if aggregatedHRZones == nil, let hrZones = session.heartRateZones {
                    aggregatedHRZones = hrZones
                }
            }

            await MainActor.run {
                analyticsService.updateRunningCache(
                    splits: allSplitPaces,
                    heartRateZones: aggregatedHRZones
                )
            }
        } catch {
            print("⚠️ Failed to fetch running sessions for HYROX analytics: \(error)")
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("HYROX RUNNING")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(1)

            HStack {
                Text("Compromised Analysis")
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

// MARK: - Pace Zones Card
struct PaceZonesCardView: View {
    let paceZones: [PaceZone]

    var body: some View {
        MetricCard(title: "YOUR PACE ZONES") {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                if !paceZones.isEmpty {
                    Text("Auto-calculated from your data")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                        .padding(.bottom, 4)

                    ForEach(Array(paceZones.enumerated()), id: \.offset) { index, zone in
                        zoneRow(
                            zone: index + 1,
                            name: zone.zoneName,
                            pace: zone.paceRange,
                            color: DesignSystem.Colors.zoneColor(index + 1)
                        )
                    }
                } else {
                    // Empty state
                    VStack(spacing: 12) {
                        Image(systemName: "speedometer")
                            .font(.system(size: 48))
                            .foregroundColor(DesignSystem.Colors.text.secondary)

                        Text("No pace zones yet")
                            .font(DesignSystem.Typography.bodyEmphasized)
                            .foregroundColor(DesignSystem.Colors.text.secondary)

                        Text("Complete running workouts to calculate zones")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.text.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }
            }
        }
    }

    private func zoneRow(zone: Int, name: String, pace: String, color: Color) -> some View {
        HStack(spacing: 12) {
            // Zone indicator
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            Text("Zone \(zone)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.text.primary)
                .frame(width: 60, alignment: .leading)

            Text(name)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .frame(width: 80, alignment: .leading)

            Spacer()

            Text(pace)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(DesignSystem.Colors.text.primary)
                .monospacedDigit()
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Compromised Running Card
struct CompromisedRunningCardView: View {
    let compromisedRuns: [CompromisedRun]

    var body: some View {
        MetricCard(title: "COMPROMISED RUNNING ANALYSIS") {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                if !compromisedRuns.isEmpty {
                    // Summary stats
                    let avgDegradation = compromisedRuns.map { $0.degradation }.reduce(0, +) / Double(compromisedRuns.count)
                    let avgExpected = compromisedRuns.map { $0.expectedPace }.reduce(0, +) / Double(compromisedRuns.count)
                    let avgActual = compromisedRuns.map { $0.actualPace }.reduce(0, +) / Double(compromisedRuns.count)

                    HStack(spacing: DesignSystem.Spacing.large) {
                        summaryItem(label: "Fresh Baseline", value: formatPace(avgExpected))
                        summaryItem(label: "Avg Compromised", value: formatPace(avgActual))
                        summaryItem(label: "Avg Degradation", value: "+\(Int(avgDegradation))s", isWarning: true)
                    }

                    Divider()
                        .background(DesignSystem.Colors.divider)
                        .padding(.vertical, 4)

                    // Degradation by segment
                    Text("DEGRADATION BY SEGMENT")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                        .tracking(0.5)
                        .padding(.top, 4)

                    VStack(spacing: 10) {
                        ForEach(compromisedRuns, id: \.segmentName) { run in
                            degradationBar(run: run)
                        }
                    }
                } else {
                    // Empty state
                    VStack(spacing: 12) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 48))
                            .foregroundColor(DesignSystem.Colors.text.secondary)

                        Text("No compromised running data")
                            .font(DesignSystem.Typography.bodyEmphasized)
                            .foregroundColor(DesignSystem.Colors.text.secondary)

                        Text("Complete HYROX workouts to analyze")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.text.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }
            }
        }
    }

    private func formatPace(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(mins):\(String(format: "%02d", secs))"
    }

    private func summaryItem(label: String, value: String, isWarning: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.text.secondary)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(isWarning ? DesignSystem.Colors.warning : DesignSystem.Colors.text.primary)
                .monospacedDigit()
        }
    }

    private func degradationBar(run: CompromisedRun) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(run.segmentName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.text.primary)

                Spacer()

                Text("+\(Int(run.degradation))s")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.text.primary)
                    .monospacedDigit()

                let status = run.degradation < 15 ? "Good" : run.degradation < 30 ? "Okay" : "Weakness"
                Text(status)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(statusColor(for: status))
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(DesignSystem.Colors.backgroundSecondary)
                        .frame(height: 6)
                        .cornerRadius(3)

                    let percentage = min(run.degradation / 60.0, 1.0) // Cap at 60s = 100%
                    Rectangle()
                        .fill(statusColor(for: run.degradation < 15 ? "Good" : run.degradation < 30 ? "Okay" : "Weakness"))
                        .frame(width: geometry.size.width * percentage, height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
    }

    private func statusColor(for status: String) -> Color {
        if status.contains("Good") {
            return DesignSystem.Colors.success
        } else if status.contains("Weakness") {
            return DesignSystem.Colors.error
        } else {
            return DesignSystem.Colors.warning
        }
    }
}

// MARK: - Weekly Volume Card
struct WeeklyVolumeCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("WEEKLY VOLUME")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            Text("Coming soon")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 40)
        }
        .padding(DesignSystem.Spacing.medium)
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.large)
    }
}

// MARK: - Time In Zones Card
struct TimeInZonesCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("TIME IN ZONES")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            Text("Coming soon")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 40)
        }
        .padding(DesignSystem.Spacing.medium)
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.large)
    }
}

// MARK: - Preview
#Preview {
    HyroxRunningAnalyticsView()
}
