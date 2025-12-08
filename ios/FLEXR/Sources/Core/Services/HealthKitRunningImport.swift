// FLEXR - HealthKit Running Import
// Automatically import running workouts from HealthKit
// Extracts detailed metrics: pace, splits, heart rate zones, elevation

import Foundation
import HealthKit

// MARK: - HealthKit Running Import Extension
extension HealthKitService {

    // MARK: - Import Running Workouts

    /// Import running workouts from HealthKit and save to Supabase
    /// - Parameters:
    ///   - daysBack: Number of days to look back (default: 30)
    ///   - gymId: Optional gym ID to associate with sessions
    func importRunningWorkouts(daysBack: Int = 30, gymId: UUID? = nil) async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        guard checkAuthorizationStatus() else {
            throw HealthKitError.notAuthorized
        }

        print("🏃 Starting HealthKit running import (last \(daysBack) days)...")

        // Query for running workouts
        let workoutType = HKObjectType.workoutType()
        let startDate = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)

        // Filter for running workouts only
        let runningPredicate = HKQuery.predicateForWorkouts(with: .running)
        let combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, runningPredicate])

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let workouts = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKWorkout], Error>) in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: combinedPredicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: [])
                    return
                }

                continuation.resume(returning: workouts)
            }

            healthStore.execute(query)
        }

        print("✅ Found \(workouts.count) running workouts in HealthKit")

        // Process each workout
        for workout in workouts {
            do {
                let runningSession = try await processRunningWorkout(workout, gymId: gymId)
                print("✅ Imported: \(runningSession.sessionType.displayName) - \(runningSession.displayDistance) in \(runningSession.displayDuration)")
            } catch {
                print("⚠️ Failed to import workout: \(error.localizedDescription)")
            }
        }

        print("✅ Running import complete - processed \(workouts.count) workouts")
    }

    // MARK: - Process Single Workout

    private func processRunningWorkout(_ workout: HKWorkout, gymId: UUID?) async throws -> RunningSession {
        // Extract basic metrics
        let distance = workout.totalDistance?.doubleValue(for: .meter()) ?? 0
        let duration = workout.duration

        // Determine session type based on distance and workout metadata
        let sessionType = determineSessionType(workout: workout, distance: distance)

        // Calculate pace
        let avgPacePerKm = duration / (distance / 1000.0)

        // Fetch detailed data concurrently
        async let splits = fetchSplits(for: workout)
        async let heartRateData = fetchHeartRateData(for: workout)
        async let elevationGain = fetchElevationGain(for: workout)

        let (splitsArray, hrData, elevation) = try await (splits, heartRateData, elevationGain)

        // Calculate pace metrics from splits
        let paceMetrics = calculatePaceMetrics(splits: splitsArray, avgPace: avgPacePerKm)

        // Create running session via service - use actual workout dates
        let supabaseService = SupabaseService.shared
        let runningSession = try await supabaseService.createRunningSession(
            sessionType: sessionType,
            distanceMeters: Int(distance),
            durationSeconds: duration,
            avgPacePerKm: avgPacePerKm,
            fastestKmPace: paceMetrics.fastest,
            slowestKmPace: paceMetrics.slowest,
            avgHeartRate: hrData.avgHR,
            maxHeartRate: hrData.maxHR,
            heartRateZones: hrData.zones,
            splits: splitsArray,
            routeData: nil, // TODO: Extract route data if available
            paceConsistency: paceMetrics.consistency,
            fadeFactor: paceMetrics.fadeFactor,
            elevationGainMeters: elevation,
            visibility: .gym,
            notes: "Imported from HealthKit",
            gymId: gymId,
            startedAt: workout.startDate,
            endedAt: workout.endDate
        )

        return runningSession
    }

    // MARK: - Determine Session Type

    private func determineSessionType(workout: HKWorkout, distance: Double) -> RunningSessionType {
        // Check workout metadata for session type hints
        if let metadata = workout.metadata {
            if let workoutName = metadata[HKMetadataKeyWorkoutBrandName] as? String {
                if workoutName.lowercased().contains("interval") {
                    return .intervals
                } else if workoutName.lowercased().contains("tempo") || workoutName.lowercased().contains("threshold") {
                    return .threshold
                }
            }
        }

        // Determine by distance
        let distanceKm = distance / 1000.0

        if distanceKm >= 4.9 && distanceKm <= 5.1 {
            return .timeTrial5k
        } else if distanceKm >= 9.9 && distanceKm <= 10.1 {
            return .timeTrial10k
        } else if distanceKm > 15 {
            return .longRun
        } else if workout.duration < 1800 { // < 30 minutes
            return .easy
        } else {
            return .longRun
        }
    }

    // MARK: - Fetch Splits

    private func fetchSplits(for workout: HKWorkout) async throws -> [Split] {
        // First, try to get lap/segment events from workout (user-created or auto-splits)
        let lapSplits = Self.extractSplitsFromWorkoutEvents(workout)
        if !lapSplits.isEmpty {
            print("✅ Found \(lapSplits.count) lap splits from workout events")
            return lapSplits
        }

        // Fallback: Calculate splits from total distance/time
        // This gives us estimated even splits based on average pace
        let totalDistance = workout.totalDistance?.doubleValue(for: .meter()) ?? 0
        let totalDuration = workout.duration

        guard totalDistance > 0, totalDuration > 0 else { return [] }

        let avgPacePerKm = totalDuration / (totalDistance / 1000.0)
        let totalKms = Int(totalDistance / 1000)

        var splits: [Split] = []
        for km in 1...totalKms {
            splits.append(Split(
                km: km,
                timeSeconds: avgPacePerKm,
                pacePerKm: avgPacePerKm,
                heartRate: nil,
                elevationGain: nil
            ))
        }

        print("⚠️ No lap events found, generated \(splits.count) estimated splits at \(Self.formatPace(avgPacePerKm))/km")
        return splits
    }

    /// Extract splits from HKWorkout segment/lap events
    private static func extractSplitsFromWorkoutEvents(_ workout: HKWorkout) -> [Split] {
        // Get workout events (laps, segments, markers)
        guard let events = workout.workoutEvents, !events.isEmpty else {
            return []
        }

        var splits: [Split] = []
        var segmentStart = workout.startDate
        var kmNumber = 1

        // Filter for lap/segment events
        let lapEvents = events.filter { event in
            event.type == .lap || event.type == .segment
        }.sorted { $0.dateInterval.start < $1.dateInterval.start }

        for event in lapEvents {
            let segmentEnd = event.dateInterval.start
            let segmentDuration = segmentEnd.timeIntervalSince(segmentStart)

            // Get distance for this segment if available from metadata
            // For now, assume 1km per lap (Apple Watch default for running)
            let segmentDistanceKm = 1.0

            // Pace = time / distance (seconds per km)
            let pacePerKm = segmentDuration / segmentDistanceKm

            // Only add if pace is reasonable (2:00 - 15:00 per km)
            if pacePerKm >= 120 && pacePerKm <= 900 {
                splits.append(Split(
                    km: kmNumber,
                    timeSeconds: segmentDuration,
                    pacePerKm: pacePerKm,
                    heartRate: nil,
                    elevationGain: nil
                ))
                kmNumber += 1
            }

            segmentStart = segmentEnd
        }

        return splits
    }

    private static func formatPace(_ secondsPerKm: TimeInterval) -> String {
        let mins = Int(secondsPerKm) / 60
        let secs = Int(secondsPerKm) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    // MARK: - Fetch Heart Rate Data

    private func fetchHeartRateData(for workout: HKWorkout) async throws -> HeartRateData {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return HeartRateData(avgHR: nil, maxHR: nil, zones: nil)
        }

        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)

        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Error>) in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let samples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }

                continuation.resume(returning: samples)
            }

            healthStore.execute(query)
        }

        guard !samples.isEmpty else {
            return HeartRateData(avgHR: nil, maxHR: nil, zones: nil)
        }

        // Calculate average and max
        let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
        let heartRates = samples.map { $0.quantity.doubleValue(for: heartRateUnit) }
        let avgHR = Int(heartRates.reduce(0, +) / Double(heartRates.count))
        let maxHR = Int(heartRates.max() ?? 0)

        // Calculate heart rate zones (assuming max HR of 190 as baseline)
        let zones = Self.calculateHeartRateZones(samples: samples, maxHR: maxHR)

        return HeartRateData(avgHR: avgHR, maxHR: maxHR, zones: zones)
    }

    private static func calculateHeartRateZones(samples: [HKQuantitySample], maxHR: Int) -> HeartRateZones? {
        guard !samples.isEmpty else { return nil }

        var zone1Duration: TimeInterval = 0
        var zone2Duration: TimeInterval = 0
        var zone3Duration: TimeInterval = 0
        var zone4Duration: TimeInterval = 0
        var zone5Duration: TimeInterval = 0

        for sample in samples {
            let hr = sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
            let duration = sample.endDate.timeIntervalSince(sample.startDate)
            let percentMax = hr / Double(maxHR)

            // Zone classification based on % of max HR
            if percentMax < 0.6 {
                zone1Duration += duration // Recovery
            } else if percentMax < 0.7 {
                zone2Duration += duration // Aerobic
            } else if percentMax < 0.8 {
                zone3Duration += duration // Tempo
            } else if percentMax < 0.9 {
                zone4Duration += duration // Threshold
            } else {
                zone5Duration += duration // Max
            }
        }

        return HeartRateZones(
            zone1Seconds: zone1Duration,
            zone2Seconds: zone2Duration,
            zone3Seconds: zone3Duration,
            zone4Seconds: zone4Duration,
            zone5Seconds: zone5Duration
        )
    }

    // MARK: - Fetch Elevation

    private func fetchElevationGain(for workout: HKWorkout) async throws -> Int? {
        // Note: HealthKit doesn't directly provide elevation gain
        // This would require route data processing
        // For now, return nil - can be enhanced later
        return nil
    }

    // MARK: - Calculate Pace Metrics

    private func calculatePaceMetrics(splits: [Split], avgPace: TimeInterval) -> PaceMetrics {
        guard !splits.isEmpty else {
            return PaceMetrics(fastest: nil, slowest: nil, consistency: nil, fadeFactor: nil)
        }

        let paces = splits.map { $0.pacePerKm }
        let fastest = paces.min()
        let slowest = paces.max()

        // Pace consistency: coefficient of variation (lower is better)
        let mean = avgPace
        let variance = paces.reduce(0.0) { $0 + pow($1 - mean, 2) } / Double(paces.count)
        let stdDev = sqrt(variance)
        let consistency = (stdDev / mean) * 100 // as percentage

        // Fade factor: compare first half pace to second half pace
        let halfwayIndex = splits.count / 2
        let firstHalfPace = splits[..<halfwayIndex].map { $0.pacePerKm }.reduce(0, +) / Double(halfwayIndex)
        let secondHalfPace = splits[halfwayIndex...].map { $0.pacePerKm }.reduce(0, +) / Double(splits.count - halfwayIndex)

        // Positive fade factor = slowed down (bad)
        // Negative fade factor = sped up (negative split, good!)
        let fadeFactor = ((secondHalfPace - firstHalfPace) / firstHalfPace) * 100

        return PaceMetrics(
            fastest: fastest,
            slowest: slowest,
            consistency: consistency,
            fadeFactor: fadeFactor
        )
    }
}

// MARK: - Supporting Types

private struct HeartRateData {
    let avgHR: Int?
    let maxHR: Int?
    let zones: HeartRateZones?
}

private struct PaceMetrics {
    let fastest: TimeInterval?
    let slowest: TimeInterval?
    let consistency: Double?
    let fadeFactor: Double?
}
