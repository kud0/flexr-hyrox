// FLEXR - Training Architecture Model
// User-defined training structure

import Foundation

struct TrainingArchitecture: Codable, Identifiable {
    var id: UUID
    var userId: UUID?
    var name: String
    var isActive: Bool

    // Structure
    var daysPerWeek: Int
    var sessionsPerDay: Int
    var sessionTypes: [DaySchedule]

    // Preferences
    var preferredWorkoutDurationMinutes: Int
    var equipmentAvailable: [String]

    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name
        case userId = "user_id"
        case isActive = "is_active"
        case daysPerWeek = "days_per_week"
        case sessionsPerDay = "sessions_per_day"
        case sessionTypes = "session_types"
        case preferredWorkoutDurationMinutes = "preferred_workout_duration_minutes"
        case equipmentAvailable = "equipment_available"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID = UUID(),
        name: String = "My Training Plan",
        daysPerWeek: Int = 5,
        sessionsPerDay: Int = 1,
        sessionTypes: [DaySchedule] = [],
        preferredWorkoutDurationMinutes: Int = 60,
        equipmentAvailable: [String] = []
    ) {
        self.id = id
        self.name = name
        self.isActive = true
        self.daysPerWeek = daysPerWeek
        self.sessionsPerDay = sessionsPerDay
        self.sessionTypes = sessionTypes
        self.preferredWorkoutDurationMinutes = preferredWorkoutDurationMinutes
        self.equipmentAvailable = equipmentAvailable
    }
}

struct DaySchedule: Codable, Identifiable {
    var id: UUID
    var day: Int // 1-7 (Monday-Sunday)
    var sessions: [SessionDefinition]

    init(day: Int, sessions: [SessionDefinition]) {
        self.id = UUID()
        self.day = day
        self.sessions = sessions
    }

    var dayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.weekdaySymbols[day % 7]
    }
}

struct SessionDefinition: Codable, Identifiable {
    var id: UUID
    var type: SessionType
    var timeOfDay: TimeOfDay
    var durationMinutes: Int?
    var notes: String?

    init(type: SessionType, timeOfDay: TimeOfDay, durationMinutes: Int? = nil, notes: String? = nil) {
        self.id = UUID()
        self.type = type
        self.timeOfDay = timeOfDay
        self.durationMinutes = durationMinutes
        self.notes = notes
    }

    enum CodingKeys: String, CodingKey {
        case id, type, notes
        case timeOfDay = "time_of_day"
        case durationMinutes = "duration_minutes"
    }
}

enum SessionType: String, Codable, CaseIterable {
    case run = "run"
    case strength = "strength"
    case hyroxSimulation = "hyrox_simulation"
    case stationFocus = "station_focus"
    case intervals = "intervals"
    case recovery = "recovery"
    case flexibility = "flexibility"
    case cross = "cross" // Cross-training

    var displayName: String {
        switch self {
        case .run: return "Running"
        case .strength: return "Strength"
        case .hyroxSimulation: return "HYROX Simulation"
        case .stationFocus: return "Station Focus"
        case .intervals: return "Intervals"
        case .recovery: return "Recovery"
        case .flexibility: return "Flexibility"
        case .cross: return "Cross Training"
        }
    }

    var icon: String {
        switch self {
        case .run: return "figure.run"
        case .strength: return "dumbbell.fill"
        case .hyroxSimulation: return "flame.fill"
        case .stationFocus: return "target"
        case .intervals: return "timer"
        case .recovery: return "heart.fill"
        case .flexibility: return "figure.yoga"
        case .cross: return "figure.mixed.cardio"
        }
    }

    var color: String {
        switch self {
        case .run: return "blue"
        case .strength: return "orange"
        case .hyroxSimulation: return "red"
        case .stationFocus: return "purple"
        case .intervals: return "yellow"
        case .recovery: return "green"
        case .flexibility: return "cyan"
        case .cross: return "gray"
        }
    }
}

