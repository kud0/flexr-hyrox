import SwiftUI

/// Weekly Training Detail View - Daily breakdown with week-over-week comparison
/// Design: Shows training volume, intensity, and insights on progression
struct WeeklyTrainingDetailView: View {
    @StateObject private var viewModel = WeeklyTrainingDetailViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.analyticsSectionSpacing) {
                // Hero progress ring
                heroProgressSection

                // Key insight
                if let insight = viewModel.keyInsight {
                    InsightBanner(type: .positive, message: insight)
                }

                // Daily breakdown
                dailyBreakdownSection

                // Week comparison
                weekComparisonSection

                // Volume vs Intensity balance
                volumeIntensitySection

                // This week's highlights
                highlightsSection

                // Recommendations
                recommendationsSection
            }
            .padding(.horizontal, DesignSystem.Spacing.screenHorizontal)
            .padding(.top, DesignSystem.Spacing.screenTop)
            .padding(.bottom, DesignSystem.Spacing.screenBottom)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle("Weekly Training")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Hero Progress

    private var heroProgressSection: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            // Circular progress ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(
                        DesignSystem.Colors.surface,
                        style: StrokeStyle(lineWidth: 24, lineCap: .round)
                    )
                    .frame(width: 220, height: 220)

                // Progress ring
                Circle()
                    .trim(from: 0, to: viewModel.progressPercentage)
                    .stroke(
                        DesignSystem.Colors.primary,
                        style: StrokeStyle(lineWidth: 24, lineCap: .round)
                    )
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(-90))

                // Center content
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.primary))
                } else {
                    VStack(spacing: 8) {
                        Text(String(format: "%.1f", viewModel.currentHours))
                            .font(DesignSystem.Typography.metricHeroLarge)
                            .foregroundColor(.white)

                        Text("of \(String(format: "%.0f", viewModel.targetHours)) hrs")
                            .font(DesignSystem.Typography.bodyEmphasized)
                            .foregroundColor(DesignSystem.Colors.text.secondary)

                        Text("\(Int(viewModel.progressPercentage * 100))% complete")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
            }
            .padding(.vertical, DesignSystem.Spacing.large)

            // Status message
            Text(viewModel.statusMessage)
                .font(DesignSystem.Typography.insightLarge)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Daily Breakdown

    private var dailyBreakdownSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("THIS WEEK")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(spacing: DesignSystem.Spacing.small) {
                // Bar chart for each day
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(viewModel.dailyHours.indices, id: \.self) { index in
                        VStack(spacing: 4) {
                            // Bar
                            ZStack(alignment: .bottom) {
                                // Background bar
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(DesignSystem.Colors.surface)
                                    .frame(height: 120)

                                // Filled bar
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(viewModel.dailyHours[index] > 0 ? DesignSystem.Colors.primary : Color.clear)
                                    .frame(height: CGFloat(viewModel.dailyHours[index] / viewModel.maxDailyHours) * 120)
                            }
                            .frame(maxWidth: .infinity)

                            // Day label
                            Text(viewModel.dayLabels[index])
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(
                                    index == viewModel.todayIndex
                                        ? .white
                                        : DesignSystem.Colors.text.secondary
                                )
                                .fontWeight(index == viewModel.todayIndex ? .bold : .regular)

                            // Hours
                            Text(viewModel.dailyHours[index] > 0 ? String(format: "%.1f", viewModel.dailyHours[index]) : "-")
                                .font(DesignSystem.Typography.footnote)
                                .foregroundColor(DesignSystem.Colors.text.tertiary)
                                .monospacedDigit()
                        }
                    }
                }
                .padding(.vertical, DesignSystem.Spacing.medium)

                // Daily details
                VStack(spacing: DesignSystem.Spacing.xSmall) {
                    ForEach(viewModel.dailyDetails) { day in
                        if day.hasWorkout {
                            HStack(spacing: DesignSystem.Spacing.small) {
                                // Day indicator
                                Circle()
                                    .fill(DesignSystem.Colors.primary)
                                    .frame(width: 6, height: 6)

                                Text(day.dayName)
                                    .font(DesignSystem.Typography.bodyMedium)
                                    .foregroundColor(.white)
                                    .frame(width: 50, alignment: .leading)

                                Text(day.workoutType)
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(DesignSystem.Colors.text.secondary)

                                Spacer()

                                Text(String(format: "%.1f hrs", day.hours))
                                    .font(DesignSystem.Typography.bodyEmphasized)
                                    .foregroundColor(.white)
                                    .monospacedDigit()
                            }
                            .padding(.horizontal, DesignSystem.Spacing.medium)
                            .padding(.vertical, DesignSystem.Spacing.small)
                        }
                    }
                }
            }
            .padding(DesignSystem.Spacing.analyticsCardPadding)
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.Radius.large)
        }
    }

    // MARK: - Week Comparison

    private var weekComparisonSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("WEEK-OVER-WEEK")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            HStack(spacing: DesignSystem.Spacing.medium) {
                // This week
                VStack(alignment: .leading, spacing: 8) {
                    Text("THIS WEEK")
                        .font(DesignSystem.Typography.footnoteEmphasized)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                        .tracking(0.5)

                    Text(String(format: "%.1f", viewModel.currentHours))
                        .font(DesignSystem.Typography.metricLarge)
                        .foregroundColor(.white)
                        .monospacedDigit()

                    Text("hours")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(DesignSystem.Spacing.medium)
                .background(DesignSystem.Colors.surface)
                .cornerRadius(DesignSystem.Radius.medium)

                // Change indicator
                VStack(spacing: 4) {
                    Image(systemName: viewModel.weekChange > 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(viewModel.weekChange > 0 ? DesignSystem.Colors.success : DesignSystem.Colors.warning)

                    Text("\(abs(viewModel.weekChange))%")
                        .font(DesignSystem.Typography.bodyEmphasized)
                        .foregroundColor(viewModel.weekChange > 0 ? DesignSystem.Colors.success : DesignSystem.Colors.warning)
                }

                // Last week
                VStack(alignment: .leading, spacing: 8) {
                    Text("LAST WEEK")
                        .font(DesignSystem.Typography.footnoteEmphasized)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                        .tracking(0.5)

                    Text(String(format: "%.1f", viewModel.lastWeekHours))
                        .font(DesignSystem.Typography.metricLarge)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                        .monospacedDigit()

                    Text("hours")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(DesignSystem.Spacing.medium)
                .background(DesignSystem.Colors.surface.opacity(0.5))
                .cornerRadius(DesignSystem.Radius.medium)
            }
        }
    }

    // MARK: - Volume vs Intensity

    private var volumeIntensitySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("TRAINING BALANCE")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(spacing: DesignSystem.Spacing.analyticsBreakdownSpacing) {
                // Volume
                MetricBreakdownCard(
                    icon: "chart.bar.fill",
                    title: "Training Volume",
                    value: String(format: "%.1f", viewModel.volumeHours),
                    unit: "hrs",
                    change: String(format: "+%.1f%%", viewModel.volumeChange),
                    changeColor: DesignSystem.Colors.success,
                    contributionPercent: viewModel.volumePercentage
                )

                // Intensity
                MetricBreakdownCard(
                    icon: "bolt.fill",
                    title: "High Intensity",
                    value: String(format: "%.1f", viewModel.intensityHours),
                    unit: "hrs",
                    change: String(format: "+%.1f%%", viewModel.intensityChange),
                    changeColor: DesignSystem.Colors.success,
                    contributionPercent: viewModel.intensityPercentage
                )
            }
        }
    }

    // MARK: - Highlights

    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("THIS WEEK'S HIGHLIGHTS")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(spacing: DesignSystem.Spacing.small) {
                ForEach(viewModel.highlights) { highlight in
                    HStack(spacing: DesignSystem.Spacing.medium) {
                        // Icon
                        Image(systemName: highlight.icon)
                            .font(.system(size: 24))
                            .foregroundColor(DesignSystem.Colors.success)
                            .frame(width: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(highlight.title)
                                .font(DesignSystem.Typography.bodyEmphasized)
                                .foregroundColor(.white)

                            Text(highlight.description)
                                .font(DesignSystem.Typography.caption)
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

    // MARK: - Recommendations

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("NEXT WEEK")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            VStack(spacing: DesignSystem.Spacing.small) {
                ForEach(viewModel.recommendations, id: \.self) { recommendation in
                    InsightBanner(type: .recommendation, message: recommendation)
                }
            }
        }
    }
}

// MARK: - View Model

@MainActor
class WeeklyTrainingDetailViewModel: ObservableObject {
    @Published var currentHours: Double = 0
    @Published var targetHours: Double = 8.0  // Default target
    @Published var lastWeekHours: Double = 0
    @Published var statusMessage: String = "Loading..."
    @Published var keyInsight: String? = nil
    @Published var isLoading: Bool = true
    @Published var hasData: Bool = false

    // Daily breakdown
    @Published var dailyHours: [Double] = [0, 0, 0, 0, 0, 0, 0]
    @Published var maxDailyHours: Double = 2.0
    @Published var dayLabels: [String] = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    @Published var todayIndex: Int = 0

    @Published var dailyDetails: [DailyDetail] = []

    // Week comparison
    @Published var weekChange: Int = 0

    // Volume vs Intensity
    @Published var volumeHours: Double = 0
    @Published var volumeChange: Double = 0
    @Published var volumePercentage: Double = 0.7

    @Published var intensityHours: Double = 0
    @Published var intensityChange: Double = 0
    @Published var intensityPercentage: Double = 0.3

    // Highlights
    @Published var highlights: [Highlight] = []

    // Recommendations
    @Published var recommendations: [String] = []

    private let healthKitService = HealthKitService.shared

    var progressPercentage: CGFloat {
        CGFloat(min(currentHours / targetHours, 1.0))
    }

    func loadData() async {
        isLoading = true

        // Fetch all workouts from HealthKit (last 14 days to compare weeks)
        let allWorkouts = await healthKitService.fetchAllWorkouts(daysBack: 14)

        let calendar = Calendar.current

        // Get start of current week (Monday)
        var weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        // If system uses Sunday as first day, adjust to Monday
        if calendar.component(.weekday, from: weekStart) == 1 {
            weekStart = calendar.date(byAdding: .day, value: 1, to: weekStart)!
        }

        // Previous week start
        let prevWeekStart = calendar.date(byAdding: .day, value: -7, to: weekStart)!

        // Filter workouts for this week and last week
        let thisWeekWorkouts = allWorkouts.filter { $0.date >= weekStart }
        let lastWeekWorkouts = allWorkouts.filter { $0.date >= prevWeekStart && $0.date < weekStart }

        // Calculate today index (0 = Monday)
        let weekday = calendar.component(.weekday, from: Date())
        // weekday: 1=Sun, 2=Mon, ..., 7=Sat
        todayIndex = weekday == 1 ? 6 : weekday - 2

        guard !allWorkouts.isEmpty else {
            isLoading = false
            hasData = false
            statusMessage = "No training data yet"
            keyInsight = "Start logging workouts to see your weekly training analytics"
            recommendations = [
                "Aim for 3-5 training sessions per week",
                "Mix different workout types for balanced fitness",
                "Track all your workouts for better insights"
            ]
            return
        }

        hasData = true

        // Calculate current week hours
        currentHours = thisWeekWorkouts.reduce(0.0) { $0 + $1.duration } / 3600

        // Calculate last week hours
        lastWeekHours = lastWeekWorkouts.reduce(0.0) { $0 + $1.duration } / 3600

        // Week change percentage
        if lastWeekHours > 0 {
            weekChange = Int(((currentHours - lastWeekHours) / lastWeekHours) * 100)
        }

        // Daily breakdown
        var dailyHoursData: [Double] = [0, 0, 0, 0, 0, 0, 0]
        var dailyDetailsData: [DailyDetail] = []

        for dayOffset in 0..<7 {
            let dayStart = calendar.date(byAdding: .day, value: dayOffset, to: weekStart)!
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

            let dayWorkouts = thisWeekWorkouts.filter { $0.date >= dayStart && $0.date < dayEnd }
            let dayHours = dayWorkouts.reduce(0.0) { $0 + $1.duration } / 3600

            dailyHoursData[dayOffset] = dayHours

            // Build workout type string
            let workoutTypes = dayWorkouts.map { $0.activityType.displayName }
            let typeString = workoutTypes.isEmpty ? "" : (workoutTypes.count == 1 ? workoutTypes[0] : "\(workoutTypes.count) workouts")

            dailyDetailsData.append(DailyDetail(
                dayName: dayLabels[dayOffset],
                workoutType: typeString,
                hours: dayHours,
                hasWorkout: !dayWorkouts.isEmpty
            ))
        }

        dailyHours = dailyHoursData
        dailyDetails = dailyDetailsData
        maxDailyHours = max(dailyHours.max() ?? 1.0, 1.0)

        // Calculate volume vs intensity split
        // High intensity = HIIT, running with fast pace, strength
        let highIntensityTypes: [ExternalActivityType] = [.hiit, .running, .crossTraining]
        let intensityWorkouts = thisWeekWorkouts.filter { highIntensityTypes.contains($0.activityType) }
        intensityHours = intensityWorkouts.reduce(0.0) { $0 + $1.duration } / 3600
        volumeHours = currentHours - intensityHours

        if currentHours > 0 {
            volumePercentage = volumeHours / currentHours
            intensityPercentage = intensityHours / currentHours
        }

        // Calculate volume/intensity changes vs last week
        let lastIntensityWorkouts = lastWeekWorkouts.filter { highIntensityTypes.contains($0.activityType) }
        let lastIntensityHours = lastIntensityWorkouts.reduce(0.0) { $0 + $1.duration } / 3600
        let lastVolumeHours = lastWeekHours - lastIntensityHours

        if lastVolumeHours > 0 {
            volumeChange = ((volumeHours - lastVolumeHours) / lastVolumeHours) * 100
        }
        if lastIntensityHours > 0 {
            intensityChange = ((intensityHours - lastIntensityHours) / lastIntensityHours) * 100
        }

        // Generate status message
        updateStatusMessage()

        // Generate highlights
        generateHighlights(thisWeekWorkouts, lastWeekWorkouts)

        // Generate recommendations
        generateRecommendations()

        isLoading = false
    }

    private func updateStatusMessage() {
        let daysWorkedOut = dailyDetails.filter { $0.hasWorkout }.count

        if currentHours >= targetHours {
            statusMessage = "Target reached! Great week"
            keyInsight = "You've hit your \(Int(targetHours))-hour weekly target - excellent work!"
        } else if currentHours >= targetHours * 0.8 {
            statusMessage = "Almost there - \(String(format: "%.1f", targetHours - currentHours)) hours to go"
            keyInsight = "You're on track to hit your weekly target"
        } else if daysWorkedOut >= 3 {
            statusMessage = "Good consistency with \(daysWorkedOut) training days"
            keyInsight = "Keep up the consistent training - it builds results over time"
        } else if currentHours > 0 {
            statusMessage = "\(String(format: "%.1f", currentHours)) hours this week so far"
            keyInsight = "Try to fit in \(4 - daysWorkedOut) more sessions this week"
        } else {
            statusMessage = "Week just started - time to train!"
            keyInsight = nil
        }
    }

    private func generateHighlights(_ thisWeek: [ExternalWorkout], _ lastWeek: [ExternalWorkout]) {
        var highlightsList: [Highlight] = []

        let daysWorkedOut = dailyDetails.filter { $0.hasWorkout }.count
        let lastWeekDays = Set(lastWeek.map { Calendar.current.component(.weekday, from: $0.date) }).count

        // Consistency highlight
        if daysWorkedOut >= 4 {
            highlightsList.append(Highlight(
                icon: "flame.fill",
                title: "\(daysWorkedOut)-Day Training Week",
                description: "Great consistency this week"
            ))
        }

        // Volume change highlight
        if weekChange > 10 {
            highlightsList.append(Highlight(
                icon: "chart.line.uptrend.xyaxis",
                title: "Volume Up \(weekChange)%",
                description: "Training load increasing sustainably"
            ))
        } else if weekChange < -20 {
            highlightsList.append(Highlight(
                icon: "bed.double.fill",
                title: "Recovery Week",
                description: "Lower volume helps your body adapt"
            ))
        }

        // Sessions count highlight
        let sessionCount = thisWeek.count
        if sessionCount >= 5 {
            highlightsList.append(Highlight(
                icon: "star.fill",
                title: "\(sessionCount) Workouts Completed",
                description: "High training frequency this week"
            ))
        }

        // Default highlight if none generated
        if highlightsList.isEmpty && currentHours > 0 {
            highlightsList.append(Highlight(
                icon: "figure.run",
                title: "Active Week",
                description: String(format: "%.1f hours of training logged", currentHours)
            ))
        }

        highlights = highlightsList
    }

    private func generateRecommendations() {
        var recs: [String] = []

        let remainingHours = max(0, targetHours - currentHours)
        let daysLeft = 7 - todayIndex - 1
        let daysWorkedOut = dailyDetails.filter { $0.hasWorkout }.count

        if remainingHours > 0 && daysLeft > 0 {
            if remainingHours < 2 {
                recs.append("Add 1 more session to hit your target - consider a recovery run")
            } else {
                recs.append(String(format: "%.1f hours remaining to reach your %.0f-hour goal", remainingHours, targetHours))
            }
        }

        if intensityPercentage > 0.5 {
            recs.append("Consider more easy/Zone 2 sessions for balanced training")
        } else if intensityPercentage < 0.2 && currentHours > 2 {
            recs.append("Add a high-intensity session to boost fitness gains")
        }

        if daysWorkedOut < 3 && todayIndex >= 3 {
            recs.append("Try to train at least 3 times this week for consistency")
        }

        // Default recommendations
        if recs.isEmpty {
            recs.append("Maintain your current training consistency")
            recs.append("Balance hard efforts with adequate recovery")
        }

        recommendations = recs
    }
}

// MARK: - Supporting Types

struct DailyDetail: Identifiable, Hashable {
    let id = UUID()
    let dayName: String
    let workoutType: String
    let hours: Double
    let hasWorkout: Bool
}

struct Highlight: Identifiable, Hashable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WeeklyTrainingDetailView()
    }
}
