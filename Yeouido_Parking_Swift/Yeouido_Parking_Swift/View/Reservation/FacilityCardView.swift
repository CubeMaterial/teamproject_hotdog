//
//  FacilityCardView.swift
//  Yeouido_Parking_Swift
//
//  Created by 유다원 on 4/12/26.
//

import SwiftUI

struct FacilityCardView: View {
    let facility: Facility
    var isFavorite = false
    var onFavoriteTap: (() -> Void)?
    var onReserveTap: (() -> Void)?

    private var imageURL: URL? {
        guard let image = facility.image else {
            return nil
        }
        return Self.resolvedImageURL(from: image)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(height: 160)
                .clipped()
                .cornerRadius(12)

                if let onFavoriteTap {
                    Button(action: onFavoriteTap) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(isFavorite ? Color(hex: "ED9781") : Color(hex: "1F3F38"))
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.94))
                            .clipShape(Circle())
                    }
                    .padding(10)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 10) {
                    Text(facility.name)
                        .font(.headline)
                        .foregroundColor(.black)

                    Spacer()

                    if facility.possible > 0 {
                        Text("예약 가능")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(hex: "167A8C"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(hex: "E5F8F4"))
                            .clipShape(Capsule())
                    }
                }

                Text(facility.info ?? "시설 설명 없음")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)

                if facility.possible > 0, let onReserveTap {
                    HStack {
                        Spacer()

                        Button("예약하기") {
                            onReserveTap()
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .frame(height: 30)
                        .background(Color(hex: "167A8C"))
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.88))
        .cornerRadius(16)
        .shadow(radius: 3)
    }
}

private extension FacilityCardView {
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