enum TimeOfDay: String, Codable, CaseIterable {
    case earlyMorning = "early_morning" // 5-7 AM
    case morning = "morning"             // 7-10 AM
    case midday = "midday"               // 10 AM - 2 PM
    case afternoon = "afternoon"         // 2-5 PM
    case evening = "evening"             // 5-8 PM
    case night = "night"                 // 8-10 PM

    var displayName: String {
        switch self {
        case .earlyMorning: return "Early Morning"
        case .morning: return "Morning"
        case .midday: return "Midday"
        case .afternoon: return "Afternoon"
        case .evening: return "Evening"
        case .night: return "Night"
        }
    }

    var timeRange: String {
        switch self {
        case .earlyMorning: return "5-7 AM"
        case .morning: return "7-10 AM"
        case .midday: return "10 AM-2 PM"
        case .afternoon: return "2-5 PM"
        case .evening: return "5-8 PM"
        case .night: return "8-10 PM"
        }
    }

    var icon: String {
        switch self {
        case .earlyMorning: return "sunrise.fill"
        case .morning: return "sun.max.fill"
        case .midday: return "sun.max.fill"
        case .afternoon: return "sun.haze.fill"
        case .evening: return "sunset.fill"
        case .night: return "moon.fill"
        }
    }
}

// MARK: - Equipment
enum Equipment: String, Codable, CaseIterable {
    case skiErg = "ski_erg"
    case rower = "rower"
    case sled = "sled"
    case wallBalls = "wall_balls"
    case sandbag = "sandbag"
    case kettlebells = "kettlebells"
    case farmersCarryHandles = "farmers_carry_handles"
    case pullUpBar = "pull_up_bar"
    case treadmill = "treadmill"
    case track = "track"

    var displayName: String {
        switch self {
        case .skiErg: return "Ski Erg"
        case .rower: return "Rowing Machine"
        case .sled: return "Sled"
        case .wallBalls: return "Wall Balls"
        case .sandbag: return "Sandbag"
        case .kettlebells: return "Kettlebells"
        case .farmersCarryHandles: return "Farmers Carry Handles"
        case .pullUpBar: return "Pull-up Bar"
        case .treadmill: return "Treadmill"
        case .track: return "Running Track"
        }
    }

    var icon: String {
        switch self {
        case .skiErg: return "figure.skiing.downhill"
        case .rower: return "oar.2.crossed"
        case .sled: return "figure.strengthtraining.traditional"
        case .wallBalls: return "circle.fill"
        case .sandbag: return "bag.fill"
        case .kettlebells: return "dumbbell.fill"
        case .farmersCarryHandles: return "hand.raised.fill"
        case .pullUpBar: return "figure.gymnastics"
        case .treadmill: return "figure.run.treadmill"
        case .track: return "figure.track.and.field"
        }
    }

    /// Which HYROX station this equipment enables
    var enablesStation: StationType? {
        switch self {
        case .skiErg: return .skiErg
        case .rower: return .rowing
        case .sled: return nil // Enables both push and pull
        case .wallBalls: return .wallBalls
        case .sandbag: return .sandbagLunges
        case .farmersCarryHandles: return .farmersCarry
        default: return nil
        }
    }
}

