//
//  ParkingLocationService.swift
//  Yeouido_Parking_Swift
//
//  Created by Codex on 8/18/25.
//

import CoreLocation
import Combine
import Foundation

final class ParkingLocationService: NSObject, ObservableObject {
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var nearestParkingLot: ParkingLot?
    @Published private(set) var nearestParkingDistanceText = "위치 확인 중"
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationUpdateID = UUID()

    let parkingLots = ParkingLot.yeouidoLots

    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
    }

    func requestAuthorization() {
        authorizationStatus = locationManager.authorizationStatus

        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            nearestParkingLot = parkingLots.first
            nearestParkingDistanceText = "위치 권한 필요"
        }
    }

    private func updateNearestParkingLot(using location: CLLocation) {
        guard let nearest = parkingLots.min(by: {
            location.distance(from: CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude))
            < location.distance(from: CLLocation(latitude: $1.coordinate.latitude, longitude: $1.coordinate.longitude))
        }) else { return }

        let distance = location.distance(from: CLLocation(latitude: nearest.coordinate.latitude, longitude: nearest.coordinate.longitude))
        nearestParkingLot = nearest
        nearestParkingDistanceText = distanceText(for: distance)
        locationUpdateID = UUID()
    }

    private func distanceText(for distance: CLLocationDistance) -> String {
        if distance >= 1000 {
            return String(format: "%.1fkm", distance / 1000)
        }

        return "\(Int(distance))m"
    }
}

extension ParkingLocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus

            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.startUpdatingLocation()
            case .denied, .restricted:
                self.nearestParkingLot = self.parkingLots.first
                self.nearestParkingDistanceText = "위치 권한 필요"
            default:
                break
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.last else { return }

        DispatchQueue.main.async {
            self.currentLocation = latestLocation
            self.updateNearestParkingLot(using: latestLocation)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.nearestParkingLot = self.parkingLots.first
            self.nearestParkingDistanceText = "위치 확인 실패"
        }
    }
}
