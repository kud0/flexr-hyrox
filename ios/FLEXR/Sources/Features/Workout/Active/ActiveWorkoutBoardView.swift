// FLEXR - Active Workout Board View
// "The Digital Whiteboard" - Designed for visibility from 2-3 meters
// High contrast, large typography, minimal clutter

import SwiftUI

struct ActiveWorkoutBoardView: View {
    @ObservedObject var viewModel: WorkoutExecutionViewModel
    @EnvironmentObject var healthKitService: HealthKitService
    
    // Auto-scroll logic
    @State private var scrollProxy: ScrollViewProxy?
    
    var body: some View {
        ZStack {
            // solid black background for maximum contrast
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // 1. Global Header (Fixed)
                // Massive Timer & HR
                headerSection
                    .padding(.top, 20)
                    .padding(.bottom, 20)

                Divider()
                    .background(Color.white.opacity(0.3))

                // 2. Main Content
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        // Current Focus (Hero)
                        // Takes up significant portion of screen
                        if let currentSegment = viewModel.currentSegment {
                            CurrentFocusHero(
                                segment: currentSegment,
                                segmentIndex: viewModel.currentSegmentIndex,
                                totalSegments: viewModel.workout.segments.count,
                                elapsedTime: viewModel.segmentElapsedTime,
                                heartRate: healthKitService.currentHeartRate,
                                wodFormat: viewModel.currentSection?.format,
                                wodFormatDetails: viewModel.currentSection?.formatDetails,
                                emomCurrentMinute: viewModel.emomCurrentMinute,
                                emomSecondsRemaining: viewModel.emomSecondsRemaining,
                                amrapCurrentRound: viewModel.amrapCurrentRound,
                                amrapSecondsRemaining: viewModel.amrapSecondsRemaining,
                                tabataIsWorkPhase: viewModel.tabataIsWorkPhase,
                                tabataCurrentRound: viewModel.tabataCurrentRound,
                                tabataPhaseSecondsRemaining: viewModel.tabataPhaseSecondsRemaining,
                                roundsCurrentRound: viewModel.roundsCurrentRound,
                                forTimeSecondsRemaining: viewModel.forTimeSecondsRemaining,
                                wodCue: viewModel.wodCueTrigger,
                                sectionSegments: viewModel.currentSectionSegments,
                                currentMovementIndex: viewModel.currentMovementIndex
                            )
                            .frame(height: geometry.size.height * 0.45) // 45% of remaining space
                        }

                        Divider()
                            .background(Color.white.opacity(0.3))

                        // The Board (List) - Show section movements for AMRAP, otherwise show all segments
                        if isAMRAPOrRoundsFormat {
                            // Show movements in current section
                            amrapMovementsList
                        } else {
                            // Standard segment list
                            ScrollViewReader { proxy in
                                ScrollView {
                                    LazyVStack(spacing: 0) {
                                        ForEach(Array(viewModel.workout.segments.enumerated()), id: \.offset) { index, segment in
                                            BoardRow(
                                                segment: segment,
                                                index: index,
                                                state: rowState(for: index),
                                                isLast: index == viewModel.workout.segments.count - 1
                                            )
                                            .id(index)
                                        }
                                    }
                                    .padding(.bottom, 100) // Space for controls
                                }
                                .onAppear {
                                    scrollProxy = proxy
                                    scrollToCurrent(proxy: proxy)
                                }
                                .onChange(of: viewModel.currentSegmentIndex) { _, _ in
                                    scrollToCurrent(proxy: proxy)
                                }
                            }
                        }
                    }
                }

