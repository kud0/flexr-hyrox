import Foundation

// MARK: - Onboarding Data Model
// Holds all data collected during minimal core onboarding (12 questions)

class OnboardingData: ObservableObject {
    // MARK: Step 1 - Basic Profile
    @Published var age: Int?
    @Published var weight: Double? // kg
    @Published var height: Double? // cm
    @Published var gender: Gender = .male
    @Published var trainingBackground: TrainingBackground?

    // MARK: Step 2 - Goal & Race Details
    @Published var primaryGoal: PrimaryGoal?
    @Published var raceDate: Date?
    @Published var targetTime: TargetTime?
    @Published var justFinishedRace: Bool = false

    // Previous HYROX race history
    @Published var hasCompletedHyroxBefore: Bool = false
    @Published var numberOfHyroxRaces: NumberOfRaces?
    @Published var bestHyroxTime: TimeInterval? // seconds
    @Published var bestHyroxDivision: HyroxDivision?
    @Published var lastHyroxRaceDate: Date?

    // MARK: Step 3 - Training Availability
    @Published var daysPerWeek: Int = 4
    @Published var sessionsPerDay: SessionsPerDay = .one
    @Published var preferredTime: PreferredTime = .morning
    @Published var sessionTiming: SessionTiming = .amPm // For 2 sessions/day
    @Published var programStartDate: Date? = Date()  // When to start the plan
    @Published var preferredRecoveryDay: DayOfWeek = .sunday  // Recovery day for 6+ days/week

    // MARK: Step 4 - Equipment Access
    @Published var equipmentLocation: EquipmentLocation?
    @Published var homeGymEquipment: Set<HomeEquipment> = []

    // MARK: Step 5 - Optional Performance Numbers
    @Published var running1kmSeconds: Double? // seconds
    @Published var running5kmSeconds: Double? // seconds
    @Published var comfortableZ2Pace: Double? // seconds per km

    // MARK: Step 6 - Workout Duration Preference
    @Published var preferredWorkoutDuration: WorkoutDuration?

    // MARK: Step 7 - Workout Type Preferences
    @Published var preferredWorkoutTypes: Set<PreferredWorkoutType> = []

    // MARK: Step 8 - Apple Watch
    @Published var hasAppleWatch: Bool?

    // MARK: Step 9 - HealthKit
    @Published var healthKitEnabled: Bool?

    // MARK: Completion
    @Published var isComplete: Bool = false

    // MARK: - Enums

    enum Gender: String, CaseIterable {
        case male = "male"
        case female = "female"
        case other = "other"

        var displayName: String {
            switch self {
            case .male: return "Male"
            case .female: return "Female"
            case .other: return "Other"
            }
        }
    }

    enum TrainingBackground: String, CaseIterable {
        case newToFitness = "new_to_fitness"
        case gymRegular = "gym_regular"
        case runner = "runner"
        case crossfit = "crossfit"
        case hyroxVeteran = "hyrox_veteran"

        var displayName: String {
            switch self {
            case .newToFitness: return "New to Fitness"
            case .gymRegular: return "Gym Regular"
            case .runner: return "Runner"
            case .crossfit: return "CrossFit/Functional"
            case .hyroxVeteran: return "HYROX Veteran"
            }
        }

        var description: String {
            switch self {
            case .newToFitness: return "Starting fresh"
            case .gymRegular: return "Regular gym-goer"
            case .runner: return "5K to marathon background"
            case .crossfit: return "Box experience, WODs"
            case .hyroxVeteran: return "Done 2+ HYROX races"
            }
        }
    }

    enum PrimaryGoal: String, CaseIterable {
        case firstHyrox = "first_hyrox"
        case prepareForRace = "prepare_for_race"
        case podium = "podium"
        case trainStyle = "train_style"
        case multipleRaces = "multiple_races"

        var displayName: String {
            switch self {
            case .firstHyrox: return "Complete my first HYROX"
            case .prepareForRace: return "Prepare for a race"
            case .podium: return "Podium / Competitive"
            case .trainStyle: return "Train HYROX style (no race)"
            case .multipleRaces: return "Multiple races this year"
            }
        }

