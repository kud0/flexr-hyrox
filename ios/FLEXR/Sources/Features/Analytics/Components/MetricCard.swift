import SwiftUI

// MARK: - Reusable Metric Card Component
// Apple Fitness+ style card with clean dark design

struct MetricCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text(title)
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            content
        }
        .padding(DesignSystem.Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.large)
    }
}

// MARK: - Progress Bar Component
struct ProgressBar: View {
    let progress: Double // 0.0 to 1.0
    let height: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color

    init(
        progress: Double,
        height: CGFloat = 8,
        backgroundColor: Color = DesignSystem.Colors.surface,
        foregroundColor: Color = DesignSystem.Colors.primary
    ) {
        self.progress = max(0, min(1, progress))
        self.height = height
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(backgroundColor)
                    .frame(height: height)
                    .cornerRadius(height / 2)

                Rectangle()
                    .fill(foregroundColor)
                    .frame(width: geometry.size.width * progress, height: height)
                    .cornerRadius(height / 2)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Circular Progress View
struct CircularProgress: View {
    let progress: Double // 0.0 to 1.0
    let lineWidth: CGFloat
    let size: CGFloat
    let color: Color

    init(
        progress: Double,
        lineWidth: CGFloat = 12,
        size: CGFloat = 120,
        color: Color = DesignSystem.Colors.primary
    ) {
        self.progress = max(0, min(1, progress))
        self.lineWidth = lineWidth
        self.size = size
        self.color = color
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(
                    DesignSystem.Colors.surface,
                    lineWidth: lineWidth
                )

            // Progress circle
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
                .animation(DesignSystem.Animation.spring, value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Trend Indicator
struct TrendIndicator: View {
    let value: String
    let isPositive: Bool
    let label: String?

    init(value: String, isPositive: Bool, label: String? = nil) {
        self.value = value
        self.isPositive = isPositive
        self.label = label
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isPositive ? "arrow.down.right" : "arrow.up.right")
                .font(.system(size: 14, weight: .bold))
            Text(value)
                .font(DesignSystem.Typography.bodyEmphasized)
            if let label = label {
                Text(label)
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }
        }
        .foregroundColor(isPositive ? DesignSystem.Colors.success : DesignSystem.Colors.error)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            (isPositive ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                .opacity(0.15)
        )
        .cornerRadius(8)
    }
}

// MARK: - Score Badge
struct ScoreBadge: View {
    let score: Int // 0-100
    let size: CGFloat

    init(score: Int, size: CGFloat = 80) {
        self.score = max(0, min(100, score))
        self.size = size
    }

    private var scoreColor: Color {
        switch score {
        case 80...100: return DesignSystem.Colors.success
        case 60..<80: return DesignSystem.Colors.warning
        default: return DesignSystem.Colors.error
        }
    }

    var body: some View {
        ZStack {
            CircularProgress(
                progress: Double(score) / 100.0,
                lineWidth: 8,
                size: size,
                color: scoreColor
            )

            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.text.primary)
                Text("/100")
                    .font(.system(size: size * 0.12, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.text.secondary)
            }
        }
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(DesignSystem.Colors.text.primary)

            Text(label)
                .font(.system(size: 12))
                .foregroundColor(DesignSystem.Colors.text.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.medium)
    }
}

// MARK: - Preview
#Preview("MetricCard") {
    VStack(spacing: 20) {
        MetricCard(title: "Readiness") {
            HStack {
                ScoreBadge(score: 78, size: 100)
                Spacer()
                VStack(alignment: .leading, spacing: 8) {
                    Text("HRV: 45ms (+8%)")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text.primary)
                    Text("Sleep: 7.2h")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text.primary)
                    Text("RHR: 52 bpm")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text.primary)
                }
            }
        }

        HStack(spacing: 12) {
            StatCard(icon: "calendar.badge.clock", value: "32 km", label: "This Week", color: DesignSystem.Colors.primary)
            StatCard(icon: "calendar", value: "128 km", label: "This Month", color: DesignSystem.Colors.primary)
        }

        VStack(alignment: .leading, spacing: 8) {
            Text("Progress")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.text.primary)
            ProgressBar(progress: 0.65)
            Text("6.5 / 8.0 hours")
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.text.secondary)
        }
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.Radius.medium)
    }
    .padding()
    .background(Color.black)
}
