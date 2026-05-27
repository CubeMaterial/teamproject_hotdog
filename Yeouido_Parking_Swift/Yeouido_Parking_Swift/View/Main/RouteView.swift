//
//  RouteView.swift
//  Yeouido_Parking_Swift
//
//  Created by Codex on 8/18/25.
//

import MapKit
import SwiftUI

struct RouteView: View {
    @EnvironmentObject private var globalState: GlobalState
    @EnvironmentObject private var parkingLocationService: ParkingLocationService

    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var route: MKRoute?
    @State private var isLoadingRoute = false
    @State private var routeErrorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Map(position: $cameraPosition) {
                    UserAnnotation()

                    ForEach(parkingLocationService.parkingLots) { parkingLot in
                        Marker(parkingLot.name, coordinate: parkingLot.coordinate)
                            .tint(globalState.selectedParkingLot == parkingLot ? .blue : .red)
                    }

                    if let route {
                        MapPolyline(route)
                            .stroke(.blue, lineWidth: 6)
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapControls {
                    MapCompass()
                    MapUserLocationButton()
                }
                .overlay(alignment: .top) {
                    routeHeader
                }

                if let selectedParkingLot = globalState.selectedParkingLot {
                    routePanel(for: selectedParkingLot)
                }
            }
            .navigationTitle("경로")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("닫기") {
                        globalState.isRoutePresented = false
                    }
                }
            }
            .task {
                parkingLocationService.requestAuthorization()
                await updateRouteIfNeeded()
            }
            .onChange(of: globalState.routeRequestID) {
                Task {
                    await updateRouteIfNeeded()
                }
            }
            .onChange(of: parkingLocationService.locationUpdateID) {
                Task {
                    await updateRouteIfNeeded()
                }
            }
        }
    }

    private var routeHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Yeouido Route")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))

            Text(globalState.selectedParkingLot?.name ?? "주차장 경로")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text(headerSubtitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.82))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 26)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.52),
                    Color.black.opacity(0.22),
                    .clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func routePanel(for selectedParkingLot: ParkingLot) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(selectedParkingLot.name)
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(Color(hex: "11211D"))

                    Text(selectedParkingLot.address)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.58))
                }

                Spacer(minLength: 12)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "63C9F2"),
                                Color(hex: "75D6AF")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay {
                        Image(systemName: "car.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    }
            }

            HStack(spacing: 12) {
                metricCard(
                    title: "예상 거리",
                    value: route.map { formattedDistance($0.distance) } ?? "--",
                    accent: Color(hex: "1C6DD0")
                )

                metricCard(
                    title: "예상 시간",
                    value: route.map { formattedTravelTime($0.expectedTravelTime) } ?? "--",
                    accent: Color(hex: "1B9C85")
                )
            }

            if isLoadingRoute {
                statusRow(
                    text: "현재 위치를 기준으로 경로를 예술적으로 탐색 중입니다.",
                    color: Color(hex: "167A8C")
                )
            } else if let routeErrorMessage {
                statusRow(text: routeErrorMessage, color: .red)
            } else {
                statusRow(
                    text: "하단 지도 선을 따라 가장 효율적인 이동 경로를 안내합니다.",
                    color: Color.black.opacity(0.62)
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 28)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(.white.opacity(0.92))

                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(.white.opacity(0.8), lineWidth: 1.2)
            }
        )
        .shadow(color: Color.black.opacity(0.14), radius: 26, y: 10)
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    private func metricCard(title: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.5))

            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(accent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func statusRow(text: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 12, weight: .bold))
            Text(text)
                .font(.system(size: 13, weight: .semibold))
        }
        .foregroundStyle(color)
    }

    private var headerSubtitle: String {
        if let route {
            return "\(formattedDistance(route.distance)) · 약 \(formattedTravelTime(route.expectedTravelTime))"
        }

        if isLoadingRoute {
            return "경로를 준비 중입니다."
        }

        return routeErrorMessage ?? "현재 위치 기준 길찾기를 준비합니다."
    }

    private func updateRouteIfNeeded() async {
        guard let destination = globalState.selectedParkingLot else {
            route = nil
            return
        }

        guard let currentLocation = parkingLocationService.currentLocation else {
            routeErrorMessage = "현재 위치를 확인할 수 없습니다."
            return
        }

        isLoadingRoute = true
        routeErrorMessage = nil

        do {
            let newRoute = try await ParkingRouteService.route(
                from: currentLocation.coordinate,
                to: destination.coordinate
            )
            route = newRoute
            cameraPosition = .rect(newRoute.polyline.boundingMapRect)
        } catch {
            route = nil
            routeErrorMessage = "경로를 불러오지 못했습니다."
        }

        isLoadingRoute = false
    }

    private func formattedDistance(_ distance: CLLocationDistance) -> String {
        if distance >= 1000 {
            return String(format: "%.1fkm", distance / 1000)
        }

        return "\(Int(distance))m"
    }

    private func formattedTravelTime(_ time: TimeInterval) -> String {
        let minutes = max(1, Int(time / 60))
        return "\(minutes)분"
    }
}

#Preview {
    RouteView()
        .environmentObject(GlobalState())
        .environmentObject(ParkingLocationService())
}
