// FLEXR - Pace Degradation Graph
// Chart showing pace across run segments to spot fading

import SwiftUI
import Charts

struct PaceDegradationGraph: View {
    let paceData: [PaceDataPoint]
    let targetPace: TimeInterval // Target pace in seconds per km

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("PACE ANALYSIS")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.text.primary)
                    .tracking(1.0)

                Spacer()

                if isDegrading {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                        Text("FADING")
                            .font(.system(size: 12, weight: .bold))
                            .tracking(0.8)
                    }
                    .foregroundColor(.orange)
                }
            }

            if paceData.count >= 2 {
                Chart {
                    // Target pace line
                    RuleMark(y: .value("Target", targetPace))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .foregroundStyle(DesignSystem.Colors.text.tertiary.opacity(0.5))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("Target")
                                .font(.system(size: 10))
                                .foregroundColor(DesignSystem.Colors.text.tertiary)
                        }

                    // Pace line
                    ForEach(paceData) { point in
                        LineMark(
                            x: .value("Segment", point.segmentName),
                            y: .value("Pace", point.pace)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    DesignSystem.Colors.primary,
                                    DesignSystem.Colors.primary.opacity(0.7)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Segment", point.segmentName),
                            y: .value("Pace", point.pace)
                        )
                        .foregroundStyle(paceColor(point.pace))
                        .symbolSize(80)
                    }

                    // Area under curve
                    ForEach(paceData) { point in
                        AreaMark(
                            x: .value("Segment", point.segmentName),
                            y: .value("Pace", point.pace)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    DesignSystem.Colors.primary.opacity(0.3),
                                    DesignSystem.Colors.primary.opacity(0.05)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartYScale(domain: (minPace - 10)...(maxPace + 10))
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine()
                            .foregroundStyle(DesignSystem.Colors.surface)
                        AxisValueLabel {
                            if let pace = value.as(Double.self) {
                                Text(pace.formattedPace)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(DesignSystem.Colors.text.tertiary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(DesignSystem.Colors.text.secondary)
                            }
                        }
                    }
                }
                .frame(height: 140)
            } else {
                // Not enough data
                VStack(spacing: 8) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 32))
                        .foregroundColor(DesignSystem.Colors.text.tertiary)

                    Text("Complete 2+ runs to see pace analysis")
                        .font(.system(size: 13))
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
            }
        }
        .padding(16)
        .background(DesignSystem.Colors.surface.opacity(0.5))
        .cornerRadius(12)
    }

    private var isDegrading: Bool {
        guard paceData.count >= 2 else { return false }
        let lastPace = paceData.last!.pace
        let avgPace = paceData.dropLast().map { $0.pace }.reduce(0, +) / Double(paceData.count - 1)
        return lastPace > avgPace + 10 // 10+ seconds slower
    }

    private var minPace: Double {
        paceData.map { $0.pace }.min() ?? targetPace
    }

    private var maxPace: Double {
        paceData.map { $0.pace }.max() ?? targetPace
    }

    private func paceColor(_ pace: TimeInterval) -> Color {
        if pace < targetPace - 5 {
            return .green
        } else if pace > targetPace + 10 {
            return .red
        } else {
            return DesignSystem.Colors.primary
        }
    }
}

private extension TimeInterval {
    var formattedPace: String {
        let minutes = Int(self / 60)
        let seconds = Int(self.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    PaceDegradationGraph(
        paceData: [
            PaceDataPoint(segmentIndex: 0, segmentName: "R1", pace: 288),
            PaceDataPoint(segmentIndex: 1, segmentName: "R2", pace: 295),
            PaceDataPoint(segmentIndex: 2, segmentName: "R3", pace: 308),
            PaceDataPoint(segmentIndex: 3, segmentName: "R4", pace: 315)
        ],
        targetPace: 300
    )
    .padding()
    .background(Color.black)
}
