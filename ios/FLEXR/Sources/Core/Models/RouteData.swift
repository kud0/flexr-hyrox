import Foundation
import CoreLocation

struct RouteData: Codable, Equatable {
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

struct RouteCoordinate: Codable, Identifiable, Equatable {
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

    static func == (lhs: RouteCoordinate, rhs: RouteCoordinate) -> Bool {
        lhs.latitude == rhs.latitude &&
        lhs.longitude == rhs.longitude &&
        lhs.altitude == rhs.altitude &&
        lhs.timestamp == rhs.timestamp &&
        lhs.speed == rhs.speed &&
        lhs.horizontalAccuracy == rhs.horizontalAccuracy
    }
}

struct MapRegion: Codable, Equatable {
    let centerLatitude: Double
    let centerLongitude: Double
    let latitudeDelta: Double
    let longitudeDelta: Double
}
