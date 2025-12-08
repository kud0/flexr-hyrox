// FLEXR - Workout History View
// Comprehensive workout history with search, filters, and monthly grouping
// Data-driven like Strava - ALL workouts accessible

import SwiftUI

struct WorkoutHistoryView: View {
    @StateObject private var viewModel = WorkoutHistoryViewModel()
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.medium, pinnedViews: [.sectionHeaders]) {
                // Search and filters
                searchAndFiltersSection

                // Quick stats bar
                if !viewModel.filteredWorkouts.isEmpty {
                    quickStatsBar
                }

                // Workouts grouped by month
                ForEach(viewModel.groupedWorkouts, id: \.month) { group in
                    Section {
                        ForEach(group.workouts) { workout in
                            NavigationLink(destination: WorkoutHistoryDetailView(workout: workout)) {
                                WorkoutHistoryCard(workout: workout)
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        MonthSectionHeader(
                            month: group.month,
                            workoutCount: group.workouts.count,
                            totalTime: group.totalTime
                        )
                    }
                }

                // Empty state
                if viewModel.filteredWorkouts.isEmpty && !viewModel.isLoading {
                    emptyStateView
                }

                // Loading
                if viewModel.isLoading {
                    loadingView
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.screenHorizontal)
            .padding(.top, DesignSystem.Spacing.small)
            .padding(.bottom, DesignSystem.Spacing.screenBottom)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle("Workouts")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $viewModel.searchText, prompt: "Search workouts...")
        .task {
            await viewModel.loadWorkouts()
        }
        .refreshable {
            await viewModel.loadWorkouts()
        }
        .sheet(isPresented: $viewModel.showingFilters) {
            WorkoutFiltersSheet(viewModel: viewModel)
        }
    }

    // MARK: - Search and Filters

    private var searchAndFiltersSection: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            // Quick filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.xSmall) {
                    WorkoutFilterChip(
                        label: "All",
                        isSelected: viewModel.selectedType == nil,
                        action: { viewModel.selectedType = nil }
                    )
                    WorkoutFilterChip(
                        label: "Full Sim",
                        isSelected: viewModel.selectedType == .fullSimulation,
                        action: { viewModel.selectedType = .fullSimulation }
                    )
                    WorkoutFilterChip(
                        label: "Half Sim",
                        isSelected: viewModel.selectedType == .halfSimulation,
                        action: { viewModel.selectedType = .halfSimulation }
                    )
                    WorkoutFilterChip(
                        label: "Stations",
                        isSelected: viewModel.selectedType == .stationFocus,
                        action: { viewModel.selectedType = .stationFocus }
                    )
                    WorkoutFilterChip(
                        label: "Running",
                        isSelected: viewModel.selectedType == .running,
                        action: { viewModel.selectedType = .running }
                    )
                }
            }

            // Filter button
            Button {
                viewModel.showingFilters = true
            } label: {
                Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    .font(.system(size: 20))
                    .foregroundColor(viewModel.hasActiveFilters ? DesignSystem.Colors.primary : DesignSystem.Colors.text.secondary)
            }
        }
    }

    // MARK: - Quick Stats Bar

    private var quickStatsBar: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            QuickStatItem(
                value: "\(viewModel.filteredWorkouts.count)",
                label: "workouts"
            )
            QuickStatItem(
                value: viewModel.totalTimeFormatted,
                label: "total time"
            )
            QuickStatItem(
                value: "\(viewModel.prCount)",
                label: "PRs"
            )
        }
        .padding(.vertical, DesignSystem.Spacing.small)
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.surface.opacity(0.5))
        .cornerRadius(DesignSystem.Radius.medium)
    }

    // MARK: - Empty/Loading States

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading workouts...")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.text.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 36))
                .foregroundColor(DesignSystem.Colors.text.tertiary)

            Text(viewModel.hasActiveFilters ? "No matching workouts" : "No workouts yet")
                .font(DesignSystem.Typography.bodyEmphasized)
                .foregroundColor(DesignSystem.Colors.text.primary)

            Text(viewModel.hasActiveFilters ? "Try adjusting your filters" : "Complete your first workout")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.text.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - ViewModel

@MainActor
class WorkoutHistoryViewModel: ObservableObject {
    @Published var allWorkouts: [Workout] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var selectedType: WorkoutType?
    @Published var timePeriod: WorkoutTimePeriod = .allTime
    @Published var showingFilters = false

    var hasActiveFilters: Bool {
        selectedType != nil || timePeriod != .allTime || !searchText.isEmpty
    }

