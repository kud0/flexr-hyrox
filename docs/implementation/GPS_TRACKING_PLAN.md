# GPS Tracking Implementation Plan - Personal Analytics Only

## Overview
Implement solid GPS tracking for all user runs with personal analytics. No social features.

## Phase 1: Location Service Foundation (Week 1-2)

### 1.1 Create LocationTrackingService
**File:** `ios/FLEXR/Sources/Core/Services/LocationTrackingService.swift`

```swift
import CoreLocation
import Combine

class LocationTrackingService: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isTracking = false
    @Published var currentLocation: CLLocation?
    @Published var routeCoordinates: [CLLocation] = []
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private var workoutStartTime: Date?

    // MARK: - Computed Properties
    var totalDistance: Double {
        guard routeCoordinates.count > 1 else { return 0 }
        var distance: Double = 0
        for i in 1..<routeCoordinates.count {
            distance += routeCoordinates[i].distance(from: routeCoordinates[i-1])
        }
        return distance
    }

    var averagePace: Double {
        guard let start = workoutStartTime,
              totalDistance > 0 else { return 0 }
        let duration = Date().timeIntervalSince(start)
        return duration / (totalDistance / 1000) // min/km
    }

    // MARK: - Initialization
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5 // Update every 5 meters
        locationManager.activityType = .fitness
        locationManager.allowsBackgroundLocationUpdates = true
    }

    // MARK: - Public Methods
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startTracking() {
        guard authorizationStatus == .authorizedWhenInUse ||
              authorizationStatus == .authorizedAlways else {
            requestPermission()
            return
        }

        routeCoordinates.removeAll()
        workoutStartTime = Date()
        isTracking = true
        locationManager.startUpdatingLocation()
    }

    func stopTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
        workoutStartTime = nil
    }

    func pauseTracking() {
        locationManager.stopUpdatingLocation()
    }

    func resumeTracking() {
        locationManager.startUpdatingLocation()
    }

    func getRouteData() -> RouteData? {
        guard !routeCoordinates.isEmpty else { return nil }

        return RouteData(
            coordinates: routeCoordinates.map { location in
                RouteCoordinate(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    altitude: location.altitude,
                    timestamp: location.timestamp,
                    speed: location.speed,
                    horizontalAccuracy: location.horizontalAccuracy
                )
            },
            totalDistance: totalDistance,
            elevationGain: calculateElevationGain(),
            elevationLoss: calculateElevationLoss()
        )
    }

    // MARK: - Private Methods
    private func calculateElevationGain() -> Double {
        guard routeCoordinates.count > 1 else { return 0 }
        var gain: Double = 0
        for i in 1..<routeCoordinates.count {
            let diff = routeCoordinates[i].altitude - routeCoordinates[i-1].altitude
            if diff > 0 { gain += diff }
        }
        return gain
    }

    private func calculateElevationLoss() -> Double {
        guard routeCoordinates.count > 1 else { return 0 }
        var loss: Double = 0
        for i in 1..<routeCoordinates.count {
            let diff = routeCoordinates[i].altitude - routeCoordinates[i-1].altitude
            if diff < 0 { loss += abs(diff) }
        }
        return loss
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationTrackingService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isTracking else { return }

        for location in locations {
            // Filter out inaccurate readings
            guard location.horizontalAccuracy < 50 else { continue }

            routeCoordinates.append(location)
            currentLocation = location
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
```

### 1.2 Data Models
**File:** `ios/FLEXR/Sources/Core/Models/RouteData.swift`

