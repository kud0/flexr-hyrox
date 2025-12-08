import SwiftUI

// MARK: - Enhanced Run Card
// Apple Fitness+ style running session card
// Displays: Type, Distance, Duration, Pace, HR, Zones, PR badge

struct EnhancedRunCard: View {
    let session: RunningSession
    let isPR: Bool  // Parent determines if this is a PR
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                // Top row: Type + Main metrics + Pace/HR
                HStack(alignment: .top, spacing: DesignSystem.Spacing.medium) {
                    // Left: Session type icon
                    sessionTypeSection

                    // Center: Distance, duration, date
                    mainMetricsSection

                    Spacer()

                    // Right: Pace and HR
                    paceHeartRateSection
                }

                // Bottom: HR zone bar (if available)
                if session.heartRateZones != nil {
                    heartRateZoneBar
                }
            }
            .padding(DesignSystem.Spacing.medium)
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.Radius.large)
            .overlay(alignment: .topTrailing) {
                // PR badge (top-right corner)
                if isPR {
                    prBadge
                        .padding(DesignSystem.Spacing.small)
                }
            }
            .overlay(alignment: .trailing) {
                // Chevron indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.text.tertiary)
                    .padding(.trailing, DesignSystem.Spacing.medium)
            }
        }
        .buttonStyle(CardButtonStyle())
    }

    // MARK: - Session Type Section

    private var sessionTypeSection: some View {
        VStack(spacing: DesignSystem.Spacing.xxSmall) {
            // Icon in colored circle
            ZStack {
                Circle()
                    .fill(sessionTypeColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: session.sessionType.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(sessionTypeColor)
            }

            // Type name
            Text(session.sessionType.displayName)
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .lineLimit(1)
                .frame(width: 60)
        }
    }

    private var sessionTypeColor: Color {
        switch session.sessionType.color {
        case "blue": return DesignSystem.Colors.primary
        case "red": return DesignSystem.Colors.error
        case "orange": return DesignSystem.Colors.warning
        case "purple": return Color.purple
        case "green": return DesignSystem.Colors.success
        case "gray": return DesignSystem.Colors.text.secondary
        default: return DesignSystem.Colors.primary
        }
    }

    // MARK: - Main Metrics Section

    private var mainMetricsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxSmall) {
            // Distance (large, bold)
            Text(session.displayDistance)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(DesignSystem.Colors.text.primary)

            // Duration
            Text(session.displayDuration)
                .font(DesignSystem.Typography.callout)
                .foregroundColor(DesignSystem.Colors.text.secondary)

            // Relative date
            Text(relativeDate)
                .font(DesignSystem.Typography.caption1)
                .foregroundColor(DesignSystem.Colors.text.tertiary)
        }
    }

    private var relativeDate: String {
        let calendar = Calendar.current
        let date = session.startedAt ?? session.createdAt

        if calendar.isDateInToday(date) {
            return "Today"
        }
        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }

        let days = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
        if days < 7 {
            return "\(days) days ago"
        }

        return date.formatted(date: .abbreviated, time: .omitted)
    }

    // MARK: - Pace & Heart Rate Section

    private var paceHeartRateSection: some View {
        VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xxxSmall) {
            // Pace (accent color)
            Text(session.displayPace)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(DesignSystem.Colors.primary)

            // Heart rate (if available)
            if let hrDisplay = session.displayAvgHeartRate {
                HStack(spacing: DesignSystem.Spacing.xxxSmall) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "FF453A"))

                    Text(hrDisplay)
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(DesignSystem.Colors.text.secondary)
                }
            }
        }
    }

    // MARK: - Heart Rate Zone Bar

    private var heartRateZoneBar: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                if let zones = session.heartRateZones {
                    let totalTime = zones.totalTime

                    // Zone 1
                    if zones.zone1Seconds > 0 {
                        Rectangle()
                            .fill(DesignSystem.Colors.zone1)
                            .frame(width: zoneWidth(zones.zone1Seconds, total: totalTime, available: geometry.size.width))
                    }

                    // Zone 2
                    if zones.zone2Seconds > 0 {
                        Rectangle()
                            .fill(DesignSystem.Colors.zone2)
                            .frame(width: zoneWidth(zones.zone2Seconds, total: totalTime, available: geometry.size.width))
                    }

                    // Zone 3
                    if zones.zone3Seconds > 0 {
                        Rectangle()
                            .fill(DesignSystem.Colors.zone3)
                            .frame(width: zoneWidth(zones.zone3Seconds, total: totalTime, available: geometry.size.width))
                    }

                    // Zone 4
                    if zones.zone4Seconds > 0 {
                        Rectangle()
                            .fill(DesignSystem.Colors.zone4)
                            .frame(width: zoneWidth(zones.zone4Seconds, total: totalTime, available: geometry.size.width))
                    }

                    // Zone 5
                    if zones.zone5Seconds > 0 {
                        Rectangle()
                            .fill(DesignSystem.Colors.zone5)
                            .frame(width: zoneWidth(zones.zone5Seconds, total: totalTime, available: geometry.size.width))
                    }
                }
            }
            .cornerRadius(2)
        }
        .frame(height: 4)
    }

    private func zoneWidth(_ zoneTime: TimeInterval, total: TimeInterval, available: CGFloat) -> CGFloat {
        guard total > 0 else { return 0 }
        let percentage = zoneTime / total
        return available * percentage - 1 // Subtract spacing
    }

    // MARK: - PR Badge

    private var prBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 10, weight: .bold))

            Text("PR")
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundColor(.black)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.yellow) // Gold/yellow
        )
    }
}

