import SwiftUI
import HealthKit

struct WorkoutView: View {
    @EnvironmentObject var workoutManager: WorkoutSessionManager
    @Environment(\.scenePhase) var scenePhase
    @State private var selectedPage = 0

    // Apple Fitness green
    private let electricBlue = Color(red: 0.67, green: 1.0, blue: 0.0) // #ABFF00

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Layer 1: TabView content (fills screen)
            TabView(selection: $selectedPage) {
                metricsContent.tag(0)
                shadowRunnerContent.tag(1)
                infoContent.tag(2)
                heartContent.tag(3)
                controlsContent.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))

            // Layer 2: ABSOLUTE header - top left corner
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(segmentColor, lineWidth: 2.5)
                        .frame(width: 26, height: 26)
                    Image(systemName: segmentIcon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(segmentColor)
                }
                Text(segmentTargetLabel)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                // Segment counter - fixed position
                Text("\(currentSegmentNumber)/\(totalSegments)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.gray)
            }
            .offset(x: 8, y: 8) // ABSOLUTE offset from top-left corner (clear rounded corners)
        }
        .ignoresSafeArea()
        .background(Color.black)
        .onTapGesture(count: 2) {
            completeCurrentSegment()
        }
        .onAppear {
            workoutManager.startMetricsCollection()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                workoutManager.refreshMetrics()
            }
        }
    }

    // MARK: - Content Views

    private var metricsContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            // TIME
            Text(workoutManager.elapsedTime.formattedTime)
                .font(.system(size: 44, weight: .bold, design: .monospaced))
                .foregroundColor(electricBlue)

            // For RUNS
            if currentWatchUI_SegmentType == .run {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(paceFormatted.0)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text("'")
                        .font(.system(size: 24, weight: .bold))
                    Text(paceFormatted.1)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text("''")
                        .font(.system(size: 24, weight: .bold))
                    Text(" KM")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.2f", workoutManager.currentDistance / 1000))
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                    Text("KM")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .foregroundColor(.white)

            // For STATIONS
            } else if currentWatchUI_SegmentType.isHyroxStation || currentWatchUI_SegmentType == .station || currentWatchUI_SegmentType == .strength {
                if !isTimeBasedSegment {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(targetValueDisplay)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text(targetLabel.uppercased())
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .foregroundColor(.white)
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.red)
                    Text("\(workoutManager.currentHeartRate)")
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                    Text("BPM")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .foregroundColor(.white)

            // For WARMUP/COOLDOWN/REST
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                    Text("\(workoutManager.currentHeartRate)")
                        .font(.system(size: 30, weight: .medium, design: .rounded))
                    Text("BPM")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .foregroundColor(.white)

                if let remaining = targetTimeRemaining, remaining > 0 {
                    Text("-\(remaining.formattedTime)")
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                        .foregroundColor(.orange)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
        .padding(.horizontal, 8)
    }

    // MARK: - Shadow Runner Screen (Dedicated Page)

    private var shadowRunnerContent: some View {
        VStack(spacing: 16) {
            // Check if shadow runner is active
            if let session = workoutManager.currentSession,
               let shadowTarget = session.shadowTargetTime, shadowTarget > 0 {

                Spacer()

                // Main shadow runner visualization (LARGE)
                ShadowRunnerView(
                    userProgress: userProgressForShadow,
                    shadowProgress: session.shadowProgress,
                    timeDifference: session.timeDifferenceFromShadow
                )

                // Additional info
                VStack(spacing: 8) {
                    // Current time
                    Text(workoutManager.elapsedTime.formattedTime)
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(electricBlue)

                    // Target time
                    HStack(spacing: 4) {
                        Text("TARGET:")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gray)
                        Text(shadowTarget.formattedTime)
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.top, 16)

                Spacer()

            } else {
                // No shadow target set
                VStack(spacing: 12) {
                    Spacer()

                    Image(systemName: "figure.run.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.5))

                    Text("No Shadow Runner")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gray)

                    Text("Target time not set for this segment")
                        .font(.system(size: 12))
                        .foregroundColor(.gray.opacity(0.7))
                        .multilineTextAlignment(.center)

                    Spacer()
                }
                .padding(.horizontal, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 12)
        .padding(.horizontal, 8)
    }

    private var infoContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(currentSegmentName)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)

            VStack(alignment: .leading, spacing: 4) {
                if let reps = currentSegmentReps, reps > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "number")
                            .font(.system(size: 14))
                        Text("\(reps) REPS")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.8))
                }

                if let distance = currentSegmentTargetDistance, distance > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "ruler")
                            .font(.system(size: 14))
                        Text("\(Int(distance))M")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.8))
                }

                if let duration = currentSegmentTargetDuration, duration > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 14))
                        Text(duration.formattedTime)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
            }

            if let nextSegment = nextSegmentName {
                HStack(spacing: 4) {
                    Text("NEXT:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    Text(nextSegment)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .padding(.top, 4)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
        .padding(.horizontal, 8)
    }

    private var heartContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(workoutManager.currentHeartRate)")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("BPM")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white.opacity(0.7))

            HStack(spacing: 3) {
                ForEach(1...5, id: \.self) { zone in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(zone <= currentHeartRateZone ? zoneColor(zone) : Color.gray.opacity(0.3))
                        .frame(width: 20, height: 6)
                }

                Text("Z\(currentHeartRateZone)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(zoneColor(currentHeartRateZone))
                    .padding(.leading, 4)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
        .padding(.horizontal, 8)
    }

    private var controlsContent: some View {
        VStack(spacing: 12) {
            // Apple-style 2x2 grid
            VStack(spacing: 10) {
                // Top row: Lock + Pause
                HStack(spacing: 10) {
                    // Lock (Water Lock)
                    Button {
                        WKInterfaceDevice.current().enableWaterLock()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "drop.fill")
                                .font(.system(size: 24, weight: .semibold))
                            Text("Lock")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.black)
                        .frame(width: 72, height: 72)
                        .background(Color.cyan)
                        .cornerRadius(16)
                    }
                    .buttonStyle(.plain)

                    // Pause/Resume
                    Button {
                        workoutManager.togglePause()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: workoutManager.isPaused ? "play.fill" : "pause.fill")
                                .font(.system(size: 24, weight: .semibold))
                            Text(workoutManager.isPaused ? "Resume" : "Pause")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.black)
                        .frame(width: 72, height: 72)
                        .background(Color.yellow)
                        .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                }

                // Bottom row: End + Next Segment
                HStack(spacing: 10) {
                    // End Workout
                    Button {
                        WKInterfaceDevice.current().play(.stop)
                        workoutManager.endWorkout()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.system(size: 24, weight: .bold))
                            Text("End")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.black)
                        .frame(width: 72, height: 72)
                        .background(Color.red)
                        .cornerRadius(16)
                    }
                    .buttonStyle(.plain)

                    // Next Segment
                    Button {
                        completeCurrentSegment()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 24, weight: .semibold))
                            Text("Next")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.black)
                        .frame(width: 72, height: 72)
                        .background(electricBlue)
                        .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .padding(.top, 32)
    }

    // MARK: - Helper Properties

    private var segmentIcon: String {
        switch currentWatchUI_SegmentType {
        case .run: return "figure.run"
        case .skiErg, .skiErg2: return "figure.skiing.crosscountry"
        case .rowErg: return "oar.2.crossed"
        case .sleds: return "arrow.right"
        case .burpeeBroadJump: return "figure.jumprope"
        case .farmers: return "figure.walk"
        case .sandbag: return "figure.flexibility"
        case .wallBalls: return "figure.handball"
        case .lunges: return "figure.walk"
        case .warmup: return "flame.fill"
        case .cooldown: return "wind"
        case .rest: return "pause.circle"
        case .station, .strength: return "dumbbell.fill"
        case .transition: return "arrow.right"
        }
    }

    private var segmentColor: Color {
        switch currentWatchUI_SegmentType {
        case .run: return electricBlue
        case .warmup: return .yellow
        case .cooldown: return .mint
        case .rest: return .gray
        case .transition: return .gray
        default: return electricBlue // Stations use green
        }
    }

    private var totalWorkoutTime: TimeInterval {
        // Sum of all completed segment times + current segment time
        guard let session = workoutManager.currentSession else {
            return workoutManager.elapsedTime
        }
        let completedTime = session.segmentMetrics.reduce(0) { $0 + $1.duration }
        return completedTime + workoutManager.elapsedTime
    }

    private var targetTimeRemaining: TimeInterval? {
        guard let session = workoutManager.currentSession,
              session.currentSegmentIndex < session.segments.count else {
            return nil
        }
        let segment = session.segments[session.currentSegmentIndex]
        if let targetDuration = segment.targetDuration, targetDuration > 0 {
            return max(0, targetDuration - workoutManager.elapsedTime)
        }
        return nil
    }

    private var currentSegmentInstructions: String? {
        guard let session = workoutManager.currentSession,
              session.currentSegmentIndex < session.segments.count else {
            return nil
        }
        return session.segments[session.currentSegmentIndex].notes
    }

    private var currentSegmentReps: Int? {
        guard let session = workoutManager.currentSession,
              session.currentSegmentIndex < session.segments.count else {
            return nil
        }
        return session.segments[session.currentSegmentIndex].targetReps
    }

    private var currentSegmentTargetDistance: Double? {
        guard let session = workoutManager.currentSession,
              session.currentSegmentIndex < session.segments.count else {
            return nil
        }
        return session.segments[session.currentSegmentIndex].targetDistance
    }

    private var currentSegmentTargetDuration: TimeInterval? {
        guard let session = workoutManager.currentSession,
              session.currentSegmentIndex < session.segments.count else {
            return nil
        }
        return session.segments[session.currentSegmentIndex].targetDuration
    }

    private var nextSegmentName: String? {
        guard let session = workoutManager.currentSession,
              session.currentSegmentIndex + 1 < session.segments.count else {
            return nil
        }
        return session.segments[session.currentSegmentIndex + 1].displayName
    }

    private var segmentTargetLabel: String {
        guard let session = workoutManager.currentSession,
              session.currentSegmentIndex < session.segments.count else {
            return currentSegmentName
        }

        let segment = session.segments[session.currentSegmentIndex]

        // For runs: show distance
        if currentWatchUI_SegmentType == .run {
            if let distance = segment.targetDistance, distance > 0 {
                return "\(Int(distance))M"
            }
        }

        // For stations: show reps or distance
        if let reps = segment.targetReps, reps > 0 {
            return "\(reps) REPS"
        } else if let distance = segment.targetDistance, distance > 0 {
            return "\(Int(distance))M"
        } else if let duration = segment.targetDuration, duration > 0 {
            let mins = Int(duration) / 60
            return "\(mins) MIN"
        }

        return currentSegmentName.uppercased()
    }

    private var paceFormatted: (String, String) {
        let pace = currentPaceDisplay
        let components = pace.split(separator: ":")
        if components.count == 2 {
            return (String(components[0]), String(components[1]))
        }
        return ("--", "--")
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

    // MARK: - Computed Properties

    private var currentWatchUI_SegmentType: WatchUI_SegmentType {
        guard let session = workoutManager.currentSession,
              session.currentSegmentIndex < session.segments.count else {
            return .run
        }
        let segment = session.segments[session.currentSegmentIndex]
        
        switch segment.segmentType {
        case .run: return .run
        case .warmup: return .warmup
        case .cooldown: return .cooldown
        case .rest: return .rest
        case .transition: return .transition
        case .strength: return .station // Strength exercises display like stations
        case .finisher: return .station // Finisher displays like stations
        case .station:
            guard let station = segment.stationType else { return .station }
            switch station {
            case .skiErg: return .skiErg
            case .sledPush, .sledPull: return .sleds
            case .burpeeBroadJump: return .burpeeBroadJump
            case .rowing: return .rowErg
            case .farmersCarry: return .farmers
            case .sandbagLunges: return .sandbag
            case .wallBalls: return .wallBalls
            }
        }
    }

    private var currentSegmentName: String {
        guard let session = workoutManager.currentSession,
              session.currentSegmentIndex < session.segments.count else {
            return "Workout"
        }
        return session.segments[session.currentSegmentIndex].displayName
    }

    private var currentSegmentNumber: Int {
        guard let session = workoutManager.currentSession else { return 1 }
        return session.currentSegmentIndex + 1
    }

    private var totalSegments: Int {
        workoutManager.currentSession?.segments.count ?? 0
    }

    private var userProgressForShadow: Double {
        guard let session = workoutManager.currentSession,
              session.currentSegmentIndex < session.segments.count else {
            return 0
        }
        let segment = session.segments[session.currentSegmentIndex]

        // Calculate progress based on segment type
        if segment.segmentType == .run {
            // For runs, use distance-based progress
            if let targetDistance = segment.targetDistance, targetDistance > 0 {
                return min(workoutManager.currentDistance / targetDistance, 1.0)
            }
        }

        // For other segments or if no distance target, use time-based progress
        if let targetDuration = segment.targetDuration, targetDuration > 0,
           let startTime = session.segmentStartTime {
            let elapsed = Date().timeIntervalSince(startTime)
            return min(elapsed / targetDuration, 1.0)
        }

        return 0
    }

    private var currentRoundInfo: String? {
        // For stations, show "Round X of Y"
        // For runs, show "After: [Previous Station]"
        guard let session = workoutManager.currentSession else { return nil }

        if currentWatchUI_SegmentType == .run {
            // Find previous station
            if session.currentSegmentIndex > 0 {
                let previousSegment = session.segments[session.currentSegmentIndex - 1]
                return "After: \(previousSegment.displayName)"
            }
        } else {
            // Calculate round number for stations
            // Count how many times this station type has appeared before
            let currentIndex = session.currentSegmentIndex
            let stationSegments = session.segments.filter { $0.segmentType == .station }
            let currentRound = session.segments.prefix(currentIndex + 1).filter { $0.segmentType == .station }.count
            let totalRounds = stationSegments.count

            if totalRounds > 0 {
                return "Round \(currentRound) of \(totalRounds)"
            }
        }

        return nil
    }

    private var targetValueDisplay: String {
        guard let session = workoutManager.currentSession,
              session.currentSegmentIndex < session.segments.count else {
            return "0"
        }

        let segment = session.segments[session.currentSegmentIndex]

        if let reps = segment.targetReps, reps > 0 {
            return "\(reps)"
        } else if let distance = segment.targetDistance, distance > 0 {
            return "\(Int(distance))"
        } else if let duration = segment.targetDuration, duration > 0 {
            // Format duration as MM:SS
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }

        // Fallback: show elapsed time for open-ended segments
        return workoutManager.elapsedTime.formattedTime
    }

    private var targetLabel: String {
        guard let session = workoutManager.currentSession,
              session.currentSegmentIndex < session.segments.count else {
            return "time"
        }

        let segment = session.segments[session.currentSegmentIndex]

        if let reps = segment.targetReps, reps > 0 {
            return "reps"
        } else if let distance = segment.targetDistance, distance > 0 {
            return "meters"
        } else if segment.targetDuration != nil {
            return "target"
        }

        return "time"
    }

    private var isTimeBasedSegment: Bool {
        // Warmup, cooldown, rest, transition are time-based
        switch currentWatchUI_SegmentType {
        case .warmup, .cooldown, .rest, .transition:
            return true
        default:
            // Also time-based if no reps/distance target
            guard let session = workoutManager.currentSession,
                  session.currentSegmentIndex < session.segments.count else {
                return true
            }
            let segment = session.segments[session.currentSegmentIndex]
            let hasReps = segment.targetReps != nil && segment.targetReps! > 0
            let hasDistance = segment.targetDistance != nil && segment.targetDistance! > 0
            return !hasReps && !hasDistance
        }
    }

    private var bestSegmentTime: String? {
        // Find best time for same segment type from previous completions
        guard let session = workoutManager.currentSession else { return nil }

        let currentSegmentName = session.segments[session.currentSegmentIndex].displayName
        let previousCompletions = session.segmentMetrics.filter { $0.segmentName == currentSegmentName }

        if let bestTime = previousCompletions.map({ $0.duration }).min() {
            return bestTime.formattedTime
        }

        return nil
    }

    private var currentPaceDisplay: String {
        let pace = workoutManager.currentPace
        if pace == "--:--" || pace.isEmpty {
            return "--:--"
        }
        return pace
    }

    private var targetPaceRange: String {
        guard let session = workoutManager.currentSession,
              session.currentSegmentIndex < session.segments.count else {
            return "--:-- - --:--"
        }

        let segment = session.segments[session.currentSegmentIndex]

        if let targetPace = segment.targetPace {
            // Parse target pace (e.g., "5:10") and create range (±5 seconds)
            let components = targetPace.split(separator: ":")
            if components.count == 2,
               let minutes = Int(components[0]),
               let seconds = Int(components[1]) {
                let totalSeconds = minutes * 60 + seconds
                let minSeconds = totalSeconds - 5
                let maxSeconds = totalSeconds + 5

                let minMin = minSeconds / 60
                let minSec = minSeconds % 60
                let maxMin = maxSeconds / 60
                let maxSec = maxSeconds % 60

                return String(format: "%d:%02d-%d:%02d", minMin, minSec, maxMin, maxSec)
            }
        }

        return "--:-- - --:--"
    }

    private var isPaceInTargetRange: Bool {
        guard let session = workoutManager.currentSession,
              session.currentSegmentIndex < session.segments.count else {
            return false
        }

        let segment = session.segments[session.currentSegmentIndex]
        let currentPaceStr = workoutManager.currentPace

        guard let targetPace = segment.targetPace else { return false }

        // Parse both paces
        let targetComponents = targetPace.split(separator: ":")
        let currentComponents = currentPaceStr.split(separator: ":")

        guard targetComponents.count == 2, currentComponents.count == 2,
              let targetMin = Int(targetComponents[0]), let targetSec = Int(targetComponents[1]),
              let currentMin = Int(currentComponents[0]), let currentSec = Int(currentComponents[1]) else {
            return false
        }

        let targetTotal = targetMin * 60 + targetSec
        let currentTotal = currentMin * 60 + currentSec

        // Allow ±5 seconds tolerance
        return abs(currentTotal - targetTotal) <= 5
    }

    private var remainingDistance: Double {
        guard let session = workoutManager.currentSession,
              session.currentSegmentIndex < session.segments.count else {
            return 0
        }

        let segment = session.segments[session.currentSegmentIndex]
        if let targetDistance = segment.targetDistance {
            let remaining = targetDistance - workoutManager.currentDistance
            return max(0, remaining)
        }

        return 0
    }

    private var currentHeartRateZone: Int {
        let hr = workoutManager.currentHeartRate

        // Calculate zone based on heart rate
        // Zone 1: 50-60% max (90-108 for max 180)
        // Zone 2: 60-70% max (108-126)
        // Zone 3: 70-80% max (126-144)
        // Zone 4: 80-90% max (144-162)
        // Zone 5: 90-100% max (162-180)

        let maxHR = 180 // Should be calculated based on age

        if hr < Int(Double(maxHR) * 0.6) {
            return 1
        } else if hr < Int(Double(maxHR) * 0.7) {
            return 2
        } else if hr < Int(Double(maxHR) * 0.8) {
            return 3
        } else if hr < Int(Double(maxHR) * 0.9) {
            return 4
        } else {
            return 5
        }
    }

    // MARK: - Actions

    private func completeCurrentSegment() {
        print("TAP WHEN DONE pressed - segment \(currentSegmentNumber)/\(totalSegments)")
        WKInterfaceDevice.current().play(.success)
        workoutManager.completeCurrentSegment()

        // Check if this was the last segment
        if currentSegmentNumber >= totalSegments {
            print("Last segment completed - ending workout")
            WKInterfaceDevice.current().play(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                workoutManager.endWorkout()
            }
        } else {
            // Advance to next segment after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                workoutManager.startNextSegment()
            }
        }
    }
}