```swift
import Foundation
import CoreLocation

struct RouteData: Codable {
    let coordinates: [RouteCoordinate]
    let totalDistance: Double
    let elevationGain: Double
    let elevationLoss: Double

    var mapRegion: MapRegion {
        guard !coordinates.isEmpty else {
            return MapRegion(
                centerLatitude: 0,
                centerLongitude: 0,
                latitudeDelta: 0.01,
                longitudeDelta: 0.01
            )
        }

        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }

        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0

        return MapRegion(
            centerLatitude: (minLat + maxLat) / 2,
            centerLongitude: (minLon + maxLon) / 2,
            latitudeDelta: (maxLat - minLat) * 1.3,
            longitudeDelta: (maxLon - minLon) * 1.3
        )
    }
}

struct RouteCoordinate: Codable, Identifiable {
    let id = UUID()
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let timestamp: Date
    let speed: Double
    let horizontalAccuracy: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    enum CodingKeys: String, CodingKey {
        case latitude, longitude, altitude, timestamp, speed, horizontalAccuracy
    }
}

struct MapRegion: Codable {
    let centerLatitude: Double
    let centerLongitude: Double
    let latitudeDelta: Double
    let longitudeDelta: Double
}
```

### 1.3 Update Info.plist
Add location permissions:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>FLEXR tracks your running route to provide accurate distance, pace, and elevation data for your personal training analytics.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>FLEXR needs location access to track your outdoor runs and provide detailed route analytics.</string>

<key>UIBackgroundModes</key>
<array>
    <string>location</string>
</array>
```

---

## Phase 2: Workout Integration (Week 2-3)

### 2.1 Update Workout Model
**File:** `ios/FLEXR/Sources/Core/Models/Workout.swift`

Add route data fields:
```swift
struct Workout {
    // ... existing fields

    var routeData: RouteData?
    var mapSnapshotUrl: String?
}
```

### 2.2 Update Database Schema
**File:** `backend/src/migrations/supabase/016_add_route_data.sql`

```sql
-- Add route tracking columns
ALTER TABLE workouts ADD COLUMN route_data JSONB;
ALTER TABLE workouts ADD COLUMN map_snapshot_url TEXT;
ALTER TABLE workouts ADD COLUMN elevation_gain DOUBLE PRECISION;
ALTER TABLE workouts ADD COLUMN elevation_loss DOUBLE PRECISION;

-- Index for querying workouts with routes
CREATE INDEX idx_workouts_has_route ON workouts ((route_data IS NOT NULL));
```

### 2.3 Integrate with WorkoutExecutionView
Update to track location for running segments:

```swift
// Add to WorkoutExecutionView
@StateObject private var locationService = LocationTrackingService()

// Start tracking when run segment begins
private func startSegment() {
    if currentSegment.segmentType == .run {
        locationService.startTracking()
    }
    // ... rest of code
}

// Stop tracking when run segment ends
private func completeSegment() {
    if currentSegment.segmentType == .run {
        locationService.stopTracking()
        // Save route data
        workout.routeData = locationService.getRouteData()
    }
    // ... rest of code
}
```

---

## Phase 3: Map Display (Week 3-4)

### 3.1 Live Tracking Map During Workout
**File:** `ios/FLEXR/Sources/Features/Workout/LiveTrackingMapView.swift`

```swift
import SwiftUI
import MapKit

struct LiveTrackingMapView: View {
    @ObservedObject var locationService: LocationTrackingService
    @State private var region: MKCoordinateRegion

