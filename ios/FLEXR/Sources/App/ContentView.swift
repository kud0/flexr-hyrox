import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: Tab = .today

    enum Tab {
        case today
        case train
        case analytics
        case profile
    }

    var body: some View {
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

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(Tab.profile)
        }
        .tint(DesignSystem.Colors.primary)
    }
}

// MARK: - Placeholder Views

struct TodayView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.large) {
                    ReadinessCard()
                    TodayWorkoutCard()
                    RecentActivityCard()
                }
                .padding()
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Today")
        }
    }
}

struct TrainView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.large) {
                    Text("Training Programs")
                        .font(DesignSystem.Typography.heading1)
                        .foregroundColor(DesignSystem.Colors.text.primary)

                    Text("Start your HYROX training session")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }
                .padding()
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Train")
        }
    }
}

struct AnalyticsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.large) {
                    Text("Performance Analytics")
                        .font(DesignSystem.Typography.heading1)
                        .foregroundColor(DesignSystem.Colors.text.primary)

                    Text("Track your progress over time")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }
                .padding()
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Analytics")
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.large) {
                    if let user = appState.currentUser {
                        VStack(spacing: DesignSystem.Spacing.medium) {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .foregroundColor(DesignSystem.Colors.primary)

                            Text(user.name)
                                .font(DesignSystem.Typography.heading2)
                                .foregroundColor(DesignSystem.Colors.text.primary)

                            Text(user.email)
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.text.secondary)
                        }
                        .padding(.vertical, DesignSystem.Spacing.large)

                        UserProfileSettings(user: user)
                    } else {
                        Text("Please log in")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                    }
                }
                .padding()
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Profile")
        }
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
        .cornerRadius(DesignSystem.CornerRadius.medium)
    }
}

struct TodayWorkoutCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("Today's Workout")
                .font(DesignSystem.Typography.heading3)
                .foregroundColor(DesignSystem.Colors.text.primary)

            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    Text("Full HYROX Simulation")
                        .font(DesignSystem.Typography.body.bold())
                        .foregroundColor(DesignSystem.Colors.text.primary)

                    Text("60-75 min • 8 stations")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }

                Spacer()

                Button(action: {}) {
                    Text("Start")
                        .font(DesignSystem.Typography.body.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, DesignSystem.Spacing.large)
                        .padding(.vertical, DesignSystem.Spacing.medium)
                        .background(DesignSystem.Colors.primary)
                        .cornerRadius(DesignSystem.CornerRadius.small)
                }
            }
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.CornerRadius.medium)
    }
}

struct RecentActivityCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("Recent Activity")
                .font(DesignSystem.Typography.heading3)
                .foregroundColor(DesignSystem.Colors.text.primary)

            VStack(spacing: DesignSystem.Spacing.small) {
                ActivityRow(title: "HYROX Simulation", date: "2 days ago", duration: "68:45")
                ActivityRow(title: "Station Focus: Ski Erg", date: "4 days ago", duration: "35:20")
                ActivityRow(title: "Recovery Run", date: "5 days ago", duration: "40:00")
            }
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.CornerRadius.medium)
    }
}

struct ActivityRow: View {
    let title: String
    let date: String
    let duration: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.text.primary)

                Text(date)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }

            Spacer()

            Text(duration)
                .font(DesignSystem.Typography.body.bold())
                .foregroundColor(DesignSystem.Colors.accent)
        }
        .padding(.vertical, DesignSystem.Spacing.small)
    }
}

struct UserProfileSettings: View {
    let user: User

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            SettingRow(title: "Training Goal", value: user.trainingGoal.displayName)

            if let raceDate = user.raceDate {
                SettingRow(title: "Race Date", value: raceDate.formatted(date: .abbreviated, time: .omitted))
            }

            SettingRow(title: "Experience", value: user.experienceLevel.displayName)
            SettingRow(title: "Training Days/Week", value: "\(user.trainingArchitecture.daysPerWeek)")
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.CornerRadius.medium)
    }
}

struct SettingRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.text.secondary)

            Spacer()

            Text(value)
                .font(DesignSystem.Typography.body.bold())
                .foregroundColor(DesignSystem.Colors.text.primary)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(HealthKitService())
}
