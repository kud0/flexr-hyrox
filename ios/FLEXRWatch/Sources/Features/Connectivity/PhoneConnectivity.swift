import Foundation
import Combine
import WatchConnectivity

class PhoneConnectivity: NSObject, ObservableObject {
    static let shared = PhoneConnectivity()

    @Published var isReachable = false
    @Published var receivedWorkout: ReceivedWorkout?
    @Published var lastSyncDate: Date?

    private var session: WCSession?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
        }
    }

    // MARK: - Session Management

    func activateSession() {
        session?.activate()
    }

    // MARK: - Sending Data to iPhone

    /// Send live workout metrics during active workout
    func sendLiveMetrics(_ metrics: LiveWorkoutMetrics) {
        guard let session = session, session.isReachable else {
            print("⚠️ iPhone not reachable - queuing metrics")
            queueMetricsForLater(metrics)
            return
        }

        do {
            let data = try encoder.encode(metrics)
            let message: [String: Any] = [
                "type": "liveMetrics",
                "data": data
            ]

            session.sendMessage(message, replyHandler: nil) { error in
                print("❌ Failed to send live metrics: \(error.localizedDescription)")
            }
        } catch {
            print("❌ Failed to encode live metrics: \(error)")
        }
    }

    /// Send segment completion update
    func sendSegmentCompletion(_ completion: SegmentCompletion) {
        guard let session = session else { return }

        do {
            let data = try encoder.encode(completion)
            let message: [String: Any] = [
                "type": "segmentComplete",
                "data": data
            ]

            if session.isReachable {
                session.sendMessage(message, replyHandler: nil) { error in
                    print("❌ Failed to send segment completion: \(error.localizedDescription)")
                }
            } else {
                // Use background transfer for non-reachable state
                session.transferUserInfo(message)
            }
        } catch {
            print("❌ Failed to encode segment completion: \(error)")
        }
    }

    /// Send final workout summary
    func sendWorkoutSummary(_ summary: WorkoutSummary) {
        guard let session = session else { return }

        do {
            let data = try encoder.encode(summary)
            let message: [String: Any] = [
                "type": "workoutSummary",
                "data": data,
                "timestamp": Date().timeIntervalSince1970
            ]

            // Always use background transfer for summary to ensure delivery
            session.transferUserInfo(message)
            print("✅ Workout summary queued for transfer")
        } catch {
            print("❌ Failed to encode workout summary: \(error)")
        }
    }

    /// Send heart rate alert
    func sendHeartRateAlert(currentHR: Int, threshold: Int) {
        guard let session = session, session.isReachable else { return }

        let message: [String: Any] = [
            "type": "heartRateAlert",
            "currentHR": currentHR,
            "threshold": threshold,
            "timestamp": Date().timeIntervalSince1970
        ]

        session.sendMessage(message, replyHandler: nil)
    }

    // MARK: - Receiving Data from iPhone

    private func handleIncomingMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else { return }

        switch type {
        case "workout":
            handleWorkoutReceived(message)
        case "workoutStart":
            handleWorkoutStartCommand(message)
        case "workoutPause":
            handleWorkoutPauseCommand()
        case "workoutResume":
            handleWorkoutResumeCommand()
        case "workoutStop":
            handleWorkoutStopCommand()
        case "settings":
            handleSettingsUpdate(message)
        case "userId":
            handleUserIdSync(message)
        default:
            print("⚠️ Unknown message type: \(type)")
        }
    }

    private func handleUserIdSync(_ message: [String: Any]) {
        guard let userIdString = message["userId"] as? String,
              let userId = UUID(uuidString: userIdString) else {
            print("❌ Invalid userId in sync message")
            return
        }

        DispatchQueue.main.async {
            WatchPlanService.shared.setUserId(userId)
            print("✅ Synced userId from iPhone: \(userId)")

            // Fetch workouts now that we have userId
            Task {
                await WatchPlanService.shared.fetchTodaysWorkouts()
            }
        }
    }

    private func handleWorkoutReceived(_ message: [String: Any]) {
        guard let data = message["data"] as? Data else { return }

        do {
            let workout = try decoder.decode(ReceivedWorkout.self, from: data)
            DispatchQueue.main.async {
                self.receivedWorkout = workout
                print("✅ Received workout: \(workout.name)")
            }
        } catch {
            print("❌ Failed to decode workout: \(error)")
        }
    }

    private func handleWorkoutStartCommand(_ message: [String: Any]) {
        // Notify workout manager to start
        NotificationCenter.default.post(name: .workoutStartCommand, object: message)
    }

    private func handleWorkoutPauseCommand() {
        NotificationCenter.default.post(name: .workoutPauseCommand, object: nil)
    }

    private func handleWorkoutResumeCommand() {
        NotificationCenter.default.post(name: .workoutResumeCommand, object: nil)
    }

    private func handleWorkoutStopCommand() {
        NotificationCenter.default.post(name: .workoutStopCommand, object: nil)
    }

    private func handleSettingsUpdate(_ message: [String: Any]) {
        // Handle settings synchronization
        if let settings = message["data"] as? [String: Any] {
            NotificationCenter.default.post(
                name: .settingsUpdated,
                object: nil,
                userInfo: settings
            )
        }
    }

    // MARK: - Background Transfer Management

    private var metricsQueue: [LiveWorkoutMetrics] = []

    private func queueMetricsForLater(_ metrics: LiveWorkoutMetrics) {
        metricsQueue.append(metrics)

        // Keep only last 100 metrics to avoid memory issues
        if metricsQueue.count > 100 {
            metricsQueue.removeFirst(metricsQueue.count - 100)
        }
    }

    private func flushQueuedMetrics() {
        guard !metricsQueue.isEmpty else { return }

        do {
            let data = try encoder.encode(metricsQueue)
            let message: [String: Any] = [
                "type": "queuedMetrics",
                "data": data,
                "count": metricsQueue.count
            ]

            session?.transferUserInfo(message)
            metricsQueue.removeAll()
            print("✅ Flushed \(metricsQueue.count) queued metrics")
        } catch {
            print("❌ Failed to flush queued metrics: \(error)")
        }
    }

    // MARK: - Application Context Sync

    func syncApplicationContext() {
        guard let session = session else { return }

        let context: [String: Any] = [
            "watchAppVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            "lastSyncDate": Date().timeIntervalSince1970,
            "hasActiveWorkout": false // Update based on actual state
        ]

        do {
            try session.updateApplicationContext(context)
            DispatchQueue.main.async {
                self.lastSyncDate = Date()
            }
        } catch {
            print("❌ Failed to update application context: \(error)")
        }
    }
}

