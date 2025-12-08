// FLEXR - Heart Rate Page View
// Page 2: Heart rate zones display

import SwiftUI

struct HeartRatePageView: View {
    let currentHR: Int
    let avgHR: Int
    let maxHR: Int

    // Apple Fitness+ green
    private let fitnessGreen = Color(red: 0.67, green: 1.0, blue: 0.0)

    // Max HR for zone calculation (should come from user profile)
    private let userMaxHR: Int = 180

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Large Heart Rate Display
            VStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
                    .symbolEffect(.pulse, options: .repeating)

                Text("\(currentHR)")
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()

                Text("BPM")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.gray)
            }

            // Zone Bars
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { zone in
                    HeartRateZoneBar(
                        zone: zone,
                        isActive: zone == currentZone,
                        color: zoneColor(zone)
                    )
                }
            }
            .padding(.horizontal, 32)

            // Zone Label
            VStack(spacing: 6) {
                Text("ZONE \(currentZone)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(zoneColor(currentZone))

                Text(zoneDescription(currentZone))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
            }

            Spacer()

            // Stats Row
            HStack(spacing: 40) {
                StatItem(label: "AVG", value: "\(avgHR)", color: .white)

                Divider()
                    .frame(height: 40)
                    .background(Color.gray.opacity(0.5))

                StatItem(label: "MAX", value: "\(maxHR)", color: .red)
            }
            .padding(.bottom, 40)
        }
        .padding(.top, 40)
    }

    // MARK: - Zone Calculation

    private var currentZone: Int {
        let percentage = Double(currentHR) / Double(userMaxHR)

        switch percentage {
        case ..<0.6: return 1
        case 0.6..<0.7: return 2
        case 0.7..<0.8: return 3
        case 0.8..<0.9: return 4
        default: return 5
        }
    }

    private func zoneColor(_ zone: Int) -> Color {
        switch zone {
        case 1: return .blue
        case 2: return .green
        case 3: return .yellow
        case 4: return .orange
        case 5: return .red
        default: return .gray
        }
    }

    private func zoneDescription(_ zone: Int) -> String {
        switch zone {
        case 1: return "Recovery"
        case 2: return "Fat Burn"
        case 3: return "Aerobic"
        case 4: return "Threshold"
        case 5: return "Maximum"
        default: return ""
        }
    }
}

// MARK: - Zone Bar

private struct HeartRateZoneBar: View {
    let zone: Int
    let isActive: Bool
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? color : color.opacity(0.3))
                .frame(height: isActive ? 60 : 40)
                .animation(.spring(response: 0.3), value: isActive)

            Text("\(zone)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isActive ? color : .gray)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        HeartRatePageView(
            currentHR: 156,
            avgHR: 148,
            maxHR: 172
        )
    }
}
