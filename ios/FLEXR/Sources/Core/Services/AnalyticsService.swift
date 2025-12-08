import Foundation
import CoreData
import Combine

/// Centralized service for handling all analytics operations
class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()

    @Published var isLoading = false
    @Published var lastSyncDate: Date?

    private let coreDataManager = CoreDataManager.shared
    private let supabaseService = SupabaseService.shared

    // HealthKit data cache - updated from UI layer
    var cachedHRV: Double?
    var cachedSleepHours: Double?
    var cachedRestingHR: Double?
    var cachedReadinessScore: Int?

    // Running session cache - for pace zone calculations
    var cachedRunningSplits: [TimeInterval] = []  // Array of pace per km values (seconds)
    var cachedHeartRateZones: HeartRateZones?

    private init() {}

    // MARK: - Save Workout

    /// Save workout summary from Watch to Core Data (triggers immediate sync)
    func saveWorkout(_ summary: WorkoutSummary) async {
        await saveWorkoutWithoutSync(summary)

        // Queue single sync operation
        await self.syncToSupabase()
    }

    /// Save workout without triggering sync (for batch imports)
    func saveWorkoutWithoutSync(_ summary: WorkoutSummary) async {
        // Check if workout already exists (prevent duplicates)
        if workoutExists(id: summary.id, date: summary.date, duration: summary.totalTime, distance: summary.totalDistance) {
            print("⚠️ Workout already exists - skipping: \(summary.workoutName) on \(summary.date)")
            return
        }

        let context = coreDataManager.newBackgroundContext()

        await context.perform {
            let workout = WorkoutEntity(from: summary, context: context)

            do {
                try context.save()
                print("✅ Workout saved to Core Data: \(summary.workoutName) on \(summary.date)")

                // Post notification for UI updates
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .workoutSaved, object: summary)
                }
            } catch {
                print("❌ Failed to save workout: \(error)")
            }
        }
    }

    /// Check if a workout already exists in Core Data
    private func workoutExists(id: UUID, date: Date, duration: TimeInterval, distance: Double) -> Bool {
        // Create a time window (±5 seconds) to account for slight timing differences
        let calendar = Calendar.current
        let startWindow = calendar.date(byAdding: .second, value: -5, to: date) ?? date
        let endWindow = calendar.date(byAdding: .second, value: 5, to: date) ?? date

        // Check for workout with same date and similar duration/distance
        let predicate = NSPredicate(
            format: "workoutDate >= %@ AND workoutDate <= %@ AND totalTime >= %f AND totalTime <= %f AND totalDistance >= %f AND totalDistance <= %f",
            startWindow as NSDate, endWindow as NSDate,
            duration - 5, duration + 5,
            distance - 10, distance + 10
        )

        let existing = coreDataManager.fetch(
            entityType: WorkoutEntity.self,
            predicate: predicate
        )

        return !existing.isEmpty
    }

    // MARK: - Fetch Workouts

    /// Fetch workouts for a specific timeframe
    func fetchWorkouts(timeframe: AnalyticsTimeframe) -> [WorkoutEntity] {
        let now = Date()
        let startDate = timeframe.startDate
        let predicate = NSPredicate(format: "workoutDate >= %@", startDate as NSDate)
        let sortDescriptors = [NSSortDescriptor(key: "workoutDate", ascending: false)]

        let workouts = coreDataManager.fetch(
            entityType: WorkoutEntity.self,
            predicate: predicate,
            sortDescriptors: sortDescriptors
        )

        print("📊 [AnalyticsService] Fetched \(workouts.count) workouts for timeframe: \(timeframe)")
        print("📅 [AnalyticsService] Date filter: \(startDate) to \(now)")

        // Debug: Show workout dates and distances
        if workouts.count > 0 {
            let dates = workouts.prefix(10).compactMap { $0.workoutDate }
            let distances = workouts.prefix(10).map { $0.totalDistance / 1000.0 }
            print("📅 [AnalyticsService] First 10 workout dates: \(dates.map { $0.description })")
            print("📏 [AnalyticsService] First 10 distances (km): \(distances.map { String(format: "%.2f", $0) })")

            let totalDistance = workouts.reduce(0.0) { $0 + $1.totalDistance }
            print("🏃 [AnalyticsService] Total distance: \(String(format: "%.2f", totalDistance / 1000.0)) km")
        }

        return workouts
    }

    /// Fetch all workouts
    func fetchAllWorkouts() -> [WorkoutEntity] {
        let sortDescriptors = [NSSortDescriptor(key: "workoutDate", ascending: false)]
        return coreDataManager.fetch(
            entityType: WorkoutEntity.self,
            sortDescriptors: sortDescriptors
        )
    }

    // MARK: - Calculate Analytics

    /// Calculate analytics data for dashboard
    func calculateAnalytics(timeframe: AnalyticsTimeframe) -> AnalyticsData {
        let workouts = fetchWorkouts(timeframe: timeframe)

        print("📊 [AnalyticsService] Calculating analytics from \(workouts.count) workouts for timeframe: \(timeframe)")

        // Calculate readiness (simplified - can be enhanced with HRV data)
        let avgHR = workouts.map { Int($0.averageHeartRate) }.reduce(0, +) / max(1, workouts.count)
        let readiness = calculateReadinessScore(avgHR: avgHR, workoutCount: workouts.count)

        // Calculate race prediction (simplified)
        let totalDistance = workouts.reduce(0.0) { $0 + $1.totalDistance }
        let totalTime = workouts.reduce(0.0) { $0 + $1.totalTime }
        let avgPacePerKm = totalDistance > 0 ? (totalTime / (totalDistance / 1000.0)) / 60.0 : 0
        let racePrediction = calculateRacePrediction(avgPacePerKm: avgPacePerKm)

        // Calculate training load
        let weeklyHours = workouts.reduce(0.0) { $0 + ($1.totalTime / 3600.0) }
        let targetHours = 8.0 // Can be customized per user
        let trainingLoad = TrainingLoad(
            weeklyTarget: targetHours,
            currentWeekHours: weeklyHours,
            dailyBreakdown: calculateDailyBreakdown(workouts: workouts)
        )

        // Calculate quick stats
        let runWorkouts = workouts.filter { workout in
            (workout.segments?.allObjects as? [SegmentEntity])?.contains(where: { $0.segmentType == "run" }) ?? false
        }
        let quickStats = QuickStats(
            weeklyDistance: totalDistance / 1000.0, // Convert to km
            monthlyDistance: totalDistance / 1000.0,
            totalRuns: runWorkouts.count,
            totalHours: totalTime / 3600.0
        )

        // Calculate pace zones (simplified)
        let paceZones = calculatePaceZones(workouts: workouts)

        // Station performance
        let stationPerf = calculateStationPerformance(workouts: workouts)

        // Compromised running analysis
        let compromisedRuns = workouts.flatMap { workout in
            (workout.compromisedRuns?.allObjects as? [CompromisedRunEntity])?.map { run in
                CompromisedRun(
                    segmentIndex: Int(run.segmentIndex),
                    segmentName: run.segmentName ?? "",
                    expectedPace: run.expectedPace,
                    actualPace: run.actualPace,
                    degradation: run.degradation
                )
            } ?? []
        }

        // Heart rate analysis
        let maxHR = workouts.map { Int($0.maxHeartRate) }.max() ?? 0
        let hrZones = calculateHRZones(workouts: workouts)

        // Time distribution
        let timeDistribution = calculateTimeDistribution(workouts: workouts)

        // Running workouts
        let runningWorkouts = calculateRunningWorkouts(workouts: runWorkouts)

        return AnalyticsData(
            readiness: readiness,
            racePrediction: racePrediction,
            trainingLoad: trainingLoad,
            quickStats: quickStats,
            paceZones: paceZones,
            stationPerformance: stationPerf,
            compromisedRunning: Array(compromisedRuns.prefix(5)),
            maxHeartRate: maxHR,
            heartRateZones: hrZones,
            timeDistribution: timeDistribution,
            runningWorkouts: runningWorkouts
        )
    }

    // MARK: - Helper Calculations

    private func calculateReadinessScore(avgHR: Int, workoutCount: Int) -> Readiness {
        // Use cached HealthKit data when available (updated by UI layer)
        let hrvScore: Int = cachedHRV != nil ? Int(cachedHRV!) : 0
        let sleepHours: Double = cachedSleepHours ?? 0
        let restingHR: Int = cachedRestingHR != nil ? Int(cachedRestingHR!) : avgHR
        let readinessScore: Int = cachedReadinessScore ?? 50

        return Readiness(
            hrvScore: hrvScore,
            sleepHours: sleepHours,
            restingHeartRate: restingHR,
            readinessScore: readinessScore
        )
    }

    /// Update cached HealthKit data from UI layer
    func updateHealthKitCache(hrv: Double?, sleepHours: Double?, restingHR: Double?, readinessScore: Int?) {
        self.cachedHRV = hrv
        self.cachedSleepHours = sleepHours
        self.cachedRestingHR = restingHR
        self.cachedReadinessScore = readinessScore
    }

    /// Update cached running session data from UI layer
    func updateRunningCache(splits: [TimeInterval], heartRateZones: HeartRateZones?) {
        self.cachedRunningSplits = splits
        self.cachedHeartRateZones = heartRateZones
    }

    private func calculateRacePrediction(avgPacePerKm: Double) -> RacePrediction {
        // Predict HYROX finish time based on average pace
        // HYROX = 8km running + 8 stations
        let runningTime = avgPacePerKm * 8.0
        let stationTime = 30.0 // ~30 min for stations (estimate)
        let totalMinutes = runningTime + stationTime

        return RacePrediction(
            predictedTime: totalMinutes * 60, // Convert to seconds
            marginOfError: 5.0,
            trend: totalMinutes < 60 ? .improving : .stable
        )
    }

    private func calculateDailyBreakdown(workouts: [WorkoutEntity]) -> [DailyTraining] {
        let calendar = Calendar.current
        let today = Date()

        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let dayWorkouts = workouts.filter {
                guard let workoutDate = $0.workoutDate else { return false }
                return calendar.isDate(workoutDate, inSameDayAs: date)
            }

            let hours = dayWorkouts.reduce(0.0) { $0 + ($1.totalTime / 3600.0) }

            return DailyTraining(
                day: calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1],
                hours: hours,
                isToday: calendar.isDateInToday(date)
            )
        }
    }

    private func calculatePaceZones(workouts: [WorkoutEntity]) -> [PaceZone] {
        // Use cached running splits if available (real data from Supabase)
        guard !cachedRunningSplits.isEmpty else {
            // Return empty zones if no data
            return [
                PaceZone(zoneName: "Zone 1 (Recovery)", paceRange: ">6:00", percentage: 0),
                PaceZone(zoneName: "Zone 2 (Easy)", paceRange: "5:30-6:00", percentage: 0),
                PaceZone(zoneName: "Zone 3 (Tempo)", paceRange: "5:00-5:30", percentage: 0),
                PaceZone(zoneName: "Zone 4 (Threshold)", paceRange: "4:30-5:00", percentage: 0),
                PaceZone(zoneName: "Zone 5 (Max)", paceRange: "<4:30", percentage: 0)
            ]
        }

        // Define zone boundaries in seconds per km
        // Zone 1: > 360s (6:00/km) - Recovery
        // Zone 2: 330-360s (5:30-6:00/km) - Easy
        // Zone 3: 300-330s (5:00-5:30/km) - Tempo
        // Zone 4: 270-300s (4:30-5:00/km) - Threshold
        // Zone 5: < 270s (< 4:30/km) - Max effort

        var zone1Count = 0
        var zone2Count = 0
        var zone3Count = 0
        var zone4Count = 0
        var zone5Count = 0

        for pace in cachedRunningSplits {
            if pace > 360 {
                zone1Count += 1
            } else if pace > 330 {
                zone2Count += 1
            } else if pace > 300 {
                zone3Count += 1
            } else if pace > 270 {
                zone4Count += 1
            } else {
                zone5Count += 1
            }
        }

        let total = Double(cachedRunningSplits.count)
        let zone1Pct = Int((Double(zone1Count) / total) * 100)
        let zone2Pct = Int((Double(zone2Count) / total) * 100)
        let zone3Pct = Int((Double(zone3Count) / total) * 100)
        let zone4Pct = Int((Double(zone4Count) / total) * 100)
        let zone5Pct = Int((Double(zone5Count) / total) * 100)

        return [
            PaceZone(zoneName: "Zone 1 (Recovery)", paceRange: ">6:00", percentage: zone1Pct),
            PaceZone(zoneName: "Zone 2 (Easy)", paceRange: "5:30-6:00", percentage: zone2Pct),
            PaceZone(zoneName: "Zone 3 (Tempo)", paceRange: "5:00-5:30", percentage: zone3Pct),
            PaceZone(zoneName: "Zone 4 (Threshold)", paceRange: "4:30-5:00", percentage: zone4Pct),
            PaceZone(zoneName: "Zone 5 (Max)", paceRange: "<4:30", percentage: zone5Pct)
        ]
    }

    private func calculateStationPerformance(workouts: [WorkoutEntity]) -> [StationPerformance] {
        var stationMap: [String: [Double]] = [:]

        // Group segments by station type
        for workout in workouts {
            let segments = workout.segments?.allObjects as? [SegmentEntity] ?? []
            for segment in segments {
                if segment.segmentType != "run" {
                    let name = segment.segmentName ?? ""
                    stationMap[name, default: []].append(segment.duration)
                }
            }
        }

        // Calculate best, average, last for each station
        return stationMap.map { (name, times) in
            let sortedTimes = times.sorted()
            return StationPerformance(
                stationName: name,
                bestTime: sortedTimes.first ?? 0,
                averageTime: times.reduce(0, +) / Double(times.count),
                lastTime: times.last ?? 0,
                trend: sortedTimes.last! < sortedTimes.first! ? .improving : .declining,
                performanceScore: 75 // Placeholder
            )
        }.sorted { $0.stationName < $1.stationName }
    }

    private func calculateHRZones(workouts: [WorkoutEntity]) -> [HRZone] {
        // Use cached heart rate zones from running sessions if available
        if let hrZones = cachedHeartRateZones {
            return [
                HRZone(zone: 1, percentage: Int(hrZones.percentInZone(1)), color: "blue"),
                HRZone(zone: 2, percentage: Int(hrZones.percentInZone(2)), color: "green"),
                HRZone(zone: 3, percentage: Int(hrZones.percentInZone(3)), color: "yellow"),
                HRZone(zone: 4, percentage: Int(hrZones.percentInZone(4)), color: "orange"),
                HRZone(zone: 5, percentage: Int(hrZones.percentInZone(5)), color: "red")
            ]
        }

        // Return empty zones if no data
        return [
            HRZone(zone: 1, percentage: 0, color: "blue"),
            HRZone(zone: 2, percentage: 0, color: "green"),
            HRZone(zone: 3, percentage: 0, color: "yellow"),
            HRZone(zone: 4, percentage: 0, color: "orange"),
            HRZone(zone: 5, percentage: 0, color: "red")
        ]
    }

    private func calculateTimeDistribution(workouts: [WorkoutEntity]) -> TimeDistribution {
        var runningTime = 0.0
        var stationTime = 0.0
        var transitionTime = 0.0

        for workout in workouts {
            let segments = workout.segments?.allObjects as? [SegmentEntity] ?? []
            for segment in segments {
                switch segment.segmentType {
                case "run":
                    runningTime += segment.duration
                case "transition":
                    transitionTime += segment.duration
                default:
                    stationTime += segment.duration
                }
            }
        }

        let total = runningTime + stationTime + transitionTime
        guard total > 0 else {
            return TimeDistribution(runningPercentage: 50, stationsPercentage: 40, transitionsPercentage: 10)
        }

        return TimeDistribution(
            runningPercentage: (runningTime / total) * 100,
            stationsPercentage: (stationTime / total) * 100,
            transitionsPercentage: (transitionTime / total) * 100
        )
    }

    private func calculateRunningWorkouts(workouts: [WorkoutEntity]) -> RunningWorkouts {
        let distances = workouts.map { $0.totalDistance / 1000.0 }
        let avgDistance = distances.isEmpty ? 0 : distances.reduce(0, +) / Double(distances.count)

        return RunningWorkouts(
            weeklyVolume: avgDistance * 7,
            longestRun: distances.max() ?? 0,
            averagePace: "5:15", // Placeholder
            personalRecords: 3, // Placeholder
            zone2Percentage: 65 // Placeholder
        )
    }

    // MARK: - Backend Sync

    /// Sync unsynced workouts to Supabase backend
    func syncToSupabase() async {
        let predicate = NSPredicate(format: "syncedToBackend == NO")
        let unsyncedWorkouts = coreDataManager.fetch(
            entityType: WorkoutEntity.self,
            predicate: predicate
        )

        guard !unsyncedWorkouts.isEmpty else {
            print("✅ All workouts already synced")
            return
        }

        print("📤 Syncing \(unsyncedWorkouts.count) workouts to backend...")

        for workout in unsyncedWorkouts {
            do {
                // Convert to WorkoutSummary for backend
                let summary = workout.toWorkoutSummary()

                // Sync to Supabase backend
                try await supabaseService.saveWorkoutSummary(summary)

                // Mark as synced
                let context = coreDataManager.viewContext
                workout.syncedToBackend = true
                try context.save()

                print("✅ Synced workout: \(workout.workoutName ?? "")")
            } catch {
                print("❌ Failed to sync workout \(workout.id?.uuidString ?? ""): \(error)")
            }
        }

        DispatchQueue.main.async {
            self.lastSyncDate = Date()
        }
    }

    // MARK: - Delete Operations

    func deleteWorkout(_ workout: WorkoutEntity) {
        do {
            try coreDataManager.delete(workout)
            print("✅ Deleted workout: \(workout.workoutName ?? "")")
        } catch {
            print("❌ Failed to delete workout: \(error)")
        }
    }

    func deleteAllWorkouts() {
        do {
            try coreDataManager.deleteAll(entityType: WorkoutEntity.self)
            print("✅ Deleted all workouts")
        } catch {
            print("❌ Failed to delete all workouts: \(error)")
        }
    }

    /// Remove duplicate workouts from Core Data
    func removeDuplicateWorkouts() {
        let allWorkouts = fetchAllWorkouts()
        print("🧹 Checking \(allWorkouts.count) workouts for duplicates...")

        var seen: Set<String> = []
        var duplicates: [WorkoutEntity] = []

        for workout in allWorkouts {
            // Create a unique key based on date + duration + distance
            let date = workout.workoutDate ?? Date()
            let dateString = ISO8601DateFormatter().string(from: date)
            let key = "\(dateString)_\(workout.totalTime)_\(workout.totalDistance)"

            if seen.contains(key) {
                // This is a duplicate
                duplicates.append(workout)
            } else {
                seen.insert(key)
            }
        }

        print("🧹 Found \(duplicates.count) duplicate workouts")

        // Delete duplicates
        for duplicate in duplicates {
            do {
                try coreDataManager.delete(duplicate)
            } catch {
                print("❌ Failed to delete duplicate: \(error)")
            }
        }

        if duplicates.count > 0 {
            print("✅ Removed \(duplicates.count) duplicate workouts")
        }
    }
}

// MARK: - Timeframe Enum

enum AnalyticsTimeframe {
    case week
    case month
    case threeMonths
    case year
    case all

    var startDate: Date {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .week:
            // Get start of 7 days ago (midnight)
            let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            print("⏰ Week timeframe: \(sevenDaysAgo) to \(now)")
            return sevenDaysAgo
        case .month:
            let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            print("⏰ Month timeframe: \(oneMonthAgo) to \(now)")
            return oneMonthAgo
        case .threeMonths:
            let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now) ?? now
            print("⏰ Three months timeframe: \(threeMonthsAgo) to \(now)")
            return threeMonthsAgo
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: now) ?? now
        case .all:
            return Date.distantPast
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let workoutSaved = Notification.Name("workoutSaved")
}