// MARK: - Card Button Style

private struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(DesignSystem.Animation.fast, value: configuration.isPressed)
    }
}

// MARK: - Preview

#if DEBUG
struct EnhancedRunCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            // PR session with HR zones
            EnhancedRunCard(
                session: RunningSession(
                    id: UUID(),
                    userId: UUID(),
                    gymId: nil,
                    sessionType: .timeTrial5k,
                    workoutId: nil,
                    distanceMeters: 5000,
                    durationSeconds: 1320, // 22:00
                    elevationGainMeters: 50,
                    avgPacePerKm: 264, // 4:24 /km
                    fastestKmPace: 252,
                    slowestKmPace: 276,
                    avgHeartRate: 168,
                    maxHeartRate: 182,
                    heartRateZones: HeartRateZones(
                        zone1Seconds: 60,
                        zone2Seconds: 120,
                        zone3Seconds: 300,
                        zone4Seconds: 600,
                        zone5Seconds: 240
                    ),
                    splits: nil,
                    routeData: nil,
                    paceConsistency: 8.5,
                    fadeFactor: -2.1,
                    createdAt: Date(),
                    startedAt: Date(),
                    endedAt: Date().addingTimeInterval(1320),
                    visibility: .public,
                    notes: nil
                ),
                isPR: true,
                onTap: {}
            )

            // Long run, 2 days ago
            EnhancedRunCard(
                session: RunningSession(
                    id: UUID(),
                    userId: UUID(),
                    gymId: nil,
                    sessionType: .longRun,
                    workoutId: nil,
                    distanceMeters: 8520,
                    durationSeconds: 2723, // 45:23
                    elevationGainMeters: 120,
                    avgPacePerKm: 319, // 5:19 /km
                    fastestKmPace: 305,
                    slowestKmPace: 335,
                    avgHeartRate: 152,
                    maxHeartRate: 165,
                    heartRateZones: HeartRateZones(
                        zone1Seconds: 200,
                        zone2Seconds: 1500,
                        zone3Seconds: 800,
                        zone4Seconds: 223,
                        zone5Seconds: 0
                    ),
                    splits: nil,
                    routeData: nil,
                    paceConsistency: 12.3,
                    fadeFactor: 3.5,
                    createdAt: Date().addingTimeInterval(-172800), // 2 days ago
                    startedAt: Date().addingTimeInterval(-172800),
                    endedAt: Date().addingTimeInterval(-172800 + 2723),
                    visibility: .friends,
                    notes: nil
                ),
                isPR: false,
                onTap: {}
            )

            // Recovery run today, no HR data
            EnhancedRunCard(
                session: RunningSession(
                    id: UUID(),
                    userId: UUID(),
                    gymId: nil,
                    sessionType: .recovery,
                    workoutId: nil,
                    distanceMeters: 3000,
                    durationSeconds: 1140, // 19:00
                    elevationGainMeters: nil,
                    avgPacePerKm: 380, // 6:20 /km
                    fastestKmPace: nil,
                    slowestKmPace: nil,
                    avgHeartRate: nil,
                    maxHeartRate: nil,
                    heartRateZones: nil,
                    splits: nil,
                    routeData: nil,
                    paceConsistency: nil,
                    fadeFactor: nil,
                    createdAt: Date(),
                    startedAt: Date(),
                    endedAt: Date().addingTimeInterval(1140),
                    visibility: .private,
                    notes: "Easy shakeout run"
                ),
                isPR: false,
                onTap: {}
            )
        }
        .padding(DesignSystem.Spacing.medium)
        .screenBackground()
    }
}
#endif
