import Foundation
import HealthKit
import Combine

@MainActor
class HealthKitService: ObservableObject {
    static let shared = HealthKitService()
    let healthStore = HKHealthStore()

    @Published var isAuthorized = false
    @Published var currentHeartRate: Double?
    @Published var restingHeartRate: Double?
    @Published var heartRateVariability: Double?
    @Published var vo2Max: Double?
    @Published var sleepAnalysis: SleepData?
    @Published var weeklySleepData: [DailySleepData] = []
    @Published var steps: Int = 0

    // Weekly training stats from HealthKit
    @Published var weeklyTrainingMinutes: Int = 0
    @Published var weeklyTrainingSessions: Int = 0

    private var heartRateQuery: HKAnchoredObjectQuery?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Authorization

    /// Check if HealthKit authorization has been granted for workouts
    func checkAuthorizationStatus() -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("⚠️ HealthKit is not available on this device")
            isAuthorized = false
            return false
        }

        let workoutType = HKObjectType.workoutType()
        let status = healthStore.authorizationStatus(for: workoutType)

        let authorized = status == .sharingAuthorized
        print("🔐 HealthKit authorization status: \(status.rawValue) - \(authorized ? "Authorized" : "Not authorized")")

        // Update the published property
        isAuthorized = authorized

        return authorized
    }

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("⚠️ HealthKit is not available on this device")
            return
        }

        print("📱 Requesting HealthKit authorization...")

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .vo2Max)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .runningSpeed)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.workoutType()
        ]

        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.workoutType()
        ]

        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            isAuthorized = true
            print("✅ HealthKit authorization granted")
            await loadBaselineMetrics()
        } catch {
            print("❌ HealthKit authorization failed: \(error.localizedDescription)")
            isAuthorized = false
        }
    }

    // MARK: - Read Data

    func loadBaselineMetrics() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchRestingHeartRate() }
            group.addTask { await self.fetchHeartRateVariability() }
            group.addTask { await self.fetchVO2Max() }
            group.addTask { await self.fetchSleepData() }
            group.addTask { await self.fetchWeeklySleepData() }
            group.addTask { await self.fetchSteps() }
            group.addTask { await self.fetchWeeklyTrainingStats() }
        }
    }

    private func fetchRestingHeartRate() async {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else { return }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, error in
            guard let self = self,
                  let sample = samples?.first as? HKQuantitySample else { return }

            let bpm = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))

            Task { @MainActor in
                self.restingHeartRate = bpm
            }
        }

        healthStore.execute(query)
    }

    private func fetchHeartRateVariability() async {
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: hrvType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, error in
            guard let self = self,
                  let sample = samples?.first as? HKQuantitySample else { return }

            let ms = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))

            Task { @MainActor in
                self.heartRateVariability = ms
            }
        }

        healthStore.execute(query)
    }

    private func fetchVO2Max() async {
        guard let vo2MaxType = HKObjectType.quantityType(forIdentifier: .vo2Max) else { return }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: vo2MaxType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, error in
            guard let self = self,
                  let sample = samples?.first as? HKQuantitySample else { return }

            let vo2 = sample.quantity.doubleValue(for: HKUnit.literUnit(with: .milli).unitDivided(by: .gramUnit(with: .kilo).unitMultiplied(by: .minute())))

            Task { @MainActor in
                self.vo2Max = vo2
            }
        }

        healthStore.execute(query)
    }

    private func fetchSleepData() async {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -1, to: endDate)!

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, error in
            guard let samples = samples as? [HKCategorySample] else { return }

            let sleepData = Self.processSleepSamples(samples)

            Task { @MainActor in
                self?.sleepAnalysis = sleepData
            }
        }

        healthStore.execute(query)
    }

    /// Fetch sleep data for the last 7 nights
    private func fetchWeeklySleepData() async {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { [weak self] _, samples, error in
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume()
                    return
                }

                let dailySleepData = Self.processWeeklySleepSamples(samples, calendar: calendar)

                Task { @MainActor in
                    self?.weeklySleepData = dailySleepData
                    continuation.resume()
                }
            }

            healthStore.execute(query)
        }
    }

    /// Process sleep samples into daily sleep data for the last 7 nights
    private nonisolated static func processWeeklySleepSamples(_ samples: [HKCategorySample], calendar: Calendar) -> [DailySleepData] {
        // Group samples by the night they belong to (sleep that ends on a given day belongs to the previous night)
        var dailyData: [Date: (total: [(Date, Date)], deep: [(Date, Date)], rem: [(Date, Date)])] = [:]

        for sample in samples {
            // Use the end date to determine which "night" this belongs to
            // Sleep ending at 7am on Tuesday belongs to "Monday night"
            let sleepNight = calendar.startOfDay(for: sample.endDate)
            let previousNight = calendar.date(byAdding: .day, value: -1, to: sleepNight) ?? sleepNight

            if dailyData[previousNight] == nil {
                dailyData[previousNight] = ([], [], [])
            }

            let interval = (sample.startDate, sample.endDate)

            switch sample.value {
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                 HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                dailyData[previousNight]?.total.append(interval)

            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                dailyData[previousNight]?.total.append(interval)
                dailyData[previousNight]?.deep.append(interval)

            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                dailyData[previousNight]?.total.append(interval)
                dailyData[previousNight]?.rem.append(interval)

            default:
                break
            }
        }

        // Convert to DailySleepData array
        var result: [DailySleepData] = []
        let today = calendar.startOfDay(for: Date())

        for dayOffset in 0..<7 {
            guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset - 1, to: today) else { continue }

            let dayOfWeek = calendar.component(.weekday, from: targetDate)
            let dayName = calendar.shortWeekdaySymbols[dayOfWeek - 1]

            if let data = dailyData[targetDate] {
                let totalSeconds = mergeAndCalculateDuration(data.total)
                let deepSeconds = mergeAndCalculateDuration(data.deep)
                let remSeconds = mergeAndCalculateDuration(data.rem)

                let quality = calculateSleepQuality(total: totalSeconds, deep: deepSeconds, rem: remSeconds)

                result.append(DailySleepData(
                    date: targetDate,
                    dayName: dayName,
                    totalHours: totalSeconds / 3600.0,
                    deepHours: deepSeconds / 3600.0,
                    remHours: remSeconds / 3600.0,
                    quality: Int(quality)
                ))
            } else {
                // No data for this night
                result.append(DailySleepData(
                    date: targetDate,
                    dayName: dayName,
                    totalHours: 0,
                    deepHours: 0,
                    remHours: 0,
                    quality: 0
                ))
            }
        }

        // Return in chronological order (oldest first)
        return result.reversed()
    }

    private func fetchSteps() async {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }

        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, statistics, error in
            guard let self = self,
                  let sum = statistics?.sumQuantity() else { return }

            let stepCount = Int(sum.doubleValue(for: HKUnit.count()))

            Task { @MainActor in
                self.steps = stepCount
            }
        }

        healthStore.execute(query)
    }

    /// Fetch weekly training stats from HealthKit workouts
    /// Includes relevant workout types: Running, Functional Training, HIIT, Strength, etc.
    private func fetchWeeklyTrainingStats() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let workoutType = HKObjectType.workoutType()

        // Get start of current week (Monday)
        let calendar = Calendar.current
        let today = Date()
        var weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!

        // If system uses Sunday as first day, adjust to Monday
        if calendar.component(.weekday, from: weekStart) == 1 {
            weekStart = calendar.date(byAdding: .day, value: 1, to: weekStart)!
        }

        let predicate = HKQuery.predicateForSamples(withStart: weekStart, end: today, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { [weak self] _, samples, error in
                guard let self = self,
                      let workouts = samples as? [HKWorkout] else {
                    continuation.resume()
                    return
                }

                // Filter to relevant workout types for HYROX training
                let relevantTypes: [HKWorkoutActivityType] = [
                    .running,
                    .functionalStrengthTraining,
                    .highIntensityIntervalTraining,
                    .traditionalStrengthTraining,
                    .rowing,
                    .crossTraining,
                    .coreTraining,
                    .mixedCardio,
                    .cycling,            // SkiErg/bike
                    .elliptical,
                    .stairClimbing
                ]

                let relevantWorkouts = workouts.filter { relevantTypes.contains($0.workoutActivityType) }

                let totalMinutes = Int(relevantWorkouts.reduce(0.0) { $0 + $1.duration } / 60)
                let sessionCount = relevantWorkouts.count

                print("📊 HealthKit weekly stats: \(sessionCount) sessions, \(totalMinutes) minutes")

                Task { @MainActor in
                    self.weeklyTrainingMinutes = totalMinutes
                    self.weeklyTrainingSessions = sessionCount
                    continuation.resume()
                }
            }

            healthStore.execute(query)
        }
    }

    private nonisolated static func processSleepSamples(_ samples: [HKCategorySample]) -> SleepData {
        // Separate intervals by type
        var allSleepIntervals: [(start: Date, end: Date)] = []
        var deepSleepIntervals: [(start: Date, end: Date)] = []
        var remSleepIntervals: [(start: Date, end: Date)] = []

        for sample in samples {
            let interval = (start: sample.startDate, end: sample.endDate)

            switch sample.value {
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                 HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                allSleepIntervals.append(interval)

            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                allSleepIntervals.append(interval)
                deepSleepIntervals.append(interval)

            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                allSleepIntervals.append(interval)
                remSleepIntervals.append(interval)

            default:
                break
            }
        }

        // Merge overlapping intervals and calculate total duration
        let totalSleepSeconds = mergeAndCalculateDuration(allSleepIntervals)
        let deepSleepSeconds = mergeAndCalculateDuration(deepSleepIntervals)
        let remSleepSeconds = mergeAndCalculateDuration(remSleepIntervals)

        return SleepData(
            totalDuration: totalSleepSeconds,
            deepSleepDuration: deepSleepSeconds,
            remSleepDuration: remSleepSeconds,
            quality: Self.calculateSleepQuality(total: totalSleepSeconds, deep: deepSleepSeconds, rem: remSleepSeconds)
        )
    }

    /// Merge overlapping time intervals and return total duration in seconds
    private nonisolated static func mergeAndCalculateDuration(_ intervals: [(start: Date, end: Date)]) -> TimeInterval {
        guard !intervals.isEmpty else { return 0 }

        // Sort by start time
        let sorted = intervals.sorted { $0.start < $1.start }

        var merged: [(start: Date, end: Date)] = []
        var current = sorted[0]

        for interval in sorted.dropFirst() {
            if interval.start <= current.end {
                // Overlapping - extend current interval
                current.end = max(current.end, interval.end)
            } else {
                // Non-overlapping - save current and start new
                merged.append(current)
                current = interval
            }
        }
        merged.append(current)

        // Calculate total duration from merged intervals
        return merged.reduce(0) { total, interval in
            total + interval.end.timeIntervalSince(interval.start)
        }
    }

    private nonisolated static func calculateSleepQuality(total: TimeInterval, deep: TimeInterval, rem: TimeInterval) -> Double {
        // Quality score based on:
        // - Total sleep (7-9 hours optimal)
        // - Deep sleep (13-23% of total)
        // - REM sleep (20-25% of total)

        let totalHours = total / 3600
        let totalScore = min(1.0, max(0.0, 1.0 - abs(totalHours - 8) / 8))

        let deepPercentage = total > 0 ? (deep / total) * 100 : 0
        let deepScore = deepPercentage >= 13 && deepPercentage <= 23 ? 1.0 : 0.5

        let remPercentage = total > 0 ? (rem / total) * 100 : 0
        let remScore = remPercentage >= 20 && remPercentage <= 25 ? 1.0 : 0.5

        return (totalScore * 0.5 + deepScore * 0.25 + remScore * 0.25) * 100
    }

    // MARK: - Live Heart Rate Monitoring

    func startLiveHeartRateMonitoring() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }

        let datePredicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate)

        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: datePredicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, samples, deletedObjects, anchor, error in
            guard let bpm = Self.extractHeartRate(from: samples) else { return }
            Task { @MainActor in
                self?.currentHeartRate = bpm
            }
        }

        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            guard let bpm = Self.extractHeartRate(from: samples) else { return }
            Task { @MainActor in
                self?.currentHeartRate = bpm
            }
        }

        heartRateQuery = query
        healthStore.execute(query)
    }

    func stopLiveHeartRateMonitoring() {
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
        }
    }

    private nonisolated static func extractHeartRate(from samples: [HKSample]?) -> Double? {
        guard let samples = samples as? [HKQuantitySample],
              let sample = samples.last else { return nil }

        return sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
    }

    // MARK: - Write Workout Data

    func saveWorkout(_ workout: Workout) async throws {
        guard let startTime = workout.segments.first?.startTime,
              let endTime = workout.segments.last?.endTime else {
            throw HealthKitError.invalidWorkoutData
        }

        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .functionalStrengthTraining
        workoutConfiguration.locationType = .indoor

        let hkWorkout = HKWorkout(
            activityType: .functionalStrengthTraining,
            start: startTime,
            end: endTime,
            duration: workout.actualDuration,
            totalEnergyBurned: workout.estimatedCalories.map {
                HKQuantity(unit: .kilocalorie(), doubleValue: Double($0))
            },
            totalDistance: workout.totalDistance > 0 ? HKQuantity(unit: .meter(), doubleValue: workout.totalDistance) : nil,
            metadata: [
                HKMetadataKeyIndoorWorkout: true,
                "WorkoutType": workout.type.rawValue
            ]
        )

        try await healthStore.save(hkWorkout)

        // Save workout samples (HR, distance, etc.)
        try await saveWorkoutSamples(for: hkWorkout, workout: workout)
    }

    private func saveWorkoutSamples(for hkWorkout: HKWorkout, workout: Workout) async throws {
        var samples: [HKSample] = []

        // Add heart rate samples
        if let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            for segment in workout.segments where segment.avgHeartRate != nil {
                if let startTime = segment.startTime, let endTime = segment.endTime, let hr = segment.avgHeartRate {
                    let quantity = HKQuantity(unit: .count().unitDivided(by: .minute()), doubleValue: hr)
                    let sample = HKQuantitySample(
                        type: heartRateType,
                        quantity: quantity,
                        start: startTime,
                        end: endTime
                    )
                    samples.append(sample)
                }
            }
        }

        // Add distance samples for runs
        if let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
            for segment in workout.runSegments where segment.actualDistance != nil {
                if let startTime = segment.startTime, let endTime = segment.endTime, let distance = segment.actualDistance {
                    let quantity = HKQuantity(unit: .meter(), doubleValue: distance)
                    let sample = HKQuantitySample(
                        type: distanceType,
                        quantity: quantity,
                        start: startTime,
                        end: endTime
                    )
                    samples.append(sample)
                }
            }
        }

        if !samples.isEmpty {
            try await healthStore.save(samples)
        }
    }

    // MARK: - Readiness Score

    func calculateReadinessScore() -> Int {
        var score = 50 // Base score

        // HRV contribution (0-25 points)
        if let hrv = heartRateVariability {
            let hrvScore = min(25, max(0, Int((hrv / 100) * 25)))
            score += hrvScore
        }

        // Sleep contribution (0-25 points)
        if let sleep = sleepAnalysis {
            score += Int(sleep.quality / 4)
        }

        // Resting HR contribution (0-10 points)
        if let rhr = restingHeartRate {
            // Lower RHR is better
            let normalizedRHR = max(0, min(100, 100 - Int(rhr - 40)))
            score += normalizedRHR / 10
        }

        return min(100, max(0, score))
    }
}

