// FLEXR - Quick Workout Sheet
// "Feeling different?" - Let users pick an unscheduled workout
// 2 taps max to start, no guilt, just options

import SwiftUI

// MARK: - Quick Workout Type

enum QuickWorkoutType: String, CaseIterable, Identifiable {
    case run = "Run"
    case strength = "Strength"
    case gymClass = "Functional"
    case stationPractice = "Station Practice"
    case quickHit = "Quick Hit"
    case challenge = "Challenge"
    case recovery = "Recovery"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .run: return "figure.run"
        case .strength: return "dumbbell.fill"
        case .gymClass: return "figure.cross.training"
        case .stationPractice: return "target"
        case .quickHit: return "bolt.fill"
        case .challenge: return "flame.fill"
        case .recovery: return "leaf.fill"
        }
    }

    var emoji: String {
        switch self {
        case .run: return "🏃"
        case .strength: return "🏋️"
        case .gymClass: return "💪"
        case .stationPractice: return "🎯"
        case .quickHit: return "⚡"
        case .challenge: return "🔥"
        case .recovery: return "🧘"
        }
    }

    var subtitle: String {
        switch self {
        case .run: return "Endurance focused"
        case .strength: return "Heavy lifting session"
        case .gymClass: return "Class-style (~1h)"
        case .stationPractice: return "Drill a weakness"
        case .quickHit: return "Fast HYROX circuit"
        case .challenge: return "Full race simulation"
        case .recovery: return "Light movement"
        }
    }

    var description: String {
        switch self {
        case .run: return "Pure running - intervals, tempo, or long steady state"
        case .strength: return "Compound lifts & accessories - barbell focused"
        case .gymClass: return "Strength + WOD with free equipment"
        case .stationPractice: return "Focus on your weakest HYROX station"
        case .quickHit: return "15-20 min HYROX-style circuit"
        case .challenge: return "Full or half HYROX simulation"
        case .recovery: return "Mobility, stretching & easy movement"
        }
    }

    var color: Color {
        switch self {
        case .run: return DesignSystem.Colors.primary
        case .strength: return Color.orange
        case .gymClass: return Color.purple
        case .stationPractice: return Color.cyan
        case .quickHit: return Color.yellow
        case .challenge: return Color.red
        case .recovery: return DesignSystem.Colors.success
        }
    }

    var needsFollowUp: Bool {
        switch self {
        case .run, .strength, .stationPractice:
            return true
        case .gymClass, .quickHit, .challenge, .recovery:
            return false
        }
    }

    var estimatedDuration: String {
        switch self {
        case .run: return "20-60 min"
        case .strength: return "45-60 min"
        case .gymClass: return "~1 hour"
        case .stationPractice: return "20-30 min"
        case .quickHit: return "15-20 min"
        case .challenge: return "60-90 min"
        case .recovery: return "20-30 min"
        }
    }
}

// MARK: - Follow-up Options

enum RunDuration: String, CaseIterable {
    case short = "Short"
    case medium = "Medium"
    case long = "Long"

    var minutes: String {
        switch self {
        case .short: return "20-30 min"
        case .medium: return "40-50 min"
        case .long: return "60+ min"
        }
    }

    var icon: String {
        switch self {
        case .short: return "hare.fill"
        case .medium: return "figure.run"
        case .long: return "figure.run.circle.fill"
        }
    }
}

enum StrengthFocus: String, CaseIterable {
    case upper = "Upper Body"
    case lower = "Lower Body"
    case fullBody = "Full Body"

    var icon: String {
        switch self {
        case .upper: return "figure.arms.open"
        case .lower: return "figure.walk"
        case .fullBody: return "figure.strengthtraining.traditional"
        }
    }
}

// MARK: - Quick Workout Sheet

