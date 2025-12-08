import Foundation
import SwiftUI

struct User: Identifiable, Codable, Equatable {
    let id: UUID
    let email: String
    var name: String?  // Optional - may be null in database
    let createdAt: Date
    var trainingGoal: TrainingGoal
    var raceDate: Date?
    var programStartDate: Date?  // When user wants to start the program
    var preferredRecoveryDay: DayOfWeek?  // User's preferred recovery/rest day
    var trainingPreferences: UserTrainingPreferences
    var experienceLevel: ExperienceLevel
    var deviceTokens: [String]?
    var equipment: [String]?
    var hasAppleWatch: Bool?

    enum CodingKeys: String, CodingKey {
        case id, email, name, equipment
        case createdAt = "created_at"
        case trainingGoal = "training_goal"
        case raceDate = "race_date"
        case programStartDate = "program_start_date"
        case preferredRecoveryDay = "preferred_recovery_day"
        case trainingPreferences = "training_preferences"
        case experienceLevel = "experience_level"
        case deviceTokens = "device_tokens"
        case hasAppleWatch = "has_apple_watch"
    }

    // Custom decoder to handle multiple date formats from database
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        trainingGoal = try container.decodeIfPresent(TrainingGoal.self, forKey: .trainingGoal) ?? .trainStyle
        trainingPreferences = try container.decodeIfPresent(UserTrainingPreferences.self, forKey: .trainingPreferences) ?? UserTrainingPreferences()
        experienceLevel = try container.decodeIfPresent(ExperienceLevel.self, forKey: .experienceLevel) ?? .intermediate
        deviceTokens = try container.decodeIfPresent([String].self, forKey: .deviceTokens)
        equipment = try container.decodeIfPresent([String].self, forKey: .equipment)
        hasAppleWatch = try container.decodeIfPresent(Bool.self, forKey: .hasAppleWatch)
        preferredRecoveryDay = try container.decodeIfPresent(DayOfWeek.self, forKey: .preferredRecoveryDay)

        // Handle createdAt - can be ISO8601 with or without time
        createdAt = try User.decodeFlexibleDate(from: container, forKey: .createdAt) ?? Date()

        // Handle optional dates with flexible parsing
        raceDate = try User.decodeFlexibleDate(from: container, forKey: .raceDate)
        programStartDate = try User.decodeFlexibleDate(from: container, forKey: .programStartDate)
    }

    /// Decodes dates that may be in various formats (ISO8601 with time, date-only, etc.)
    private static func decodeFlexibleDate(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Date? {
        // First try decoding as Date directly (handles ISO8601 with time)
        if let date = try? container.decode(Date.self, forKey: key) {
            return date
        }

        // If that fails, try decoding as string and parse
        guard let dateString = try? container.decodeIfPresent(String.self, forKey: key),
              !dateString.isEmpty else {
            return nil
        }

        // Try ISO8601 with fractional seconds
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }

        // Try ISO8601 without fractional seconds
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }

        // Try date-only format (YYYY-MM-DD)
        let dateOnlyFormatter = DateFormatter()
        dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
        dateOnlyFormatter.timeZone = TimeZone(identifier: "UTC")
        if let date = dateOnlyFormatter.date(from: dateString) {
            return date
        }

        print("⚠️ User: Could not parse date string: \(dateString)")
        return nil
    }

    // Standard memberwise initializer for creating User instances in code
    init(
        id: UUID,
        email: String,
        name: String? = nil,
        createdAt: Date = Date(),
        trainingGoal: TrainingGoal,
        raceDate: Date? = nil,
        programStartDate: Date? = nil,
        preferredRecoveryDay: DayOfWeek? = nil,
        trainingPreferences: UserTrainingPreferences,
        experienceLevel: ExperienceLevel,
        deviceTokens: [String]? = nil,
        equipment: [String]? = nil,
        hasAppleWatch: Bool? = nil
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.createdAt = createdAt
        self.trainingGoal = trainingGoal
        self.raceDate = raceDate
        self.programStartDate = programStartDate
        self.preferredRecoveryDay = preferredRecoveryDay
        self.trainingPreferences = trainingPreferences
        self.experienceLevel = experienceLevel
        self.deviceTokens = deviceTokens
        self.equipment = equipment
        self.hasAppleWatch = hasAppleWatch
    }

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

// MARK: - User Training Preferences (embedded in User)
// Note: The full TrainingArchitecture model is in TrainingArchitecture.swift

struct UserTrainingPreferences: Codable, Equatable {
    var daysPerWeek: Int // 2-6 days
    var sessionsPerDay: Int // 1-2 sessions
    var preferredTypes: [WorkoutType]

    init(daysPerWeek: Int = 4, sessionsPerDay: Int = 1, preferredTypes: [WorkoutType] = []) {
        self.daysPerWeek = max(2, min(6, daysPerWeek))
        self.sessionsPerDay = max(1, min(2, sessionsPerDay))
        self.preferredTypes = preferredTypes
    }

