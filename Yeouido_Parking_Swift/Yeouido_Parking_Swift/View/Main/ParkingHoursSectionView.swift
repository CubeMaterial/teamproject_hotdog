//
//  ParkingHoursSectionView.swift
//  Yeouido_Parking_Swift
//
//  Created by Codex on 8/18/25.
//

import SwiftUI

struct ParkingHoursSectionView: View {
    let title: String
    let hoursText: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.badge.checkmark.fill")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(Color(hex: "F4B860"))
                .frame(width: 38, height: 38)
                .background(Color(hex: "F7F7F9"))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.62))

                Text(hoursText)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.black)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.black.opacity(0.16), lineWidth: 1.2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "63C9F2"), Color(hex: "75B992")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        ParkingHoursSectionView(
            title: "주차장 이용시간",
            hoursText: "06:00 - 23:00"
        )
        .padding(20)
    }
}
