// FLEXR - HR Zones Card
// Heart rate zone distribution with percentages

import SwiftUI

struct HRZonesCard: View {
    let zones: [HRZoneData]
    let currentHR: Int
    let currentZone: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("HR ZONES")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.text.primary)
                    .tracking(1.0)

                Spacer()

                HStack(spacing: 6) {
                    Circle()
                        .fill(zoneColor(currentZone))
                        .frame(width: 8, height: 8)

                    Text("\(currentHR) bpm")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(zoneColor(currentZone))
                        .monospacedDigit()

                    Text("Z\(currentZone)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }
            }

            // Zone bars
            VStack(spacing: 8) {
                ForEach(zones.sorted(by: { $0.zone > $1.zone })) { zone in
                    HStack(spacing: 12) {
                        Text("Z\(zone.zone)")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(zone.color)
                            .frame(width: 28)

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(DesignSystem.Colors.surface)
                                    .frame(height: 8)

                                // Fill
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(zone.color)
                                    .frame(
                                        width: geometry.size.width * (zone.percentage / 100),
                                        height: 8
                                    )
                            }
                        }
                        .frame(height: 8)

                        Text("\(Int(zone.percentage))%")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(DesignSystem.Colors.text.secondary)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }

            // Zone legend
            HStack(spacing: 16) {
                ForEach([5, 4, 3, 2], id: \.self) { zone in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(zoneColor(zone))
                            .frame(width: 6, height: 6)

                        Text(zoneName(zone))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.text.tertiary)
                    }
                }
            }
        }
        .padding(16)
        .background(DesignSystem.Colors.surface.opacity(0.5))
        .cornerRadius(12)
    }

    private func zoneColor(_ zone: Int) -> Color {
        switch zone {
        case 5: return .red
        case 4: return .orange
        case 3: return DesignSystem.Colors.primary
        case 2: return .cyan
        default: return .gray
        }
    }

    private func zoneName(_ zone: Int) -> String {
        switch zone {
        case 5: return "Max"
        case 4: return "Hard"
        case 3: return "Tempo"
        case 2: return "Easy"
        default: return "Rest"
        }
    }
}

#Preview {
    HRZonesCard(
        zones: [
            HRZoneData(zone: 5, percentage: 5, duration: 30, color: .red),
            HRZoneData(zone: 4, percentage: 45, duration: 270, color: .orange),
            HRZoneData(zone: 3, percentage: 30, duration: 180, color: DesignSystem.Colors.primary),
            HRZoneData(zone: 2, percentage: 20, duration: 120, color: .cyan)
        ],
        currentHR: 172,
        currentZone: 4
    )
    .padding()
    .background(Color.black)
}
