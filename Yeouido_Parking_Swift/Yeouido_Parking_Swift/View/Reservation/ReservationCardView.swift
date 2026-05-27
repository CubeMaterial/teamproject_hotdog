//
//  ReservationCardView.swift
//  Yeouido_Parking_Swift
//
//  Created by 유다원 on 4/13/26.
//

import SwiftUI

struct ReservationCardView: View {
    let reservation: Reservation
    let facility: Facility?

    var body: some View {
        let state = computedState(reservation)

        VStack(alignment: .leading, spacing: 14) {
            ZStack(alignment: .topLeading) {
                ReservationFacilityImage(imageURL: imageURL)
                    .frame(height: 148)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.55),
                        Color.black.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(facility?.name ?? "시설 \(reservation.facilityId)")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(.white)

                    Text("예약번호 \(reservation.id)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.82))
                }
                .padding(16)
            }

            HStack(spacing: 10) {
                ReservationMetricChip(
                    title: "예약 시작",
                    value: formattedDateTime(reservation.startDate)
                )
                ReservationMetricChip(
                    title: "이용 시간",
                    value: durationText
                )
                ReservationMetricChip(
                    title: "상태",
                    value: stateText(state),
                    tint: colorForState(state)
                )
            }

            HStack(alignment: .center) {
                if let facilityInfo = facility?.info, !facilityInfo.isEmpty {
                    Text(facilityInfo)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: "167A8C"))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 6)
    }
    
    private func computedState(_ reservation: Reservation) -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        guard let endDate = formatter.date(from: reservation.endDate) else {
            return reservation.state
        }

        if reservation.state == 1 && endDate < Date() {
            return 2
        }

        return reservation.state
    }

    private func stateText(_ state: Int) -> String {
        switch state {
        case 0: return "예약 취소"
        case 1: return "예약 중"
        case 2: return "이용 완료"
        default: return "알 수 없음"
        }
    }
    
    private func colorForState(_ state: Int) -> Color {
        switch state {
        case 0: return Color(hex: "ED9781")
        case 1: return Color(hex: "63C9F2")
        case 2: return .gray
        default: return .black
        }
    }

    private func formattedDateTime(_ text: String) -> String {
        ReservationDateFormatter.cardStartText(text)
    }

    private var durationText: String {
        guard let start = ReservationDateFormatter.parseServerDate(reservation.startDate),
              let end = ReservationDateFormatter.parseServerDate(reservation.endDate) else {
            return "-"
        }

        let minutes = Int(end.timeIntervalSince(start) / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0 && remainingMinutes > 0 {
            return "\(hours)시간 \(remainingMinutes)분"
        }

        if hours > 0 {
            return "\(hours)시간"
        }

        return "\(remainingMinutes)분"
    }

    private var imageURL: URL? {
        guard let image = facility?.image else { return nil }
        return resolvedImageURL(from: image)
    }

    private func resolvedImageURL(from rawValue: String) -> URL? {
        guard let originalURL = URL(string: rawValue) else {
            return nil
        }

        if originalURL.host?.contains("drive.google.com") == true,
           let fileID = googleDriveFileID(from: originalURL) {
            var components = URLComponents()
            components.scheme = "https"
            components.host = "drive.google.com"
            components.path = "/uc"
            components.queryItems = [
                URLQueryItem(name: "export", value: "view"),
                URLQueryItem(name: "id", value: fileID)
            ]
            return components.url
        }

        return originalURL
    }

    private func googleDriveFileID(from url: URL) -> String? {
        let pathComponents = url.pathComponents

        if let fileIndex = pathComponents.firstIndex(of: "d"),
           pathComponents.indices.contains(fileIndex + 1) {
            return pathComponents[fileIndex + 1]
        }

        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let id = components.queryItems?.first(where: { $0.name == "id" })?.value,
           id.isEmpty == false {
            return id
        }

        return nil
    }
}

private struct ReservationFacilityImage: View {
    let imageURL: URL?

    var body: some View {
        AsyncImage(url: imageURL) { phase in
            switch phase {
            case .empty:
                placeholder
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                placeholder
            @unknown default:
                placeholder
            }
        }
    }

    private var placeholder: some View {
        LinearGradient(
            colors: [
                Color(hex: "63C9F2"),
                Color(hex: "75B992")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct ReservationMetricChip: View {
    let title: String
    let value: String
    var tint: Color = Color(hex: "167A8C")

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(hex: "F6FBFB"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
