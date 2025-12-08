import Foundation
import CoreData

@objc(WorkoutEntity)
public class WorkoutEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var workoutName: String?
    @NSManaged public var workoutDate: Date?
    @NSManaged public var totalTime: Double
    @NSManaged public var segmentsCompleted: Int32
    @NSManaged public var totalSegments: Int32
    @NSManaged public var averageHeartRate: Int32
    @NSManaged public var maxHeartRate: Int32
    @NSManaged public var activeCalories: Int32
    @NSManaged public var totalDistance: Double
    @NSManaged public var createdAt: Date?
    @NSManaged public var syncedToBackend: Bool
    @NSManaged public var segments: NSSet?
    @NSManaged public var compromisedRuns: NSSet?
}

// MARK: Generated accessors for segments
extension WorkoutEntity {
    @objc(addSegmentsObject:)
    @NSManaged public func addToSegments(_ value: SegmentEntity)

    @objc(removeSegmentsObject:)
    @NSManaged public func removeFromSegments(_ value: SegmentEntity)

    @objc(addSegments:)
    @NSManaged public func addToSegments(_ values: NSSet)

    @objc(removeSegments:)
    @NSManaged public func removeFromSegments(_ values: NSSet)
}

// MARK: Generated accessors for compromisedRuns
extension WorkoutEntity {
    @objc(addCompromisedRunsObject:)
    @NSManaged public func addToCompromisedRuns(_ value: CompromisedRunEntity)

    @objc(removeCompromisedRunsObject:)
    @NSManaged public func removeFromCompromisedRuns(_ value: CompromisedRunEntity)

    @objc(addCompromisedRuns:)
    @NSManaged public func addToCompromisedRuns(_ values: NSSet)

    @objc(removeCompromisedRuns:)
    @NSManaged public func removeFromCompromisedRuns(_ values: NSSet)
}
