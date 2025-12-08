// FLEXR - Training Cycle View
// Shows full training plan with all weeks and phases

import SwiftUI

struct TrainingCycleView: View {
    @StateObject private var planService = PlanService.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    headerSection
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    if planService.allWeeks.isEmpty {
                        emptyStateView
                            .padding(.top, 40)
                    } else {
                        // AI Reasoning Section (Why this plan)
                        if let reasoning = planService.planReasoning {
                            planReasoningSection(reasoning)
                                .padding(.horizontal, 20)
                        }

                        // Phase Timeline
                        phaseTimelineSection
                            .padding(.horizontal, 20)

                        // All Weeks
                        allWeeksSection
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 32)
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.gray, Color.white.opacity(0.1))
                    }
                }
            }
            .onAppear {
                Task {
                    await planService.fetchFullTrainingCycle()
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TRAINING CYCLE")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.gray)

            Text("Your Journey")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.white)

            if let totalWeeks = planService.allWeeks.first?.totalWeeks {
                Text("\(totalWeeks) weeks to race day")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.gray)
            }
        }
    }

    // MARK: - Plan Reasoning Section (Why this plan)

    private func planReasoningSection(_ reasoning: PlanReasoning) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.primary)
                Text("Your Personalized Plan")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }

            // Key Focus Areas
            VStack(alignment: .leading, spacing: 8) {
                Text("KEY FOCUS AREAS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.gray)

                HStack(spacing: 8) {
                    ForEach(reasoning.keyFocusAreas.prefix(3), id: \.self) { area in
                        Text(area)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(DesignSystem.Colors.primary.opacity(0.15))
                            .cornerRadius(8)
                    }
                }
            }

            // AI Notes
            VStack(alignment: .leading, spacing: 6) {
                Text("COACH NOTES")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.gray)

                Text(reasoning.athleteSpecificNotes)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Intensity progression hint
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "FFD60A"))
                Text(reasoning.intensityProgression)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(DesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Phase Timeline

    private var phaseTimelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Training Phases")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)

            // Group weeks by phase
            let phases = Dictionary(grouping: planService.allWeeks) { $0.phase }
            let phaseOrder: [TrainingPhase] = [.base, .build, .peak, .taper, .race, .recovery]

            HStack(spacing: 8) {
                ForEach(phaseOrder, id: \.self) { phase in
                    if let weeksInPhase = phases[phase], !weeksInPhase.isEmpty {
                        PhaseBarView(
                            phase: phase,
                            weekCount: weeksInPhase.count,
                            totalWeeks: planService.allWeeks.count,
                            hasCurrentWeek: weeksInPhase.contains { $0.isCurrentWeek }
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(height: 80)

            // Phase Legend
            HStack(spacing: 16) {
                ForEach(phaseOrder.filter { phases[$0] != nil }, id: \.self) { phase in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(phaseColor(phase))
                            .frame(width: 8, height: 8)
                        Text(phase.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }

    // MARK: - All Weeks

    private var allWeeksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Week by Week")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)

            LazyVStack(spacing: 12) {
                ForEach(planService.allWeeks) { week in
                    TrainingWeekCard(week: week)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 64))
                .foregroundColor(.gray)

            Text("No Training Cycle Yet")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)

            Text("Generate a training plan to see your full journey")
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
    }

    private func phaseColor(_ phase: TrainingPhase) -> Color {
        switch phase {
        case .base: return DesignSystem.Colors.primary
        case .build: return Color(hex: "5AC8FA")
        case .peak: return Color(hex: "FFD60A")
        case .taper: return Color(hex: "FF9F0A")
        case .race: return Color(hex: "FF453A")
        case .recovery: return Color(hex: "BF5AF2")
        }
    }
}

// MARK: - Phase Bar View

struct PhaseBarView: View {
    let phase: TrainingPhase
    let weekCount: Int
    let totalWeeks: Int
    let hasCurrentWeek: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(phaseColor.opacity(0.2))

            RoundedRectangle(cornerRadius: 12)
                .fill(phaseColor)
                .opacity(hasCurrentWeek ? 1.0 : 0.5)

            VStack(spacing: 4) {
                Text(phase.displayName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("\(weekCount)w")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 4)
        }
    }

    private var phaseColor: Color {
        switch phase {
        case .base: return DesignSystem.Colors.primary
        case .build: return Color(hex: "5AC8FA")
        case .peak: return Color(hex: "FFD60A")
        case .taper: return Color(hex: "FF9F0A")
        case .race: return Color(hex: "FF453A")
        case .recovery: return Color(hex: "BF5AF2")
        }
    }
}

// MARK: - Training Week Card

struct TrainingWeekCard: View {
    let week: TrainingWeekSummary
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Main card content
            HStack(spacing: 16) {
                // Week number indicator
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 50, height: 50)

                    if week.isCurrentWeek {
                        Circle()
                            .stroke(DesignSystem.Colors.primary, lineWidth: 3)
                            .frame(width: 50, height: 50)
                    }

                    // Deload indicator overlay
                    if week.isDeload {
                        Circle()
                            .stroke(Color(hex: "BF5AF2").opacity(0.6), lineWidth: 2)
                            .frame(width: 50, height: 50)
                    }

                    Text("\(week.weekNumber)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(statusColor)
                }

                // Week info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Week \(week.weekNumber)")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)

                        if week.isCurrentWeek {
                            Text("NOW")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(DesignSystem.Colors.primary)
                                .cornerRadius(4)
                        }

                        if week.isDeload {
                            Text("DELOAD")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: "BF5AF2"))
                                .cornerRadius(4)
                        }
                    }

                    Text(week.weekRange)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)

                    HStack(spacing: 8) {
                        // Phase badge
                        HStack(spacing: 4) {
                            Circle()
                                .fill(phaseColor)
                                .frame(width: 6, height: 6)
                            Text(week.phase.displayName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(phaseColor)
                        }

                        // Workouts count
                        HStack(spacing: 4) {
                            Image(systemName: "figure.run")
                                .font(.system(size: 10))
                            Text("\(week.totalWorkouts) workouts")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.gray)
                    }
                }

                Spacer()

                // Completion indicator (for past/current weeks)
                if week.isPast || week.isCurrentWeek {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(week.completedWorkouts)/\(week.totalWorkouts)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(statusColor)

                        // Mini progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.15))
                                    .frame(height: 4)

                                RoundedRectangle(cornerRadius: 2)
                                    .fill(statusColor)
                                    .frame(width: geo.size.width * (week.completionPercentage / 100), height: 4)
                            }
                        }
                        .frame(width: 50, height: 4)
                    }
                } else {
                    // Upcoming - show expandable indicator
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                }
            }
            .padding(16)

            // Expanded details for upcoming weeks (intensity guidance)
            if isExpanded && !week.isPast && !week.isCurrentWeek {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .background(Color.white.opacity(0.1))

                    if let intensityGuidance = week.intensityGuidance {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "gauge.medium")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "FFD60A"))
                            Text(intensityGuidance)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(2)
                        }
                        .padding(.horizontal, 16)
                    }

                    if let phaseDescription = week.phaseDescription {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "text.quote")
                                .font(.system(size: 12))
                                .foregroundColor(phaseColor)
                            Text(phaseDescription)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.gray)
                                .lineLimit(2)
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 12)
            }
        }
        .background(cardBackgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(cardBorderColor, lineWidth: 2)
        )
        .onTapGesture {
            if !week.isPast && !week.isCurrentWeek {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }
        }
    }

    private var cardBackgroundColor: Color {
        if week.isCurrentWeek {
            return Color.white.opacity(0.08)
        } else if week.isDeload {
            return Color(hex: "BF5AF2").opacity(0.08)
        }
        return Color.white.opacity(0.05)
    }

    private var cardBorderColor: Color {
        if week.isCurrentWeek {
            return DesignSystem.Colors.primary
        } else if week.isDeload {
            return Color(hex: "BF5AF2").opacity(0.4)
        }
        return Color.clear
    }

    private var statusColor: Color {
        switch week.status {
        case .current: return DesignSystem.Colors.primary
        case .completedGood: return DesignSystem.Colors.success
        case .completedPartial: return Color(hex: "FFD60A")
        case .upcoming: return .gray
        }
    }

    private var phaseColor: Color {
        switch week.phase {
        case .base: return DesignSystem.Colors.primary
        case .build: return Color(hex: "5AC8FA")
        case .peak: return Color(hex: "FFD60A")
        case .taper: return Color(hex: "FF9F0A")
        case .race: return Color(hex: "FF453A")
        case .recovery: return Color(hex: "BF5AF2")
        }
    }
}

#Preview {
    TrainingCycleView()
}
