import SwiftUI

/// Running History View - ALL runs with comprehensive filtering and sorting
/// Like Strava/Runna: FULL data access, not just recent runs
/// Features: Search, filter by type, sort by various metrics, monthly grouping
struct RunningHistoryView: View {
    @StateObject private var viewModel = RunningHistoryViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            DesignSystem.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Search and filter bar
                searchAndFilterBar

                // Statistics summary
                statisticsSummaryBar

                // Runs list (ALL runs, grouped by month)
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.filteredRuns.isEmpty {
                    emptyStateView
                } else {
                    runsListView
                }
            }
        }
        .navigationTitle("All Runs")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.showingFilters.toggle()
                } label: {
                    Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingFilters) {
            FiltersSheet(viewModel: viewModel)
        }
        .task {
            await viewModel.loadAllRuns()
        }
    }

    // MARK: - Search and Filter Bar

    private var searchAndFilterBar: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DesignSystem.Colors.text.tertiary)

                TextField("Search runs...", text: $viewModel.searchText)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.white)

                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.text.tertiary)
                    }
                }
            }
            .padding(DesignSystem.Spacing.medium)
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.Radius.medium)

            // Quick filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.small) {
                    QuickFilterChip(
                        title: "All",
                        isSelected: viewModel.selectedQuickFilter == .all,
                        action: { viewModel.selectedQuickFilter = .all }
                    )
                    QuickFilterChip(
                        title: "Zone 2",
                        isSelected: viewModel.selectedQuickFilter == .zone2,
                        action: { viewModel.selectedQuickFilter = .zone2 }
                    )
                    QuickFilterChip(
                        title: "Race Pace",
                        isSelected: viewModel.selectedQuickFilter == .racePace,
                        action: { viewModel.selectedQuickFilter = .racePace }
                    )
                    QuickFilterChip(
                        title: "Intervals",
                        isSelected: viewModel.selectedQuickFilter == .intervals,
                        action: { viewModel.selectedQuickFilter = .intervals }
                    )
                    QuickFilterChip(
                        title: "This Month",
                        isSelected: viewModel.selectedQuickFilter == .thisMonth,
                        action: { viewModel.selectedQuickFilter = .thisMonth }
                    )
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.screenHorizontal)
        .padding(.top, DesignSystem.Spacing.small)
    }

    // MARK: - Statistics Summary Bar

    private var statisticsSummaryBar: some View {
        HStack {
            Text("\(viewModel.filteredRuns.count) runs")
                .font(DesignSystem.Typography.heading3)
                .foregroundColor(.white)

            Spacer()

            NavigationLink(destination: RunningStatsView()) {
                HStack(spacing: 6) {
                    Text("View Stats")
                        .font(DesignSystem.Typography.bodyEmphasized)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(DesignSystem.Colors.primary)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.screenHorizontal)
        .padding(.vertical, DesignSystem.Spacing.large)
    }

    // MARK: - Runs List

    private var runsListView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.medium, pinnedViews: [.sectionHeaders]) {
                ForEach(viewModel.groupedRuns, id: \.month) { group in
                    Section {
                        VStack(spacing: DesignSystem.Spacing.small) {
                            ForEach(group.runs) { run in
                                NavigationLink(destination: RunDetailView(run: run)) {
                                    ExpandedRunCard(run: run, showMonth: false)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    } header: {
                        MonthHeader(month: group.month, totalDistance: group.totalDistance, runCount: group.runs.count)
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.screenHorizontal)
            .padding(.top, DesignSystem.Spacing.medium)
            .padding(.bottom, DesignSystem.Spacing.screenBottom)
        }
    }

    // MARK: - Empty/Loading States

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(DesignSystem.Colors.primary)
            Text("Loading all runs...")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.text.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 60))
                .foregroundColor(DesignSystem.Colors.text.tertiary)

            Text("No runs found")
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(.white)

            Text(viewModel.hasActiveFilters
                 ? "Try adjusting your filters"
                 : "Start tracking your runs to see them here")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Quick Filter Chip

struct QuickFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.footnoteEmphasized)
                .foregroundColor(isSelected ? .white : DesignSystem.Colors.text.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.surface)
                .cornerRadius(16)
        }
    }
}


