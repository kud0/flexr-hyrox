import SwiftUI

/// All Stations Overview - Shows all 8 HYROX stations performance at a glance
/// Storytelling: Quick view of which stations are improving, stable, or need work
/// Design: Grid of station cards with trend indicators and tap to drill down
struct AllStationsOverviewView: View {
    @StateObject private var viewModel = AllStationsOverviewViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.analyticsSectionSpacing) {
                // Summary section
                summarySection

                // Key insight
                if let insight = viewModel.keyInsight {
                    InsightBanner(type: .positive, message: insight)
                }

                // Stations grid
                stationsGridSection

                // View all history link
                NavigationLink(destination: StationHistoryView()) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 18))
                        Text("View All Station History")
                            .font(DesignSystem.Typography.bodyEmphasized)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                    .padding()
                    .background(DesignSystem.Colors.surface)
                    .cornerRadius(DesignSystem.Radius.medium)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DesignSystem.Spacing.screenHorizontal)
            .padding(.top, DesignSystem.Spacing.screenTop)
            .padding(.bottom, DesignSystem.Spacing.screenBottom)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle("All Stations")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            // Overall station performance
            VStack(spacing: DesignSystem.Spacing.small) {
                Text("OVERALL STATION PERFORMANCE")
                    .font(DesignSystem.Typography.footnoteEmphasized)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
                    .tracking(0.5)

                Text("\(viewModel.improvingCount)")
                    .font(DesignSystem.Typography.metricHeroLarge)
                    .foregroundColor(DesignSystem.Colors.success)

                Text("stations improving")
                    .font(DesignSystem.Typography.bodyEmphasized)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Stations Grid

    private var stationsGridSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("8 HYROX STATIONS")
                .font(DesignSystem.Typography.sectionHeader)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .tracking(0.5)

            // 2-column grid of station cards
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: DesignSystem.Spacing.medium),
                GridItem(.flexible(), spacing: DesignSystem.Spacing.medium)
            ], spacing: DesignSystem.Spacing.medium) {
                ForEach(viewModel.stations) { station in
                    NavigationLink(destination: StationPerformanceDetailView(
                        stationName: station.name,
                        emoji: station.emoji,
                        mode: station.trend.isImproving
                            ? .improvement(percentImprovement: station.improvementPercent)
                            : .focus(improvementPotential: station.improvementPotential)
                    )) {
                        StationCard(station: station)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

}

// MARK: - Station Card

struct StationCard: View {
    let station: StationOverviewData

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            // Station emoji - smaller
            Text(station.emoji)
                .font(.system(size: 28))

            Spacer()

            // Station name
            Text(station.name)
                .font(DesignSystem.Typography.bodyEmphasized)
                .foregroundColor(.white)
                .lineLimit(1)

            // Performance metric - cleaner layout
            Text(station.averageTime)
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(DesignSystem.Colors.primary)
                .monospacedDigit()

            // Change indicator
            HStack(spacing: 4) {
                Image(systemName: station.trend.icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(station.changeText)
                    .font(DesignSystem.Typography.caption)
            }
            .foregroundColor(station.trend.isImproving ? DesignSystem.Colors.success : DesignSystem.Colors.warning)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 140)
        .padding(DesignSystem.Spacing.medium)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.large)
    }
}


// MARK: - View Model

class AllStationsOverviewViewModel: ObservableObject {
    @Published var keyInsight: String? = "4 stations are improving - your sled and ski work is paying off"
    @Published var improvingCount: Int = 4
    @Published var stableCount: Int = 3
    @Published var needsFocusCount: Int = 1

    @Published var stations: [StationOverviewData] = [
        StationOverviewData(
            name: "SkiErg",
            emoji: "🚣",
            averageTime: "2:28",
            trend: .improving,
            improvementPercent: 12,
            improvementPotential: 0,
            changeText: "-15%"
        ),
        StationOverviewData(
            name: "Sled Push",
            emoji: "🏋️",
            averageTime: "2:15",
            trend: .improving,
            improvementPercent: 18,
            improvementPotential: 0,
            changeText: "-18%"
        ),
        StationOverviewData(
            name: "Sled Pull",
            emoji: "🪂",
            averageTime: "2:35",
            trend: .improving,
            improvementPercent: 8,
            improvementPotential: 0,
            changeText: "-8%"
        ),
        StationOverviewData(
            name: "Burpees",
            emoji: "💪",
            averageTime: "3:05",
            trend: .declining,
            improvementPercent: 0,
            improvementPotential: 20,
            changeText: "+3%"
        ),
        StationOverviewData(
            name: "Row",
            emoji: "🚣‍♀️",
            averageTime: "2:42",
            trend: .stable,
            improvementPercent: 0,
            improvementPotential: 0,
            changeText: "±0%"
        ),
        StationOverviewData(
            name: "Farmers Carry",
            emoji: "🏋️‍♀️",
            averageTime: "1:58",
            trend: .improving,
            improvementPercent: 6,
            improvementPotential: 0,
            changeText: "-6%"
        ),
        StationOverviewData(
            name: "Sandbag",
            emoji: "🎒",
            averageTime: "2:20",
            trend: .stable,
            improvementPercent: 0,
            improvementPotential: 0,
            changeText: "±1%"
        ),
        StationOverviewData(
            name: "Wall Balls",
            emoji: "⚽",
            averageTime: "2:52",
            trend: .stable,
            improvementPercent: 0,
            improvementPotential: 0,
            changeText: "±2%"
        )
    ]

