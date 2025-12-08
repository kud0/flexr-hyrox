# Phase 2 GPS Flow Diagram

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    WorkoutExecutionViewModel                 │
│                                                              │
│  Properties:                                                 │
│  - locationService: LocationTrackingService?                 │
│  - isTrackingGPS: Bool                                       │
│  - workout: Workout (includes routeData, gpsSource)         │
│                                                              │
│  Computed:                                                   │
│  - isWatchAvailable: Bool                                    │
│    └─> WatchConnectivityService.shared.isReachable &&       │
│        WatchConnectivityService.shared.isWatchAppInstalled   │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ uses
                            ▼
        ┌──────────────────────────────────────┐
        │                                      │
        ▼                                      ▼
┌─────────────────────┐           ┌─────────────────────┐
│ LocationTracking    │           │ WatchConnectivity   │
│ Service             │           │ Service             │
│                     │           │                     │
│ - startTracking()   │           │ - isReachable       │
│ - stopTracking()    │           │ - isWatchApp        │
│ - pauseTracking()   │           │   Installed         │
│ - resumeTracking()  │           │                     │
│ - getRouteData()    │           │                     │
└─────────────────────┘           └─────────────────────┘
        │
        │ returns
        ▼
┌─────────────────────┐
│ RouteData           │
│                     │
│ - coordinates[]     │
│ - totalDistance     │
│ - elevationGain     │
│ - elevationLoss     │
└─────────────────────┘
```

---

## Workflow: Starting a Run Segment

```
User starts run segment
        │
        ▼
WorkoutExecutionViewModel.continueToNextSegment()
        │
        ▼
startGPSIfNeeded()
        │
        ├─> Check: Is segment type == .run?
        │   ├─ No  → Return (no GPS needed)
        │   └─ Yes → Continue
        │
        ├─> Check: isWatchAvailable?
        │   ├─ Yes → Set gpsSource = .watch
        │   │         Watch handles GPS
        │   │         Return
        │   │
        │   └─ No  → Continue to iPhone GPS
        │
        ├─> Initialize LocationTrackingService
        │
        ├─> locationService.startTracking()
        │
        ├─> Set isTrackingGPS = true
        │
        └─> Set workout.gpsSource = .iphone
```

---

## Workflow: Completing a Run Segment

```
User completes segment
        │
        ▼
WorkoutExecutionViewModel.completeCurrentSegment()
        │
        ▼
stopGPSIfNeeded()
        │
        ├─> Check: isTrackingGPS == true?
        │   ├─ No  → Return (no GPS to stop)
        │   └─ Yes → Continue
        │
        ├─> locationService.stopTracking()
        │
        ├─> routeData = locationService.getRouteData()
        │
        ├─> workout.routeData = routeData
        │
        ├─> Set isTrackingGPS = false
        │
        └─> Log: "Captured route data: Xm, Y points"
```

---

## Workflow: Pause/Resume

```
┌─────────────┐                  ┌─────────────┐
│   PAUSE     │                  │   RESUME    │
└─────────────┘                  └─────────────┘
      │                                │
      ▼                                ▼
WorkoutExecutionViewModel          WorkoutExecutionViewModel
.pause()                           .resume()
      │                                │
      ├─> isPaused = true              ├─> isPaused = false
      │                                │
      ├─> stopTimers()                 ├─> startTimers()
      │                                │
      ├─> Check: isTrackingGPS?        ├─> Check: isTrackingGPS?
      │   └─> Yes: locationService     │   └─> Yes: locationService
      │            .pauseTracking()     │            .resumeTracking()
      │                                │
      └─> Haptic feedback              └─> Haptic feedback
```

---

## State Transitions

```
                    ┌─────────────────┐
                    │  Workout Start  │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │  Run Segment    │
                    │  Detected       │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ Check Watch     │
                    │ Availability    │
                    └────┬───────┬────┘
                         │       │
              Watch      │       │     Watch
           Available     │       │  Unavailable
                 │       │       │      │
                 ▼       │       │      ▼
         ┌───────────┐   │       │  ┌────────────┐
         │ Watch GPS │   │       │  │ iPhone GPS │
         │ (Phase 3) │   │       │  │ (Phase 2)  │
         └───────────┘   │       │  └─────┬──────┘
                         │       │        │
                         │       │        │ Start Tracking
                         │       │        │
                         │       │        ▼
                         │       │  ┌────────────┐
                         │       │  │  Tracking  │
                         │       │  │  Active    │
                         │       │  └─────┬──────┘
                         │       │        │
                 ┌───────┴───────┴────────┴───────┐
                 │                                 │
                 ▼                                 ▼
         ┌───────────────┐              ┌──────────────────┐
         │ Segment       │              │ Workout Paused   │
         │ Complete      │              └────────┬─────────┘
         └───────┬───────┘                       │
                 │                               │ Resume
                 │ Stop GPS                      │
                 │                               ▼
                 │                      ┌──────────────────┐
                 │                      │ Resume Tracking  │
                 │                      └────────┬─────────┘
                 │                               │
                 ▼                               │
         ┌───────────────┐                       │
         │ Save Route    │◄──────────────────────┘
         │ Data          │
         └───────┬───────┘
                 │
                 ▼
         ┌───────────────┐
         │ Next Segment  │
         │ or Complete   │
         └───────────────┘
