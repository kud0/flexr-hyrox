// FLEXR - Controls Page View
// Page 4: Workout controls (pause, end, next, skip)

import SwiftUI

struct ControlsPageView: View {
    let isPaused: Bool
    let onPause: () -> Void
    let onResume: () -> Void
    let onEnd: () -> Void
    let onNext: () -> Void
    let onSkip: () -> Void

    // Apple Fitness+ green
    private let fitnessGreen = Color(red: 0.67, green: 1.0, blue: 0.0)

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            // 2x2 Grid
            VStack(spacing: 16) {
                // Top Row: Pause + Next
                HStack(spacing: 16) {
                    // Pause/Resume Button
                    ControlButton(
                        icon: isPaused ? "play.fill" : "pause.fill",
                        label: isPaused ? "Resume" : "Pause",
                        color: .yellow,
                        action: isPaused ? onResume : onPause
                    )

                    // Next Segment Button
                    ControlButton(
                        icon: "forward.fill",
                        label: "Next",
                        color: fitnessGreen,
                        action: onNext
                    )
                }

                // Bottom Row: End + Skip
                HStack(spacing: 16) {
                    // End Workout Button
                    ControlButton(
                        icon: "xmark",
                        label: "End",
                        color: .red,
                        action: onEnd
                    )

                    // Skip Button
                    ControlButton(
                        icon: "forward.end.fill",
                        label: "Skip",
                        color: .gray,
                        action: onSkip
                    )
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            // Hint text
            Text("Swipe left for metrics")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray.opacity(0.6))
                .padding(.bottom, 40)
        }
        .padding(.top, 40)
    }
}

// MARK: - Control Button

struct ControlButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .semibold))

                Text(label.uppercased())
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(color)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        ControlsPageView(
            isPaused: false,
            onPause: {},
            onResume: {},
            onEnd: {},
            onNext: {},
            onSkip: {}
        )
    }
}

#Preview("Paused") {
    ZStack {
        Color.black.ignoresSafeArea()

        ControlsPageView(
            isPaused: true,
            onPause: {},
            onResume: {},
            onEnd: {},
            onNext: {},
            onSkip: {}
        )
    }
}
