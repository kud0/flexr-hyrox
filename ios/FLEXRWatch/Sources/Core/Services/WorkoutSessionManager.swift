import Foundation
import Combine
import HealthKit
import CoreLocation
import WatchKit

class WorkoutSessionManager: NSObject, ObservableObject {
    // MARK: - Published Properties

    @Published var isWorkoutActive = false
    @Published var isPaused = false
    @Published var showCompleteSummary = false
    @Published var completedSummary: WorkoutCompleteSummary?
    @Published var currentSession: WatchWorkoutSession?
    @Published var currentHeartRate: Int = 0
    @Published var currentPace: String = "--:--"
    @Published var currentSplit: String = "--:--"
    @Published var currentReps: Int = 0
    @Published var currentDistance: Double = 0.0
    @Published var elapsedTime: TimeInterval = 0

    // MARK: - Private Properties

    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var locationManager: CLLocationManager?

    private var elapsedTimer: Timer?
    private var metricsTimer: Timer?

    // Heart rate query
    private var heartRateQuery: HKQuery?

    // Location tracking
    private var lastLocation: CLLocation?
    private var totalDistance: Double = 0.0

    // MARK: - Initialization

    override init() {
        super.init()
        setupLocationManager()
    }

    // MARK: - Authorization

    func requestAuthorization() {
        let typesToShare: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!
        ]

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.activitySummaryType()
        ]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if let error = error {
                print("❌ HealthKit authorization failed: \(error.localizedDescription)")
            } else {
                print("✅ HealthKit authorized: \(success)")
            }
        }
    }

    // MARK: - Workout Management

    func startWorkout(_ workout: ReceivedWorkout) {
        guard !isWorkoutActive else { return }

        // Create workout session
        let session = WatchWorkoutSession(
            workoutId: workout.id,
            workoutName: workout.name,
            segments: workout.segments
        )

        currentSession = session
        session.startSegment(at: 0)

        // Set shadow target for first segment (if available)
        setShadowTargetForCurrentSegment(session: session)

        // Start HealthKit workout session
        startHealthKitSession()

        // Start metrics collection
        startMetricsCollection()

        // Start elapsed timer
        startElapsedTimer()

        isWorkoutActive = true

        print("✅ Workout started: \(workout.name)")
    }

    func pauseWorkout() {
        guard isWorkoutActive, let session = currentSession else { return }

        session.isPaused = true
        isPaused = true
        workoutSession?.pause()
        stopElapsedTimer()

        print("⏸️ Workout paused")
    }

    func resumeWorkout() {
        guard isWorkoutActive, let session = currentSession else { return }

        session.isPaused = false
        isPaused = false
        workoutSession?.resume()
        startElapsedTimer()

        print("▶️ Workout resumed")
    }

    func togglePause() {
        if isPaused {
            resumeWorkout()
        } else {
            pauseWorkout()
        }
    }

    func endWorkout() {
        guard isWorkoutActive, let session = currentSession else { return }

        session.finishWorkout()

        // End HealthKit session
        endHealthKitSession()

        // Stop timers
        stopElapsedTimer()
        stopMetricsCollection()

        // Generate summary for watch display
        completedSummary = WorkoutCompleteSummary(from: session)
        showCompleteSummary = true

        // Generate and send summary to iPhone
        let summary = session.generateSummary()
        PhoneConnectivity.shared.sendWorkoutSummary(summary)

        isWorkoutActive = false

        print("✅ Workout ended")
    }

    func dismissCompleteSummary() {
        showCompleteSummary = false
        completedSummary = nil
        currentSession = nil

        print("✅ Summary dismissed")
    }

    // MARK: - Segment Management

    func completeCurrentSegment() {
        guard let session = currentSession else { return }

        session.completeCurrentSegment()

        // Send completion to iPhone
        if let segment = session.currentSegment {
            let completion = SegmentCompletion(
                segmentIndex: session.currentSegmentIndex,
                segmentName: segment.displayName,
                completionTime: session.segmentElapsedTime,
                averageHeartRate: session.averageHeartRate,
                maxHeartRate: session.maxHeartRate
            )
            PhoneConnectivity.shared.sendSegmentCompletion(completion)
        }
    }

    func startNextSegment() {
        guard let session = currentSession else { return }
        session.startNextSegment()
    }

    // MARK: - HealthKit Session Management

    private func startHealthKitSession() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .functionalStrengthTraining
        configuration.locationType = .outdoor

        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()

            session.delegate = self
            builder.delegate = self

            builder.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )

            self.workoutSession = session
            self.workoutBuilder = builder

            session.startActivity(with: Date())
            builder.beginCollection(withStart: Date()) { success, error in
                if let error = error {
                    print("❌ Failed to begin collection: \(error.localizedDescription)")
                }
            }

        } catch {
            print("❌ Failed to start workout session: \(error.localizedDescription)")
        }
    }

    private func endHealthKitSession() {
        guard let session = workoutSession,
              let builder = workoutBuilder else { return }

        session.end()
        builder.endCollection(withEnd: Date()) { success, error in
            if let error = error {
                print("❌ Failed to end collection: \(error.localizedDescription)")
                return
            }

            builder.finishWorkout { workout, error in
                if let error = error {
                    print("❌ Failed to finish workout: \(error.localizedDescription)")
                } else {
                    print("✅ Workout saved to HealthKit")
                }
            }
        }
    }

    // MARK: - Metrics Collection

    func startMetricsCollection() {
        // Start heart rate streaming
        startHeartRateQuery()

        // Start location tracking for runs
        startLocationTracking()

        // Send metrics to iPhone every 5 seconds
        metricsTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.sendLiveMetrics()
        }
    }

    func stopMetricsCollection() {
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
        }

        locationManager?.stopUpdatingLocation()
        metricsTimer?.invalidate()
        metricsTimer = nil
    }

    func refreshMetrics() {
        // Refresh current metrics when app becomes active
        if isWorkoutActive {
            sendLiveMetrics()
        }
    }

    // MARK: - Heart Rate Monitoring

    private func startHeartRateQuery() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: Date(),
            end: nil,
            options: .strictStartDate
        )

        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.handleHeartRateSamples(samples)
        }

        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.handleHeartRateSamples(samples)
        }

        heartRateQuery = query
        healthStore.execute(query)
    }

    private func handleHeartRateSamples(_ samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample],
              let sample = heartRateSamples.last else { return }

        let heartRate = Int(sample.quantity.doubleValue(for: HKUnit(from: "count/min")))

        DispatchQueue.main.async {
            self.currentHeartRate = heartRate
            self.currentSession?.updateHeartRate(heartRate)

            // Check for heart rate alerts
            if heartRate > 180 {
                PhoneConnectivity.shared.sendHeartRateAlert(
                    currentHR: heartRate,
                    threshold: 180
                )
            }
        }
    }

    // MARK: - Location Tracking

    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.activityType = .fitness
        locationManager?.requestWhenInUseAuthorization()
    }

    private func startLocationTracking() {
        guard let segment = currentSession?.currentSegment,
              segment.segmentType == .run else { return }

        locationManager?.startUpdatingLocation()
    }

    // MARK: - Elapsed Timer

    private func startElapsedTimer() {
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let session = self.currentSession else { return }

            DispatchQueue.main.async {
                self.elapsedTime = session.segmentElapsedTime

                // Update shadow runner position
                session.updateShadowRunner(elapsedSegmentTime: session.segmentElapsedTime)
            }
        }
    }

    private func stopElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = nil
    }

    // MARK: - Send Live Metrics

    private func sendLiveMetrics() {
        guard let session = currentSession else { return }

        let metrics = LiveWorkoutMetrics(
            currentSegmentIndex: session.currentSegmentIndex,
            segmentElapsed: session.segmentElapsedTime,
            totalElapsed: session.totalElapsedTime,
            heartRate: currentHeartRate,
            pace: session.currentSegment?.segmentType == .run ? session.currentPace : nil,
            distance: totalDistance,
            reps: currentReps
        )

        PhoneConnectivity.shared.sendLiveMetrics(metrics)
    }
}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutSessionManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            switch toState {
            case .running:
                print("✅ Workout session running")
            case .paused:
                print("⏸️ Workout session paused")
            case .ended:
                print("🏁 Workout session ended")
            default:
                break
            }
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("❌ Workout session failed: \(error.localizedDescription)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WorkoutSessionManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }

            if let statistics = workoutBuilder.statistics(for: quantityType) {
                updateMetrics(for: quantityType, statistics: statistics)
            }
        }
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Handle workout events if needed
    }

    private func updateMetrics(for type: HKQuantityType, statistics: HKStatistics) {
        DispatchQueue.main.async {
            switch type.identifier {
            case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
                let calories = Int(statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0)
                self.currentSession?.updateCalories(calories)

            case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
                let distance = statistics.sumQuantity()?.doubleValue(for: .meter()) ?? 0
                self.totalDistance = distance
                self.currentDistance = distance
                self.currentSession?.updateDistance(distance)

            default:
                break
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension WorkoutSessionManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last,
              let session = currentSession,
              session.currentSegment?.segmentType == .run else { return }

        // Filter out inaccurate GPS readings (horizontal accuracy > 50m)
        let accurateLocations = locations.filter { $0.horizontalAccuracy <= 50 && $0.horizontalAccuracy > 0 }

        // Store GPS coordinates for route tracking
        if !accurateLocations.isEmpty {
            session.routeCoordinates.append(contentsOf: accurateLocations)
        }

        if let lastLocation = lastLocation {
            let distance = location.distance(from: lastLocation)

            // Calculate pace (min/km)
            let timeInterval = location.timestamp.timeIntervalSince(lastLocation.timestamp)
            if timeInterval > 0 {
                let speed = distance / timeInterval // m/s
                let pace = speed > 0 ? (1000.0 / 60.0) / speed : 0 // min/km

                DispatchQueue.main.async {
                    self.currentPace = String(format: "%d:%02d", Int(pace), Int((pace - Double(Int(pace))) * 60))
                    self.currentSession?.updatePace(pace)
                }
            }
        }

        lastLocation = location
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location tracking failed: \(error.localizedDescription)")
    }

    // MARK: - Shadow Runner Helpers

    /// Sets shadow target time for the current segment
    /// Uses segment's target duration/distance to calculate expected time
    private func setShadowTargetForCurrentSegment(session: WatchWorkoutSession) {
        guard session.currentSegmentIndex < session.segments.count else { return }

        let segment = session.segments[session.currentSegmentIndex]

        // Calculate target time based on segment type
        var targetTime: TimeInterval?

        if segment.segmentType == .run {
            // For runs, calculate based on target distance and estimated pace
            if let targetDistance = segment.targetDistance {
                // Assume 5:00/km pace as default target (can be customized later)
                let targetPacePerKm: TimeInterval = 5.0 * 60 // 5 minutes per km
                targetTime = (targetDistance / 1000.0) * targetPacePerKm
            }
        } else {
            // For stations and other segments, use target duration
            targetTime = segment.targetDuration
        }

        // Set the shadow target
        if let targetTime = targetTime {
            session.setShadowTarget(targetTime)
            print("🎯 Shadow target set: \(Int(targetTime))s for \(segment.displayName)")
        }
    }
}
