import SwiftUI
import WatchKit

@main
struct FLEXRWatchApp: App {
    @StateObject private var connectivity = PhoneConnectivity()
    @StateObject private var workoutManager = WorkoutSessionManager()

    @SceneBuilder var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectivity)
                .environmentObject(workoutManager)
        }

        #if os(watchOS)
        WKNotificationScene(controller: NotificationController.self, category: "workoutReminder")
        #endif
    }
}