        var requiresRaceDate: Bool {
            switch self {
            case .firstHyrox, .prepareForRace, .podium: return true
            case .trainStyle, .multipleRaces: return false
            }
        }
    }

    enum TargetTime: String, CaseIterable {
        case justFinish = "just_finish"
        case sub2Hours = "sub_2_hours"
        case sub90Min = "sub_90_min"
        case sub75Min = "sub_75_min"
        case sub60Min = "sub_60_min"
        case podium = "podium"

        var displayName: String {
            switch self {
            case .justFinish: return "Just finish strong"
            case .sub2Hours: return "Sub 2:00 hours"
            case .sub90Min: return "Sub 1:30 hours"
            case .sub75Min: return "Sub 1:15 hours"
            case .sub60Min: return "Sub 1:00 hours"
            case .podium: return "Podium (top 3)"
            }
        }

        var seconds: Int {
            switch self {
            case .justFinish: return 7200 // 2 hours as default
            case .sub2Hours: return 7200
            case .sub90Min: return 5400
            case .sub75Min: return 4500
            case .sub60Min: return 3600
            case .podium: return 3600 // ~1 hour for podium
            }
        }
    }

    enum NumberOfRaces: String, CaseIterable {
        case one = "1"
        case two = "2"
        case threeToFive = "3_5"
        case sixPlus = "6+"

        var displayName: String {
            switch self {
            case .one: return "1 race"
            case .two: return "2 races"
            case .threeToFive: return "3-5 races"
            case .sixPlus: return "6+ races"
            }
        }

        var count: Int {
            switch self {
            case .one: return 1
            case .two: return 2
            case .threeToFive: return 4 // Average
            case .sixPlus: return 6
            }
        }
    }

    enum HyroxDivision: String, CaseIterable {
        case menOpen = "men_open"
        case womenOpen = "women_open"
        case menPro = "men_pro"
        case womenPro = "women_pro"
        case doubles = "doubles"
        case relay = "relay"

        var displayName: String {
            switch self {
            case .menOpen: return "Men Open"
            case .womenOpen: return "Women Open"
            case .menPro: return "Men Pro"
            case .womenPro: return "Women Pro"
            case .doubles: return "Doubles"
            case .relay: return "Relay (4-person)"
            }
        }
    }

    enum SessionsPerDay: Int, CaseIterable {
        case one = 1
        case two = 2

        var displayName: String {
            switch self {
            case .one: return "1 session"
            case .two: return "2 sessions"
            }
        }

        var description: String {
            switch self {
            case .one: return "Most people"
            case .two: return "Serious athletes"
            }
        }
    }

    enum PreferredTime: String, CaseIterable {
        case morning = "morning"
        case afternoon = "afternoon"
        case evening = "evening"
        case flexible = "flexible"

        var displayName: String {
            switch self {
            case .morning: return "Morning (5-8am)"
            case .afternoon: return "Midday (11am-1pm)"
            case .evening: return "Evening (6-9pm)"
            case .flexible: return "Flexible"
            }
        }
    }

    enum SessionTiming: String, CaseIterable {
        case amPm = "am_pm"
        case amAm = "am_am"
        case pmPm = "pm_pm"

        var displayName: String {
            switch self {
            case .amPm: return "AM / PM"
            case .amAm: return "AM / AM"
            case .pmPm: return "PM / PM"
            }
        }

        var description: String {
            switch self {
            case .amPm: return "Morning and evening"
            case .amAm: return "Both morning sessions"
            case .pmPm: return "Both evening sessions"
            }
        }
    }

    enum EquipmentLocation: String, CaseIterable {
        case hyroxGym = "hyrox_gym"
        case crossfitGym = "crossfit_gym"
        case commercialGym = "commercial_gym"
        case homeGym = "home_gym"
        case minimal = "minimal"

        var displayName: String {
            switch self {
            case .hyroxGym: return "HYROX-equipped gym"
            case .crossfitGym: return "CrossFit/Functional gym"
            case .commercialGym: return "Commercial gym"
            case .homeGym: return "Home gym"
            case .minimal: return "Minimal/Outdoor"
            }
        }

