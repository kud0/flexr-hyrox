import SwiftUI

struct ContentView: View {
    @EnvironmentObject var connectivity: PhoneConnectivity
    @EnvironmentObject var workoutManager: WorkoutSessionManager

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Active Workout or Start Screen
            if workoutManager.isWorkoutActive {
                WorkoutView()
                    .tag(0)
            } else {
                StartWorkoutView()
                    .tag(0)
            }

            // History/Stats
            HistoryView()
                .tag(1)

            // Settings
            SettingsView()
                .tag(2)
        }
        .tabViewStyle(.page)
        .onAppear {
            connectivity.activateSession()
            workoutManager.requestAuthorization()
        }
    }
}

// MARK: - Start Workout View
struct StartWorkoutView: View {
    @EnvironmentObject var connectivity: PhoneConnectivity
    @EnvironmentObject var workoutManager: WorkoutSessionManager

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.run")
                .font(.system(size: 40))
                .foregroundColor(.accentColor)

            Text("FLEXR")
                .font(.title3.bold())

            Text("HYROX Training")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            if connectivity.isReachable {
                if let workout = connectivity.receivedWorkout {
                    VStack(spacing: 8) {
                        Text(workout.name)
                            .font(.headline)
                            .multilineTextAlignment(.center)

                        Text("\(workout.segments.count) segments")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button {
                            workoutManager.startWorkout(workout)
                        } label: {
                            Label("Start Workout", systemImage: "play.fill")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                } else {
                    VStack(spacing: 8) {
                        Text("No Workout Selected")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Select a workout on your iPhone")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "iphone.slash")
                        .font(.title2)
                        .foregroundColor(.orange)

                    Text("iPhone Not Connected")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Open FLEXR on your iPhone")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
    }
}

// MARK: - History View (Placeholder)
struct HistoryView: View {
    var body: some View {
        VStack {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("History")
                .font(.headline)

            Text("Coming Soon")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Settings View (Placeholder)
struct SettingsView: View {
    var body: some View {
        List {
            Section("Workout") {
                Toggle("Auto-pause", isOn: .constant(true))
                Toggle("Haptic feedback", isOn: .constant(true))
            }

            Section("Display") {
                Toggle("Always-on display", isOn: .constant(true))
                Toggle("Show pace zones", isOn: .constant(false))
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PhoneConnectivity())
        .environmentObject(WorkoutSessionManager())
}
