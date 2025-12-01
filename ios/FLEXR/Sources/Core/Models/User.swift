import Foundation

struct User: Identifiable, Codable, Equatable {
    let id: UUID
    let email: String
    var name: String
    let createdAt: Date
    var trainingGoal: TrainingGoal
    var raceDate: Date?
    var trainingArchitecture: TrainingArchitecture
    var experienceLevel: ExperienceLevel

    // MARK: - Computed Properties

    var daysUntilRace: Int? {
        guard let raceDate = raceDate else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let race = calendar.startOfDay(for: raceDate)
        return calendar.dateComponents([.day], from: today, to: race).day
    }

    var weeksUntilRace: Int? {
        guard let days = daysUntilRace else { return nil }
        return days / 7
    }

    var isRaceApproaching: Bool {
        guard let days = daysUntilRace else { return false }
        return days <= 14 && days > 0
    }
}

// MARK: - Training Goal

enum TrainingGoal: String, Codable, CaseIterable {
    case trainStyle = "train_style"
    case competeRace = "compete_race"

    var displayName: String {
        switch self {
        case .trainStyle:
            return "Train HYROX Style"
        case .competeRace:
            return "Compete in Race"
        }
    }

    var description: String {
        switch self {
        case .trainStyle:
            return "Focus on fitness and technique without a specific race date"
        case .competeRace:
            return "Prepare for an upcoming HYROX competition"
        }
    }
}

// MARK: - Training Architecture

struct TrainingArchitecture: Codable, Equatable {
    var daysPerWeek: Int // 2-6 days
    var sessionsPerDay: Int // 1-2 sessions
    var sessionTypes: [WorkoutType]

    init(daysPerWeek: Int = 4, sessionsPerDay: Int = 1, sessionTypes: [WorkoutType] = []) {
        self.daysPerWeek = max(2, min(6, daysPerWeek))
        self.sessionsPerDay = max(1, min(2, sessionsPerDay))
        self.sessionTypes = sessionTypes
    }

    var totalSessionsPerWeek: Int {
        return daysPerWeek * sessionsPerDay
    }

    var isDoubleDay: Bool {
        return sessionsPerDay == 2
    }
}

// MARK: - Experience Level

enum ExperienceLevel: String, Codable, CaseIterable {
    case beginner
    case intermediate
    case advanced
    case elite

    var displayName: String {
        switch self {
        case .beginner:
            return "Beginner"
        case .intermediate:
            return "Intermediate"
        case .advanced:
            return "Advanced"
        case .elite:
            return "Elite"
        }
    }

    var description: String {
        switch self {
        case .beginner:
            return "New to HYROX or functional fitness"
        case .intermediate:
            return "Completed 1-3 HYROX races or regular functional training"
        case .advanced:
            return "Completed 4+ races or extensive functional fitness background"
        case .elite:
            return "Competitive athlete with podium finishes"
        }
    }

    var recommendedVolume: Int {
        switch self {
        case .beginner:
            return 3 // sessions per week
        case .intermediate:
            return 4
        case .advanced:
            return 5
        case .elite:
            return 6
        }
    }
}

// MARK: - Workout Type

enum WorkoutType: String, Codable, CaseIterable {
    case fullSimulation = "full_simulation"
    case stationFocus = "station_focus"
    case running = "running"
    case recovery = "recovery"
    case strength = "strength"
    case interval = "interval"

    var displayName: String {
        switch self {
        case .fullSimulation:
            return "Full HYROX Simulation"
        case .stationFocus:
            return "Station Focus"
        case .running:
            return "Running Session"
        case .recovery:
            return "Recovery Session"
        case .strength:
            return "Strength Training"
        case .interval:
            return "Interval Training"
        }
    }

    var icon: String {
        switch self {
        case .fullSimulation:
            return "figure.mixed.cardio"
        case .stationFocus:
            return "dumbbell.fill"
        case .running:
            return "figure.run"
        case .recovery:
            return "leaf.fill"
        case .strength:
            return "figure.strengthtraining.traditional"
        case .interval:
            return "timer"
        }
    }

    var estimatedDuration: TimeInterval {
        switch self {
        case .fullSimulation:
            return 4200 // 70 minutes
        case .stationFocus:
            return 2700 // 45 minutes
        case .running:
            return 2400 // 40 minutes
        case .recovery:
            return 1800 // 30 minutes
        case .strength:
            return 3600 // 60 minutes
        case .interval:
            return 2400 // 40 minutes
        }
    }
}

// MARK: - User Settings

struct UserSettings: Codable, Equatable {
    var unitPreference: UnitPreference
    var paceDisplay: PaceDisplay
    var notificationsEnabled: Bool
    var healthKitSyncEnabled: Bool
    var appleMusicEnabled: Bool

    init(
        unitPreference: UnitPreference = .metric,
        paceDisplay: PaceDisplay = .minPerKm,
        notificationsEnabled: Bool = true,
        healthKitSyncEnabled: Bool = true,
        appleMusicEnabled: Bool = false
    ) {
        self.unitPreference = unitPreference
        self.paceDisplay = paceDisplay
        self.notificationsEnabled = notificationsEnabled
        self.healthKitSyncEnabled = healthKitSyncEnabled
        self.appleMusicEnabled = appleMusicEnabled
    }
}

enum UnitPreference: String, Codable {
    case metric
    case imperial
}

enum PaceDisplay: String, Codable {
    case minPerKm = "min_per_km"
    case minPerMile = "min_per_mile"
}
