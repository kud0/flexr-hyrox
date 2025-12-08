// FLEXR - Running Session Detail View
// Comprehensive performance analysis for a single run
// Focus: Splits, pace, heart rate, consistency

import SwiftUI

struct RunningSessionDetailView: View {
    let session: RunningSession

    @StateObject private var supabase = SupabaseService.shared
    @State private var intervalSession: IntervalSession?
    @State private var isLoadingInterval = false

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.medium) {
                // Header section with unified component
                HStack(alignment: .top) {
                    FlexrHeader(
                        title: session.sessionType.displayName,
                        subtitle: (session.startedAt ?? session.createdAt).formatted(date: .long, time: .shortened)
                    )
                    
                    Spacer()
                    
                    Image(systemName: session.sessionType.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(sessionTypeColor)
                        .padding(.top, 4)
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.top, DesignSystem.Spacing.medium)

                // Route map section (if available)
                if let routeData = session.routeData {
                    FlexrCard(padding: 0) {
                        CompletedRouteMapView(routeData: routeData)
                            .frame(height: 250)
                            .clipped()
                    }
                    .padding(.horizontal, DesignSystem.Spacing.medium)
                }

                // Key metrics section
                FlexrCard {
                    VStack(spacing: 24) {
                        // Primary Metric: Distance
                        VStack(spacing: 4) {
                            Text(session.displayDistance)
                                .font(DesignSystem.Typography.heading1)
                                .foregroundColor(DesignSystem.Colors.text.primary)
                            Text("Total Distance")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundColor(DesignSystem.Colors.text.secondary)
                                .textCase(.uppercase)
                                .tracking(1)
                        }
                        
                        Divider().background(DesignSystem.Colors.divider)
                        
                        // Secondary Metrics Grid
                        MetricRow(items: [
                            MetricRow.MetricItemData(
                                value: session.displayDuration,
                                label: "Duration",
                                icon: "timer",
                                color: DesignSystem.Colors.secondary
                            ),
                            MetricRow.MetricItemData(
                                value: session.displayPace,
                                label: "Avg Pace",
                                icon: "speedometer",
                                color: DesignSystem.Colors.accent
                            )
                        ])
                        
                        if session.avgHeartRate != nil || session.elevationGainMeters != nil {
                            Divider().background(DesignSystem.Colors.divider)
                            
                            MetricRow(items: [
                                session.avgHeartRate.map {
                                    MetricRow.MetricItemData(
                                        value: "\($0) bpm",
                                        label: "Avg HR",
                                        icon: "heart.fill",
                                        color: DesignSystem.Colors.error
                                    )
                                },
                                session.elevationGainMeters.map {
                                    MetricRow.MetricItemData(
                                        value: "\($0)m",
                                        label: "Elevation",
                                        icon: "arrow.up.forward",
                                        color: DesignSystem.Colors.warning
                                    )
                                }
                            ].compactMap { $0 })
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)

                // Splits section (if available)
                if let splits = session.splits, !splits.isEmpty {
                    splitsSection(splits: splits)
                        .padding(.horizontal, DesignSystem.Spacing.medium)
                } 

                // Heart rate zones (if available)
                if let zones = session.heartRateZones {
                    heartRateZonesSection(zones: zones)
                        .padding(.horizontal, DesignSystem.Spacing.medium)
                }

                // Performance analysis
                performanceAnalysisSection
                    .padding(.horizontal, DesignSystem.Spacing.medium)

                // Interval details (if interval session)
                if let intervalSession = intervalSession {
                    intervalDetailsSection(interval: intervalSession)
                        .padding(.horizontal, DesignSystem.Spacing.medium)
                }

                // Notes (if available)
                if let notes = session.notes, !notes.isEmpty {
                    notesSection(notes: notes)
                        .padding(.horizontal, DesignSystem.Spacing.medium)
                }
            }
            .padding(.bottom, DesignSystem.Spacing.large)
        }
        .background(DesignSystem.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadIntervalData()
        }
    }

    // MARK: - Splits Section

    private func splitsSection(splits: [Split]) -> some View {
        FlexrCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Splits")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundStyle(DesignSystem.Colors.text.primary)

                VStack(spacing: 0) {
                    // Header row
                    HStack {
                        Text("KM")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundStyle(DesignSystem.Colors.text.secondary)
                            .frame(width: 40, alignment: .leading)

                        Text("Time")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundStyle(DesignSystem.Colors.text.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("Pace")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundStyle(DesignSystem.Colors.text.secondary)
                            .frame(width: 70, alignment: .trailing)

                        if splits.first?.heartRate != nil {
                            Text("HR")
                                .font(DesignSystem.Typography.caption1)
                                .foregroundStyle(DesignSystem.Colors.text.secondary)
                                .frame(width: 50, alignment: .trailing)
                        }
                    }
                    .padding(.bottom, 8)
                    .overlay(Rectangle().frame(height: 1).foregroundColor(DesignSystem.Colors.divider), alignment: .bottom)

                    // Split rows
                    ForEach(splits.indices, id: \.self) { index in
                        let split = splits[index]
                        SplitRow(
                            split: split,
                            avgPace: session.avgPacePerKm,
                            showHeartRate: split.heartRate != nil
                        )
                        .padding(.vertical, 12)
                        
                        if index < splits.count - 1 {
                            Divider().background(DesignSystem.Colors.divider)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Heart Rate Zones Section

    private func heartRateZonesSection(zones: HeartRateZones) -> some View {
        FlexrCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Heart Rate Zones")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundStyle(DesignSystem.Colors.text.primary)

                VStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { zone in
                        HeartRateZoneBar(
                            zone: zone,
                            percent: zones.percentInZone(zone),
                            time: zones.displayTime(forZone: zone),
                            isDominant: zone == zones.dominantZone
                        )
                    }
                }
            }
        }
    }

    // MARK: - Performance Analysis Section

    private var performanceAnalysisSection: some View {
        FlexrCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Performance Analysis")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundStyle(DesignSystem.Colors.text.primary)

                VStack(spacing: 16) {
                    if let consistency = session.displayPaceConsistency {
                        MetricRow(items: [
                            MetricRow.MetricItemData(
                                value: consistency,
                                label: "Pace Consistency",
                                icon: "waveform.path.ecg",
                                color: .white
                            )
                        ])
                    }
                    
                    if let fadeFactor = session.displayFadeFactor {
                        Divider().background(DesignSystem.Colors.divider)
                        MetricRow(items: [
                            MetricRow.MetricItemData(
                                value: fadeFactor,
                                label: "Split Analysis",
                                icon: "chart.line.uptrend.xyaxis",
                                color: .white
                            )
                        ])
                    }
                    
                    if let fastestPace = session.displayFastestPace,
                       let slowestPace = session.displaySlowestPace {
                        Divider().background(DesignSystem.Colors.divider)
                        MetricRow(items: [
                            MetricRow.MetricItemData(
                                value: "\(fastestPace) - \(slowestPace)",
                                label: "Pace Range",
                                icon: "arrow.up.arrow.down",
                                color: .white
                            )
                        ])
                    }
                }
            }
        }
    }

    // MARK: - Interval Details Section

    private func intervalDetailsSection(interval: IntervalSession) -> some View {
        FlexrCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Interval Breakdown")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundStyle(DesignSystem.Colors.text.primary)

                // Structure Summary
                HStack(spacing: 20) {
                     VStack(alignment: .leading, spacing: 4) {
                         Text("SETS")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundStyle(DesignSystem.Colors.text.secondary)
                         Text("\(interval.totalReps)")
                            .font(DesignSystem.Typography.title3)
                            .foregroundStyle(DesignSystem.Colors.text.primary)
                     }
                     
                     VStack(alignment: .leading, spacing: 4) {
                         Text("WORK")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundStyle(DesignSystem.Colors.text.secondary)
                         Text(interval.displayWorkDistance)
                            .font(DesignSystem.Typography.title3)
                            .foregroundStyle(DesignSystem.Colors.text.primary)
                     }
                     
                     VStack(alignment: .leading, spacing: 4) {
                         Text("REST")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundStyle(DesignSystem.Colors.text.secondary)
                         Text(interval.displayRestDuration)
                            .font(DesignSystem.Typography.title3)
                            .foregroundStyle(DesignSystem.Colors.text.primary)
                     }
                }
                .padding(.bottom, 8)

                if let targetPace = interval.displayTargetPace {
                     MetricRow(items: [
                        MetricRow.MetricItemData(
                            value: targetPace,
                            label: "Target Pace",
                            icon: "target",
                            color: .white
                        )
                    ])
                    Divider().background(DesignSystem.Colors.divider)
                }
                
                // Rep-by-rep breakdown
                VStack(spacing: 0) {
                    ForEach(interval.intervals.indices, id: \.self) { index in
                        let rep = interval.intervals[index]
                        IntervalRepRow(
                            rep: rep,
                            targetPace: interval.targetPacePerKm
                        )
                        .padding(.vertical, 12)

                        if index < interval.intervals.count - 1 {
                            Divider().background(DesignSystem.Colors.divider)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Notes Section

    private func notesSection(notes: String) -> some View {
        FlexrCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Notes")
                    .font(DesignSystem.Typography.heading3)
                    .foregroundStyle(DesignSystem.Colors.text.primary)

                Text(notes)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)
                    .lineSpacing(4)
            }
        }
    }

    // MARK: - Helper Properties

    private var sessionTypeColor: Color {
        switch session.sessionType.color {
        case "blue": return DesignSystem.Colors.primary
        case "red": return DesignSystem.Colors.error
        case "orange": return DesignSystem.Colors.warning
        case "purple": return DesignSystem.Colors.accent
        case "green": return DesignSystem.Colors.success
        default: return DesignSystem.Colors.text.secondary
        }
    }

    // MARK: - Actions

    private func loadIntervalData() async {
        guard session.sessionType == .intervals else { return }

        isLoadingInterval = true
        defer { isLoadingInterval = false }

        do {
            intervalSession = try await supabase.getIntervalSession(runningSessionId: session.id)
        } catch {
            print("Failed to load interval session: \(error)")
        }
    }
}

// MARK: - Supporting Components

private struct SplitRow: View {
    let split: Split
    let avgPace: TimeInterval
    let showHeartRate: Bool

    // Check if split data is valid
    private var isValidPace: Bool {
        split.pacePerKm > 0 && split.pacePerKm < 3600
    }

    var body: some View {
        HStack {
            // KM number
            Text("\(split.km)")
                .font(DesignSystem.Typography.bodyEmphasized)
                .foregroundStyle(DesignSystem.Colors.text.primary)
                .frame(width: 40, alignment: .leading)

            // Time
            Text(split.displayTime)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.text.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Pace with indicator (only show comparison if valid)
            HStack(spacing: 6) {
                if isValidPace {
                    if split.pacePerKm < avgPace {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 10))
                            .foregroundStyle(DesignSystem.Colors.success)
                    } else if split.pacePerKm > avgPace {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 10))
                            .foregroundStyle(DesignSystem.Colors.error)
                    }
                }

                Text(split.displayPace)
                    .font(DesignSystem.Typography.bodyEmphasized)
                    .foregroundStyle(
                        !isValidPace
                            ? DesignSystem.Colors.text.tertiary
                            : split.pacePerKm < avgPace
                                ? DesignSystem.Colors.success
                                : split.pacePerKm > avgPace
                                    ? DesignSystem.Colors.error
                                    : DesignSystem.Colors.text.primary
                    )
            }
            .frame(width: 70, alignment: .trailing)

            // Heart rate
            if showHeartRate {
                Group {
                    if let hr = split.heartRate {
                        Text("\(hr)")
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.text.secondary)
                    } else {
                        Text("-")
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(DesignSystem.Colors.text.tertiary)
                    }
                }
                .frame(width: 50, alignment: .trailing)
            }
        }
    }
}

