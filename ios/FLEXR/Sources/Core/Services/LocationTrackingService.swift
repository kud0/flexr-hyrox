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
