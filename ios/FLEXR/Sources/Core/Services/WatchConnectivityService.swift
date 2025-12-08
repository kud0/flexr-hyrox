// FLEXR - iOS Watch Connectivity Service
// Handles communication with Apple Watch app

import Foundation
import WatchConnectivity

@MainActor
class WatchConnectivityService: NSObject, ObservableObject {
    static let shared = WatchConnectivityService()

    @Published var isWatchAppInstalled = false
    @Published var isReachable = false
    @Published var isPaired = false

    private var session: WCSession?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    override init() {
        super.init()
        setupSession()
    }

    // MARK: - Session Setup

    private func setupSession() {
        guard WCSession.isSupported() else {
            print("WatchConnectivity: Not supported on this device")
            return
        }

        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    // MARK: - Send User ID to Watch

    /// Sends the user ID to the Watch so it can fetch workouts from Supabase
    func sendUserIdToWatch(_ userId: UUID) {
        guard let session = session else {
            print("WatchConnectivity: No session available")
            return
        }

        guard session.activationState == .activated else {
            print("WatchConnectivity: Session not activated")
            return
        }

        let message: [String: Any] = [
            "type": "userId",
            "userId": userId.uuidString
        ]

        // Try interactive message first (faster)
        if session.isReachable {
            session.sendMessage(message, replyHandler: { response in
                print("WatchConnectivity: userId sent successfully, response: \(response)")
            }, errorHandler: { error in
                print("WatchConnectivity: Failed to send userId via message: \(error)")
                // Fall back to application context
                self.sendViaApplicationContext(message)
            })
        } else {
            // Use application context for background delivery
            sendViaApplicationContext(message)
        }
    }

    private func sendViaApplicationContext(_ data: [String: Any]) {
        guard let session = session else { return }

        do {
            try session.updateApplicationContext(data)
            print("WatchConnectivity: Sent via application context")
        } catch {
            print("WatchConnectivity: Failed to update application context: \(error)")

            // Last resort: transfer user info (queued)
            session.transferUserInfo(data)
            print("WatchConnectivity: Queued via transferUserInfo")
        }
    }

    // MARK: - Send Workout to Watch

    /// Sends a workout to the Watch for immediate start
    func sendWorkoutToWatch(_ workout: PlannedWorkout) {
        guard let session = session, session.isReachable else {
            print("WatchConnectivity: Watch not reachable for workout send")
            return
        }

        do {
            let workoutData = WatchWorkoutData(
                id: workout.id,
                name: workout.name,
                workoutType: workout.workoutType.rawValue,
                estimatedDuration: workout.estimatedDuration,
                segments: workout.segments?.map { seg in
                    WatchSegmentData(
                        id: seg.id,
                        name: seg.name,
                        segmentType: seg.segmentType.rawValue,
                        targetDurationSeconds: seg.targetDurationSeconds,
                        targetDistanceMeters: seg.targetDistanceMeters,
                        targetReps: seg.targetReps,
                        targetPace: seg.targetPace,
                        instructions: seg.instructions
                    )
                }
            )

            let data = try encoder.encode(workoutData)
            let message: [String: Any] = [
                "type": "workout",
                "data": data
            ]

            session.sendMessage(message, replyHandler: nil) { error in
                print("WatchConnectivity: Failed to send workout: \(error)")
            }
        } catch {
            print("WatchConnectivity: Failed to encode workout: \(error)")
        }
    }

    // MARK: - Workout Commands

    func sendStartCommand() {
        sendCommand("workoutStart")
    }

    func sendPauseCommand() {
        sendCommand("workoutPause")
    }

    func sendResumeCommand() {
        sendCommand("workoutResume")
    }

    func sendStopCommand() {
        sendCommand("workoutStop")
    }

    private func sendCommand(_ type: String) {
        guard let session = session, session.isReachable else { return }

        let message: [String: Any] = [
            "type": type,
            "timestamp": Date().timeIntervalSince1970
        ]

        session.sendMessage(message, replyHandler: nil)
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("WatchConnectivity: Activation failed: \(error)")
            } else {
                print("WatchConnectivity: Activated with state: \(activationState.rawValue)")
                self.isPaired = session.isPaired
                self.isWatchAppInstalled = session.isWatchAppInstalled
                self.isReachable = session.isReachable
            }
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        print("WatchConnectivity: Session became inactive")
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        print("WatchConnectivity: Session deactivated")
        // Reactivate for switching watches
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
            print("WatchConnectivity: Reachability changed: \(session.isReachable)")
        }
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isPaired = session.isPaired
            self.isWatchAppInstalled = session.isWatchAppInstalled
            print("WatchConnectivity: Watch state changed - paired: \(session.isPaired), installed: \(session.isWatchAppInstalled)")
        }
    }

    // MARK: - Receiving Messages

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleIncomingMessage(message)
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        handleIncomingMessage(message)
        replyHandler(["status": "received"])
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        handleIncomingMessage(userInfo)
    }

    nonisolated private func handleIncomingMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else { return }

        Task { @MainActor in
            switch type {
            case "liveMetrics":
                handleLiveMetrics(message)
            case "segmentComplete":
                handleSegmentCompletion(message)
            case "workoutSummary":
                handleWorkoutSummary(message)
            case "heartRateAlert":
                handleHeartRateAlert(message)
            default:
                print("WatchConnectivity: Unknown message type: \(type)")
            }
        }
    }

    private func handleLiveMetrics(_ message: [String: Any]) {
        // Post notification for live workout view to consume
        NotificationCenter.default.post(
            name: .watchLiveMetricsReceived,
            object: nil,
            userInfo: message
        )
    }

    private func handleSegmentCompletion(_ message: [String: Any]) {
        NotificationCenter.default.post(
            name: .watchSegmentCompleted,
            object: nil,
            userInfo: message
        )
    }

    private func handleWorkoutSummary(_ message: [String: Any]) {
        NotificationCenter.default.post(
            name: .watchWorkoutSummaryReceived,
            object: nil,
            userInfo: message
        )
    }

    private func handleHeartRateAlert(_ message: [String: Any]) {
        NotificationCenter.default.post(
            name: .watchHeartRateAlert,
            object: nil,
            userInfo: message
        )
    }
}

// MARK: - Supporting Types

struct WatchWorkoutData: Codable {
    let id: UUID
    let name: String
    let workoutType: String
    let estimatedDuration: Int
    let segments: [WatchSegmentData]?
}

struct WatchSegmentData: Codable {
    let id: UUID
    let name: String
    let segmentType: String
    let targetDurationSeconds: Int?
    let targetDistanceMeters: Int?
    let targetReps: Int?
    let targetPace: String?
    let instructions: String?
}

// MARK: - Notification Names

extension Notification.Name {
    static let watchLiveMetricsReceived = Notification.Name("watchLiveMetricsReceived")
    static let watchSegmentCompleted = Notification.Name("watchSegmentCompleted")
    static let watchWorkoutSummaryReceived = Notification.Name("watchWorkoutSummaryReceived")
    static let watchHeartRateAlert = Notification.Name("watchHeartRateAlert")
}
