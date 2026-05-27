//
//  ParkingMarker.swift
//  Yeouido_Parking_Swift
//

import SwiftUI

struct ParkingMarker: View {
    let title: String
    let isSelected: Bool

    private let accentColor = MapMarkerFilter.parking.accentColor

    var body: some View {
        VStack(spacing: 0) {
            if isSelected {
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white, in: Capsule())
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 4)
            }

            ZStack {
                Circle()
                    .stroke(isSelected ? Color.white : accentColor, lineWidth: isSelected ? 5 : 3)
                    .frame(width: isSelected ? 30 : 24, height: isSelected ? 30 : 24)
                    .background(
                        Circle()
                            .fill(accentColor)
                    )

                Circle()
                    .fill(isSelected ? Color.white : accentColor.opacity(0.9))
                    .frame(width: isSelected ? 12 : 9, height: isSelected ? 12 : 9)
            }
            .shadow(color: .black.opacity(0.16), radius: 8, y: 4)

            Rectangle()
                .fill(accentColor)
                .frame(width: 2.5, height: isSelected ? 18 : 14)

            Circle()
                .fill(accentColor.opacity(0.2))
                .frame(width: isSelected ? 10 : 8, height: isSelected ? 10 : 8)
                .blur(radius: 1)
                .offset(y: -2)
        }
    }
}