// MARK: - Supporting Types
enum WatchUI_SegmentType: String, Codable {
    case run
    case skiErg
    case sleds
    case burpeeBroadJump
    case rowErg
    case farmers
    case sandbag
    case skiErg2
    case wallBalls
    case lunges
    // Additional types for AI-generated segments
    case warmup
    case cooldown
    case rest
    case station
    case strength
    case transition

    /// Returns true if this is a running segment (shows pace UI)
    var isRun: Bool {
        return self == .run
    }

    /// Returns true if this is a HYROX station (shows reps/distance UI)
    var isHyroxStation: Bool {
        switch self {
        case .skiErg, .skiErg2, .rowErg, .sleds, .burpeeBroadJump,
             .farmers, .sandbag, .wallBalls, .lunges:
            return true
        default:
            return false
        }
    }

    var displayName: String {
        switch self {
        case .run: return "Run"
        case .skiErg: return "Ski Erg"
        case .sleds: return "Sleds"
        case .burpeeBroadJump: return "Burpee Broad Jump"
        case .rowErg: return "Row Erg"
        case .farmers: return "Farmers Carry"
        case .sandbag: return "Sandbag Lunges"
        case .skiErg2: return "Ski Erg"
        case .wallBalls: return "Wall Balls"
        case .lunges: return "Lunges"
        case .warmup: return "Warm Up"
        case .cooldown: return "Cool Down"
        case .rest: return "Rest"
        case .station: return "Station"
        case .strength: return "Strength"
        case .transition: return "Transition"
        }
    }

