import Foundation

/// Represents a section of a workout (warm-up, strength, WOD, finisher, cooldown)
/// Used for UI grouping and display with format metadata
struct WorkoutSection: Identifiable, Codable, Equatable {
    let id: UUID
    let type: SectionType
    let label: String
    let format: WODFormat?
    let formatDetails: FormatDetails?
    var segments: [WorkoutSegment]

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case label
        case format
        case formatDetails = "format_details"
        case segments
    }

    init(
        id: UUID = UUID(),
        type: SectionType,
        label: String,
        format: WODFormat? = nil,
        formatDetails: FormatDetails? = nil,
        segments: [WorkoutSegment] = []
    ) {
        self.id = id
        self.type = type
        self.label = label
        self.format = format
        self.formatDetails = formatDetails
        self.segments = segments
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        type = try container.decode(SectionType.self, forKey: .type)
        label = try container.decode(String.self, forKey: .label)
        format = try container.decodeIfPresent(WODFormat.self, forKey: .format)
        formatDetails = try container.decodeIfPresent(FormatDetails.self, forKey: .formatDetails)
        segments = try container.decodeIfPresent([WorkoutSegment].self, forKey: .segments) ?? []
    }

    // MARK: - Computed Properties

    /// Display title for the section header (e.g., "WOD: EMOM 16")
    var displayTitle: String {
        if let format = format, let details = formatDetails {
            switch format {
            case .emom:
                if let minutes = details.totalMinutes {
                    return "\(label): EMOM \(minutes)"
                }
            case .amrap:
                if let cap = details.timeCapMinutes {
                    return "\(label): AMRAP \(cap)"
                }
            case .forTime:
                if let rounds = details.rounds {
                    return "\(label): \(rounds) Rounds For Time"
                }
                return "\(label): For Time"
            case .tabata:
                return "\(label): Tabata"
            case .rounds:
                if let rounds = details.rounds {
                    return "\(label): \(rounds) Rounds"
                }
            }
        }
        return label
    }

    /// Subtitle with format details (e.g., "4 movements, 4 rounds each")
    var displaySubtitle: String? {
        guard let format = format, let details = formatDetails else { return nil }

        switch format {
        case .emom:
            if let movements = details.movementsPerRound, let rounds = details.rounds {
                return "\(movements) movements × \(rounds) rounds"
            }
        case .amrap:
            return "As many rounds as possible"
        case .forTime:
            if let cap = details.timeCapMinutes {
                return "Time cap: \(cap) min"
            }
        case .tabata:
            if let work = details.workSeconds, let rest = details.restSeconds, let rounds = details.rounds {
                return "\(work)s work / \(rest)s rest × \(rounds) rounds"
            }
        case .rounds:
            return "For quality"
        }
        return nil
    }

    /// Estimated duration for this section in seconds
    var estimatedDuration: TimeInterval {
        // Calculate based on format details or segment durations
        if let format = format, let details = formatDetails {
            switch format {
            case .emom:
                if let minutes = details.totalMinutes {
                    return TimeInterval(minutes * 60)
                }
            case .amrap:
                if let cap = details.timeCapMinutes {
                    return TimeInterval(cap * 60)
                }
            case .tabata:
                if let work = details.workSeconds, let rest = details.restSeconds, let rounds = details.rounds {
                    return TimeInterval((work + rest) * rounds)
                }
            case .forTime:
                if let cap = details.timeCapMinutes {
                    return TimeInterval(cap * 60)
                }
            case .rounds:
                break
            }
        }

        // Fallback to sum of segment durations
        return segments.compactMap { $0.targetDuration }.reduce(0, +)
    }

    /// Icon for the section type
    var icon: String {
        type.icon
    }
}

// MARK: - Section Type

enum SectionType: String, Codable, CaseIterable {
    case warmup
    case strength
    case wod
    case finisher
    case cooldown

    var displayName: String {
        switch self {
        case .warmup: return "Warm-up"
        case .strength: return "Strength"
        case .wod: return "WOD"
        case .finisher: return "Finisher"
        case .cooldown: return "Cool-down"
        }
    }

    var icon: String {
        switch self {
        case .warmup: return "flame.fill"
        case .strength: return "dumbbell.fill"
        case .wod: return "bolt.fill"
        case .finisher: return "flame"
        case .cooldown: return "snowflake"
        }
    }

    var color: String {
        switch self {
        case .warmup: return "orange"
        case .strength: return "blue"
        case .wod: return "green"
        case .finisher: return "red"
        case .cooldown: return "cyan"
        }
    }
}

// MARK: - WOD Format

enum WODFormat: String, Codable, CaseIterable {
    case emom
    case amrap
    case forTime = "for_time"
    case tabata
    case rounds

    var displayName: String {
        switch self {
        case .emom: return "EMOM"
        case .amrap: return "AMRAP"
        case .forTime: return "For Time"
        case .tabata: return "Tabata"
        case .rounds: return "Rounds"
        }
    }

    var description: String {
        switch self {
        case .emom: return "Every Minute On the Minute"
        case .amrap: return "As Many Rounds As Possible"
        case .forTime: return "Complete as fast as possible"
        case .tabata: return "20s work / 10s rest intervals"
        case .rounds: return "Complete X rounds for quality"
        }
    }
}

// MARK: - Format Details

struct FormatDetails: Codable, Equatable {
    let totalMinutes: Int?
    let rounds: Int?
    let movementsPerRound: Int?
    let workSeconds: Int?
    let restSeconds: Int?
    let timeCapMinutes: Int?

    enum CodingKeys: String, CodingKey {
        case totalMinutes = "total_minutes"
        case rounds
        case movementsPerRound = "movements_per_round"
        case workSeconds = "work_seconds"
        case restSeconds = "rest_seconds"
        case timeCapMinutes = "time_cap_minutes"
    }

    init(
        totalMinutes: Int? = nil,
        rounds: Int? = nil,
        movementsPerRound: Int? = nil,
        workSeconds: Int? = nil,
        restSeconds: Int? = nil,
        timeCapMinutes: Int? = nil
    ) {
        self.totalMinutes = totalMinutes
        self.rounds = rounds
        self.movementsPerRound = movementsPerRound
        self.workSeconds = workSeconds
        self.restSeconds = restSeconds
        self.timeCapMinutes = timeCapMinutes
    }
}

// MARK: - Sections Metadata (stored on Workout)

struct SectionMetadata: Codable, Equatable {
    let type: SectionType
    let label: String
    let format: WODFormat?
    let formatDetails: FormatDetails?
    let segmentCount: Int

    enum CodingKeys: String, CodingKey {
        case type
        case label
        case format
        case formatDetails = "format_details"
        case segmentCount = "segment_count"
    }
}
