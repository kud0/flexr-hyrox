# FLEXR Analytics System Audit Report

**Date:** December 6, 2024
**Status:** PARTIALLY IMPLEMENTED - Major gaps identified

---

## Executive Summary

The analytics system has a **significant mismatch** between database schema, Swift services, and UI components. Most UI views are using **local Core Data** or **placeholder/hardcoded values** instead of real Supabase backend data.

**Key Finding:** The database is well-designed with all the right tables, but the Swift code isn't using them properly.

---

## Critical Issues Found

### 1. AnalyticsService Uses Core Data Instead of Supabase

**File:** `FLEXR/Sources/Core/Services/AnalyticsService.swift`

The main analytics service queries **local Core Data** (WorkoutEntity) instead of Supabase. This means:
- Analytics only show data saved locally on the device
- No cloud sync of analytics
- Cross-device analytics don't work

**Hardcoded Placeholder Values Found:**

| Line | What | Current Value |
|------|------|---------------|
| ~256-260 | Pace Zones | Fixed zones, not from real data |
| ~291-299 | HR Zones | Fixed percentage distribution |
| ~287 | Performance Score | `performanceScore: 75 // Placeholder` |
| ~333-344 | Running Stats | `averagePace: "5:15", personalRecords: 3, zone2Percentage: 65` |

### 2. Running Analytics Uses Mock Data in DEBUG

**File:** `FLEXR/Sources/Features/Analytics/Running/RunningAnalyticsView.swift`

```swift
#if DEBUG
@State private var useMockData = true  // Lines 16-20
#else
@State private var useMockData = false
#endif
```

In development builds, this view shows **fake data** instead of real queries. This masks the fact that the real queries aren't implemented.

### 3. Database Tables Exist But Are Empty

| Table | Status | Why Empty |
|-------|--------|-----------|
| `running_sessions` | EXISTS but EMPTY | No HealthKit import implemented |
| `pr_records` | EXISTS but EMPTY | PR detection not called on workout save |
| `gym_activity_feed` | EXISTS but EMPTY | Activity feed not populated |
| `performance_profiles` | EXISTS but EMPTY | Recovery metrics not collected |
| `workout_feedback` | EXISTS but EMPTY | Feedback UI just implemented |

### 4. Missing Service Methods

**WorkoutAnalyticsService.swift needs:**
- `getRunningAnalytics()` - for running sessions
- `getStationAnalytics()` - for station performance
- `getHeartRateAnalytics()` - for HR zone analysis

**Missing entirely:**
- `RunningService.swift` - to manage running sessions
- `RecoveryService.swift` - to track recovery metrics

---

## What's Actually Working

| Component | Status | Data Source |
|-----------|--------|-------------|
| Dashboard workout count | ✅ WORKING | Supabase `workouts` table |
| Dashboard training minutes | ✅ WORKING | Supabase `workouts` table |
| Dashboard this week sessions | ✅ WORKING | Supabase `workouts` table |
| Today's planned workout | ✅ WORKING | Supabase `planned_workouts` table |
| Weekly plan view | ✅ WORKING | Supabase via PlanService |
| Workout feedback save | ✅ WORKING | Supabase `workout_feedback` table |

---

## Priority Fix List

### P0 - Critical (Broken Core Functionality)

| # | Issue | Impact | Effort |
|---|-------|--------|--------|
| 1 | AnalyticsService queries Core Data not Supabase | All analytics are local-only | HIGH |
| 2 | Running analytics mock data in DEBUG | Devs see fake data, masks bugs | LOW |
| 3 | No running session import from HealthKit | Can't track runs | MEDIUM |

### P1 - High (Major Gaps)

| # | Issue | Impact | Effort |
|---|-------|--------|--------|
| 4 | Hardcoded pace zones | Inaccurate pace distribution | MEDIUM |
| 5 | Hardcoded HR zones | Inaccurate HR analysis | MEDIUM |
| 6 | No station performance query | Can't show station analytics | MEDIUM |
| 7 | No PR detection on save | PRs not flagged | LOW |
| 8 | No activity feed implementation | Social features broken | MEDIUM |

### P2 - Medium (Missing Features)

| # | Issue | Impact | Effort |
|---|-------|--------|--------|
| 9 | Placeholder running stats | Incomplete running view | MEDIUM |
| 10 | No compromised running data | Missing key HYROX metric | MEDIUM |
| 11 | No recovery metrics | Simplified readiness | HIGH |
| 12 | Materialized view not refreshed | Stale stats | LOW |

---

## Database Schema Status

### Tables That Exist and Have Good Schema

| Table | Key Columns Available |
|-------|----------------------|
| `workouts` | avg_heart_rate, max_heart_rate, calories_burned, total_distance_meters, average_pace_per_km, performance_score, is_pr |
| `workout_segments` | station_type, actual_duration, actual_distance, completion_status |
| `running_sessions` | distance, duration, elevation, avg_pace, fastest_km_pace, heart_rate_zones (JSONB), splits (JSONB), route_data (JSONB) |
| `pr_records` | record_type, value, previous_value, improvement_percentage |
| `gym_activity_feed` | activity_type, visibility, likes_count, comments_count |
| `workout_feedback` | rpe_score, mood_score, tags, free_text, completion_percentage |
| `workout_stats_summary` | Materialized view with aggregated stats |

**The database is ready. The Swift code just isn't using it.**

---

## Data Flow Problem

### Current Flow (Broken)
```
Workout Completed
    ↓
Saved to Core Data (local SQLite)
    ↓
AnalyticsService queries Core Data
    ↓
Shows analytics with placeholder values
    ↓
(Maybe) Eventually syncs to Supabase
```

