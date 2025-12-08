import Foundation
import CoreData

// MARK: - Core Data Entity Extensions

extension WorkoutEntity {
    convenience init(from summary: WorkoutSummary, context: NSManagedObjectContext) {
        self.init(context: context)
        self.id = summary.id
        self.workoutName = summary.workoutName
        self.workoutDate = summary.date
        self.totalTime = summary.totalTime
        self.totalDistance = summary.totalDistance
        self.activeCalories = Int32(summary.activeCalories)
        self.averageHeartRate = Int32(summary.averageHeartRate)
        self.maxHeartRate = Int32(summary.maxHeartRate)
        self.segmentsCompleted = Int32(summary.segmentsCompleted)
        self.totalSegments = Int32(summary.totalSegments)
        self.createdAt = Date()
        self.syncedToBackend = false

        // Add segments
        for segmentResult in summary.segmentResults {
            let segment = SegmentEntity(context: context)
            segment.id = UUID()
            segment.segmentIndex = Int32(segmentResult.index)
            segment.segmentName = segmentResult.name
            segment.segmentType = segmentResult.type
            segment.duration = segmentResult.duration
            segment.distance = segmentResult.distance ?? 0
            segment.averageHeartRate = Int32(segmentResult.averageHeartRate ?? 0)
            segment.caloriesBurned = Int32(segmentResult.caloriesBurned ?? 0)
            segment.completedAt = segmentResult.completedAt
            segment.workout = self
        }

        // Add compromised runs
        for compromisedRun in summary.compromisedRuns {
            let run = CompromisedRunEntity(context: context)
            run.id = UUID()
            run.segmentIndex = Int32(compromisedRun.segmentIndex)
            run.segmentName = compromisedRun.segmentName
            run.expectedPace = compromisedRun.expectedPace
            run.actualPace = compromisedRun.actualPace
            run.degradation = compromisedRun.degradation
            run.workout = self
        }
    }

    func toWorkoutSummary() -> WorkoutSummary {
        let segments = (self.segments?.allObjects as? [SegmentEntity] ?? [])
            .sorted { $0.segmentIndex < $1.segmentIndex }
            .map { segment in
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
            }

        let compromised = (self.compromisedRuns?.allObjects as? [CompromisedRunEntity] ?? [])
            .sorted { $0.segmentIndex < $1.segmentIndex }
            .map { run in
                CompromisedRun(
                    segmentIndex: Int(run.segmentIndex),
                    segmentName: run.segmentName ?? "",
                    expectedPace: run.expectedPace,
                    actualPace: run.actualPace,
                    degradation: run.degradation
                )
            }

        return WorkoutSummary(
            id: self.id ?? UUID(),
            workoutName: self.workoutName ?? "",
            date: self.workoutDate ?? Date(),
            totalTime: self.totalTime,
            segmentsCompleted: Int(self.segmentsCompleted),
            totalSegments: Int(self.totalSegments),
            averageHeartRate: Int(self.averageHeartRate),
            maxHeartRate: Int(self.maxHeartRate),
            activeCalories: Int(self.activeCalories),
            totalDistance: self.totalDistance,
            compromisedRuns: compromised,
            segmentResults: segments
        )
    }
}
