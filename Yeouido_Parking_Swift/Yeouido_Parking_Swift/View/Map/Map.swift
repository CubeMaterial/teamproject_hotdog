//
//  Map.swift
//  Yeouido_Parking_Swift
//
//  Created by Codex on 8/18/25.
//

import MapKit
import SwiftUI

struct MapView: View {
    @EnvironmentObject private var globalState: GlobalState
    private let floatingTabBarSpacing: CGFloat = 96

    @State private var searchText = ""
    @State private var isFilterSheetPresented = false
    @State private var selectedFilter: MapMarkerFilter = .parking
    @State private var selectedParkingSpotID: Int?
    @State private var selectedFacilityID: Int?
    @State private var availabilityBySourceName: [String: ParkingAvailability] = [:]
    @State private var isLoadingAvailability = false
    @State private var availabilityErrorMessage: String?
    @State private var facilities: [MapFacility] = []
    @State private var facilityLoadMessage: String?
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.5276, longitude: 126.9329),
            span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
        )
    )

    private let parkingSpots = ParkingSpot.sampleSpots
    private let availabilityService = MapParkingAvailabilityService.shared

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                mapLayer
                mapShade

                VStack(spacing: 0) {
                    MapFilterBar(
                        selectedFilter: selectedFilter,
                        selectedParkingSpot: selectedParkingSpot,
                        onFilterTap: {
                            isFilterSheetPresented = true
                        },
                        onFilterSelect: { filter in
                            selectedFilter = filter
                            clearSelectionIfNeeded(for: filter)
                        },
                        onSelectedSpotTap: { spot in
                            select(spot)
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    Spacer()
                }

                if isFilterSheetPresented {
                    ParkingFilterSheet(
                        searchText: $searchText,
                        selectedFilter: $selectedFilter,
                        selectedParkingSpotID: $selectedParkingSpotID,
                        filterOptions: MapMarkerFilter.allCases,
                        searchResults: filteredSearchResults,
                        onClose: {
                            isFilterSheetPresented = false
                        },
                        onResultSelect: { result in
                            switch result {
                            case .parking(let spot):
                                select(spot)
                            case .facility(let facility):
                                select(facility)
                            }
                        }
                    )
                    .zIndex(10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .toolbar(.hidden, for: .navigationBar)
            .animation(.spring(response: 0.34, dampingFraction: 0.86), value: isFilterSheetPresented)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Group {
                    if !isFilterSheetPresented {
                        if let selectedParkingSpot {
                            VStack(spacing: 0) {
                                ParkingInfoCard(
                                    parkingSpot: selectedParkingSpot,
                                    availability: availabilityBySourceName[selectedParkingSpot.sourceName],
                                    isLoading: isLoadingAvailability,
                                    errorMessage: availabilityErrorMessage,
                                    onClose: {
                                        selectedParkingSpotID = nil
                                        availabilityErrorMessage = nil
                                    }
                                )
                                drawerBottomExtension
                            }
                            .padding(.horizontal, 16)
                        } else if let selectedReservableFacility {
                            VStack(spacing: 0) {
                                FacilityInfoCard(
                                    facility: selectedReservableFacility,
                                    onClose: {
                                        selectedFacilityID = nil
                                    }
                                )
                                drawerBottomExtension
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .task {
                await loadFacilitiesIfNeeded()
                applyExternalSelectionIfNeeded()
            }
            .onChange(of: globalState.mapSelectionRequestID) {
                applyExternalSelectionIfNeeded()
            }
            .onChange(of: isFilterSheetPresented) { _, isPresented in
                globalState.isMapFilterSheetPresented = isPresented
            }
            .onDisappear {
                globalState.isMapFilterSheetPresented = false
            }
        }
    }

    private var mapLayer: some View {
        Map(position: $cameraPosition) {
            ForEach(filteredFacilities) { facility in
                Annotation(facility.name, coordinate: facility.coordinate, anchor: .bottom) {
                    Button {
                        toggleSelection(for: facility)
                    } label: {
                        FacilityMarker(
                            title: facility.name,
                            isSelected: selectedFacilityID == facility.id,
                            category: facility.category,
                            isReservable: facility.isReservable,
                            isFavorite: globalState.favoriteFacilityIDs.contains(facility.id)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            ForEach(filteredMapParkingSpots) { spot in
                Annotation(spot.name, coordinate: spot.coordinate, anchor: .bottom) {
                    Button {
                        toggleSelection(for: spot)
                    } label: {
                        ParkingMarker(
                            title: spot.shortDisplayName,
                            isSelected: selectedParkingSpotID == spot.id
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControlVisibility(.hidden)
        .ignoresSafeArea()
    }

    private var mapShade: some View {
        LinearGradient(
            colors: [
                Color.black.opacity(0.12),
                Color.clear,
                Color.black.opacity(0.06)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
    
    private var drawerBottomExtension: some View {
        Rectangle()
            .fill(Color.white.opacity(0.96))
            .frame(height: floatingTabBarSpacing)
    }

    private var filteredParkingSpots: [ParkingSpot] {
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedText.isEmpty {
            return parkingSpots
        }

        return parkingSpots.filter { $0.name.localizedCaseInsensitiveContains(trimmedText) }
    }

    private var filteredSearchResults: [MapSearchResult] {
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        let parkingResults: [MapSearchResult] = shouldShowParking(for: selectedFilter)
            ? parkingSpots.compactMap { spot -> MapSearchResult? in
                if trimmedText.isEmpty || spot.name.localizedCaseInsensitiveContains(trimmedText) {
                    return .parking(spot)
                }
                return nil
            }
            : []

        let facilityResults = facilities.compactMap { facility -> MapSearchResult? in
            guard matchesFacility(facility, for: selectedFilter) else { return nil }

            if trimmedText.isEmpty {
                return .facility(facility)
            }

            let matchesText = facility.name.localizedCaseInsensitiveContains(trimmedText)
                || (facility.info?.localizedCaseInsensitiveContains(trimmedText) ?? false)
            return matchesText ? .facility(facility) : nil
        }

        if selectedFilter == .all {
            return parkingResults + facilityResults
        }

        return shouldShowParking(for: selectedFilter) ? parkingResults : facilityResults
    }

    private var selectedParkingSpot: ParkingSpot? {
        parkingSpots.first { $0.id == selectedParkingSpotID }
    }

    private var selectedReservableFacility: MapFacility? {
        guard let selectedFacilityID else { return nil }

        return facilities.first {
            $0.id == selectedFacilityID && $0.isReservable
        }
    }

    private var filteredMapParkingSpots: [ParkingSpot] {
        shouldShowParking(for: selectedFilter) ? parkingSpots : []
    }

    private var filteredFacilities: [MapFacility] {
        facilities.filter { matchesFacility($0, for: selectedFilter) }
    }

    private func select(_ spot: ParkingSpot) {
        selectedParkingSpotID = spot.id
        selectedFacilityID = nil
        focus(on: spot)
        loadAvailability(for: spot)
    }

    private func select(_ facility: MapFacility) {
        selectedFacilityID = facility.id
        selectedParkingSpotID = nil
        cameraPosition = .region(
            MKCoordinateRegion(
                center: facility.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.0045, longitudeDelta: 0.0045)
            )
        )
    }
    
    private func toggleSelection(for spot: ParkingSpot) {
        if selectedParkingSpotID == spot.id {
            selectedParkingSpotID = nil
            availabilityErrorMessage = nil
            return
        }
        
        select(spot)
    }
    
    private func toggleSelection(for facility: MapFacility) {
        if selectedFacilityID == facility.id {
            selectedFacilityID = nil
            return
        }
        
        select(facility)
    }

    private func focus(on spot: ParkingSpot) {
        cameraPosition = .region(
            MKCoordinateRegion(
                center: spot.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.0045, longitudeDelta: 0.0045)
            )
        )
    }

    private func loadAvailability(for spot: ParkingSpot) {
        if availabilityBySourceName[spot.sourceName] != nil {
            availabilityErrorMessage = nil
            return
        }

        isLoadingAvailability = true
        availabilityErrorMessage = nil

        Task {
            do {
                let availabilities = try await availabilityService.fetchAvailabilities()
                await MainActor.run {
                    availabilityBySourceName = availabilities
                    isLoadingAvailability = false

                    if availabilities[spot.sourceName] == nil {
                        availabilityErrorMessage = "잔여 대수를 찾지 못했습니다."
                    }
                }
            } catch {
                await MainActor.run {
                    isLoadingAvailability = false
                    availabilityErrorMessage = "잔여 대수를 불러오지 못했습니다."
                }
            }
        }
    }

    private func loadFacilitiesIfNeeded() async {
        guard facilities.isEmpty else { return }

        do {
            let fetchedFacilities = try await MapFacilityService.fetchAllFacilities()
            await MainActor.run {
                facilities = fetchedFacilities
                facilityLoadMessage = "시설물 \(fetchedFacilities.count)개 표시"
            }
        } catch {
            await MainActor.run {
                facilityLoadMessage = error.localizedDescription
            }
        }
    }

    private func applyExternalSelectionIfNeeded() {
        guard let selectedMapFacilityID = globalState.selectedMapFacilityID else { return }

        if let facility = facilities.first(where: { $0.id == selectedMapFacilityID }) {
            // 시설 상세 등 외부 진입으로 맵을 열 때는 시설이 바로 보이도록 전체 필터로 전환한다.
            if selectedFilter == .parking {
                selectedFilter = .all
            }
            select(facility)
        }
    }

    private func clearSelectionIfNeeded(for filter: MapMarkerFilter) {
        if filter == .all {
            return
        }

        if filter == .parking {
            selectedFacilityID = nil
            return
        }

        selectedParkingSpotID = nil
        if let selectedFacilityID,
           let selectedFacility = facilities.first(where: { $0.id == selectedFacilityID }),
           !matchesFacility(selectedFacility, for: filter) {
            self.selectedFacilityID = nil
        }
    }

    private func shouldShowParking(for filter: MapMarkerFilter) -> Bool {
        filter == .all || filter == .parking
    }

    private func matchesFacility(_ facility: MapFacility, for filter: MapMarkerFilter) -> Bool {
        switch filter {
        case .all:
            return true
        case .parking:
            return false
        case .reservableFacility:
            return facility.isReservable
        case .favoriteFacility:
            return globalState.favoriteFacilityIDs.contains(facility.id)
        case .performance:
            return facility.category == .performance
        case .culture:
            return facility.category == .culture
        case .park:
            return facility.category == .park
        case .food:
            return facility.category == .food
        case .convenience:
            return facility.category == .convenience
        case .otherFacility:
            return facility.category == nil
        }
    }
}

#Preview {
    MapView()
}
