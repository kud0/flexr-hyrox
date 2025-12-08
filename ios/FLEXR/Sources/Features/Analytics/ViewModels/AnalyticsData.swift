import Foundation
import SwiftUI

// MARK: - Analytics Data Container
// Used by AnalyticsService for real-time calculations

struct AnalyticsData {
    let readiness: Readiness
    let racePrediction: RacePrediction
    let trainingLoad: TrainingLoad
    let quickStats: QuickStats
    let paceZones: [PaceZone]
    let stationPerformance: [StationPerformance]
    let compromisedRunning: [CompromisedRun]
    let maxHeartRate: Int
    let heartRateZones: [HRZone]
    let timeDistribution: TimeDistribution
    let runningWorkouts: RunningWorkouts

    static var mock: AnalyticsData {
        AnalyticsData(
            readiness: Readiness(
                hrvScore: 65,
                sleepHours: 7.5,
                restingHeartRate: 52,
                readinessScore: 78
            ),
            racePrediction: RacePrediction(
                predictedTime: 4350,
                marginOfError: 5.0,
                trend: .improving
            ),
            trainingLoad: TrainingLoad(
                weeklyTarget: 8.0,
                currentWeekHours: 6.5,
                dailyBreakdown: [
                    DailyTraining(day: "Mon", hours: 1.5, isToday: false),
                    DailyTraining(day: "Tue", hours: 0, isToday: false),
                    DailyTraining(day: "Wed", hours: 1.5, isToday: false),
                    DailyTraining(day: "Thu", hours: 0, isToday: false),
                    DailyTraining(day: "Fri", hours: 1.5, isToday: false),
                    DailyTraining(day: "Sat", hours: 2.0, isToday: false),
                    DailyTraining(day: "Sun", hours: 0, isToday: true)
                ]
            ),
            quickStats: QuickStats(
                weeklyDistance: 32.0,
                monthlyDistance: 128.0,
                totalRuns: 156,
                totalHours: 89.5
            ),
            paceZones: [],
            stationPerformance: [],
            compromisedRunning: [],
            maxHeartRate: 186,
            heartRateZones: [],
            timeDistribution: TimeDistribution(
                runningPercentage: 52,
                stationsPercentage: 42,
                transitionsPercentage: 6
            ),
            runningWorkouts: RunningWorkouts(
                weeklyVolume: 38.2,
                longestRun: 15.0,
                averagePace: "5:12",
                personalRecords: 3,
                zone2Percentage: 72
            )
        )
    }

    // MARK: - Readiness Data
    struct ReadinessData {
        let score: Int // 0-100
        let hrv: Double // ms
        let hrvChange: Double // percentage
        let sleepHours: Double
        let restingHR: Int // bpm
        let recommendation: String

        static var mock: ReadinessData {
            ReadinessData(
                score: 78,
                hrv: 45,
                hrvChange: 8,
                sleepHours: 7.2,
                restingHR: 52,
                recommendation: "Ready for high intensity training"
            )
        }
    }

    // MARK: - Race Prediction Data
    struct RacePredictionData {
        let predictedTime: TimeInterval // seconds
        let marginOfError: TimeInterval // seconds
        let targetTime: TimeInterval? // seconds
        let trendChange: TimeInterval // seconds (negative = improvement)

        var formattedTime: String {
            let hours = Int(predictedTime) / 3600
            let minutes = (Int(predictedTime) % 3600) / 60
            let seconds = Int(predictedTime) % 60
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        var formattedTrend: String {
            let minutes = abs(Int(trendChange)) / 60
            let seconds = abs(Int(trendChange)) % 60
            let sign = trendChange < 0 ? "-" : "+"
            return "\(sign)\(minutes):\(String(format: "%02d", seconds))"
        }

        static var mock: RacePredictionData {
            RacePredictionData(
                predictedTime: 4350, // 1:12:30
                marginOfError: 120, // ±2 minutes
                targetTime: 4500, // 1:15:00
                trendChange: -135 // -2:15 improvement
            )
        }
    }

    // MARK: - Training Load Data
    struct TrainingLoadData {
        let targetHours: Double
        let completedHours: Double
        let dailyHours: [Double] // 7 days (Mon-Sun)

        var percentage: Double {
            completedHours / targetHours
        }

        static var mock: TrainingLoadData {
            TrainingLoadData(
                targetHours: 8.0,
                completedHours: 6.5,
                dailyHours: [1.5, 0, 1.5, 0, 1.5, 2.0, 0]
            )
        }
    }

    // MARK: - Quick Stats Data
    struct QuickStatsData {
        let weeklyKm: Double
        let weeklyChange: Double // percentage
        let monthlyKm: Double
        let monthlyChange: Double // percentage
        let totalRuns: Int
        let totalHours: Double

        static var mock: QuickStatsData {
            QuickStatsData(
                weeklyKm: 32,
                weeklyChange: 12,
                monthlyKm: 128,
                monthlyChange: 8,
                totalRuns: 156,
                totalHours: 89.5
            )
        }
    }

