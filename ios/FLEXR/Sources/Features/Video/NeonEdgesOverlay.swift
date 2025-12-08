// FLEXR - Neon Edges Video Overlay
// Pulsing glowing borders that react to heart rate
// Makes FLEXR videos instantly recognizable on social media

import SwiftUI

struct NeonEdgesOverlay: View {
    @ObservedObject var workoutVM: WorkoutExecutionViewModel

    @State private var pulseAnimation: CGFloat = 1.0
    @State private var glowIntensity: Double = 0.5

    // FLEXR Electric Blue
    private let electricBlue = Color(red: 0.039, green: 0.518, blue: 1.0) // #0A84FF
    private let neonGreen = Color(red: 0.67, green: 1.0, blue: 0.0) // #ABFF00 (your original brand color)

    var body: some View {
        ZStack {
            // Top glowing edge
            topEdge

            // Bottom glowing edge
            bottomEdge

            // Top info panel
            topPanel

            // Bottom info panel
            bottomPanel
        }
        .onAppear {
            startPulseAnimation()
        }
    }

    // MARK: - Glowing Edges

    private var topEdge: some View {
        VStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            hrZoneColor.opacity(glowIntensity),
                            hrZoneColor.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 80)
                .blur(radius: 20)
                .scaleEffect(x: pulseAnimation, y: 1.0)
                .animation(.easeInOut(duration: heartRatePulseDuration), value: pulseAnimation)

            Spacer()
        }
        .ignoresSafeArea()
    }

    private var bottomEdge: some View {
        VStack {
            Spacer()

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            hrZoneColor.opacity(0.0),
                            hrZoneColor.opacity(glowIntensity)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 80)
                .blur(radius: 20)
                .scaleEffect(x: pulseAnimation, y: 1.0)
                .animation(.easeInOut(duration: heartRatePulseDuration), value: pulseAnimation)
        }
        .ignoresSafeArea()
    }

    // MARK: - Info Panels

    private var topPanel: some View {
        VStack {
            HStack(spacing: 12) {
                // Recording indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .opacity(pulseAnimation > 0.95 ? 1.0 : 0.3)

                    Text("REC")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.6))
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.red.opacity(0.5), lineWidth: 1)
                        )
                )

                Spacer()

                // Timer
                Text(formattedTime(workoutVM.totalElapsedTime))
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .shadow(color: electricBlue, radius: 8)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.7))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(electricBlue.opacity(0.8), lineWidth: 2)
                            )
                    )

                Spacer()

                // Heart rate
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(hrZoneColor)
                        .scaleEffect(pulseAnimation)

                    Text("\(currentHeartRate)")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)

                    Text("BPM")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.7))
                        .overlay(
                            Capsule()
                                .strokeBorder(hrZoneColor.opacity(0.6), lineWidth: 2)
                        )
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 50)

            Spacer()
        }
    }

    private var currentSegmentRow: some View {
        HStack {
            Image(systemName: segmentIcon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(segmentColor)

            Text(currentSegmentName)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .textCase(.uppercase)
                .shadow(color: segmentColor, radius: 8)

            Spacer()

            // Round counter
            roundCounter
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(segmentBackground)
    }

    private var roundCounter: some View {
        HStack(spacing: 4) {
            Text("\(1)")
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(electricBlue)

            Text("/")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white.opacity(0.5))

            Text("\(1)")
                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(electricBlue.opacity(0.5), lineWidth: 1.5)
                )
        )
    }

    private var segmentBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.black.opacity(0.75))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            colors: [segmentColor.opacity(0.8), electricBlue.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
            )
    }

    private var bottomPanel: some View {
        VStack {
            Spacer()

            VStack(spacing: 12) {
                // Current segment
                currentSegmentRow

                // Next segment preview (optional)

                // Next segment preview (optional)
                if let nextSegment = workoutVM.nextSegment {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))

                        Text("NEXT:")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))

                        Text(nextSegment.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .textCase(.uppercase)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.5))
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Computed Properties

    private var currentHeartRate: Int {
        // Get from HealthKit or Watch
        // For now, return mock value
        return 152
    }

    private var hrZoneColor: Color {
        let hr = currentHeartRate

        // Calculate zones based on max HR (approximate)
        let maxHR = 220 - 30 // Assume age 30 for now
        let percentage = Double(hr) / Double(maxHR)

        if percentage < 0.6 {
            return .blue // Zone 1-2
        } else if percentage < 0.7 {
            return .green // Zone 3
        } else if percentage < 0.8 {
            return .yellow // Zone 4
        } else {
            return .red // Zone 5
        }
    }

    private var heartRatePulseDuration: Double {
        // Pulse faster at higher HR
        let hr = Double(currentHeartRate)
        return 60.0 / hr // Pulse matches heart rate
    }

    private var currentSegmentName: String {
        workoutVM.currentSegment?.displayName ?? "Ready"
    }

    private var segmentColor: Color {
        switch workoutVM.currentSegment?.segmentType {
        case .run:
            return neonGreen
        case .station:
            return .orange
        case .warmup:
            return .yellow
        case .cooldown:
            return .blue
        default:
            return electricBlue
        }
    }

    private var segmentIcon: String {
        switch workoutVM.currentSegment?.segmentType {
        case .run:
            return "figure.run"
        case .station:
            return "dumbbell.fill"
        case .warmup:
            return "flame.fill"
        case .cooldown:
            return "wind"
        default:
            return "bolt.fill"
        }
    }

    // MARK: - Animations

    private func startPulseAnimation() {
        // Pulse based on heart rate
        Timer.scheduledTimer(withTimeInterval: heartRatePulseDuration, repeats: true) { _ in
            withAnimation(.easeInOut(duration: heartRatePulseDuration * 0.3)) {
                pulseAnimation = 1.05
                glowIntensity = 0.7
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + heartRatePulseDuration * 0.3) {
                withAnimation(.easeInOut(duration: heartRatePulseDuration * 0.7)) {
                    pulseAnimation = 1.0
                    glowIntensity = 0.5
                }
            }
        }
    }
}

// MARK: - Preview

    // MARK: - Helper Functions

    private func formattedTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }


#Preview {
    ZStack {
        // Mock camera view
        Color.gray
            .ignoresSafeArea()

        // Overlay
        NeonEdgesOverlay(
            workoutVM: WorkoutExecutionViewModel(workout: Workout(userId: UUID(), date: Date(), type: .fullSimulation, segments: [WorkoutSegment(workoutId: UUID(), segmentType: .warmup, targetDuration: 600), WorkoutSegment(workoutId: UUID(), segmentType: .run, targetDistance: 1000), WorkoutSegment(workoutId: UUID(), segmentType: .station, stationType: .skiErg, targetDistance: 1000)]))
        )
    }
}