// MARK: - WCSessionDelegate
extension PhoneConnectivity: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable

            if let error = error {
                print("❌ Session activation failed: \(error.localizedDescription)")
            } else {
                print("✅ WatchConnectivity session activated: \(activationState.rawValue)")
                self.syncApplicationContext()
            }
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            print("📱 iPhone reachability: \(session.isReachable)")

            // Flush queued metrics when reachable
            if session.isReachable {
                self.flushQueuedMetrics()
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleIncomingMessage(message)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        handleIncomingMessage(message)
        replyHandler(["status": "received"])
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        handleIncomingMessage(userInfo)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        // Handle application context updates from iPhone
        print("📲 Received application context: \(applicationContext)")
    }
}

// MARK: - Supporting Types

struct ReceivedWorkout: Codable {
    let id: UUID
    let name: String
    let type: String
    let segments: [WorkoutSegment]
    let estimatedDuration: TimeInterval

    init(id: UUID = UUID(), name: String, type: String, segments: [WorkoutSegment], estimatedDuration: TimeInterval) {
        self.id = id
        self.name = name
        self.type = type
        self.segments = segments
        self.estimatedDuration = estimatedDuration
    }
}

struct LiveWorkoutMetrics: Codable {
    let timestamp: Date
    let currentSegmentIndex: Int
    let segmentElapsed: TimeInterval
    let totalElapsed: TimeInterval
    let heartRate: Int
    let pace: Double?
    let distance: Double?
    let reps: Int?

    init(
        timestamp: Date = Date(),
        currentSegmentIndex: Int,
        segmentElapsed: TimeInterval,
        totalElapsed: TimeInterval,
        heartRate: Int,
        pace: Double? = nil,
        distance: Double? = nil,
        reps: Int? = nil
    ) {
        self.timestamp = timestamp
        self.currentSegmentIndex = currentSegmentIndex
        self.segmentElapsed = segmentElapsed
        self.totalElapsed = totalElapsed
        self.heartRate = heartRate
        self.pace = pace
        self.distance = distance
        self.reps = reps
    }
}

struct SegmentCompletion: Codable {
    let segmentIndex: Int
    let segmentName: String
    let completionTime: TimeInterval
    let averageHeartRate: Int
    let maxHeartRate: Int
    let timestamp: Date

    init(
        segmentIndex: Int,
        segmentName: String,
        completionTime: TimeInterval,
        averageHeartRate: Int,
        maxHeartRate: Int,
        timestamp: Date = Date()
    ) {
        self.segmentIndex = segmentIndex
        self.segmentName = segmentName
        self.completionTime = completionTime
        self.averageHeartRate = averageHeartRate
        self.maxHeartRate = maxHeartRate
        self.timestamp = timestamp
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let workoutStartCommand = Notification.Name("workoutStartCommand")
    static let workoutPauseCommand = Notification.Name("workoutPauseCommand")
    static let workoutResumeCommand = Notification.Name("workoutResumeCommand")
    static let workoutStopCommand = Notification.Name("workoutStopCommand")
    static let settingsUpdated = Notification.Name("settingsUpdated")
}