    var totalSessionsPerWeek: Int {
        return daysPerWeek * sessionsPerDay
    }

    var isDoubleDay: Bool {
        return sessionsPerDay == 2
    }

    enum CodingKeys: String, CodingKey {
        case daysPerWeek = "days_per_week"
        case sessionsPerDay = "sessions_per_day"
        case preferredTypes = "preferred_types"
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
    case halfSimulation = "half_simulation"
    case stationFocus = "station_focus"
    case running = "running"
    case recovery = "recovery"
    case strength = "strength"
    case functional = "functional"
    case interval = "interval"
    case custom = "custom"
    case compromisedRunning = "compromised_running"
    case warmup = "warmup"
    case cooldown = "cooldown"
    case hybrid = "hybrid"

    var displayName: String {
        switch self {
        case .fullSimulation:
            return "Full HYROX Simulation"
        case .halfSimulation:
            return "Half Simulation"
        case .stationFocus:
            return "Station Focus"
        case .running:
            return "Running Session"
        case .recovery:
            return "Recovery Session"
        case .strength:
            return "Strength Training"
        case .functional:
            return "Functional Class"
        case .interval:
            return "Interval Training"
        case .custom:
            return "Custom Workout"
        case .compromisedRunning:
            return "Compromised Running"
        case .warmup:
            return "Warm Up"
        case .cooldown:
            return "Cool Down"
        case .hybrid:
            return "Hybrid Training"
        }
    }

    var icon: String {
        switch self {
        case .fullSimulation:
            return "figure.mixed.cardio"
        case .halfSimulation:
            return "figure.mixed.cardio"
        case .stationFocus:
            return "dumbbell.fill"
        case .running:
            return "figure.run"
        case .recovery:
            return "leaf.fill"
        case .strength:
            return "figure.strengthtraining.traditional"
        case .functional:
            return "figure.cross.training"
        case .interval:
            return "timer"
        case .custom:
            return "pencil.and.outline"
        case .compromisedRunning:
            return "figure.run.circle.fill"
        case .warmup:
            return "flame"
        case .cooldown:
            return "snowflake"
        case .hybrid:
            return "bolt.horizontal.fill"
        }
    }

    var color: Color {
        switch self {
        case .fullSimulation, .halfSimulation:
            return DesignSystem.Colors.primary
        case .stationFocus, .strength, .functional:
            return DesignSystem.Colors.accent
        case .running:
            return DesignSystem.Colors.secondary
        case .recovery:
            return DesignSystem.Colors.success
        case .interval:
            return DesignSystem.Colors.warning
        case .custom:
            return DesignSystem.Colors.text.tertiary
        case .compromisedRunning:
            return DesignSystem.Colors.warning
        case .warmup:
            return Color(hex: "FF9F0A")
        case .cooldown:
            return Color(hex: "64D2FF")
        case .hybrid:
            return DesignSystem.Colors.primary
        }
    }

    var estimatedDuration: TimeInterval {
        switch self {
        case .fullSimulation:
            return 4200 // 70 minutes
        case .halfSimulation:
            return 2400 // 40 minutes
        case .stationFocus:
            return 2700 // 45 minutes
        case .running:
            return 2400 // 40 minutes
        case .recovery:
            return 1800 // 30 minutes
        case .strength:
            return 3600 // 60 minutes
        case .functional:
            return 3600 // 60 minutes
        case .interval:
            return 2400 // 40 minutes
        case .custom:
            return 3000 // 50 minutes default
        case .compromisedRunning:
            return 2400 // 40 minutes
        case .warmup:
            return 900 // 15 minutes
        case .cooldown:
            return 600 // 10 minutes
        case .hybrid:
            return 3000 // 50 minutes
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

// MARK: - Day of Week

enum DayOfWeek: String, Codable, CaseIterable {
    case monday = "monday"
    case tuesday = "tuesday"
    case wednesday = "wednesday"
    case thursday = "thursday"
    case friday = "friday"
    case saturday = "saturday"
    case sunday = "sunday"

    var displayName: String {
        rawValue.capitalized
    }

    var shortName: String {
        String(displayName.prefix(3))
    }

    var singleLetter: String {
        switch self {
        case .monday: return "M"
        case .tuesday: return "T"
        case .wednesday: return "W"
        case .thursday: return "T"
        case .friday: return "F"
        case .saturday: return "S"
        case .sunday: return "S"
        }
    }

    /// Returns the day before this day (for intense session scheduling)
    var previousDay: DayOfWeek {
        switch self {
        case .monday: return .sunday
        case .tuesday: return .monday
        case .wednesday: return .tuesday
        case .thursday: return .wednesday
        case .friday: return .thursday
        case .saturday: return .friday
        case .sunday: return .saturday
        }
    }
}