        var description: String {
            switch self {
            case .hyroxGym: return "All 8 stations available"
            case .crossfitGym: return "Most equipment, maybe no sleds"
            case .commercialGym: return "Standard gym equipment"
            case .homeGym: return "Select what you have"
            case .minimal: return "Bodyweight + running"
            }
        }
    }

    enum HomeEquipment: String, CaseIterable {
        case rower = "rower"
        case skierg = "skierg"
        case barbell = "barbell"
        case dumbbells = "dumbbells"
        case kettlebells = "kettlebells"
        case pullupBar = "pullup_bar"
        case resistanceBands = "resistance_bands"

        var displayName: String {
            switch self {
            case .rower: return "Rower"
            case .skierg: return "SkiErg"
            case .barbell: return "Barbell + Rack"
            case .dumbbells: return "Dumbbells"
            case .kettlebells: return "Kettlebells"
            case .pullupBar: return "Pull-up Bar"
            case .resistanceBands: return "Resistance Bands"
            }
        }
    }

    // MARK: - Validation

    func isStepComplete(_ step: Int) -> Bool {
        switch step {
        case 1:
            return age != nil && weight != nil && height != nil && trainingBackground != nil
        case 2:
            if primaryGoal == nil { return false }
            if primaryGoal?.requiresRaceDate == true && raceDate == nil { return false }
            if primaryGoal?.requiresRaceDate == true && targetTime == nil { return false }
            return true
        case 3:
            return true // Always valid (has defaults)
        case 4:
            return equipmentLocation != nil
        case 5:
            return true // Optional step, always valid
        case 6:
            return preferredWorkoutDuration != nil
        case 7:
            return !preferredWorkoutTypes.isEmpty
        case 8:
            return true // Optional step, always valid
        case 9:
            return true // Optional step, always valid
        default:
            return false
        }
    }

    func canProceed(from step: Int) -> Bool {
        return isStepComplete(step)
    }

    // MARK: - Derived Values

