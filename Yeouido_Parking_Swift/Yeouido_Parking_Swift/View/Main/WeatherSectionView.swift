//
//  WeatherSectionView.swift
//  Yeouido_Parking_Swift
//
//  Created by Codex on 8/18/25.
//

import SwiftUI

struct WeatherSummary {
    let location: String
    let weatherSymbolName: String
    let airQualityText: String
    let skyText: String
    let temperatureText: String
    let humidityText: String
}

extension WeatherSummary {
    static func placeholder(location: String) -> WeatherSummary {
        WeatherSummary(
            location: location,
            weatherSymbolName: "cloud.sun.fill",
            airQualityText: "불러오는 중",
            skyText: "확인 중",
            temperatureText: "--°",
            humidityText: "--%"
        )
    }
}

struct WeatherSectionView: View {
    let weather: WeatherSummary

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "aqi.medium")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.78))

                Text("미세먼지")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.76))

                Text(weather.airQualityText)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(hex: "1C6DD0"))
            }

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: weather.weatherSymbolName)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Color(hex: "F4B400"))

                Text(weather.temperatureText)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.black)

                Text(weather.skyText)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.82))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
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

        WeatherSectionView(
            weather: WeatherSummary(
                location: "여의도",
                weatherSymbolName: "cloud.sun.fill",
                airQualityText: "보통",
                skyText: "맑음",
                temperatureText: "27°",
                humidityText: "61%"
            )
        )
        .padding(20)
    }
}
