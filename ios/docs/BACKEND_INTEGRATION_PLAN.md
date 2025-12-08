# FLEXR Backend Integration Plan

## Overview
Connect the analytics views to real Supabase data instead of mock data.

---

## Phase 1: Running Analytics (High Impact)

### 1.1 RunningHistoryView Integration
**Current**: Mock data in `RunningHistoryViewModel`
**Target**: Real data from `running_sessions` table

**Changes needed:**
- Update `RunningHistoryViewModel.loadSessions()` to call `SupabaseService.shared.getRunningSessions()`
- Map `RunningSession` model to view data
- The method already exists, just needs wiring

**Files:**
- `FLEXR/Sources/Features/Analytics/Views/RunningHistoryView.swift`

### 1.2 RunningStatsView Integration
**Current**: Mock aggregated stats
**Target**: Computed from `running_sessions` data

**Changes needed:**
- Add `getRunningStats()` method to SupabaseService
- Query: aggregate pace, distance, HR from running_sessions
- OR compute client-side from fetched sessions

**Files:**
- `FLEXR/Sources/Features/Analytics/Views/RunningStatsView.swift`
- `FLEXR/Sources/Core/Services/SupabaseService.swift`

### 1.3 RunningAnalyticsDetailView Integration
**Current**: Mock pace/HR/split data
**Target**: Real session detail with splits

**Changes needed:**
- Pass real `RunningSession` to detail view
- Display actual splits array
- Show real HR zone breakdown

**Files:**
- `FLEXR/Sources/Features/Analytics/Views/RunningAnalyticsDetailView.swift`

---

## Phase 2: Workout History (Already Partially Wired)

### 2.1 WorkoutHistoryView
**Current**: Already calls `getWorkoutHistory(limit: 500)` ✓
**Status**: Should work with real data if workouts exist

**Verify:**
- Test with real workout data
- Ensure segments load correctly
- Check date/duration formatting

### 2.2 WorkoutHistoryDetailView
**Current**: Uses passed `Workout` object
**Status**: Should work if parent passes real data

---

## Phase 3: Station Analytics (New Queries Needed)

### 3.1 StationHistoryView Integration
**Current**: Mock `StationPerformanceRecord` data
**Target**: Real data from `workout_segments` table

**New SupabaseService method needed:**
```swift
func getStationPerformances(station: String? = nil, limit: Int = 100) async throws -> [StationPerformanceRecord]
```

**Query approach:**
```sql
SELECT
  ws.id, ws.name, ws.actual_duration_minutes, ws.completion_status,
  w.completed_at, w.type as workout_type
FROM workout_segments ws
JOIN workouts w ON ws.workout_id = w.id
WHERE ws.type = 'station'
  AND ws.completion_status = 'completed'
  AND w.user_id = $userId
ORDER BY w.completed_at DESC
LIMIT $limit
```

**Files:**
- `FLEXR/Sources/Features/Analytics/Views/StationHistoryView.swift`
- `FLEXR/Sources/Core/Services/SupabaseService.swift`

### 3.2 AllStationsOverviewView Integration
**Current**: Mock station overview data
**Target**: Aggregated station stats

**New SupabaseService method needed:**
```swift
func getStationStats() async throws -> [StationOverviewData]
```

**Query approach:**
- Group by station name
- Calculate avg time, trend (compare last 5 vs previous 5)
- Count improving/stable/declining

**Files:**
- `FLEXR/Sources/Features/Analytics/Views/AllStationsOverviewView.swift`
- `FLEXR/Sources/Core/Services/SupabaseService.swift`

### 3.3 StationPerformanceDetailView
**Current**: Mock drill recommendations
**Status**: Keep mock for now (AI-generated recommendations)

---

## Phase 4: Heart Rate Analytics

### 4.1 HeartRateAnalyticsDetailView Integration
**Current**: Mock HR zone data
**Target**: Real HR data from workouts/segments

**Data sources:**
- `workouts.avg_heart_rate`, `workouts.max_heart_rate`
- `workout_segments` HR data (if tracked)
- `running_sessions.heart_rate_zones` (JSON: zone1-5 seconds)

**New method needed:**
```swift
func getHeartRateStats(days: Int = 30) async throws -> HeartRateAnalyticsData
```

**Files:**
- `FLEXR/Sources/Features/Analytics/Views/HeartRateAnalyticsDetailView.swift`
- `FLEXR/Sources/Core/Services/SupabaseService.swift`

---

## Phase 5: Training Load & Recovery

### 5.1 TrainingLoadDetailView
**Current**: Mock training load data
**Target**: Computed from workout frequency/intensity

**Calculation:**
- Training Load = Sum of (duration × intensity factor per workout type)
- Compare current week vs 4-week average

### 5.2 ReadinessDetailView
**Current**: Mock readiness scores
**Status**: Keep mock (requires HRV/sleep data from HealthKit)

---

## Implementation Priority

| Priority | View | Effort | Impact |
|----------|------|--------|--------|
| 1 | RunningHistoryView | Low | High |
| 2 | StationHistoryView | Medium | High |
| 3 | AllStationsOverviewView | Medium | High |
| 4 | RunningStatsView | Low | Medium |
| 5 | HeartRateAnalyticsDetailView | Medium | Medium |
| 6 | TrainingLoadDetailView | Medium | Medium |

---

## New SupabaseService Methods Required

```swift
// Phase 1
func getRunningStats(days: Int) async throws -> RunningStatsData

// Phase 3
func getStationPerformances(station: String?, limit: Int) async throws -> [SegmentPerformance]
func getStationStats() async throws -> [StationStats]

// Phase 4
func getHeartRateStats(days: Int) async throws -> HeartRateStats
```

---

## Data Model Mapping

### RunningSession (existing) → RunningHistoryView
- `sessionType` → filter chips
- `distanceMeters` → display distance
- `avgPacePerKm` → display pace
- `startedAt` → date grouping
- `splits` → detail view

### WorkoutSegment (existing) → StationHistoryView
- `name` (station name) → station filter
- `actualDuration` → time display
- `workout.completedAt` → date grouping
- Compare to previous → change indicator

---

## Testing Strategy

1. **Verify existing data**: Check Supabase dashboard for existing records
2. **Start with reads**: Wire up fetches before writes
3. **Fallback to mock**: If no data, show empty state or sample data
4. **Progressive enhancement**: Add real data as users complete workouts

---

## Files Changed Summary

**Modified:**
- `SupabaseService.swift` - Add 4 new methods
- `RunningHistoryView.swift` - Wire to real data
- `RunningStatsView.swift` - Wire to real data
- `StationHistoryView.swift` - Wire to real data
- `AllStationsOverviewView.swift` - Wire to real data
- `HeartRateAnalyticsDetailView.swift` - Wire to real data

**No changes needed:**
- `WorkoutHistoryView.swift` - Already wired
- `StationPerformanceDetailView.swift` - Keep mock recommendations
- `ReadinessDetailView.swift` - Needs HealthKit data