    var weeksToRace: Int? {
        guard let raceDate = raceDate else { return nil }
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: now, to: raceDate)
        guard let days = components.day else { return nil }
        return max(1, Int(ceil(Double(days) / 7.0)))
    }

    var fitnessLevel: String {
        // Estimate fitness level from training background
        switch trainingBackground {
        case .newToFitness:
            return "beginner"
        case .gymRegular, .runner:
            return "intermediate"
        case .crossfit:
            return "advanced"
        case .hyroxVeteran:
            return "elite"
        case .none:
            return "intermediate"
        }
    }

    // MARK: - API Payload

    func toAPIPayload() -> [String: Any] {
        var payload: [String: Any] = [:]

        // Basic profile
        if let age = age { payload["age"] = age }
        if let weight = weight { payload["weight_kg"] = weight }
        if let height = height { payload["height_cm"] = height }
        payload["gender"] = gender.rawValue
        if let background = trainingBackground {
            payload["training_background"] = background.rawValue
        }

        // Goal & race
        if let goal = primaryGoal {
            payload["primary_goal"] = goal.rawValue
        }
        if let raceDate = raceDate {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            payload["race_date"] = formatter.string(from: raceDate)
        }
        if let targetTime = targetTime {
            payload["target_time_seconds"] = targetTime.seconds
        }
        if let weeks = weeksToRace {
            payload["weeks_to_race"] = weeks
        }
        payload["just_finished_race"] = justFinishedRace

        // Previous HYROX race history
        payload["has_completed_hyrox_before"] = hasCompletedHyroxBefore
        if hasCompletedHyroxBefore {
            if let numberOfRaces = numberOfHyroxRaces {
                payload["number_of_hyrox_races"] = numberOfRaces.count
            }
            if let bestTime = bestHyroxTime {
                payload["best_hyrox_time_seconds"] = bestTime
            }
            if let division = bestHyroxDivision {
                payload["best_hyrox_division"] = division.rawValue
            }
            if let lastRaceDate = lastHyroxRaceDate {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withFullDate]
                payload["last_hyrox_race_date"] = formatter.string(from: lastRaceDate)
            }
        }

        // Training availability
        payload["days_per_week"] = daysPerWeek
        payload["sessions_per_day"] = sessionsPerDay.rawValue
        payload["preferred_time"] = preferredTime.rawValue

        // Program start date
        if let startDate = programStartDate {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            payload["program_start_date"] = formatter.string(from: startDate)
        }

        // Recovery day (for 6+ days/week training)
        if daysPerWeek >= 6 {
            payload["preferred_recovery_day"] = preferredRecoveryDay.rawValue
        }

        // Equipment
        if let location = equipmentLocation {
            payload["equipment_location"] = location.rawValue
        }

        // Fitness level (derived)
        payload["fitness_level"] = fitnessLevel

        // Optional performance numbers (will be in separate benchmarks table)
        var benchmarks: [String: Any] = [:]
        if let running1km = running1kmSeconds {
            benchmarks["running_1km_seconds"] = running1km
        }
        if let running5km = running5kmSeconds {
            benchmarks["running_5km_seconds"] = running5km
        }
        if let z2Pace = comfortableZ2Pace {
            benchmarks["running_zone2_pace_seconds"] = z2Pace
        }
        if !benchmarks.isEmpty {
            payload["benchmarks"] = benchmarks
        }

        // Workout duration preference
        if let duration = preferredWorkoutDuration {
            payload["preferred_workout_duration_minutes"] = duration.minutes
        }

        // Workout type preferences
        if !preferredWorkoutTypes.isEmpty {
            payload["preferred_workout_types"] = preferredWorkoutTypes.map { $0.rawValue }
        }

        // Device setup
        if let hasWatch = hasAppleWatch {
            payload["has_apple_watch"] = hasWatch
        }
        if let healthKit = healthKitEnabled {
            payload["healthkit_enabled"] = healthKit
        }

        return payload
    }

    // MARK: - Workout Duration

    enum WorkoutDuration: String, CaseIterable {
        case short = "short"           // 30-45 minutes
        case standard = "standard"     // 45-60 minutes
        case extended = "extended"     // 60-75 minutes
        case comprehensive = "comprehensive" // 75-90 minutes

        var displayName: String {
            switch self {
            case .short: return "30-45 minutes"
            case .standard: return "45-60 minutes"
            case .extended: return "60-75 minutes"
            case .comprehensive: return "75-90 minutes"
            }
        }

        var description: String {
            switch self {
            case .short: return "Quick, efficient sessions"
            case .standard: return "Balanced workout time"
            case .extended: return "Longer training blocks"
            case .comprehensive: return "Full comprehensive sessions"
            }
        }

        var minutes: Int {
            switch self {
            case .short: return 40
            case .standard: return 55
            case .extended: return 70
            case .comprehensive: return 85
            }
        }
    }

    // MARK: - Preferred Workout Types

    enum PreferredWorkoutType: String, CaseIterable, Hashable {
        case running = "running"
        case strength = "strength"
        case hyroxSimulation = "hyrox_simulation"
        case stationFocus = "station_focus"
        case intervals = "intervals"
        case recovery = "recovery"

        var displayName: String {
            switch self {
            case .running: return "Running"
            case .strength: return "Strength Training"
            case .hyroxSimulation: return "HYROX Simulations"
            case .stationFocus: return "Station Focus Work"
            case .intervals: return "Interval Training"
            case .recovery: return "Recovery & Mobility"
            }
        }

        var description: String {
            switch self {
            case .running: return "Pure running sessions and intervals"
            case .strength: return "Resistance training and power work"
            case .hyroxSimulation: return "Full or partial race simulations"
            case .stationFocus: return "Station-specific skill work"
            case .intervals: return "High-intensity interval training"
            case .recovery: return "Active recovery and stretching"
            }
        }

        var icon: String {
            switch self {
            case .running: return "figure.run"
            case .strength: return "dumbbell.fill"
            case .hyroxSimulation: return "flame.fill"
            case .stationFocus: return "target"
            case .intervals: return "timer"
            case .recovery: return "heart.fill"
            }
        }
    }
}
