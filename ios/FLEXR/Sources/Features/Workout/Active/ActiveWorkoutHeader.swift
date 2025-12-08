// FLEXR - Active Workout Header
// Floating header showing current segment info

import SwiftUI

struct ActiveWorkoutHeader: View {
    let segmentIcon: String
    let segmentLabel: String
    let segmentNumber: Int
    let totalSegments: Int
    let segmentColor: Color

    var body: some View {
        HStack(spacing: 10) {
            // Segment Icon in Circle
            ZStack {
                Circle()
                    .stroke(segmentColor, lineWidth: 3)
                    .frame(width: 36, height: 36)

                Image(systemName: segmentIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(segmentColor)
            }

            // Segment Label
            Text(segmentLabel)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()

            // Segment Counter
            Text("\(segmentNumber)/\(totalSegments)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
        }
        .padding(.horizontal, 4)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 20) {
            ActiveWorkoutHeader(
                segmentIcon: "figure.run",
                segmentLabel: "1000M",
                segmentNumber: 3,
                totalSegments: 16,
                segmentColor: Color(red: 0.67, green: 1.0, blue: 0.0)
            )

            ActiveWorkoutHeader(
                segmentIcon: "figure.skiing.crosscountry",
                segmentLabel: "SKI ERG",
                segmentNumber: 4,
                totalSegments: 16,
                segmentColor: Color(red: 0.67, green: 1.0, blue: 0.0)
            )

            ActiveWorkoutHeader(
                segmentIcon: "flame.fill",
                segmentLabel: "10 MIN",
                segmentNumber: 1,
                totalSegments: 16,
                segmentColor: .yellow
            )
        }
        .padding()
    }
}
