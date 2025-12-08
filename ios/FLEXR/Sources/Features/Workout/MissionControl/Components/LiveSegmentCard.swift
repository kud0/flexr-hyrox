// FLEXR - Live Segment Card
// Expanded card showing current segment with live data streaming

import SwiftUI

struct LiveSegmentCard: View {
    let segment: WorkoutSegment
    let elapsedTime: TimeInterval
    let progress: Double
    let currentPace: TimeInterval?
    let currentHeartRate: Int
    let hrZone: Int
    let projectedTime: TimeInterval?

    @State private var pulse: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with live indicator
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .scaleEffect(pulse ? 1.2 : 1.0)
                        .opacity(pulse ? 0.6 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                            value: pulse
                        )

                    Text("LIVE")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.red)
                        .tracking(1.5)
                }

                Spacer()

                Text(segment.displayName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
            }

            // Progress bar
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 6)
                            .fill(DesignSystem.Colors.surface)
                            .frame(height: 12)

                        // Progress
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        DesignSystem.Colors.primary,
                                        DesignSystem.Colors.primary.opacity(0.6)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 12)
                            .animation(.easeOut(duration: 0.2), value: progress)

                        // Marker
                        Circle()
                            .fill(.white)
                            .frame(width: 8, height: 8)
                            .offset(x: (geometry.size.width * progress) - 4)
                            .animation(.easeOut(duration: 0.2), value: progress)
                    }
                }
                .frame(height: 12)

                HStack {
                    Text(progressText)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()

                    Spacer()

                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }
            }

            // Live metrics
            HStack(spacing: 12) {
                if let pace = currentPace {
                    LiveMetricPill(
                        label: "PACE",
                        value: pace.formattedPace,
                        trend: paceWarning,
                        color: paceWarning ? .orange : DesignSystem.Colors.primary
                    )
                }

                LiveMetricPill(
                    label: "HR",
                    value: "\(currentHeartRate)",
                    subtitle: "Zone \(hrZone)",
                    color: hrZoneColor
                )
            }

            // Projected time if behind
            if let projected = projectedTime,
               let target = segment.targetDuration,
               projected > target {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.orange)

                    Text("Projected: \(projected.formattedTime) (\(deltaText(projected - target)))")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignSystem.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    DesignSystem.Colors.primary.opacity(0.5),
                                    DesignSystem.Colors.primary.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .shadow(color: DesignSystem.Colors.primary.opacity(0.2), radius: 10, y: 5)
        .onAppear {
            pulse = true
        }
    }

    private var progressText: String {
        if let targetDistance = segment.targetDistance {
            let currentMeters = Int(targetDistance * progress)
            return "\(currentMeters)m / \(Int(targetDistance))m"
        }
        if let targetReps = segment.targetReps {
            let currentReps = Int(Double(targetReps) * progress)
            return "\(currentReps) / \(targetReps) reps"
        }
        return elapsedTime.formattedTime
    }

    private var paceWarning: Bool {
        guard let pace = currentPace,
              let targetPace = segment.targetPace else { return false }
        // Warning if pace is more than 10s/km slower than target
        return pace > 310 // Mock 5:10/km threshold
    }

    private var hrZoneColor: Color {
        switch hrZone {
        case 5: return .red
        case 4: return .orange
        case 3: return DesignSystem.Colors.primary
        case 2: return .cyan
        default: return .gray
        }
    }

    private func deltaText(_ delta: TimeInterval) -> String {
        let seconds = Int(abs(delta))
        return "+\(seconds)s"
    }
}

struct LiveMetricPill: View {
    let label: String
    let value: String
    var subtitle: String? = nil
    var trend: Bool = false
    var color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(DesignSystem.Colors.text.tertiary)
                .tracking(1.0)

            HStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                    .monospacedDigit()

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }

                if trend {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(color)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

private extension TimeInterval {
    var formattedTime: String {
        let minutes = Int(self / 60)
        let seconds = Int(self.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedPace: String {
        let minutes = Int(self / 60)
        let seconds = Int(self.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d/km", minutes, seconds)
    }
}

#Preview {
    LiveSegmentCard(
        segment: WorkoutSegment(
            workoutId: UUID(),
            segmentType: .run,
            targetDuration: 285,
            targetDistance: 1000,
            targetPace: "4:45-5:00"
        ),
        elapsedTime: 135,
        progress: 0.52,
        currentPace: 312,
        currentHeartRate: 172,
        hrZone: 4,
        projectedTime: 304
    )
    .padding()
    .background(Color.black)
}