// MARK: - Supporting Types

struct SleepData {
    let totalDuration: TimeInterval
    let deepSleepDuration: TimeInterval
    let remSleepDuration: TimeInterval
    let quality: Double // 0-100

    var formattedTotal: String {
        let hours = Int(totalDuration / 3600)
        let minutes = Int((totalDuration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
}

/// Daily sleep data for 7-night analysis
struct DailySleepData: Identifiable {
    let id = UUID()
    let date: Date
    let dayName: String
    let totalHours: Double
    let deepHours: Double
    let remHours: Double
    let quality: Int  // 0-100

    var formattedTotal: String {
        String(format: "%.1fh", totalHours)
    }

    var formattedDeep: String {
        String(format: "%.1fh", deepHours)
    }

    var formattedRem: String {
        String(format: "%.1fh", remHours)
    }

    var qualityColor: String {
        if quality >= 85 { return "green" }
        if quality >= 70 { return "yellow" }
        return "red"
    }
}

enum HealthKitError: LocalizedError {
    case notAvailable
    case notAuthorized
    case invalidWorkoutData

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .notAuthorized:
            return "HealthKit authorization required"
        case .invalidWorkoutData:
            return "Invalid workout data"
        }
    }
}

// MARK: - Fetch Workouts for Analytics
extension HealthKitService {
    /// Fetch recent workouts from HealthKit and save to Core Data
    func syncWorkoutsToAnalytics(daysBack: Int = 30) async {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("⚠️ HealthKit not available - skipping workout sync")
            return
        }

