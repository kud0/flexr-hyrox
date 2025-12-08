// FLEXR - Workout Execution View Model
// Manages active workout state and timing

import Foundation
import SwiftUI
import Combine

@MainActor
class WorkoutExecutionViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var workout: Workout
    @Published var currentSegmentIndex: Int = 0
    @Published var totalElapsedTime: TimeInterval = 0
    @Published var segmentElapsedTime: TimeInterval = 0
    @Published var isPaused: Bool = false
    @Published var isTransitioning: Bool = false
    @Published var isWorkoutComplete: Bool = false

    @Published var completedSegment: WorkoutSegment?
    @Published var nextSegment: WorkoutSegment?

    // MARK: - WOD Format State

    /// Current section being executed (with format info)
    @Published var currentSection: WorkoutSection?

    /// For EMOM: current minute (1-based)
    @Published var emomCurrentMinute: Int = 1

    /// For EMOM: seconds remaining in current minute
    @Published var emomSecondsRemaining: Int = 60

    /// For AMRAP: current round (1-based)
    @Published var amrapCurrentRound: Int = 1

    /// For AMRAP: seconds remaining until time cap
    @Published var amrapSecondsRemaining: Int = 0

    /// For Tabata: is currently in work phase (vs rest)
    @Published var tabataIsWorkPhase: Bool = true

    /// For Tabata: current round (1-based)
    @Published var tabataCurrentRound: Int = 1

    /// For Tabata: seconds remaining in current phase
    @Published var tabataPhaseSecondsRemaining: Int = 20

    /// For Rounds/ForTime: current round (1-based)
    @Published var roundsCurrentRound: Int = 1

    /// For ForTime: seconds remaining until time cap (nil = no cap)
    @Published var forTimeSecondsRemaining: Int?

    /// Trigger for haptic/audio cues
    @Published var wodCueTrigger: WODCue?

    /// Whether waiting for user to confirm ready for next section
    @Published var isWaitingForSectionReady: Bool = false

    /// The next section pending (when waiting for ready confirmation)
    @Published var pendingNextSection: WorkoutSection?

    /// All segments in current WOD section (for AMRAP display)
    @Published var currentSectionSegments: [WorkoutSegment] = []

    /// Current movement index within AMRAP/Rounds (cycles through movements)
    @Published var currentMovementIndex: Int = 0

    // MARK: - Private Properties

    private var workoutTimer: Timer?
    private var segmentTimer: Timer?
    private var segmentStartTime: Date?
    private var totalPausedTime: TimeInterval = 0
    private var pauseStartTime: Date?

    /// For WOD formats: when the current section started
    private var sectionStartTime: Date?

    /// Track last EMOM minute to detect transitions
    private var lastEmomMinute: Int = 0

    /// Track last Tabata phase to detect transitions
    private var lastTabataIsWorkPhase: Bool = true

    /// Track last second for cue debouncing (prevents multiple triggers)
    private var lastCueSecond: Int = -1

    /// Track last triggered cue to prevent duplicates
    private var lastTriggeredCue: WODCue?

    private(set) var completedSegmentIndices: Set<Int> = []

    // GPS tracking
    private var locationService: LocationTrackingService?
    private var isTrackingGPS = false

    // MARK: - Computed Properties

    var currentSegment: WorkoutSegment? {
        guard currentSegmentIndex < workout.segments.count else { return nil }
        return workout.segments[currentSegmentIndex]
    }

    var progress: Double {
        guard !workout.segments.isEmpty else { return 0 }
        return Double(completedSegmentIndices.count) / Double(workout.segments.count)
    }

    // MARK: - Main Segment Completion (excludes warmup/cooldown)

    /// Main segments are everything except warmup, cooldown, rest, and transition
    var mainSegments: [WorkoutSegment] {
        workout.segments.filter { segment in
            segment.segmentType != .warmup &&
            segment.segmentType != .cooldown &&
            segment.segmentType != .rest &&
            segment.segmentType != .transition
        }
    }

    /// Indices of main segments in the full workout
    var mainSegmentIndices: Set<Int> {
        Set(workout.segments.enumerated().compactMap { index, segment in
            (segment.segmentType != .warmup &&
             segment.segmentType != .cooldown &&
             segment.segmentType != .rest &&
             segment.segmentType != .transition) ? index : nil
        })
    }

    /// How many main segments have been completed
    var completedMainSegments: Int {
        completedSegmentIndices.intersection(mainSegmentIndices).count
    }

    /// Total main segments in workout
    var totalMainSegments: Int {
        mainSegments.count
    }

    /// Progress based only on main segments (for display)
    var mainProgress: Double {
        guard totalMainSegments > 0 else { return 0 }
        return Double(completedMainSegments) / Double(totalMainSegments)
    }

    /// Completion percentage (0-100) for main segments
    var mainCompletionPercentage: Double {
        mainProgress * 100
    }

    /// Whether workout is considered "completed" (>75% main segments + >5 min)
    var isWorkoutConsideredComplete: Bool {
        let hasEnoughSegments = mainCompletionPercentage >= 75
        let hasMinimumDuration = totalElapsedTime >= 300 // 5 minutes
        return hasEnoughSegments && hasMinimumDuration
    }

    /// Whether user skipped warmup
    var skippedWarmup: Bool {
        let warmupIndices = workout.segments.enumerated().compactMap { index, segment in
            segment.segmentType == .warmup ? index : nil
        }
        return !warmupIndices.isEmpty && warmupIndices.allSatisfy { !completedSegmentIndices.contains($0) }
    }

    /// Whether user skipped cooldown
    var skippedCooldown: Bool {
        let cooldownIndices = workout.segments.enumerated().compactMap { index, segment in
            segment.segmentType == .cooldown ? index : nil
        }
        return !cooldownIndices.isEmpty && cooldownIndices.allSatisfy { !completedSegmentIndices.contains($0) }
    }

    var isWatchAvailable: Bool {
        WatchConnectivityService.shared.isReachable &&
        WatchConnectivityService.shared.isWatchAppInstalled
    }

    // MARK: - Initialization

    init(workout: Workout) {
        var mutableWorkout = workout
        mutableWorkout.start()
        self.workout = mutableWorkout
    }

    // MARK: - Workout Control

    func start() {
        segmentStartTime = Date()

        // Detect and initialize section if this segment belongs to a WOD format
        detectAndInitializeSection(for: currentSegmentIndex)

        // Start timers
        startTimers()

        // Start GPS tracking if needed
        startGPSIfNeeded()

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Detect if current segment belongs to a section with WOD format and initialize it
    private func detectAndInitializeSection(for segmentIndex: Int) {
        guard segmentIndex < workout.segments.count else { return }

        // Check if workout has sections
        if let sections = workout.sections {
            // Find which section this segment belongs to
            var segmentCounter = 0
            for section in sections {
                let sectionEndIndex = segmentCounter + section.segments.count
                if segmentIndex >= segmentCounter && segmentIndex < sectionEndIndex {
                    // Found the section
                    if section.format != nil {
                        initializeWODFormat(for: section)
                    } else {
                        currentSection = section
                        sectionStartTime = nil // No WOD timing
                    }
                    return
                }
                segmentCounter = sectionEndIndex
            }
        }

        // Fallback: try to detect section from segment metadata
        let segment = workout.segments[segmentIndex]
        if let sectionType = segment.sectionType,
           let sectionLabel = segment.sectionLabel {
            // Build a section from segment metadata
            let format = segment.sectionFormat.flatMap { WODFormat(rawValue: $0) }

            // Try to find format details from sectionsMetadata
            var formatDetails: FormatDetails? = nil
            if let metadata = workout.sectionsMetadata,
               let meta = metadata.first(where: { $0.type.rawValue == sectionType }) {
                formatDetails = meta.formatDetails
            }

            let sectionTypeEnum = SectionType(rawValue: sectionType) ?? .wod
            let section = WorkoutSection(
                type: sectionTypeEnum,
                label: sectionLabel,
                format: format,
                formatDetails: formatDetails,
                segments: [segment]
            )

            if format != nil {
                initializeWODFormat(for: section)
            } else {
                currentSection = section
                sectionStartTime = nil
            }
        } else {
            // No section info - clear current section
            currentSection = nil
            sectionStartTime = nil
        }
    }

    func pause() {
        isPaused = true
        pauseStartTime = Date()
        stopTimers()

        // Pause GPS if tracking
        if isTrackingGPS {
            locationService?.pauseTracking()
        }

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    func resume() {
        // Calculate paused time
        if let pauseStart = pauseStartTime {
            totalPausedTime += Date().timeIntervalSince(pauseStart)
        }

        isPaused = false
        pauseStartTime = nil
        startTimers()

        // Resume GPS if tracking
        if isTrackingGPS {
            locationService?.resumeTracking()
        }

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    func togglePause() {
        if isPaused {
            resume()
        } else {
            pause()
        }
    }

    func completeCurrentSegment() {
        guard currentSegmentIndex < workout.segments.count else { return }

        // For AMRAP/Rounds formats - "Next" means "Complete Round", not advance segment
        if let format = currentSection?.format {
            switch format {
            case .amrap:
                // In AMRAP, "Next" = complete a round (timer keeps running)
                incrementAMRAPRound()
                return
            case .rounds, .forTime:
                // In Rounds/ForTime, "Next" = complete a round
                incrementRound()
                return
            case .emom, .tabata:
                // EMOM and Tabata auto-advance - manual next skips to next section
                showSectionReadyPrompt()
                return
            }
        }

        // Standard segment completion (non-WOD formats)
        standardSegmentComplete()
    }

    /// Standard segment completion logic (for non-WOD or warmup/cooldown)
    private func standardSegmentComplete() {
        guard currentSegmentIndex < workout.segments.count else { return }

        // Stop GPS if tracking for this segment
        stopGPSIfNeeded()

        // Record segment completion
        var segment = workout.segments[currentSegmentIndex]
        segment.actualDuration = segmentElapsedTime
        segment.endTime = Date()
        workout.segments[currentSegmentIndex] = segment

        // Mark as completed
        completedSegmentIndices.insert(currentSegmentIndex)
        completedSegment = segment

        // Success haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Check if workout is complete
        if currentSegmentIndex >= workout.segments.count - 1 {
            completeWorkout()
        } else {
            // Check if next segment is in a different section
            let currentSectionType = currentSection?.type
            let nextIndex = currentSegmentIndex + 1

            if nextIndex < workout.segments.count {
                let nextSegment = workout.segments[nextIndex]
                let nextSectionType = nextSegment.sectionType.flatMap { SectionType(rawValue: $0) }

                // If section is changing, show ready prompt
                if currentSectionType != nil && nextSectionType != nil && currentSectionType != nextSectionType {
                    // Find the next section
                    if let sections = workout.sections,
                       let nextSection = sections.first(where: { $0.type == nextSectionType }) {
                        pendingNextSection = nextSection
                        isWaitingForSectionReady = true
                        stopTimers()

                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        return
                    }
                }
            }

            // Same section - continue normally
            continueToNextSegment()
        }
    }

    func continueToNextSegment() {
        let previousSection = currentSection

        currentSegmentIndex += 1
        segmentElapsedTime = 0
        segmentStartTime = Date()
        isTransitioning = false

        // Mark next segment start
        if currentSegmentIndex < workout.segments.count {
            workout.segments[currentSegmentIndex].startTime = Date()
        }

        // Detect if we're entering a new section
        detectAndInitializeSection(for: currentSegmentIndex)

        // Check if section changed (for potential transition screen in future)
        let sectionChanged = previousSection?.type != currentSection?.type

        startTimers()

        // Start GPS tracking if needed for new segment
        startGPSIfNeeded()

        // Haptic feedback - stronger if section changed
        if sectionChanged {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } else {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        }
    }

    func skipCurrentSegment() {
        // Mark as skipped (not completed)
        if currentSegmentIndex >= workout.segments.count - 1 {
            completeWorkout()
        } else {
            nextSegment = workout.segments[currentSegmentIndex + 1]
            currentSegmentIndex += 1
            segmentElapsedTime = 0
            segmentStartTime = Date()
        }
    }

    func endWorkout() {
        stopTimers()

        // Stop GPS if still tracking
        stopGPSIfNeeded()

        workout.complete()
        isWorkoutComplete = true
    }

    // MARK: - Private Methods

    private func startTimers() {
        // ALWAYS stop existing timers first to prevent duplicates
        stopTimers()

        // Total elapsed timer - runs every second
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTotalTime()
            }
        }

        // Segment elapsed timer - also 1 second (no need for 0.1s updates)
        segmentTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateSegmentTime()
            }
        }
    }

    private func stopTimers() {
        workoutTimer?.invalidate()
        workoutTimer = nil
        segmentTimer?.invalidate()
        segmentTimer = nil
    }

    private func updateTotalTime() {
        guard !isPaused else { return }
        totalElapsedTime += 1
    }

    private func updateSegmentTime() {
        guard !isPaused, let startTime = segmentStartTime else { return }

        let elapsed = Date().timeIntervalSince(startTime)
        segmentElapsedTime = elapsed

        // Update WOD format state if active
        if currentSection?.format != nil {
            updateWODFormatState()
        }

        // Check if segment has target duration and auto-alert (for non-WOD segments)
        if currentSection?.format == nil,
           let target = currentSegment?.targetDuration,
           elapsed >= target {
            // Could trigger alert or haptic
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }

    private func completeWorkout() {
        stopTimers()

        // Stop GPS if still tracking
        stopGPSIfNeeded()

        workout.complete()
        workout.totalDuration = totalElapsedTime
        isWorkoutComplete = true

        // Success haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    // MARK: - WOD Format Timing

    /// Update WOD format state based on elapsed time
    private func updateWODFormatState() {
        guard let section = currentSection,
              let format = section.format,
              let details = section.formatDetails,
              let sectionStart = sectionStartTime else {
            return
        }

        let sectionElapsed = Date().timeIntervalSince(sectionStart)
        let currentSecond = Int(sectionElapsed)

        // Only update state once per second to prevent multiple triggers
        guard currentSecond != lastCueSecond else { return }
        lastCueSecond = currentSecond

        switch format {
        case .emom:
            updateEMOMState(elapsed: sectionElapsed, details: details)
        case .amrap:
            updateAMRAPState(elapsed: sectionElapsed, details: details)
        case .tabata:
            updateTabataState(elapsed: sectionElapsed, details: details)
        case .forTime:
            updateForTimeState(elapsed: sectionElapsed, details: details)
        case .rounds:
            // Rounds don't have automatic timing - user advances manually
            break
        }
    }

    private func updateEMOMState(elapsed: TimeInterval, details: FormatDetails) {
        guard let totalMinutes = details.totalMinutes else { return }

        let totalSeconds = totalMinutes * 60
        let secondsIntoSection = Int(elapsed)

        // Check if EMOM is complete
        if secondsIntoSection >= totalSeconds {
            // EMOM complete - auto-advance section
            triggerCue(.sectionComplete)
            completeCurrentSection()
            return
        }

        // Calculate current minute (1-based) and seconds remaining
        let currentMinute = (secondsIntoSection / 60) + 1
        let secondsIntoMinute = secondsIntoSection % 60
        let secondsRemaining = 60 - secondsIntoMinute

        emomCurrentMinute = currentMinute
        emomSecondsRemaining = secondsRemaining

        // Detect minute transitions for cues
        if currentMinute != lastEmomMinute {
            lastEmomMinute = currentMinute

            // New minute started - GO cue
            if secondsIntoMinute == 0 {
                triggerCue(.emomGo)
            }
        }

        // Warning cues
        if secondsRemaining == 10 {
            triggerCue(.emomWarning10)
        } else if secondsRemaining == 3 {
            triggerCue(.countdown3)
        }
    }

    private func updateAMRAPState(elapsed: TimeInterval, details: FormatDetails) {
        guard let timeCapMinutes = details.timeCapMinutes else { return }

        let totalSeconds = timeCapMinutes * 60
        let secondsRemaining = max(0, totalSeconds - Int(elapsed))

        amrapSecondsRemaining = secondsRemaining

        // Check if AMRAP time is up
        if secondsRemaining <= 0 {
            triggerCue(.sectionComplete)
            // Don't auto-complete - show ready prompt for next section
            showSectionReadyPrompt()
            return
        }

        // Warning cues (only trigger once per threshold)
        if secondsRemaining == 60 {
            triggerCue(.amrapOneMinuteLeft)
        } else if secondsRemaining == 30 {
            triggerCue(.amrap30SecondsLeft)
        } else if secondsRemaining == 10 {
            triggerCue(.countdown10)
        } else if secondsRemaining == 3 {
            triggerCue(.countdown3)
        }
    }

    private func updateTabataState(elapsed: TimeInterval, details: FormatDetails) {
        let workSeconds = details.workSeconds ?? 20
        let restSeconds = details.restSeconds ?? 10
        let totalRounds = details.rounds ?? 8

        let cycleDuration = workSeconds + restSeconds
        let totalDuration = cycleDuration * totalRounds

        let secondsIntoSection = Int(elapsed)

        // Check if Tabata is complete
        if secondsIntoSection >= totalDuration {
            triggerCue(.sectionComplete)
            completeCurrentSection()
            return
        }

        // Calculate current position
        let currentCycle = secondsIntoSection / cycleDuration
        let secondsIntoCycle = secondsIntoSection % cycleDuration

        let isWorkPhase = secondsIntoCycle < workSeconds
        let currentRound = currentCycle + 1

        let phaseSecondsRemaining: Int
        if isWorkPhase {
            phaseSecondsRemaining = workSeconds - secondsIntoCycle
        } else {
            phaseSecondsRemaining = restSeconds - (secondsIntoCycle - workSeconds)
        }

        tabataIsWorkPhase = isWorkPhase
        tabataCurrentRound = min(currentRound, totalRounds)
        tabataPhaseSecondsRemaining = phaseSecondsRemaining

        // Detect phase transitions
        if isWorkPhase != lastTabataIsWorkPhase {
            lastTabataIsWorkPhase = isWorkPhase
            if isWorkPhase {
                triggerCue(.tabataWork)
            } else {
                triggerCue(.tabataRest)
            }
        }

        // Countdown cues
        if phaseSecondsRemaining == 3 {
            triggerCue(.countdown3)
        }
    }

    private func updateForTimeState(elapsed: TimeInterval, details: FormatDetails) {
        guard let timeCapMinutes = details.timeCapMinutes else {
            // No time cap - just count up
            forTimeSecondsRemaining = nil
            return
        }

        let totalSeconds = timeCapMinutes * 60
        let secondsRemaining = max(0, totalSeconds - Int(elapsed))

        forTimeSecondsRemaining = secondsRemaining

        // Check if time cap reached
        if secondsRemaining <= 0 {
            triggerCue(.forTimeCapReached)
            completeCurrentSection()
            return
        }

        // Warning cues
        if secondsRemaining == 60 {
            triggerCue(.amrapOneMinuteLeft) // Reuse cue
        } else if secondsRemaining == 30 {
            triggerCue(.amrap30SecondsLeft)
        }
    }

    private func triggerCue(_ cue: WODCue) {
        wodCueTrigger = cue

        // Haptic feedback based on cue type
        switch cue {
        case .emomGo, .tabataWork, .sectionComplete:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .tabataRest:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        case .countdown3, .countdown10:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        case .emomWarning10, .amrapOneMinuteLeft, .amrap30SecondsLeft, .forTimeCapReached:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }

        // Clear trigger after a moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.wodCueTrigger = nil
        }
    }

    /// Complete current WOD section and advance to next section
    private func completeCurrentSection() {
        // Mark all segments in this section as complete
        for (index, segment) in workout.segments.enumerated() {
            if segment.sectionType == currentSection?.type.rawValue {
                completedSegmentIndices.insert(index)
            }
        }

        // Find next section and show ready prompt
        showSectionReadyPrompt()
    }

    /// Show "Are you ready?" prompt before advancing to next section
    private func showSectionReadyPrompt() {
        // Stop timers while waiting
        stopTimers()

        // Find the next section
        if let sections = workout.sections,
           let currentSectionType = currentSection?.type,
           let currentIndex = sections.firstIndex(where: { $0.type == currentSectionType }),
           currentIndex + 1 < sections.count {
            pendingNextSection = sections[currentIndex + 1]
        }

        isWaitingForSectionReady = true

        // Strong haptic to get attention
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// User confirmed ready - advance to next section
    func confirmReadyForNextSection() {
        isWaitingForSectionReady = false

        guard let nextSection = pendingNextSection else {
            // No more sections - complete workout
            completeWorkout()
            return
        }

        pendingNextSection = nil

        // Find first segment of next section
        if let sections = workout.sections {
            var segmentCounter = 0
            for section in sections {
                if section.type == nextSection.type {
                    // Found it - advance to this segment index
                    currentSegmentIndex = segmentCounter
                    segmentElapsedTime = 0
                    segmentStartTime = Date()

                    // Initialize the new section
                    detectAndInitializeSection(for: currentSegmentIndex)

                    // Restart timers
                    startTimers()

                    // Haptic
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    return
                }
                segmentCounter += section.segments.count
            }
        }

        // Fallback: just continue to next segment
        continueToNextSegment()
    }

    /// Increment AMRAP round count (called when user taps "Complete Round")
    func incrementAMRAPRound() {
        amrapCurrentRound += 1
        currentMovementIndex = 0 // Reset to first movement

        // Haptic for round completion
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Cycle to next movement in AMRAP (without incrementing round)
    func nextMovementInAMRAP() {
        guard !currentSectionSegments.isEmpty else { return }

        currentMovementIndex = (currentMovementIndex + 1) % currentSectionSegments.count

        // Light haptic
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Increment Rounds count (for Rounds format)
    func incrementRound() {
        roundsCurrentRound += 1
        currentMovementIndex = 0 // Reset to first movement

        // Check if all rounds complete
        if let details = currentSection?.formatDetails,
           let totalRounds = details.rounds,
           roundsCurrentRound > totalRounds {
            triggerCue(.sectionComplete)
            showSectionReadyPrompt()
        } else {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }

    /// Initialize WOD state when entering a new section
    func initializeWODFormat(for section: WorkoutSection) {
        currentSection = section
        sectionStartTime = Date()
        lastCueSecond = -1 // Reset cue tracking

        // Collect all segments in this section
        currentSectionSegments = section.segments
        currentMovementIndex = 0

        // Reset WOD state
        emomCurrentMinute = 1
        emomSecondsRemaining = 60
        lastEmomMinute = 0

        amrapCurrentRound = 1
        amrapSecondsRemaining = (section.formatDetails?.timeCapMinutes ?? 0) * 60

        tabataIsWorkPhase = true
        tabataCurrentRound = 1
        tabataPhaseSecondsRemaining = section.formatDetails?.workSeconds ?? 20
        lastTabataIsWorkPhase = true

        roundsCurrentRound = 1
        forTimeSecondsRemaining = section.formatDetails?.timeCapMinutes.map { $0 * 60 }
    }

    // MARK: - GPS Management

    private func startGPSIfNeeded() {
        guard let segment = currentSegment else { return }

        // Only track GPS for run segments
        guard segment.segmentType == .run else { return }

        // Only use iPhone GPS if Watch is NOT available (fallback only)
        guard !isWatchAvailable else {
            // Watch is available, it will handle GPS tracking
            workout.gpsSource = .watch
            return
        }

        // Initialize location service if needed
        if locationService == nil {
            locationService = LocationTrackingService()
        }

        // Start iPhone GPS tracking
        locationService?.startTracking()
        isTrackingGPS = true
        workout.gpsSource = .iphone

        print("Started iPhone GPS tracking for run segment (Watch unavailable)")
    }

    private func stopGPSIfNeeded() {
        guard isTrackingGPS else { return }

        // Stop tracking and capture route data
        locationService?.stopTracking()

        // Get route data and add to workout
        if let routeData = locationService?.getRouteData() {
            workout.routeData = routeData
            print("Captured route data: \(routeData.totalDistance)m, \(routeData.coordinates.count) points")
        }

        isTrackingGPS = false
    }
}

// MARK: - WOD Cue Types

/// Cues triggered during WOD format execution
enum WODCue: Equatable {
    // EMOM
    case emomGo              // Start of each minute
    case emomWarning10       // 10 seconds remaining in minute

    // AMRAP
    case amrapOneMinuteLeft  // 1 minute remaining
    case amrap30SecondsLeft  // 30 seconds remaining

    // Tabata
    case tabataWork          // Work phase started
    case tabataRest          // Rest phase started

    // For Time
    case forTimeCapReached   // Time cap reached

    // General
    case countdown3          // 3 seconds countdown
    case countdown10         // 10 seconds countdown
    case sectionComplete     // Section/format complete

    var displayText: String {
        switch self {
        case .emomGo: return "GO!"
        case .emomWarning10: return "10 SEC"
        case .amrapOneMinuteLeft: return "1 MIN LEFT"
        case .amrap30SecondsLeft: return "30 SEC"
        case .tabataWork: return "WORK!"
        case .tabataRest: return "REST"
        case .forTimeCapReached: return "TIME!"
        case .countdown3: return "3..."
        case .countdown10: return "10..."
        case .sectionComplete: return "DONE!"
        }
    }

    var color: String {
        switch self {
        case .emomGo, .tabataWork: return "green"
        case .tabataRest: return "blue"
        case .emomWarning10, .amrapOneMinuteLeft, .amrap30SecondsLeft: return "orange"
        case .countdown3, .countdown10: return "yellow"
        case .forTimeCapReached, .sectionComplete: return "red"
        }
    }
}
