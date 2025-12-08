import SwiftUI
import MapKit

// MARK: - Completed Route Map View
/// Displays a completed workout route with map, polyline, start/end markers, and elevation/distance stats
/// Follows Apple Watch/Strava design patterns with FLEXR design system
struct CompletedRouteMapView: View {
    let routeData: RouteData
    @State private var region: MKCoordinateRegion

    init(routeData: RouteData) {
        self.routeData = routeData

        // Initialize region from routeData.mapRegion
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
        VStack(spacing: DesignSystem.Spacing.medium) {
            // Map with route polyline and markers
            ZStack {
                RouteMapViewRepresentable(
                    routeData: routeData,
                    region: $region
                )
                .frame(height: 250)
                .cornerRadius(DesignSystem.Radius.large)
                .disabled(true) // Disable interaction for completed routes
            }

            // Stats row
            HStack(spacing: DesignSystem.Spacing.large) {
                RouteStatItem(
                    icon: "arrow.up.right",
                    label: "Elevation Gain",
                    value: formatElevation(routeData.elevationGain),
                    color: DesignSystem.Colors.success
                )

                RouteStatItem(
                    icon: "arrow.down.right",
                    label: "Elevation Loss",
                    value: formatElevation(routeData.elevationLoss),
                    color: DesignSystem.Colors.error
                )

                RouteStatItem(
                    icon: "map",
                    label: "Distance",
                    value: formatDistance(routeData.totalDistance),
                    color: DesignSystem.Colors.primary
                )
            }
            .padding(.horizontal, DesignSystem.Spacing.xSmall)
        }
    }

    // MARK: - Formatters

    private func formatElevation(_ meters: Double) -> String {
        return "\(Int(meters.rounded()))m"
    }

    private func formatDistance(_ meters: Double) -> String {
        let km = meters / 1000.0
        return String(format: "%.2f km", km)
    }
}

// MARK: - Route Stat Item
/// Individual stat display for elevation/distance metrics
struct RouteStatItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xxSmall) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)

            // Value
            Text(value)
                .font(DesignSystem.Typography.bodyEmphasized)
                .foregroundColor(DesignSystem.Colors.text.primary)

            // Label
            Text(label)
                .font(DesignSystem.Typography.caption2)
                .foregroundColor(DesignSystem.Colors.text.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Route Map View Representable
/// UIViewRepresentable wrapper for MKMapView with route polyline and markers
struct RouteMapViewRepresentable: UIViewRepresentable {
    let routeData: RouteData
    @Binding var region: MKCoordinateRegion

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = .standard
        mapView.isScrollEnabled = false
        mapView.isZoomEnabled = false
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        mapView.showsUserLocation = false

        // Set region to fit route
        mapView.setRegion(region, animated: false)

        // Add route polyline
        if !routeData.coordinates.isEmpty {
            let coordinates = routeData.coordinates.map { $0.coordinate }
            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            mapView.addOverlay(polyline)

            // Add start marker (green)
            if let startCoordinate = routeData.coordinates.first {
                let startAnnotation = RouteMarkerAnnotation(
                    coordinate: startCoordinate.coordinate,
                    title: "Start",
                    type: .start
                )
                mapView.addAnnotation(startAnnotation)
            }

            // Add finish marker (red)
            if let endCoordinate = routeData.coordinates.last {
                let endAnnotation = RouteMarkerAnnotation(
                    coordinate: endCoordinate.coordinate,
                    title: "Finish",
                    type: .finish
                )
                mapView.addAnnotation(endAnnotation)
            }
        }

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region if needed
        if !mapView.region.center.latitude.isEqual(to: region.center.latitude) ||
           !mapView.region.center.longitude.isEqual(to: region.center.longitude) {
            mapView.setRegion(region, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        // Render route polyline
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(DesignSystem.Colors.primary)
                renderer.lineWidth = 4
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        // Render start/finish markers
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let markerAnnotation = annotation as? RouteMarkerAnnotation else {
                return nil
            }

            let identifier = "RouteMarker"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false
            } else {
                annotationView?.annotation = annotation
            }

            // Create custom marker view
            let markerSize: CGFloat = 20
            let circleView = UIView(frame: CGRect(x: 0, y: 0, width: markerSize, height: markerSize))
            circleView.layer.cornerRadius = markerSize / 2
            circleView.layer.borderWidth = 3
            circleView.layer.borderColor = UIColor.white.cgColor

            switch markerAnnotation.type {
            case .start:
                circleView.backgroundColor = UIColor(DesignSystem.Colors.success)
            case .finish:
                circleView.backgroundColor = UIColor(DesignSystem.Colors.error)
            }

            // Convert UIView to UIImage
            let renderer = UIGraphicsImageRenderer(size: circleView.bounds.size)
            let image = renderer.image { context in
                circleView.layer.render(in: context.cgContext)
            }

            annotationView?.image = image
            annotationView?.centerOffset = CGPoint(x: 0, y: -markerSize / 2)

            return annotationView
        }
    }
}

// MARK: - Route Marker Annotation
/// Custom annotation for start/finish markers
class RouteMarkerAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let type: MarkerType

    enum MarkerType {
        case start
        case finish
    }

    init(coordinate: CLLocationCoordinate2D, title: String, type: MarkerType) {
        self.coordinate = coordinate
        self.title = title
        self.type = type
        super.init()
    }
}

// MARK: - Double Extension for Floating Point Comparison
extension Double {
    func isEqual(to other: Double, epsilon: Double = 0.0001) -> Bool {
        return abs(self - other) < epsilon
    }
}

// MARK: - Preview
#if DEBUG
struct CompletedRouteMapView_Previews: PreviewProvider {
    static var previews: some View {
        CompletedRouteMapView(routeData: sampleRouteData)
            .padding()
            .screenBackground()
    }

    static var sampleRouteData: RouteData {
        // Sample route data for preview
        let coordinates = [
            RouteCoordinate(
                latitude: 37.7749,
                longitude: -122.4194,
                altitude: 10,
                timestamp: Date(),
                speed: 3.0,
                horizontalAccuracy: 5.0
            ),
            RouteCoordinate(
                latitude: 37.7759,
                longitude: -122.4184,
                altitude: 15,
                timestamp: Date().addingTimeInterval(30),
                speed: 3.2,
                horizontalAccuracy: 5.0
            ),
            RouteCoordinate(
                latitude: 37.7769,
                longitude: -122.4174,
                altitude: 20,
                timestamp: Date().addingTimeInterval(60),
                speed: 3.1,
                horizontalAccuracy: 5.0
            ),
            RouteCoordinate(
                latitude: 37.7779,
                longitude: -122.4164,
                altitude: 12,
                timestamp: Date().addingTimeInterval(90),
                speed: 3.0,
                horizontalAccuracy: 5.0
            )
        ]

        return RouteData(
            coordinates: coordinates,
            totalDistance: 1250.5,
            elevationGain: 45.0,
            elevationLoss: 23.0
        )
    }
}
#endif
