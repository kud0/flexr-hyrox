import SwiftUI

/// Analytics home view - New single-screen analytics journey
/// Design: Progressive disclosure with hero cards, ONE metric per card
/// Replaces: AnalyticsContainerView (old 7-tab design)
struct AnalyticsHomeView: View {
    @StateObject private var viewModel = AnalyticsHomeViewModel()
    @State private var selectedTimeframe: TimeFrame = .sevenDays

    enum TimeFrame: String, CaseIterable {
        case sevenDays = "7d"
        case thirtyDays = "30d"

        var days: Int {
            switch self {
            case .sevenDays: return 7
            case .thirtyDays: return 30
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.analyticsCardSpacing) {
                    // Header
                    headerSection

                    // Hero cards - The analytics journey
                    readinessCard
                    racePredictionCard
                    weeklyTrainingCard
                    improvementCard
                    focusAreaCard
                    recentWorkoutsPreview

                    // Detailed Analytics Section
                    detailedAnalyticsSection
                }
                .padding(.horizontal, DesignSystem.Spacing.screenHorizontal)
                .padding(.top, DesignSystem.Spacing.screenTop)
                .padding(.bottom, DesignSystem.Spacing.screenBottom)
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
        }
        .onAppear {
            viewModel.loadData()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
            Text("PERFORMANCE")
                .font(DesignSystem.Typography.footnoteEmphasized)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            HStack {
                Text("Analytics")
                    .font(DesignSystem.Typography.largeTitle)
                    .foregroundColor(.white)

                Spacer()

                // Timeframe picker
                HStack(spacing: DesignSystem.Spacing.xxSmall) {
                    ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                        Button(action: {
                            selectedTimeframe = timeframe
                            viewModel.updateTimeframe(timeframe)
                        }) {
                            Text(timeframe.rawValue)
                                .font(DesignSystem.Typography.footnoteEmphasized)
                                .foregroundColor(
                                    selectedTimeframe == timeframe
                                        ? .white
                                        : DesignSystem.Colors.text.secondary
                                )
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    selectedTimeframe == timeframe
                                        ? DesignSystem.Colors.primary
                                        : DesignSystem.Colors.surface
                                )
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding(.bottom, DesignSystem.Spacing.small)
    }

    // MARK: - 1. Readiness Card

    private var readinessCard: some View {
        NavigationLink(destination: ReadinessDetailView()) {
            ReadinessHeroCard(
                score: viewModel.readinessScore,
                hrvScore: viewModel.hrvScore,
                sleepHours: viewModel.sleepHours,
                restingHR: viewModel.restingHR,
                onTap: nil
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - 2. Race Prediction Card

    private var racePredictionCard: some View {
        NavigationLink(destination: RacePredictionTimelineView()) {
            RacePredictionHeroCard(
                predictedTime: viewModel.predictedTime,
                changeMinutes: viewModel.timeChangeMinutes,
                sessionCount: viewModel.sessionCount,
                onTap: nil
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - 3. Weekly Training Card

    private var weeklyTrainingCard: some View {
        NavigationLink(destination: WeeklyTrainingDetailView()) {
            WeeklyTrainingHeroCard(
                currentHours: viewModel.currentWeekHours,
                targetHours: viewModel.targetWeekHours,
                onTap: nil
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - 4. Improvement Card

    private var improvementCard: some View {
        NavigationLink(destination: StationPerformanceDetailView(
            stationName: viewModel.topImprovement.name,
            emoji: viewModel.topImprovement.emoji,
            mode: .improvement(percentImprovement: viewModel.topImprovement.percentImprovement)
        )) {
            improvementCardContent
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var improvementCardContent: some View {
        HeroMetricCard(title: "Biggest Improvement", tapAction: nil) {
            VStack(spacing: DesignSystem.Spacing.medium) {
                // Station emoji and name
                HStack(spacing: DesignSystem.Spacing.small) {
                    Text(viewModel.topImprovement.emoji)
                        .font(.system(size: 32))
                    Text(viewModel.topImprovement.name)
                        .font(DesignSystem.Typography.title2)
                        .foregroundColor(.white)
                }

                // Improvement percentage
                Text("+\(viewModel.topImprovement.percentImprovement)%")
                    .font(DesignSystem.Typography.metricLarge)
                    .foregroundColor(DesignSystem.Colors.success)

                Text("faster this month")
                    .font(DesignSystem.Typography.insightMedium)
                    .foregroundColor(DesignSystem.Colors.text.secondary)

                // Insight
                if let insight = viewModel.topImprovement.insight {
                    Text(insight)
                        .font(DesignSystem.Typography.insightSmall)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - 5. Focus Area Card

    private var focusAreaCard: some View {
        NavigationLink(destination: StationPerformanceDetailView(
            stationName: viewModel.focusArea.name,
            emoji: viewModel.focusArea.emoji,
            mode: .focus(improvementPotential: viewModel.focusArea.improvementPotential)
        )) {
            focusAreaCardContent
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var focusAreaCardContent: some View {
        HeroMetricCard(title: "Focus This Week", tapAction: nil) {
            VStack(spacing: DesignSystem.Spacing.medium) {
                // Station emoji and name
                HStack(spacing: DesignSystem.Spacing.small) {
                    Text(viewModel.focusArea.emoji)
                        .font(.system(size: 32))
                    Text(viewModel.focusArea.name)
                        .font(DesignSystem.Typography.title2)
                        .foregroundColor(.white)
                }

                // Weakness indicator
                VStack(spacing: 4) {
                    Text("Your weakest station")
                        .font(DesignSystem.Typography.insightMedium)
                        .foregroundColor(DesignSystem.Colors.warning)

                    Text("\(viewModel.focusArea.improvementPotential)% improvement potential")
                        .font(DesignSystem.Typography.insightLarge)
                        .foregroundColor(.white)
                }

                // Recommendation
                if let recommendation = viewModel.focusArea.recommendation {
                    InsightBanner(
                        type: .recommendation,
                        message: recommendation
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - 6. Recent Workouts Preview

    private var recentWorkoutsPreview: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            HStack {
                Text("RECENT WORKOUTS")
                    .font(DesignSystem.Typography.sectionHeader)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
                    .tracking(0.5)

                Spacer()

                NavigationLink(destination: WorkoutHistoryView()) {
                    HStack(spacing: 4) {
                        Text("View all")
                            .font(DesignSystem.Typography.subheadlineEmphasized)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                }
            }

            // Recent workout cards (compact)
            VStack(spacing: DesignSystem.Spacing.small) {
                ForEach(viewModel.recentWorkouts.prefix(3)) { workout in
                    compactWorkoutCard(workout)
                }
            }
        }
    }

    private func compactWorkoutCard(_ workout: RecentWorkout) -> some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            // Workout type icon
            ZStack {
                Circle()
                    .fill(workout.color.opacity(0.2))
                    .frame(width: 48, height: 48)

                Text(workout.icon)
                    .font(.system(size: 24))
            }

            // Workout info
            VStack(alignment: .leading, spacing: 2) {
                Text(workout.name)
                    .font(DesignSystem.Typography.subheadlineEmphasized)
                    .foregroundColor(.white)

                Text(workout.dateString)
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }

            Spacer()

            // Duration
            Text(workout.duration)
                .font(DesignSystem.Typography.bodyEmphasized)
                .foregroundColor(DesignSystem.Colors.text.secondary)
        }
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.medium)
    }

    // MARK: - Detailed Analytics Section

    private var detailedAnalyticsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("DETAILED ANALYTICS")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            // 2-column grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: DesignSystem.Spacing.medium),
                GridItem(.flexible(), spacing: DesignSystem.Spacing.medium)
            ], spacing: DesignSystem.Spacing.medium) {
                // Running Analytics
                NavigationLink(destination: RunningAnalyticsDetailView()) {
                    AnalyticsCategoryCard(
                        icon: "figure.run",
                        iconColor: DesignSystem.Colors.primary,
                        title: "Running",
                        miniInsight: "Pace improving 5% this month",
                        onTap: nil
                    )
                }
                .buttonStyle(PlainButtonStyle())

                // Heart Rate
                NavigationLink(destination: HeartRateAnalyticsDetailView()) {
                    AnalyticsCategoryCard(
                        icon: "heart.fill",
                        iconColor: DesignSystem.Colors.error,
                        title: "Heart Rate",
                        miniInsight: "72% time in Zone 2-3",
                        onTap: nil
                    )
                }
                .buttonStyle(PlainButtonStyle())

                // All Stations
                NavigationLink(destination: AllStationsOverviewView()) {
                    AnalyticsCategoryCard(
                        icon: "figure.strengthtraining.traditional",
                        iconColor: DesignSystem.Colors.accent,
                        title: "All Stations",
                        miniInsight: "4 stations improving",
                        onTap: nil
                    )
                }
                .buttonStyle(PlainButtonStyle())

                // Training Load
                NavigationLink(destination: TrainingLoadDetailView()) {
                    AnalyticsCategoryCard(
                        icon: "chart.line.uptrend.xyaxis",
                        iconColor: DesignSystem.Colors.success,
                        title: "Training Load",
                        miniInsight: "Balanced this week",
                        onTap: nil
                    )
                }
                .buttonStyle(PlainButtonStyle())

                // All Activity (External Workouts)
                NavigationLink(destination: AllActivityView()) {
                    AnalyticsCategoryCard(
                        icon: "sparkles",
                        iconColor: .purple,
                        title: "All Activity",
                        miniInsight: "All workouts from any source",
                        onTap: nil
                    )
                }
                .buttonStyle(PlainButtonStyle())

                // Workout History
                NavigationLink(destination: WorkoutHistoryView()) {
                    AnalyticsCategoryCard(
                        icon: "clock.arrow.circlepath",
                        iconColor: .orange,
                        title: "History",
                        miniInsight: "FLEXR workout history",
                        onTap: nil
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Supporting Types

struct RecentWorkout: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let dateString: String
    let duration: String
}

struct StationImprovement {
    let name: String
    let emoji: String
    let percentImprovement: Int
    let insight: String?
}

struct StationFocus {
    let name: String
    let emoji: String
    let improvementPotential: Int
    let recommendation: String?
}

// MARK: - ViewModel

class AnalyticsHomeViewModel: ObservableObject {
    // Readiness data
    @Published var readinessScore: Int = 78
    @Published var hrvScore: Int = 45
    @Published var sleepHours: Double = 7.5
    @Published var restingHR: Int = 52

    // Race prediction
    @Published var predictedTime: String = "1:18" // h:mm format (no seconds for predictions)
    @Published var timeChangeMinutes: Int = -135 // Negative = faster
    @Published var sessionCount: Int = 47

    // Weekly training
    @Published var currentWeekHours: Double = 6.2
    @Published var targetWeekHours: Double = 8.0

    // Top improvement
    @Published var topImprovement = StationImprovement(
        name: "Sled Push",
        emoji: "🏋️",
        percentImprovement: 18,
        insight: "Your resistance band work is paying off. Keep adding 3x/week."
    )

    // Focus area
    @Published var focusArea = StationFocus(
        name: "Ski Erg",
        emoji: "🚣",
        improvementPotential: 20,
        recommendation: "Add 2x ski erg intervals this week"
    )

    // Recent workouts
    @Published var recentWorkouts: [RecentWorkout] = [
        RecentWorkout(
            name: "HYROX Simulation",
            icon: "🏃",
            color: DesignSystem.Colors.primary,
            dateString: "Today, 6:00 AM",
            duration: "1:24:32"
        ),
        RecentWorkout(
            name: "Station Practice",
            icon: "🏋️",
            color: DesignSystem.Colors.sledPush,
            dateString: "Yesterday",
            duration: "52:18"
        ),
        RecentWorkout(
            name: "Zone 2 Run",
            icon: "🏃",
            color: DesignSystem.Colors.zone2,
            dateString: "2 days ago",
            duration: "45:00"
        )
    ]

    func loadData() {
        // TODO: Load real data from SupabaseService
        // This will fetch data from the backend and update @Published properties
    }

    func updateTimeframe(_ timeframe: AnalyticsHomeView.TimeFrame) {
        // TODO: Update data based on selected timeframe
    }
}

// MARK: - Placeholder Detail Views
// These will be implemented in Phase 3

// MARK: - Preview

#Preview {
    AnalyticsHomeView()
}
