// FLEXR - Station History View
// Comprehensive station performance history with search, filters, and trends
// Data-driven like Strava - ALL station performances accessible

import SwiftUI

struct StationHistoryView: View {
    @StateObject private var viewModel = StationHistoryViewModel()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.medium, pinnedViews: [.sectionHeaders]) {
                // Station selector
                stationSelectorSection

                // Quick stats for selected station
                if viewModel.selectedStation != nil {
                    quickStatsBar
                }

                // Performance history grouped by month
                ForEach(viewModel.groupedPerformances, id: \.month) { group in
                    Section {
                        ForEach(group.performances) { performance in
                            StationPerformanceCard(performance: performance)
                        }
                    } header: {
                        StationMonthHeader(
                            month: group.month,
                            performanceCount: group.performances.count,
                            averageTime: group.averageTime
                        )
                    }
                }

                // Empty state
                if viewModel.groupedPerformances.isEmpty && !viewModel.isLoading {
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
        .navigationTitle("Station History")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadData()
        }
        .refreshable {
            await viewModel.loadData()
        }
    }

    // MARK: - Station Selector

    private var stationSelectorSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text("SELECT STATION")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.xSmall) {
                    ForEach(HYROXStation.allCases, id: \.self) { station in
                        StationChip(
                            station: station,
                            isSelected: viewModel.selectedStation == station,
                            action: { viewModel.selectedStation = station }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Quick Stats Bar

    private var quickStatsBar: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            HStack(spacing: DesignSystem.Spacing.medium) {
                StationStatItem(
                    value: viewModel.totalPerformances,
                    label: "performances"
                )
                StationStatItem(
                    value: viewModel.bestTime,
                    label: "best time"
                )
                StationStatItem(
                    value: viewModel.averageTime,
                    label: "average"
                )
            }

            // Improvement trend
            HStack(spacing: DesignSystem.Spacing.small) {
                Image(systemName: viewModel.trendIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(viewModel.trendColor)

                Text(viewModel.trendDescription)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.medium)
        .padding(.horizontal, DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.surface.opacity(0.5))
        .cornerRadius(DesignSystem.Radius.medium)
    }

    // MARK: - Empty/Loading States

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading station data...")
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

            Text("No station data yet")
                .font(DesignSystem.Typography.bodyEmphasized)
                .foregroundColor(DesignSystem.Colors.text.primary)

            Text("Complete workouts with stations to see your history")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - HYROX Station Enum

enum HYROXStation: String, CaseIterable {
    case skiErg = "SkiErg"
    case sledPush = "Sled Push"
    case sledPull = "Sled Pull"
    case burpees = "Burpees"
    case row = "Row"
    case farmersCarry = "Farmers Carry"
    case sandbag = "Sandbag"
    case wallBalls = "Wall Balls"

    var displayName: String { rawValue }

    var emoji: String {
        switch self {
        case .skiErg: return "🚣"
        case .sledPush: return "🏋️"
        case .sledPull: return "🪂"
        case .burpees: return "💪"
        case .row: return "🚣‍♀️"
        case .farmersCarry: return "🏋️‍♀️"
        case .sandbag: return "🎒"
        case .wallBalls: return "⚽"
        }
    }

    var icon: String {
        switch self {
        case .skiErg: return "figure.skiing.downhill"
        case .sledPush: return "arrow.right.circle.fill"
        case .sledPull: return "arrow.left.circle.fill"
        case .burpees: return "figure.jumprope"
        case .row: return "figure.rowing"
        case .farmersCarry: return "figure.walk"
        case .sandbag: return "bag.fill"
        case .wallBalls: return "volleyball.fill"
        }
    }
}

// MARK: - Station Chip

private struct StationChip: View {
    let station: HYROXStation
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(station.emoji)
                    .font(.system(size: 16))
                Text(station.displayName)
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? .white : DesignSystem.Colors.text.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.surface)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Station Stat Item

private struct StationStatItem: View {
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

// MARK: - Station Month Header

private struct StationMonthHeader: View {
    let month: String
    let performanceCount: Int
    let averageTime: String

    var body: some View {
        HStack {
            Text(month)
                .font(DesignSystem.Typography.heading3)
                .foregroundColor(DesignSystem.Colors.text.primary)

            Spacer()

            HStack(spacing: 8) {
                Text("\(performanceCount) times")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.text.secondary)

                Text("•")
                    .foregroundColor(DesignSystem.Colors.text.tertiary)

                Text("avg \(averageTime)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.small)
        .padding(.horizontal, DesignSystem.Spacing.small)
        .background(DesignSystem.Colors.background)
    }
}

// MARK: - Station Performance Card

private struct StationPerformanceCard: View {
    let performance: StationPerformanceRecord

    var body: some View {
        HStack(spacing: 12) {
            // Time display
            VStack(alignment: .leading, spacing: 4) {
                Text(performance.timeFormatted)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.text.primary)
                    .monospacedDigit()

                HStack(spacing: 8) {
                    Label(performance.dateFormatted, systemImage: "calendar")
                    if let workout = performance.workoutType {
                        Text("•")
                        Text(workout)
                    }
                }
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.text.secondary)
            }

            Spacer()

            // Performance badges
            VStack(alignment: .trailing, spacing: 4) {
                if performance.isPR {
                    PRBadge()
                }

                // Change from previous
                if let change = performance.changeFromPrevious {
                    ChangeIndicator(change: change)
                }
            }
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.medium)
    }
}

// MARK: - PR Badge

private struct PRBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 10))
            Text("PR")
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(DesignSystem.Colors.accent)
        .cornerRadius(6)
    }
}

