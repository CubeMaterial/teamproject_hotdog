import Combine
import CoreLocation
import Foundation

struct WalkCoordinate: Codable, Hashable {
    let latitude: Double
    let longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    init(_ coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }

    var clLocationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct WalkRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let startDate: Date
    let duration: TimeInterval
    let distance: CLLocationDistance
    let coordinates: [WalkCoordinate]

    init(
        id: UUID = UUID(),
        title: String,
        startDate: Date,
        duration: TimeInterval,
        distance: CLLocationDistance,
        coordinates: [WalkCoordinate]
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.duration = duration
        self.distance = distance
        self.coordinates = coordinates
    }

    var routeCoordinates: [CLLocationCoordinate2D] {
        coordinates.map(\.clLocationCoordinate)
    }

    var dateText: String {
        Self.recordDateFormatter.string(from: startDate)
    }

    var dayText: String {
        Self.dayFormatter.string(from: startDate)
    }

    var dayKey: String {
        Self.dayKeyFormatter.string(from: startDate)
    }

    private static let recordDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 HH:mm"
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter
    }()

    private static let dayKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

@MainActor
final class WalkTracker: NSObject, ObservableObject {
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var isTracking = false
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    @Published var completedRouteSegments: [[CLLocationCoordinate2D]] = []
    @Published var walkRecords: [WalkRecord] = []
    @Published var currentLocation: CLLocation?
    @Published var elapsedTime: TimeInterval = 0
    @Published var totalDistance: CLLocationDistance = 0

    private let locationManager = CLLocationManager()
    private var timerCancellable: AnyCancellable?
    private var startDate: Date?
    private var lastRecordedLocation: CLLocation?
    private var pendingStartAfterAuthorization = false

    private static let recordsStorageKey = "hotdog_walk_records_v1"
    private static let didSeedRecordsKey = "hotdog_walk_records_seeded_v1"

    override init() {
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5
        locationManager.activityType = .fitness
        loadStoredRecords()
    }

    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startLocationPreview() {
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
            return
        }
        if authorizationStatus == .notDetermined {
            requestAuthorization()
        }
    }

    func startWalk() {
        if authorizationStatus == .notDetermined {
            pendingStartAfterAuthorization = true
            requestAuthorization()
            locationManager.startUpdatingLocation()
            return
        }

        if authorizationStatus == .denied || authorizationStatus == .restricted {
            return
        }

        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }

        routeCoordinates = []
        elapsedTime = 0
        totalDistance = 0
        startDate = Date()
        lastRecordedLocation = nil

        isTracking = true
        locationManager.startUpdatingLocation()
        startTimer()
    }

    func stopWalk() {
        finalizeCurrentWalk()
        isTracking = false
        locationManager.stopUpdatingLocation()
        timerCancellable?.cancel()
        timerCancellable = nil
        routeCoordinates = []
        elapsedTime = 0
        totalDistance = 0
        startDate = nil
        lastRecordedLocation = nil
    }

    func resetWalk() {
        stopWalk()
        routeCoordinates = []
        completedRouteSegments = []
        walkRecords = []
        currentLocation = nil
        elapsedTime = 0
        totalDistance = 0
        startDate = nil
        lastRecordedLocation = nil
        UserDefaults.standard.set(true, forKey: Self.didSeedRecordsKey)
        saveRecords()
    }

    private func startTimer() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let startDate else { return }
                self.elapsedTime = Date().timeIntervalSince(startDate)
            }
    }

    private func appendLocationIfNeeded(_ location: CLLocation) {
        let locationAge = Date().timeIntervalSince(location.timestamp)
        guard locationAge < 15 else { return }
        guard location.horizontalAccuracy >= 0, location.horizontalAccuracy < 50 else { return }

        currentLocation = location

        guard isTracking else { return }

        if let lastRecordedLocation {
            let distance = location.distance(from: lastRecordedLocation)
            guard distance >= 3 else { return }
            totalDistance += distance
        }

        routeCoordinates.append(location.coordinate)
        lastRecordedLocation = location
    }

    private func finalizeCurrentWalk() {
        guard isTracking else { return }
        guard elapsedTime > 0 || totalDistance > 0 || routeCoordinates.count > 1 else { return }

        let recordRoute = routeCoordinates.map(WalkCoordinate.init)
        if routeCoordinates.count > 1 {
            completedRouteSegments.append(routeCoordinates)
        }

        walkRecords.insert(
            WalkRecord(
                title: "산책 기록 \(walkRecords.count + 1)",
                startDate: startDate ?? Date(),
                duration: elapsedTime,
                distance: totalDistance,
                coordinates: recordRoute
            ),
            at: 0
        )
        saveRecords()
    }

    private func loadStoredRecords() {
        if let data = UserDefaults.standard.data(forKey: Self.recordsStorageKey),
           let decodedRecords = try? JSONDecoder().decode([WalkRecord].self, from: data) {
            walkRecords = decodedRecords.sorted { $0.startDate > $1.startDate }
        } else if !UserDefaults.standard.bool(forKey: Self.didSeedRecordsKey) {
            walkRecords = Self.sampleRecords
            UserDefaults.standard.set(true, forKey: Self.didSeedRecordsKey)
            saveRecords()
        }

        completedRouteSegments = walkRecords
            .map(\.routeCoordinates)
            .filter { $0.count > 1 }
    }

    private func saveRecords() {
        guard let data = try? JSONEncoder().encode(walkRecords) else { return }
        UserDefaults.standard.set(data, forKey: Self.recordsStorageKey)
        completedRouteSegments = walkRecords
            .map(\.routeCoordinates)
            .filter { $0.count > 1 }
    }

    private static var sampleRecords: [WalkRecord] {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

        return [
            WalkRecord(
                title: "한강공원 저녁 산책",
                startDate: calendar.date(bySettingHour: 18, minute: 20, second: 0, of: today) ?? today,
                duration: 1_860,
                distance: 1_420,
                coordinates: [
                    WalkCoordinate(latitude: 37.52882, longitude: 126.93265),
                    WalkCoordinate(latitude: 37.52923, longitude: 126.93418),
                    WalkCoordinate(latitude: 37.52994, longitude: 126.93566),
                    WalkCoordinate(latitude: 37.53072, longitude: 126.93692),
                    WalkCoordinate(latitude: 37.53128, longitude: 126.93816)
                ]
            ),
            WalkRecord(
                title: "동네 공원 아침 산책",
                startDate: calendar.date(bySettingHour: 8, minute: 10, second: 0, of: yesterday) ?? yesterday,
                duration: 1_240,
                distance: 860,
                coordinates: [
                    WalkCoordinate(latitude: 37.56652, longitude: 126.97802),
                    WalkCoordinate(latitude: 37.56696, longitude: 126.97908),
                    WalkCoordinate(latitude: 37.56742, longitude: 126.98032),
                    WalkCoordinate(latitude: 37.56698, longitude: 126.98115),
                    WalkCoordinate(latitude: 37.56621, longitude: 126.98064)
                ]
            )
        ]
    }
}

extension WalkTracker: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }

        if pendingStartAfterAuthorization && (authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways) {
            pendingStartAfterAuthorization = false
            startWalk()
        }
        if authorizationStatus == .denied || authorizationStatus == .restricted {
            pendingStartAfterAuthorization = false
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            appendLocationIfNeeded(location)
        }
    }
}
