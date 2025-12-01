import SwiftUI
import HealthKit

struct WorkoutView: View {
    @EnvironmentObject var workoutManager: WorkoutSessionManager
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        VStack(spacing: 0) {
            // Header - Current Segment
            CurrentSegmentHeader(
                segmentType: currentSegmentType,
                segmentName: currentSegmentName
            )
            .padding(.top, 8)

            Spacer()

            // Main Metrics
            MainMetricsView(
                heartRate: workoutManager.currentHeartRate,
                primaryMetric: primaryMetric,
                primaryValue: primaryValue
            )

            Spacer()

            // Secondary Metrics
            SecondaryMetricsView(
                elapsed: workoutManager.elapsedTime,
                target: currentTargetTime
            )

            Spacer()

            // Action Button
            Button {
                completeCurrentSegment()
            } label: {
                Text("DONE")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .onAppear {
            workoutManager.startMetricsCollection()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                workoutManager.refreshMetrics()
            }
        }
    }

    // MARK: - Computed Properties

    private var currentSegmentType: SegmentType {
        guard let session = workoutManager.currentSession,
              session.currentSegmentIndex < session.segments.count else {
            return .run
        }
        return session.segments[session.currentSegmentIndex].type
    }

    private var currentSegmentName: String {
        guard let session = workoutManager.currentSession,
              session.currentSegmentIndex < session.segments.count else {
            return "Workout"
        }
        return session.segments[session.currentSegmentIndex].name
    }

    private var primaryMetric: String {
        switch currentSegmentType {
        case .run:
            return "PACE"
        case .skiErg, .rowErg, .skiErg2:
            return "SPLIT"
        case .sleds, .burpeeBroadJump, .lunges:
            return "REPS"
        case .sandbag, .farmers, .wallBalls:
            return "REPS"
        }
    }

    private var primaryValue: String {
        switch currentSegmentType {
        case .run:
            return workoutManager.currentPace
        case .skiErg, .rowErg, .skiErg2:
            return workoutManager.currentSplit
        default:
            return workoutManager.currentReps > 0 ? "\(workoutManager.currentReps)" : "--"
        }
    }

    private var currentTargetTime: TimeInterval? {
        guard let session = workoutManager.currentSession,
              session.currentSegmentIndex < session.segments.count else {
            return nil
        }
        return session.segments[session.currentSegmentIndex].targetDuration
    }

    // MARK: - Actions

    private func completeCurrentSegment() {
        WKInterfaceDevice.current().play(.success)
        workoutManager.completeCurrentSegment()
    }
}

// MARK: - Current Segment Header
struct CurrentSegmentHeader: View {
    let segmentType: SegmentType
    let segmentName: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: segmentType.iconName)
                    .font(.caption2)
                Text(segmentType.displayName.uppercased())
                    .font(.caption2.bold())
            }
            .foregroundColor(segmentType.color)

            Text(segmentName)
                .font(.headline)
                .lineLimit(1)
        }
    }
}

// MARK: - Main Metrics View
struct MainMetricsView: View {
    let heartRate: Int
    let primaryMetric: String
    let primaryValue: String

    var body: some View {
        VStack(spacing: 16) {
            // Heart Rate (Large and prominent)
            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(heartRate)")
                        .font(.system(size: 54, weight: .bold, design: .rounded))
                        .foregroundColor(.red)

                    Text("BPM")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                MetricRingView(
                    value: Double(heartRate),
                    maxValue: 200,
                    lineWidth: 6,
                    color: .red
                )
                .frame(width: 80, height: 80)
            }

            // Primary Metric (Pace/Reps)
            VStack(spacing: 2) {
                Text(primaryMetric)
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)

                Text(primaryValue)
                    .font(.title3.bold())
                    .foregroundColor(.primary)
            }
        }
    }
}

// MARK: - Secondary Metrics View
struct SecondaryMetricsView: View {
    let elapsed: TimeInterval
    let target: TimeInterval?

    var body: some View {
        HStack(spacing: 20) {
            // Elapsed Time
            VStack(spacing: 2) {
                Text("ELAPSED")
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)

                Text(elapsed.formattedTime)
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.primary)
            }

            Divider()
                .frame(height: 24)

            // Target Time
            if let target = target {
                VStack(spacing: 2) {
                    Text("TARGET")
                        .font(.caption2.bold())
                        .foregroundColor(.secondary)

                    Text(target.formattedTime)
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.primary)
                }
            } else {
                VStack(spacing: 2) {
                    Text("DISTANCE")
                        .font(.caption2.bold())
                        .foregroundColor(.secondary)

                    Text("--")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Supporting Types
enum SegmentType: String, Codable {
    case run
    case skiErg
    case sleds
    case burpeeBroadJump
    case rowErg
    case farmers
    case sandbag
    case skiErg2
    case wallBalls
    case lunges

    var displayName: String {
        switch self {
        case .run: return "Run"
        case .skiErg: return "Ski Erg"
        case .sleds: return "Sleds"
        case .burpeeBroadJump: return "Burpee Broad Jump"
        case .rowErg: return "Row Erg"
        case .farmers: return "Farmers Carry"
        case .sandbag: return "Sandbag Lunges"
        case .skiErg2: return "Ski Erg"
        case .wallBalls: return "Wall Balls"
        case .lunges: return "Lunges"
        }
    }

    var iconName: String {
        switch self {
        case .run: return "figure.run"
        case .skiErg, .skiErg2: return "figure.skiing.crosscountry"
        case .sleds: return "figure.strengthtraining.traditional"
        case .burpeeBroadJump: return "figure.jumprope"
        case .rowErg: return "figure.rowing"
        case .farmers: return "figure.walk"
        case .sandbag: return "figure.flexibility"
        case .wallBalls: return "figure.handball"
        case .lunges: return "figure.flexibility"
        }
    }

    var color: Color {
        switch self {
        case .run: return .blue
        case .skiErg, .rowErg, .skiErg2: return .cyan
        case .sleds, .sandbag, .farmers: return .orange
        case .burpeeBroadJump, .wallBalls, .lunges: return .green
        }
    }
}

// MARK: - TimeInterval Extension
extension TimeInterval {
    var formattedTime: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    WorkoutView()
        .environmentObject(WorkoutSessionManager())
}
