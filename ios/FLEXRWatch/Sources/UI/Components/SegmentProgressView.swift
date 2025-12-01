import SwiftUI

/// Visual progress indicator for workout segments
struct SegmentProgressView: View {
    let currentSegment: Int
    let totalSegments: Int
    let segmentType: ProgressType

    enum ProgressType {
        case compact    // Dots or small indicators
        case detailed   // Full segment names
        case timeline   // Vertical timeline
    }

    var body: some View {
        switch segmentType {
        case .compact:
            CompactProgressView(current: currentSegment, total: totalSegments)
        case .detailed:
            DetailedProgressView(current: currentSegment, total: totalSegments)
        case .timeline:
            TimelineProgressView(current: currentSegment, total: totalSegments)
        }
    }
}

// MARK: - Compact Progress View
struct CompactProgressView: View {
    let current: Int
    let total: Int

    private let maxDotsToShow = 17 // HYROX standard

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<min(total, maxDotsToShow), id: \.self) { index in
                Circle()
                    .fill(index < current ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
                    .overlay(
                        Circle()
                            .stroke(index == current ? Color.white : Color.clear, lineWidth: 2)
                    )
            }
        }
    }
}

// MARK: - Detailed Progress View
struct DetailedProgressView: View {
    let current: Int
    let total: Int

    var body: some View {
        VStack(spacing: 8) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.green, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * progress,
                            height: 8
                        )
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 8)

            // Text indicator
            HStack {
                Text("Segment \(current + 1) of \(total)")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.caption2.bold())
                    .foregroundColor(.primary)
            }
        }
    }

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }
}

// MARK: - Timeline Progress View
struct TimelineProgressView: View {
    let current: Int
    let total: Int

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<total, id: \.self) { index in
                HStack(spacing: 12) {
                    // Timeline indicator
                    VStack(spacing: 0) {
                        if index > 0 {
                            Rectangle()
                                .fill(index <= current ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 2, height: 16)
                        }

                        Circle()
                            .fill(index < current ? Color.green : (index == current ? Color.blue : Color.gray.opacity(0.3)))
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: index == current ? 2 : 0)
                            )

                        if index < total - 1 {
                            Rectangle()
                                .fill(index < current ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 2, height: 16)
                        }
                    }

                    // Segment info
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Segment \(index + 1)")
                            .font(.caption.bold())
                            .foregroundColor(index <= current ? .primary : .secondary)

                        if index == current {
                            Text("In Progress")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        } else if index < current {
                            Text("Complete")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }

                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - Segment Cards View
/// Shows upcoming segments as cards
struct SegmentCardsView: View {
    let segments: [SegmentCardData]
    let currentIndex: Int

    struct SegmentCardData: Identifiable {
        let id: UUID
        let name: String
        let type: String
        let target: String
        let iconName: String
        let color: Color

        init(id: UUID = UUID(), name: String, type: String, target: String, iconName: String, color: Color) {
            self.id = id
            self.name = name
            self.type = type
            self.target = target
            self.iconName = iconName
            self.color = color
        }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                    SegmentCard(
                        segment: segment,
                        status: cardStatus(for: index)
                    )
                }
            }
            .padding(.horizontal)
        }
    }

    private func cardStatus(for index: Int) -> CardStatus {
        if index < currentIndex {
            return .completed
        } else if index == currentIndex {
            return .active
        } else {
            return .upcoming
        }
    }

    enum CardStatus {
        case completed, active, upcoming
    }
}

// MARK: - Segment Card
struct SegmentCard: View {
    let segment: SegmentCardsView.SegmentCardData
    let status: SegmentCardsView.CardStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon and type
            HStack(spacing: 6) {
                Image(systemName: segment.iconName)
                    .font(.caption2)
                    .foregroundColor(segment.color)

                Text(segment.type)
                    .font(.caption2.bold())
                    .foregroundColor(segment.color)
                    .textCase(.uppercase)

                Spacer()

                // Status indicator
                statusIndicator
            }

            // Name
            Text(segment.name)
                .font(.caption.bold())
                .foregroundColor(.primary)
                .lineLimit(1)

            // Target
            Text(segment.target)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(width: 140)
        .background(backgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: status == .active ? 2 : 0)
        )
    }

    @ViewBuilder
    private var statusIndicator: some View {
        switch status {
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(.green)
        case .active:
            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)
        case .upcoming:
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 6, height: 6)
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .completed:
            return Color.green.opacity(0.1)
        case .active:
            return Color.blue.opacity(0.15)
        case .upcoming:
            return Color.gray.opacity(0.1)
        }
    }

    private var borderColor: Color {
        switch status {
        case .active:
            return Color.blue
        default:
            return Color.clear
        }
    }
}

// MARK: - Previews
#Preview("Compact Progress") {
    VStack(spacing: 20) {
        CompactProgressView(current: 5, total: 17)
        CompactProgressView(current: 12, total: 17)
        CompactProgressView(current: 17, total: 17)
    }
    .padding()
}

#Preview("Detailed Progress") {
    VStack(spacing: 20) {
        DetailedProgressView(current: 3, total: 17)
        DetailedProgressView(current: 10, total: 17)
    }
    .padding()
}

#Preview("Timeline Progress") {
    ScrollView {
        TimelineProgressView(current: 2, total: 8)
            .padding()
    }
}

#Preview("Segment Cards") {
    SegmentCardsView(
        segments: [
            .init(name: "Run 1", type: "Run", target: "1000m", iconName: "figure.run", color: .blue),
            .init(name: "Ski Erg", type: "Ski", target: "1000m", iconName: "figure.skiing.crosscountry", color: .cyan),
            .init(name: "Run 2", type: "Run", target: "1000m", iconName: "figure.run", color: .blue),
            .init(name: "Sleds", type: "Push", target: "50m", iconName: "figure.strengthtraining.traditional", color: .orange)
        ],
        currentIndex: 1
    )
    .frame(height: 120)
}
