//
//  Facility.swift
//  Yeouido_Parking_Swift
//
//  Created by Codex on 8/18/25.
//

import SwiftUI

struct FacilityView: View {
    private enum FacilityFilter: String, CaseIterable, Identifiable {
        case all = "전체"
        case performance = "공연"
        case culture = "문화"
        case park = "공원"
        case food = "식음"
        case convenience = "편의"

        var id: String { rawValue }
    }

    private enum FacilityCondition: String, CaseIterable, Identifiable {
        case reservable = "예약 가능"
        case favorite = "즐겨찾기"

        var id: String { rawValue }
    }

    @EnvironmentObject private var globalState: GlobalState
    @StateObject private var vm = FacilityViewModel()
    @State private var searchText = ""
    @State private var selectedFilter: FacilityFilter = .all
    @State private var selectedConditions: Set<FacilityCondition> = []
    @State private var selectedFacilityForReservation: Facility?
    @State private var isLoginPresented = false

    private var filteredFacilities: [Facility] {
        let baseFacilities = vm.facilities.filter { facility in
            matchesFilter(facility, filter: selectedFilter) &&
            matchesConditions(facility)
        }

        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return baseFacilities
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return baseFacilities.filter { facility in
            facility.name.localizedCaseInsensitiveContains(query) ||
            (facility.info?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    private func matchesFilter(_ facility: Facility, filter: FacilityFilter) -> Bool {
        switch filter {
        case .all:
            return true
        case .performance:
            return matchesKeywords(in: facility, keywords: ["공연", "콘서트", "무대", "축제", "페스티벌", "드론", "라이드"])
        case .culture:
            return matchesKeywords(in: facility, keywords: ["문화", "전시", "미술", "역사", "체험", "도서", "박물관", "갤러리"])
        case .park:
            return matchesKeywords(in: facility, keywords: ["공원", "한강", "산책", "광장", "정원", "생태"])
        case .food:
            return matchesKeywords(in: facility, keywords: ["식당", "카페", "푸드", "음식", "레스토랑", "베이커리", "매점"])
        case .convenience:
            return matchesKeywords(in: facility, keywords: ["화장실", "편의", "안내", "센터", "라운지", "휴게", "대여", "보관"])
        }
    }

    private func matchesConditions(_ facility: Facility) -> Bool {
        if selectedConditions.contains(.reservable), facility.possible <= 0 {
            return false
        }

        if selectedConditions.contains(.favorite), !globalState.favoriteFacilityIDs.contains(facility.id) {
            return false
        }

        return true
    }

    private func matchesKeywords(in facility: Facility, keywords: [String]) -> Bool {
        let text = "\(facility.name) \(facility.info ?? "")".lowercased()
        return keywords.contains { keyword in
            text.contains(keyword.lowercased())
        }
    }

    var body: some View {
        NavigationStack {
            ZStack{
                LinearGradient(
                    colors: [
                        Color(hex: "63C9F2"),
                        Color(hex: "75B992")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    filterHeader

                    if vm.isLoading {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                if filteredFacilities.isEmpty {
                                    FacilityEmptyStateView(
                                        isSearching: !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedFilter != .all
                                    )
                                    .padding(.top, 48)
                                } else {
                                    ForEach(filteredFacilities) { facility in
                                        NavigationLink {
                                            FacilityDetailView(facility: facility)
                                        } label: {
                                            FacilityCardView(
                                                facility: facility,
                                                isFavorite: globalState.isFavoriteFacility(facility.id),
                                                onFavoriteTap: {
                                                    globalState.toggleFavoriteFacility(facility.id)
                                                },
                                                onReserveTap: {
                                                    guard globalState.userLoginStatus else {
                                                        isLoginPresented = true
                                                        return
                                                    }
                                                    selectedFacilityForReservation = facility
                                                }
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding()
                            .padding(.bottom, 120)
                        }
                    }
                }
                .navigationTitle("시설 목록")
                .navigationBarTitleDisplayMode(.inline)
                .task {
                    await vm.fetchFacilities()
                }
                .fullScreenCover(isPresented: $isLoginPresented) {
                    LoginView()
                        .environmentObject(globalState)
                }
                .navigationDestination(item: $selectedFacilityForReservation) { facility in
                    ReservationFormView(facility: facility)
                        .environmentObject(globalState)
                }
            }
        }
    }

    private var filterHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: "167A8C"))

                TextField("시설명 또는 설명 검색", text: $searchText)
                    .font(.system(size: 15))
                    .textInputAutocapitalization(.never)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
            .background(Color.white.opacity(0.94))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(FacilityCondition.allCases) { condition in
                        Button {
                            toggleCondition(condition)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: selectedConditions.contains(condition) ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 13, weight: .semibold))
                                Text(condition.rawValue)
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(selectedConditions.contains(condition) ? Color(hex: "0F5C67") : Color(hex: "43615B"))
                            .padding(.horizontal, 14)
                            .frame(height: 34)
                            .background {
                                Group {
                                    if selectedConditions.contains(condition) {
                                        Color.white
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color(hex: "63C9F2"), lineWidth: 1.4)
                                            )
                                    } else {
                                        Color.white.opacity(0.78)
                                    }
                                }
                            }
                            .clipShape(Capsule())
                        }
                    }
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(FacilityFilter.allCases) { filter in
                        Button {
                            selectedFilter = filter
                        } label: {
                            Text(filter.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(selectedFilter == filter ? .white : Color(hex: "1F3F38"))
                                .padding(.horizontal, 14)
                                .frame(height: 34)
                                .background(
                                    Group {
                                        if selectedFilter == filter {
                                            LinearGradient(
                                                colors: [
                                                    Color(hex: "63C9F2"),
                                                    Color(hex: "75B992")
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        } else {
                                            Color.white.opacity(0.9)
                                        }
                                    }
                                )
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private func toggleCondition(_ condition: FacilityCondition) {
        if selectedConditions.contains(condition) {
            selectedConditions.remove(condition)
        } else {
            selectedConditions.insert(condition)
        }
    }
}

private struct FacilityEmptyStateView: View {
    let isSearching: Bool

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: isSearching ? "magnifyingglass.circle" : "building.2.crop.circle")
                .font(.system(size: 42))
                .foregroundStyle(Color.white.opacity(0.95))

            Text(isSearching ? "조건에 맞는 시설이 없습니다" : "등록된 시설이 없습니다")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)

            Text(isSearching ? "검색어나 필터를 바꿔 다시 확인해 주세요." : "잠시 후 다시 시도해 주세요.")
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.82))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }
}
