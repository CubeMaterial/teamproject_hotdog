import SwiftUI

struct FavoriteListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var globalState: GlobalState
    @StateObject private var facilityViewModel = FacilityViewModel()

    private var favoriteFacilities: [Facility] {
        facilityViewModel.facilities.filter { globalState.favoriteFacilityIDs.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
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

                Group {
                    if facilityViewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else if favoriteFacilities.isEmpty {
                        FavoriteEmptyStateView()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 16) {
                                ForEach(favoriteFacilities) { facility in
                                    Button {
                                        globalState.showFacilityOnMap(facilityID: facility.id)
                                        dismiss()
                                    } label: {
                                        FacilityCardView(
                                            facility: facility,
                                            isFavorite: globalState.isFavoriteFacility(facility.id),
                                            onFavoriteTap: {
                                                globalState.toggleFavoriteFacility(facility.id)
                                            }
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(16)
                        }
                    }
                }
            }
            .navigationTitle("즐겨찾기 시설")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await facilityViewModel.fetchFacilities()
        }
    }
}

private struct FavoriteEmptyStateView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "heart.slash")
                .font(.system(size: 42))
                .foregroundStyle(.white)

            Text("즐겨찾기한 시설이 없습니다")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)

            Text("시설 목록에서 하트를 눌러 자주 찾는 시설을 저장해 보세요.")
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.82))
                .multilineTextAlignment(.center)
        }
        .padding(24)
    }
}

#Preview {
    FavoriteListView()
        .environmentObject(GlobalState())
}
