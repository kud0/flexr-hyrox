// FLEXR Watch - Shadow Runner Visualization
// Shows your position vs target/best time like Colin McRae ghost racing

import SwiftUI

struct ShadowRunnerView: View {
    let userProgress: Double // 0.0 to 1.0 (percentage of segment completed)
    let shadowProgress: Double // 0.0 to 1.0 (where shadow should be)
    let timeDifference: TimeInterval // positive = ahead, negative = behind

    private let trackLength: CGFloat = 140 // Width of the track on Watch
    private let runnerSize: CGFloat = 16

    // FLEXR Electric Blue
    private let electricBlue = Color(red: 0.039, green: 0.518, blue: 1.0) // #0A84FF

    var body: some View {
        VStack(spacing: 4) {
            // The track with runners
            ZStack(alignment: .leading) {
                // Track background
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 4)

                // Progress fill (shows how much of segment is done)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: trackLength * min(max(userProgress, shadowProgress), 1.0), height: 4)

                // Shadow runner (target/best)
                Image(systemName: "figure.run")
                    .font(.system(size: runnerSize, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .offset(x: (trackLength - runnerSize) * min(max(shadowProgress, 0), 1.0))

                // User runner (you)
                Image(systemName: "figure.run")
                    .font(.system(size: runnerSize, weight: .bold))
                    .foregroundColor(electricBlue)
                    .offset(x: (trackLength - runnerSize) * min(max(userProgress, 0), 1.0))
            }
            .frame(width: trackLength, height: 20)

            // Labels and time difference
            HStack(spacing: 8) {
                // YOU label
                HStack(spacing: 2) {
                    Circle()
                        .fill(electricBlue)
                        .frame(width: 6, height: 6)
                    Text("YOU")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                }

                Spacer()

                // Time difference indicator
                HStack(spacing: 2) {
                    Image(systemName: timeDifference >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(timeDifference >= 0 ? .green : .red)

                    Text(timeDifferenceText)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(timeDifference >= 0 ? .green : .red)
                }

                Spacer()

                // TARGET label
                HStack(spacing: 2) {
                    Circle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 6, height: 6)
                    Text("BEST")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .frame(width: trackLength)
        }
        .padding(.vertical, 4)
    }

    private var timeDifferenceText: String {
        let absTime = abs(timeDifference)
        let sign = timeDifference >= 0 ? "+" : "-"

        if absTime < 60 {
            return String(format: "%@%ds", sign, Int(absTime))
        } else {
            let minutes = Int(absTime) / 60
            let seconds = Int(absTime) % 60
            return String(format: "%@%d:%02d", sign, minutes, seconds)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // User ahead
        ShadowRunnerView(
            userProgress: 0.7,
            shadowProgress: 0.5,
            timeDifference: 8
        )

        // User behind
        ShadowRunnerView(
            userProgress: 0.4,
            shadowProgress: 0.6,
            timeDifference: -5
        )

        // Neck and neck
        ShadowRunnerView(
            userProgress: 0.5,
            shadowProgress: 0.51,
            timeDifference: -1
        )
    }
    .padding()
    .background(Color.black)
}
