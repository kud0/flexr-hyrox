import Foundation

// MARK: - Unified Analytics Types
// Shared between AnalyticsService and UI

// Readiness
struct Readiness {
    let hrvScore: Int
    let sleepHours: Double
    let restingHeartRate: Int
    let readinessScore: Int
}

// Race Prediction
struct RacePrediction {
    let predictedTime: TimeInterval
    let marginOfError: Double
    let trend: Trend

    enum Trend {
        case improving
        case stable
        case declining
    }

    var formattedTime: String {
        let hours = Int(predictedTime) / 3600
        let minutes = (Int(predictedTime) % 3600) / 60
        let seconds = Int(predictedTime) % 60
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
}

// Training Load
struct TrainingLoad {
    let weeklyTarget: Double
    let currentWeekHours: Double
    let dailyBreakdown: [DailyTraining]
}

struct DailyTraining {
    let day: String
    let hours: Double
    let isToday: Bool
}

// Quick Stats
struct QuickStats {
    let weeklyDistance: Double // km
    let monthlyDistance: Double // km
    let totalRuns: Int
    let totalHours: Double
}

// Pace Zones
struct PaceZone {
    let zoneName: String
    let paceRange: String
    let percentage: Int
}

// Station Performance
struct StationPerformance {
    let stationName: String
    let bestTime: Double
    let averageTime: Double
    let lastTime: Double
    let trend: RacePrediction.Trend
    let performanceScore: Int
}

// Heart Rate Zones
struct HRZone {
    let zone: Int
    let percentage: Int
    let color: String
}

// Time Distribution
struct TimeDistribution {
    let runningPercentage: Double
    let stationsPercentage: Double
    let transitionsPercentage: Double
}

// Running Workouts
struct RunningWorkouts {
    let weeklyVolume: Double
    let longestRun: Double
    let averagePace: String
    let personalRecords: Int
    let zone2Percentage: Int
}
