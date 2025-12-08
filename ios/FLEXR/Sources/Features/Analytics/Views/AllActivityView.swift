// FLEXR - All Activity View
// Shows all workouts including external sources (HealthKit, Apple Watch, Strava, etc.)

import SwiftUI

struct AllActivityView: View {
    @EnvironmentObject var healthKitService: HealthKitService

    @State private var allWorkouts: [ExternalWorkout] = []
    @State private var isLoading = true
    @State private var selectedTimeframe: ActivityTimeframe = .week
    @State private var showOnlyExternal = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 20)

                // Summary Card
                summaryCard
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                // Timeframe Picker
                timeframePicker
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                // Filter Toggle
                filterToggle
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                // Activity List
                if isLoading {
                    loadingView
                } else if filteredWorkouts.isEmpty {
                    emptyStateView
                } else {
                    activityList
                }
            }
        }
        .background(Color.black)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadWorkouts()
        }
        .refreshable {
            await loadWorkouts()
        }
    }

    // MARK: - Computed Properties

    private var filteredWorkouts: [ExternalWorkout] {
        var workouts = allWorkouts

        // Filter by timeframe
        let cutoff: Date
        switch selectedTimeframe {
        case .week:
            cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        case .month:
            cutoff = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        case .threeMonths:
            cutoff = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        }
        workouts = workouts.filter { $0.date >= cutoff }

        // Filter external only
        if showOnlyExternal {
            workouts = workouts.filter { !$0.isFLEXRWorkout }
        }

        return workouts.sorted { $0.date > $1.date }
    }

    private var totalDuration: Int {
        Int(filteredWorkouts.reduce(0) { $0 + $1.duration } / 60)
    }

    private var totalCalories: Int {
        Int(filteredWorkouts.reduce(0) { $0 + ($1.activeCalories ?? 0) })
    }

    private var totalDistance: Double {
        filteredWorkouts.reduce(0) { $0 + ($1.distance ?? 0) } / 1000
    }

    // MARK: - Views

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("All Activity")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text("Workouts from all sources")
                .font(.system(size: 15))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var summaryCard: some View {
        FlexrCard {
            VStack(spacing: 16) {
                HStack(spacing: 0) {
                    summaryItem(
                        value: "\(filteredWorkouts.count)",
                        label: "Workouts",
                        icon: "flame.fill",
                        color: DesignSystem.Colors.primary
                    )

                    Divider()
                        .frame(height: 40)
                        .background(Color.gray.opacity(0.3))

                    summaryItem(
                        value: formatDuration(totalDuration),
                        label: "Total Time",
                        icon: "clock.fill",
                        color: .green
                    )

                    Divider()
                        .frame(height: 40)
                        .background(Color.gray.opacity(0.3))

                    summaryItem(
                        value: String(format: "%.1f km", totalDistance),
                        label: "Distance",
                        icon: "figure.run",
                        color: .orange
                    )
                }

                // Sources breakdown
                if !filteredWorkouts.isEmpty {
                    sourcesBreakdown
                }
            }
        }
    }

    private func summaryItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)

                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }

    private var sourcesBreakdown: some View {
        let sources = Dictionary(grouping: filteredWorkouts) { $0.source }

        return HStack(spacing: 12) {
            ForEach(Array(sources.keys).sorted(by: { $0.displayName < $1.displayName }), id: \.self) { source in
                HStack(spacing: 4) {
                    Image(systemName: source.icon)
                        .font(.system(size: 10))
                        .foregroundColor(source == .flexr ? DesignSystem.Colors.primary : .gray)

                    Text("\(sources[source]?.count ?? 0)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)

                    Text(source.displayName)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.05))
                .cornerRadius(6)
            }
        }
    }

    private var timeframePicker: some View {
        HStack(spacing: 8) {
            ForEach(ActivityTimeframe.allCases, id: \.self) { timeframe in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTimeframe = timeframe
                    }
                } label: {
                    Text(timeframe.label)
                        .font(.system(size: 14, weight: selectedTimeframe == timeframe ? .semibold : .regular))
                        .foregroundColor(selectedTimeframe == timeframe ? .black : .gray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedTimeframe == timeframe
                                ? DesignSystem.Colors.primary
                                : Color.white.opacity(0.05)
                        )
                        .cornerRadius(8)
                }
            }

            Spacer()
        }
    }

    private var filterToggle: some View {
        HStack {
            Text("External only")
                .font(.system(size: 14))
                .foregroundColor(.gray)

            Toggle("", isOn: $showOnlyExternal)
                .labelsHidden()
                .tint(DesignSystem.Colors.primary)

            Spacer()
        }
    }

    private var activityList: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredWorkouts) { workout in
                ExternalWorkoutCard(workout: workout)
                    .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 100)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.primary))

            Text("Loading activity...")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("No Activity Found")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Text("Complete a workout or sync from HealthKit")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Methods

    private func loadWorkouts() async {
        isLoading = true
        allWorkouts = await healthKitService.fetchAllWorkouts(daysBack: 90)
        isLoading = false
    }

    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
}

// MARK: - Activity Timeframe

enum ActivityTimeframe: String, CaseIterable {
    case week
    case month
    case threeMonths

    var label: String {
        switch self {
        case .week: return "7 Days"
        case .month: return "30 Days"
        case .threeMonths: return "90 Days"
        }
    }
}

// MARK: - External Workout Card

struct ExternalWorkoutCard: View {
    let workout: ExternalWorkout

    var body: some View {
        FlexrCard {
            HStack(spacing: 12) {
                // Activity Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: workout.activityType.color).opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: workout.activityType.icon)
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: workout.activityType.color))
                }

                // Details
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(workout.activityType.displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)

                        // Source badge
                        SourceBadge(source: workout.source, sourceName: workout.sourceName)
                    }

                    HStack(spacing: 12) {
                        // Duration
                        Label(workout.formattedDuration, systemImage: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)

                        // Distance (if available)
                        if let distance = workout.formattedDistance {
                            Label(distance, systemImage: "figure.run")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }

                        // Calories (if available)
                        if let cal = workout.activeCalories, cal > 0 {
                            Label("\(Int(cal)) cal", systemImage: "flame")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                }

                Spacer()

                // Date
                VStack(alignment: .trailing, spacing: 2) {
                    Text(workout.date.formatted(.dateTime.weekday(.abbreviated)))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)

                    Text(workout.date.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

// MARK: - Source Badge

struct SourceBadge: View {
    let source: WorkoutSource
    let sourceName: String

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: source.icon)
                .font(.system(size: 8))

            Text(displayName)
                .font(.system(size: 9, weight: .medium))
        }
        .foregroundColor(badgeColor)
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(badgeColor.opacity(0.15))
        .cornerRadius(4)
    }

    private var displayName: String {
        if source == .flexr {
            return "FLEXR"
        } else if source == .healthKit {
            // Show actual app name for HealthKit sources
            return shortenedSourceName
        }
        return source.displayName
    }

    private var shortenedSourceName: String {
        let name = sourceName
        if name.count > 12 {
            return String(name.prefix(10)) + "..."
        }
        return name
    }

    private var badgeColor: Color {
        switch source {
        case .flexr:
            return DesignSystem.Colors.primary
        case .appleFitness:
            return .green
        case .appleWatch:
            return .pink
        case .strava:
            return .orange
        default:
            return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AllActivityView()
            .environmentObject(HealthKitService.shared)
    }
}
