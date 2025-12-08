import SwiftUI
import WatchKit

struct SegmentTransitionView: View {
    let completedSegment: WorkoutSegment
    let completionTime: TimeInterval
    let nextSegment: WorkoutSegment?
    let onStart: () -> Void

    private let appleGreen = Color(red: 0.19, green: 0.82, blue: 0.35)

    var body: some View {
        VStack(spacing: 0) {
            // Completed Segment Section
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(appleGreen)

                    Text(completedSegment.displayName.uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }

                Text("Done: \(completionTime.formattedTime)")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.3))

            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)

            Spacer()

            // Next Segment Section
            if let next = nextSegment {
                VStack(spacing: 8) {
                    Text("NEXT UP:")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.gray)

                    HStack(spacing: 6) {
                        Image(systemName: next.segmentType.icon)
                            .font(.system(size: 18))
                        Text(next.displayName.uppercased())
                            .font(.system(size: 16, weight: .bold))
                            .lineLimit(1)
                    }
                    .foregroundColor(colorForSegment(next.segmentType))

                    if let targetInfo = nextSegmentTargetInfo {
                        Text(targetInfo)
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }

                    if let context = nextSegmentContext {
                        Text(context)
                            .font(.system(size: 10))
                            .foregroundColor(.gray.opacity(0.8))
                            .italic()
                    }
                }
            } else {
                // Workout Complete
                VStack(spacing: 8) {
                    Image(systemName: "flag.checkered.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(appleGreen)

                    Text("WORKOUT COMPLETE")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            Spacer()

            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)

            // Action Button
            Button {
                WKInterfaceDevice.current().play(.success)
                onStart()
            } label: {
                Text(nextSegment != nil ? "TAP TO START" : "FINISH")
                    .font(.system(size: 15, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(appleGreen)
                    .foregroundColor(.black)
            }
            .buttonStyle(.plain)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Computed Properties

    private var nextSegmentTargetInfo: String? {
        guard let next = nextSegment else { return nil }

        var components: [String] = []

        if let duration = next.targetDuration {
            components.append("Target: \(duration.formattedTime)")
        }

        if let distance = next.targetDistance {
            components.append("\(Int(distance))m")
        }

        if let reps = next.targetReps {
            components.append("\(reps) reps")
        }

        if let pace = next.targetPace {
            components.append(pace)
        }

        return components.isEmpty ? nil : components.joined(separator: " • ")
    }

    private var nextSegmentContext: String? {
        guard nextSegment != nil else { return nil }
        return "(Post-\(completedSegment.displayName))"
    }

    private func colorForSegment(_ type: SegmentType) -> Color {
        switch type {
        case .run: return DesignSystem.Colors.running
        case .station: return DesignSystem.Colors.secondary
        case .rest: return DesignSystem.Colors.zone1
        default: return .white
        }
    }
}

// MARK: - Local Helpers

// Removed duplicate WorkoutSegment struct to use shared Core/Models/WorkoutSegment.swift

#Preview {
    SegmentTransitionView(
        completedSegment: WorkoutSegment(
            workoutId: UUID(),
            segmentType: .station,
            stationType: .wallBalls,
            targetReps: 100
        ),
        completionTime: 68,
        nextSegment: WorkoutSegment(
            workoutId: UUID(),
            segmentType: .run,
            targetDuration: 190,
            targetDistance: 600,
            targetPace: "3:05-3:15"
        ),
        onStart: {}
    )
}

#Preview("Workout Complete") {
    SegmentTransitionView(
        completedSegment: WorkoutSegment(
            workoutId: UUID(),
            segmentType: .run,
            targetDistance: 600
        ),
        completionTime: 192,
        nextSegment: nil,
        onStart: {}
    )
}
