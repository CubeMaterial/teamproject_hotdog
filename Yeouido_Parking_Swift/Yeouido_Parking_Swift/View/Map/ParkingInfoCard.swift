//
//  ParkingInfoCard.swift
//  Yeouido_Parking_Swift
//

import SwiftUI

struct ParkingInfoCard: View {
    let parkingSpot: ParkingSpot
    let availability: ParkingAvailability?
    let isLoading: Bool
    let errorMessage: String?
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Text(parkingSpot.shortDisplayName)
                    .font(.headline.weight(.bold))
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.35))
                }
                .buttonStyle(.plain)
            }

            Text(parkingSpot.address)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if isLoading {
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                    Text("잔여 대수를 불러오는 중입니다.")
                        .font(.subheadline.weight(.medium))
                }
            } else if let availability {
                Text("잔여대수 \(availability.availableSpots) / 전체대수 \(availability.totalSpots)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(availability.availableSpots > 0 ? Color.blue : Color.red)
            } else if let errorMessage {
                Text(errorMessage)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.red)
            } else {
                Text("잔여 대수 정보가 없습니다.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 196, alignment: .topLeading)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 22,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 22,
                style: .continuous
            )
                .fill(Color.white.opacity(0.96))
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 22,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 22,
                style: .continuous
            )
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(height: 1)
        }
        .shadow(color: .black.opacity(0.1), radius: 14, y: 8)
    }
}
