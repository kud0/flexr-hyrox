import SwiftUI

/// Circular progress ring for displaying metrics on Apple Watch
struct MetricRingView: View {
    let value: Double
    let maxValue: Double
    let lineWidth: CGFloat
    let color: Color
    let showBackground: Bool
    let animationDuration: Double

    init(
        value: Double,
        maxValue: Double,
        lineWidth: CGFloat = 8,
        color: Color = .blue,
        showBackground: Bool = true,
        animationDuration: Double = 0.5
    ) {
        self.value = value
        self.maxValue = maxValue
        self.lineWidth = lineWidth
        self.color = color
        self.showBackground = showBackground
        self.animationDuration = animationDuration
    }

    private var progress: Double {
        guard maxValue > 0 else { return 0 }
        return min(value / maxValue, 1.0)
    }

    var body: some View {
        ZStack {
            // Background ring
            if showBackground {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: lineWidth)
            }

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: animationDuration), value: progress)
        }
    }
}

// MARK: - Multi-Ring View
/// Display multiple concentric rings for complex metrics
struct MultiRingView: View {
    let rings: [RingData]

    struct RingData: Identifiable {
        let id = UUID()
        let value: Double
        let maxValue: Double
        let color: Color
        let lineWidth: CGFloat

        init(value: Double, maxValue: Double, color: Color, lineWidth: CGFloat = 6) {
            self.value = value
            self.maxValue = maxValue
            self.color = color
            self.lineWidth = lineWidth
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Array(rings.enumerated()), id: \.element.id) { index, ring in
                    let offset = CGFloat(index) * 10
                    let diameter = geometry.size.width - (offset * 2)

                    MetricRingView(
                        value: ring.value,
                        maxValue: ring.maxValue,
                        lineWidth: ring.lineWidth,
                        color: ring.color
                    )
                    .frame(width: diameter, height: diameter)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Heart Rate Ring
/// Specialized ring for heart rate zones
struct HeartRateRingView: View {
    let heartRate: Int
    let maxHeartRate: Int
    let size: CGFloat

    private var zone: HeartRateZone {
        HeartRateZone.fromHeartRate(heartRate, max: maxHeartRate)
    }

    var body: some View {
        ZStack {
            // Background zones
            ForEach(HeartRateZone.allCases, id: \.self) { zone in
                Circle()
                    .trim(from: zone.rangeStart, to: zone.rangeEnd)
                    .stroke(zone.color.opacity(0.2), lineWidth: 8)
                    .rotationEffect(.degrees(-90))
            }

            // Current HR indicator
            MetricRingView(
                value: Double(heartRate),
                maxValue: Double(maxHeartRate),
                lineWidth: 8,
                color: zone.color,
                showBackground: false
            )

            // Center text
            VStack(spacing: 2) {
                Text("\(heartRate)")
                    .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                    .foregroundColor(zone.color)

                Text("BPM")
                    .font(.system(size: size * 0.1))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Heart Rate Zones
enum HeartRateZone: CaseIterable {
    case rest       // 0-50%
    case warmup     // 50-60%
    case fatBurn    // 60-70%
    case cardio     // 70-80%
    case peak       // 80-100%

    var color: Color {
        switch self {
        case .rest: return .gray
        case .warmup: return .blue
        case .fatBurn: return .green
        case .cardio: return .orange
        case .peak: return .red
        }
    }

    var rangeStart: Double {
        switch self {
        case .rest: return 0.0
        case .warmup: return 0.5
        case .fatBurn: return 0.6
        case .cardio: return 0.7
        case .peak: return 0.8
        }
    }

    var rangeEnd: Double {
        switch self {
        case .rest: return 0.5
        case .warmup: return 0.6
        case .fatBurn: return 0.7
        case .cardio: return 0.8
        case .peak: return 1.0
        }
    }

    static func fromHeartRate(_ hr: Int, max: Int) -> HeartRateZone {
        let percentage = Double(hr) / Double(max)

        if percentage >= 0.8 { return .peak }
        if percentage >= 0.7 { return .cardio }
        if percentage >= 0.6 { return .fatBurn }
        if percentage >= 0.5 { return .warmup }
        return .rest
    }
}

// MARK: - Gauge Ring View
/// Activity ring style gauge for metrics
struct GaugeRingView: View {
    let value: Double
    let target: Double
    let label: String
    let color: Color
    let size: CGFloat

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(value / target, 1.0)
    }

    private var isOverTarget: Bool {
        value >= target
    }

    var body: some View {
        ZStack {
            // Ring
            MetricRingView(
                value: value,
                maxValue: target,
                lineWidth: 10,
                color: color
            )

            // Center content
            VStack(spacing: 4) {
                // Value
                Text(formattedValue)
                    .font(.system(size: size * 0.25, weight: .bold, design: .rounded))
                    .foregroundColor(isOverTarget ? .green : color)

                // Label
                Text(label)
                    .font(.system(size: size * 0.12))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
        }
        .frame(width: size, height: size)
    }

    private var formattedValue: String {
        if value >= 1000 {
            return String(format: "%.1fk", value / 1000)
        } else {
            return String(format: "%.0f", value)
        }
    }
}

// MARK: - Previews
#Preview("Single Ring") {
    VStack(spacing: 20) {
        MetricRingView(
            value: 145,
            maxValue: 200,
            lineWidth: 8,
            color: .red
        )
        .frame(width: 100, height: 100)

        MetricRingView(
            value: 750,
            maxValue: 1000,
            lineWidth: 10,
            color: .green
        )
        .frame(width: 80, height: 80)
    }
    .padding()
}

#Preview("Multi Ring") {
    MultiRingView(rings: [
        .init(value: 350, maxValue: 500, color: .red, lineWidth: 8),
        .init(value: 25, maxValue: 30, color: .green, lineWidth: 6),
        .init(value: 8, maxValue: 12, color: .blue, lineWidth: 6)
    ])
    .frame(width: 120, height: 120)
    .padding()
}

#Preview("Heart Rate Ring") {
    VStack(spacing: 20) {
        HeartRateRingView(heartRate: 165, maxHeartRate: 190, size: 120)
        HeartRateRingView(heartRate: 142, maxHeartRate: 190, size: 100)
        HeartRateRingView(heartRate: 95, maxHeartRate: 190, size: 80)
    }
    .padding()
}

#Preview("Gauge Ring") {
    HStack(spacing: 16) {
        GaugeRingView(
            value: 850,
            target: 1000,
            label: "Calories",
            color: .orange,
            size: 80
        )

        GaugeRingView(
            value: 5.2,
            target: 8.0,
            label: "Distance",
            color: .blue,
            size: 80
        )
    }
    .padding()
}