// MARK: - Month Header

struct MonthHeader: View {
    let month: String
    let totalDistance: Double
    let runCount: Int

    var body: some View {
        HStack {
            Text(month)
                .font(DesignSystem.Typography.heading3)
                .foregroundColor(.white)

            Spacer()

            Text(String(format: "%.0f km", totalDistance))
                .font(DesignSystem.Typography.bodyEmphasized)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .monospacedDigit()
        }
        .padding(.horizontal, DesignSystem.Spacing.screenHorizontal)
        .padding(.vertical, DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.background)
    }
}

// MARK: - Expanded Run Card (More detail than RunCard)

struct ExpandedRunCard: View {
    let run: RecentRun
    let showMonth: Bool

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            // Type indicator - smaller, cleaner
            ZStack {
                Circle()
                    .fill(run.type.color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: run.type.icon)
                    .font(.system(size: 20))
                    .foregroundColor(run.type.color)
            }

            // Run info - cleaner layout
            VStack(alignment: .leading, spacing: 6) {
                Text(String(format: "%.1f km", run.distance))
                    .font(DesignSystem.Typography.heading3)
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    Text(run.avgPace)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.primary)
                        .monospacedDigit()

                    Text("•")
                        .foregroundColor(DesignSystem.Colors.text.tertiary)

                    Text(run.duration)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                        .monospacedDigit()
                }

                Text(formatShortDate(run.date))
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.text.tertiary)
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.text.tertiary)
        }
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.medium)
    }

    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d • h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Filters Sheet

