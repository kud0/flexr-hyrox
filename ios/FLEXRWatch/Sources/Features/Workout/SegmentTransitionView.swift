import SwiftUI
import WatchKit

struct SegmentTransitionView: View {
    @EnvironmentObject var workoutManager: WorkoutSessionManager

    let nextSegment: WorkoutSegment
    let restDuration: TimeInterval

    @State private var remainingRest: TimeInterval
    @State private var timer: Timer?
    @State private var isReady = false

    init(nextSegment: WorkoutSegment, restDuration: TimeInterval = 30) {
        self.nextSegment = nextSegment
        self.restDuration = restDuration
        self._remainingRest = State(initialValue: restDuration)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Next Segment Preview
            VStack(spacing: 8) {
                Text("NEXT")
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)

                HStack(spacing: 6) {
                    Image(systemName: nextSegment.type.iconName)
                        .font(.title3)
                    Text(nextSegment.name)
                        .font(.title3.bold())
                }
                .foregroundColor(nextSegment.type.color)
                .lineLimit(1)

                if let target = nextSegment.targetDuration {
                    Text("Target: \(target.formattedTime)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let distance = nextSegment.targetDistance {
                    Text("Distance: \(Int(distance))m")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Rest Timer or Heart Rate Recovery
            if remainingRest > 0 {
                RestTimerView(
                    remaining: remainingRest,
                    total: restDuration
                )
            } else {
                HeartRateRecoveryView(
                    currentHR: workoutManager.currentHeartRate,
                    isReady: $isReady
                )
            }

            Spacer()

            // Start Button
            Button {
                startNextSegment()
            } label: {
                Label(
                    remainingRest > 0 ? "Skip Rest" : "START",
                    systemImage: "play.fill"
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(remainingRest > 0 ? .orange : .green)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .onAppear {
            startRestTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    // MARK: - Timer Management

    private func startRestTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if remainingRest > 0 {
                remainingRest -= 1

                // Haptic feedback at intervals
                if remainingRest == 10 || remainingRest == 5 {
                    WKInterfaceDevice.current().play(.notification)
                } else if remainingRest == 3 || remainingRest == 2 || remainingRest == 1 {
                    WKInterfaceDevice.current().play(.click)
                } else if remainingRest == 0 {
                    WKInterfaceDevice.current().play(.start)
                }
            } else {
                timer?.invalidate()
            }
        }
    }

    private func startNextSegment() {
        timer?.invalidate()
        WKInterfaceDevice.current().play(.start)
        workoutManager.startNextSegment()
    }
}

// MARK: - Rest Timer View
struct RestTimerView: View {
    let remaining: TimeInterval
    let total: TimeInterval

    var progress: Double {
        1.0 - (remaining / total)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("REST")
                .font(.caption2.bold())
                .foregroundColor(.secondary)

            ZStack {
                // Progress Ring
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 12)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        remaining <= 5 ? Color.red : Color.orange,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.0), value: progress)

                // Timer Text
                Text("\(Int(remaining))")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(remaining <= 5 ? .red : .primary)
            }

            Text("seconds remaining")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Heart Rate Recovery View
struct HeartRateRecoveryView: View {
    let currentHR: Int
    @Binding var isReady: Bool

    private let recoveryThreshold = 120 // BPM

    var body: some View {
        VStack(spacing: 8) {
            Text("HEART RATE")
                .font(.caption2.bold())
                .foregroundColor(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(currentHR)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(hrColor)

                Text("BPM")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Recovery Status
            HStack(spacing: 6) {
                Image(systemName: isRecovered ? "checkmark.circle.fill" : "arrow.down.circle")
                    .foregroundColor(isRecovered ? .green : .orange)

                Text(isRecovered ? "Recovered" : "Recovering...")
                    .font(.caption)
                    .foregroundColor(isRecovered ? .green : .orange)
            }
        }
        .onChange(of: currentHR) { oldValue, newValue in
            isReady = newValue <= recoveryThreshold
        }
    }

    private var isRecovered: Bool {
        currentHR <= recoveryThreshold
    }

    private var hrColor: Color {
        if currentHR <= recoveryThreshold {
            return .green
        } else if currentHR <= 140 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Supporting Types
struct WorkoutSegment: Identifiable, Codable {
    let id: UUID
    let name: String
    let type: SegmentType
    let targetDuration: TimeInterval?
    let targetDistance: Double?
    let targetReps: Int?

    init(
        id: UUID = UUID(),
        name: String,
        type: SegmentType,
        targetDuration: TimeInterval? = nil,
        targetDistance: Double? = nil,
        targetReps: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.targetDuration = targetDuration
        self.targetDistance = targetDistance
        self.targetReps = targetReps
    }
}

#Preview {
    SegmentTransitionView(
        nextSegment: WorkoutSegment(
            name: "Ski Erg",
            type: .skiErg,
            targetDistance: 1000
        ),
        restDuration: 30
    )
    .environmentObject(WorkoutSessionManager())
}