        // Check authorization status
        if !checkAuthorizationStatus() {
            print("⚠️ HealthKit not authorized - requesting authorization...")
            await requestAuthorization()

            // Check again after requesting
            if !checkAuthorizationStatus() {
                print("❌ HealthKit authorization denied - cannot sync workouts")
                return
            }
        }

        print("🔄 Starting HealthKit workout sync (last \(daysBack) days)...")

        let workoutType = HKObjectType.workoutType()
        let startDate = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    print("❌ Failed to fetch workouts from HealthKit: \(error.localizedDescription)")
                    continuation.resume()
                    return
                }

                guard let workouts = samples as? [HKWorkout] else {
                    print("⚠️ No workouts found in HealthKit")
                    continuation.resume()
                    return
                }

                print("✅ Fetched \(workouts.count) workouts from HealthKit (types: \(Set(workouts.map { $0.workoutActivityType.rawValue })))")

                // Convert and save each workout WITHOUT triggering sync for each one
                Task {
                    // Week 3: Analytics service integration
                    // AnalyticsService.shared.removeDuplicateWorkouts()

                    print("✅ HealthKit workouts fetched: \(workouts.count)")
                    print("📝 Week 3: Analytics integration pending")
                    continuation.resume()
                }
            }

            healthStore.execute(query)
        }
    }

    private func convertHKWorkoutToSummary(_ workout: HKWorkout) -> WorkoutSummary {
        // Extract basic workout info
        let duration = workout.duration
        let distance = workout.totalDistance?.doubleValue(for: .meter()) ?? 0
        let calories = Int(workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0)

        // Try to get heart rate data from workout statistics
        var avgHR = 0
        var maxHR = 0

        if let avgHRQuantity = workout.statistics(for: HKQuantityType.quantityType(forIdentifier: .heartRate)!)?.averageQuantity() {
            avgHR = Int(avgHRQuantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
        }

        if let maxHRQuantity = workout.statistics(for: HKQuantityType.quantityType(forIdentifier: .heartRate)!)?.maximumQuantity() {
            maxHR = Int(maxHRQuantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
        }

        // Create a simplified workout summary
        return WorkoutSummary(
            id: UUID(),
            workoutName: workoutTypeName(workout.workoutActivityType),
            date: workout.startDate,
            totalTime: duration,
            segmentsCompleted: 1, // HealthKit workouts don't have segment info
            totalSegments: 1,
            averageHeartRate: avgHR,
            maxHeartRate: maxHR,
            activeCalories: calories,
            totalDistance: distance,
            compromisedRuns: [],
            segmentResults: []
        )
    }

    private func workoutTypeName(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .walking: return "Walking"
        case .functionalStrengthTraining: return "Strength Training"
        case .crossTraining: return "Cross Training"
        default: return "Workout"
        }
    }

    // MARK: - Fetch External Workouts

    /// Fetch all workouts from HealthKit (including external apps)
    /// Returns workouts that were NOT created by FLEXR
    func fetchExternalWorkouts(daysBack: Int = 30) async -> [ExternalWorkout] {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("⚠️ HealthKit not available")
            return []
        }

        if !checkAuthorizationStatus() {
            await requestAuthorization()
            if !checkAuthorizationStatus() {
                print("❌ HealthKit authorization denied")
                return []
            }
        }

        let workoutType = HKObjectType.workoutType()
        let startDate = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { [weak self] _, samples, error in
                if let error = error {
                    print("❌ Failed to fetch external workouts: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }

                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: [])
                    return
                }

                // Convert HKWorkout to ExternalWorkout, filtering out FLEXR workouts
                let externalWorkouts = workouts.compactMap { hkWorkout -> ExternalWorkout? in
                    self?.convertHKWorkoutToExternal(hkWorkout)
                }.filter { !$0.isFLEXRWorkout }

                print("✅ Fetched \(externalWorkouts.count) external workouts from HealthKit")
                continuation.resume(returning: externalWorkouts)
            }

            healthStore.execute(query)
        }
    }

    /// Fetch all workouts (FLEXR + external) for complete activity picture
    func fetchAllWorkouts(daysBack: Int = 30) async -> [ExternalWorkout] {
        guard HKHealthStore.isHealthDataAvailable() else {
            return []
        }

        if !checkAuthorizationStatus() {
            await requestAuthorization()
            if !checkAuthorizationStatus() {
                return []
            }
        }

        let workoutType = HKObjectType.workoutType()
        let startDate = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { [weak self] _, samples, error in
                if let error = error {
                    print("❌ Failed to fetch all workouts: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }

                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: [])
                    return
                }

                let allWorkouts = workouts.compactMap { hkWorkout -> ExternalWorkout? in
                    self?.convertHKWorkoutToExternal(hkWorkout)
                }

                print("✅ Fetched \(allWorkouts.count) total workouts from HealthKit")
                continuation.resume(returning: allWorkouts)
            }

            healthStore.execute(query)
        }
    }

    /// Convert HKWorkout to ExternalWorkout model
    private func convertHKWorkoutToExternal(_ workout: HKWorkout) -> ExternalWorkout {
        // Get source info
        let sourceName = workout.sourceRevision.source.name
        let sourceVersion = workout.sourceRevision.version

        // Determine workout source type
        let source: WorkoutSource
        let lowerName = sourceName.lowercased()
        if lowerName.contains("flexr") {
            source = .flexr
        } else if lowerName.contains("fitness") && lowerName.contains("apple") {
            source = .appleFitness
        } else if lowerName.contains("strava") {
            source = .strava
        } else if lowerName.contains("watch") {
            source = .appleWatch
        } else {
            source = .healthKit
        }

        // Extract metrics
        let distance = workout.totalDistance?.doubleValue(for: .meter())
        let activeCalories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie())

        // Heart rate from statistics
        var avgHR: Double? = nil
        var maxHR: Double? = nil
        if let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            if let avgQuantity = workout.statistics(for: hrType)?.averageQuantity() {
                avgHR = avgQuantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            }
            if let maxQuantity = workout.statistics(for: hrType)?.maximumQuantity() {
                maxHR = maxQuantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            }
        }

        // Calculate pace for running workouts
        var avgPace: Double? = nil
        if workout.workoutActivityType == .running, let dist = distance, dist > 0 {
            avgPace = (workout.duration / dist) * 1000 // seconds per km
        }

        return ExternalWorkout(
            id: UUID(),
            healthKitId: workout.uuid,
            date: workout.startDate,
            endDate: workout.endDate,
            activityType: ExternalActivityType.from(hkType: workout.workoutActivityType),
            source: source,
            sourceName: sourceName,
            sourceVersion: sourceVersion,
            duration: workout.duration,
            activeCalories: activeCalories,
            totalCalories: activeCalories, // Could add basal if needed
            distance: distance,
            averageHeartRate: avgHR,
            maxHeartRate: maxHR,
            averagePace: avgPace
        )
    }

    /// Get summary of external workouts
    func getExternalWorkoutsSummary(daysBack: Int = 30) async -> ExternalWorkoutsSummary {
        let workouts = await fetchExternalWorkouts(daysBack: daysBack)

        guard !workouts.isEmpty else {
            return .empty
        }

        let totalDuration = workouts.reduce(0) { $0 + $1.duration }
        let totalDistance = workouts.reduce(0.0) { $0 + ($1.distance ?? 0) }
        let totalCalories = workouts.reduce(0.0) { $0 + ($1.activeCalories ?? 0) }

        // Group by type
        var byType: [ExternalActivityType: Int] = [:]
        for workout in workouts {
            byType[workout.activityType, default: 0] += 1
        }

        // Group by source
        var bySource: [String: Int] = [:]
        for workout in workouts {
            bySource[workout.sourceName, default: 0] += 1
        }

        return ExternalWorkoutsSummary(
            totalWorkouts: workouts.count,
            totalDurationMinutes: Int(totalDuration / 60),
            totalDistanceKm: totalDistance / 1000,
            totalCalories: Int(totalCalories),
            workoutsByType: byType,
            workoutsBySource: bySource
        )
    }
}
