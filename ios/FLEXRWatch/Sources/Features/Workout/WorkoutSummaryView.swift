import SwiftUI
import HealthKit

struct WorkoutSummaryView: View {
    @EnvironmentObject var workoutManager: WorkoutSessionManager
    @EnvironmentObject var connectivity: PhoneConnectivity

    let summary: WorkoutSummary
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Success Header
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.green)

                    Text("Workout Complete")
                        .font(.headline)

                    Text(summary.workoutName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top)

                Divider()

                // Total Time (Large)
                VStack(spacing: 4) {
                    Text("TOTAL TIME")
                        .font(.caption2.bold())
                        .foregroundColor(.secondary)

                    Text(summary.totalTime.formattedWorkoutTime)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }

                Divider()

                // Key Metrics Grid
                MetricsGrid(summary: summary)

                Divider()

                // Segments Completed
                SegmentsCompletedView(
                    completed: summary.segmentsCompleted,
                    total: summary.totalSegments
                )

                Divider()

                // Compromised Runs Preview
                if !summary.compromisedRuns.isEmpty {
                    CompromisedRunsPreview(runs: summary.compromisedRuns)
                        .padding(.vertical, 4)
                }

                // Action Buttons
                VStack(spacing: 8) {
                    Button {
                        syncToPhone()
                    } label: {
                        Label("Sync to iPhone", systemImage: "arrow.up.doc")
                            .font(.caption.bold())
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.caption.bold())
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top, 8)
            }
            .padding()
        }
    }

    private func syncToPhone() {
        WKInterfaceDevice.current().play(.click)
        connectivity.sendWorkoutSummary(summary)
    }
}

// MARK: - Metrics Grid
struct MetricsGrid: View {
    let summary: WorkoutSummary

    var body: some View {
        VStack(spacing: 12) {
            // Row 1: Average HR & Max HR
            HStack(spacing: 12) {
                MetricCard(
                    title: "AVG HR",
                    value: "\(summary.averageHeartRate)",
                    unit: "BPM",
                    icon: "heart.fill",
                    color: .red
                )

                MetricCard(
                    title: "MAX HR",
                    value: "\(summary.maxHeartRate)",
                    unit: "BPM",
                    icon: "bolt.heart.fill",
                    color: .orange
                )
            }

            // Row 2: Calories & Distance
            HStack(spacing: 12) {
                MetricCard(
                    title: "CALORIES",
                    value: "\(summary.activeCalories)",
                    unit: "KCAL",
                    icon: "flame.fill",
                    color: .orange
                )

                if summary.totalDistance > 0 {
                    MetricCard(
                        title: "DISTANCE",
                        value: String(format: "%.1f", summary.totalDistance / 1000),
                        unit: "KM",
                        icon: "figure.run",
                        color: .blue
                    )
                }
            }
        }
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(title)
                    .font(.caption2.bold())
            }
            .foregroundColor(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3.bold())
                    .foregroundColor(color)

                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Segments Completed View
struct SegmentsCompletedView: View {
    let completed: Int
    let total: Int

    var progress: Double {
        total > 0 ? Double(completed) / Double(total) : 0
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("SEGMENTS")
                .font(.caption2.bold())
                .foregroundColor(.secondary)

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(completed == total ? Color.green : Color.blue)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)

            Text("\(completed) of \(total) completed")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Compromised Runs Preview
struct CompromisedRunsPreview: View {
    let runs: [CompromisedRun]

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("COMPROMISED RUNS")
                    .font(.caption2.bold())
            }
            .foregroundColor(.secondary)

            VStack(spacing: 6) {
                ForEach(runs) { run in
                    HStack {
                        Text(run.segmentName)
                            .font(.caption)

                        Spacer()

                        Text("+\(run.compromisedSeconds)s")
                            .font(.caption.bold())
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                }
            }

            Text("View full analysis on iPhone")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Supporting Types
struct WorkoutSummary: Codable {
    let id: UUID
    let workoutName: String
    let date: Date
    let totalTime: TimeInterval
    let segmentsCompleted: Int
    let totalSegments: Int
    let averageHeartRate: Int
    let maxHeartRate: Int
    let activeCalories: Int
    let totalDistance: Double
    let compromisedRuns: [CompromisedRun]
    let segmentResults: [SegmentResult]

    init(
        id: UUID = UUID(),
        workoutName: String,
        date: Date = Date(),
        totalTime: TimeInterval,
        segmentsCompleted: Int,
        totalSegments: Int,
        averageHeartRate: Int,
        maxHeartRate: Int,
        activeCalories: Int,
        totalDistance: Double,
        compromisedRuns: [CompromisedRun] = [],
        segmentResults: [SegmentResult] = []
    ) {
        self.id = id
        self.workoutName = workoutName
        self.date = date
        self.totalTime = totalTime
        self.segmentsCompleted = segmentsCompleted
        self.totalSegments = totalSegments
        self.averageHeartRate = averageHeartRate
        self.maxHeartRate = maxHeartRate
        self.activeCalories = activeCalories
        self.totalDistance = totalDistance
        self.compromisedRuns = compromisedRuns
        self.segmentResults = segmentResults
    }
}

struct CompromisedRun: Identifiable, Codable {
    let id: UUID
    let segmentName: String
    let compromisedSeconds: Int
    let reason: String

    init(id: UUID = UUID(), segmentName: String, compromisedSeconds: Int, reason: String) {
        self.id = id
        self.segmentName = segmentName
        self.compromisedSeconds = compromisedSeconds
        self.reason = reason
    }
}

struct SegmentResult: Identifiable, Codable {
    let id: UUID
    let segmentName: String
    let type: SegmentType
    let duration: TimeInterval
    let averageHeartRate: Int
    let maxHeartRate: Int
    let distance: Double?
    let reps: Int?

    init(
        id: UUID = UUID(),
        segmentName: String,
        type: SegmentType,
        duration: TimeInterval,
        averageHeartRate: Int,
        maxHeartRate: Int,
        distance: Double? = nil,
        reps: Int? = nil
    ) {
        self.id = id
        self.segmentName = segmentName
        self.type = type
        self.duration = duration
        self.averageHeartRate = averageHeartRate
        self.maxHeartRate = maxHeartRate
        self.distance = distance
        self.reps = reps
    }
}

// MARK: - TimeInterval Extension
extension TimeInterval {
    var formattedWorkoutTime: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

#Preview {
    WorkoutSummaryView(
        summary: WorkoutSummary(
            workoutName: "HYROX Simulation",
            totalTime: 3847,
            segmentsCompleted: 17,
            totalSegments: 17,
            averageHeartRate: 165,
            maxHeartRate: 189,
            activeCalories: 985,
            totalDistance: 8400,
            compromisedRuns: [
                CompromisedRun(segmentName: "Run 4", compromisedSeconds: 12, reason: "High HR"),
                CompromisedRun(segmentName: "Run 6", compromisedSeconds: 8, reason: "High HR")
            ]
        )
    )
    .environmentObject(WorkoutSessionManager())
    .environmentObject(PhoneConnectivity())
}
