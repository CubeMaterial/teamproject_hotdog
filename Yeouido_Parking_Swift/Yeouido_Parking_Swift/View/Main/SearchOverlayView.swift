//
//  SearchOverlayView.swift
//  Yeouido_Parking_Swift
//
//  Created by Codex on 8/18/25.
//

import SwiftUI

struct SearchOverlayView: View {
    private enum StorageKey {
        static let recentSearches = "homeRecentSearches"
    }

    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var facilities: [MapFacility] = []
    @State private var recentSearches: [String] = []
    @State private var loadMessage: String?

    let recentKeywords: [String]
    let onParkingLotSelect: (ParkingLot) -> Void
    let onFacilitySelect: (MapFacility) -> Void

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                    searchField
                    keywordSection
                    Divider()
                        .padding(.top, 20)
                    resultSection
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
            }
            .frame(maxWidth: .infinity)
            .frame(height: min(440, geometry.size.height * 0.56), alignment: .top)
            .background(
                Color.white
                    .ignoresSafeArea(edges: .top)
            )
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 24,
                    bottomTrailingRadius: 24,
                    topTrailingRadius: 0
                )
            )
            .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .task {
                loadRecentSearches()
                await loadFacilitiesIfNeeded()
            }
        }
    }

    private var header: some View {
        HStack {
            Text("통합 검색")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.black)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                    isPresented = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.black)
            }
        }
        .frame(height: 44)
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(hex: "167A8C"))

            TextField("주차장 또는 시설을 입력해 주세요.", text: $searchText)
                .font(.system(size: 16))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.black.opacity(0.26))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(Color.white)
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "63C9F2"), lineWidth: 1.6)
        }
        .padding(.top, 18)
    }

    private var keywordSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("인기키워드")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.black)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(recentKeywords, id: \.self) { keyword in
                        Button {
                            searchText = keyword
                        } label: {
                            Text(keyword)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.white)
                                .overlay {
                                    Capsule()
                                        .stroke(Color.black.opacity(0.18), lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 20)
    }

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "최근검색" : "검색 결과")
                    .font(.system(size: 16, weight: .semibold))

                Spacer()

                if !recentSearches.isEmpty && searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button("전체삭제") {
                        recentSearches.removeAll()
                        persistRecentSearches()
                    }
                    .font(.system(size: 14))
                    .foregroundStyle(.black.opacity(0.66))
                }
            }

            if let loadMessage, facilities.isEmpty {
                Text(loadMessage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.black.opacity(0.66))
            } else if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                recentSearchList
            } else if filteredResults.isEmpty {
                Text("검색 결과가 없습니다.")
                    .font(.system(size: 16))
                    .foregroundStyle(.black.opacity(0.8))
            } else {
                VStack(spacing: 10) {
                    ForEach(filteredResults) { result in
                        Button {
                            select(result)
                        } label: {
                            HStack(spacing: 14) {
                                Circle()
                                    .fill(result.badgeColor.opacity(0.12))
                                    .frame(width: 38, height: 38)
                                    .overlay {
                                        Image(systemName: result.iconName)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundStyle(result.badgeColor)
                                    }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(result.categoryText)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.secondary)
                                    Text(result.title)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 64)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color(red: 0.97, green: 0.98, blue: 0.99))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 20)
    }

    private var recentSearchList: some View {
        Group {
            if recentSearches.isEmpty {
                Text("최근검색어가 없습니다.")
                    .font(.system(size: 16))
                    .foregroundStyle(.black.opacity(0.8))
            } else {
                VStack(spacing: 10) {
                    ForEach(recentSearches, id: \.self) { keyword in
                        Button {
                            searchText = keyword
                        } label: {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundStyle(.secondary)
                                Text(keyword)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.black)
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 50)
                            .background(Color.black.opacity(0.03))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var filteredResults: [HomeSearchResult] {
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else {
            return []
        }

        let parkingResults = ParkingLot.yeouidoLots.compactMap { lot -> HomeSearchResult? in
            let matchesText = lot.name.localizedCaseInsensitiveContains(trimmedText)
                || lot.address.localizedCaseInsensitiveContains(trimmedText)

            return matchesText ? .parkingLot(lot) : nil
        }

        let facilityResults = facilities.compactMap { facility -> HomeSearchResult? in
            let matchesText = facility.name.localizedCaseInsensitiveContains(trimmedText)
                || (facility.info?.localizedCaseInsensitiveContains(trimmedText) ?? false)

            return matchesText ? .facility(facility) : nil
        }

        return parkingResults + facilityResults
    }

    private func select(_ result: HomeSearchResult) {
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedText.isEmpty {
            recentSearches.removeAll { $0 == trimmedText }
            recentSearches.insert(trimmedText, at: 0)
            recentSearches = Array(recentSearches.prefix(6))
            persistRecentSearches()
        }

        withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
            isPresented = false
        }

        switch result {
        case .parkingLot(let parkingLot):
            onParkingLotSelect(parkingLot)
        case .facility(let facility):
            onFacilitySelect(facility)
        }
    }

    private func loadFacilitiesIfNeeded() async {
        guard facilities.isEmpty else { return }

        do {
            facilities = try await MapFacilityService.fetchAllFacilities()
        } catch {
            loadMessage = error.localizedDescription
        }
    }

    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: StorageKey.recentSearches) ?? []
    }

    private func persistRecentSearches() {
        UserDefaults.standard.set(recentSearches, forKey: StorageKey.recentSearches)
    }
}

private enum HomeSearchResult: Identifiable {
    case parkingLot(ParkingLot)
    case facility(MapFacility)

    var id: String {
        switch self {
        case .parkingLot(let parkingLot):
            return "parking-\(parkingLot.id)"
        case .facility(let facility):
            return "facility-\(facility.id)"
        }
    }

    var title: String {
        switch self {
        case .parkingLot(let parkingLot):
            return parkingLot.name
        case .facility(let facility):
            return facility.name
        }
    }

    var categoryText: String {
        switch self {
        case .parkingLot:
            return "주차장 경로"
        case .facility(let facility):
            return facility.isReservable ? "예약 시설" : "기타 시설"
        }
    }

    var iconName: String {
        switch self {
        case .parkingLot:
            return "car.fill"
        case .facility(let facility):
            return facility.isReservable ? "ticket.fill" : "mappin.and.ellipse"
        }
    }

    var badgeColor: Color {
        switch self {
        case .parkingLot:
            return Color(hex: "1C6DD0")
        case .facility(let facility):
            return facility.isReservable ? Color(hex: "1B9C85") : Color(hex: "7A5AF8")
        }
    }
}

#Preview {
    SearchOverlayView(
        isPresented: .constant(true),
        recentKeywords: ["어트랙션", "페스티벌"],
        onParkingLotSelect: { _ in },
        onFacilitySelect: { _ in }
    )
}
