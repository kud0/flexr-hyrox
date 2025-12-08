import Foundation
import CoreLocation

/// Route data captured during workout runs
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

    /// Create RouteData from an array of CLLocation objects
    static func from(locations: [CLLocation]) -> RouteData? {
        guard !locations.isEmpty else { return nil }

        let coordinates = locations.map { location in
            RouteCoordinate(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                altitude: location.altitude,
                timestamp: location.timestamp,
                speed: location.speed,
                horizontalAccuracy: location.horizontalAccuracy
            )
        }

        // Calculate total distance
        var totalDistance: Double = 0
        for i in 1..<locations.count {
            totalDistance += locations[i].distance(from: locations[i - 1])
        }

        // Calculate elevation gain and loss
        var elevationGain: Double = 0
        var elevationLoss: Double = 0
        for i in 1..<locations.count {
            let elevationDelta = locations[i].altitude - locations[i - 1].altitude
            if elevationDelta > 0 {
                elevationGain += elevationDelta
            } else {
                elevationLoss += abs(elevationDelta)
            }
        }

        return RouteData(
            coordinates: coordinates,
            totalDistance: totalDistance,
            elevationGain: elevationGain,
            elevationLoss: elevationLoss
        )
    }
}

/// Individual coordinate point along the route
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

/// Map region for displaying the route
struct MapRegion: Codable {
    let centerLatitude: Double
    let centerLongitude: Double
    let latitudeDelta: Double
    let longitudeDelta: Double
}
