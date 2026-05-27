//
//  ReservationViewModel.swift
//  Yeouido_Parking_Swift
//
//  Created by 유다원 on 4/12/26.
//

import Foundation
import Combine

@MainActor
final class ReservationViewModel: ObservableObject {
    @Published var reservations: [Reservation] = []
    @Published var reservationDetail: ReservationDetail?
    @Published var createdReservation: Reservation?
    @Published var dailyReservations: [DailyReservation] = []
    @Published var reservedHours: Set<Int> = []
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchReservations(userId: Int) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            reservations = try await APIService.shared.fetchReservations(userId: userId)
        } catch {
            print("예약 목록 조회 실패:", error)
        }
    }
    
    func fetchReservationDetail(reservationId: Int) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            reservationDetail = try await APIService.shared.fetchReservationDetail(reservationId: reservationId)
        } catch {
            print("예약 상세 조회 실패:", error)
        }
    }
    
    func fetchDailyReservations(facilityId: Int, date: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            dailyReservations = try await APIService.shared.fetchDailyReservations(facilityId: facilityId, date: date)
            reservedHours = makeReservedHours(from: dailyReservations, targetDate: date)
        } catch let error as APIError {
            errorMessage = error.message
            print("일별 예약 조회 실패:", error.message)
        } catch {
            errorMessage = error.localizedDescription
            print("일별 예약 조회 실패:", error)
        }
    }
    
    func createReservation(
        userId: Int,
        facilityId: Int,
        startDate: String,
        endDate: String
    ) async -> Reservation? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let request = ReservationCreateRequest(
                userId: userId,
                facilityId: facilityId,
                startDate: startDate,
                endDate: endDate
            )
            
            let created = try await APIService.shared.createReservation(request: request)
            createdReservation = created
            return created
        } catch let error as APIError {
            errorMessage = error.message
            print("예약 생성 실패:", error.message)
            return nil
        } catch {
            errorMessage = error.localizedDescription
            print("예약 생성 실패:", error)
            return nil
        }
    }
    
    private func makeReservedHours(from reservations: [DailyReservation], targetDate: String) -> Set<Int> {
        var result = Set<Int>()
        
        let calendar = Calendar.current
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd"
        dayFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let selectedDay = dayFormatter.date(from: targetDate) else {
            return result
        }
        
        let dayStart = calendar.startOfDay(for: selectedDay)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
            return result
        }
        
        for reservation in reservations {
            guard let start = parseServerDate(reservation.startDate),
                  let end = parseServerDate(reservation.endDate) else {
                continue
            }
            
            let effectiveStart = max(start, dayStart)
            let effectiveEnd = min(end, dayEnd)
            if effectiveStart >= effectiveEnd { continue }
            
            let startHour = calendar.component(.hour, from: effectiveStart)
            var endHour = calendar.component(.hour, from: effectiveEnd)
            
            let minute = calendar.component(.minute, from: effectiveEnd)
            let second = calendar.component(.second, from: effectiveEnd)
            if minute > 0 || second > 0 {
                endHour += 1
            }
            
            for hour in startHour..<min(endHour, 24) {
                result.insert(hour)
            }
        }
        
        return result
    }
    
    private func parseServerDate(_ text: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: text) { return date }
        
        let formatter2 = ISO8601DateFormatter()
        formatter2.formatOptions = [.withInternetDateTime]
        if let date = formatter2.date(from: text) { return date }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let formats = [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        ]
        
        for format in formats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: text) {
                return date
            }
        }
        
        return nil
    }
    
    func cancelReservation(reservationId: Int) async {
        do {
            try await APIService.shared.updateReservationState(
                reservationId: reservationId,
                state: 0 // 🔥 취소
            )
        } catch {
            print("예약 취소 실패:", error)
        }
    }
}