// MARK: - Preset Architectures
extension TrainingArchitecture {
    static let presets: [TrainingArchitecture] = [
        // Beginner: 3 days/week
        TrainingArchitecture(
            name: "Beginner (3 days)",
            daysPerWeek: 3,
            sessionsPerDay: 1,
            sessionTypes: [
                DaySchedule(day: 1, sessions: [SessionDefinition(type: .run, timeOfDay: .morning)]),
                DaySchedule(day: 3, sessions: [SessionDefinition(type: .stationFocus, timeOfDay: .morning)]),
                DaySchedule(day: 5, sessions: [SessionDefinition(type: .hyroxSimulation, timeOfDay: .morning)])
            ],
            preferredWorkoutDurationMinutes: 45
        ),

        // Intermediate: 5 days/week
        TrainingArchitecture(
            name: "Intermediate (5 days)",
            daysPerWeek: 5,
            sessionsPerDay: 1,
            sessionTypes: [
                DaySchedule(day: 1, sessions: [SessionDefinition(type: .run, timeOfDay: .morning)]),
                DaySchedule(day: 2, sessions: [SessionDefinition(type: .strength, timeOfDay: .morning)]),
                DaySchedule(day: 3, sessions: [SessionDefinition(type: .stationFocus, timeOfDay: .morning)]),
                DaySchedule(day: 4, sessions: [SessionDefinition(type: .run, timeOfDay: .morning)]),
                DaySchedule(day: 5, sessions: [SessionDefinition(type: .hyroxSimulation, timeOfDay: .morning)])
            ],
            preferredWorkoutDurationMinutes: 60
        ),

        // Advanced: 5-6 days, 2 sessions
        TrainingArchitecture(
            name: "Advanced (2x daily)",
            daysPerWeek: 6,
            sessionsPerDay: 2,
            sessionTypes: [
                DaySchedule(day: 1, sessions: [
                    SessionDefinition(type: .run, timeOfDay: .earlyMorning),
                    SessionDefinition(type: .strength, timeOfDay: .evening)
                ]),
                DaySchedule(day: 2, sessions: [
                    SessionDefinition(type: .run, timeOfDay: .earlyMorning),
                    SessionDefinition(type: .stationFocus, timeOfDay: .evening)
                ]),
                DaySchedule(day: 3, sessions: [
                    SessionDefinition(type: .run, timeOfDay: .earlyMorning),
                    SessionDefinition(type: .strength, timeOfDay: .evening)
                ]),
                DaySchedule(day: 4, sessions: [
                    SessionDefinition(type: .run, timeOfDay: .earlyMorning),
                    SessionDefinition(type: .stationFocus, timeOfDay: .evening)
                ]),
                DaySchedule(day: 5, sessions: [
                    SessionDefinition(type: .run, timeOfDay: .earlyMorning),
                    SessionDefinition(type: .intervals, timeOfDay: .evening)
                ]),
                DaySchedule(day: 6, sessions: [
                    SessionDefinition(type: .hyroxSimulation, timeOfDay: .morning)
                ])
            ],
            preferredWorkoutDurationMinutes: 75
        ),

        // Elite: 6 days, focused periodization
        TrainingArchitecture(
            name: "Elite Race Prep",
            daysPerWeek: 6,
            sessionsPerDay: 2,
            sessionTypes: [
                DaySchedule(day: 1, sessions: [
                    SessionDefinition(type: .run, timeOfDay: .earlyMorning, durationMinutes: 45),
                    SessionDefinition(type: .strength, timeOfDay: .evening, durationMinutes: 60)
                ]),
                DaySchedule(day: 2, sessions: [
                    SessionDefinition(type: .intervals, timeOfDay: .earlyMorning, durationMinutes: 40),
                    SessionDefinition(type: .stationFocus, timeOfDay: .evening, durationMinutes: 45)
                ]),
                DaySchedule(day: 3, sessions: [
                    SessionDefinition(type: .run, timeOfDay: .earlyMorning, durationMinutes: 60),
                    SessionDefinition(type: .flexibility, timeOfDay: .evening, durationMinutes: 30)
                ]),
                DaySchedule(day: 4, sessions: [
                    SessionDefinition(type: .run, timeOfDay: .earlyMorning, durationMinutes: 45),
                    SessionDefinition(type: .stationFocus, timeOfDay: .evening, durationMinutes: 60)
                ]),
                DaySchedule(day: 5, sessions: [
                    SessionDefinition(type: .intervals, timeOfDay: .earlyMorning, durationMinutes: 40),
                    SessionDefinition(type: .strength, timeOfDay: .evening, durationMinutes: 45)
                ]),
                DaySchedule(day: 6, sessions: [
                    SessionDefinition(type: .hyroxSimulation, timeOfDay: .morning, durationMinutes: 90)
                ])
            ],
            preferredWorkoutDurationMinutes: 60
        )
    ]
}
