// FLEXR - Dynamic Terminal Overlay
// Raw training data that appears and disappears
// "Terminal command line" aesthetic - unique and authentic

import SwiftUI
import Combine

// MARK: - Terminal Metric Types

enum TerminalMetric {
    case timer(String)
    case heartRate(Int, String) // BPM, zone
    case segment(String)
    case round(Int, Int) // current, total
    case pace(String)
    case power(Int)
    case status(String)
    case transition(String)

    var displayText: String {
        switch self {
        case .timer(let time):
            return "> TIME: \(time)"
        case .heartRate(let bpm, let zone):
            return "> HR: \(bpm) [ZONE_\(zone)]"
        case .segment(let name):
            return "> SEGMENT: \(name.uppercased().replacingOccurrences(of: " ", with: "_"))"
        case .round(let current, let total):
            let percentage = Int((Double(current) / Double(total)) * 100)
            let bars = String(repeating: "█", count: current) + String(repeating: "░", count: total - current)
            return "> ROUND: [\(bars)] \(current)/\(total) [\(percentage)%]"
        case .pace(let pace):
            return "> PACE: \(pace)"
        case .power(let watts):
            return "> POWER: \(watts)W ⚡"
        case .status(let status):
            return "> STATUS: \(status)"
        case .transition(let next):
            return "> NEXT: \(next.uppercased().replacingOccurrences(of: " ", with: "_"))"
        }
    }

    var displayDuration: TimeInterval {
        switch self {
        case .timer: return 2.5
        case .heartRate: return 3.0
        case .segment: return 3.5
        case .round: return 3.0
        case .pace: return 2.5
        case .power: return 2.5
        case .status: return 4.0
        case .transition: return 4.0
        }
    }
}

// MARK: - Terminal Overlay View

struct TerminalOverlay: View {
    @ObservedObject var workoutVM: WorkoutExecutionViewModel

    @State private var currentMetric: TerminalMetric?
    @State private var isVisible = false
    @State private var metricRotationTimer: Timer?
    @State private var lastHRZone: Int = 1

    // Terminal colors
    private let terminalGreen = Color(red: 0.0, green: 1.0, blue: 0.0) // #00FF00
    private let electricBlue = Color(red: 0.039, green: 0.518, blue: 1.0) // #0A84FF
    private let warningRed = Color(red: 1.0, green: 0.2, blue: 0.2)

    var body: some View {
        ZStack {
            if let metric = currentMetric, isVisible {
                terminalDisplay(for: metric)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .bottom))
                    ))
            }
        }
        .onAppear {
            startMetricRotation()
        }
        .onDisappear {
            stopMetricRotation()
        }
    }

    // MARK: - Terminal Display

    @ViewBuilder
    private func terminalDisplay(for metric: TerminalMetric) -> some View {
        VStack {
            HStack {
                Text(metric.displayText)
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(terminalColor(for: metric))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Rectangle()
                            .fill(Color.black.opacity(0.75))
                    )

                Spacer()
            }
            .padding(.leading, 16)
            .padding(.top, 60)

            Spacer()
        }
    }

    private func terminalColor(for metric: TerminalMetric) -> Color {
        switch metric {
        case .heartRate(_, let zone):
            // Color code by HR zone
            if zone.contains("5") {
                return warningRed
            } else if zone.contains("4") {
                return .yellow
            } else {
                return terminalGreen
            }
        case .status(let status):
            if status.contains("AHEAD") {
                return terminalGreen
            } else if status.contains("BEHIND") {
                return warningRed
            } else {
                return electricBlue
            }
        case .power:
            return .yellow
        default:
            return electricBlue
        }
    }

    // MARK: - Metric Rotation Logic

    private func startMetricRotation() {
        // Initial delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showNextMetric()

            // Set up rotation timer
            metricRotationTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { _ in
                showNextMetric()
            }
        }
    }

    private func stopMetricRotation() {
        metricRotationTimer?.invalidate()
        metricRotationTimer = nil
    }

    private func showNextMetric() {
        // Check for priority metrics first (context-aware)
        if let priorityMetric = checkPriorityMetrics() {
            displayMetric(priorityMetric)
            return
        }

        // Otherwise, rotate through standard metrics
        let metrics = getAvailableMetrics()
        guard !metrics.isEmpty else { return }

        // Pick next metric (round-robin style)
        let nextMetric = metrics.randomElement() ?? metrics[0]
        displayMetric(nextMetric)
    }

    private func checkPriorityMetrics() -> TerminalMetric? {
        // Priority 1: HR zone change
        let currentZone = getCurrentHRZone()
        if currentZone != lastHRZone {
            lastHRZone = currentZone
            return .heartRate(getCurrentHeartRate(), "\(currentZone)")
        }

        // Priority 2: Segment transition (check if just changed)
        // This would need state tracking - simplified for now

        // Priority 3: PR or significant achievement
        // Would need comparison logic

        return nil
    }

    private func getAvailableMetrics() -> [TerminalMetric] {
        var metrics: [TerminalMetric] = []

        // Always available
        metrics.append(.timer(formattedTime(workoutVM.totalElapsedTime)))
        if let segment = workoutVM.currentSegment {
            metrics.append(.segment(segment.displayName))
        }
        metrics.append(.round(1, 1))

        // Heart rate (if available)
        let hr = getCurrentHeartRate()
        if hr > 0 {
            let zone = getCurrentHRZone()
            metrics.append(.heartRate(hr, "\(zone)"))
        }

        // Pace (if running)
        if let pace = getCurrentPace() {
            metrics.append(.pace(pace))
        }

        // Power (if on equipment)
        if let power = getCurrentPower() {
            metrics.append(.power(power))
        }

        // Status (if tracking vs target)
        if let status = getStatus() {
            metrics.append(.status(status))
        }

        // Next segment
        if let next = workoutVM.nextSegment {
            metrics.append(.transition(next.displayName))
        }

        return metrics
    }

    private func displayMetric(_ metric: TerminalMetric) {
        // Fade out current
        withAnimation(.easeOut(duration: 0.3)) {
            isVisible = false
        }

        // Change metric
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            currentMetric = metric

            // Fade in new
            withAnimation(.easeIn(duration: 0.3)) {
                isVisible = true
            }

            // Schedule fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + metric.displayDuration) {
                withAnimation(.easeOut(duration: 0.3)) {
                    isVisible = false
                }
            }
        }
    }

    // MARK: - Data Helpers

    private func getCurrentHeartRate() -> Int {
        // TODO: Get from HealthKit or Watch
        return 152
    }

    private func getCurrentHRZone() -> Int {
        let hr = getCurrentHeartRate()
        let maxHR = 220 - 30 // TODO: Use actual max HR
        let percentage = Double(hr) / Double(maxHR)

        if percentage < 0.6 {
            return 1
        } else if percentage < 0.7 {
            return 2
        } else if percentage < 0.8 {
            return 3
        } else if percentage < 0.9 {
            return 4
        } else {
            return 5
        }
    }

    private func getCurrentPace() -> String? {
        // TODO: Get from workout data
        if workoutVM.currentSegment?.segmentType == .run {
            return "5:12 /KM"
        }
        return nil
    }

    private func getCurrentPower() -> Int? {
        // TODO: Get from connected equipment
        guard let segment = workoutVM.currentSegment else { return nil }
        if segment.displayName.contains("SKI") ||
           segment.displayName.contains("ROW") {
            return 340
        }
        return nil
    }

    private func getStatus() -> String? {
        // TODO: Compare with target/best
        // For now, return nil
        return nil // or "AHEAD +8s" / "BEHIND -3s"
    }
}

