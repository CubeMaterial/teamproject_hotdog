//
//  APIService.swift
//  Yeouido_Parking_Swift
//
//  Created by 유다원 on 4/12/26.
//

import Foundation

struct APIErrorResponse: Codable {
    let detail: String
}

struct APIError: Error {
    let message: String
}

final class APIService {
    
    static let shared = APIService()
    private init() {}
    
    private let baseURL = "http://127.0.0.1:8000"
    
    // 시설 탭용: 전체 시설
    func fetchFacilities() async throws -> [Facility] {
        let url = URL(string: "\(baseURL)/facilities")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Facility].self, from: data)
    }
    
    // 예약 탭용: 예약 가능한 시설만
    func fetchReservableFacilities() async throws -> [Facility] {
        let url = URL(string: "\(baseURL)/facilities/reservable")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Facility].self, from: data)
    }
    
    func createReservation(request: ReservationCreateRequest) async throws -> Reservation {
        let url = URL(string: "\(baseURL)/reservation")!
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.cachePolicy = .reloadIgnoringLocalCacheData
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError(message: "응답을 확인할 수 없습니다.")
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw APIError(message: apiError.detail)
            } else {
                throw APIError(message: "예약 요청에 실패했습니다.")
            }
        }
        
        return try JSONDecoder().decode(Reservation.self, from: data)
    }
    
    func fetchReservations(userId: Int) async throws -> [Reservation] {
        let url = URL(string: "\(baseURL)/reservation/user/\(userId)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Reservation].self, from: data)
    }
    
    func fetchReservationDetail(reservationId: Int) async throws -> ReservationDetail {
        let url = URL(string: "\(baseURL)/reservation/\(reservationId)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(ReservationDetail.self, from: data)
    }
    
    func fetchDailyReservations(facilityId: Int, date: String) async throws -> [DailyReservation] {
        let url = URL(string: "\(baseURL)/reservation/facility/\(facilityId)/date/\(date)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError(message: "응답을 확인할 수 없습니다.")
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw APIError(message: apiError.detail)
            } else {
                throw APIError(message: "예약 시간 조회에 실패했습니다.")
            }
        }
        
        return try JSONDecoder().decode([DailyReservation].self, from: data)
    }
    
    func updateReservationState(reservationId: Int, state: Int) async throws {
        let url = URL(string: "\(baseURL)/reservation/\(reservationId)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["reservation_state": state]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError(message: "예약 상태 변경 실패")
        }
    }
}
