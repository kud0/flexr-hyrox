// FLEXR - Segment Info Page View
// Page 3: Current segment details and upcoming segments

import SwiftUI

struct SegmentInfoPageView: View {
    let currentSegment: WorkoutSegment?
    let nextSegment: WorkoutSegment?
    let upcomingSegment: WorkoutSegment?

    // Apple Fitness+ green
    private let fitnessGreen = Color(red: 0.67, green: 1.0, blue: 0.0)

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Current Segment
            if let current = currentSegment {
                SegmentInfoCard(
                    title: "CURRENT SEGMENT",
                    segment: current,
                    isPrimary: true
                )
            }

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
                .padding(.horizontal, 32)
                .padding(.vertical, 20)

            // Next Segment
            if let next = nextSegment {
                SegmentInfoCard(
                    title: "NEXT UP",
                    segment: next,
                    isPrimary: false
                )
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "flag.checkered.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(fitnessGreen)

                    Text("FINAL SEGMENT")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.gray)
                }
            }

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
                .padding(.horizontal, 32)
                .padding(.vertical, 20)

            // Upcoming Segment
            if let upcoming = upcomingSegment {
                SegmentInfoCard(
                    title: "AFTER THAT",
                    segment: upcoming,
                    isPrimary: false,
                    isCompact: true
                )
            }

            Spacer()
        }
        .padding(.top, 40)
    }
}

// MARK: - Segment Info Card

struct SegmentInfoCard: View {
    let title: String
    let segment: WorkoutSegment
    let isPrimary: Bool
    var isCompact: Bool = false

    // Apple Fitness+ green
    private let fitnessGreen = Color(red: 0.67, green: 1.0, blue: 0.0)

    var body: some View {
        VStack(spacing: isCompact ? 6 : 10) {
            // Title
            Text(title)
                .font(.system(size: isCompact ? 11 : 12, weight: .semibold))
                .foregroundColor(.gray)
                .tracking(1)

            // Icon + Name
            HStack(spacing: 10) {
                Image(systemName: segmentIcon)
                    .font(.system(size: isPrimary ? 24 : 18))
                    .foregroundColor(segmentColor)

                Text(segment.displayName)
                    .font(.system(size: isPrimary ? 22 : 16, weight: .bold))
                    .foregroundColor(isPrimary ? .white : .gray)
            }

            // Target Info
            if !isCompact {
                HStack(spacing: 16) {
                    if let distance = segment.targetDistance, distance > 0 {
                        TargetBadge(icon: "ruler", value: "\(Int(distance))m")
                    }

                    if let reps = segment.targetReps, reps > 0 {
                        TargetBadge(icon: "number", value: "\(reps) reps")
                    }

                    if let duration = segment.targetDuration, duration > 0 {
                        TargetBadge(icon: "clock", value: duration.formattedWorkoutTime)
                    }

                    if let pace = segment.targetPace {
                        TargetBadge(icon: "speedometer", value: pace)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 24)
    }

    private var segmentIcon: String {
        segment.stationType?.icon ?? segment.segmentType.icon
    }

    private var segmentColor: Color {
        switch segment.segmentType {
        case .run: return fitnessGreen
        case .warmup: return .yellow
        case .cooldown: return .mint
        case .rest: return .gray
        case .station: return fitnessGreen
        default: return fitnessGreen
        }
    }
}

// MARK: - Target Badge

struct TargetBadge: View {
    let icon: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(value)
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundColor(.gray)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        SegmentInfoPageView(
            currentSegment: WorkoutSegment(
                workoutId: UUID(),
                segmentType: SegmentType.run,
                targetDistance: 1000,
                targetPace: "5:00-5:15"
            ),
            nextSegment: WorkoutSegment(
                workoutId: UUID(),
                segmentType: SegmentType.station,
                stationType: StationType.skiErg,
                targetDistance: 1000
            ),
            upcomingSegment: WorkoutSegment(
                workoutId: UUID(),
                segmentType: SegmentType.run,
                targetDistance: 1000
            )
        )
    }
}
