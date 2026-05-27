//
//  FacilityDetailView.swift
//  Yeouido_Parking_Swift
//
//  Created by 유다원 on 4/12/26.
//

import SwiftUI

struct FacilityDetailView: View {
    @EnvironmentObject private var globalState: GlobalState
    let facility: Facility
    @State private var isLoginPresented = false
    @State private var goToReservation = false

    private var imageURL: URL? {
        guard let image = facility.image else {
            return nil
        }
        
        return Self.resolvedImageURL(from: image)
    }

    private var canReserve: Bool {
        facility.possible > 0
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
                    
                    // 🔥 이미지 카드
                    if let url = imageURL {
                        
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(height: 220)
                                
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 220)
                                    .clipped()
                                
                            case .failure:
                                Color.gray.opacity(0.3)
                                    .frame(height: 220)
                                
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(height: 220)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
                    }
                    
                    // 🔥 시설 정보 카드
                    VStack(alignment: .leading, spacing: 14) {
                        
                        Text(facility.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("시설 정보")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        Text(facility.info ?? "시설 정보가 없습니다.")
                            .font(.subheadline)
                            .foregroundColor(.black.opacity(0.75))
                            .fixedSize(horizontal: false, vertical: true)

                        if canReserve {
                            reservationButton(compact: true)
                                .padding(.top, 4)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color.white.opacity(0.88))
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
                    
                    // 🔥 위치 카드
                    VStack(alignment: .leading, spacing: 14) {
                        
                        Label("위치", systemImage: "location.fill")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        MiniMapView(
                            lat: facility.lat,
                            long: facility.long
                        )
                        .frame(height: 180)
                        .cornerRadius(14)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color.white.opacity(0.88))
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
            .safeAreaPadding(.top)
            .navigationTitle("시설 상세")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        globalState.toggleFavoriteFacility(facility.id)
                    } label: {
                        Image(systemName: globalState.isFavoriteFacility(facility.id) ? "heart.fill" : "heart")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(globalState.isFavoriteFacility(facility.id) ? Color(hex: "ED9781") : .white)
                    }
                }
            }
            .navigationDestination(isPresented: $goToReservation) {
                ReservationFormView(facility: facility)
                    .environmentObject(globalState)
            }
            .fullScreenCover(isPresented: $isLoginPresented) {
                LoginView()
                    .environmentObject(globalState)
            }
            .safeAreaInset(edge: .bottom) {
                if canReserve {
                    reservationButton(compact: false)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.96),
                                    Color.white.opacity(0.82)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .ignoresSafeArea()
                        )
                }
            }
        }
    }

    @ViewBuilder
    private func reservationButton(compact: Bool) -> some View {
        Button {
            guard globalState.userLoginStatus else {
                isLoginPresented = true
                return
            }
            goToReservation = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: compact ? 14 : 16, weight: .bold))

                Text("이 시설 예약하기")
                    .font(.system(size: compact ? 15 : 16, weight: .bold))

                Spacer(minLength: 0)

                if !compact {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, compact ? 16 : 18)
            .frame(height: compact ? 44 : 52)
            .frame(maxWidth: compact ? nil : .infinity)
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: "167A8C"),
                        Color(hex: "1E9BB1")
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: compact ? 22 : 18, style: .continuous))
            .shadow(color: Color(hex: "167A8C").opacity(0.28), radius: compact ? 8 : 14, x: 0, y: 6)
        }
    }
}

private extension FacilityDetailView {
    static func resolvedImageURL(from rawValue: String) -> URL? {
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
    
    static func googleDriveFileID(from url: URL) -> String? {
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
