//
//  FacilityMarker.swift
//  Yeouido_Parking_Swift
//

import SwiftUI

struct FacilityMarker: View {
    let title: String
    let isSelected: Bool
    let category: MapFacilityCategory?
    let isReservable: Bool
    let isFavorite: Bool

    var body: some View {
        VStack(spacing: 0) {
            if isSelected {
                HStack(spacing: 6) {
                    if let categoryLabel {
                        markerChip(text: categoryLabel, color: markerAccentColor)
                    }

                    if isReservable {
                        markerChip(text: "예약 가능", color: MapMarkerFilter.reservableFacility.accentColor)
                    }

                    if isFavorite {
                        markerChip(text: "즐겨찾기", color: MapMarkerFilter.favoriteFacility.accentColor)
                    }

                    Text(title)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.black)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white, in: Capsule())
                .shadow(color: .black.opacity(0.12), radius: 6, y: 4)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(markerBackgroundColor)
                    .frame(width: isSelected ? 42 : 36, height: isSelected ? 42 : 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(markerBorderColor, lineWidth: isSelected ? 2 : 1.5)
                    )

                Image(systemName: categorySymbolName)
                    .font(.system(size: isSelected ? 20 : 17, weight: .bold))
                    .foregroundStyle(.white)

                VStack {
                    HStack {
                        Spacer()
                        if isFavorite {
                            markerStateBadge(
                                systemName: "heart.fill",
                                tint: MapMarkerFilter.favoriteFacility.accentColor
                            )
                        }
                    }
                    Spacer()
                    HStack {
                        if isReservable {
                            markerStateBadge(
                                systemName: "ticket.fill",
                                tint: MapMarkerFilter.reservableFacility.accentColor
                            )
                        }
                        Spacer()
                    }
                }
                .padding(3)
            }
            .shadow(color: .black.opacity(0.14), radius: 8, y: 4)

            Rectangle()
                .fill(markerAccentColor)
                .frame(width: 2, height: isSelected ? 12 : 10)
        }
    }

    private var markerAccentColor: Color {
        categoryFilter.accentColor
    }

    private var markerBackgroundColor: Color {
        markerAccentColor
    }

    private var markerBorderColor: Color {
        isSelected ? Color.white : markerAccentColor.opacity(0.95)
    }

    private var categoryLabel: String? {
        category?.rawValue
    }

    private var categoryFilter: MapMarkerFilter {
        switch category {
        case .performance:
            return .performance
        case .culture:
            return .culture
        case .park:
            return .park
        case .food:
            return .food
        case .convenience:
            return .convenience
        case nil:
            return .otherFacility
        }
    }

    private var categorySymbolName: String {
        switch category {
        case .performance:
            return "music.mic"
        case .culture:
            return "paintpalette.fill"
        case .park:
            return "leaf.fill"
        case .food:
            return "fork.knife"
        case .convenience:
            return "sparkles"
        case nil:
            return "building.2.fill"
        }
    }

    private func markerChip(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color, in: Capsule())
    }

    private func markerStateBadge(systemName: String, tint: Color) -> some View {
        Circle()
            .fill(Color.white)
            .frame(width: 14, height: 14)
            .overlay(
                Image(systemName: systemName)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(tint)
            )
    }
}