struct QuickWorkoutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: QuickWorkoutType?
    @State private var showingFollowUp = false

    // Follow-up selections
    @State private var runDuration: RunDuration?
    @State private var strengthFocus: StrengthFocus?
    @State private var selectedStation: HYROXStation?

    let onWorkoutSelected: (QuickWorkoutType, Any?) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !showingFollowUp {
                    mainSelectionView
                } else if let type = selectedType {
                    followUpView(for: type)
                }
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle(showingFollowUp ? selectedType?.rawValue ?? "" : "What do you feel like?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.text.secondary)
                }

                if showingFollowUp {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            withAnimation {
                                showingFollowUp = false
                                selectedType = nil
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(DesignSystem.Colors.primary)
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Main Selection View

    private var mainSelectionView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(QuickWorkoutType.allCases) { type in
                    QuickWorkoutOptionCard(type: type) {
                        handleTypeSelection(type)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Follow-up Views

    @ViewBuilder
    private func followUpView(for type: QuickWorkoutType) -> some View {
        switch type {
        case .run:
            runFollowUpView
        case .strength:
            strengthFollowUpView
        case .stationPractice:
            stationFollowUpView
        default:
            EmptyView()
        }
    }

    private var runFollowUpView: some View {
        VStack(spacing: 24) {
            Text("How long?")
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(DesignSystem.Colors.text.primary)

            VStack(spacing: 12) {
                ForEach(RunDuration.allCases, id: \.self) { duration in
                    Button {
                        runDuration = duration
                        startWorkout()
                    } label: {
                        HStack {
                            Image(systemName: duration.icon)
                                .font(.system(size: 24))
                                .foregroundColor(DesignSystem.Colors.primary)
                                .frame(width: 40)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(duration.rawValue)
                                    .font(DesignSystem.Typography.bodyEmphasized)
                                    .foregroundColor(DesignSystem.Colors.text.primary)

                                Text(duration.minutes)
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.text.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(DesignSystem.Colors.text.tertiary)
                        }
                        .padding()
                        .background(DesignSystem.Colors.surface)
                        .cornerRadius(DesignSystem.Radius.medium)
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 32)
    }

    private var strengthFollowUpView: some View {
        VStack(spacing: 24) {
            Text("What's the focus?")
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(DesignSystem.Colors.text.primary)

            VStack(spacing: 12) {
                ForEach(StrengthFocus.allCases, id: \.self) { focus in
                    Button {
                        strengthFocus = focus
                        startWorkout()
                    } label: {
                        HStack {
                            Image(systemName: focus.icon)
                                .font(.system(size: 24))
                                .foregroundColor(Color.orange)
                                .frame(width: 40)

                            Text(focus.rawValue)
                                .font(DesignSystem.Typography.bodyEmphasized)
                                .foregroundColor(DesignSystem.Colors.text.primary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(DesignSystem.Colors.text.tertiary)
                        }
                        .padding()
                        .background(DesignSystem.Colors.surface)
                        .cornerRadius(DesignSystem.Radius.medium)
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 32)
    }

    private var stationFollowUpView: some View {
        VStack(spacing: 24) {
            Text("Which station?")
                .font(DesignSystem.Typography.heading2)
                .foregroundColor(DesignSystem.Colors.text.primary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(HYROXStation.allCases, id: \.self) { station in
                    Button {
                        selectedStation = station
                        startWorkout()
                    } label: {
                        VStack(spacing: 8) {
                            Text(station.emoji)
                                .font(.system(size: 32))

                            Text(station.displayName)
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.text.primary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(DesignSystem.Colors.surface)
                        .cornerRadius(DesignSystem.Radius.medium)
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 32)
    }

    // MARK: - Actions

    private func handleTypeSelection(_ type: QuickWorkoutType) {
        selectedType = type

        if type.needsFollowUp {
            withAnimation {
                showingFollowUp = true
            }
        } else {
            // No follow-up needed, start immediately
            startWorkout()
        }
    }

    private func startWorkout() {
        guard let type = selectedType else { return }

        let followUpData: Any?
        switch type {
        case .run:
            followUpData = runDuration
        case .strength:
            followUpData = strengthFocus
        case .stationPractice:
            followUpData = selectedStation
        default:
            followUpData = nil
        }

        onWorkoutSelected(type, followUpData)
        dismiss()
    }
}

// MARK: - Quick Workout Option Card

private struct QuickWorkoutOptionCard: View {
    let type: QuickWorkoutType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Emoji
                Text(type.emoji)
                    .font(.system(size: 32))

                // Title
                Text(type.rawValue)
                    .font(DesignSystem.Typography.bodyEmphasized)
                    .foregroundColor(DesignSystem.Colors.text.primary)

                // Description
                Text(type.description)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.text.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                // Duration badge
                Text(type.estimatedDuration)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(type.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(type.color.opacity(0.15))
                    .cornerRadius(DesignSystem.Radius.small)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.Radius.large)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.large)
                    .stroke(type.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    QuickWorkoutSheet { type, data in
        print("Selected: \(type.rawValue), data: \(String(describing: data))")
    }
}
