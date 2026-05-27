//
//  FacilityInfoCard.swift
//  Yeouido_Parking_Swift
//

import SwiftUI

struct FacilityInfoCard: View {
    let facility: MapFacility
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Text("예약 시설")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.orange)
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.35))
                }
                .buttonStyle(.plain)
            }

            Text(facility.name)
                .font(.headline.weight(.bold))

            if let displayInfo, !displayInfo.isEmpty {
                Text(displayInfo)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            } else {
                Text("시설 정보가 없습니다.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text("해당 시설은 예약탭에서 예약이 가능합니다.")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.orange)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 192, alignment: .topLeading)
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

    private var displayInfo: String? {
        guard let info = facility.info else { return nil }

        let filteredLines = info
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !$0.contains("이용기간") }

        guard !filteredLines.isEmpty else { return nil }
        return filteredLines.joined(separator: "\n")
    }
}
