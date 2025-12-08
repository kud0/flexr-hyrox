import SwiftUI

/// Heart Rate Analytics Detail View - Deep dive into heart rate zones and training intensity
/// Storytelling: Shows zone distribution, cardiovascular efficiency, and intensity balance
/// Design: Hero zone metric + zone breakdown + efficiency trends + recommendations
struct HeartRateAnalyticsDetailView: View {
    @StateObject private var viewModel = HeartRateAnalyticsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.analyticsSectionSpacing) {
                // Hero zone metric
                heroSection

                // Key insight
                if let insight = viewModel.keyInsight {
                    InsightBanner(type: .positive, message: insight)
                }

                // Zone distribution (30 days)
                zoneDistributionSection

                // Efficiency metrics
                efficiencySection

                // Weekly intensity balance
                intensityBalanceSection

                // Zone performance
                zonePerformanceSection

                // Recommendations
                recommendationsSection
            }
            .padding(.horizontal, DesignSystem.Spacing.screenHorizontal)
            .padding(.top, DesignSystem.Spacing.screenTop)
            .padding(.bottom, DesignSystem.Spacing.screenBottom)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle("Heart Rate Analytics")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            // Heart icon
            Image(systemName: "heart.fill")
                .font(.system(size: 64, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.error)
                .padding(.vertical, DesignSystem.Spacing.medium)

            // Dominant zone
            VStack(spacing: DesignSystem.Spacing.small) {
                Text("MOST TIME IN")
                    .font(DesignSystem.Typography.footnoteEmphasized)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
                    .tracking(0.5)

                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.error))
                        .padding(.vertical, 20)
                } else if viewModel.hasData {
                    Text("Zone \(viewModel.dominantZone)")
                        .font(DesignSystem.Typography.metricHero)
                        .foregroundColor(viewModel.dominantZoneColor)

                    Text("\(viewModel.dominantZonePercentage)% of training time")
                        .font(DesignSystem.Typography.bodyEmphasized)
                        .foregroundColor(.white)
                } else {
                    Text("--")
                        .font(DesignSystem.Typography.metricHero)
                        .foregroundColor(DesignSystem.Colors.text.tertiary)

                    Text("No HR data available")
                        .font(DesignSystem.Typography.bodyEmphasized)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Zone Distribution

    private var zoneDistributionSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("ZONE BREAKDOWN (30 DAYS)")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(spacing: DesignSystem.Spacing.small) {
                ForEach(viewModel.zones) { zone in
                    HStack {
                        // Zone indicator - cleaner
                        Circle()
                            .fill(zone.color.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text("Z\(zone.number)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(zone.color)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(zone.name)
                                .font(DesignSystem.Typography.bodyEmphasized)
                                .foregroundColor(.white)

                            Text(zone.duration)
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.text.secondary)
                        }

                        Spacer()

                        // Percentage - larger, cleaner
                        Text("\(zone.percentage)%")
                            .font(DesignSystem.Typography.heading2)
                            .foregroundColor(zone.color)
                            .monospacedDigit()
                    }
                    .padding(DesignSystem.Spacing.medium)
                    .background(DesignSystem.Colors.surface)
                    .cornerRadius(DesignSystem.Radius.medium)
                }
            }
        }
    }

    // MARK: - Efficiency Section

    private var efficiencySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("CARDIOVASCULAR EFFICIENCY")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(spacing: DesignSystem.Spacing.analyticsBreakdownSpacing) {
                MetricBreakdownCard(
                    icon: "heart.fill",
                    iconColor: DesignSystem.Colors.error,
                    title: "Avg Heart Rate",
                    value: "\(viewModel.avgHeartRate)",
                    unit: "bpm",
                    change: "-\(viewModel.avgHRChange)%",
                    changeColor: DesignSystem.Colors.success,
                    contributionPercent: 0.4
                )

                MetricBreakdownCard(
                    icon: "arrow.down.heart.fill",
                    iconColor: DesignSystem.Colors.success,
                    title: "Recovery Rate",
                    value: "\(viewModel.recoveryRate)",
                    unit: "bpm/min",
                    change: "+\(viewModel.recoveryChange)%",
                    changeColor: DesignSystem.Colors.success,
                    contributionPercent: 0.35
                )

                MetricBreakdownCard(
                    icon: "waveform.path.ecg",
                    iconColor: DesignSystem.Colors.accent,
                    title: "HRV Average",
                    value: "\(viewModel.hrvAverage)",
                    unit: "ms",
                    change: "+\(viewModel.hrvChange)%",
                    changeColor: DesignSystem.Colors.success,
                    contributionPercent: 0.25
                )
            }
        }
    }

    // MARK: - Intensity Balance

    private var intensityBalanceSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("WEEKLY INTENSITY BALANCE")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                // Balance status
                HStack(spacing: DesignSystem.Spacing.xSmall) {
                    Image(systemName: viewModel.intensityBalance.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(viewModel.intensityBalance.color)

                    Text(viewModel.intensityBalance.text)
                        .font(DesignSystem.Typography.bodyEmphasized)
                        .foregroundColor(.white)
                }
                .padding(.bottom, DesignSystem.Spacing.small)

                // Easy vs Hard ratio
                HStack(spacing: DesignSystem.Spacing.medium) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("EASY (Z1-Z2)")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.text.secondary)

                        Text("\(viewModel.easyPercentage)%")
                            .font(DesignSystem.Typography.heading2)
                            .foregroundColor(DesignSystem.Colors.zone2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()
                        .frame(height: 40)

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("HARD (Z4-Z5)")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.text.secondary)

                        Text("\(viewModel.hardPercentage)%")
                            .font(DesignSystem.Typography.heading2)
                            .foregroundColor(DesignSystem.Colors.error)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding(DesignSystem.Spacing.analyticsCardPadding)
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.Radius.large)
        }
    }

    // MARK: - Zone Performance

    private var zonePerformanceSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("ZONE INSIGHTS")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(spacing: DesignSystem.Spacing.small) {
                ForEach(viewModel.zoneInsights) { insight in
                    HStack(alignment: .top, spacing: DesignSystem.Spacing.medium) {
                        Image(systemName: insight.icon)
                            .font(.system(size: 18))
                            .foregroundColor(insight.color)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(insight.title)
                                .font(DesignSystem.Typography.bodyEmphasized)
                                .foregroundColor(.white)

                            Text(insight.description)
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.text.secondary)
                                .lineLimit(2)
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

    // MARK: - Recommendations

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("TO OPTIMIZE TRAINING")
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
class HeartRateAnalyticsViewModel: ObservableObject {
    @Published var dominantZone: Int = 2
    @Published var dominantZonePercentage: Int = 0
    @Published var keyInsight: String? = nil
    @Published var isLoading: Bool = true
    @Published var hasData: Bool = false

    // Zones
    @Published var zones: [HeartRateZone] = []

    // Efficiency metrics (from HealthKit)
    @Published var avgHeartRate: Int = 0
    @Published var avgHRChange: Int = 0
    @Published var recoveryRate: Int = 0  // Placeholder - needs specific HR recovery tracking
    @Published var recoveryChange: Int = 0
    @Published var hrvAverage: Int = 0
    @Published var hrvChange: Int = 0

    // Intensity balance
    @Published var easyPercentage: Int = 0
    @Published var hardPercentage: Int = 0
    @Published var intensityBalance: IntensityBalanceStatus = IntensityBalanceStatus(
        icon: "minus.circle.fill",
        text: "No data yet",
        color: DesignSystem.Colors.text.secondary
    )

    // Zone insights
    @Published var zoneInsights: [ZoneInsight] = []

    // Recommendations
    @Published var recommendations: [String] = []

    private let healthKitService = HealthKitService.shared

    var dominantZoneColor: Color {
        zones.first { $0.number == dominantZone }?.color ?? DesignSystem.Colors.primary
    }

    func loadData() async {
        isLoading = true

        // Load baseline metrics from HealthKit (resting HR, HRV)
        await healthKitService.loadBaselineMetrics()

        // Fetch all workouts from HealthKit
        let allWorkouts = await healthKitService.fetchAllWorkouts(daysBack: 30)
        let workoutsWithHR = allWorkouts.filter { $0.averageHeartRate != nil }

        // Update HealthKit-based metrics
        if let restingHR = healthKitService.restingHeartRate {
            // Resting HR isn't workout avg, so we'll use workout avg below
        }

        if let hrv = healthKitService.heartRateVariability {
            hrvAverage = Int(hrv)
        }

        guard !workoutsWithHR.isEmpty else {
            isLoading = false
            hasData = false
            keyInsight = "No heart rate data yet - train with a heart rate monitor to see analytics"
            recommendations = [
                "Wear your Apple Watch or a heart rate monitor during workouts",
                "Sync workouts from other apps like Strava or Garmin",
                "Heart rate training helps optimize your fitness gains"
            ]
            return
        }

        hasData = true

        // Calculate average workout heart rate
        let avgWorkoutHR = workoutsWithHR.reduce(0.0) { $0 + ($1.averageHeartRate ?? 0) } / Double(workoutsWithHR.count)
        avgHeartRate = Int(avgWorkoutHR)

        // Calculate total training duration for zone time estimates
        let totalTrainingMinutes = workoutsWithHR.reduce(0.0) { $0 + $1.duration } / 60

        // Classify workouts into HR zones based on average HR
        // Zone thresholds (assuming max HR of 190 - could be personalized)
        let maxHR = 190.0
        var zoneCounts: [Int: (count: Int, duration: TimeInterval)] = [1: (0, 0), 2: (0, 0), 3: (0, 0), 4: (0, 0), 5: (0, 0)]

        for workout in workoutsWithHR {
            guard let hr = workout.averageHeartRate else { continue }
            let percentMax = (hr / maxHR) * 100

            let zone: Int
            if percentMax < 60 {
                zone = 1
            } else if percentMax < 70 {
                zone = 2
            } else if percentMax < 80 {
                zone = 3
            } else if percentMax < 90 {
                zone = 4
            } else {
                zone = 5
            }

            zoneCounts[zone] = (zoneCounts[zone]!.count + 1, zoneCounts[zone]!.duration + workout.duration)
        }

        // Calculate zone percentages based on duration
        let totalDuration = zoneCounts.values.reduce(0.0) { $0 + $1.duration }

        var zoneData: [HeartRateZone] = []
        let zoneColors = [
            1: Color(hex: "#4A90E2"),
            2: Color(hex: "#50C878"),
            3: Color(hex: "#FFB347"),
            4: Color(hex: "#FF6B6B"),
            5: Color(hex: "#C44569")
        ]
        let zoneNames = [
            1: "Recovery",
            2: "Endurance",
            3: "Tempo",
            4: "Threshold",
            5: "Max"
        ]

        for zone in 1...5 {
            let (_, duration) = zoneCounts[zone]!
            let percentage = totalDuration > 0 ? Int((duration / totalDuration) * 100) : 0
            let durationFormatted = formatDuration(duration)

            zoneData.append(HeartRateZone(
                number: zone,
                name: zoneNames[zone]!,
                color: zoneColors[zone]!,
                percentage: percentage,
                duration: durationFormatted
            ))
        }

        zones = zoneData

        // Calculate dominant zone
        if let maxZone = zones.max(by: { $0.percentage < $1.percentage }) {
            dominantZone = maxZone.number
            dominantZonePercentage = maxZone.percentage
        }

        // Calculate easy/hard split (Zone 1+2 = easy, Zone 4+5 = hard)
        easyPercentage = (zones.first { $0.number == 1 }?.percentage ?? 0) + (zones.first { $0.number == 2 }?.percentage ?? 0)
        hardPercentage = (zones.first { $0.number == 4 }?.percentage ?? 0) + (zones.first { $0.number == 5 }?.percentage ?? 0)

        // Update intensity balance status
        updateIntensityBalance()

        // Generate insights
        updateZoneInsights()

        // Generate recommendations
        generateRecommendations()

        isLoading = false
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private func updateIntensityBalance() {
        let easyTotal = easyPercentage
        let hardTotal = hardPercentage

        if easyTotal >= 70 && hardTotal <= 25 {
            intensityBalance = IntensityBalanceStatus(
                icon: "checkmark.circle.fill",
                text: "Good polarized training",
                color: DesignSystem.Colors.success
            )
            keyInsight = "Your training is well polarized - building a strong aerobic base"
        } else if easyTotal >= 60 {
            intensityBalance = IntensityBalanceStatus(
                icon: "checkmark.circle.fill",
                text: "Balanced training",
                color: DesignSystem.Colors.success
            )
            keyInsight = "Good mix of easy and hard training"
        } else if hardTotal > 40 {
            intensityBalance = IntensityBalanceStatus(
                icon: "exclamationmark.triangle.fill",
                text: "Too much intensity",
                color: DesignSystem.Colors.warning
            )
            keyInsight = "You're pushing hard often - add more easy sessions to avoid burnout"
        } else {
            intensityBalance = IntensityBalanceStatus(
                icon: "info.circle.fill",
                text: "Moderate balance",
                color: DesignSystem.Colors.accent
            )
            keyInsight = "Consider more polarized training - either easy or hard, less in the middle"
        }
    }

    private func updateZoneInsights() {
        var insights: [ZoneInsight] = []

        // Zone 2 insight
        if let zone2 = zones.first(where: { $0.number == 2 }) {
            if zone2.percentage >= 40 {
                insights.append(ZoneInsight(
                    icon: "checkmark.circle.fill",
                    color: DesignSystem.Colors.success,
                    title: "Great Zone 2 volume",
                    description: "You're spending \(zone2.percentage)% of time building aerobic base - perfect for endurance"
                ))
            } else if zone2.percentage > 0 {
                insights.append(ZoneInsight(
                    icon: "exclamationmark.triangle.fill",
                    color: DesignSystem.Colors.warning,
                    title: "Need more Zone 2",
                    description: "Only \(zone2.percentage)% in Zone 2 - aim for 40%+ for better aerobic development"
                ))
            }
        }

        // Zone 4-5 insight
        let zone4Percent = zones.first(where: { $0.number == 4 })?.percentage ?? 0
        let zone5Percent = zones.first(where: { $0.number == 5 })?.percentage ?? 0
        let highIntensity = zone4Percent + zone5Percent

        if highIntensity > 30 {
            insights.append(ZoneInsight(
                icon: "exclamationmark.triangle.fill",
                color: DesignSystem.Colors.warning,
                title: "High intensity training",
                description: "\(highIntensity)% in high intensity zones - ensure adequate recovery between sessions"
            ))
        } else if highIntensity > 0 {
            insights.append(ZoneInsight(
                icon: "checkmark.circle.fill",
                color: DesignSystem.Colors.success,
                title: "Balanced intensity",
                description: "\(highIntensity)% in high intensity zones - good for building fitness"
            ))
        }

        // HRV insight
        if hrvAverage > 0 {
            if hrvAverage > 50 {
                insights.append(ZoneInsight(
                    icon: "checkmark.circle.fill",
                    color: DesignSystem.Colors.success,
                    title: "Good HRV",
                    description: "HRV of \(hrvAverage)ms indicates good recovery capacity"
                ))
            } else if hrvAverage > 30 {
                insights.append(ZoneInsight(
                    icon: "info.circle.fill",
                    color: DesignSystem.Colors.accent,
                    title: "Moderate HRV",
                    description: "HRV of \(hrvAverage)ms - monitor for trends and prioritize sleep"
                ))
            }
        }

        zoneInsights = insights
    }

    private func generateRecommendations() {
        var recs: [String] = []

        // Based on zone distribution
        let zone2Percent = zones.first(where: { $0.number == 2 })?.percentage ?? 0
        let zone3Percent = zones.first(where: { $0.number == 3 })?.percentage ?? 0

        if zone2Percent < 40 && hasData {
            recs.append("Add more Zone 2 (easy pace) sessions to build your aerobic base")
        }

        if zone3Percent > 30 {
            recs.append("You're spending a lot of time in Zone 3 (tempo) - try more polarized training")
        }

        if hardPercentage > 30 {
            recs.append("Consider more easy sessions between hard workouts for better recovery")
        }

        if easyPercentage >= 70 {
            recs.append("Great aerobic base building - your easy/hard balance is on point")
        }

        // HRV recommendation
        if hrvAverage > 0 && hrvAverage < 40 {
            recs.append("Focus on sleep and recovery - your HRV suggests your body needs rest")
        }

        // Default recommendations if few specific ones
        if recs.count < 2 {
            recs.append("Train with a heart rate monitor consistently for better insights")
            recs.append("Monitor your resting heart rate trend for fitness improvements")
        }

        recommendations = recs
    }
}

// MARK: - Supporting Types

struct HeartRateZone: Identifiable, Hashable {
    let id = UUID()
    let number: Int
    let name: String
    let color: Color
    let percentage: Int
    let duration: String
}

struct ZoneInsight: Identifiable, Hashable {
    let id = UUID()
    let icon: String
    let color: Color
    let title: String
    let description: String
}

struct IntensityBalanceStatus: Hashable {
    let icon: String
    let text: String
    let color: Color
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HeartRateAnalyticsDetailView()
    }
}