    init(locationService: LocationTrackingService) {
        self.locationService = locationService

        // Initialize with user's location or default
        let center = locationService.currentLocation?.coordinate ??
                     CLLocationCoordinate2D(latitude: 0, longitude: 0)
        _region = State(initialValue: MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    var body: some View {
        Map(coordinateRegion: $region,
            showsUserLocation: true,
            userTrackingMode: .constant(.follow),
            annotationItems: []) { _ in }
        .overlay(
            RoutePolylineView(coordinates: locationService.routeCoordinates)
        )
        .onChange(of: locationService.currentLocation) { newLocation in
            if let location = newLocation {
                region.center = location.coordinate
            }
        }
    }
}

struct RoutePolylineView: UIViewRepresentable {
    let coordinates: [CLLocation]

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)

        guard coordinates.count > 1 else { return }

        let polylineCoordinates = coordinates.map { $0.coordinate }
        let polyline = MKPolyline(coordinates: polylineCoordinates, count: polylineCoordinates.count)
        mapView.addOverlay(polyline)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(DesignSystem.Colors.primary)
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
```

### 3.2 Completed Route Map in Detail View
**File:** `ios/FLEXR/Sources/Features/Workout/CompletedRouteMapView.swift`

```swift
import SwiftUI
import MapKit

struct CompletedRouteMapView: View {
    let routeData: RouteData
    @State private var region: MKCoordinateRegion

    init(routeData: RouteData) {
        self.routeData = routeData

        let mapRegion = routeData.mapRegion
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: mapRegion.centerLatitude,
                longitude: mapRegion.centerLongitude
            ),
            span: MKCoordinateSpan(
                latitudeDelta: mapRegion.latitudeDelta,
                longitudeDelta: mapRegion.longitudeDelta
            )
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Map
            Map(coordinateRegion: .constant(region),
                annotationItems: routeAnnotations) { annotation in
                    MapMarker(
                        coordinate: annotation.coordinate,
                        tint: annotation.type == .start ? .green : .red
                    )
                }
            .overlay(
                StaticRoutePolylineView(coordinates: routeData.coordinates)
            )
            .frame(height: 250)
            .cornerRadius(16)

            // Route stats
            HStack(spacing: 20) {
                RouteStatItem(
                    icon: "arrow.up.right",
                    label: "Elevation Gain",
                    value: "\(Int(routeData.elevationGain))m"
                )

                RouteStatItem(
                    icon: "arrow.down.right",
                    label: "Elevation Loss",
                    value: "\(Int(routeData.elevationLoss))m"
                )

                RouteStatItem(
                    icon: "map",
                    label: "Distance",
                    value: String(format: "%.2f km", routeData.totalDistance / 1000)
                )
            }
        }
    }

    private var routeAnnotations: [RouteAnnotation] {
        guard let first = routeData.coordinates.first,
              let last = routeData.coordinates.last else { return [] }

        return [
            RouteAnnotation(coordinate: first.coordinate, type: .start),
            RouteAnnotation(coordinate: last.coordinate, type: .end)
        ]
    }
}

struct RouteAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let type: AnnotationType

    enum AnnotationType {
        case start, end
    }
}

struct RouteStatItem: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(DesignSystem.Colors.primary)

            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(DesignSystem.Colors.text.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct StaticRoutePolylineView: UIViewRepresentable {
    let coordinates: [RouteCoordinate]

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.isUserInteractionEnabled = false
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)

        guard coordinates.count > 1 else { return }

        let coords = coordinates.map { $0.coordinate }
        let polyline = MKPolyline(coordinates: coords, count: coords.count)
        mapView.addOverlay(polyline)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(DesignSystem.Colors.primary)
                renderer.lineWidth = 3
                renderer.lineCap = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
```

---

## Phase 4: Personal Analytics (Week 4-5)

### 4.1 Route Analytics View
Show detailed analytics for completed runs:
- Split times per kilometer
- Pace variation chart
- Elevation profile
- Heart rate zones overlaid on map (if available)

### 4.2 Historical Route Comparison
- View all past runs on the same route
- Compare times and paces
- Personal records on specific routes

### 4.3 Heat Map
- Show where user runs most frequently
- Identify favorite routes

---

## Implementation Priority

**Must Have (MVP):**
✅ Phase 1: LocationTrackingService
✅ Phase 2: Workout Integration
✅ Phase 3.1: Live map during workout
✅ Phase 3.2: Completed route in detail view

**Nice to Have (Later):**
- Phase 4: Advanced analytics
- Map thumbnails in workout cards
- Offline map caching
- Route export (GPX format)

---

## Technical Notes

### Battery Optimization
- Use `distanceFilter = 5` (update every 5m)
- Switch to `kCLLocationAccuracyNearestTenMeters` if battery low
- Stop GPS during indoor segments

### Data Storage
- Store coordinates as JSONB in Supabase
- Compress route data (Douglas-Peucker algorithm)
- Generate map snapshots for quick preview

### Privacy
- All data stays personal (no sharing yet)
- Option to delete route data but keep workout stats
- Start/end location privacy (blur home address)

---

## Next Steps

1. Create `LocationTrackingService.swift`
2. Add location permissions to Info.plist
3. Create route data models
4. Update database schema
5. Integrate with WorkoutExecutionView
6. Build map display components
7. Test with outdoor runs
