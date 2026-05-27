//
//  NearestParkingSectionView.swift
//  Yeouido_Parking_Swift
//
//  Created by Codex on 8/18/25.
//

import SwiftUI

struct NearestParkingSectionView: View {
    let parkingLot: ParkingLot?
    let distanceText: String
    let availableCount: Int?
    let onTap: (ParkingLot) -> Void

    var body: some View {
        Button {
            guard let parkingLot else { return }
            onTap(parkingLot)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "parkingsign.circle.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color(hex: "1C6DD0"))
                    .frame(width: 42, height: 42)
                    .background(Color(hex: "EEF5FF"))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("현재 가장 가까운 주차장")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.black.opacity(0.58))

                    Text(parkingLot?.name ?? "위치를 확인 중입니다.")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.black)

                    Text(parkingLot?.address ?? "위치 권한을 허용하면 가장 가까운 주차장을 안내합니다.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.black.opacity(0.55))
                        .lineLimit(1)

                    if let availableCount {
                        Text("실시간 주차 가능 \(availableCount)대")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(hex: "1C6DD0"))
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(distanceText)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(hex: "1C6DD0"))

                    Text("경로 보기")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.black.opacity(parkingLot == nil ? 0.28 : 0.58))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
        .disabled(parkingLot == nil)
        .buttonStyle(.plain)
    }
}

#Preview {
    NearestParkingSectionView(
        parkingLot: ParkingLot.yeouidoLots[0],
        distanceText: "420m",
        availableCount: 142
    ) { _ in }
    .padding(20)
}