// MARK: - Alternative: Bottom Corner Terminal

struct TerminalOverlayBottomCorner: View {
    @ObservedObject var workoutVM: WorkoutExecutionViewModel

    @State private var currentMetric: TerminalMetric?
    @State private var isVisible = false
    @State private var metricRotationTimer: Timer?

    private let electricBlue = Color(red: 0.039, green: 0.518, blue: 1.0)

    var body: some View {
        ZStack {
            if let metric = currentMetric, isVisible {
                VStack {
                    Spacer()

                    HStack {
                        Text(metric.displayText)
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(electricBlue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Rectangle()
                                    .fill(Color.black.opacity(0.7))
                            )

                        Spacer()
                    }
                    .padding(.leading, 16)
                    .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            startRotation()
        }
    }

    private func startRotation() {
        // Similar rotation logic as main terminal overlay
        // Simplified for now
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showMetric(.timer("00:12:34"))
        }
    }

    private func showMetric(_ metric: TerminalMetric) {
        withAnimation(.easeIn(duration: 0.3)) {
            currentMetric = metric
            isVisible = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + metric.displayDuration) {
            withAnimation(.easeOut(duration: 0.3)) {
                isVisible = false
            }
        }
    }
}

// MARK: - Terminal Notification (One-time alerts)

struct TerminalNotification: View {
    let message: String
    @Binding var isShowing: Bool

    private let terminalGreen = Color(red: 0.0, green: 1.0, blue: 0.0)

    var body: some View {
        VStack {
            if isShowing {
                HStack {
                    Spacer()

                    Text(message)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(terminalGreen)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.black.opacity(0.85))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(terminalGreen, lineWidth: 2)
                                )
                        )

                    Spacer()
                }
                .padding(.top, 100)
                .transition(.scale.combined(with: .opacity))
            }

            Spacer()
        }
    }
}

// MARK: - Preview

    // MARK: - Helper Functions

    private func formattedTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }


#Preview("Terminal Overlay") {
    ZStack {
        Color.gray.ignoresSafeArea()

        TerminalOverlay(
            workoutVM: WorkoutExecutionViewModel(workout: Workout(userId: UUID(), date: Date(), type: .fullSimulation, segments: [WorkoutSegment(workoutId: UUID(), segmentType: .warmup, targetDuration: 600), WorkoutSegment(workoutId: UUID(), segmentType: .run, targetDistance: 1000), WorkoutSegment(workoutId: UUID(), segmentType: .station, stationType: .skiErg, targetDistance: 1000)]))
        )
    }
}

#Preview("Bottom Corner") {
    ZStack {
        Color.gray.ignoresSafeArea()

        TerminalOverlayBottomCorner(
            workoutVM: WorkoutExecutionViewModel(workout: Workout(userId: UUID(), date: Date(), type: .fullSimulation, segments: [WorkoutSegment(workoutId: UUID(), segmentType: .warmup, targetDuration: 600), WorkoutSegment(workoutId: UUID(), segmentType: .run, targetDistance: 1000), WorkoutSegment(workoutId: UUID(), segmentType: .station, stationType: .skiErg, targetDistance: 1000)]))
        )
    }
}
