import SwiftUI

// MARK: - Analytics Container View
// Main view with segmented tab navigation between analytics sections

struct AnalyticsContainerView: View {
    @EnvironmentObject var healthKitService: HealthKitService
    @State private var selectedTab: AnalyticsTab = .dashboard
    @State private var scrollProxy: ScrollViewProxy?
    @Namespace private var tabAnimation

    enum AnalyticsTab: String, CaseIterable {
        case dashboard = "Overview"
        case history = "History"
        case running = "Running"
        case hyrox = "HYROX"
        case stations = "Stations"
        case heartRate = "HR"
        case recovery = "Recovery"

        var icon: String {
            switch self {
            case .dashboard: return "square.grid.2x2"
            case .history: return "clock.arrow.circlepath"
            case .running: return "figure.run"
            case .hyrox: return "flame"
            case .stations: return "dumbbell"
            case .heartRate: return "heart"
            case .recovery: return "bed.double"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom segmented control
                tabSelector

                Divider()
                    .background(DesignSystem.Colors.divider)

                // Content
                TabView(selection: $selectedTab) {
                    AnalyticsDashboardView()
                        .environmentObject(healthKitService)
                        .tag(AnalyticsTab.dashboard)

                    WorkoutHistoryView()
                        .tag(AnalyticsTab.history)

                    RunningWorkoutsView()
                        .environmentObject(healthKitService)
                        .tag(AnalyticsTab.running)

                    HyroxRunningAnalyticsView()
                        .environmentObject(healthKitService)
                        .tag(AnalyticsTab.hyrox)

                    StationAnalyticsView()
                        .tag(AnalyticsTab.stations)

                    HeartRateAnalyticsView()
                        .environmentObject(healthKitService)
                        .tag(AnalyticsTab.heartRate)

                    RecoveryAnalyticsView()
                        .environmentObject(healthKitService)
                        .tag(AnalyticsTab.recovery)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(DesignSystem.Animation.fast, value: selectedTab)
            }
            .background(Color.black)
            .navigationBarHidden(true)
            .task {
                // Ensure HealthKit data is loaded when analytics tab opens
                await healthKitService.loadBaselineMetrics()
            }
        }
    }

    private var tabSelector: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(AnalyticsTab.allCases, id: \.self) { tab in
                        tabButton(for: tab)
                            .id(tab)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.large)
                .padding(.vertical, DesignSystem.Spacing.small)
            }
            .background(Color.black)
            .onAppear {
                scrollProxy = proxy
            }
            .onChange(of: selectedTab) { _, newTab in
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(newTab, anchor: .center)
                }
            }
        }
    }

    private func tabButton(for tab: AnalyticsTab) -> some View {
        Button {
            withAnimation(DesignSystem.Animation.fast) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14, weight: .semibold))

                Text(tab.rawValue)
                    .font(DesignSystem.Typography.subheadlineEmphasized)
            }
            .foregroundColor(
                selectedTab == tab
                    ? .white
                    : DesignSystem.Colors.text.secondary
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                selectedTab == tab
                    ? DesignSystem.Colors.primary
                    : DesignSystem.Colors.surface
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        selectedTab == tab ? Color.white.opacity(0.1) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
    }
}

// MARK: - Preview
#Preview {
    AnalyticsContainerView()
        .environmentObject(HealthKitService())
}