    // MARK: - Pace Zones Data
    struct PaceZonesData {
        let zone1Max: String // "6:00+ /km"
        let zone2Range: String // "5:15 - 5:45 /km"
        let zone3Range: String // "4:45 - 5:15 /km"
        let zone4Range: String // "4:25 - 4:45 /km"
        let zone5Max: String // "< 4:25 /km"
        let basedOnRuns: Int

        static var mock: PaceZonesData {
            PaceZonesData(
                zone1Max: "6:00+ /km",
                zone2Range: "5:15 - 5:45 /km",
                zone3Range: "4:45 - 5:15 /km",
                zone4Range: "4:25 - 4:45 /km",
                zone5Max: "< 4:25 /km",
                basedOnRuns: 23
            )
        }
    }


    // MARK: - Compromised Running Data
    struct CompromisedRunningData {
        let freshPace: String // "4:38/km"
        let avgCompromisedPace: String // "5:02/km"
        let avgDegradation: String // "+24 sec (8.6%)"
        let byStation: [StationDegradation]

        struct StationDegradation {
            let name: String
            let degradation: Int // seconds
            let percentage: Double // 0-100 for bar
            let status: String
        }

        static var mock: CompromisedRunningData {
            CompromisedRunningData(
                freshPace: "4:38/km",
                avgCompromisedPace: "5:02/km",
                avgDegradation: "+24 sec (8.6%)",
                byStation: [
                    StationDegradation(name: "Post-SkiErg", degradation: 15, percentage: 30, status: "Good"),
                    StationDegradation(name: "Post-Sled Push", degradation: 32, percentage: 65, status: "Work on it"),
                    StationDegradation(name: "Post-Sled Pull", degradation: 22, percentage: 45, status: "Okay"),
                    StationDegradation(name: "Post-Burpees", degradation: 38, percentage: 75, status: "Weakness ⚠️"),
                    StationDegradation(name: "Post-Rowing", degradation: 12, percentage: 25, status: "Strong"),
                    StationDegradation(name: "Post-Farmers", degradation: 28, percentage: 55, status: "Work on it"),
                    StationDegradation(name: "Post-Lunges", degradation: 35, percentage: 70, status: "Weakness ⚠️"),
                    StationDegradation(name: "Post-Wall Balls", degradation: 25, percentage: 50, status: "Okay")
                ]
            )
        }
    }

    // MARK: - Heart Rate Zones
    struct HeartRateZoneConfig {
        let maxHR: Int
        let restingHR: Int
        let zone1Max: Int
        let zone2Range: String
        let zone3Range: String
        let zone4Range: String
        let zone5Min: Int

        static var mock: HeartRateZoneConfig {
            HeartRateZoneConfig(
                maxHR: 186,
                restingHR: 52,
                zone1Max: 112,
                zone2Range: "112-130 bpm",
                zone3Range: "130-149 bpm",
                zone4Range: "149-167 bpm",
                zone5Min: 167
            )
        }
    }


    // MARK: - Running Workouts Data
    struct RunningWorkoutsData {
        let thisWeekKm: Double
        let thisWeekRuns: Int
        let thisWeekAvgPace: String
        let thisWeekTotalTime: String
        let volumeTrend: Double // percentage change vs last week
        let workoutTypes: [WorkoutType]
        let avgFreshPace: String
        let paceTrendSeconds: Int // negative = getting faster
        let paceTrendData: [Double] // pace in seconds per km over time
        let prs: [PersonalRecord]
        let zone2Percentage: Double

        struct WorkoutType {
            let name: String
            let count: Int
            let totalKm: Double
            let percentage: Double // 0-100 for bar chart
        }

        struct PersonalRecord {
            let distance: String
            let time: String
            let pace: String
        }

        static var mock: RunningWorkoutsData {
            RunningWorkoutsData(
                thisWeekKm: 38.2,
                thisWeekRuns: 5,
                thisWeekAvgPace: "5:12/km",
                thisWeekTotalTime: "3h 18m",
                volumeTrend: 8.5,
                workoutTypes: [
                    WorkoutType(name: "Easy Run", count: 12, totalKm: 78.4, percentage: 62),
                    WorkoutType(name: "Tempo", count: 4, totalKm: 28.2, percentage: 22),
                    WorkoutType(name: "Intervals", count: 3, totalKm: 12.5, percentage: 10),
                    WorkoutType(name: "Long Run", count: 2, totalKm: 42.8, percentage: 34)
                ],
                avgFreshPace: "4:48",
                paceTrendSeconds: -12,
                paceTrendData: [305, 298, 295, 292, 290, 288, 293],
                prs: [
                    PersonalRecord(distance: "1km", time: "3:42", pace: "3:42/km"),
                    PersonalRecord(distance: "5km", time: "19:28", pace: "3:54/km"),
                    PersonalRecord(distance: "10km", time: "41:35", pace: "4:10/km")
                ],
                zone2Percentage: 72.5
            )
        }
    }
}
