//
//  ReservationDetailView.swift
//  Yeouido_Parking_Swift
//
//  Created by 유다원 on 4/12/26.
//

import SwiftUI

struct ReservationDetailView: View {
    @EnvironmentObject private var globalState: GlobalState
    @Environment(\.dismiss) private var dismiss

    let reservationId: Int
    @StateObject private var vm = ReservationViewModel()
    @StateObject private var facilityViewModel = FacilityViewModel()

    private var matchedFacility: Facility? {
        guard let detail = vm.reservationDetail else { return nil }
        return facilityViewModel.facilities.first { $0.id == detail.facilityId }
    }

    private var imageURL: URL? {
        guard let image = matchedFacility?.image ?? vm.reservationDetail?.facilityImage else {
            return nil
        }

        guard let originalURL = URL(string: image) else {
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

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "63C9F2"),
                    Color(hex: "75B992")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 18) {
                    if vm.isLoading {
                        VStack {
                            Spacer().frame(height: 120)
                            ProgressView()
                            Spacer()
                        }
                    } else if let detail = vm.reservationDetail {
                        if let imageURL {
                            AsyncImage(url: imageURL) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(height: 220)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.white.opacity(0.35))
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 220)
                                        .frame(maxWidth: .infinity)
                                        .clipped()
                                case .failure:
                                    reservationHeroPlaceholder
                                @unknown default:
                                    reservationHeroPlaceholder
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .shadow(color: .black.opacity(0.12), radius: 12, y: 8)
                        }

                        VStack(alignment: .leading, spacing: 14) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(detail.facilityName)
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.black)

                                    Text("예약번호 \(detail.id)")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text(stateText(detail.state))
                                    .font(.subheadline)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(statusBackgroundColor(detail.state))
                                    .foregroundColor(statusTextColor(detail.state))
                                    .cornerRadius(20)
                            }

                            if let facilityInfo = detail.facilityInfo, !facilityInfo.isEmpty {
                                Text(facilityInfo)
                                    .font(.subheadline)
                                    .foregroundColor(.black.opacity(0.72))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(Color.white.opacity(0.88))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
                        
                        VStack(alignment: .leading, spacing: 14) {
                            Label("예약 정보", systemImage: "doc.text.fill")
                                .font(.headline)
                                .foregroundColor(.black)

                            detailRow(title: "예약 시작", value: formattedDateTime(detail.startDate))
                            detailRow(title: "예약 종료", value: formattedDateTime(detail.endDate))
                            detailRow(title: "이용 시간", value: durationText(start: detail.startDate, end: detail.endDate))
                            detailRow(title: "예약 생성", value: formattedDateTime(detail.reservationDate))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(Color.white.opacity(0.88))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
                        
                        if let matchedFacility {
                            VStack(alignment: .leading, spacing: 14) {
                                Label("시설 위치", systemImage: "location.fill")
                                    .font(.headline)
                                    .foregroundColor(.black)

                                MiniMapView(lat: matchedFacility.lat, long: matchedFacility.long)
                                    .frame(height: 180)
                                    .cornerRadius(18)

                                Button {
                                    globalState.showFacilityOnMap(facilityID: matchedFacility.id)
                                    dismiss()
                                } label: {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "map.fill")
                                        Text("맵에서 경로 확인")
                                            .fontWeight(.semibold)
                                        Spacer()
                                    }
                                    .padding(.vertical, 16)
                                    .background(Color(hex: "167A8C"))
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .background(Color.white.opacity(0.88))
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
                        }
                    } else {
                        VStack {
                            Spacer().frame(height: 120)
                            Text("상세 정보를 불러오지 못했습니다.")
                                .foregroundColor(.black)
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 30)
            }
            .navigationTitle("예약 상세")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .task {
                await vm.fetchReservationDetail(reservationId: reservationId)
                await facilityViewModel.fetchFacilities()
            }
        }
    }

    @ViewBuilder
    private func detailRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.black.opacity(0.55))
            
            Text(value)
                .font(.body)
                .foregroundColor(.black)
        }
    }

    private func stateText(_ state: Int) -> String {
        switch state {
        case 0:
            return "예약 취소"
        case 1:
            if let detail = vm.reservationDetail,
               let endDate = ReservationDateFormatter.parseServerDate(detail.endDate),
               endDate < Date() {
                return "이용 완료"
            }
            return "예약 중"
        case 2:
            return "이용 완료"
        default:
            return "알 수 없음"
        }
    }

    private func statusBackgroundColor(_ state: Int) -> Color {
        switch resolvedState(from: state) {
        case 0:
            return Color.red.opacity(0.15)
        case 1:
            return Color.blue.opacity(0.15)
        case 2:
            return Color.gray.opacity(0.15)
        default:
            return Color.gray.opacity(0.15)
        }
    }

    private func statusTextColor(_ state: Int) -> Color {
        switch resolvedState(from: state) {
        case 0:
            return .red
        case 1:
            return .blue
        case 2:
            return .gray
        default:
            return .gray
        }
    }

    private func resolvedState(from state: Int) -> Int {
        guard state == 1,
              let detail = vm.reservationDetail,
              let endDate = ReservationDateFormatter.parseServerDate(detail.endDate),
              endDate < Date() else {
            return state
        }

        return 2
    }

    private func formattedDateTime(_ text: String) -> String {
        ReservationDateFormatter.detailDateTimeText(text)
    }

    private func durationText(start: String, end: String) -> String {
        guard let startDate = ReservationDateFormatter.parseServerDate(start),
              let endDate = ReservationDateFormatter.parseServerDate(end) else { return "-" }

        let minutes = Int(endDate.timeIntervalSince(startDate) / 60)
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

    private var reservationHeroPlaceholder: some View {
        LinearGradient(
            colors: [
                Color.white.opacity(0.32),
                Color.white.opacity(0.12)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(height: 220)
    }
}
