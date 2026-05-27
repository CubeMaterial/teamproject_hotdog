//
//  MapFilterBar.swift
//  Yeouido_Parking_Swift
//

import SwiftUI

struct MapFilterBar: View {
    let selectedFilter: MapMarkerFilter
    let selectedParkingSpot: ParkingSpot?
    let onFilterTap: () -> Void
    let onFilterSelect: (MapMarkerFilter) -> Void
    let onSelectedSpotTap: (ParkingSpot) -> Void
    
    private let primaryFilters: [MapMarkerFilter] = [
        .all, .parking, .reservableFacility, .favoriteFacility
    ]
    
    private let categoryFilters: [MapMarkerFilter] = [
        .performance, .culture, .park, .food, .convenience, .otherFacility
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    Button(action: onFilterTap) {
                        HStack(spacing: 8) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 17, weight: .semibold))
                            Text("필터")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundStyle(.black)
                        .padding(.horizontal, 18)
                        .frame(height: 44)
                        .background(Color.white, in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.black, lineWidth: 1.2)
                        )
                    }
                    .buttonStyle(.plain)
                    .shadow(color: .black.opacity(0.08), radius: 10, y: 6)
                    
                    ForEach(primaryFilters) { filter in
                        filterChip(for: filter)
                    }
                }
                .padding(.vertical, 2)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(categoryFilters) { filter in
                        filterChip(for: filter)
                    }
                    
                    if let selectedParkingSpot {
                        Button {
                            onSelectedSpotTap(selectedParkingSpot)
                        } label: {
                            HStack(spacing: 6) {
                                Text("주차장")
                                    .font(.system(size: 14, weight: .bold))
                                Text(selectedParkingSpot.name)
                                    .font(.system(size: 15, weight: .semibold))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(Color.red)
                            .padding(.horizontal, 18)
                            .frame(height: 44)
                            .background(Color.white, in: Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(MapMarkerFilter.parking.accentColor, lineWidth: 1.2)
                            )
                        }
                        .buttonStyle(.plain)
                        .shadow(color: .black.opacity(0.08), radius: 10, y: 6)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
    
    @ViewBuilder
    private func filterChip(for filter: MapMarkerFilter) -> some View {
        Button {
            onFilterSelect(filter)
        } label: {
            Text(filter.rawValue)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(selectedFilter == filter ? .white : filter.accentColor)
                .padding(.horizontal, 16)
                .frame(height: 44)
                .background(
                    Capsule()
                        .fill(selectedFilter == filter ? filter.accentColor : .white)
                )
                .overlay(
                    Capsule()
                        .stroke(filter.accentColor, lineWidth: 1.2)
                )
        }
        .buttonStyle(.plain)
        .shadow(color: .black.opacity(0.08), radius: 10, y: 6)
    }
}
