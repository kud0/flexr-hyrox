// FLEXR - App Configuration
// Centralized configuration for the app

import Foundation

enum Config {
    // MARK: - Supabase
    enum Supabase {
        static let projectId = "umvwmoxikxxxmxpwrsgc"
        static let url = URL(string: "https://\(projectId).supabase.co")!

        // Get from Supabase Dashboard > Settings > API
        // IMPORTANT: Only use the anon key in the app, never the service role key!
        static var anonKey: String {
            // Try to get from environment first (for CI/CD)
            if let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] {
                return key
            }
            // Fallback to bundled config (set in Xcode scheme or Info.plist)
            if let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String {
                return key
            }
            // Development fallback - replace with your actual anon key
            return "YOUR_ANON_KEY_HERE"
        }
    }

    // MARK: - App Info
    enum App {
        static let name = "FLEXR"
        static let bundleId = "com.flexr.app"
        static let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        static let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    // MARK: - Feature Flags
    enum Features {
        /// Enable AI workout generation (requires AI-Powered tier)
        static let aiWorkoutGeneration = true

        /// Enable custom workout templates (requires Tracker tier)
        static let customWorkouts = true

        /// Enable compromised running analytics
        static let compromisedRunningAnalytics = true

        /// Enable Apple Watch integration
        static let watchIntegration = true

        /// Enable push notifications
        static let pushNotifications = true

        /// Enable debug logging
        #if DEBUG
        static let debugLogging = true
        #else
        static let debugLogging = false
        #endif
    }

    // MARK: - Limits
    enum Limits {
        /// Free tier workout limit per month
        static let freeWorkoutsPerMonth = 3

        /// Maximum segments in a custom workout
        static let maxSegmentsPerWorkout = 50

        /// Maximum custom templates per user (Tracker tier)
        static let maxCustomTemplates = 100

        /// Maximum programs per user
        static let maxPrograms = 20
    }

    // MARK: - URLs
    enum URLs {
        static let privacyPolicy = URL(string: "https://flexr.app/privacy")!
        static let termsOfService = URL(string: "https://flexr.app/terms")!
        static let support = URL(string: "https://flexr.app/support")!
        static let hyroxOfficial = URL(string: "https://hyrox.com")!
    }

    // MARK: - Subscription
    enum Subscription {
        static let freeProductId = "com.flexr.free"
        static let trackerProductId = "com.flexr.tracker.monthly"
        static let aiPoweredProductId = "com.flexr.aipowered.monthly"

        /// Tracker tier monthly price
        static let trackerPrice = "$9.99"

        /// AI-Powered tier monthly price
        static let aiPoweredPrice = "$19.99"
    }

    // MARK: - HealthKit
    enum HealthKit {
        /// Sample types to read
        static let readTypes: Set<String> = [
            "HKQuantityTypeIdentifierHeartRate",
            "HKQuantityTypeIdentifierRestingHeartRate",
            "HKQuantityTypeIdentifierHeartRateVariabilitySDNN",
            "HKQuantityTypeIdentifierVO2Max",
            "HKQuantityTypeIdentifierActiveEnergyBurned",
            "HKQuantityTypeIdentifierDistanceWalkingRunning",
            "HKCategoryTypeIdentifierSleepAnalysis"
        ]

        /// Sample types to write
        static let writeTypes: Set<String> = [
            "HKWorkoutType",
            "HKQuantityTypeIdentifierActiveEnergyBurned",
            "HKQuantityTypeIdentifierDistanceWalkingRunning",
            "HKQuantityTypeIdentifierHeartRate"
        ]
    }

    // MARK: - AI Learning
    enum AILearning {
        /// Weight for historical data in profile updates (0.0-1.0)
        static let historicalWeight: Double = 0.7

        /// Weight for new data in profile updates (0.0-1.0)
        static let newDataWeight: Double = 0.3

        /// Minimum samples for high confidence
        static let highConfidenceSamples = 10

        /// Minimum samples for medium confidence
        static let mediumConfidenceSamples = 5

        /// Minimum samples for low confidence
        static let lowConfidenceSamples = 3
    }
}

// MARK: - Debug Helpers
extension Config {
    static func log(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        if Features.debugLogging {
            let filename = (file as NSString).lastPathComponent
            print("[\(filename):\(line)] \(function): \(message)")
        }
        #endif
    }
}
