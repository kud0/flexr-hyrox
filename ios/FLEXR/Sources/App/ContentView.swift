import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var healthKitService: HealthKitService
    @State private var selectedTab: Tab = .today

    enum Tab {
        case today
        case train
        case analytics
        case gym
        case profile
    }

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                TodayView()
                    .tabItem {
                        Label("Today", systemImage: "calendar")
                    }
                    .tag(Tab.today)

                TrainView()
                    .tabItem {
                        Label("Train", systemImage: "figure.run")
                    }
                    .tag(Tab.train)

                AnalyticsView()
                    .tabItem {
                        Label("Analytics", systemImage: "chart.xyaxis.line")
                    }
                    .tag(Tab.analytics)

                FriendsListView()
                    .tabItem {
                        Label("Social", systemImage: "person.3.fill")
                    }
                    .tag(Tab.gym)

                EnhancedProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.circle")
                    }
                    .tag(Tab.profile)
            }
            .tint(DesignSystem.Colors.primary)

            // Floating Active Workout Indicator
            if appState.hasActiveWorkout && !appState.isShowingActiveWorkout {
                VStack {
                    Spacer()
                    ActiveWorkoutBanner {
                        appState.returnToActiveWorkout()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 90) // Above tab bar
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.3), value: appState.hasActiveWorkout)
            }
        }
        .fullScreenCover(isPresented: $appState.isShowingActiveWorkout) {
            if let viewModel = appState.activeWorkoutViewModel {
                ActiveWorkoutContainerView(viewModel: viewModel)
                    .environmentObject(appState)
                    .environmentObject(healthKitService)
            }
        }
    }
}

// MARK: - Active Workout Banner (floating indicator)

struct ActiveWorkoutBanner: View {
    let onTap: () -> Void
    @EnvironmentObject var appState: AppState

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Pulsing indicator
                Circle()
                    .fill(Color.green)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.green.opacity(0.5), lineWidth: 2)
                            .scaleEffect(1.5)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("WORKOUT IN PROGRESS")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)

                    if let vm = appState.activeWorkoutViewModel {
                        Text(formatTime(vm.totalElapsedTime))
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                    }
                }

                Spacer()

                Text("TAP TO RETURN")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.green.opacity(0.5), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let mins = Int(interval) / 60
        let secs = Int(interval) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - Active Workout Container (wraps existing view with minimize button)

struct ActiveWorkoutContainerView: View {
    @ObservedObject var viewModel: WorkoutExecutionViewModel
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var healthKitService: HealthKitService

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Main workout view
            ActiveWorkoutBoardView(viewModel: viewModel)
                .environmentObject(healthKitService)

            // Minimize button (top-right, icon only)
            VStack {
                HStack {
                    Spacer()
                    Button {
                        appState.minimizeWorkout()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 16)
                }
                .padding(.top, 54)
                Spacer()
            }
        }
        .onChange(of: viewModel.isWorkoutComplete) { _, isComplete in
            if isComplete {
                // Workout finished - clean up
                appState.endActiveWorkout()
            }
        }
    }
}

// MARK: - Placeholder Views

struct TodayView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var healthKitService: HealthKitService

    var body: some View {
        DashboardView()
            .environmentObject(appState)
            .environmentObject(healthKitService)
    }
}

struct TrainView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var healthKitService: HealthKitService

    var body: some View {
        WeeklyPlanView()
            .environmentObject(appState)
            .environmentObject(healthKitService)
    }
}

struct AnalyticsView: View {
    var body: some View {
        AnalyticsHomeView()
    }
}

struct SocialHubView: View {
    @StateObject private var supabase = SupabaseService.shared
    @State private var selectedTab: SocialTab = .friends
    @State private var friends: [UserRelationship] = []
    @State private var racePartner: UserRelationship?
    @State private var isLoading = true

    enum SocialTab: String, CaseIterable {
        case friends = "Friends"
        case partner = "Partner"

        var icon: String {
            switch self {
            case .friends: return "person.2.fill"
            case .partner: return "figure.2"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Tab Selector
                    HStack(spacing: 0) {
                        ForEach(SocialTab.allCases, id: \.self) { tab in
                            Button {
                                withAnimation {
                                    selectedTab = tab
                                }
                            } label: {
                                VStack(spacing: 6) {
                                    HStack(spacing: 6) {
                                        Image(systemName: tab.icon)
                                            .font(.system(size: 16))

                                        Text(tab.rawValue)
                                            .font(.system(size: 15, weight: .semibold))
                                    }
                                    .foregroundStyle(selectedTab == tab ? DesignSystem.Colors.primary : DesignSystem.Colors.text.secondary)

                                    if selectedTab == tab {
                                        Rectangle()
                                            .fill(DesignSystem.Colors.primary)
                                            .frame(height: 2)
                                    } else {
                                        Rectangle()
                                            .fill(Color.clear)
                                            .frame(height: 2)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    Divider()
                        .background(DesignSystem.Colors.divider)

                    // Content
                    if isLoading {
                        ProgressView()
                            .tint(DesignSystem.Colors.primary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        TabView(selection: $selectedTab) {
                            FriendsListView()
                                .tag(SocialTab.friends)

                            PartnerView(partner: racePartner)
                                .tag(SocialTab.partner)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                    }
                }
            }
            .navigationTitle("Social")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await loadData()
            }
        }
    }

    private func loadData() async {
        isLoading = true
        defer { isLoading = false }

        // TODO: Load friends and race partner from Supabase
        // For now, just simulate loading
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
}

// MARK: - Partner View

struct PartnerView: View {
    let partner: UserRelationship?

    var body: some View {
        ScrollView {
            if let partner = partner {
                VStack(spacing: 20) {
                    Text("Partner view with shared analytics")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.text.secondary)

                    // TODO: Show partner stats, graphs, progression
                }
                .padding()
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "person.2.badge.gearshape")
                        .font(.system(size: 60))
                        .foregroundStyle(DesignSystem.Colors.text.tertiary)

                    Text("No Race Partner")
                        .font(DesignSystem.Typography.heading3)
                        .foregroundStyle(DesignSystem.Colors.text.primary)

                    Text("Link with a race partner to see shared analytics and training data")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.text.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxHeight: .infinity)
                .padding(.top, 100)
            }
        }
        .background(DesignSystem.Colors.background)
    }
}

struct SocialActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(color)

            VStack(spacing: 4) {
                Text(title)
                    .font(DesignSystem.Typography.bodyEmphasized)
                    .foregroundStyle(DesignSystem.Colors.text.primary)

                Text(subtitle)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.medium)
    }
}

struct UpcomingFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                Text(title)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.text.primary)

                Text(description)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }

            Spacer()
        }
        .padding(.vertical, DesignSystem.Spacing.small)
    }
}

// MARK: - Component Views

struct ReadinessCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("Readiness Score")
                .font(DesignSystem.Typography.heading3)
                .foregroundColor(DesignSystem.Colors.text.primary)

            HStack(alignment: .firstTextBaseline, spacing: DesignSystem.Spacing.small) {
                Text("85")
                    .font(DesignSystem.Typography.metricLarge)
                    .foregroundColor(DesignSystem.Colors.accent)

                Text("/ 100")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }

            Text("Ready for high-intensity training")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.text.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.medium)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(HealthKitService())
}