```

---

## Data Flow

```
┌──────────────────────────────────────────────────────────┐
│                     iPhone GPS Tracking                   │
└──────────────────────────────────────────────────────────┘
                            │
                            │ Location updates
                            ▼
                ┌──────────────────────────┐
                │  LocationTracking        │
                │  Service                 │
                │                          │
                │  Collects:               │
                │  - Latitude/Longitude    │
                │  - Altitude              │
                │  - Speed                 │
                │  - Timestamp             │
                │  - Horizontal Accuracy   │
                └──────────┬───────────────┘
                           │
                           │ getRouteData()
                           ▼
                ┌──────────────────────────┐
                │  RouteData               │
                │                          │
                │  coordinates: [          │
                │    RouteCoordinate {     │
                │      lat, lon, alt,      │
                │      timestamp, speed    │
                │    }                     │
                │  ]                       │
                │  totalDistance: Double   │
                │  elevationGain: Double   │
                │  elevationLoss: Double   │
                └──────────┬───────────────┘
                           │
                           │ Saved to
                           ▼
                ┌──────────────────────────┐
                │  Workout                 │
                │                          │
                │  routeData: RouteData?   │
                │  gpsSource: .iphone      │
                └──────────────────────────┘
```

---

## Decision Matrix

| Condition | Watch Available | Watch Unavailable |
|-----------|----------------|-------------------|
| **Run Segment** | gpsSource = .watch<br/>Watch handles GPS<br/>iPhone GPS OFF | gpsSource = .iphone<br/>iPhone GPS ON<br/>LocationTrackingService active |
| **Station Segment** | No GPS tracking<br/>gpsSource = nil | No GPS tracking<br/>gpsSource = nil |
| **Warmup/Cooldown** | No GPS tracking<br/>gpsSource = nil | No GPS tracking<br/>gpsSource = nil |

---

## Integration Points

### WorkoutExecutionViewModel → LocationTrackingService
```swift
// Start tracking
locationService?.startTracking()
isTrackingGPS = true
workout.gpsSource = .iphone

// Stop tracking
locationService?.stopTracking()
if let routeData = locationService?.getRouteData() {
    workout.routeData = routeData
}
isTrackingGPS = false
```

### WorkoutExecutionViewModel → WatchConnectivityService
```swift
// Check availability
var isWatchAvailable: Bool {
    WatchConnectivityService.shared.isReachable &&
    WatchConnectivityService.shared.isWatchAppInstalled
}
```

### Workout Model → RouteData
```swift
struct Workout {
    var routeData: RouteData?  // GPS coordinates
    var gpsSource: GPSSource?  // .watch or .iphone
}
```

---

## Error Handling

```
GPS Permission Denied
        │
        ├─> LocationTrackingService.requestPermission()
        │
        └─> Continue without GPS (graceful degradation)


GPS Tracking Failed
        │
        ├─> Log error
        │
        └─> routeData = nil (no GPS data available)


Watch Disconnects Mid-Workout
        │
        ├─> Next run segment detects !isWatchAvailable
        │
        └─> Falls back to iPhone GPS automatically
```

---

## Testing Checklist

- [ ] Run segment with Watch connected → gpsSource = .watch
- [ ] Run segment without Watch → gpsSource = .iphone, GPS starts
- [ ] Station segment → No GPS tracking
- [ ] Pause during GPS tracking → GPS paused
- [ ] Resume after pause → GPS resumed
- [ ] Complete segment → GPS stopped, routeData saved
- [ ] Multiple run segments → GPS starts/stops correctly
- [ ] Complete workout → GPS fully stopped
- [ ] GPS permission denied → Graceful handling
- [ ] Watch disconnect mid-workout → Falls back to iPhone GPS

---

## Performance Metrics

| Metric | Value | Notes |
|--------|-------|-------|
| GPS Update Frequency | 5 meters | Distance filter in LocationTrackingService |
| Battery Impact | Moderate | GPS only active during run segments |
| Memory Usage | Low | RouteData stored in memory until save |
| CPU Usage | Low | Native CoreLocation APIs |
| Accuracy | ±5-10m | Standard iPhone GPS accuracy |

---

## Future Enhancements (Post-Phase 3)

1. **Offline Map Caching**: Pre-cache map tiles for workout routes
2. **Real-time Route Visualization**: Show route on map during workout
3. **Pace Zones**: Color-code route by pace zones
4. **Elevation Profile**: Show elevation chart with route
5. **GPS Smoothing**: Apply Kalman filter to reduce GPS jitter
6. **Battery Optimization**: Reduce GPS accuracy when low battery
7. **Route Sharing**: Export GPX files for external apps
