// FLEXR Watch - Workout Complete View
// Shows summary after completing a workout

import SwiftUI
import WatchKit

struct WorkoutCompleteView: View {
    @EnvironmentObject var workoutManager: WorkoutSessionManager
    let summary: WorkoutCompleteSummary
    let onDismiss: () -> Void

    private let appleGreen = Color(red: 0.19, green: 0.82, blue: 0.35)

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Celebration header
                VStack(spacing: 8) {
                    Text("🎉")
                        .font(.system(size: 40))

                    Text("WORKOUT COMPLETE")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.top, 8)
                .padding(.bottom, 16)

                Divider()
                    .background(Color.white.opacity(0.2))

                // Total time (prominent)
                VStack(spacing: 4) {
                    Text("Total")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)

                    Text(summary.totalTime.formattedTime)
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(appleGreen)
                }
                .padding(.vertical, 16)

                Divider()
                    .background(Color.white.opacity(0.2))

                // Time breakdown
                VStack(spacing: 12) {
                    HStack {
                        Label("Runs", systemImage: "figure.run")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)

                        Spacer()

                        Text(summary.runTime.formattedTime)
                            .font(.system(size: 15, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white)
                    }

                    HStack {
                        Label("Stations", systemImage: "figure.strengthtraining.functional")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)

                        Spacer()

                        Text(summary.stationTime.formattedTime)
                            .font(.system(size: 15, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white)
                    }

                    if summary.segmentsCompleted > 0 {
                        HStack {
                            Label("Segments", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)

                            Spacer()

                            Text("\(summary.segmentsCompleted)/\(summary.totalSegments)")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }

                    if summary.averageHeartRate > 0 {
                        HStack {
                            Label("Avg HR", systemImage: "heart.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.red.opacity(0.8))

                            Spacer()

                            Text("\(summary.averageHeartRate) bpm")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }

                    if summary.activeCalories > 0 {
                        HStack {
                            Label("Calories", systemImage: "flame.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.orange.opacity(0.8))

                            Spacer()

                            Text("\(summary.activeCalories) kcal")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)

                Divider()
                    .background(Color.white.opacity(0.2))

                // iPhone sync message
                VStack(spacing: 4) {
                    Text("See full analysis")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)

                    Text("on iPhone")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 12)

                // Done button
                Button(action: onDismiss) {
                    Text("DONE")
                        .font(.system(size: 15, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(appleGreen)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .onAppear {
            // Play success haptic
            WKInterfaceDevice.current().play(.success)
        }
    }
}

// MARK: - Summary Model
struct WorkoutCompleteSummary {
    let workoutName: String
    let totalTime: TimeInterval
    let runTime: TimeInterval
    let stationTime: TimeInterval
    let segmentsCompleted: Int
    let totalSegments: Int
    let averageHeartRate: Int
    let maxHeartRate: Int
    let activeCalories: Int
    let totalDistance: Double

    init(from session: WatchWorkoutSession) {
        self.workoutName = session.workoutName
        self.totalTime = session.totalElapsedTime
        self.segmentsCompleted = session.currentSegmentIndex
        self.totalSegments = session.segments.count
        self.averageHeartRate = session.averageHeartRate
        self.maxHeartRate = session.maxHeartRate
        self.activeCalories = session.activeCalories
        self.totalDistance = session.segmentMetrics.compactMap { $0.distance }.reduce(0, +)

        // Calculate run time vs station time
        var runs: TimeInterval = 0
        var stations: TimeInterval = 0

        for metrics in session.segmentMetrics {
            if metrics.segmentType == .run {
                runs += metrics.duration
            } else {
                stations += metrics.duration
            }
        }

        self.runTime = runs
        self.stationTime = stations
    }

    // Default empty summary
    static var empty: WorkoutCompleteSummary {
        WorkoutCompleteSummary(
            workoutName: "",
            totalTime: 0,
            runTime: 0,
            stationTime: 0,
            segmentsCompleted: 0,
            totalSegments: 0,
            averageHeartRate: 0,
            maxHeartRate: 0,
            activeCalories: 0,
            totalDistance: 0
        )
    }

    init(
        workoutName: String,
        totalTime: TimeInterval,
        runTime: TimeInterval,
        stationTime: TimeInterval,
        segmentsCompleted: Int,
        totalSegments: Int,
        averageHeartRate: Int,
        maxHeartRate: Int,
        activeCalories: Int,
        totalDistance: Double
    ) {
        self.workoutName = workoutName
        self.totalTime = totalTime
        self.runTime = runTime
        self.stationTime = stationTime
        self.segmentsCompleted = segmentsCompleted
        self.totalSegments = totalSegments
        self.averageHeartRate = averageHeartRate
        self.maxHeartRate = maxHeartRate
        self.activeCalories = activeCalories
        self.totalDistance = totalDistance
    }
}

#Preview {
    WorkoutCompleteView(
        summary: WorkoutCompleteSummary(
            workoutName: "HYROX Simulation",
            totalTime: 2062, // 34:22
            runTime: 945,    // 15:45
            stationTime: 1117, // 18:37
            segmentsCompleted: 16,
            totalSegments: 16,
            averageHeartRate: 165,
            maxHeartRate: 182,
            activeCalories: 487,
            totalDistance: 8000
        ),
        onDismiss: {}
    )
    .environmentObject(WorkoutSessionManager())
}
