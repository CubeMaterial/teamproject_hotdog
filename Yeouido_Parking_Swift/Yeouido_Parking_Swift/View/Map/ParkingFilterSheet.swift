//
//  ParkingFilterSheet.swift
//  Yeouido_Parking_Swift
//

import SwiftUI

struct ParkingFilterSheet: View {
    @Binding var searchText: String
    @Binding var selectedFilter: MapMarkerFilter
    @Binding var selectedParkingSpotID: Int?
    @State private var sheetOffset: CGFloat = 0

    let filterOptions: [MapMarkerFilter]
    let searchResults: [MapSearchResult]
    let onClose: () -> Void
    let onResultSelect: (MapSearchResult) -> Void
    
    private let primaryFilters: [MapMarkerFilter] = [
        .all, .parking, .reservableFacility, .favoriteFacility
    ]
    
    private let categoryFilters: [MapMarkerFilter] = [
        .performance, .culture, .park, .food, .convenience, .otherFacility
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                Color.black.opacity(0.24)
                    .ignoresSafeArea()
                    .onTapGesture {
                        onClose()
                    }

                VStack(alignment: .leading, spacing: 18) {
                    dragIndicator

                    searchField
                    quickFilterRow
                    parkingList
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 0)
                .frame(maxWidth: .infinity)
                .frame(height: max(geometry.size.height - 96, 500), alignment: .top)
                .background(
                    ZStack(alignment: .bottom) {
                        Rectangle()
                            .fill(Color.white)
                            .ignoresSafeArea(edges: .bottom)

                        UnevenRoundedRectangle(
                            topLeadingRadius: 28,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 28,
                            style: .continuous
                        )
                        .fill(Color.white)
                    }
                )
                .offset(y: max(sheetOffset, 0))
                .gesture(sheetDragGesture)
                .ignoresSafeArea(.container, edges: .bottom)
            }
            .ignoresSafeArea(.container, edges: .bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }

    private var dragIndicator: some View {
        Capsule()
            .fill(Color(.systemGray4))
            .frame(width: 44, height: 5)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(.systemGray2))

            TextField("목적지를 입력해주세요.", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(size: 16))

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.black.opacity(0.28))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(red: 0.97, green: 0.98, blue: 1.0))
        )
    }

    private var quickFilterRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("필터")
                .font(.system(size: 15, weight: .bold))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(primaryFilterOptions) { filter in
                        filterChip(for: filter)
                    }
                }
                .padding(.vertical, 2)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(categoryFilterOptions) { filter in
                        filterChip(for: filter)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var primaryFilterOptions: [MapMarkerFilter] {
        filterOptions.filter { primaryFilters.contains($0) }
    }
    
    private var categoryFilterOptions: [MapMarkerFilter] {
        filterOptions.filter { categoryFilters.contains($0) }
    }
    
    @ViewBuilder
    private func filterChip(for filter: MapMarkerFilter) -> some View {
        Button {
            selectedFilter = filter
        } label: {
            Text(filter.rawValue)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(selectedFilter == filter ? .white : filter.accentColor)
                .padding(.horizontal, 14)
                .frame(height: 42)
                .background(
                    Capsule()
                        .fill(selectedFilter == filter ? filter.accentColor : .white)
                )
                .overlay(
                    Capsule()
                        .stroke(filter.accentColor, lineWidth: 1.2)
                )
        }
        .buttonStyle(.plain)
    }

    private var parkingList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("검색 결과")
                .font(.title3.weight(.bold))

            ScrollView {
                if searchResults.isEmpty {
                    EmptyView()
                } else {
                    VStack(spacing: 10) {
                        ForEach(searchResults) { result in
                            Button {
                                if case .parking(let spot) = result {
                                    selectedParkingSpotID = spot.id
                                } else {
                                    selectedParkingSpotID = nil
                                }
                                onResultSelect(result)
                                onClose()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(result.categoryText)
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.secondary)
                                        Text(result.title)
                                            .font(.system(size: 17, weight: .semibold))
                                            .foregroundStyle(.primary)
                                    }

                                    Spacer()

                                    if result.id == selectedResultID {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.red)
                                    } else {
                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 62)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(Color(red: 0.97, green: 0.97, blue: 0.98))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var sheetDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation.height > 0 {
                    sheetOffset = value.translation.height
                } else {
                    sheetOffset = value.translation.height * 0.18
                }
            }
            .onEnded { value in
                if value.translation.height > 120 {
                    onClose()
                } else {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                        sheetOffset = 0
                    }
                }
            }
    }
    private var selectedResultID: String? {
        if let selectedParkingSpotID {
            return "parking-\(selectedParkingSpotID)"
        }
        return nil
    }
}
