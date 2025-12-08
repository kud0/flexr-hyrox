import SwiftUI

// MARK: - Heart Rate Analytics View
// Phase 4: HR Zones, Resting HR Trends

struct HeartRateAnalyticsView: View {
    @EnvironmentObject var healthKitService: HealthKitService
    @ObservedObject private var analyticsService = AnalyticsService.shared
    @State private var analyticsData: AnalyticsData?
    @State private var selectedTimeframe: AnalyticsTimeframe = .week
    @State private var isLoading = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                // Header
                headerView

                // HR Zones Card
                HRZonesCardView(maxHR: analyticsData?.maxHeartRate ?? 0, restingHR: analyticsData?.readiness.restingHeartRate ?? 0)

                // HR Stats Grid
                HStack(spacing: DesignSystem.Spacing.medium) {
                    hrStatCard(
                        title: "Max HR",
                        value: "\(analyticsData?.maxHeartRate ?? 0)",
                        unit: "bpm",
                        subtitle: "From workouts",
                        color: DesignSystem.Colors.error
                    )
                    .frame(height: 150)

                    hrStatCard(
                        title: "Resting HR",
                        value: "\(analyticsData?.readiness.restingHeartRate ?? 0)",
                        unit: "bpm",
                        subtitle: "Average",
                        color: DesignSystem.Colors.success
                    )
                    .frame(height: 150)
                }

                // Zone Distribution
                MetricCard(title: "TRAINING DISTRIBUTION") {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                        Text("Heart rate during workouts")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.text.secondary)

                        if let zones = analyticsData?.heartRateZones, !zones.isEmpty {
                            ForEach(zones, id: \.zone) { zone in
                                zoneDistributionRow(zone: zone.zone, percentage: Double(zone.percentage), label: zoneLabel(zone.zone))
                            }
                        } else {
                            Text("No heart rate data yet")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.text.secondary)
                                .padding(.vertical, 32)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
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

        // Fetch running sessions for HR zones
        Task {
            await fetchRunningSessionData()
            await MainActor.run {
                analyticsData = analyticsService.calculateAnalytics(timeframe: selectedTimeframe)
                isLoading = false
            }
        }
    }

    private func fetchRunningSessionData() async {
        do {
            let sessions = try await SupabaseService.shared.getRunningSessionsFor(limit: 50)

            var aggregatedHRZones: HeartRateZones?
            var allSplitPaces: [TimeInterval] = []

            for session in sessions {
                if let splits = session.splits {
                    allSplitPaces.append(contentsOf: splits.map { $0.pacePerKm })
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
            print("⚠️ Failed to fetch running sessions for HR analytics: \(error)")
        }
    }

    private func zoneLabel(_ zone: Int) -> String {
        switch zone {
        case 1: return "Recovery"
        case 2: return "Easy"
        case 3: return "Aerobic"
        case 4: return "Threshold"
        case 5: return "Max"
        default: return "Zone \(zone)"
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("HEART RATE")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(1)

            Text("Zones & Efficiency")
                .font(DesignSystem.Typography.largeTitle)
                .foregroundColor(DesignSystem.Colors.text.primary)
        }
        .padding(.top, 8)
    }

    private func hrStatCard(
        title: String,
        value: String,
        unit: String,
        subtitle: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                    .monospacedDigit()

                Text(unit)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }

            Text(subtitle)
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.text.secondary)
        }
        .padding(DesignSystem.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.large)
    }

    private func zoneDistributionRow(zone: Int, percentage: Double, label: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(DesignSystem.Colors.zoneColor(zone))
                .frame(width: 10, height: 10)

            Text("Zone \(zone)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.text.primary)
                .frame(width: 60, alignment: .leading)

            Text(label)
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .frame(width: 70, alignment: .leading)

            ProgressBar(
                progress: percentage / 100,
                height: 16,
                backgroundColor: DesignSystem.Colors.backgroundSecondary,
                foregroundColor: DesignSystem.Colors.zoneColor(zone)
            )

            Text("\(Int(percentage))%")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(DesignSystem.Colors.text.primary)
                .frame(width: 36, alignment: .trailing)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - HR Zones Card
struct HRZonesCardView: View {
    let maxHR: Int
    let restingHR: Int

    var body: some View {
        MetricCard(title: "YOUR HEART RATE ZONES") {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                if maxHR > 0 {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Max HR")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.text.secondary)
                            Text("\(maxHR) bpm")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(DesignSystem.Colors.text.primary)
                                .monospacedDigit()
                            Text("(from workouts)")
                                .font(DesignSystem.Typography.caption2)
                                .foregroundColor(DesignSystem.Colors.text.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Resting HR")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.text.secondary)
                            Text("\(restingHR) bpm")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(DesignSystem.Colors.text.primary)
                                .monospacedDigit()
                        }
                    }
                    .padding(.bottom, 8)

                    Divider()
                        .background(DesignSystem.Colors.divider)
                        .padding(.bottom, 4)

                    let zone1 = Int(Double(maxHR) * 0.6)
                    let zone2Min = zone1
                    let zone2Max = Int(Double(maxHR) * 0.7)
                    let zone3Min = zone2Max
                    let zone3Max = Int(Double(maxHR) * 0.8)
                    let zone4Min = zone3Max
                    let zone4Max = Int(Double(maxHR) * 0.9)
                    let zone5Min = zone4Max

                    hrZoneRow(zone: 1, range: "< \(zone1) bpm", label: "Recovery", color: DesignSystem.Colors.zone1)
                    hrZoneRow(zone: 2, range: "\(zone2Min)-\(zone2Max) bpm", label: "Aerobic Base", color: DesignSystem.Colors.zone2)
                    hrZoneRow(zone: 3, range: "\(zone3Min)-\(zone3Max) bpm", label: "Tempo", color: DesignSystem.Colors.zone3)
                    hrZoneRow(zone: 4, range: "\(zone4Min)-\(zone4Max) bpm", label: "Threshold", color: DesignSystem.Colors.zone4)
                    hrZoneRow(zone: 5, range: "\(zone5Min)+ bpm", label: "VO2max", color: DesignSystem.Colors.zone5)
                } else {
                    // Empty state
                    VStack(spacing: 12) {
                        Image(systemName: "heart.circle")
                            .font(.system(size: 48))
                            .foregroundColor(DesignSystem.Colors.text.secondary)

                        Text("No heart rate zones yet")
                            .font(DesignSystem.Typography.bodyEmphasized)
                            .foregroundColor(DesignSystem.Colors.text.secondary)

                        Text("Complete workouts with heart rate data")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(DesignSystem.Colors.text.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }
            }
        }
    }

    private func hrZoneRow(zone: Int, range: String, label: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            Text("Zone \(zone)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.text.primary)
                .frame(width: 60, alignment: .leading)

            Text(range)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(DesignSystem.Colors.text.primary)
                .monospacedDigit()
                .frame(width: 100, alignment: .leading)

            Spacer()

            Text(label)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.text.secondary)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Preview
#Preview {
    HeartRateAnalyticsView()
}