private struct HeartRateZoneBar: View {
    let zone: Int
    let percent: Double
    let time: String
    let isDominant: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Zone \(zone)")
                    .font(DesignSystem.Typography.caption1)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)

                Spacer()

                Text(time)
                    .font(DesignSystem.Typography.caption1)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)

                Text(String(format: "%.0f%%", percent))
                    .font(DesignSystem.Typography.caption1)
                    .foregroundStyle(DesignSystem.Colors.text.primary)
                    .frame(width: 40, alignment: .trailing)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(DesignSystem.Colors.background)
                        .frame(height: isDominant ? 12 : 8)

                    Capsule()
                        .fill(zoneColor)
                        .frame(
                            width: max(geometry.size.width * (percent / 100), 8), // Min width visual
                            height: isDominant ? 12 : 8
                        )
                }
            }
            .frame(height: isDominant ? 12 : 8)
        }
    }

    private var zoneColor: Color {
        switch zone {
        case 1: return DesignSystem.Colors.success.opacity(0.6)
        case 2: return DesignSystem.Colors.success
        case 3: return DesignSystem.Colors.warning
        case 4: return DesignSystem.Colors.error.opacity(0.8)
        case 5: return DesignSystem.Colors.error
        default: return DesignSystem.Colors.text.secondary
        }
    }
}

private struct IntervalRepRow: View {
    let rep: IntervalRep
    let targetPace: TimeInterval?

    var body: some View {
        HStack {
            // Rep number
            Text("#\(rep.rep)")
                .font(DesignSystem.Typography.bodyEmphasized)
                .foregroundStyle(DesignSystem.Colors.text.primary)
                .frame(width: 50, alignment: .leading)

            // Time
            Text(rep.displayTime)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.text.secondary)

            Spacer()

            // Pace
            HStack(spacing: 6) {
                if let target = targetPace {
                    if rep.pacePerKm < target {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(DesignSystem.Colors.success)
                    } else if rep.pacePerKm > target + 5 {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(DesignSystem.Colors.warning)
                    }
                }

                Text(rep.displayPace)
                    .font(DesignSystem.Typography.bodyEmphasized)
                    .foregroundStyle(DesignSystem.Colors.text.primary)
            }

            // Heart rate
            if let hr = rep.avgHeartRate {
                Text("\(hr)")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.text.secondary)
                    .frame(width: 50, alignment: .trailing)
            }
        }
    }
}
