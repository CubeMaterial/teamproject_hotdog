import CoreLocation
import MapKit
import SwiftUI
import UIKit

struct WalkView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var walkTracker = WalkTracker()
    @State private var selectedDayKey: String?
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )
    @Namespace private var mapScope

    var body: some View {
        let palette = appState.palette

        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerSection(palette: palette)
                    metricSection(palette: palette)
                    mapSection(palette: palette)
                    controlSection(palette: palette)
                    historySection(palette: palette)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(palette.background.ignoresSafeArea())
            .onAppear {
                walkTracker.startLocationPreview()
                applyDefaultSelectedDayIfNeeded()
            }
            .onChange(of: walkTracker.walkRecords) { _, _ in
                applyDefaultSelectedDayIfNeeded()
            }
            .onReceive(walkTracker.$currentLocation) { location in
                guard let location else { return }
                if walkTracker.routeCoordinates.count < 2 {
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: location.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
                        )
                    )
                }
            }
            .onReceive(walkTracker.$routeCoordinates) { coordinates in
                guard coordinates.count > 1 else { return }
                updateCamera(for: coordinates)
            }
            .onReceive(walkTracker.$completedRouteSegments) { segments in
                let coordinates = segments.flatMap { $0 }
                guard coordinates.count > 1 else { return }
                updateCamera(for: coordinates)
            }
        }
    }

    private func headerSection(palette: AppPalette) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("산책")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(palette.textPrimary)
            Text("\(appState.selectedDog.name)와 함께 걷는 경로를 기록해보세요")
                .font(.system(size: 14))
                .foregroundStyle(palette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metricSection(palette: AppPalette) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            walkMetricCard(title: "시간", value: formattedDuration(walkTracker.elapsedTime), systemImage: "clock.fill", palette: palette)
            walkMetricCard(title: "거리", value: formattedDistance(walkTracker.totalDistance), systemImage: "ruler.fill", palette: palette)
            walkMetricCard(title: "누적", value: formattedDistance(accumulatedDistance), systemImage: "point.topleft.down.curvedto.point.bottomright.up", palette: palette)
            walkMetricCard(title: "기록", value: "\(walkTracker.walkRecords.count)회", systemImage: "list.bullet.rectangle.fill", palette: palette)
        }
    }

    private func walkMetricCard(title: String, value: String, systemImage: String, palette: AppPalette) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(palette.accent)
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(palette.textSecondary)
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(palette.textPrimary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func mapSection(palette: AppPalette) -> some View {
        ZStack(alignment: .topLeading) {
            Map(position: $cameraPosition, scope: mapScope) {
                UserAnnotation()

                ForEach(Array(walkTracker.completedRouteSegments.enumerated()), id: \.offset) { _, coordinates in
                    MapPolyline(coordinates: coordinates)
                        .stroke(palette.primary.opacity(0.36), lineWidth: 5)
                }

                if walkTracker.routeCoordinates.count > 1 {
                    MapPolyline(coordinates: walkTracker.routeCoordinates)
                        .stroke(palette.accent, lineWidth: 6)
                }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .frame(maxWidth: .infinity)
            .frame(height: 360)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                if walkTracker.authorizationStatus != .authorizedAlways && walkTracker.authorizationStatus != .authorizedWhenInUse {
                    VStack(spacing: 10) {
                        Image(systemName: "location.slash.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                        Text("위치 권한이 필요해요")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                        Text("산책 경로와 거리를 기록하려면 위치 접근을 허용해주세요.")
                            .font(.system(size: 13))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.9))
                        Button {
                            if walkTracker.authorizationStatus == .denied || walkTracker.authorizationStatus == .restricted {
                                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                                UIApplication.shared.open(url)
                            } else {
                                walkTracker.requestAuthorization()
                            }
                        } label: {
                            Text(walkTracker.authorizationStatus == .denied || walkTracker.authorizationStatus == .restricted ? "설정 열기" : "권한 요청")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(palette.primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(.white, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black.opacity(0.38))
                }
            }
            .mapControls {
                MapUserLocationButton(scope: mapScope)
                MapCompass(scope: mapScope)
            }
            .mapScope(mapScope)

            Text(walkTracker.isTracking ? "기록중" : "누적 \(formattedDistance(accumulatedDistance))")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(walkTracker.isTracking ? palette.accent : palette.primary, in: Capsule())
                .padding(16)
        }
    }

    private func controlSection(palette: AppPalette) -> some View {
        VStack(spacing: 10) {
            Button {
                if walkTracker.isTracking {
                    walkTracker.stopWalk()
                } else {
                    walkTracker.startWalk()
                }
            } label: {
                Text(walkTracker.isTracking ? "산책 종료" : "산책 시작")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(walkTracker.isTracking ? palette.accent : palette.primary, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                walkTracker.resetWalk()
                selectedDayKey = nil
            } label: {
                Text("전체 기록 초기화")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(palette.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private func historySection(palette: AppPalette) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("산책 기록")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(palette.textPrimary)
                Text("일자별로 저장된 산책 경로를 확인할 수 있어요")
                    .font(.system(size: 13))
                    .foregroundStyle(palette.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if walkTracker.walkRecords.isEmpty {
                emptyHistoryCard(palette: palette)
            } else {
                dayFilterSection(palette: palette)

                ForEach(filteredRecords) { record in
                    NavigationLink {
                        WalkRecordDetailView(record: record)
                            .environmentObject(appState)
                    } label: {
                        recordRow(record, palette: palette)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func dayFilterSection(palette: AppPalette) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(walkDays, id: \.key) { day in
                    Button {
                        selectedDayKey = day.key
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(day.title)
                                .font(.system(size: 13, weight: .bold))
                            Text("\(day.count)회")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(selectedDayKey == day.key ? .white : palette.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(selectedDayKey == day.key ? palette.primary : palette.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func emptyHistoryCard(palette: AppPalette) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "figure.walk.circle")
                .font(.system(size: 28))
                .foregroundStyle(palette.accent)
            VStack(alignment: .leading, spacing: 4) {
                Text("아직 저장된 산책 기록이 없어요")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(palette.textPrimary)
                Text("산책 시작 후 종료하면 기록이 로컬에 저장됩니다")
                    .font(.system(size: 13))
                    .foregroundStyle(palette.textSecondary)
            }
            Spacer()
        }
        .padding(16)
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func recordRow(_ record: WalkRecord, palette: AppPalette) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(palette.secondary.opacity(0.14))
                    .frame(width: 50, height: 50)
                Image(systemName: "map.fill")
                    .foregroundStyle(palette.primary)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(record.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(palette.textPrimary)
                Text(record.dateText)
                    .font(.system(size: 12))
                    .foregroundStyle(palette.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                Text(formattedDistance(record.distance))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(palette.primary)
                Text(formattedDuration(record.duration))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(palette.textSecondary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(palette.textSecondary)
        }
        .padding(16)
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func formattedDuration(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func formattedDistance(_ distance: CLLocationDistance) -> String {
        if distance >= 1000 {
            return String(format: "%.2f km", distance / 1000)
        }
        return "\(Int(distance)) m"
    }

    private func updateCamera(for coordinates: [CLLocationCoordinate2D]) {
        let rect = coordinates.map { MKMapPoint($0) }.reduce(MKMapRect.null) { partial, point in
            partial.union(MKMapRect(origin: point, size: MKMapSize(width: 0, height: 0)))
        }
        cameraPosition = .rect(rect.insetBy(dx: -400, dy: -400))
    }

    private func applyDefaultSelectedDayIfNeeded() {
        let keys = Set(walkDays.map(\.key))
        if selectedDayKey == nil || selectedDayKey.map({ !keys.contains($0) }) == true {
            selectedDayKey = walkDays.first?.key
        }
    }

    private var accumulatedDistance: CLLocationDistance {
        walkTracker.walkRecords.reduce(walkTracker.totalDistance) { $0 + $1.distance }
    }

    private var filteredRecords: [WalkRecord] {
        guard let selectedDayKey else { return walkTracker.walkRecords }
        return walkTracker.walkRecords.filter { $0.dayKey == selectedDayKey }
    }

    private var walkDays: [(key: String, title: String, count: Int)] {
        let grouped = Dictionary(grouping: walkTracker.walkRecords, by: \.dayKey)
        return grouped.compactMap { key, records in
            guard let first = records.sorted(by: { $0.startDate > $1.startDate }).first else { return nil }
            return (key: key, title: first.dayText, count: records.count)
        }
        .sorted { $0.key > $1.key }
    }
}

private struct WalkRecordDetailView: View {
    @EnvironmentObject private var appState: AppState
    let record: WalkRecord
    @State private var cameraPosition: MapCameraPosition

    init(record: WalkRecord) {
        self.record = record
        self._cameraPosition = State(initialValue: WalkRecordDetailView.initialCameraPosition(for: record.routeCoordinates))
    }

    var body: some View {
        let palette = appState.palette

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Map(position: $cameraPosition) {
                    if record.routeCoordinates.count > 1 {
                        MapPolyline(coordinates: record.routeCoordinates)
                            .stroke(palette.accent, lineWidth: 6)
                    }

                    if let start = record.routeCoordinates.first {
                        Marker("출발", systemImage: "play.fill", coordinate: start)
                            .tint(palette.primary)
                    }

                    if let end = record.routeCoordinates.last {
                        Marker("도착", systemImage: "flag.fill", coordinate: end)
                            .tint(palette.accent)
                    }
                }
                .mapStyle(.standard(pointsOfInterest: .excludingAll))
                .frame(maxWidth: .infinity)
                .frame(height: 360)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    Text(record.title)
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(palette.textPrimary)
                    Text(record.dateText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(palette.textSecondary)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    detailMetric(title: "거리", value: formattedDistance(record.distance), systemImage: "ruler.fill", palette: palette)
                    detailMetric(title: "시간", value: formattedDuration(record.duration), systemImage: "clock.fill", palette: palette)
                    detailMetric(title: "경로 지점", value: "\(record.coordinates.count)개", systemImage: "mappin.and.ellipse", palette: palette)
                    detailMetric(title: "일자", value: record.dayText, systemImage: "calendar", palette: palette)
                }
            }
            .padding(16)
        }
        .background(palette.background.ignoresSafeArea())
        .navigationTitle("산책 상세")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailMetric(title: String, value: String, systemImage: String, palette: AppPalette) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(palette.accent)
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(palette.textSecondary)
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(palette.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func formattedDuration(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func formattedDistance(_ distance: CLLocationDistance) -> String {
        if distance >= 1000 {
            return String(format: "%.2f km", distance / 1000)
        }
        return "\(Int(distance)) m"
    }

    private static func initialCameraPosition(for coordinates: [CLLocationCoordinate2D]) -> MapCameraPosition {
        guard coordinates.count > 1 else {
            return .region(
                MKCoordinateRegion(
                    center: coordinates.first ?? CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            )
        }

        let rect = coordinates.map { MKMapPoint($0) }.reduce(MKMapRect.null) { partial, point in
            partial.union(MKMapRect(origin: point, size: MKMapSize(width: 0, height: 0)))
        }
        return .rect(rect.insetBy(dx: -350, dy: -350))
    }
}
