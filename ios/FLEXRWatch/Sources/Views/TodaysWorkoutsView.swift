// FLEXR Watch - Today's Workouts View
// Clean, Apple-like design with large fonts

import SwiftUI

struct TodaysWorkoutsView: View {
    @StateObject private var planService = WatchPlanService.shared
    @EnvironmentObject var workoutManager: WorkoutSessionManager

    private let electricBlue = Color(red: 0.039, green: 0.518, blue: 1.0)  // #0A84FF

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Header - just the day, left aligned
                    Text(todayString.uppercased())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 12)
                        .padding(.top, 8)

                    if planService.isLoading && planService.todaysWorkouts.isEmpty {
                        // Loading state
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(electricBlue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)

                    } else if planService.todaysWorkouts.isEmpty {
                        // Rest Day - but show upcoming workouts for flexibility
                        VStack(spacing: 8) {
                            Image(systemName: "moon.zzz.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.gray)

                            Text("Rest Day")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)

                        // Show upcoming workouts user can do early
                        if !planService.upcomingWorkouts.isEmpty {
                            Text("COMING UP")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 12)
                                .padding(.top, 8)

                            ForEach(planService.upcomingWorkouts) { workout in
                                NavigationLink {
                                    WorkoutPreviewView(workout: workout) { skipWarmup, skipCooldown in
                                        startWorkout(workout, skipWarmup: skipWarmup, skipCooldown: skipCooldown)
                                    }
                                } label: {
                                    WorkoutCard(workout: workout)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)
                        }

                    } else {
                        // Workout cards
                        ForEach(planService.todaysWorkouts) { workout in
                            NavigationLink {
                                WorkoutPreviewView(workout: workout) { skipWarmup, skipCooldown in
                                    startWorkout(workout, skipWarmup: skipWarmup, skipCooldown: skipCooldown)
                                }
                            } label: {
                                WorkoutCard(workout: workout)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 8)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await planService.fetchTodaysWorkouts()
            }
        }
    }

    private var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }

    private func startWorkout(_ workout: WatchPlannedWorkout, skipWarmup: Bool = false, skipCooldown: Bool = false) {
        var allSegments: [WorkoutSegment] = []

        for seg in workout.segments ?? [] {
            let (mappedSegType, mappedStationType) = mapSegmentType(seg.segmentType, name: seg.name, distanceMeters: seg.targetDistanceMeters, stationType: seg.stationType)
            let setCount = seg.sets ?? 1

            if setCount > 1 {
                for setNum in 1...setCount {
                    // Note: Core model doesn't have mutable 'name' property in init, it uses displayName computed from type.
                    // But we might want to store "Wall Balls (1/3)" in notes? Or trust the model handling?
                    // Core init allows 'notes'.
                    // For now, we reconstruct segments.
                    
                    allSegments.append(WorkoutSegment(
                        id: UUID(),
                        workoutId: workout.id,
                        segmentType: mappedSegType,
                        stationType: mappedStationType,
                        targetDuration: seg.targetDurationSeconds.map { TimeInterval($0) },
                        targetDistance: seg.targetDistanceMeters.map { Double($0) },
                        targetReps: seg.targetReps,
                        targetPace: seg.targetPace,
                        notes: "\(seg.name) (\(setNum)/\(setCount))"
                    ))

                    if let restSeconds = seg.restBetweenSetsSeconds, restSeconds > 0, setNum < setCount {
                        allSegments.append(WorkoutSegment(
                            id: UUID(),
                            workoutId: workout.id,
                            segmentType: .rest,
                            targetDuration: TimeInterval(restSeconds)
                        ))
                    }
                }
            } else {
                allSegments.append(WorkoutSegment(
                    id: seg.id,
                    workoutId: workout.id,
                    segmentType: mappedSegType,
                    stationType: mappedStationType,
                    targetDuration: seg.targetDurationSeconds.map { TimeInterval($0) },
                    targetDistance: seg.targetDistanceMeters.map { Double($0) },
                    targetReps: seg.targetReps,
                    targetPace: seg.targetPace,
                    notes: seg.instructions
                ))
            }
        }

        let segments = allSegments.filter { segment in
            if skipWarmup && segment.segmentType == .warmup { return false }
            if skipCooldown && segment.segmentType == .cooldown { return false }
            return true
        }

        let receivedWorkout = ReceivedWorkout(
            id: workout.id,
            name: workout.name,
            type: workout.workoutType,
            segments: segments,
            estimatedDuration: TimeInterval(workout.estimatedDuration * 60)
        )

        workoutManager.startWorkout(receivedWorkout)
    }

    private func mapSegmentType(_ type: String, name: String = "", distanceMeters: Int? = nil, stationType: String? = nil) -> (SegmentType, StationType?) {
        let typeLower = type.lowercased()
        let nameLower = name.lowercased()
        let stationLower = stationType?.lowercased() ?? ""

        switch typeLower {
        case "warmup": return (.warmup, nil)
        case "cooldown": return (.cooldown, nil)
        case "rest": return (.rest, nil)
        case "transition": return (.transition, nil)
        default: break
        }

        if typeLower == "run" || typeLower == "running" { return (.run, nil) }
        if nameLower.contains("run") && !nameLower.contains("warm") && typeLower != "station" { return (.run, nil) }
        if let distance = distanceMeters, distance >= 400, stationType == nil || stationType?.isEmpty == true, typeLower != "station" { return (.run, nil) }

        if !stationLower.isEmpty {
            switch stationLower {
            case "ski_erg", "skierg": return (.station, .skiErg)
            case "sled_push", "sled_pull", "sleds": return (.station, .sledPush) // Map both to sledPush or separate? Core has both. Let's safe bet sledPush or check logic.
            case "burpee_broad_jump", "bbj": return (.station, .burpeeBroadJump)
            case "rowing", "row_erg", "rowerg": return (.station, .rowing)
            case "farmers_carry", "farmers": return (.station, .farmersCarry)
            case "sandbag_lunges", "sandbag": return (.station, .sandbagLunges)
            case "wall_balls", "wallballs": return (.station, .wallBalls)
            default: break
            }
        }

        if typeLower == "station" || typeLower == "main" {
            if nameLower.contains("ski") { return (.station, .skiErg) }
            if nameLower.contains("row") { return (.station, .rowing) }
            if nameLower.contains("sled") { return (.station, .sledPush) }
            if nameLower.contains("burpee") || nameLower.contains("bbj") { return (.station, .burpeeBroadJump) }
            if nameLower.contains("farmer") || nameLower.contains("carry") { return (.station, .farmersCarry) }
            if nameLower.contains("sandbag") || (nameLower.contains("lunge") && nameLower.contains("bag")) { return (.station, .sandbagLunges) }
            if nameLower.contains("wall ball") || nameLower.contains("wallball") { return (.station, .wallBalls) }
            if nameLower.contains("lunge") { return (.station, .sandbagLunges) }
        }

        if typeLower == "main" || typeLower == "strength" { return (.station, nil) } // Core doesn't have strength? It has station.
        return (.station, nil)
    }
}

// MARK: - Workout Card (Clean, Large)

struct WorkoutCard: View {
    let workout: WatchPlannedWorkout

    private let electricBlue = Color(red: 0.039, green: 0.518, blue: 1.0)  // #0A84FF

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Workout type label (small, colored)
            Text(workoutTypeLabel.uppercased())
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(electricBlue)

            // Workout name (LARGE)
            Text(displayName)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            // Duration badge
            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 14))
                Text("\(workout.estimatedDuration) MIN")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(electricBlue.opacity(0.15))
        .cornerRadius(16)
    }

    // Use AI-generated watch_name or fallback to name
    private var displayName: String {
        if let watchName = workout.watchName, !watchName.isEmpty {
            return watchName.uppercased()
        }
        // Fallback: truncate full name
        return String(workout.name.prefix(12)).uppercased()
    }

    private var workoutTypeLabel: String {
        switch workout.workoutType {
        case "running": return "Running"
        case "strength": return "Strength"
        case "station_focus": return "Stations"
        case "full_simulation": return "Full Sim"
        case "half_simulation": return "Half Sim"
        case "recovery": return "Recovery"
        default: return "Workout"
        }
    }
}

#Preview {
    TodaysWorkoutsView()
        .environmentObject(WorkoutSessionManager())
}
