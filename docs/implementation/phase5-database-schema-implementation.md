# Phase 5 - Database Schema Updates Implementation

**Status:** ✅ Complete
**Date:** 2025-12-04

## Overview
Implemented database schema updates to support GPS route tracking data storage in the workouts table, including route coordinates, elevation metrics, and GPS source tracking.

## Files Created

### 1. Migration File
**File:** `/Users/alexsolecarretero/Public/projects/FLEXR/backend/src/migrations/supabase/016_add_route_data.sql`

Added four new columns to the workouts table:
- `route_data` (JSONB) - GPS coordinates and metadata
- `gps_source` (TEXT) - Device that tracked GPS (watch/iphone)
- `elevation_gain` (DOUBLE PRECISION) - Total elevation gain in meters
- `elevation_loss` (DOUBLE PRECISION) - Total elevation loss in meters

Created two indexes for efficient querying:
- `idx_workouts_route_data` - For workouts with routes
- `idx_workouts_gps_source` - For GPS source filtering

## Files Modified

### 2. SupabaseService.swift
**File:** `/Users/alexsolecarretero/Public/projects/FLEXR/ios/FLEXR/Sources/Core/Services/SupabaseService.swift`

#### Changes to `saveWorkoutSummary()`:
- Added route data JSON serialization using JSONEncoder with ISO8601 date encoding
- Extract elevation metrics from RouteData
- Updated CompletedWorkoutInsert struct to include:
  - `route_data: String?` (JSON serialized)
  - `gps_source: String?` (watch/iphone)
  - `elevation_gain: Double?`
  - `elevation_loss: Double?`
- Enhanced logging to indicate when route data is saved

#### Changes to `fetchRecentWorkouts()`:
- Added placeholder for route data deserialization
- TODO comment for future implementation when Workout model supports route data

## Technical Implementation Details

### JSON Serialization
```swift
var routeDataJson: String? = nil
if let routeData = summary.routeData {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    if let jsonData = try? encoder.encode(routeData),
       let jsonString = String(data: jsonData, encoding: .utf8) {
        routeDataJson = jsonString
    }
}
```

### Database Schema
```sql
-- JSONB for efficient storage and querying
route_data JSONB

-- Enum-like constraint for GPS source
gps_source TEXT CHECK (gps_source IN ('watch', 'iphone'))

-- Separate fields for quick queries without JSON parsing
elevation_gain DOUBLE PRECISION
elevation_loss DOUBLE PRECISION
```

### Indexes
```sql
-- Partial index for workouts with routes
CREATE INDEX idx_workouts_route_data
  ON workouts ((route_data IS NOT NULL))
  WHERE route_data IS NOT NULL;

-- Index for GPS source filtering
CREATE INDEX idx_workouts_gps_source
  ON workouts (gps_source)
  WHERE gps_source IS NOT NULL;
```

## Data Storage Strategy

### Why JSONB?
1. **Flexible Schema** - Route data structure can evolve without schema changes
2. **Efficient Storage** - Binary JSON format, compact storage
3. **Query Support** - PostgreSQL JSONB supports indexing and querying
4. **Complex Data** - Perfect for nested structures (coordinates, timestamps, metadata)

### Why Separate Elevation Fields?
1. **Performance** - Direct queries without JSON parsing
2. **Aggregation** - Easy to calculate total elevation across workouts
3. **Filtering** - Quick filtering by elevation metrics

### GPS Source Tracking
- Track which device collected GPS data
- Useful for debugging GPS accuracy issues
- Future analytics (watch vs phone GPS quality)

## Database Migration Notes

### Running the Migration
```bash
# Using Supabase CLI
supabase migration up 016_add_route_data.sql

# Or through Supabase Dashboard
# 1. Go to Database > Migrations
# 2. Upload 016_add_route_data.sql
# 3. Run migration
```

### Rollback (if needed)
```sql
-- Remove indexes
DROP INDEX IF EXISTS idx_workouts_route_data;
DROP INDEX IF EXISTS idx_workouts_gps_source;

-- Remove columns
ALTER TABLE workouts
  DROP COLUMN IF EXISTS route_data,
  DROP COLUMN IF EXISTS gps_source,
  DROP COLUMN IF EXISTS elevation_gain,
  DROP COLUMN IF EXISTS elevation_loss;
```

## Testing Checklist

- [ ] Migration runs successfully on Supabase
- [ ] Workouts save with route data
- [ ] Workouts save without route data (null handling)
- [ ] Route data JSON serialization works correctly
- [ ] Elevation metrics are stored properly
- [ ] GPS source is tracked correctly
- [ ] Indexes are created and functional
- [ ] Fetching workouts doesn't break

## Future Enhancements

1. **Route Data Deserialization**
   - Update Workout model to include route data fields
   - Implement JSON deserialization in `fetchRecentWorkouts()`
   - Support route visualization in iOS app

2. **Route Analytics**
   - Calculate route efficiency metrics
   - Compare routes for similar workouts
   - Identify optimal training routes

3. **Route Sharing**
   - Enable sharing routes with race partners
   - Community route discovery
   - Popular training route recommendations

4. **Advanced Querying**
   - Find workouts by location (geospatial queries)
   - Filter by elevation profile
   - Search workouts within distance of point

## Notes

- Route data is optional (nullable fields)
- Old workouts without GPS data remain compatible
- JSON encoding uses ISO8601 for timestamp consistency
- Supabase client handles JSONB conversion automatically
- No breaking changes to existing workout functionality

## References

- Phase 3: RouteData Model Implementation
- Phase 4: GPS Tracking Service Implementation
- WorkoutSummary Model (includes routeData and gpsSource)
- PostgreSQL JSONB Documentation
- Supabase Database Functions
