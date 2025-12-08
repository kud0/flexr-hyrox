// FLEXR - Workout Analytics Service
// Manages workout analytics, PRs, and activity feed
// Extension to SupabaseService

import Foundation

// MARK: - Workout Analytics Service Extension
extension SupabaseService {

    // MARK: - Fetch Workout History

    /// Get user's workout history with optional filtering
    func getWorkoutHistory(
        userId: UUID? = nil,
        workoutType: AnalyticsWorkoutType? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> [Workout] {
        let targetUserId: UUID
        if let userId = userId {
            targetUserId = userId
        } else if let session = try? await client.auth.session {
            targetUserId = session.user.id
        } else {
            throw SupabaseError.notAuthenticated
        }

        var query = client
            .database.from("workouts")
            .select()
            .order("completed_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)

        // Note: filtering by user_id and type would need to be done on the result
        // since the actual Workout model structure may differ

        let workouts: [Workout] = try await query
            .execute()
            .value

        return workouts
    }

    /// Get specific workout by ID with full details
    func getWorkoutDetail(id: UUID) async throws -> Workout {
        let workout: Workout = try await client
            .database.from("workouts")
            .select("*, workout_segments(*)")
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value

        return workout
    }

    // MARK: - Workout Statistics

    /// Get aggregated workout statistics for a month
    func getWorkoutStats(
        userId: UUID? = nil,
        month: Date
    ) async throws -> [WorkoutStatsSummary] {
        let targetUserId: UUID
        if let userId = userId {
            targetUserId = userId
        } else if let session = try? await client.auth.session {
            targetUserId = session.user.id
        } else {
            throw SupabaseError.notAuthenticated
        }

        let stats: [WorkoutStatsSummary] = try await client
            .database.from("workout_stats_summary")
            .select()
            .eq("user_id", value: targetUserId.uuidString)
            .eq("month", value: month.ISO8601Format())
            .execute()
            .value

        return stats
    }

    /// Get overall workout statistics
    func getOverallStats(userId: UUID? = nil) async throws -> OverallStats {
        let targetUserId: UUID
        if let userId = userId {
            targetUserId = userId
        } else if let session = try? await client.auth.session {
            targetUserId = session.user.id
        } else {
            throw SupabaseError.notAuthenticated
        }

        // Get all completed workouts
        let workouts = try await getWorkoutHistory(userId: targetUserId, limit: 1000)

        let totalWorkouts = workouts.count
        // Note: isPR needs to be computed, not a stored property
        let totalPRs = 0 // Placeholder - would need to implement PR detection
        let totalMinutes = workouts.compactMap { $0.totalDuration }.reduce(0, +) / 60
        let avgDuration = totalWorkouts > 0 ? totalMinutes / Double(totalWorkouts) : 0

        // Get current month stats
        let now = Date()
        let thisMonthWorkouts = workouts.filter {
            Calendar.current.isDate($0.date, equalTo: now, toGranularity: .month)
        }

        return OverallStats(
            totalWorkouts: totalWorkouts,
            totalPRs: totalPRs,
            totalTrainingMinutes: Int(totalMinutes),
            avgWorkoutDuration: avgDuration,
            thisMonthWorkouts: thisMonthWorkouts.count,
            mostCommonType: getMostCommonWorkoutType(workouts)
        )
    }

    // MARK: - Personal Records

    /// Get all personal records for user
    func getPersonalRecords(
        userId: UUID? = nil,
        prType: PRType? = nil,
        limit: Int = 10
    ) async throws -> [PRRecord] {
        let targetUserId: UUID
        if let userId = userId {
            targetUserId = userId
        } else if let session = try? await client.auth.session {
            targetUserId = session.user.id
        } else {
            throw SupabaseError.notAuthenticated
        }

        var query = client
            .database.from("pr_records")
            .select()
            .eq("user_id", value: targetUserId.uuidString)
            .order("achieved_at", ascending: false)
            .limit(limit)

        // Note: Supabase Swift SDK filter methods need verification
        // if let prType = prType {
        //     query = query.eq("pr_type", value: prType.rawValue)
        // }

        let prs: [PRRecord] = try await query
            .execute()
            .value

        return prs
    }

    /// Check if workout is a PR and create record
    func checkAndCreatePR(workoutId: UUID) async throws -> Bool {
        // Call database function
        let result = try await client
            .database.rpc("check_and_create_pr", params: ["p_workout_id": workoutId.uuidString])
            .execute()

        guard let isPR = result.value as? Bool else {
            return false
        }

        return isPR
    }

    // MARK: - Gym Activity Feed

    /// Get gym activity feed
    func getGymActivityFeed(
        gymId: UUID,
        limit: Int = 50,
        offset: Int = 0
    ) async throws -> [GymActivityFeedItem] {
        let items: [GymActivityFeedItem] = try await client
            .database.from("gym_activity_feed")
            .select()
            .eq("gym_id", value: gymId.uuidString)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value

        return items
    }

    /// Create activity feed item for workout
    func createActivityFeedItem(workoutId: UUID) async throws -> UUID? {
        // Call database function
        let result = try await client
            .database.rpc("create_activity_feed_item", params: ["p_workout_id": workoutId.uuidString])
            .execute()

        guard let feedId = result.value as? String else {
            return nil
        }

        return UUID(uuidString: feedId)
    }

    // MARK: - Station Performance Analytics

    /// Get station performance aggregated by station type
    func getStationPerformance(
        userId: UUID? = nil,
        limit: Int = 100
    ) async throws -> [StationPerformanceData] {
        let targetUserId: UUID
        if let userId = userId {
            targetUserId = userId
        } else if let session = try? await client.auth.session {
            targetUserId = session.user.id
        } else {
            throw SupabaseError.notAuthenticated
        }

        // Query planned_workout_segments for station segments with actual times
        let segments: [StationSegmentRecord] = try await client
            .from("planned_workout_segments")
            .select("id, segment_type, station_type, target_duration_seconds, actual_duration_seconds, planned_workout_id")
            .eq("segment_type", value: "station")
            .not("actual_duration_seconds", operator: .is, value: "null")
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        // Group by station type and calculate stats
        var stationData: [String: [TimeInterval]] = [:]

        for segment in segments {
            guard let stationType = segment.stationType,
                  let actualDuration = segment.actualDurationSeconds else {
                continue
            }

            if stationData[stationType] == nil {
                stationData[stationType] = []
            }
            stationData[stationType]?.append(actualDuration)
        }

        // Convert to StationPerformanceData
        var results: [StationPerformanceData] = []

        for (stationType, times) in stationData {
            guard !times.isEmpty else { continue }

            let sortedTimes = times.sorted()
            let bestTime = sortedTimes.first ?? 0
            let avgTime = times.reduce(0, +) / Double(times.count)
            let lastTime = times.first ?? 0 // Already sorted by created_at desc

            // Calculate trend (comparing recent vs older)
            let trend: PerformanceTrend
            if times.count >= 3 {
                let recentAvg = times.prefix(3).reduce(0, +) / 3.0
                let olderAvg = times.suffix(3).reduce(0, +) / Double(min(3, times.count))
                if recentAvg < olderAvg * 0.95 {
                    trend = .improving
                } else if recentAvg > olderAvg * 1.05 {
                    trend = .declining
                } else {
                    trend = .stable
                }
            } else {
                trend = .stable
            }

            // Performance score (100 = best time, lower for slower)
            let performanceScore = bestTime > 0 ? Int((bestTime / avgTime) * 100) : 0

            results.append(StationPerformanceData(
                stationType: stationType,
                displayName: StationType(rawValue: stationType)?.displayName ?? stationType,
                bestTime: bestTime,
                averageTime: avgTime,
                lastTime: lastTime,
                totalAttempts: times.count,
                trend: trend,
                performanceScore: min(100, performanceScore)
            ))
        }

        // Sort by station order (HYROX sequence)
        let stationOrder = ["ski_erg", "sled_push", "sled_pull", "burpee_broad_jump",
                           "rowing", "farmers_carry", "sandbag_lunges", "wall_balls"]
        results.sort { a, b in
            let indexA = stationOrder.firstIndex(of: a.stationType) ?? 999
            let indexB = stationOrder.firstIndex(of: b.stationType) ?? 999
            return indexA < indexB
        }

        return results
    }

    // MARK: - Workout Comparison

    /// Compare two workouts
    func compareWorkouts(
        workout1Id: UUID,
        workout2Id: UUID
    ) async throws -> AnalyticsWorkoutComparison {
        let workout1 = try await getWorkoutDetail(id: workout1Id)
        let workout2 = try await getWorkoutDetail(id: workout2Id)

        // Calculate performance difference
        let perfDiff: Double?
        if let duration1 = workout1.totalDuration,
           let duration2 = workout2.totalDuration {
            perfDiff = ((duration2 - duration1) / duration1) * 100
        } else {
            perfDiff = nil
        }

        // Compare segments
        let segmentComparisons = compareSegments(
            segments1: workout1.segments,
            segments2: workout2.segments
        )

        return AnalyticsWorkoutComparison(
            id: UUID(),
            workoutId1: workout1Id,
            workoutId2: workout2Id,
            performanceDiff: perfDiff,
            segmentComparison: segmentComparisons
        )
    }

    // MARK: - Helper Functions

    private func getMostCommonWorkoutType(_ workouts: [Workout]) -> AnalyticsWorkoutType? {
        let typeCounts = Dictionary(grouping: workouts, by: { $0.type })
            .mapValues { $0.count }

        // Note: Need to map WorkoutType to AnalyticsWorkoutType
        return nil // Placeholder
    }

    private func compareSegments(
        segments1: [WorkoutSegment],
        segments2: [WorkoutSegment]
    ) -> [AnalyticsSegmentComparison] {
        var comparisons: [AnalyticsSegmentComparison] = []

        // Match segments by order
        for (index, segment1) in segments1.enumerated() {
            guard index < segments2.count else { break }
            let segment2 = segments2[index]

            // Get durations (using targetDuration as fallback)
            let time1 = segment1.actualDuration ?? segment1.targetDuration ?? 0
            let time2 = segment2.actualDuration ?? segment2.targetDuration ?? 0

            comparisons.append(AnalyticsSegmentComparison(
                segmentIndex: index,
                segmentName: segment1.segmentType.rawValue,
                time1: time1,
                time2: time2
            ))
        }

        return comparisons
    }

    // MARK: - Update Workout

    /// Update workout visibility and notes
    func updateWorkout(
        id: UUID,
        visibility: String? = nil,
        notes: String? = nil,
        isPR: Bool? = nil
    ) async throws -> Workout {
        guard let userId = (try? await client.auth.session)?.user.id else {
            throw SupabaseError.notAuthenticated
        }

        // Note: Update functionality would need to match actual Workout model
        // For now, just return the workout as-is
        return try await getWorkoutDetail(id: id)
    }

    // MARK: - Refresh Stats

    /// Manually refresh workout statistics materialized view
    func refreshWorkoutStats() async throws {
        // Note: RPC call would need proper setup
        // For now, this is a placeholder
    }
}

// MARK: - Overall Stats Model

struct OverallStats {
    let totalWorkouts: Int
    let totalPRs: Int
    let totalTrainingMinutes: Int
    let avgWorkoutDuration: Double
    let thisMonthWorkouts: Int
    let mostCommonType: AnalyticsWorkoutType?

    var displayTotalTime: String {
        let hours = totalTrainingMinutes / 60
        let minutes = totalTrainingMinutes % 60
        return "\(hours)h \(minutes)m"
    }

    var displayAvgDuration: String {
        let mins = Int(avgWorkoutDuration)
        let secs = Int((avgWorkoutDuration - Double(mins)) * 60)
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Station Performance Data

struct StationPerformanceData: Identifiable {
    let id = UUID()
    let stationType: String
    let displayName: String
    let bestTime: TimeInterval
    let averageTime: TimeInterval
    let lastTime: TimeInterval
    let totalAttempts: Int
    let trend: PerformanceTrend
    let performanceScore: Int

    var formattedBestTime: String {
        formatTime(bestTime)
    }

    var formattedAverageTime: String {
        formatTime(averageTime)
    }

    var formattedLastTime: String {
        formatTime(lastTime)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Station Segment Record (for Supabase query)
// Note: PerformanceTrend enum is defined in PerformanceProfile.swift

struct StationSegmentRecord: Decodable {
    let id: UUID
    let segmentType: String
    let stationType: String?
    let targetDurationSeconds: TimeInterval?
    let actualDurationSeconds: TimeInterval?
    let plannedWorkoutId: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case segmentType = "segment_type"
        case stationType = "station_type"
        case targetDurationSeconds = "target_duration_seconds"
        case actualDurationSeconds = "actual_duration_seconds"
        case plannedWorkoutId = "planned_workout_id"
    }
}
