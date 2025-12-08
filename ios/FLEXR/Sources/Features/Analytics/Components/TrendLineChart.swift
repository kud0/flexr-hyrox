import SwiftUI

/// Simple trend line chart for analytics
/// Design: Clean, minimal line chart showing trends over time
/// Usage: 7-day, 30-day trends for metrics like readiness, HRV, etc.
struct TrendLineChart: View {
    let dataPoints: [Double]
    let labels: [String]
    let color: Color
    let height: CGFloat

    init(
        dataPoints: [Double],
        labels: [String],
        color: Color = DesignSystem.Colors.primary,
        height: CGFloat = 280
    ) {
        self.dataPoints = dataPoints
        self.labels = labels
        self.color = color
        self.height = height
    }

    private var normalizedPoints: [CGPoint] {
        guard !dataPoints.isEmpty else { return [] }

        let maxValue = dataPoints.max() ?? 1
        let minValue = dataPoints.min() ?? 0
        let range = maxValue - minValue

        return dataPoints.enumerated().map { index, value in
            let x = CGFloat(index) / CGFloat(dataPoints.count - 1)
            let y = range > 0 ? 1 - ((value - minValue) / range) : 0.5
            return CGPoint(x: x, y: y)
        }
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            // Chart
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    // Background grid lines
                    ForEach(0..<5) { i in
                        Path { path in
                            let y = geometry.size.height * CGFloat(i) / 4
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                        }
                        .stroke(DesignSystem.Colors.divider, lineWidth: 0.5)
                    }

                    // Line chart
                    Path { path in
                        guard !normalizedPoints.isEmpty else { return }

                        let firstPoint = normalizedPoints[0]
                        path.move(to: CGPoint(
                            x: firstPoint.x * geometry.size.width,
                            y: firstPoint.y * geometry.size.height
                        ))

                        for point in normalizedPoints.dropFirst() {
                            path.addLine(to: CGPoint(
                                x: point.x * geometry.size.width,
                                y: point.y * geometry.size.height
                            ))
                        }
                    }
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                    // Area fill
                    Path { path in
                        guard !normalizedPoints.isEmpty else { return }

                        let firstPoint = normalizedPoints[0]
                        path.move(to: CGPoint(
                            x: firstPoint.x * geometry.size.width,
                            y: geometry.size.height
                        ))

                        path.addLine(to: CGPoint(
                            x: firstPoint.x * geometry.size.width,
                            y: firstPoint.y * geometry.size.height
                        ))

                        for point in normalizedPoints.dropFirst() {
                            path.addLine(to: CGPoint(
                                x: point.x * geometry.size.width,
                                y: point.y * geometry.size.height
                            ))
                        }

                        path.addLine(to: CGPoint(
                            x: normalizedPoints.last!.x * geometry.size.width,
                            y: geometry.size.height
                        ))

                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Data point dots
                    ForEach(normalizedPoints.indices, id: \.self) { index in
                        Circle()
                            .fill(color)
                            .frame(width: 8, height: 8)
                            .position(
                                x: normalizedPoints[index].x * geometry.size.width,
                                y: normalizedPoints[index].y * geometry.size.height
                            )
                    }
                }
            }
            .frame(height: height)

            // Labels
            if !labels.isEmpty {
                HStack {
                    ForEach(labels.indices, id: \.self) { index in
                        if index < labels.count {
                            Text(labels[index])
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.text.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        DesignSystem.Colors.background.ignoresSafeArea()

        VStack(spacing: DesignSystem.Spacing.xLarge) {
            // Example 1: 7-day readiness trend
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                Text("7-DAY TREND")
                    .font(DesignSystem.Typography.sectionHeader)
                    .foregroundColor(DesignSystem.Colors.text.secondary)

                TrendLineChart(
                    dataPoints: [72, 68, 75, 78, 81, 76, 78],
                    labels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
                    color: DesignSystem.Colors.success
                )
            }
            .padding()
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.Radius.large)

            // Example 2: 30-day HRV trend
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                Text("30-DAY HRV")
                    .font(DesignSystem.Typography.sectionHeader)
                    .foregroundColor(DesignSystem.Colors.text.secondary)

                TrendLineChart(
                    dataPoints: [42, 45, 43, 48, 50, 47, 45],
                    labels: ["Wk1", "Wk2", "Wk3", "Wk4"],
                    color: DesignSystem.Colors.primary,
                    height: 200
                )
            }
            .padding()
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.Radius.large)
        }
        .padding()
    }
}