struct FiltersSheet: View {
    @ObservedObject var viewModel: RunningHistoryViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Sort By", selection: $viewModel.sortOption) {
                        Text("Date (Newest)").tag(HistorySortOption.dateNewest)
                        Text("Date (Oldest)").tag(HistorySortOption.dateOldest)
                        Text("Distance (Longest)").tag(HistorySortOption.distanceLongest)
                        Text("Distance (Shortest)").tag(HistorySortOption.distanceShortest)
                        Text("Pace (Fastest)").tag(HistorySortOption.paceFastest)
                        Text("Pace (Slowest)").tag(HistorySortOption.paceSlowest)
                    }
                } header: {
                    Text("SORT")
                }

                Section {
                    Toggle("Zone 2", isOn: $viewModel.filterZone2)
                    Toggle("Race Pace", isOn: $viewModel.filterRacePace)
                    Toggle("Intervals", isOn: $viewModel.filterIntervals)
                } header: {
                    Text("RUN TYPE")
                }

                Section {
                    Picker("Time Period", selection: $viewModel.timePeriod) {
                        Text("All Time").tag(TimePeriod.allTime)
                        Text("This Month").tag(TimePeriod.thisMonth)
                        Text("Last 30 Days").tag(TimePeriod.last30Days)
                        Text("Last 90 Days").tag(TimePeriod.last90Days)
                        Text("This Year").tag(TimePeriod.thisYear)
                    }
                } header: {
                    Text("TIME PERIOD")
                }

                Section {
                    HStack {
                        Text("Minimum Distance")
                        Spacer()
                        Text(String(format: "%.1f km", viewModel.minDistance))
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                    }
                    Slider(value: $viewModel.minDistance, in: 0...25, step: 0.5)
                } header: {
                    Text("DISTANCE")
                }

                Section {
                    Button("Reset All Filters") {
                        viewModel.resetFilters()
                    }
                    .foregroundColor(DesignSystem.Colors.error)
                }
            }
            .navigationTitle("Filters & Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - View Model

enum QuickFilter {
    case all, zone2, racePace, intervals, thisMonth
}

enum HistorySortOption {
    case dateNewest, dateOldest, distanceLongest, distanceShortest, paceFastest, paceSlowest
}

enum TimePeriod {
    case allTime, thisMonth, last30Days, last90Days, thisYear
}

struct RunGroup {
    let month: String
    let runs: [RecentRun]

    var totalDistance: Double {
        runs.reduce(0) { $0 + $1.distance }
    }
}

class RunningHistoryViewModel: ObservableObject {
    @Published var allRuns: [RecentRun] = []
    @Published var isLoading = false

    // Search and filters
    @Published var searchText = ""
    @Published var selectedQuickFilter: QuickFilter = .all
    @Published var sortOption: HistorySortOption = .dateNewest
    @Published var timePeriod: TimePeriod = .allTime
    @Published var filterZone2 = false
    @Published var filterRacePace = false
    @Published var filterIntervals = false
    @Published var minDistance: Double = 0
    @Published var showingFilters = false

    var hasActiveFilters: Bool {
        selectedQuickFilter != .all ||
        filterZone2 || filterRacePace || filterIntervals ||
        timePeriod != .allTime ||
        minDistance > 0 ||
        !searchText.isEmpty
    }

    var filteredRuns: [RecentRun] {
        var runs = allRuns

        // Search filter
        if !searchText.isEmpty {
            runs = runs.filter { run in
                run.routeName?.localizedCaseInsensitiveContains(searchText) ?? false ||
                run.type.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Quick filter
        switch selectedQuickFilter {
        case .all:
            break
        case .zone2:
            runs = runs.filter { $0.type == .zone2 }
        case .racePace:
            runs = runs.filter { $0.type == .racePace }
        case .intervals:
            runs = runs.filter { $0.type == .intervals }
        case .thisMonth:
            let calendar = Calendar.current
            runs = runs.filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .month) }
        }

        // Type filters
        if filterZone2 || filterRacePace || filterIntervals {
            runs = runs.filter { run in
                (filterZone2 && run.type == .zone2) ||
                (filterRacePace && run.type == .racePace) ||
                (filterIntervals && run.type == .intervals)
            }
        }

        // Time period filter
        let calendar = Calendar.current
        let now = Date()

        switch timePeriod {
        case .allTime:
            break
        case .thisMonth:
            runs = runs.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
        case .last30Days:
            let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now)!
            runs = runs.filter { $0.date >= thirtyDaysAgo }
        case .last90Days:
            let ninetyDaysAgo = calendar.date(byAdding: .day, value: -90, to: now)!
            runs = runs.filter { $0.date >= ninetyDaysAgo }
        case .thisYear:
            runs = runs.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .year) }
        }

        // Distance filter
        if minDistance > 0 {
            runs = runs.filter { $0.distance >= minDistance }
        }

        // Sort
        switch sortOption {
        case .dateNewest:
            runs.sort { $0.date > $1.date }
        case .dateOldest:
            runs.sort { $0.date < $1.date }
        case .distanceLongest:
            runs.sort { $0.distance > $1.distance }
        case .distanceShortest:
            runs.sort { $0.distance < $1.distance }
        case .paceFastest:
            runs.sort { paceToSeconds($0.avgPace) < paceToSeconds($1.avgPace) }
        case .paceSlowest:
            runs.sort { paceToSeconds($0.avgPace) > paceToSeconds($1.avgPace) }
        }

        return runs
    }

    var groupedRuns: [RunGroup] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        let grouped = Dictionary(grouping: filteredRuns) { run in
            formatter.string(from: run.date)
        }

        return grouped.map { month, runs in
            RunGroup(month: month, runs: runs)
        }.sorted { group1, group2 in
            guard let date1 = formatter.date(from: group1.month),
                  let date2 = formatter.date(from: group2.month) else {
                return false
            }
            return date1 > date2
        }
    }

    var totalDistance: Double {
        filteredRuns.reduce(0) { $0 + $1.distance }
    }

    var totalTimeString: String {
        let totalSeconds = filteredRuns.compactMap { durationToSeconds($0.duration) }.reduce(0, +)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        return String(format: "%dh %dm", hours, minutes)
    }

    var averagePaceString: String {
        guard !filteredRuns.isEmpty else { return "0:00" }
        let avgSeconds = filteredRuns.compactMap { paceToSeconds($0.avgPace) }.reduce(0, +) / filteredRuns.count
        return secondsToPace(avgSeconds)
    }

    func resetFilters() {
        searchText = ""
        selectedQuickFilter = .all
        sortOption = .dateNewest
        timePeriod = .allTime
        filterZone2 = false
        filterRacePace = false
        filterIntervals = false
        minDistance = 0
    }

    func loadAllRuns() async {
        isLoading = true

        do {
            // Fetch real running sessions from Supabase
            let sessions = try await SupabaseService.shared.getRunningSessions(limit: 500)

            // Convert RunningSession to RecentRun for display
            let runs = sessions.map { session -> RecentRun in
                RecentRun(
                    date: session.startedAt ?? session.createdAt,
                    distance: session.distanceKm,
                    duration: session.displayDuration,
                    avgPace: formatPaceFromSeconds(session.avgPacePerKm),
                    type: mapSessionTypeToRunType(session.sessionType),
                    routeName: session.notes
                )
            }

            await MainActor.run {
                allRuns = runs
                isLoading = false
            }
        } catch {
            print("Failed to load running sessions: \(error)")
            // Fallback to mock data if no real data
            await MainActor.run {
                allRuns = generateMockRuns(count: 20) // Fewer mock runs as fallback
                isLoading = false
            }
        }
    }

    private func formatPaceFromSeconds(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func mapSessionTypeToRunType(_ sessionType: RunningSessionType) -> RecentRun.RunType {
        switch sessionType {
        case .easy, .recovery, .longRun:
            return .zone2
        case .threshold, .timeTrial5k, .timeTrial10k:
            return .racePace
        case .intervals:
            return .intervals
        }
    }

    // MARK: - Helper Functions

    private func paceToSeconds(_ pace: String) -> Int {
        let components = pace.split(separator: ":")
        guard components.count == 2,
              let minutes = Int(components[0]),
              let seconds = Int(components[1]) else {
            return 0
        }
        return minutes * 60 + seconds
    }

    private func secondsToPace(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    private func durationToSeconds(_ duration: String) -> Int? {
        let components = duration.split(separator: ":")
        guard components.count == 2,
              let minutes = Int(components[0]),
              let seconds = Int(components[1]) else {
            return nil
        }
        return minutes * 60 + seconds
    }

    private func generateMockRuns(count: Int) -> [RecentRun] {
        var runs: [RecentRun] = []
        let types: [RecentRun.RunType] = [.zone2, .racePace, .intervals]
        let routeNames = ["Morning Loop", "Track Session", "Long Run", "Hill Repeats", "Recovery Run", "Tempo Run", "Easy Run", "Speed Work"]

        for i in 0..<count {
            let daysAgo = Double(i * 3) // Spread runs over time
            let date = Date().addingTimeInterval(-daysAgo * 86400)
            let type = types[i % types.count]
            let distance = Double.random(in: 3.0...21.0)
            let paceSeconds = Int.random(in: 240...330) // 4:00 to 5:30 pace
            let pace = String(format: "%d:%02d", paceSeconds / 60, paceSeconds % 60)
            let durationSeconds = Int(distance * Double(paceSeconds))
            let duration = String(format: "%d:%02d", durationSeconds / 60, durationSeconds % 60)

            runs.append(RecentRun(
                date: date,
                distance: distance,
                duration: duration,
                avgPace: pace,
                type: type,
                routeName: routeNames[i % routeNames.count]
            ))
        }

        return runs.sorted { $0.date > $1.date }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RunningHistoryView()
    }
}
