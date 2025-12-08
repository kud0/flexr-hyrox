import Foundation
import CoreData

@objc(CompromisedRunEntity)
public class CompromisedRunEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var segmentIndex: Int32
    @NSManaged public var segmentName: String?
    @NSManaged public var expectedPace: Double
    @NSManaged public var actualPace: Double
    @NSManaged public var degradation: Double
    @NSManaged public var workout: WorkoutEntity?
}
