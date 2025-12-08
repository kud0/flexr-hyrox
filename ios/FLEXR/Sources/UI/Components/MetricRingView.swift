// FLEXR - Metric Ring View
// Circular progress indicator for metrics

import SwiftUI

struct MetricRingView: View {
    let value: Double
    let maxValue: Double
    let lineWidth: CGFloat
    let color: Color
    var backgroundColor: Color = DesignSystem.Colors.surface
    var showLabel: Bool = false
    var label: String = ""

    private var progress: Double {
        min(1.0, max(0.0, value / maxValue))
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: progress)

            // Label
            if showLabel {
                VStack(spacing: 2) {
                    Text("\(Int(value))")
                        .font(DesignSystem.Typography.heading3)
                        .foregroundColor(DesignSystem.Colors.text.primary)

                    if !label.isEmpty {
                        Text(label)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Heart Rate Ring

struct HeartRateRingView: View {
    let heartRate: Int
    let maxHeartRate: Int

    private var zoneColor: Color {
        let percentage = Double(heartRate) / Double(maxHeartRate) * 100
        switch percentage {
        case 0..<50: return DesignSystem.Colors.zone1
        case 50..<60: return DesignSystem.Colors.zone2
        case 60..<70: return DesignSystem.Colors.zone3
        case 70..<80: return DesignSystem.Colors.zone3
        case 80..<90: return DesignSystem.Colors.zone4
        default: return DesignSystem.Colors.zone5
        }
    }

    var body: some View {
        ZStack {
            MetricRingView(
                value: Double(heartRate),
                maxValue: Double(maxHeartRate),
                lineWidth: 8,
                color: zoneColor
            )

            VStack(spacing: 2) {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundColor(.red)
                    .symbolEffect(.pulse, options: .repeating)

                Text("\(heartRate)")
                    .font(DesignSystem.Typography.heading2)
                    .foregroundColor(DesignSystem.Colors.text.primary)

                Text("BPM")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }
        }
    }
}

// MARK: - Progress Ring

struct ProgressRingView: View {
    let progress: Double
    let label: String
    var color: Color = DesignSystem.Colors.accent

    var body: some View {
        ZStack {
            // Background
            Circle()
                .stroke(DesignSystem.Colors.surface, lineWidth: 6)

            // Progress
            Circle()
                .trim(from: 0, to: min(1.0, progress))
                .stroke(
                    LinearGradient(
                        colors: [color, color.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)

            // Label
            VStack(spacing: 2) {
                Text("\(Int(progress * 100))%")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundColor(DesignSystem.Colors.text.primary)

                Text(label)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }
        }
    }
}

// MARK: - Zone Distribution Ring

struct ZoneDistributionRing: View {
    let zones: HeartRateZones

    private var segments: [(Color, Double)] {
        [
            (DesignSystem.Colors.zone1, zones.percentInZone(1)),
            (DesignSystem.Colors.zone2, zones.percentInZone(2)),
            (DesignSystem.Colors.zone3, zones.percentInZone(3)),
            (DesignSystem.Colors.zone4, zones.percentInZone(4)),
            (DesignSystem.Colors.zone5, zones.percentInZone(5))
        ].filter { $0.1 > 0 }
    }

    var body: some View {
        ZStack {
            ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                Circle()
                    .trim(from: startAngle(for: index), to: endAngle(for: index))
                    .stroke(segment.0, style: StrokeStyle(lineWidth: 12, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
            }

            VStack(spacing: 2) {
                Text("Zone \(zones.dominantZone)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.text.secondary)

                Text("\(Int(zones.percentInZone(zones.dominantZone)))%")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundColor(DesignSystem.Colors.zoneColor(zones.dominantZone))
            }
        }
    }

    private func startAngle(for index: Int) -> Double {
        segments.prefix(index).map { $0.1 / 100 }.reduce(0, +)
    }

    private func endAngle(for index: Int) -> Double {
        segments.prefix(index + 1).map { $0.1 / 100 }.reduce(0, +)
    }
}

// MARK: - Countdown Ring

struct CountdownRingView: View {
    let remaining: TimeInterval
    let total: TimeInterval
    var size: CGFloat = 100

    private var progress: Double {
        guard total > 0 else { return 0 }
        return remaining / total
    }

    private var color: Color {
        switch progress {
        case 0..<0.25: return .red
        case 0.25..<0.5: return .orange
        default: return DesignSystem.Colors.accent
        }
    }

    var body: some View {
        ZStack {
            // Background
            Circle()
                .stroke(DesignSystem.Colors.surface, lineWidth: 8)
                .frame(width: size, height: size)

            // Progress
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: remaining)

            // Time label
            VStack(spacing: 0) {
                Text(remaining.formattedCountdown)
                    .font(.system(size: size * 0.25, weight: .bold, design: .monospaced))
                    .foregroundColor(DesignSystem.Colors.text.primary)

                Text("remaining")
                    .font(.system(size: size * 0.1))
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }
        }
    }
}

// MARK: - TimeInterval Extension

extension TimeInterval {
    var formattedCountdown: String {
        let totalSeconds = Int(self)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(seconds)"
        }
    }
}

// MARK: - Previews

#Preview("Metric Ring") {
    VStack(spacing: 24) {
        MetricRingView(
            value: 145,
            maxValue: 200,
            lineWidth: 8,
            color: .red,
            showLabel: true,
            label: "BPM"
        )
        .frame(width: 100, height: 100)

        HeartRateRingView(heartRate: 165, maxHeartRate: 185)
            .frame(width: 120, height: 120)

        ProgressRingView(progress: 0.75, label: "Complete")
            .frame(width: 80, height: 80)

        CountdownRingView(remaining: 45, total: 60, size: 100)
    }
    .padding()
    .background(DesignSystem.Colors.background)
    .preferredColorScheme(.dark)
}
