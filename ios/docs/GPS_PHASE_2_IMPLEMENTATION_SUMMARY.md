# Phase 2 GPS Route Tracking Implementation Summary

**Implementation Date:** 2025-12-04
**Feature:** iPhone Fallback GPS When Watch Unavailable

## Overview
Implemented intelligent GPS fallback that uses iPhone GPS tracking when Apple Watch is not available during run segments. This ensures users always have GPS route tracking regardless of Watch connectivity.

## Files Modified

### 1. `/ios/FLEXR/Sources/Core/Models/Workout.swift`

**Changes:**
- Added `routeData: RouteData?` field to store GPS route data
- Added `gpsSource: GPSSource?` field to track which device captured the GPS
- Added `GPSSource` enum with cases:
  - `.watch` - GPS data from Apple Watch
  - `.iphone` - GPS data from iPhone (fallback)
- Updated initializer to include new fields with nil defaults

**Purpose:** Allows workouts to store route data and know which device captured it.

---

### 2. `/ios/FLEXR/Sources/Features/Workout/WorkoutExecutionViewModel.swift`

**Changes:**

#### Added Properties:
```swift
// GPS tracking
private var locationService: LocationTrackingService?
private var isTrackingGPS = false
```

#### Added Computed Property:
```swift
var isWatchAvailable: Bool {
    WatchConnectivityService.shared.isReachable &&
    WatchConnectivityService.shared.isWatchAppInstalled
}
```

#### Added GPS Management Methods:
```swift
private func startGPSIfNeeded() {
    // Only tracks GPS for run segments
    // Only uses iPhone GPS if Watch is NOT available
    // Sets workout.gpsSource appropriately
}

private func stopGPSIfNeeded() {
    // Stops tracking and captures route data
    // Saves routeData to workout
}
```

#### Integrated GPS Lifecycle:
- `start()` - Calls `startGPSIfNeeded()` when workout starts
- `pause()` - Pauses GPS tracking if active
- `resume()` - Resumes GPS tracking if active
- `completeCurrentSegment()` - Stops GPS and saves route data
- `continueToNextSegment()` - Starts GPS for new run segments
- `endWorkout()` - Ensures GPS is stopped
- `completeWorkout()` - Ensures GPS is stopped

**Purpose:** Manages GPS lifecycle automatically based on segment type and Watch availability.

---

## Implementation Logic

### GPS Activation Decision Tree:
```
Is current segment a run segment?
├─ No → Don't track GPS
└─ Yes → Check Watch availability
    ├─ Watch Available → Set gpsSource = .watch (Watch handles GPS)
    └─ Watch Unavailable → Start iPhone GPS, set gpsSource = .iphone
```

### GPS Lifecycle:
```
Segment Start (Run) → startGPSIfNeeded()
                      └─ If Watch unavailable → Start iPhone GPS

Workout Pause → Pause GPS tracking (if active)

Workout Resume → Resume GPS tracking (if active)

Segment Complete → stopGPSIfNeeded()
                   └─ Stop GPS, capture routeData, save to workout

Segment Transition → Stop GPS → Start GPS for next segment (if run)

Workout End → Ensure GPS stopped
```

---

## Key Features

### 1. Automatic Fallback
- iPhone GPS only activates when Watch is unavailable
- No manual intervention required
- Seamless user experience

### 2. Segment-Aware
- Only tracks GPS during run segments
- Automatically stops between segments
- Restarts for next run segment

### 3. State Management
- Properly handles pause/resume
- Captures route data on segment completion
- Sets `gpsSource` to indicate tracking device

### 4. Resource Management
- LocationTrackingService initialized only when needed
- GPS tracking stopped when not in use
- Clean lifecycle management

---

## Testing Recommendations

### Scenario 1: Watch Available
1. Start workout with Watch connected and reachable
2. Begin run segment
3. Verify `workout.gpsSource == .watch`
4. Verify iPhone GPS does NOT activate
5. Verify Watch sends GPS data via WatchConnectivity

### Scenario 2: Watch Unavailable
1. Start workout without Watch (or Watch unreachable)
2. Begin run segment
3. Verify `workout.gpsSource == .iphone`
4. Verify iPhone GPS activates (`isTrackingGPS == true`)
5. Complete segment
6. Verify `workout.routeData` contains GPS coordinates

### Scenario 3: Mid-Workout Watch Disconnect
1. Start workout with Watch connected
2. Begin run segment (Watch handles GPS)
3. Disconnect Watch mid-segment
4. Move to next run segment
5. Verify iPhone GPS takes over (`gpsSource == .iphone`)

### Scenario 4: Pause/Resume
1. Start run segment with iPhone GPS
2. Pause workout
3. Verify GPS tracking paused
4. Resume workout
5. Verify GPS tracking resumed
6. Complete segment
7. Verify route data includes all coordinates (before and after pause)

### Scenario 5: Multiple Run Segments
1. Start workout with mixed segments (run, station, run)
2. Complete first run → verify GPS stopped and data saved
3. Complete station → verify no GPS tracking
4. Start second run → verify GPS restarted
5. Complete workout → verify each run has route data

---

## Dependencies

### Existing Services Used:
- **LocationTrackingService** (`/ios/FLEXR/Sources/Core/Services/LocationTrackingService.swift`)
  - `startTracking()` - Starts GPS tracking
  - `stopTracking()` - Stops GPS tracking
  - `pauseTracking()` - Pauses GPS tracking
  - `resumeTracking()` - Resumes GPS tracking
  - `getRouteData()` - Returns RouteData with coordinates

- **WatchConnectivityService** (`/ios/FLEXR/Sources/Core/Services/WatchConnectivityService.swift`)
  - `isReachable` - Watch connection status
  - `isWatchAppInstalled` - Watch app installation status

- **RouteData Model** (`/ios/FLEXR/Sources/Core/Models/RouteData.swift`)
  - Stores GPS coordinates with metadata
  - Includes elevation gain/loss calculations

---

## Known Limitations

1. **Watch GPS Integration Pending**: Phase 3 will implement Watch-side GPS tracking and data transmission
2. **Permission Handling**: LocationTrackingService handles permissions, but UI feedback could be improved
3. **Battery Impact**: GPS tracking impacts battery, especially on iPhone
4. **Accuracy**: iPhone GPS may be less accurate than Watch GPS during high-intensity workouts

---

## Next Steps (Phase 3)

1. Implement Watch GPS tracking in `WatchWorkoutSessionManager`
2. Transmit GPS data from Watch to iPhone via WatchConnectivity
3. Handle GPS data format conversion
4. Test dual-device scenarios
5. Implement GPS data visualization in workout summary

---

## Code Quality Notes

### Strengths:
- Clean separation of concerns
- Automatic lifecycle management
- Minimal coupling between components
- Clear intent with descriptive method names

### Potential Improvements:
- Add unit tests for GPS lifecycle logic
- Add error handling for GPS permission denied
- Consider battery optimization strategies
- Add UI indicators for GPS source (Watch vs iPhone)

---

## Performance Considerations

- LocationTrackingService uses 5-meter distance filter (efficient)
- GPS only active during run segments (not entire workout)
- Pause/resume properly manages battery usage
- RouteData stored in memory until workout completes

---

## Conclusion

Phase 2 successfully implements iPhone GPS fallback with:
- Automatic Watch availability detection
- Intelligent fallback to iPhone GPS
- Proper lifecycle management (start, pause, resume, stop)
- Clean integration with existing services
- Minimal code changes to existing architecture

The implementation is ready for testing and integration with Phase 3 (Watch GPS tracking).