    var filteredWorkouts: [Workout] {
        var result = allWorkouts

        // Search filter
        if !searchText.isEmpty {
            result = result.filter { workout in
                workout.type.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Type filter
        if let type = selectedType {
            result = result.filter { $0.type == type }
        }

        // Time period filter
        switch timePeriod {
        case .allTime:
            break
        case .thisMonth:
            let calendar = Calendar.current
            result = result.filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .month) }
        case .last30Days:
            let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            result = result.filter { $0.date >= cutoff }
        case .thisYear:
            let calendar = Calendar.current
            result = result.filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .year) }
        }

        return result.sorted { $0.date > $1.date }
    }

    var groupedWorkouts: [WorkoutGroup] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        let grouped = Dictionary(grouping: filteredWorkouts) { workout in
            formatter.string(from: workout.date)
        }

        return grouped.map { month, workouts in
            WorkoutGroup(
                month: month,
                workouts: workouts.sorted { $0.date > $1.date }
            )
        }.sorted { $0.workouts.first?.date ?? Date() > $1.workouts.first?.date ?? Date() }
    }

    var totalTimeFormatted: String {
        let totalSeconds = filteredWorkouts.compactMap(\.totalDuration).reduce(0, +)
        let hours = Int(totalSeconds) / 3600
        let minutes = (Int(totalSeconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var prCount: Int {
        // Simplified PR count - in real app, compare against all workouts
        filteredWorkouts.filter { $0.performanceScore > 90 }.count
    }

    func loadWorkouts() async {
        isLoading = true
        do {
            let workouts = try await SupabaseService.shared.getWorkoutHistory(limit: 500)
            self.allWorkouts = workouts
        } catch {
            print("Failed to load workouts: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Supporting Types

enum WorkoutTimePeriod {
    case allTime, thisMonth, last30Days, thisYear
}

struct WorkoutGroup {
    let month: String
    let workouts: [Workout]

    var totalTime: TimeInterval {
        workouts.compactMap(\.totalDuration).reduce(0, +)
    }
}

// MARK: - Filter Chip Component

private struct WorkoutFilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(DesignSystem.Typography.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : DesignSystem.Colors.text.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.surface)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quick Stat Item

private struct QuickStatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(DesignSystem.Colors.text.primary)
            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.text.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Month Section Header

private struct MonthSectionHeader: View {
    let month: String
    let workoutCount: Int
    let totalTime: TimeInterval

    var body: some View {
        HStack {
            Text(month)
                .font(DesignSystem.Typography.heading3)
                .foregroundColor(DesignSystem.Colors.text.primary)

            Spacer()

            HStack(spacing: 8) {
                Text("\(workoutCount) workouts")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.text.secondary)

                Text("•")
                    .foregroundColor(DesignSystem.Colors.text.tertiary)

                Text(formatTotalTime(totalTime))
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.small)
        .padding(.horizontal, DesignSystem.Spacing.small)
        .background(DesignSystem.Colors.background)
    }

    private func formatTotalTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - Workout History Card

private struct WorkoutHistoryCard: View {
    let workout: Workout

    var body: some View {
        HStack(spacing: 12) {
            // Type icon
            ZStack {
                Circle()
                    .fill(workout.type.color.opacity(0.2))
                    .frame(width: 48, height: 48)

                Image(systemName: workout.type.icon)
                    .font(.system(size: 20))
                    .foregroundColor(workout.type.color)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(workout.type.displayName)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.text.primary)

                    if workout.performanceScore > 90 {
                        Text("PR")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DesignSystem.Colors.accent)
                            .cornerRadius(4)
                    }
                }

                HStack(spacing: 12) {
                    Label(formatDate(workout.date), systemImage: "calendar")
                    if let duration = workout.totalDuration {
                        Label(formatDuration(duration), systemImage: "clock")
                    }
                }
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.text.secondary)
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.text.tertiary)
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.medium)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Filters Sheet

private struct WorkoutFiltersSheet: View {
    @ObservedObject var viewModel: WorkoutHistoryViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Time Period
                Section("Time Period") {
                    ForEach([WorkoutTimePeriod.allTime, .thisMonth, .last30Days, .thisYear], id: \.self) { period in
                        Button {
                            viewModel.timePeriod = period
                        } label: {
                            HStack {
                                Text(periodLabel(period))
                                    .foregroundColor(DesignSystem.Colors.text.primary)
                                Spacer()
                                if viewModel.timePeriod == period {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(DesignSystem.Colors.primary)
                                }
                            }
                        }
                    }
                }

                // Workout Type
                Section("Workout Type") {
                    Button {
                        viewModel.selectedType = nil
                    } label: {
                        HStack {
                            Text("All Types")
                                .foregroundColor(DesignSystem.Colors.text.primary)
                            Spacer()
                            if viewModel.selectedType == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(DesignSystem.Colors.primary)
                            }
                        }
                    }

                    ForEach(WorkoutType.allCases, id: \.self) { type in
                        Button {
                            viewModel.selectedType = type
                        } label: {
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(type.color)
                                Text(type.displayName)
                                    .foregroundColor(DesignSystem.Colors.text.primary)
                                Spacer()
                                if viewModel.selectedType == type {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(DesignSystem.Colors.primary)
                                }
                            }
                        }
                    }
                }

                // Clear Filters
                if viewModel.hasActiveFilters {
                    Section {
                        Button("Clear All Filters", role: .destructive) {
                            viewModel.selectedType = nil
                            viewModel.timePeriod = .allTime
                            viewModel.searchText = ""
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func periodLabel(_ period: WorkoutTimePeriod) -> String {
        switch period {
        case .allTime: return "All Time"
        case .thisMonth: return "This Month"
        case .last30Days: return "Last 30 Days"
        case .thisYear: return "This Year"
        }
    }
}

// Note: WorkoutSharingSheet is defined in Features/Analytics/Social/WorkoutSharingSheet.swift

// MARK: - Workout History Row (Legacy)

private struct WorkoutHistoryRow: View {
    let workout: Workout
    @State private var isPR: Bool = false
    @StateObject private var supabase = SupabaseService.shared

    var body: some View {
        HStack(spacing: 16) {
            // Workout type icon
            workoutTypeIcon

            // Workout info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(workout.type.displayName)
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.text.primary)

                    if isPR {
                        prBadge
                    }
                }

                HStack(spacing: 8) {
                    Label(formatDate(workout.date), systemImage: "calendar")

                    if let duration = workout.totalDuration {
                        Label(formatDuration(duration), systemImage: "clock")
                    }
                }
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.text.secondary)
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DesignSystem.Colors.text.tertiary)
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.medium)
        .task {
            await checkIfPR()
        }
    }

    private func checkIfPR() async {
        guard let duration = workout.totalDuration else {
            isPR = false
            return
        }

        do {
            // Fetch previous workouts of the same type
            let previousWorkouts = try await supabase.getWorkoutHistory(limit: 100)

            // Filter to same type and before this workout
            let sameTypeWorkouts = previousWorkouts.filter {
                $0.type == workout.type && $0.date < workout.date
            }

            // Check if this is a PR
            isPR = workout.isPR(comparedTo: sameTypeWorkouts)
        } catch {
            isPR = false
        }
    }

    private var workoutTypeIcon: some View {
        ZStack {
            Circle()
                .fill(workout.type.color.opacity(0.2))
                .frame(width: 44, height: 44)

            Image(systemName: workout.type.icon)
                .font(.system(size: 20))
                .foregroundStyle(workout.type.color)
        }
    }

    private var prBadge: some View {
        Text("PR")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(DesignSystem.Colors.accent)
            .cornerRadius(4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Workout History Detail View

struct WorkoutHistoryDetailView: View {
    let workout: Workout
    @State private var selectedSegment: WorkoutSegment?
    @State private var showSharingSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Workout summary card
                workoutSummaryCard

                // Segment breakdown
                if !workout.segments.isEmpty {
                    segmentBreakdownSection
                }

                // Performance metrics
                performanceMetricsSection
            }
            .padding()
        }
        .navigationTitle(workout.type.displayName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSharingSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(DesignSystem.Colors.primary)
                }
            }
        }
        .sheet(isPresented: $showSharingSheet) {
            WorkoutSharingSheet(workout: workout)
        }
    }

    // MARK: - Workout Summary Card

    private var workoutSummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.type.displayName)
                        .font(DesignSystem.Typography.heading2)
                        .foregroundStyle(DesignSystem.Colors.text.primary)

                    Text(formatDate(workout.date))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.text.secondary)
                }

                Spacer()

                // TODO: Add PR badge when we have previous workouts to compare
            }

            Divider()
                .background(DesignSystem.Colors.divider)

            // Key metrics
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                if let duration = workout.totalDuration {
                    metricItem(
                        icon: "clock.fill",
                        label: "Duration",
                        value: formatDuration(duration),
                        color: DesignSystem.Colors.primary
                    )
                }

                metricItem(
                    icon: "list.bullet",
                    label: "Segments",
                    value: "\(workout.segments.count)",
                    color: DesignSystem.Colors.secondary
                )

                metricItem(
                    icon: "checkmark.circle.fill",
                    label: "Completed",
                    value: "\(workout.segments.filter { $0.isCompleted }.count)",
                    color: DesignSystem.Colors.success
                )
            }
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.large)
    }

    // MARK: - Segment Breakdown

    private var segmentBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Segments")
                .font(DesignSystem.Typography.heading3)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            VStack(spacing: 8) {
                ForEach(Array(workout.segments.enumerated()), id: \.element.id) { index, segment in
                    segmentRow(segment: segment, index: index)
                }
            }
        }
    }

    private func segmentRow(segment: WorkoutSegment, index: Int) -> some View {
        Button {
            selectedSegment = segment
        } label: {
            HStack(spacing: 12) {
                // Segment number
                ZStack {
                    Circle()
                        .fill(segment.isCompleted ? DesignSystem.Colors.success.opacity(0.2) : DesignSystem.Colors.surface)
                        .frame(width: 32, height: 32)

                    Text("\(index + 1)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(segment.isCompleted ? DesignSystem.Colors.success : DesignSystem.Colors.text.secondary)
                }

                // Segment info
                VStack(alignment: .leading, spacing: 4) {
                    Text(segment.segmentType.displayName)
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.text.primary)

                    let target = segment.targetDescription
                    if !target.isEmpty {
                        Text(target)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.text.secondary)
                    }
                }

                Spacer()

                // Duration or status
                if segment.isCompleted {
                    if let duration = segment.actualDuration {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(formatDuration(duration))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(DesignSystem.Colors.text.primary)

                            if let target = segment.targetDuration {
                                let diff = duration - target
                                Text(diff < 0 ? "−\(formatDuration(abs(diff)))" : "+\(formatDuration(diff))")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(diff < 0 ? DesignSystem.Colors.success : DesignSystem.Colors.warning)
                            }
                        }
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(DesignSystem.Colors.success)
                    }
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(DesignSystem.Colors.text.tertiary)
                }

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DesignSystem.Colors.text.tertiary)
            }
            .padding()
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.Radius.medium)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Performance Metrics

    private var performanceMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance")
                .font(DesignSystem.Typography.heading3)
                .foregroundStyle(DesignSystem.Colors.text.primary)

            VStack(spacing: 12) {
                // Completion rate
                performanceMetricRow(
                    icon: "chart.pie.fill",
                    label: "Completion Rate",
                    value: "\(Int(completionRate * 100))%",
                    color: DesignSystem.Colors.primary
                )

                // Performance score
                performanceMetricRow(
                    icon: "star.fill",
                    label: "Performance Score",
                    value: String(format: "%.1f", workout.performanceScore),
                    color: DesignSystem.Colors.accent
                )

                // Average heart rate (if available)
                if let avgHR = workout.averageHeartRate {
                    performanceMetricRow(
                        icon: "heart.fill",
                        label: "Avg Heart Rate",
                        value: "\(Int(avgHR)) bpm",
                        color: DesignSystem.Colors.error
                    )
                }

                // Total distance (if available)
                let totalDist = workout.totalDistance
                if totalDist > 0 {
                    performanceMetricRow(
                        icon: "figure.run",
                        label: "Total Distance",
                        value: formatDistance(totalDist),
                        color: DesignSystem.Colors.secondary
                    )
                }
            }
        }
    }

    private func performanceMetricRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 24)

            Text(label)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.text.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DesignSystem.Colors.text.primary)
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.medium)
    }

    // MARK: - Helper Views

    private func metricItem(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(DesignSystem.Colors.text.primary)

            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.text.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var prBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 12))
            Text("PR")
                .font(.system(size: 12, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(DesignSystem.Colors.accent)
        .cornerRadius(8)
    }

    // MARK: - Computed Properties

    private var completionRate: Double {
        guard !workout.segments.isEmpty else { return 0 }
        let completed = workout.segments.filter { $0.isCompleted }.count
        return Double(completed) / Double(workout.segments.count)
    }

    // MARK: - Formatting Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func formatDistance(_ distance: Double) -> String {
        if distance >= 1000 {
            return String(format: "%.2f km", distance / 1000)
        }
        return "\(Int(distance))m"
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WorkoutHistoryView()
            .environmentObject(AppState())
    }
}
