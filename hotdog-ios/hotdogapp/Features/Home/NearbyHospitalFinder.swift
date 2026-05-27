import Combine
import CoreLocation
import MapKit
import Foundation

struct NearbyHospital: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let address: String
    let distance: CLLocationDistance
}

@MainActor
final class NearbyHospitalFinder: NSObject, ObservableObject {
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var isLoading = false
    @Published var hospitals: [NearbyHospital] = []
    @Published var errorMessage: String?

    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?

    override init() {
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    func refreshNearbyHospitals() {
        errorMessage = nil

        if authorizationStatus == .notDetermined {
            requestAuthorization()
        }

        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            errorMessage = "위치 권한을 허용하면 근처 동물병원을 추천해드릴 수 있어요."
            return
        }

        isLoading = true
        locationManager.requestLocation()
    }

    private func searchHospitals(near location: CLLocation) {
        Task {
            let region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 4000,
                longitudinalMeters: 4000
            )

            let request = MKLocalSearch.Request(naturalLanguageQuery: "동물병원", region: region)
            request.resultTypes = .pointOfInterest

            do {
                let response = try await MKLocalSearch(request: request).start()
                let results = response.mapItems.compactMap { item -> NearbyHospital? in
                    guard let placeLocation = item.placemark.location else { return nil }
                    let distance = placeLocation.distance(from: location)
                    let address = [item.placemark.thoroughfare, item.placemark.subThoroughfare, item.placemark.locality]
                        .compactMap { $0 }
                        .joined(separator: " ")

                    return NearbyHospital(
                        name: item.name ?? "이름 없음",
                        address: address.isEmpty ? "주소 정보 없음" : address,
                        distance: distance
                    )
                }
                .sorted { $0.distance < $1.distance }

                hospitals = Array(results.prefix(5))
                if hospitals.isEmpty {
                    errorMessage = "근처에서 추천할 동물병원을 찾지 못했어요."
                }
            } catch {
                errorMessage = "근처 병원을 불러오지 못했어요."
            }

            isLoading = false
        }
    }
}

extension NearbyHospitalFinder: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            isLoading = false
            errorMessage = "현재 위치를 가져오지 못했어요."
            return
        }

        currentLocation = location
        searchHospitals(near: location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoading = false
        errorMessage = "현재 위치를 가져오지 못했어요."
    }
}