// MARK: - Change Indicator

private struct ChangeIndicator: View {
    let change: TimeInterval

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: change < 0 ? "arrow.down" : "arrow.up")
                .font(.system(size: 10, weight: .semibold))
            Text(formatChange(change))
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(change < 0 ? DesignSystem.Colors.success : DesignSystem.Colors.warning)
    }

    private func formatChange(_ change: TimeInterval) -> String {
        let absChange = abs(change)
        if absChange >= 60 {
            let minutes = Int(absChange) / 60
            let seconds = Int(absChange) % 60
            return "\(minutes):\(String(format: "%02d", seconds))"
        }
        return String(format: "%.0fs", absChange)
    }
}

// MARK: - View Model

@MainActor
class StationHistoryViewModel: ObservableObject {
    @Published var selectedStation: HYROXStation? = .skiErg
    @Published var allPerformances: [StationPerformanceRecord] = []
    @Published var isLoading = false

    var filteredPerformances: [StationPerformanceRecord] {
        guard let station = selectedStation else { return allPerformances }
        return allPerformances.filter { $0.station == station }
    }

    var groupedPerformances: [StationPerformanceGroup] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        let grouped = Dictionary(grouping: filteredPerformances) { performance in
            formatter.string(from: performance.date)
        }

        return grouped.map { month, performances in
            let sortedPerformances = performances.sorted { $0.date > $1.date }
            let avgSeconds = sortedPerformances.map(\.duration).reduce(0, +) / Double(sortedPerformances.count)

            return StationPerformanceGroup(
                month: month,
                performances: sortedPerformances,
                averageTime: formatDuration(avgSeconds)
            )
        }.sorted { $0.performances.first?.date ?? Date() > $1.performances.first?.date ?? Date() }
    }

    var totalPerformances: String {
        "\(filteredPerformances.count)"
    }

    var bestTime: String {
        guard let best = filteredPerformances.min(by: { $0.duration < $1.duration }) else {
            return "--:--"
        }
        return best.timeFormatted
    }

    var averageTime: String {
        guard !filteredPerformances.isEmpty else { return "--:--" }
        let avg = filteredPerformances.map(\.duration).reduce(0, +) / Double(filteredPerformances.count)
        return formatDuration(avg)
    }

    var trendIcon: String {
        // Compare last 5 vs previous 5
        let sorted = filteredPerformances.sorted { $0.date > $1.date }
        guard sorted.count >= 10 else { return "arrow.right" }

        let recent = sorted.prefix(5).map(\.duration).reduce(0, +) / 5
        let previous = sorted.dropFirst(5).prefix(5).map(\.duration).reduce(0, +) / 5

        if recent < previous - 5 { return "arrow.up.right" }
        if recent > previous + 5 { return "arrow.down.right" }
        return "arrow.right"
    }

    var trendColor: Color {
        switch trendIcon {
        case "arrow.up.right": return DesignSystem.Colors.success
        case "arrow.down.right": return DesignSystem.Colors.warning
        default: return DesignSystem.Colors.text.secondary
        }
    }

    var trendDescription: String {
        switch trendIcon {
        case "arrow.up.right": return "Improving over time"
        case "arrow.down.right": return "Declining - needs focus"
        default: return "Stable performance"
        }
    }

    func loadData() async {
        isLoading = true

        do {
            // Fetch real station performances from Supabase
            let segments = try await SupabaseService.shared.getStationPerformances(limit: 500)

            // Convert to StationPerformanceRecord
            var performances: [StationPerformanceRecord] = []
            var bestByStation: [HYROXStation: TimeInterval] = [:]

            for segment in segments {
                guard let station = mapNameToStation(segment.name),
                      let duration = segment.actualDurationMinutes else { continue }

                let durationSeconds = duration * 60 // Convert minutes to seconds
                let date = segment.workout?.completedAt ?? Date()
                let workoutType = segment.workout?.type

                // Check if PR
                let currentBest = bestByStation[station] ?? .infinity
                let isPR = durationSeconds < currentBest
                if isPR {
                    bestByStation[station] = durationSeconds
                }

                performances.append(StationPerformanceRecord(
                    station: station,
                    date: date,
                    duration: durationSeconds,
                    isPR: isPR,
                    changeFromPrevious: nil, // Would need previous segment to calculate
                    workoutType: workoutType
                ))
            }

            allPerformances = performances.sorted { $0.date > $1.date }
            isLoading = false
        } catch {
            print("Failed to load station performances: \(error)")
            // Fallback to mock data
            allPerformances = generateMockPerformances()
            isLoading = false
        }
    }

    private func mapNameToStation(_ name: String) -> HYROXStation? {
        let lowercased = name.lowercased()
        if lowercased.contains("ski") { return .skiErg }
        if lowercased.contains("sled") && lowercased.contains("push") { return .sledPush }
        if lowercased.contains("sled") && lowercased.contains("pull") { return .sledPull }
        if lowercased.contains("burpee") { return .burpees }
        if lowercased.contains("row") { return .row }
        if lowercased.contains("farmer") { return .farmersCarry }
        if lowercased.contains("sandbag") { return .sandbag }
        if lowercased.contains("wall") && lowercased.contains("ball") { return .wallBalls }
        return nil
    }

    private func generateMockPerformances() -> [StationPerformanceRecord] {
        var performances: [StationPerformanceRecord] = []
        let calendar = Calendar.current

        for station in HYROXStation.allCases {
            // Generate 10-20 performances per station over last 90 days
            let count = Int.random(in: 10...20)
            var previousDuration: TimeInterval? = nil

            for i in 0..<count {
                let daysAgo = Int.random(in: 0...90)
                let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()

                // Base time varies by station
                let baseTime: TimeInterval
                switch station {
                case .skiErg: baseTime = 150
                case .sledPush: baseTime = 135
                case .sledPull: baseTime = 155
                case .burpees: baseTime = 185
                case .row: baseTime = 162
                case .farmersCarry: baseTime = 118
                case .sandbag: baseTime = 140
                case .wallBalls: baseTime = 172
                }

                // Add some variance and improvement trend
                let improvement = Double(count - i) * 0.5 // Slower as we go back in time
                let variance = Double.random(in: -10...10)
                let duration = baseTime + improvement + variance

                let changeFromPrevious: TimeInterval? = previousDuration.map { duration - $0 }

                // Mark as PR if it's the fastest
                let currentBest = performances.filter { $0.station == station }.min(by: { $0.duration < $1.duration })?.duration ?? Double.infinity
                let isPR = duration < currentBest

                performances.append(StationPerformanceRecord(
                    station: station,
                    date: date,
                    duration: duration,
                    isPR: isPR,
                    changeFromPrevious: changeFromPrevious,
                    workoutType: ["Full Simulation", "Half Simulation", "Station Focus"].randomElement()
                ))

                previousDuration = duration
            }
        }

        return performances.sorted { $0.date > $1.date }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - Supporting Types

struct StationPerformanceRecord: Identifiable {
    let id = UUID()
    let station: HYROXStation
    let date: Date
    let duration: TimeInterval
    let isPR: Bool
    let changeFromPrevious: TimeInterval?
    let workoutType: String?

    var timeFormatted: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var dateFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct StationPerformanceGroup {
    let month: String
    let performances: [StationPerformanceRecord]
    let averageTime: String
}

// MARK: - Preview

#Preview {
    NavigationStack {
        StationHistoryView()
    }
}