    var improvingStations: String {
        stations.filter { $0.trend.isImproving }
            .map { $0.name }
            .joined(separator: ", ")
    }

    var stableStations: String {
        stations.filter { $0.trend.text == "Stable" }
            .map { $0.name }
            .joined(separator: ", ")
    }

    var needsFocusStations: String {
        stations.filter { $0.trend.text == "Declining" }
            .map { $0.name }
            .joined(separator: ", ")
    }

    func loadData() async {
        do {
            // Fetch real station stats from Supabase
            let stats = try await SupabaseService.shared.getStationStats()

            // Convert to StationOverviewData
            var stationData: [StationOverviewData] = []

            let stationConfigs: [(name: String, emoji: String)] = [
                ("SkiErg", "🚣"),
                ("Sled Push", "🏋️"),
                ("Sled Pull", "🪂"),
                ("Burpees", "💪"),
                ("Row", "🚣‍♀️"),
                ("Farmers Carry", "🏋️‍♀️"),
                ("Sandbag", "🎒"),
                ("Wall Balls", "⚽")
            ]

            for config in stationConfigs {
                // Find matching stat from DB (fuzzy match)
                let stat = stats.first { $0.stationName.lowercased().contains(config.name.lowercased().prefix(4).description) }

                if let stat = stat {
                    let avgMinutes = stat.avgDurationMinutes
                    let mins = Int(avgMinutes)
                    let secs = Int((avgMinutes - Double(mins)) * 60)
                    let avgTimeStr = String(format: "%d:%02d", mins, secs)

                    let trend: TrendDirection
                    let changeText: String
                    if stat.trendPercent > 5 {
                        trend = .improving
                        changeText = String(format: "-%.0f%%", stat.trendPercent)
                    } else if stat.trendPercent < -5 {
                        trend = .declining
                        changeText = String(format: "+%.0f%%", abs(stat.trendPercent))
                    } else {
                        trend = .stable
                        changeText = "±\(Int(abs(stat.trendPercent)))%"
                    }

                    stationData.append(StationOverviewData(
                        name: config.name,
                        emoji: config.emoji,
                        averageTime: avgTimeStr,
                        trend: trend,
                        improvementPercent: trend == .improving ? Int(stat.trendPercent) : 0,
                        improvementPotential: trend == .declining ? 20 : 0,
                        changeText: changeText
                    ))
                } else {
                    // No data yet for this station
                    stationData.append(StationOverviewData(
                        name: config.name,
                        emoji: config.emoji,
                        averageTime: "--:--",
                        trend: .stable,
                        improvementPercent: 0,
                        improvementPotential: 0,
                        changeText: "No data"
                    ))
                }
            }

            stations = stationData

            // Update counts
            improvingCount = stations.filter { $0.trend == .improving }.count
            stableCount = stations.filter { $0.trend == .stable }.count
            needsFocusCount = stations.filter { $0.trend == .declining }.count

            // Update insight
            if improvingCount > 0 {
                let improvingNames = stations.filter { $0.trend == .improving }.map { $0.name }.joined(separator: " and ")
                keyInsight = "\(improvingCount) stations improving - your \(improvingNames.lowercased()) work is paying off"
            } else if needsFocusCount > 0 {
                keyInsight = "Focus on \(stations.filter { $0.trend == .declining }.first?.name ?? "stations") to improve overall time"
            } else {
                keyInsight = "Consistent performance across all stations - keep it up!"
            }

        } catch {
            print("Failed to load station stats: \(error)")
            // Keep mock data as fallback
        }
    }
}

// MARK: - Supporting Types

struct StationOverviewData: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let emoji: String
    let averageTime: String
    let trend: TrendDirection
    let improvementPercent: Int
    let improvementPotential: Int
    let changeText: String
}

extension TrendDirection {
    var isImproving: Bool {
        self.text == "Improving"
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AllStationsOverviewView()
    }
}
