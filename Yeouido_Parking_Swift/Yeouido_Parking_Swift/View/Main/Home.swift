//
//  Home.swift
//  Yeouido_Parking_Swift
//
//  Created by Codex on 8/18/25.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var globalState: GlobalState
    @EnvironmentObject private var parkingLocationService: ParkingLocationService
    @AppStorage("isDarkModeEnabled") private var isDarkModeEnabled = false
    @StateObject private var facilityViewModel = FacilityViewModel()
    @State private var isSearchPresented = false
    @State private var isNotificationPresented = false
    @State private var isMenuPresented = false
    @State private var weather = WeatherSummary.placeholder(location: "여의도")
    @State private var festivals: [FestivalItem] = []
    @State private var parkingAvailability: [String: Int] = [:]
    @State private var isInquiryExpanded = false
    @State private var isLoginRequiredPresented = false
    @State private var isChatPresented = false
    @State private var isFavoriteListPresented = false
    @State private var isReservationListPresented = false
    @State private var predictedAvailabilityByLot: [String: Int] = [:]
    @State private var selectedPredictionOffsetHours = 1
    @State private var predictionErrorMessage: String?

    private let predictionEngine = WeightPredictionEngine.makeDefault()
    private let parkingCapacityByName: [String: Int] = [
        "여의도1주차장": 230,
        "여의도2주차장": 180,
        "여의도3주차장": 140,
        "여의도4주차장": 450,
        "여의도5주차장": 560
    ]

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

                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Text("여한이 없을까?")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)

                        Spacer()

                        HeaderIconButton(systemName: "magnifyingglass") {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                                isNotificationPresented = false
                                isMenuPresented = false
                                isSearchPresented = true
                            }
                        }
                        ZStack(alignment: .topTrailing) {
                            HeaderIconButton(systemName: "bell") {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                                    isSearchPresented = false
                                    isMenuPresented = false
                                    isNotificationPresented = true
                                }
                            }

                            if globalState.unreadNotificationCount > 0 {
                                Circle()
                                    .fill(Color(hex: "ED9781"))
                                    .frame(width: 10, height: 10)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                                    .offset(x: 2, y: -2)
                            }
                        }
                        HeaderIconButton(systemName: "line.3.horizontal") {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                                isSearchPresented = false
                                isNotificationPresented = false
                                isMenuPresented = true
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                    ZStack {
                        Color.white
                            .ignoresSafeArea(edges: .bottom)

                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 14) {
                                WeatherSectionView(
                                    weather: weather
                                )
                                .padding(.horizontal, 20)
                                .padding(.top, 18)

                                NearestParkingSectionView(
                                    parkingLot: parkingLocationService.nearestParkingLot,
                                    distanceText: parkingLocationService.nearestParkingDistanceText,
                                    availableCount: parkingAvailability[parkingLocationService.nearestParkingLot?.name ?? ""]
                                ) { parkingLot in
                                    globalState.showRoute(to: parkingLot)
                                }
                                .padding(.horizontal, 20)

                                if !favoriteFacilities.isEmpty {
                                    FavoriteFacilitiesSectionView(
                                        facilities: favoriteFacilities,
                                        favoriteIDs: globalState.favoriteFacilityIDs,
                                        onFavoriteTap: { facility in
                                            globalState.toggleFavoriteFacility(facility.id)
                                        },
                                        onFacilityTap: { facility in
                                            globalState.showFacilityOnMap(facilityID: facility.id)
                                        }
                                    )
                                    .padding(.horizontal, 20)
                                }

                                FestivalSectionView(festivals: festivals)

                                ParkingHoursSectionView(
                                    title: "주차장 이용시간",
                                    hoursText: "06:00 - 23:00"
                                )
                                .padding(.horizontal, 20)
                                
                                ParkingAvailabilityGridSectionView(
                                    parkingLots: ParkingLot.yeouidoLots,
                                    availability: parkingAvailability,
                                    predictedAvailability: predictedAvailabilityByLot,
                                    selectedPredictionOffsetHours: $selectedPredictionOffsetHours,
                                    predictionHour: HomeView.hourOffsetBucket(
                                        from: HomeView.currentHourBucket(),
                                        offset: selectedPredictionOffsetHours
                                    ),
                                    errorMessage: predictionErrorMessage,
                                    onParkingLotTap: { parkingLot in
                                        globalState.showRoute(to: parkingLot)
                                    }
                                )
                                .padding(.horizontal, 20)
                                .padding(.bottom, 150)
                            }
                        }
                        .refreshable {
                            await refreshHomeData()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 28,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 28
                        )
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if isSearchPresented || isNotificationPresented || isMenuPresented {
                    Color.black.opacity(0.18)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                                isSearchPresented = false
                                isNotificationPresented = false
                                isMenuPresented = false
                            }
                        }
                        .transition(.opacity)
                        .zIndex(1)

                    if isSearchPresented || isNotificationPresented {
                        VStack(spacing: 0) {
                            Color.white
                                .frame(height: 120)
                                .ignoresSafeArea(edges: .top)

                            Spacer()
                        }
                        .allowsHitTesting(false)
                        .zIndex(2)
                    }

                    if isSearchPresented {
                        SearchOverlayView(
                            isPresented: $isSearchPresented,
                            recentKeywords: ["여의도1주차장", "축제", "공연장"],
                            onParkingLotSelect: { parkingLot in
                                globalState.showRoute(to: parkingLot)
                            },
                            onFacilitySelect: { facility in
                                globalState.showFacilityOnMap(facilityID: facility.id)
                            }
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(3)
                    }

                    if isNotificationPresented {
                        NotificationOverlayView(
                            isPresented: $isNotificationPresented,
                            notifications: globalState.notifications,
                            onNotificationTap: { notification in
                                globalState.removeNotification(notification.id)
                            },
                            onClearAll: {
                                globalState.clearNotifications()
                            },
                            onAppear: {
                                globalState.markAllNotificationsAsRead()
                            }
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(3)
                    }

                    if isMenuPresented {
                        MenuDrawerView(
                            isPresented: $isMenuPresented,
                            isDarkModeEnabled: $isDarkModeEnabled,
                            onLoginTap: {
                                isLoginRequiredPresented = true
                            },
                            onFavoriteListTap: {
                                isFavoriteListPresented = true
                            },
                            onReservationListTap: {
                                isReservationListPresented = true
                            }
                        )
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        .zIndex(3)
                    }
                }

                VStack {
                    Spacer()

                    HStack {
                        Spacer()

                        InquiryFloatingButtonView(
                            isExpanded: $isInquiryExpanded,
                            isCompact: isMenuPresented,
                            onCallTap: openPhoneInquiry,
                            onChatTap: openChatInquiry
                        )
                        .offset(x: isMenuPresented ? -292 : 0, y: isMenuPresented ? -10 : 0)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 104)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(4)
            }
            .toolbar(.hidden, for: .navigationBar)
            .task {
                await refreshHomeData()
            }
            .onChange(of: parkingAvailability) { _, _ in
                refreshPrediction()
            }
            .onChange(of: selectedPredictionOffsetHours) { _, _ in
                refreshPrediction()
            }
            .fullScreenCover(isPresented: $globalState.isRoutePresented) {
                RouteView()
                    .environmentObject(globalState)
                    .environmentObject(parkingLocationService)
            }
            .fullScreenCover(isPresented: $isLoginRequiredPresented) {
                LoginView()
                    .environmentObject(globalState)
            }
            .fullScreenCover(isPresented: $isChatPresented) {
                ChatView()
                    .environmentObject(globalState)
            }
            .fullScreenCover(isPresented: $isFavoriteListPresented) {
                FavoriteListView()
                    .environmentObject(globalState)
            }
            .fullScreenCover(isPresented: $isReservationListPresented) {
                ReservationListView()
                    .environmentObject(globalState)
            }
        }
    }

    private func loadWeather() async {
        do {
            weather = try await WeatherService.fetchYeouidoWeather()
        } catch {
            weather = WeatherSummary.placeholder(location: "여의도")
        }
    }

    private func loadParkingAvailability() async {
        do {
            parkingAvailability = try await ParkingAvailabilityService.fetchYeouidoAvailability()
        } catch {
            parkingAvailability = [:]
        }
    }

    private func loadFestivals() async {
        do {
            festivals = try await FestivalService.fetchYeouidoFestivals()
        } catch {
            festivals = []
        }
    }

    private func refreshHomeData() async {
        parkingLocationService.requestAuthorization()
        await loadWeather()
        await loadParkingAvailability()
        await loadFestivals()
        await facilityViewModel.fetchFacilities()
        refreshPrediction()
    }

    private func refreshPrediction() {
        let anchorHour = HomeView.currentHourBucket()
        let targetHour = HomeView.hourOffsetBucket(from: anchorHour, offset: selectedPredictionOffsetHours)
        var output: [String: Int] = [:]
        var hasAnyPrediction = false

        for lot in ParkingLot.yeouidoLots {
            guard let anchorCount = parkingAvailability[lot.name] else { continue }
            let capacity = parkingCapacityByName[lot.name] ?? max(anchorCount + 100, 200)

            if let predictedByHour = try? predictionEngine.predict(
                date: Date(),
                anchorHour: anchorHour,
                anchorCount: anchorCount,
                maxCapacity: capacity
            ) {
                output[lot.name] = predictedByHour[targetHour] ?? anchorCount
                hasAnyPrediction = true
            }
        }

        predictedAvailabilityByLot = output
        predictionErrorMessage = hasAnyPrediction ? nil : "예측할 주차장 데이터가 없습니다."
    }

    private static func currentHourBucket() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let clamped = min(max(hour, 7), 22)
        return String(format: "%02d", clamped)
    }

    private static func hourOffsetBucket(from hourText: String, offset: Int) -> String {
        guard let hour = Int(hourText) else { return "22" }
        let safeOffset = min(max(offset, 1), 3)
        return String(format: "%02d", min(hour + safeOffset, 22))
    }

    private func openPhoneInquiry() {
        guard let url = URL(string: "tel://15775252") else { return }
        openURL(url)
    }

    private func openChatInquiry() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
            isInquiryExpanded = false
        }

        guard globalState.userLoginStatus else {
            isLoginRequiredPresented = true
            return
        }

        isChatPresented = true
    }
}

