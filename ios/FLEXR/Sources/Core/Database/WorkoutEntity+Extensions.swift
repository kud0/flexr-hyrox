import Foundation
import CoreData

// MARK: - WorkoutEntity Extensions
// Conversion between WorkoutSummary (struct) and WorkoutEntity (CoreData)

extension WorkoutEntity {

    /// Create WorkoutEntity from WorkoutSummary struct
    convenience init(from summary: WorkoutSummary, context: NSManagedObjectContext) {
        self.init(context: context)

        self.id = summary.id
        self.workoutName = summary.workoutName
        self.workoutDate = summary.date
        self.totalTime = summary.totalTime
        self.segmentsCompleted = Int32(summary.segmentsCompleted)
        self.totalSegments = Int32(summary.totalSegments)
        self.averageHeartRate = Int32(summary.averageHeartRate)
        self.maxHeartRate = Int32(summary.maxHeartRate)
        self.activeCalories = Int32(summary.activeCalories)
        self.totalDistance = summary.totalDistance
        self.createdAt = Date()
        self.syncedToBackend = false

        // Convert segment results to entities
        for segmentResult in summary.segmentResults {
            let segmentEntity = SegmentEntity(context: context)
            segmentEntity.id = UUID()
            segmentEntity.segmentIndex = Int32(segmentResult.index)
            segmentEntity.segmentName = segmentResult.name
            segmentEntity.segmentType = segmentResult.type
            segmentEntity.duration = segmentResult.duration
            segmentEntity.distance = segmentResult.distance ?? 0.0
            segmentEntity.averageHeartRate = Int32(segmentResult.averageHeartRate ?? 0)
            segmentEntity.caloriesBurned = Int32(segmentResult.caloriesBurned ?? 0)
            segmentEntity.completedAt = segmentResult.completedAt
            segmentEntity.workout = self
            self.addToSegments(segmentEntity)
        }

        // Convert compromised runs to entities
        for run in summary.compromisedRuns {
            let runEntity = CompromisedRunEntity(context: context)
            runEntity.id = UUID()
            runEntity.segmentIndex = Int32(run.segmentIndex)
            runEntity.segmentName = run.segmentName
            runEntity.expectedPace = run.expectedPace
            runEntity.actualPace = run.actualPace
            runEntity.degradation = run.degradation
            runEntity.workout = self
            self.addToCompromisedRuns(runEntity)
        }
    }

    /// Convert WorkoutEntity back to WorkoutSummary struct
    func toWorkoutSummary() -> WorkoutSummary {
        let segmentResults = (segments?.allObjects as? [SegmentEntity])?.map { segment in
            SegmentResult(
                index: Int(segment.segmentIndex),
                name: segment.segmentName ?? "",
                type: segment.segmentType ?? "",
                duration: segment.duration,
                distance: segment.distance,
                averageHeartRate: Int(segment.averageHeartRate),
                caloriesBurned: Int(segment.caloriesBurned),
                completedAt: segment.completedAt ?? Date()
            )
        } ?? []

        let compromisedRuns = (self.compromisedRuns?.allObjects as? [CompromisedRunEntity])?.map { run in
            CompromisedRun(
                segmentIndex: Int(run.segmentIndex),
                segmentName: run.segmentName ?? "",
                expectedPace: run.expectedPace,
                actualPace: run.actualPace,
                degradation: run.degradation
            )
        } ?? []

        return WorkoutSummary(
            id: id ?? UUID(),
            workoutName: workoutName ?? "",
            date: workoutDate ?? Date(),
            totalTime: totalTime,
            segmentsCompleted: Int(segmentsCompleted),
            totalSegments: Int(totalSegments),
            averageHeartRate: Int(averageHeartRate),
            maxHeartRate: Int(maxHeartRate),
            activeCalories: Int(activeCalories),
            totalDistance: totalDistance,
            compromisedRuns: compromisedRuns,
            routeData: nil, // Not stored in CoreData yet
            segmentResults: segmentResults
        )
    }
}
