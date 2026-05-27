//
//  ParkingRouteService.swift
//  Yeouido_Parking_Swift
//
//  Created by Codex on 8/18/25.
//

import CoreLocation
import MapKit

enum ParkingRouteService {
    static func route(from start: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> MKRoute {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        let response = try await directions.calculate()

        guard let route = response.routes.first else {
            throw RouteError.routeNotFound
        }

        return route
    }
}

private enum RouteError: Error {
    case routeNotFound
}