private struct FavoriteFacilitiesSectionView: View {
    let facilities: [Facility]
    let favoriteIDs: Set<Int>
    let onFavoriteTap: (Facility) -> Void
    let onFacilityTap: (Facility) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("즐겨찾는 시설")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color(hex: "1F3F38"))

                Spacer()

                Text("\(facilities.count)곳")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "167A8C"))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(facilities) { facility in
                        Button {
                            onFacilityTap(facility)
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(facility.name)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(Color(hex: "1F3F38"))
                                            .lineLimit(1)

                                        Text(facility.info ?? "시설 설명이 없습니다.")
                                            .font(.system(size: 12))
                                            .foregroundStyle(Color.black.opacity(0.55))
                                            .lineLimit(2)
                                    }

                                    Spacer(minLength: 10)

                                    Button {
                                        onFavoriteTap(facility)
                                    } label: {
                                        Image(systemName: favoriteIDs.contains(facility.id) ? "heart.fill" : "heart")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(Color(hex: "ED9781"))
                                            .frame(width: 30, height: 30)
                                            .background(Color.white.opacity(0.95))
                                            .clipShape(Circle())
                                    }
                                }

                                HStack {
                                    Label("지도에서 보기", systemImage: "map")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(Color(hex: "167A8C"))

                                    Spacer()

                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(Color(hex: "167A8C"))
                                }
                            }
                            .padding(16)
                            .frame(width: 240, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white,
                                                Color(hex: "F3FFFC")
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color(hex: "D8F3EC"), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 10, y: 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

private struct HeaderIconButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(.white.opacity(0.22))
                .clipShape(Circle())
        }
    }
}

#Preview {
    HomeView()
}
