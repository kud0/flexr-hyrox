// FLEXR - Segment Transition Sheet
// Shows between segments with AI coaching message

import SwiftUI

struct SegmentTransitionSheet: View {
    let completedSegment: WorkoutSegment?
    let completionTime: TimeInterval
    let nextSegment: WorkoutSegment?
    let onStart: () -> Void

    @State private var countdown: Int = 5
    @State private var timer: Timer?

    // Apple Fitness+ green
    private let fitnessGreen = Color(red: 0.67, green: 1.0, blue: 0.0)

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Completed Section
                if let completed = completedSegment {
                    VStack(spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(fitnessGreen)

                            Text(completed.displayName.uppercased())
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }

                        Text(completionTime.formattedWorkoutTime)
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(fitnessGreen)
                    }
                    .padding(.bottom, 24)
                }

                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                    .padding(.horizontal, 40)

                // AI Coaching Message
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16))
                            .foregroundColor(.yellow)

                        Text("AI Coach")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray)
                    }

                    Text(aiCoachingMessage)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                }
                .padding(.vertical, 24)

                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                    .padding(.horizontal, 40)

                // Next Segment Section
                if let next = nextSegment {
                    VStack(spacing: 16) {
                        Text("NEXT UP")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gray)
                            .tracking(1)

                        HStack(spacing: 12) {
                            Image(systemName: nextSegmentIcon(next))
                                .font(.system(size: 28))
                                .foregroundColor(nextSegmentColor(next))

                            Text(next.displayName)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }

                        // Target info
                        HStack(spacing: 16) {
                            if let distance = next.targetDistance, distance > 0 {
                                Label("\(Int(distance))m", systemImage: "ruler")
                            }
                            if let reps = next.targetReps, reps > 0 {
                                Label("\(reps) reps", systemImage: "number")
                            }
                            if let pace = next.targetPace {
                                Label(pace, systemImage: "speedometer")
                            }
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    }
                    .padding(.vertical, 24)
                } else {
                    // Workout Complete
                    VStack(spacing: 16) {
                        Image(systemName: "flag.checkered.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(fitnessGreen)

                        Text("WORKOUT COMPLETE")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 24)
                }

                Spacer()

                // Countdown + Start Button
                VStack(spacing: 16) {
                    if nextSegment != nil {
                        Text("Starting in \(countdown)...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    }

                    Button(action: {
                        timer?.invalidate()
                        onStart()
                    }) {
                        Text(nextSegment != nil ? "TAP TO START NOW" : "FINISH")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(fitnessGreen)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            startCountdown()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    // MARK: - Countdown

    private func startCountdown() {
        guard nextSegment != nil else { return }

        countdown = 5
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if countdown > 1 {
                countdown -= 1

                // Haptic at 3, 2, 1
                if countdown <= 3 {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
            } else {
                timer?.invalidate()
                onStart()
            }
        }
    }

    // MARK: - AI Coaching Message

    private var aiCoachingMessage: String {
        guard let completed = completedSegment else {
            return "Great effort! Keep pushing."
        }

        // Generate contextual message based on segment type
        switch completed.segmentType {
        case .run:
            return "Good run! Your pace was consistent. Take a breath and prepare for the next station."

        case .station:
            if let stationType = completed.stationType {
                switch stationType {
                case .skiErg:
                    return "Strong Ski Erg! Your arms should feel the burn. Focus on steady breathing for the next run."
                case .sledPush, .sledPull:
                    return "Powerful sled work! Your legs will feel heavy on the run - that's normal. Stay smooth."
                case .wallBalls:
                    return "Wall balls done! Your legs and shoulders worked hard. Keep your running form tight."
                case .burpeeBroadJump:
                    return "Burpees complete! Your HR is elevated. Start the run controlled, then build."
                case .rowing:
                    return "Nice row! Your pulling muscles got a workout. Shake out your arms on the run."
                case .farmersCarry:
                    return "Farmers carry done! Grip might be tired. Relax your hands on the run."
                case .sandbagLunges:
                    return "Lunges finished! Your quads are loaded. Expect the run to feel harder - push through."
                default:
                    return "Station complete! Great work. Stay focused for what's next."
                }
            }
            return "Station complete! Keep the momentum going."

        case .warmup:
            return "Warm-up done! Your body is ready. Time to push the intensity."

        case .cooldown:
            return "Great cool-down. Your body will thank you tomorrow!"

        case .rest:
            return "Rest complete. You should feel recovered. Let's go!"

        default:
            return "Segment complete! Keep up the great work."
        }
    }

    // MARK: - Helpers

    private func nextSegmentIcon(_ segment: WorkoutSegment) -> String {
        segment.stationType?.icon ?? segment.segmentType.icon
    }

    private func nextSegmentColor(_ segment: WorkoutSegment) -> Color {
        switch segment.segmentType {
        case .run: return fitnessGreen
        case .warmup: return .yellow
        case .cooldown: return .mint
        case .rest: return .gray
        default: return fitnessGreen
        }
    }
}

#Preview {
    SegmentTransitionSheet(
        completedSegment: WorkoutSegment(
            workoutId: UUID(),
            segmentType: SegmentType.station,
            stationType: StationType.skiErg,
            targetDistance: 1000
        ),
        completionTime: 272,
        nextSegment: WorkoutSegment(
            workoutId: UUID(),
            segmentType: SegmentType.run,
            targetDistance: 1000,
            targetPace: "5:05-5:15"
        ),
        onStart: {}
    )
}

#Preview("Workout Complete") {
    SegmentTransitionSheet(
        completedSegment: WorkoutSegment(
            workoutId: UUID(),
            segmentType: SegmentType.run,
            targetDistance: 1000
        ),
        completionTime: 312,
        nextSegment: nil,
        onStart: {}
    )
}
