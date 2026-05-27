//
//  MapFacilityService.swift
//  Yeouido_Parking_Swift
//

import Foundation

enum MapFacilityServiceError: LocalizedError {
    case invalidResponse
    case connection
    case decoding(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "시설물 데이터를 확인할 수 없습니다."
        case .connection:
            return "시설물 서버에 연결할 수 없습니다."
        case .decoding(let message):
            return "시설물 디코딩 실패: \(message)"
        }
    }
}

enum MapFacilityService {
    static func fetchAllFacilities() async throws -> [MapFacility] {
        var request = URLRequest(url: AuthAPI.baseURL.appendingPathComponent("facilities"))
        request.httpMethod = "GET"
        request.timeoutInterval = 5

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw MapFacilityServiceError.connection
        }

        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw MapFacilityServiceError.invalidResponse
        }

        let decoder = JSONDecoder()

        if let direct = try? decoder.decode([MapFacility].self, from: data) {
            return direct
        }

        if let wrapped = try? decoder.decode(FacilityListResponse.self, from: data) {
            return wrapped.data
        }

        let preview = String(decoding: data.prefix(200), as: UTF8.self)
        throw MapFacilityServiceError.decoding(preview)
    }
}

private struct FacilityListResponse: Decodable {
    let data: [MapFacility]
}
