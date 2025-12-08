import Foundation
import CoreData

@objc(SegmentEntity)
public class SegmentEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var segmentIndex: Int32
    @NSManaged public var segmentName: String?
    @NSManaged public var segmentType: String?
    @NSManaged public var duration: Double
    @NSManaged public var distance: Double
    @NSManaged public var averageHeartRate: Int32
    @NSManaged public var caloriesBurned: Int32
    @NSManaged public var completedAt: Date?
    @NSManaged public var workout: WorkoutEntity?
}