    var iconName: String {
        switch self {
        case .run: return "figure.run"
        case .skiErg, .skiErg2: return "figure.skiing.crosscountry"
        case .sleds: return "figure.strengthtraining.traditional"
        case .burpeeBroadJump: return "figure.jumprope"
        case .rowErg: return "oar.2.crossed"
        case .farmers: return "figure.walk"
        case .sandbag: return "figure.flexibility"
        case .wallBalls: return "figure.handball"
        case .lunges: return "figure.flexibility"
        case .warmup: return "flame.fill"
        case .cooldown: return "wind"
        case .rest: return "pause.circle"
        case .station: return "figure.strengthtraining.functional"
        case .strength: return "dumbbell.fill"
        case .transition: return "arrow.right"
        }
    }

    var color: Color {
        switch self {
        case .run: return .blue
        case .skiErg, .rowErg, .skiErg2: return .cyan
        case .sleds, .sandbag, .farmers: return .orange
        case .burpeeBroadJump, .wallBalls, .lunges: return .green
        case .warmup: return .yellow
        case .cooldown: return .mint
        case .rest: return .gray
        case .station, .strength: return .purple
        case .transition: return .gray
        }
    }
}

// MARK: - TimeInterval Extension
extension TimeInterval {
    var formattedTime: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var formattedTimeWithHours: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// MARK: - Shadow Runner View

struct ShadowRunnerView: View {
    let userProgress: Double // 0.0 to 1.0 (percentage of segment completed)
    let shadowProgress: Double // 0.0 to 1.0 (where shadow should be)
    let timeDifference: TimeInterval // positive = ahead, negative = behind

    private let trackLength: CGFloat = 140 // Width of the track on Watch
    private let runnerSize: CGFloat = 16

    // Apple Fitness green
    private let electricBlue = Color(red: 0.67, green: 1.0, blue: 0.0) // #ABFF00

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

#Preview {
    WorkoutView()
        .environmentObject(WorkoutSessionManager())
}
