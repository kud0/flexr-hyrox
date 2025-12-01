import Foundation
import HealthKit
import Combine

@MainActor
class HealthKitService: ObservableObject {
    private let healthStore = HKHealthStore()

    @Published var isAuthorized = false
    @Published var currentHeartRate: Double?
    @Published var restingHeartRate: Double?
    @Published var heartRateVariability: Double?
    @Published var vo2Max: Double?
    @Published var sleepAnalysis: SleepData?

    private var heartRateQuery: HKAnchoredObjectQuery?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Authorization

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .vo2Max)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .runningSpeed)!,
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
            await loadBaselineMetrics()
        } catch {
            print("HealthKit authorization failed: \(error.localizedDescription)")
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
            guard let self = self,
                  let samples = samples as? [HKCategorySample] else { return }

            let sleepData = self.processSleepSamples(samples)

            Task { @MainActor in
                self.sleepAnalysis = sleepData
            }
        }

        healthStore.execute(query)
    }

    private func processSleepSamples(_ samples: [HKCategorySample]) -> SleepData {
        var totalSleepSeconds: TimeInterval = 0
        var deepSleepSeconds: TimeInterval = 0
        var remSleepSeconds: TimeInterval = 0

        for sample in samples {
            let duration = sample.endDate.timeIntervalSince(sample.startDate)

            switch sample.value {
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                 HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                totalSleepSeconds += duration

            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                totalSleepSeconds += duration
                deepSleepSeconds += duration

            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                totalSleepSeconds += duration
                remSleepSeconds += duration

            default:
                break
            }
        }

        return SleepData(
            totalDuration: totalSleepSeconds,
            deepSleepDuration: deepSleepSeconds,
            remSleepDuration: remSleepSeconds,
            quality: calculateSleepQuality(total: totalSleepSeconds, deep: deepSleepSeconds, rem: remSleepSeconds)
        )
    }

    private func calculateSleepQuality(total: TimeInterval, deep: TimeInterval, rem: TimeInterval) -> Double {
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
            self?.processHeartRateSamples(samples)
        }

        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHeartRateSamples(samples)
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

    private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample],
              let sample = samples.last else { return }

        let bpm = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))

        Task { @MainActor in
            self.currentHeartRate = bpm
        }
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
