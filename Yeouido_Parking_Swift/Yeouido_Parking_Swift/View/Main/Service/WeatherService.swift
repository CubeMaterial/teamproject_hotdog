//
//  WeatherService.swift
//  Yeouido_Parking_Swift
//
//  Created by Codex on 8/18/25.
//

import Foundation

enum WeatherService {
    private static let yeouidoLatitude = 37.5219
    private static let yeouidoLongitude = 126.9245

    static func fetchYeouidoWeather() async throws -> WeatherSummary {
        async let weatherResponse = fetchWeather()
        async let airQualityResponse = fetchAirQuality()

        let weather = try await weatherResponse
        let airQuality = try await airQualityResponse

        return WeatherSummary(
            location: "여의도",
            weatherSymbolName: weather.current.symbolName,
            airQualityText: airQuality.current.displayText,
            skyText: weather.current.displayText,
            temperatureText: "\(Int(weather.current.temperature.rounded()))°",
            humidityText: "\(weather.current.relativeHumidity)%"
        )
    }

    private static func fetchWeather() async throws -> WeatherAPIResponse {
        let urlString = """
        https://api.open-meteo.com/v1/forecast?latitude=\(yeouidoLatitude)&longitude=\(yeouidoLongitude)&current=temperature_2m,relative_humidity_2m,weather_code&timezone=Asia%2FSeoul
        """

        guard let url = URL(string: urlString) else {
            throw WeatherServiceError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(WeatherAPIResponse.self, from: data)
        return decoded
    }

    private static func fetchAirQuality() async throws -> AirQualityAPIResponse {
        let urlString = """
        https://air-quality-api.open-meteo.com/v1/air-quality?latitude=\(yeouidoLatitude)&longitude=\(yeouidoLongitude)&current=us_aqi&timezone=Asia%2FSeoul
        """

        guard let url = URL(string: urlString) else {
            throw WeatherServiceError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(AirQualityAPIResponse.self, from: data)
        return decoded
    }
}

private enum WeatherServiceError: Error {
    case invalidURL
}

private struct WeatherAPIResponse: Decodable {
    let current: CurrentWeather
}

private struct CurrentWeather: Decodable {
    let temperature: Double
    let relativeHumidity: Int
    let weatherCode: Int

    enum CodingKeys: String, CodingKey {
        case temperature = "temperature_2m"
        case relativeHumidity = "relative_humidity_2m"
        case weatherCode = "weather_code"
    }

    var displayText: String {
        switch weatherCode {
        case 0:
            return "맑음"
        case 1, 2, 3:
            return "구름"
        case 45, 48:
            return "안개"
        case 51, 53, 55, 56, 57:
            return "이슬비"
        case 61, 63, 65, 66, 67, 80, 81, 82:
            return "비"
        case 71, 73, 75, 77, 85, 86:
            return "눈"
        case 95, 96, 99:
            return "뇌우"
        default:
            return "흐림"
        }
    }

    var symbolName: String {
        switch weatherCode {
        case 0:
            return "sun.max.fill"
        case 1, 2:
            return "cloud.sun.fill"
        case 3:
            return "cloud.fill"
        case 45, 48:
            return "cloud.fog.fill"
        case 51, 53, 55, 56, 57:
            return "cloud.drizzle.fill"
        case 61, 63, 65, 66, 67, 80, 81, 82:
            return "cloud.rain.fill"
        case 71, 73, 75, 77, 85, 86:
            return "cloud.snow.fill"
        case 95, 96, 99:
            return "cloud.bolt.rain.fill"
        default:
            return "cloud.fill"
        }
    }
}

private struct AirQualityAPIResponse: Decodable {
    let current: CurrentAirQuality
}

private struct CurrentAirQuality: Decodable {
    let usAQI: Int

    enum CodingKeys: String, CodingKey {
        case usAQI = "us_aqi"
    }

    var displayText: String {
        switch usAQI {
        case ..<51:
            return "좋음"
        case 51..<101:
            return "보통"
        case 101..<151:
            return "민감군"
        case 151..<201:
            return "나쁨"
        case 201..<301:
            return "매우나쁨"
        default:
            return "위험"
        }
    }
}