                // 3. Controls (Fixed Bottom)
                ControlsBar(
                    isPaused: viewModel.isPaused,
                    wodFormat: viewModel.currentSection?.format,
                    onPause: { viewModel.pause() },
                    onResume: { viewModel.resume() },
                    onNext: { viewModel.completeCurrentSegment() },
                    onEnd: { viewModel.endWorkout() }
                )
                .padding(.horizontal)
                .padding(.bottom, 20)
                .padding(.top, 20)
                .background(Color.black)
            }

            // Section Ready Overlay
            if viewModel.isWaitingForSectionReady {
                sectionReadyOverlay
            }
        }
    }
    
    // MARK: - Computed Properties

    private var isAMRAPOrRoundsFormat: Bool {
        guard let format = viewModel.currentSection?.format else { return false }
        return format == .amrap || format == .rounds || format == .forTime
    }

    // MARK: - AMRAP Movements List

    private var amrapMovementsList: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Section header
                HStack {
                    Text("MOVEMENTS IN ROUND")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.success)
                        .tracking(2)
                    Spacer()
                    Text("Round \(viewModel.amrapCurrentRound)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)

                // Movement rows - simple list
                ForEach(Array(viewModel.currentSectionSegments.enumerated()), id: \.offset) { index, segment in
                    AMRAPMovementRow(segment: segment, index: index)
                }
            }
            .padding(.bottom, 100)
        }
    }

    // MARK: - Section Ready Overlay

    private var sectionReadyOverlay: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Completed section info
                if let currentSection = viewModel.currentSection {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(DesignSystem.Colors.success)

                        Text("\(currentSection.label.uppercased()) COMPLETE!")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)

                        if viewModel.currentSection?.format == .amrap {
                            Text("\(viewModel.amrapCurrentRound) rounds completed")
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                        }
                    }
                }

                // Next section preview
                if let nextSection = viewModel.pendingNextSection {
                    VStack(spacing: 16) {
                        Text("UP NEXT")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.gray)
                            .tracking(2)

                        HStack(spacing: 12) {
                            Image(systemName: nextSection.icon)
                                .font(.system(size: 32))
                                .foregroundColor(sectionColor(nextSection.type))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(nextSection.displayTitle)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)

                                if let subtitle = nextSection.displaySubtitle {
                                    Text(subtitle)
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .padding(24)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(16)
                }

                // Ready button
                Button(action: {
                    viewModel.confirmReadyForNextSection()
                }) {
                    HStack(spacing: 12) {
                        Text("I'M READY")
                            .font(.system(size: 24, weight: .black))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 24, weight: .black))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(DesignSystem.Colors.success)
                    .cornerRadius(40)
                }
                .padding(.horizontal, 32)
            }
        }
    }

    private func sectionColor(_ type: SectionType) -> Color {
        switch type {
        case .warmup: return .orange
        case .strength: return .blue
        case .wod: return DesignSystem.Colors.success
        case .finisher: return .red
        case .cooldown: return .cyan
        }
    }

    // MARK: - Components

    private var headerSection: some View {
        HStack(alignment: .center, spacing: 20) {
            // Total Time - MASSIVE
            Text(timeString(from: viewModel.totalElapsedTime))
                .font(.system(size: 72, weight: .black, design: .monospaced)) // Monospaced for stability
                .foregroundColor(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            
            // HR Pill
            if let hr = healthKitService.currentHeartRate {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                    Text("\(Int(hr))")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(hrColor(for: Int(hr)))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods
    
    private func rowState(for index: Int) -> BoardRowState {
        if index < viewModel.currentSegmentIndex {
            return .done
        } else if index == viewModel.currentSegmentIndex {
            return .active
        } else {
            return .upcoming
        }
    }
    
    private func scrollToCurrent(proxy: ScrollViewProxy) {
        withAnimation {
            // Scroll to keep upcoming items visible
            // We want the current item to be at the top of the list if possible, 
            // but since we have a hero view, maybe we want to see the NEXT items in the list.
            // Actually, the list should probably show "Up Next" primarily.
            // Let's scroll to current char but maybe slightly offset?
            proxy.scrollTo(viewModel.currentSegmentIndex, anchor: .top)
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func hrColor(for hr: Int) -> Color {
        // Simplified zones
        switch hr {
        case ..<100: return .gray
        case 100..<130: return DesignSystem.Colors.success // Green
        case 130..<150: return DesignSystem.Colors.secondary // Blue? Or use Zone 2/3 colors
        case 150..<170: return DesignSystem.Colors.warning // Orange
        default: return DesignSystem.Colors.error // Red
        }
    }
}

// MARK: - Subviews

struct CurrentFocusHero: View {
    let segment: WorkoutSegment
    let segmentIndex: Int
    let totalSegments: Int
    let elapsedTime: TimeInterval
    let heartRate: Double?

    // WOD format state (optional)
    var wodFormat: WODFormat?
    var wodFormatDetails: FormatDetails?
    var emomCurrentMinute: Int = 1
    var emomSecondsRemaining: Int = 60
    var amrapCurrentRound: Int = 1
    var amrapSecondsRemaining: Int = 0
    var tabataIsWorkPhase: Bool = true
    var tabataCurrentRound: Int = 1
    var tabataPhaseSecondsRemaining: Int = 20
    var roundsCurrentRound: Int = 1
    var forTimeSecondsRemaining: Int?
    var wodCue: WODCue?

    // AMRAP/Rounds section segments
    var sectionSegments: [WorkoutSegment] = []
    var currentMovementIndex: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header: "Now Active" or WOD format info
            HStack {
                if let format = wodFormat {
                    Text(formatHeaderText(format))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(formatColor(format))
                        .tracking(2)
                } else {
                    Text("CURRENT SECTION  \(segmentIndex + 1)/\(totalSegments)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.primary)
                        .tracking(2)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            Spacer()

            // WOD Format Display or Standard Segment Display
            if let format = wodFormat {
                wodFormatDisplay(format)
            } else {
                standardSegmentDisplay
            }

            Spacer()

            // Progress Bar (Thick)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))

                    Rectangle()
                        .fill(progressBarColor)
                        .frame(width: geo.size.width * progress)
                        .animation(.linear, value: progress)
                }
            }
            .frame(height: 12)
        }
        .background(backgroundColor)
        .overlay(cueOverlay)
    }

    // MARK: - WOD Format Display

    @ViewBuilder
    private func wodFormatDisplay(_ format: WODFormat) -> some View {
        VStack(spacing: 16) {
            switch format {
            case .emom:
                emomDisplay
            case .amrap:
                amrapDisplay
            case .tabata:
                tabataDisplay
            case .forTime:
                forTimeDisplay
            case .rounds:
                roundsDisplay
            }

            // Current movement
            Text(segment.displayName.uppercased())
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
    }

    private var emomDisplay: some View {
        VStack(spacing: 8) {
            // Big countdown
            Text("\(emomSecondsRemaining)")
                .font(.system(size: 96, weight: .black, design: .monospaced))
                .foregroundColor(emomSecondsRemaining <= 10 ? .red : .white)

            Text("seconds remaining")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
        }
    }

    private var amrapDisplay: some View {
        VStack(spacing: 8) {
            // Round counter
            Text("ROUND \(amrapCurrentRound)")
                .font(.system(size: 32, weight: .black))
                .foregroundColor(DesignSystem.Colors.success)

            // Time remaining
            Text(formatTime(amrapSecondsRemaining))
                .font(.system(size: 56, weight: .bold, design: .monospaced))
                .foregroundColor(amrapSecondsRemaining <= 60 ? .orange : .white)

            Text("remaining")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
        }
    }

    private var tabataDisplay: some View {
        VStack(spacing: 8) {
            // Phase indicator
            Text(tabataIsWorkPhase ? "WORK" : "REST")
                .font(.system(size: 36, weight: .black))
                .foregroundColor(tabataIsWorkPhase ? .green : .blue)
                .padding(.horizontal, 32)
                .padding(.vertical, 8)
                .background(tabataIsWorkPhase ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                .cornerRadius(12)

            // Phase countdown
            Text("\(tabataPhaseSecondsRemaining)")
                .font(.system(size: 96, weight: .black, design: .monospaced))
                .foregroundColor(tabataPhaseSecondsRemaining <= 3 ? .red : .white)

            // Round info
            Text("Round \(tabataCurrentRound) of \(wodFormatDetails?.rounds ?? 8)")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.gray)
        }
    }

    private var forTimeDisplay: some View {
        VStack(spacing: 8) {
            // Elapsed time (counting up)
            Text(formatTime(Int(elapsedTime)))
                .font(.system(size: 64, weight: .black, design: .monospaced))
                .foregroundColor(.white)

            if let remaining = forTimeSecondsRemaining {
                HStack {
                    Text("Cap:")
                        .foregroundColor(.gray)
                    Text(formatTime(remaining))
                        .foregroundColor(remaining <= 60 ? .orange : .white.opacity(0.7))
                }
                .font(.system(size: 20, weight: .medium))
            }

            Text("Round \(roundsCurrentRound)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(DesignSystem.Colors.primary)
        }
    }

    private var roundsDisplay: some View {
        VStack(spacing: 12) {
            Text("ROUND")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.gray)

            Text("\(roundsCurrentRound)")
                .font(.system(size: 96, weight: .black))
                .foregroundColor(.white)

            if let totalRounds = wodFormatDetails?.rounds {
                Text("of \(totalRounds)")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
    }

    // MARK: - Standard Segment Display

    private var standardSegmentDisplay: some View {
        VStack(spacing: 16) {
            // Exercise name - big and clear
            Text(segmentTitle)
                .font(.system(size: 44, weight: .heavy))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 16)

            // Sets x Reps (for strength) or target
            if let sets = segment.sets, let repsPerSet = segment.repsPerSet {
                // Strength format: 4 x 5
                HStack(spacing: 8) {
                    Text("\(sets)")
                        .font(.system(size: 64, weight: .black, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.primary)
                    Text("×")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.gray)
                    Text("\(repsPerSet)")
                        .font(.system(size: 64, weight: .black, design: .rounded))
                        .foregroundColor(DesignSystem.Colors.primary)
                }

                // Weight suggestion if available
                if let weight = segment.weightSuggestion, !weight.isEmpty {
                    Text(weight)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.orange)
                }
            } else {
                // Standard target (distance, duration, reps)
                Text(segmentTarget)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.gray)
            }

            // Segment type icon
            Image(systemName: segmentIcon)
                .font(.system(size: 32))
                .foregroundColor(segmentColor.opacity(0.7))
        }
    }

    // MARK: - Cue Overlay

    @ViewBuilder
    private var cueOverlay: some View {
        if let cue = wodCue {
            ZStack {
                Color.black.opacity(0.7)
                Text(cue.displayText)
                    .font(.system(size: 72, weight: .black))
                    .foregroundColor(cueColor(cue))
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: wodCue)
        }
    }

    // MARK: - Helpers

    private func formatHeaderText(_ format: WODFormat) -> String {
        switch format {
        case .emom:
            if let total = wodFormatDetails?.totalMinutes {
                return "EMOM \(total) MIN  •  MINUTE \(emomCurrentMinute)"
            }
            return "EMOM"
        case .amrap:
            if let cap = wodFormatDetails?.timeCapMinutes {
                return "AMRAP \(cap) MIN"
            }
            return "AMRAP"
        case .tabata:
            return "TABATA  •  ROUND \(tabataCurrentRound)"
        case .forTime:
            return "FOR TIME  •  ROUND \(roundsCurrentRound)"
        case .rounds:
            if let total = wodFormatDetails?.rounds {
                return "\(total) ROUNDS  •  ROUND \(roundsCurrentRound)"
            }
            return "ROUNDS"
        }
    }

    private func formatColor(_ format: WODFormat) -> Color {
        switch format {
        case .emom: return .orange
        case .amrap: return DesignSystem.Colors.success
        case .tabata: return tabataIsWorkPhase ? .green : .blue
        case .forTime: return .purple
        case .rounds: return DesignSystem.Colors.primary
        }
    }

    private func cueColor(_ cue: WODCue) -> Color {
        switch cue.color {
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        case "yellow": return .yellow
        case "red": return .red
        default: return .white
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private var backgroundColor: Color {
        if let format = wodFormat {
            switch format {
            case .tabata:
                return tabataIsWorkPhase ? Color.green.opacity(0.1) : Color.blue.opacity(0.1)
            default:
                return Color.white.opacity(0.05)
            }
        }
        return Color.white.opacity(0.05)
    }

    private var progressBarColor: Color {
        if let format = wodFormat {
            switch format {
            case .tabata:
                return tabataIsWorkPhase ? .green : .blue
            default:
                return segmentColor
            }
        }
        return segmentColor
    }
    
    private var progress: Double {
        if let targetDist = segment.targetDistance, targetDist > 0 {
            // We don't have simulated distance progress in this view model easily accessible per segment 
            // without diving deeper. For now, assuming time-based progress or indefinite.
            // Use time if targetDuration exists
            if let targetDur = segment.targetDuration, targetDur > 0 {
                return min(elapsedTime / targetDur, 1.0)
            }
            return 0 // TODO: Distance progress
        } else if let targetDur = segment.targetDuration, targetDur > 0 {
            return min(elapsedTime / targetDur, 1.0)
        }
        return 0
    }
    
    private var segmentIcon: String {
        segment.stationType?.icon ?? segment.segmentType.icon
    }
    
    private var segmentTitle: String {
        segment.displayName.uppercased()
    }
    
    private var segmentTarget: String {
        if let dist = segment.targetDistance {
            return "\(Int(dist))m"
        } else if let dur = segment.targetDuration {
            return "\(Int(dur/60)) min"
        } else if let reps = segment.targetReps {
            return "\(reps) reps"
        }
        return "--"
    }
    
    private var segmentColor: Color {
        // Apple Fitness+ Greens styling or Brand Colors
        switch segment.segmentType {
        case .run: return Color(red: 0.67, green: 1.0, blue: 0.0) // Fitness Green
        case .station: return DesignSystem.Colors.primary // Electric Blue
        case .rest: return .orange
        default: return .white
        }
    }
}

enum BoardRowState {
    case done, active, upcoming
}

struct BoardRow: View {
    let segment: WorkoutSegment
    let index: Int
    let state: BoardRowState
    let isLast: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Status Indicator
            ZStack {
                if state == .done {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 24))
                } else if state == .active {
                    Circle()
                        .fill(DesignSystem.Colors.primary)
                        .frame(width: 12, height: 12)
                        .shadow(color: DesignSystem.Colors.primary, radius: 4)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .frame(width: 32)
            
            // Content
            Text("\(index + 1). \(segment.displayName.uppercased())")
                .font(.system(size: 24, weight: .bold)) // Large for readability
                .foregroundColor(textColor)
                .strikethrough(state == .done)
            
            Spacer()
            
            // Target
            Text(targetString)
                .font(.system(size: 20, weight: state == .active ? .bold : .regular, design: .monospaced))
                .foregroundColor(textColor)
                .strikethrough(state == .done)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .background(backgroundColor)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.white.opacity(0.1)),
            alignment: .bottom
        )
    }
    
    private var textColor: Color {
        switch state {
        case .done: return .gray
        case .active: return .white
        case .upcoming: return .white.opacity(0.5)
        }
    }
    
    private var backgroundColor: Color {
        state == .active ? Color.white.opacity(0.1) : Color.clear
    }
    
    private var targetString: String {
        if let dist = segment.targetDistance {
            return "\(Int(dist))m"
        } else if let dur = segment.targetDuration {
            return String(format: "%d:%02d", Int(dur)/60, Int(dur)%60)
        } else if let reps = segment.targetReps {
            return "\(reps)"
        }
        return ""
    }
}

struct ControlsBar: View {
    let isPaused: Bool
    var wodFormat: WODFormat? = nil
    let onPause: () -> Void
    let onResume: () -> Void
    let onNext: () -> Void
    let onEnd: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            // Pause/Resume Button
            Button(action: isPaused ? onResume : onPause) {
                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.black)
                    .frame(width: 80, height: 80)
                    .background(isPaused ? DesignSystem.Colors.success : .yellow)
                    .clipShape(Circle())
            }

            // End Workout Button (Small, Red)
            Button(action: onEnd) {
                VStack(spacing: 4) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 24))
                    Text("END")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(width: 60, height: 80)
                .background(Color.red.opacity(0.8))
                .cornerRadius(16)
            }

            // Next Button (Giant) - Label changes based on format
            Button(action: onNext) {
                HStack(spacing: 12) {
                    Text(nextButtonLabel)
                        .font(.system(size: 24, weight: .black))
                    Image(systemName: nextButtonIcon)
                        .font(.system(size: 24, weight: .black))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(nextButtonColor)
                .cornerRadius(40)
            }
        }
    }

    private var nextButtonLabel: String {
        guard let format = wodFormat else { return "NEXT" }
        switch format {
        case .amrap, .rounds, .forTime:
            return "ROUND +"
        case .emom, .tabata:
            return "SKIP"
        }
    }

    private var nextButtonIcon: String {
        guard let format = wodFormat else { return "arrow.right" }
        switch format {
        case .amrap, .rounds, .forTime:
            return "checkmark"
        case .emom, .tabata:
            return "forward.fill"
        }
    }

    private var nextButtonColor: Color {
        guard let format = wodFormat else { return .white }
        switch format {
        case .amrap, .rounds, .forTime:
            return DesignSystem.Colors.success
        case .emom, .tabata:
            return .orange
        }
    }
}

// MARK: - AMRAP Movement Row

struct AMRAPMovementRow: View {
    let segment: WorkoutSegment
    let index: Int

    var body: some View {
        HStack(spacing: 16) {
            // Movement number
            Text("\(index + 1)")
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.2))
                .cornerRadius(18)

            // Movement name and target
            VStack(alignment: .leading, spacing: 4) {
                Text(segment.displayName.uppercased())
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)

                if let reps = segment.targetReps {
                    Text("\(reps) reps")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                } else if let dist = segment.targetDistance {
                    Text("\(Int(dist))m")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
            }

            Spacer()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 24)
    }
}
