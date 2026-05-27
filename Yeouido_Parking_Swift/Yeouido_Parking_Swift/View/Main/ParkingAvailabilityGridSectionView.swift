//
//  ParkingAvailabilityGridSectionView.swift
//  Yeouido_Parking_Swift
//
//  Created by Codex on 8/18/25.
//

import SwiftUI

struct ParkingAvailabilityGridSectionView: View {
    let parkingLots: [ParkingLot]
    let availability: [String: Int]
    let predictedAvailability: [String: Int]
    @Binding var selectedPredictionOffsetHours: Int
    let predictionHour: String
    let errorMessage: String?
    let onParkingLotTap: (ParkingLot) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Text("주차장별 잔여 대수 / 예측")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.black)

                HStack(spacing: 8) {
                    predictionSelectButton(hours: 1)
                    predictionSelectButton(hours: 2)
                    predictionSelectButton(hours: 3)
                    Spacer()
                    Text("예측 기준 \(predictionHour)시")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.black.opacity(0.45))
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.red)
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(parkingLots) { parkingLot in
                    parkingLotCard(for: parkingLot)
                }
            }
        }
    }

    private func predictionSelectButton(hours: Int) -> some View {
        let isSelected = selectedPredictionOffsetHours == hours
        return Button {
            selectedPredictionOffsetHours = hours
        } label: {
            Text("\(hours)시간 후")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(isSelected ? .white : Color(hex: "167A8C"))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? Color(hex: "167A8C") : Color(hex: "EAF4FF"))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func parkingLotCard(for parkingLot: ParkingLot) -> some View {
        Button {
            onParkingLotTap(parkingLot)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(parkingLot.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.black)

                    Spacer(minLength: 8)

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: "1C6DD0"))
                        .padding(8)
                        .background(Color(hex: "EAF4FF"))
                        .clipShape(Circle())
                }

                HStack(alignment: .firstTextBaseline) {
                    valueBlock(
                        title: "현재",
                        value: currentCountText(for: parkingLot),
                        color: Color(hex: "1C6DD0")
                    )
                    Spacer(minLength: 8)
                    valueBlock(
                        title: "\(selectedPredictionOffsetHours)시간 후",
                        value: predictedCountText(for: parkingLot),
                        color: Color(hex: "167A8C")
                    )
                }

                if let deltaLabel = deltaText(for: parkingLot),
                   let deltaColor = deltaColor(for: parkingLot) {
                    HStack(spacing: 6) {
                        Image(systemName: deltaIconName(for: parkingLot))
                            .font(.system(size: 10, weight: .bold))
                        Text(deltaLabel)
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(deltaColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(deltaColor.opacity(0.12))
                    .clipShape(Capsule())
                }

                Text(parkingLot.address)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.black.opacity(0.52))
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Image(systemName: "location.viewfinder")
                        .font(.system(size: 11, weight: .semibold))
                    Text("경로 보기")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(Color(hex: "167A8C"))
                .padding(.top, 2)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
            .background(Color.white)
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    private func valueBlock(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.black.opacity(0.48))
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(color)
        }
    }

    private func currentCountText(for parkingLot: ParkingLot) -> String {
        guard let count = availability[parkingLot.name] else {
            return "-"
        }

        return "\(count)대"
    }

    private func predictedCountText(for parkingLot: ParkingLot) -> String {
        guard let count = predictedAvailability[parkingLot.name] else {
            return "-"
        }

        return "\(count)대"
    }

    private func deltaValue(for parkingLot: ParkingLot) -> Int? {
        guard let current = availability[parkingLot.name],
              let predicted = predictedAvailability[parkingLot.name] else {
            return nil
        }
        return predicted - current
    }

    private func deltaText(for parkingLot: ParkingLot) -> String? {
        guard let delta = deltaValue(for: parkingLot) else {
            return nil
        }
        if delta == 0 {
            return "변동 없음"
        }
        let sign = delta > 0 ? "+" : ""
        return "\(sign)\(delta)대"
    }

    private func deltaColor(for parkingLot: ParkingLot) -> Color? {
        guard let delta = deltaValue(for: parkingLot) else {
            return nil
        }
        if delta > 0 {
            return Color(hex: "1B8A5A")
        }
        if delta < 0 {
            return Color(hex: "D64545")
        }
        return Color(hex: "6B7280")
    }

    private func deltaIconName(for parkingLot: ParkingLot) -> String {
        guard let delta = deltaValue(for: parkingLot) else {
            return "minus"
        }
        if delta > 0 {
            return "arrow.up"
        }
        if delta < 0 {
            return "arrow.down"
        }
        return "minus"
    }
}

#Preview {
    @Previewable @State var selectedPredictionOffsetHours = 1
    ParkingAvailabilityGridSectionView(
        parkingLots: ParkingLot.yeouidoLots,
        availability: [
            "여의도1주차장": 0,
            "여의도2주차장": 0,
            "여의도3주차장": 7,
            "여의도4주차장": 142,
            "여의도5주차장": 156
        ],
        predictedAvailability: [
            "여의도1주차장": 3,
            "여의도2주차장": 6,
            "여의도3주차장": 10,
            "여의도4주차장": 130,
            "여의도5주차장": 148
        ],
        selectedPredictionOffsetHours: $selectedPredictionOffsetHours,
        predictionHour: "14",
        errorMessage: nil,
        onParkingLotTap: { _ in }
    )
    .padding(20)
}
