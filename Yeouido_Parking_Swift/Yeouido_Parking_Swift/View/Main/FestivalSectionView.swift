//
//  FestivalSectionView.swift
//  Yeouido_Parking_Swift
//
//  Created by Codex on 8/18/25.
//

import SwiftUI

struct FestivalItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let imageName: String?
    let imageURL: URL?
    let detailURL: URL?
}

struct FestivalSectionView: View {
    let festivals: [FestivalItem]

    private var displayFestivals: [FestivalItem] {
        festivals.isEmpty ? fallbackFestivals : festivals
    }

    var body: some View {
        TabView {
            ForEach(displayFestivals) { festival in
                FestivalCardView(festival: festival)
                    .padding(.horizontal, 16)
            }
        }
        .frame(height: 400)
        .tabViewStyle(.page(indexDisplayMode: .automatic))
    }

    private var fallbackFestivals: [FestivalItem] {
        [
            FestivalItem(
                title: "드론라이트쇼",
                subtitle: "한강 야경과 함께 즐기는 야간 축제",
                imageName: "드론라이트쇼",
                imageURL: nil,
                detailURL: nil
            ),
            FestivalItem(
                title: "서울스프링페스티벌",
                subtitle: "봄 시즌 대표 문화 축제",
                imageName: "서울스프링페스티벌",
                imageURL: nil,
                detailURL: nil
            ),
            FestivalItem(
                title: "책읽는 한강공원",
                subtitle: "여유롭게 쉬며 즐기는 야외 독서 축제",
                imageName: "책읽는 한강공원",
                imageURL: nil,
                detailURL: nil
            )
        ]
    }
}

private struct FestivalCardView: View {
    @Environment(\.openURL) private var openURL
    let festival: FestivalItem

    var body: some View {
        Button {
            guard let detailURL = festival.detailURL else { return }
            openURL(detailURL)
        } label: {
            ZStack(alignment: .bottomLeading) {
                festivalImage

                LinearGradient(
                    colors: [.clear, .black.opacity(0.72)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text(festival.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)

                    Text(festival.subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.86))
                        .lineLimit(3)
                }
                .padding(18)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 400)
            .clipShape(RoundedRectangle(cornerRadius: 28))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var festivalImage: some View {
        if let imageURL = festival.imageURL {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    fallbackImage
                case .empty:
                    ZStack {
                        LinearGradient(
                            colors: [Color(hex: "DDEBF4"), Color(hex: "B4CFE3")],
                            startPoint: .top,
                            endPoint: .bottom
                        )

                        ProgressView()
                            .tint(.white)
                    }
                @unknown default:
                    fallbackImage
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 400)
            .clipped()
        } else {
            fallbackImage
        }
    }

    private var fallbackImage: some View {
        Group {
            if let imageName = festival.imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [Color(hex: "DDEBF4"), Color(hex: "B4CFE3")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 400)
        .clipped()
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "63C9F2"), Color(hex: "75B992")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        FestivalSectionView(festivals: [])
    }
}