### Expected Flow (Correct)
```
Workout Completed
    ↓
Saved to Supabase workouts table
    ↓
DB triggers run (PR detection, activity feed)
    ↓
Analytics UI queries Supabase
    ↓
Shows real-time analytics
```

---

## Files Requiring Changes

### Critical Files

| File | Changes Needed |
|------|----------------|
| `AnalyticsService.swift` | Replace Core Data queries with Supabase, remove placeholders |
| `RunningAnalyticsView.swift` | Remove mock data, implement real queries |
| `WorkoutAnalyticsService.swift` | Add missing query methods |

### Files to Create

| File | Purpose |
|------|---------|
| `RunningService.swift` | Running session management + HealthKit import |
| `HealthKitRunningImport.swift` | Import runs from Apple Health |

---

## Implementation Phases

### Phase 1: Stop the Bleeding
**Goal:** Remove fake data, fix broken queries, verify basics work

| Task | File | Status |
|------|------|--------|
| 1.1 Fix UserStatsService column names | `UserStatsService.swift` | ✅ DONE |
| 1.2 Remove mock data flag from RunningAnalyticsView | `RunningAnalyticsView.swift` | ✅ DONE |
| 1.3 Verify dashboard stats display correctly | `DashboardView.swift` | ✅ DONE |
| 1.4 Test workout feedback saves to DB | `WorkoutCompletionView.swift` | ✅ DONE (previous session) |

---

### Phase 2: Connect Analytics to Real Data
**Goal:** Replace Core Data queries with Supabase queries

| Task | File | Status |
|------|------|--------|
| 2.1 Connect AnalyticsService to HealthKitService for real HRV/Sleep/RHR | `AnalyticsService.swift`, `AnalyticsDashboardView.swift` | ✅ DONE |
| 2.2 Add `getStationPerformance()` query | `WorkoutAnalyticsService.swift` | ✅ DONE |
| 2.3 Refactor AnalyticsService to use Supabase data | `AnalyticsService.swift` | ✅ DONE |
| 2.4 Remove hardcoded pace zones - calculate from real data | `AnalyticsService.swift` | ✅ DONE |
| 2.5 Remove hardcoded HR zones - calculate from real data | `AnalyticsService.swift` | ✅ DONE |
| 2.6 Remove placeholder running stats | `AnalyticsService.swift` | ⬜ TODO |

---

### Phase 3: Populate Empty Tables
**Goal:** Start saving data to tables that exist but are empty

| Task | File | Status |
|------|------|--------|
| 3.1 Save completed workouts to Supabase `workouts` table | `WorkoutExecutionViewModel.swift` | ⬜ TODO |
| 3.2 Call PR detection on workout completion | `WorkoutAnalyticsService.swift` | ⬜ TODO |
| 3.3 Populate activity feed on workout completion | `WorkoutAnalyticsService.swift` | ⬜ TODO |
| 3.4 Import running sessions from HealthKit | NEW: `HealthKitRunningImport.swift` | ⬜ TODO |

---

### Phase 4: Advanced Analytics
**Goal:** Implement sophisticated calculations

| Task | File | Status |
|------|------|--------|
| 4.1 Calculate real pace zones from splits data | `AnalyticsService.swift` | ⬜ TODO |
| 4.2 Calculate real HR zones from heart_rate_zones JSONB | `AnalyticsService.swift` | ⬜ TODO |
| 4.3 Implement compromised running analysis | `WorkoutAnalyticsService.swift` | ⬜ TODO |
| 4.4 Implement recovery metrics from HRV | NEW: `RecoveryService.swift` | ⬜ TODO |

---

### Phase 5: Accurate Race Prediction
**Goal:** Replace simplistic formula with data-driven prediction

**Current Formula (Simplistic):**
```
Predicted Time = (avgPacePerKm × 8) + 30 minutes (hardcoded station time)
```

**Target Formula (Data-Driven):**
```
Predicted Time =
    Σ(Run[i] × degradation_factor[i]) +     // 8 runs with fatigue curve
    Σ(Station[i]_actual_avg) +               // Real station times
    (transition_time × 16)                   // Transitions between segments
```

| Task | File | Status |
|------|------|--------|
| 5.1 Calculate user's pace degradation curve | `AnalyticsService.swift` | ⬜ TODO |
| 5.2 Use actual station averages from `workout_segments` | `AnalyticsService.swift` | ⬜ TODO |
| 5.3 Factor in compromised running data | `AnalyticsService.swift` | ⬜ TODO |
| 5.4 Calculate confidence interval based on data volume | `AnalyticsService.swift` | ⬜ TODO |
| 5.5 Add trend calculation (improving/stable/declining) | `AnalyticsService.swift` | ⬜ TODO |

---

### Phase 6: Polish & Edge Cases
**Goal:** Handle empty states, errors, loading states

| Task | File | Status |
|------|------|--------|
| 6.1 Add empty state UI for no workout data | Analytics views | ⬜ TODO |
| 6.2 Add loading skeletons | Analytics views | ⬜ TODO |
| 6.3 Add error handling for failed queries | All services | ⬜ TODO |
| 6.4 Cache frequently accessed analytics | Services | ⬜ TODO |

---

## Conclusion

The **database architecture is solid** - all the right tables exist with proper columns. The problem is the **Swift code isn't using them**:

1. AnalyticsService queries local Core Data instead of Supabase
2. Many values are hardcoded placeholders
3. Mock data masks bugs in development
4. Tables exist but aren't being populated

**Bottom line:** The "data-driven companion" promise isn't being fulfilled because we're showing fake/local data instead of real analytics from the cloud database.

---

*Report generated: December 6, 2024*
