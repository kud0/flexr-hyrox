import SwiftUI
import WatchKit

@main
struct FLEXRWatchApp: App {
    @StateObject private var connectivity = PhoneConnectivity()
    @StateObject private var workoutManager = WorkoutSessionManager()
    private var authService = WatchAuthService.shared

    @SceneBuilder var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectivity)
                .environmentObject(workoutManager)
                .environment(authService)
        }

        // Notification scene removed - add NotificationController if needed
        // WKNotificationScene(controller: NotificationController.self, category: "workoutReminder")
    }
}
