// FLEXR - Mission Control View Model
// Brain of the tactical workout overview - predictions, insights, analytics

import Foundation
import SwiftUI
import Combine

@MainActor
class MissionControlViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var workout: Workout
    @Published var currentSegmentIndex: Int = 0
    @Published var totalElapsedTime: TimeInterval = 0
    @Published var segmentElapsedTime: TimeInterval = 0
    @Published var currentDistance: Double = 0 // For distance-based segments
    @Published var currentReps: Int = 0 // For rep-based segments
    @Published var currentHeartRate: Int = 140 // Mock - would come from HealthKit
    @Published var isPaused: Bool = false

    @Published var insights: [AIInsight] = []

    // MARK: - Private Properties

    private var timer: Timer?
    private var segmentStartTime: Date?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var currentSegment: WorkoutSegment? {
        guard currentSegmentIndex < workout.segments.count else { return nil }
        return workout.segments[currentSegmentIndex]
    }

    var completedSegments: [WorkoutSegment] {
        Array(workout.segments.prefix(currentSegmentIndex))
    }

    var upcomingSegments: [WorkoutSegment] {
        guard currentSegmentIndex < workout.segments.count else { return [] }
        return Array(workout.segments.suffix(from: currentSegmentIndex + 1))
    }

    // MARK: - Performance Analytics

    var projectedFinishTime: TimeInterval {
        // Calculate based on current pace
        let completedTime = completedSegments.compactMap { $0.actualDuration }.reduce(0, +)
        let remainingSegments = workout.segments.count - currentSegmentIndex

        guard remainingSegments > 0 else { return completedTime }

        // Use average pace of completed segments to project
        let avgSegmentTime = completedTime / Double(max(1, currentSegmentIndex))
        let projectedRemaining = avgSegmentTime * Double(remainingSegments)

        return completedTime + segmentElapsedTime + projectedRemaining
    }

    var targetFinishTime: TimeInterval {
        workout.segments.compactMap { $0.targetDuration }.reduce(0, +)
    }

    var finishTimeDelta: TimeInterval {
        projectedFinishTime - targetFinishTime
    }

    var isAheadOfPace: Bool {
        finishTimeDelta < 0
    }

    var overallProgress: Double {
        guard !workout.segments.isEmpty else { return 0 }
        let completedProgress = Double(currentSegmentIndex)
        let currentProgress = segmentProgress
        return (completedProgress + currentProgress) / Double(workout.segments.count)
    }

    var segmentProgress: Double {
        guard let segment = currentSegment else { return 0 }

        if let targetDistance = segment.targetDistance, targetDistance > 0 {
            return min(currentDistance / targetDistance, 1.0)
        }

        if let targetReps = segment.targetReps, targetReps > 0 {
            return min(Double(currentReps) / Double(targetReps), 1.0)
        }

        if let targetDuration = segment.targetDuration, targetDuration > 0 {
            return min(segmentElapsedTime / targetDuration, 1.0)
        }

        return 0
    }

    // MARK: - Pace Analysis

    var currentPace: TimeInterval? {
        guard let segment = currentSegment,
              segment.segmentType == .run,
              currentDistance > 100 else { return nil }

        // Pace in seconds per km
        let distanceInKm = currentDistance / 1000.0
        return segmentElapsedTime / distanceInKm
    }

    var paceDegradationData: [PaceDataPoint] {
        completedSegments.enumerated().compactMap { index, segment in
            guard segment.segmentType == .run,
                  let duration = segment.actualDuration,
                  let distance = segment.actualDistance,
                  distance > 0 else { return nil }

            let pace = duration / (distance / 1000.0)
            return PaceDataPoint(
                segmentIndex: index,
                segmentName: "R\(index + 1)",
                pace: pace
            )
        }
    }

    var isPaceDegrading: Bool {
        let runPaces = paceDegradationData.map { $0.pace }
        guard runPaces.count >= 2 else { return false }

        // Check if last pace is significantly slower than average
        let avgPace = runPaces.dropLast().reduce(0, +) / Double(runPaces.count - 1)
        let lastPace = runPaces.last!

        return lastPace > avgPace + 10 // 10+ seconds slower
    }

    // MARK: - HR Zone Distribution

    var hrZoneDistribution: [HRZoneData] {
        // Mock data - would calculate from actual HR history
        [
            HRZoneData(zone: 5, percentage: 5, duration: totalElapsedTime * 0.05, color: .red),
            HRZoneData(zone: 4, percentage: 45, duration: totalElapsedTime * 0.45, color: .orange),
            HRZoneData(zone: 3, percentage: 30, duration: totalElapsedTime * 0.30, color: DesignSystem.Colors.primary),
            HRZoneData(zone: 2, percentage: 20, duration: totalElapsedTime * 0.20, color: .cyan)
        ]
    }

    var currentHRZone: Int {
        // Simple zone calculation - would use actual max HR from user profile
        let maxHR = 190.0
        let percentage = Double(currentHeartRate) / maxHR

        switch percentage {
        case 0.9...: return 5
        case 0.8..<0.9: return 4
        case 0.7..<0.8: return 3
        case 0.6..<0.7: return 2
        default: return 1
        }
    }

    // MARK: - Segment Performance

    func segmentDelta(_ segment: WorkoutSegment) -> TimeInterval? {
        guard let actual = segment.actualDuration,
              let target = segment.targetDuration else { return nil }
        return actual - target
    }

    func segmentStatus(_ segment: WorkoutSegment) -> SegmentStatus {
        guard let delta = segmentDelta(segment) else { return .unknown }

        if delta < -5 { return .ahead }
        if delta > 5 { return .behind }
        return .onPace
    }

    // MARK: - AI Insights

    func generateInsights() {
        var newInsights: [AIInsight] = []

        // Pace degradation insight
        if isPaceDegrading {
            newInsights.append(AIInsight(
                icon: "chart.line.downtrend.xyaxis",
                text: "Your run pace is dropping. HR steady - station fatigue kicking in.",
                type: .warning
            ))
        }

        // Next segment intelligence
        if let next = upcomingSegments.first {
            let intel = getStationIntel(next)
            if intel.isStrength {
                newInsights.append(AIInsight(
                    icon: "bolt.fill",
                    text: "Next: \(next.displayName) - your best station. Chance to make up time!",
                    type: .opportunity
                ))
            }
        }

        // Overall pacing
        if isAheadOfPace {
            newInsights.append(AIInsight(
                icon: "checkmark.circle.fill",
                text: "Strong pacing - \(Int(abs(finishTimeDelta)))s ahead of target.",
                type: .positive
            ))
        } else if finishTimeDelta > 30 {
            newInsights.append(AIInsight(
                icon: "exclamationmark.triangle.fill",
                text: "Behind pace. Focus on efficient transitions and steady effort.",
                type: .warning
            ))
        }

        self.insights = newInsights
    }

    // MARK: - Station Intelligence

    func getStationIntel(_ segment: WorkoutSegment) -> StationIntel {
        // Mock data - would come from historical workouts
        let isStrength = segment.stationType == .sledPush || segment.stationType == .rowing

        return StationIntel(
            personalBest: segment.targetDuration.map { $0 * 0.85 },
            average: segment.targetDuration.map { $0 * 0.95 },
            target: segment.targetDuration,
            isStrength: isStrength,
            rank: isStrength ? 1 : 5,
            recentPerformances: [
                segment.targetDuration.map { $0 * 0.95 },
                segment.targetDuration.map { $0 * 0.92 },
                segment.targetDuration.map { $0 * 0.97 }
            ].compactMap { $0 },
            strategy: isStrength ? "Start explosive, maintain power" : "Steady pace, control breathing"
        )
    }

    // MARK: - Initialization

    init(workout: Workout) {
        self.workout = workout
        setupTimers()
        generateInsights()
    }

    // MARK: - Timer Management

    private func setupTimers() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, !self.isPaused else { return }

            self.totalElapsedTime += 0.5
            self.segmentElapsedTime += 0.5

            // Mock progression for demo
            if let segment = self.currentSegment {
                if segment.segmentType == .run, let targetDistance = segment.targetDistance {
                    // Simulate running at ~5:00/km pace
                    let pacePerSecond = 1000.0 / 300.0 // 5:00/km = 300s per km
                    self.currentDistance += pacePerSecond * 0.5

                    if self.currentDistance >= targetDistance {
                        self.completeSegment()
                    }
                }
            }

            // Update HR (mock variation)
            self.currentHeartRate = Int.random(in: 165...175)

            // Regenerate insights periodically
            if Int(self.totalElapsedTime) % 10 == 0 {
                self.generateInsights()
            }
        }
    }

    // MARK: - Workout Control

    func pause() {
        isPaused = true
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    func resume() {
        isPaused = false
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    func completeSegment() {
        guard currentSegmentIndex < workout.segments.count else { return }

        workout.segments[currentSegmentIndex].actualDuration = segmentElapsedTime
        workout.segments[currentSegmentIndex].actualDistance = currentDistance
        workout.segments[currentSegmentIndex].avgHeartRate = Double(currentHeartRate)

        currentSegmentIndex += 1
        segmentElapsedTime = 0
        currentDistance = 0
        currentReps = 0

        generateInsights()

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    func skipSegment() {
        currentSegmentIndex += 1
        segmentElapsedTime = 0
        currentDistance = 0
        currentReps = 0
        generateInsights()
    }

    func endWorkout() {
        timer?.invalidate()
        workout.status = .completed
    }

    deinit {
        timer?.invalidate()
    }
}

// MARK: - Supporting Types

struct PaceDataPoint: Identifiable {
    let id = UUID()
    let segmentIndex: Int
    let segmentName: String
    let pace: TimeInterval
}

struct HRZoneData: Identifiable {
    let id = UUID()
    let zone: Int
    let percentage: Double
    let duration: TimeInterval
    let color: Color
}

enum SegmentStatus {
    case ahead
    case onPace
    case behind
    case unknown

    var color: Color {
        switch self {
        case .ahead: return .green
        case .onPace: return .yellow
        case .behind: return .red
        case .unknown: return .gray
        }
    }

    var icon: String {
        switch self {
        case .ahead: return "arrow.down.circle.fill"
        case .onPace: return "checkmark.circle.fill"
        case .behind: return "arrow.up.circle.fill"
        case .unknown: return "circle"
        }
    }
}

struct AIInsight: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
    let type: InsightType

    enum InsightType {
        case positive
        case warning
        case opportunity
        case neutral

        var color: Color {
            switch self {
            case .positive: return .green
            case .warning: return .orange
            case .opportunity: return DesignSystem.Colors.primary
            case .neutral: return .gray
            }
        }
    }
}

struct StationIntel {
    let personalBest: TimeInterval?
    let average: TimeInterval?
    let target: TimeInterval?
    let isStrength: Bool
    let rank: Int
    let recentPerformances: [TimeInterval]
    let strategy: String
}
